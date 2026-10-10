# CPU throttle: the gated-clock contract

Status: implemented (mode A of `docs/throttle-design.md`, with the "stop the
whole CPU" primitive of its section 4). The park of the previous throttle
(`throttle_parked_r`, `throttle_atomic_chain`, the `d2_ready`/`uc_slot_live`/
`mem_op_eligible` terms, the event-control fuse) is deleted.

## The idea

z486 has **no speed input any more**. A slower CPU is the same CPU that sees
fewer clock edges: the platform runs `z486.clk` from a *gated* copy of its own
clock, and every flop and memory inside z486 simply holds its value across the
edges it does not get. A pause is therefore architecturally invisible **by
construction**, including in the middle of a REP, a page walk or a multi-beat
microcode sequence; there is no per-path "paused" term to forget. (The old
mechanism could only act at an instruction boundary: a REP was one instruction,
and one 12288-dword `REP STOSD` ran 32.5x too fast at its slowest setting.)

`cpu_throttle.sv` carries three small modules:

| module | what it is |
| --- | --- |
| `cpu_throttle` | The rate generator. `CLOCK_RATE_KHZ` (the platform clock, a compile-time parameter, so a setting means the same effective rate at any `clk_sys`) and `speed_sel[3:0]`; output `cpu_ce`, a **registered** enable. `cpu_ce` high during a platform-clock cycle means *the CPU gets the clock edge that ends this cycle*. A Bresenham accumulator spreads the enabled edges evenly, so the CPU never waits more than `ceil(clk/rate)` platform cycles for one. Setting 0 (and the reserved 14 and 15), or any rate at or above the platform clock, makes `cpu_ce` constant 1 (a strict no-op: the full-speed core is cycle-identical to the ungated core). `reset_n` low forces `cpu_ce` to 1, so a reset of two or more platform cycles is always seen. |
| `cpu_clk_gate` | A glitch-free gate (low-phase latch + AND) for simulation and for targets without a clock-control block. On Cyclone V use `ALTCLKCTRL` with `ena = cpu_ce` instead; it latches `ena` while its clock is low, which is exactly the property `cpu_ce` being registered relies on. |
| `cpu_pulse_hold` | Holds a one-platform-cycle pulse until the CPU's next enabled edge (below). |

### The settings

Owner decisions (2026-10-10): no title needs exact timing, so mode A (a uniform
rate) is enough and the 286 cost tables (mode B) are not wanted; exponential
steps, many low and few high, from 0.5 MHz up to full; the bus stays FAST
(only CPU execution is throttled, no extra bus or I/O wait states); labels are
plain rates. `speed_sel` is 4 bits (the core's `status[17:14]`), 14 values used:

| `speed_sel` | rate | `speed_sel` | rate |
| --- | --- | --- | --- |
| 0 | full | 7 | 4 MHz |
| 1 | 33 MHz | 8 | 3 MHz |
| 2 | 25 MHz | 9 | 2 MHz |
| 3 | 16 MHz | 10 | 1.5 MHz |
| 4 | 12 MHz | 11 | 1 MHz |
| 5 | 8 MHz | 12 | 0.75 MHz |
| 6 | 6 MHz | 13 | 0.5 MHz |

14 and 15 are reserved and run at full speed. These are rates of CPU clock
edges, not machine equivalences.

A setting at or above the platform clock is full speed (the unselected branch
const-folds away at a compile-time `CLOCK_RATE_KHZ`). Changing the setting takes
effect on the next platform cycle with no transient; the rate is a function of
the platform clock only, never of a count of it.

## What the platform must do

1. **Gate the CPU clock** with `cpu_ce`. On the MiSTer core: an `ALTCLKCTRL`
   (Cyclone V clock-control block, `ena` = `cpu_ce`) between the PLL's clk_sys
   and `z486.clk`. It costs no LABs but **one global clock network** (a fit must
   confirm one is free), and the gated clock is the same clock with a small
   skew against the platform domain: the paths crossing the boundary must be
   timed by the fitter (same-clock STA does that; do not false-path them).
   `cpu_ce` is registered on the *ungated* clock.
2. **Treat `cpu_ce` as `bus_ce`.** Everything the platform samples from the CPU
   (`valid`, `addr`, `be`, `burstcount`, `write`, `io`, `dout`, `inta`, `lock`,
   `cache_flush_busy`/`_done`, `triple_fault_reset`, the `dbg_*` taps) is what
   the CPU drives for its next enabled edge. The bus outputs (`valid`, `addr`,
   `be`, `burstcount`, `line_read`, `write`, `io`, `inta`, `dout`) are
   registered and so hold between enabled edges; some taps (`dbg_issue`,
   `dbg_gate_read`, `lock`'s walker term) are combinational inside the CPU and
   may move with its inputs between edges. Sample the CPU's outputs, and accept a bus request (`valid && ready`), **only
   in a cycle with `cpu_ce` high**: the CPU's own view of `valid && ready` is
   taken at its enabled edges, so a transfer is exactly the `cpu_ce` cycles in
   which both held. A responder that raises `ready` for one platform cycle
   therefore needs its `ready` held like a pulse input (below), and must not
   see `valid` again until the CPU has taken that edge. A one-CPU-cycle pulse
   on an output (`cache_flush_done`, `triple_fault_reset`, `dbg_issue`,
   `dbg_gate_read`, `dbg_page_fault`) is several platform cycles wide: sample
   it under `cpu_ce` as well.
3. **Hold pulse inputs until the CPU's next enabled edge.** The CPU samples its
   inputs only at enabled edges, so an input that is a pulse must be held. Those
   are `resp_valid`, `line_resp_valid` (with their data), `snoop_valid` (with its
   address) and `nmi` (edge-detected inside the CPU), plus `ready` and
   `cache_flush` wherever the platform drives them as one-cycle pulses.
   `cpu_pulse_hold` is the reference implementation:
   `pulse_o = pulse_i | pending`, `pending <= pulse_o & ~cpu_ce`, and a `stall`
   output (`pulse_o & ~cpu_ce`) that the producer uses as **back-pressure**: do
   not present a new beat while the previous one is not consumed (a burst's
   next beat waits for the CPU, one beat per CPU edge). A producer that cannot
   be back-pressured (an SDRAM burst, a DMA snoop) needs a small FIFO in front
   of the hold instead: up to `burstcount` beats (4 for a line fill) for the
   responses. The data bus stays driven
   with the beat's data until it is consumed - a producer that does not clear
   `din` already does. The held response then arrives at the CPU's next edge,
   exactly as a response may start in the accept cycle or any cycle after
   (`z486.sv`'s bus contract). True levels (`intr`, `a20_enable`,
   `win0_unmapped`, `ram_cache_top`, the `*_off_req` switches, ...) need no
   hold.
4. **Count CPU events, not platform cycles,** in any debug that counts the CPU's
   progress (the core's trace ring, the watchdog): the CPU's outputs repeat
   between enabled edges.
5. **Reset.** Drive `cpu_throttle.reset_n` from the CPU's own reset and hold it
   low for at least two platform cycles: `cpu_ce` is registered, so the first
   low cycle forces the enable and the second is the edge the CPU's
   synchronous-reset flops see.

Memory, I/O, the PIT, DMA and the sound chip keep running on the platform clock
at their real rates, as on a real machine whose CPU clock was lower: relative to
the CPU the bus is faster, which is also what makes the throttle an *instrument*
(next section).

## Why the testbench is not the platform: `tb_protected_mode`

`tb_protected_mode` gates the DUT with `cpu_clk_gate` and puts the response
pulses through `cpu_pulse_hold`; the memory model, the DMA/flush model and the
real-time cycle counter (port 0xFC) run on the ungated clock, while the
bench's observers and its interrupt/NMI placement run on the CPU's clock (so a
cycle-placed interrupt keeps its place in the instruction stream at every
setting). `+cpu_speed=N` selects the setting (the bench prints
`[TB] throttle: speed N = R kHz of 85000 kHz`; the bench's clock is 85 MHz for
this purpose); `+mem_latency=N` is the memory latency in platform cycles.

## The instrument

Slowing the CPU relative to memory and I/O shifts every timing relationship the
RTL has, which is how latent races surface. Targets (all in `tests/Makefile`):

| target | what |
| --- | --- |
| `test-throttle-rate` | `tests/test_throttle_rate.py`: a 12288-dword `REP STOSD` and a `DEC/JNZ` loop take the requested time at each setting (the REP check fails on a throttle that acts only at instruction boundaries) |
| `test-protected-throttled` | the whole protected suite at each setting in `THROTTLE_SELS` |
| `test-throttle-invariance` | `tests/test_throttle_invariance.py`: every program's verdict, reported data and final-memory hash identical to full speed at each (setting, memory latency) |
| `test-fuzz-throttle` | the hazard fuzzers (`fuzz_hazard*.py`) and `fuzz_gpr_pipeline.py` with throttle variants against the full-speed reference (`FUZZ_THROTTLE`) |
| `test-throttle-sweep` | the volume run: suite and fuzzers over `SWEEP_SELS` x `SWEEP_LATS` |

`tests/test_protected_mode.py`'s `THROTTLE_RATE_KHZ` mirrors `rate_khz()`;
`test_throttle_rate.py` fails if they disagree.
