#!/usr/bin/env python3
"""sweep.py PROGRAM [PROGRAM...] [--lat 0-32] [--jobs 4] [--modes fast,off] [--extra '+plusarg ...']

Runs tests/programs/<PROGRAM> through test_protected_mode.py at every memory
latency in the range (a +mem_latency=N in SIM_PLUSARGS precedes the JSON's own,
and $value$plusargs takes the first), with the fast paths on ("fast") and off
("off" = +z486_fast_off), and prints one verdict per (program, mode, latency)
plus a summary. Exit 1 if any run failed. Uses the prebuilt
obj_dir/Vtb_protected_mode; never rebuilds it.
"""
import argparse
import concurrent.futures as cf
import os
import re
import subprocess
import sys

TDIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lat_range(s):
    out = []
    for part in s.split(','):
        if '-' in part:
            a, b = part.split('-')
            out += list(range(int(a), int(b) + 1))
        else:
            out.append(int(part))
    return out


def run(prog, mode, lat, extra, cycles):
    plus = f"+mem_latency={lat} " + ("+z486_fast_off " if mode == "off" else "") + extra
    env = dict(os.environ, SIM_PLUSARGS=plus.strip())
    r = subprocess.run(["./test_protected_mode.py", prog, "-c", str(cycles)], cwd=TDIR, env=env,
                       capture_output=True, text=True)
    out = r.stdout + r.stderr
    ok = ("PASS" in out) and ("FAIL" not in out) and r.returncode == 0
    m = re.findall(r"data=([0-9a-fA-F]+)", out)
    why = ""
    if not ok:
        tail = [l for l in out.splitlines() if l.strip()][-2:]
        why = " | ".join(tail)[:200]
    return prog, mode, lat, ok, why


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("progs", nargs="+")
    ap.add_argument("--lat", default="0-32")
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--modes", default="fast,off")
    ap.add_argument("--extra", default="")
    ap.add_argument("--cycles", type=int, default=400000)
    a = ap.parse_args()
    jobs = []
    with cf.ThreadPoolExecutor(max_workers=min(a.jobs, 8)) as ex:
        for p in a.progs:
            for mode in a.modes.split(','):
                for lat in lat_range(a.lat):
                    jobs.append(ex.submit(run, p, mode, lat, a.extra, a.cycles))
        res = [j.result() for j in jobs]
    bad = 0
    for p in a.progs:
        for mode in a.modes.split(','):
            rs = sorted([r for r in res if r[0] == p and r[1] == mode], key=lambda r: r[2])
            fails = [r for r in rs if not r[3]]
            bad += len(fails)
            print(f"{p:32s} {mode:4s} {len(rs)-len(fails)}/{len(rs)} pass"
                  + (f"  FAIL at lat {[r[2] for r in fails]}" if fails else ""))
            for r in fails[:3]:
                print(f"    lat {r[2]}: {r[4]}")
    sys.exit(1 if bad else 0)


main()
