#!/usr/bin/env python3
"""Throttle invariance bench: the architectural result of every program is the
same at every throttle setting (and at every memory latency).

A throttled CPU is the same CPU seeing fewer clock edges, so a program's result
must not depend on the setting.  For each program of the protected suite this
runs it at full speed and at each requested (setting, memory latency) and
compares, against the full-speed run:
  - the verdict,
  - the sequence of values the program reports on data port 0xE4,
  - a hash of final memory (+arch_digest).
Programs that read the real-time clock (port 0xFC), place an interrupt or NMI
through the signal port (detected from the full-speed run's own SIGNAL trace,
not from the source text) or are marked unthrottled_only legitimately depend
on the setting and are skipped, as are expected-failure programs.  Running at a different MEMORY LATENCY changes every
timing relationship between the CPU and the bus, which is what makes this an
instrument and not only a regression: a mismatch is a latent race.

usage: test_throttle_invariance.py [--sel 3 6] [--lat 1] [--jobs 4] [prog ...]
       --ref-lat N   latency of the full-speed reference (default 1)
Exit 0 only if every comparison matches.
"""
import argparse
import concurrent.futures as cf
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import test_protected_mode as tpm   # noqa: E402


def uses_clock(name, cfg):
    """True for a program whose result legitimately depends on the setting
    before it runs: it reads the real-time clock (port 0xFC), or is hit by a
    real-time external write (xdma_*), so WHICH instruction the event lands on
    depends on CPU speed against the bus.  The match is on port USE (an IN, a
    DX load, an EQU, CYCLE_PORT), not on any 0xFC byte: an opcode table or a
    compared constant is not a clock read.  A signal-port event is detected
    from the reference run instead (one()).  The suite itself still runs every
    skipped program at every setting (test-protected-throttled)."""
    asm = (tpm.TESTS_DIR / cfg["asm"]).read_text(errors="replace")
    plus = " ".join(cfg.get("sim_plusargs", []))
    return bool(re.search(r"CYCLE_PORT|\bin\s+\w+\s*,\s*0xfc\b|\bdx\s*,\s*0xfc\b|\bequ\s+0xfc\b",
                          asm, re.I)
                or "xdma_" in plus or "fuzz_irq" in plus)


# The testbench's +trace_io lines for an interrupt or NMI the program placed
# through the signal port (0xE8 data 1-4); a write of any other value is inert.
SIGNAL_EVENT = re.compile(r"^SIGNAL: (INTR|NMI) (requested|armed)", re.M)


def run(name, cfg, hex_file, base, sel, lat, extra):
    plus = f"+cpu_speed={sel} +trace_io +arch_digest +mem_latency={lat} {extra}".strip()
    os.environ["SIM_PLUSARGS"] = plus   # (single-threaded callers only)
    scale = tpm.THROTTLE_CYCLE_SCALE[sel] * (1 + lat // 4)
    passed, failed, timeout, out = tpm.run_simulation(
        name, cfg, hex_file, base, False, False,
        cfg.get("cycles", 20_000) * scale, None, wall_timeout=120 * scale)
    data = re.findall(r"TEST DATA: 0x([0-9A-Fa-f]+)", out)
    dig = re.findall(r"ARCH_DIGEST memhash=([0-9a-f]+)", out)
    fatal = [l for l in out.splitlines() if "Fatal" in l or "%Error" in l]
    return ("PASS" if passed else "TIMEOUT" if timeout else "FAIL", data,
            dig[-1] if dig else None, fatal[:1]), bool(SIGNAL_EVENT.search(out))


def one(name, sels, lats, ref_lat, extra):
    cfg = tpm.TESTS[name]
    work = Path(tempfile.mkdtemp(prefix=f"z486_inv_{name}_"))
    try:
        bin_file, lst, hex_file = (work / f"{name}.{e}" for e in ("bin", "lst", "hex"))
        if not tpm.assemble(tpm.TESTS_DIR / cfg["asm"], bin_file, lst, False):
            return name, [("assembly failed",)]
        base = tpm.build_memory_image(cfg, bin_file, hex_file)
        ref, signal = run(name, cfg, hex_file, base, 0, ref_lat, extra)
        bad = []
        if ref[0] != "PASS":
            return name, [(f"full-speed reference {ref[0]} {ref[3]}",)]
        if signal:
            print(f"SKIP {name}: places an interrupt through the signal port")
            return name, []
        for sel in sels:
            for lat in lats:
                got, _ = run(name, cfg, hex_file, base, sel, lat, extra)
                if got != ref:
                    bad.append((sel, lat, got, ref))
        return name, bad
    finally:
        shutil.rmtree(work, ignore_errors=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("progs", nargs="*")
    ap.add_argument("--sel", type=int, nargs="+", default=[3, 7])
    ap.add_argument("--lat", type=int, nargs="+", default=[1])
    ap.add_argument("--ref-lat", type=int, default=1)
    ap.add_argument("--extra", default="")
    ap.add_argument("--jobs", type=int, default=1)
    a = ap.parse_args()
    names = a.progs or sorted(tpm.TESTS)
    todo = []
    for n in names:
        cfg = tpm.TESTS[n]
        plus = " ".join(cfg.get("sim_plusargs", []))
        if (cfg.get("requires_x87") or cfg.get("requires_bigmem") or "expect_pc98_map" in plus
                or cfg.get("unthrottled_only") or cfg.get("expect_fail")
                or uses_clock(n, cfg)):
            continue
        if cfg.get("fast_paths_only") and "z486_fast_off" in a.extra:
            continue
        todo.append(n)
    print(f"{len(todo)} programs x settings {a.sel} x latencies {a.lat} vs full speed at latency {a.ref_lat}")
    bad_total = 0
    if a.jobs > 1:
        # run_simulation reads SIM_PLUSARGS from the environment: use processes.
        import subprocess
        procs = []
        with cf.ProcessPoolExecutor(max_workers=a.jobs) as ex:
            res = list(ex.map(one, todo, [a.sel] * len(todo), [a.lat] * len(todo),
                              [a.ref_lat] * len(todo), [a.extra] * len(todo)))
    else:
        res = [one(n, a.sel, a.lat, a.ref_lat, a.extra) for n in todo]
    for name, bad in res:
        for b in bad:
            bad_total += 1
            print(f"MISMATCH {name}: {b}")
    print(f"TB_THROTTLE_INVARIANCE: {'PASS' if not bad_total else f'FAIL ({bad_total})'}")
    sys.exit(1 if bad_total else 0)


if __name__ == "__main__":
    main()
