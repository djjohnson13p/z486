These are unmodified full CPU source files from doublej472/z486 at
`85d8190c452e065f9253add1cc86516282c4d8ea`, frozen before the selected EX-read
rewrite. They are test references, never production build inputs.

`check_selected_ex_equiv.py` validates their Git blob identities (normalizing
only checkout CRLF to LF), translates the two actual merge module bodies for
Yosys, and extracts the old and new actual data-unit formatter and named-port
connections. The sole package import is replaced with the four unchanged
EA_FWD constants taken from the pinned package; simulation-only fuse blocks
are excluded as synthesis excludes them. No production combinational body is
restated. All legacy module outputs, both selected EX outputs, and the final
destination formatter are compared. Producer data, visibility and arbitration
inputs remain free, including independent `data_wb` and `fwd_wb` values.

The positive proofs and separate priority, M3, visibility, AH-index and size
mutants must all produce their expected SAT verdict. A parser/tool failure is
never accepted as a killed mutant. This establishes the rewrite's equivalence
to the reference, not architectural correctness of the reference CPU, FPGA
timing, a PC9821 boot or hardware operation.

The release invocation uses the installed **yosys-slang** frontend. See
`../../README.selected-ex.md` for plugin selection, dependency failures,
prepare-only review, resource bounds and the preserved legacy diagnostic.
