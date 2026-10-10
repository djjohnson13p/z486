#!/usr/bin/env python3
"""Throttle rate bench: a throttled CPU takes the requested time, REP included.

Runs programs/throttle_rep_stosd.asm (a 12288-dword REP STOSD, then a DEC/JNZ
loop, each timed with the testbench's real-time clock) at full speed and at
each throttle setting, and requires the throttled time to be the full-speed
time times the clock ratio: the CPU sees 1 clk edge in (clk_khz / rate_khz),
so a CPU-bound instruction - a REP most of all - takes that many times longer.

The expected ratio comes from the testbench's own start-up banner (the RTL's
rate_khz()), and the runner's mirrored table is checked against it.  A
throttle that acts only at instruction boundaries fails the REP check.

The reserved selector codes (14, 15) must run at full speed: the REP and the
loop take exactly the full-speed clocks.

usage: test_throttle_rate.py [--sel 3 5 7 9 11] [--reserved 14 15]
                             [--rep-tol 0.10] [--loop-tol 0.05]
Exit 0 only if every check holds.
"""
import argparse
import os
import re
import sys
import tempfile
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import test_protected_mode as tpm   # noqa: E402

PROG = "throttle_rep_stosd"


def run(sel, work, cfg, hex_file, base):
    os.environ["SIM_PLUSARGS"] = f"+cpu_speed={sel} +trace_io"
    passed, failed, timeout, out = tpm.run_simulation(
        PROG, cfg, hex_file, base, False, False,
        cfg["cycles"] * tpm.THROTTLE_CYCLE_SCALE[sel], None,
        wall_timeout=120 * tpm.THROTTLE_CYCLE_SCALE[sel])
    if not passed:
        raise SystemExit(f"{PROG} at speed {sel}: {'TIMEOUT' if timeout else 'FAILED'}")
    data = [int(x, 16) for x in re.findall(r"TEST DATA: 0x([0-9A-Fa-f]+)", out)]
    if len(data) < 2:
        raise SystemExit(f"{PROG} at speed {sel}: no timing data")
    m = re.search(r"\[TB\] throttle: speed (\d+) = (\d+) kHz of (\d+) kHz", out)
    khz = (int(m.group(2)), int(m.group(3))) if m else None
    return data[0], data[1], khz


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sel", type=int, nargs="+", default=[3, 5, 7, 9, 11])
    ap.add_argument("--reserved", type=int, nargs="*", default=[14, 15])
    ap.add_argument("--rep-tol", type=float, default=0.10)
    ap.add_argument("--loop-tol", type=float, default=0.05)
    a = ap.parse_args()
    cfg = tpm.TESTS[PROG]
    work = Path(tempfile.mkdtemp(prefix="z486_rate_"))
    try:
        bin_file, lst, hex_file = (work / f"{PROG}.{e}" for e in ("bin", "lst", "hex"))
        if not tpm.assemble(tpm.TESTS_DIR / cfg["asm"], bin_file, lst, False):
            raise SystemExit("assembly failed")
        base = tpm.build_memory_image(cfg, bin_file, hex_file)
        rep0, loop0, _ = run(0, work, cfg, hex_file, base)
        print(f"full speed: REP STOSD x12288 {rep0} clk, DEC/JNZ x4096 {loop0} clk")
        bad = 0
        for sel in a.reserved:
            rep, loop, _ = run(sel, work, cfg, hex_file, base)
            ok = (rep, loop) == (rep0, loop0)
            print(f"{'ok  ' if ok else 'FAIL'} speed {sel} (reserved): REP STOSD {rep} clk, "
                  f"DEC/JNZ {loop} clk, full speed is {rep0}/{loop0}")
            bad += not ok
        for sel in a.sel:
            rep, loop, khz = run(sel, work, cfg, hex_file, base)
            if khz is None:
                raise SystemExit(f"speed {sel}: the testbench printed no throttle banner")
            if khz[0] != tpm.THROTTLE_RATE_KHZ[sel] or khz[1] != tpm.THROTTLE_TB_KHZ:
                print(f"FAIL speed {sel}: RTL says {khz[0]}/{khz[1]} kHz, the runner's table says "
                      f"{tpm.THROTTLE_RATE_KHZ[sel]}/{tpm.THROTTLE_TB_KHZ}")
                bad += 1
                continue
            want = khz[1] / khz[0]
            for name, got, ref, tol in (("REP STOSD", rep, rep0, a.rep_tol),
                                        ("DEC/JNZ loop", loop, loop0, a.loop_tol)):
                ratio = got / ref
                ok = abs(ratio / want - 1.0) <= tol
                print(f"{'ok  ' if ok else 'FAIL'} speed {sel} ({khz[0]} kHz): {name} {got} clk = "
                      f"{ratio:.2f}x full speed, requested {want:.2f}x (tol {tol:.0%})")
                bad += not ok
        print("TB_THROTTLE_RATE: PASS" if not bad else f"TB_THROTTLE_RATE: FAIL ({bad})")
        sys.exit(1 if bad else 0)
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
