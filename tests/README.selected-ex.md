# Selected EX-read equivalence gate

This gate needs Python 3, Yosys and the **yosys-slang plugin**. It defaults to
Slang because the legacy Verilog frontend rejects a nested function in the
unchanged reference merge before it reaches SAT. The release recipe explicitly
selects Slang. A missing Yosys or Slang dependency fails; it never skips or falls
back to a weaker parser or oracle.

Install the plugin for the chosen Yosys build. Pass `--slang-plugin PATH` or
set `YOSYS_SLANG_PLUGIN=PATH` to select it explicitly. With neither supplied,
the checker requires exactly one installed `slang.so` adjacent to the resolved
Yosys executable (`share/yosys/plugins` or `lib/yosys/plugins`), or under
`YOSYS_DATDIR/plugins`. An ambiguous installation fails and asks for an explicit
path. Each preparation binds both executable and plugin hashes and rechecks
them before and after execution.

```sh
# Generate the seven proof cases and bind inputs; execute no frontend or proof.
python3 check_selected_ex_equiv.py --yosys /path/to/yosys --slang-plugin /path/to/slang.so

# Execute the same gate, with its default Slang frontend.
python3 check_selected_ex_equiv.py --run --yosys /path/to/yosys --slang-plugin /path/to/slang.so

# Preserve the old frontend for explicit diagnosis; it is not the release gate.
python3 check_selected_ex_equiv.py --frontend legacy --yosys /path/to/yosys
```

The source snapshots, actual formatter/port binding, all free producer inputs,
two positive controls and five mutants are identical for both frontends. Slang
parses in one thread with implicit array memory inference disabled; the SAT
backend and expected results are unchanged. An expected counterexample requires
the actual SAT FAIL marker and a nonzero exit. Parsing, timeout or tool failure
does not count as detecting a mutant.

The checker defaults to 120 seconds per case and executes serially. The calling
release harness must apply its host memory/commit guard; it must preserve logs
and terminate only owned processes on a limit. The reviewed local proof run
uses 512 MiB process-tree RSS, 1 GiB free-commit floor and held-process-handle
cleanup. No test helper silently raises those limits or retries a stopped case.

Passing establishes two-state combinational equivalence of this rewrite. The
CPU release suite, cycle contracts, area pricing, FPGA timing, firmware boot
and hardware validation remain separate requirements.
