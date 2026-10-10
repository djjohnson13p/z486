# Review of the 2026-10-10 CPU fixes (`cpu-fixes-review`)

Date: 2026-10-10. Reviewer: an independent agent. It did not write any of the fixes.
Scope: `fix-spec-victim-store`, `hazard-audit`, `audit-nonalloc`, `audit-specdev` and
`audit-rmwprobe`, integrated on top of `personal/main` (`23bdc0c`). `throttle-gated` is out of
scope. Nothing has been pushed. The source branches are unchanged.

## Verdict

**The series is ready to push to the fork.** Every fix closes the window it claims, and every
fail-first program fails on its parent and passes on its fix, for the stated reason. The
expected values come from 486 behaviour, not from our RTL. Dhrystone is unchanged, and so is
every microbenchmark.

Two items go to the owner before the next re-vendor into the PC-9821 core. Neither blocks the
fork push:

1. **Timing (`fac8d54`, specdev).** It adds about 2 ns, in the post-map model, to the
   TLB -> class compare -> I$ request path. This was measured one variable at a time.
2. **Boot golden.** Under `fac8d54`, a branch target in a non-CACHEABLE window class (the PC-98
   aperture A0000-FFFFF, which holds the BIOS ROM) loses its speculative head start. The
   microbenchmarks here cannot reach that window. Measure `CYCLES used=` in the core.

The RMW late-finish item has one gap left, and it is the owner's call (see "Owner items").

## Integrated series (final)

```
8b3db69 tests: smc_spec_demote_rm                        326ff23 fix(prefetch): victim line vs a same-cycle store
1d7aba3 tests: hazard-audit guards
19fc2b0 tests: hz_invlpg_spec                            2d7cb45 fix(z486): INVLPG kills the buffer          (D1)
6a5fb7c tests: hz_spec_a20_rm (+ obj_dir_bigmem)         5ef52c8 fix(z486): A20 edge kills the buffer        (D2)
5f3aa58 tests: hz_vipt_share_unposted                    3a586ff fix(l1_cache): share only with an accepted store (D3)
7c0d9d8 tests: hz_patchq_overrun                         ba4fd3b fix(cache_unit): I$ fill waits for the drain (D4)
8d89c77 tests: hz_tr6_spec                               f2bc244 fix(z486): TR6 kills the buffer and pf_xlat (D5)
7e7746f tests: fuzz_hazard.py
cd63106 tests: fuzz_hazard_v86.py
02d3c03 tests: hz_spec_walk_store
c1f3b54 tests: fuzz_hazard_emm.py   (5414d17 folded in: a correction of this generator)
8ee07d9 tests: fuzz_hazard_emm branchy guest code
0f089de tests: +spec_check oracle
17afdcd docs: coherency-audit C8, C21-C24
36b57d7 tests: hz_nonalloc_target                        413b539 fix(paging_unit): buffer refuses NO_ALLOC lines
ba25b1a tests: hz_spec_dev_reads, hz_spec_walk_abit      fac8d54 fix(paging_unit): spec fetch never walks or reads devices
e571bf7 tests: hz_rmw_late_finish, fuzz_hazard --rmw     623d0c3 chore(data_access): RMW late-finish fuse
9249e94 docs: z486-hazard-audit.md (b7ae2ec moved to the end, the three lead docs commits folded in)
        docs: this report
```

The RTL tree is byte-identical to the integration that ran the gates: a plain cherry-pick of
the three `audit-*` branches onto `hazard-audit`, at `c1a791a`. The curation touched only:

- docs;
- one docstring line in `tests/hazard/fuzz_hazard.py`;
- commit messages.

`git diff c1a791a 9249e94` lists only `docs/z486-hazard-audit.md` and that docstring.

### Integration notes

- `audit-nonalloc` and `audit-specdev` conflicted in the port lists of `cache_unit`, `memory`
  and `z486`. Both added an output next to `icache_req_is_pcd`. The resolution keeps both ports:
  `icache_req_is_no_alloc` (it moved from an internal wire to a port) and `icache_req_spec_ok`.
  `icache_req_class_ram` stays an internal wire.
- The RMW docs commit conflicted with the lead-2 docs section. The resolution keeps both
  sections.

### Nits fixed by the reviewer (no semantic change)

1. `5414d17` ("scribble only the unloaded overlay's own slots") corrected a generator defect in
   `7abdc90`. Per the policy it is folded into that commit (now `c1f3b54`), and the message is
   updated.
2. The three docs-only "lead resolved" commits (`3f76887`, `f1e0897`, `77d93bc`/`c1a791a`)
   edited `docs/z486-hazard-audit.md`, which is new in this unpushed series. `b7ae2ec` moved to
   the end, and they are folded into it (now `9249e94`). The doc's own commit table and fix-SHA
   citations are re-pointed to the final ids, and leads 1 and 2 are marked closed in the
   open-leads list. The non-allocating-window row of the audit table now says NO_ALLOC is fixed.
   The "phase 2 still running" placeholder now points here.
3. Stale SHA `5cfe7ab`, a pre-rebase id on no branch, is replaced by a description in the
   messages of `1d7aba3` and `7e7746f` and in the `fuzz_hazard.py` docstring.
4. The `fac8d54` message cited its test commit by a branch-local SHA (`2bd9f1a`). It now says
   "the preceding tests: commit".
5. The `fac8d54` `Upstream:` line was wrong: it said "the speculative target buffer is a fork
   addition". The buffer is upstream's (`prefetch.sv` `spec_*`, upstream `50ea1f5`), and
   `hz_spec_walk_abit` fails on upstream `4bfdde0` too. Corrected.
6. The `623d0c3` `Upstream:` line was wrong: it said `data_access.sv` "is fork-only structure".
   The RMW_FAST `rd_fast_*` path is upstream's. Corrected.

### Nits left for the owner (not changed)

- **Red commits.** Each `tests:` commit before its `fix(...)` leaves `make test-release` red at
  that commit. `36b57d7` adds `hz_nonalloc_target` to `test-pc98-map`, and every
  `tests/programs` addition is run by `test-protected`. `personal/main`'s precedent bundles a
  fail-first test into its fix commit (`112cf9c`, `b59f784`), which keeps every commit green and
  bisectable. The split form does help the policy's "triage tests before RTL" on a rebase.
  Either is defensible. Squash test+fix pairs if bisectability matters more.
- **Mixed commit.** `c1f3b54` also changes `fuzz_hazard_v86.py`'s window stubs (the "window
  stubs branch in-line" part of its subject). That is a correction to `cd63106` and could be
  split out and folded there.

## Per-commit verdicts

| commit | verdict | notes |
|---|---|---|
| `8b3db69` tests smc_spec_demote_rm | ACCEPT | FAIL data=0x1 at lat 0-20 on the parent, also on upstream `4bfdde0`; PASS with fast off. 486 rule: a store followed by a jump runs the new bytes |
| `326ff23` fix(prefetch) victim | ACCEPT | `spec_b_valid <= !spec_kill` on demotion. Swap path checked: `spec_b_match` already excludes any store/kill cycle, so a stale victim cannot be promoted. A store that hits the old victim during a demotion over-kills (harmless). 33/33 x2 after |
| `1d7aba3` tests guards | ACCEPT | all pass at 0-32, fast/off/narrow on the head |
| `19fc2b0` / `2d7cb45` D1 INVLPG | ACCEPT | FAIL data=0x6 at all lat 0-32 before (and on upstream); PASS after. OR-term on the registered kill |
| `6a5fb7c` / `5ef52c8` D2 A20 | ACCEPT | FAIL data=0x1c at 0-32 before; PASS after. 486: A20M# masks before the cache lookup. Reset value 1 gives at most one harmless kill |
| `5f3aa58` / `3a586ff` D3 VIPT share | ACCEPT | The window is narrow: the default xdma pair fails only at lat 3, data=0x3. Genuine: PASS after at 0-32. The new term equals `accept_cpu`'s first arm and reaches only two flops (`rd_fast_probed_r`, `vipt_load_ex_probed_r`). Checked. Upstream run inconclusive (its bench has no `+xdma`) |
| `7c0d9d8` / `ba4fd3b` D4 I$ fill vs storeq | ACCEPT-WITH-NITS | FAIL at lat 5-32 fast and 13-32 fast-off before (a core cache defect, not a fast-path one); PASS after, narrow too. Handshake safe: `l1_icache.mem_valid_r` is held until `mem_ready`, which is `ext_icache_accept` and only exists after the gated launch. No deadlock: the D$ drain never waits on the I$ (`drain_issue_now` needs only `!mem_busy`, and `icache_read_pending` is false while held). Nit: a store sitting in `S_NW_WRITE` (CR0.NW=1, enqueues from that state) is not in `storeq_line_hit_c`; NW=1 is the already-recorded limit |
| `8d89c77` / `f2bc244` D5 TR6 | ACCEPT-WITH-NITS | FAIL data=0x11 at 0-32 before; PASS after. Observation: in the `tlbt_done` cycle itself, `pf_xlat` (refreshed from the replaced entry at `tlbt_go`) is still valid and usable by a *demand* prefetch for that one cycle. The buffer is covered. TR6 is diagnostic and the 486 does not define queue coherence across it, so no change asked |
| `7e7746f`, `cd63106`, `02d3c03`, `c1f3b54`, `8ee07d9`, `0f089de` | ACCEPT | fuzzers and oracle; volume below |
| `17afdcd` docs coherency-audit | ACCEPT | could gain C25/C26 rows for lead 1/2 (optional) |
| `36b57d7` / `413b539` nonalloc | ACCEPT | FAIL data=0x11223344 at lat 0-13 before (fast and narrow); PASS after at 0-32 in every mode. One OR-term into the `pf_nocache` flop. Overlaps specdev only on adopted/demand fills, which specdev does not gate, so both are needed. Cost measured: a loop in a NO_ALLOC window is cycle-identical to main (`ub98_noalloc`) |
| `ba25b1a` / `fac8d54` specdev | ACCEPT-WITH-NITS | FAIL before at 0-32 (`hz_spec_dev_reads`; `hz_spec_walk_abit` data=0x1, also on upstream); PASS after. Checked: `pf_refused` is a one-cycle pulse aligned with the ack toggle exactly as `pf_fault`, cleared at the ack edge with `spec_adopted_r`. A refused adopted fetch re-requests via `pf_can_fetch`; `icache_req_spec_ok` is evaluated on `fast_pf_phys` (`icache_req_valid_r` is never set in PG_IDLE). Nits: timing and boot-golden (owner items 1-2). Message fixed (nit 5) |
| `e571bf7` tests rmw | ACCEPT | passes 0-32 fast/off/narrow |
| `623d0c3` chore fuse | ACCEPT | sim-only; never fired in the release gate (incl. `+cpu_speed` 1-3) or any run here. Message fixed (nit 6). `chore:` is a fair prefix for a translate_off guard |
| `9249e94` docs hazard audit | ACCEPT | curated by the reviewer (nit 2) |

## Fail-first re-runs (reviewer's own, newdelltower)

Each test ran on its parent commit and on its fix, at mem_latency 0-32, fast and `+z486_fast_off`:

| program | parent | fix |
|---|---|---|
| smc_spec_demote_rm | fast 0/21 (data 0x1), off 21/21 | 33/33, 33/33 |
| hz_invlpg_spec | fast 0/33 (0x6), off 33/33 | 33/33, 33/33 |
| hz_spec_a20_rm (bigmem) | fast 0/33 (0x1c), off 33/33 | 33/33, 33/33 |
| hz_vipt_share_unposted | fast 32/33 (lat 3: 0x3) | 33/33, 33/33 |
| hz_patchq_overrun | fast 5/33, off 13/33 (0x2000f); narrow 33/33 | 33/33, 33/33, narrow 33/33 |
| hz_tr6_spec | fast 0/33 (0x11), off 33/33 | 33/33, 33/33 |
| hz_nonalloc_target (pc98) | fast 19/33 (0x11223344), narrow 19/33 | 33/33 in all three |
| hz_spec_dev_reads | fast 0/33, off 33/33 | 33/33, 33/33 |
| hz_spec_walk_abit | fast 0/33 (0x1), off 33/33 | 33/33, 33/33 |

**Upstream (`origin/main` = `4bfdde0`, the merge base; upstream has no newer commits).** Each
program ran serially, because the upstream runner shares one hex file between parallel runs.

- Fail on upstream with the same data: smc_spec_demote_rm, hz_invlpg_spec, hz_spec_walk_abit.
  These are upstream defects, so `fix(...)` is the right prefix.
- Fails differently on upstream: hz_tr6_spec (data 0x0).
- Pass on upstream because its bench lacks the stimulus (`+xdma`, the watch window, wide fills):
  hz_patchq_overrun, hz_vipt_share_unposted, hz_spec_dev_reads. Inconclusive.
- Upstream has not fixed any of them.

## Gates on the integrated head (`c1a791a`, same RTL as `9249e94`)

- `make -C tests test-release JOBS=4`: **EXIT 0**.
  - protected 308/308, at default, narrow and `+cpu_speed` 1/2/3;
  - pc98-map 7/7 x 2, bigmem 1/1 x 2, x87 317/317, plus `test-fuzz`, every unit bench,
    `check-equiv` and `check-generators`.
- `make dhrystone`: **254235 cy / 121837 instr / CPI 2.087**, identical to `personal/main`.
- Hazard directed sweep, head: 19 programs x (fast 0-32, off 0-32, narrow fast 0-32) = 1881 runs,
  all pass. hz_nonalloc_target (pc98) 99/99 and hz_spec_a20_rm (bigmem) 66/66 also pass.
- Hazard fuzzers on the head, new seed ranges (70000+; the authors used lower). 4 sims per seed;
  `+spec_check` and every `$fatal` fuse active:
  - `fuzz_hazard.py`: 100/100 match;
  - `fuzz_hazard.py --rmw`: 50/50;
  - `fuzz_hazard_v86.py`: 50/50;
  - `fuzz_hazard_v86.py --irq 1200`: 50/50;
  - `fuzz_hazard_emm.py`: 50/50;
  - `fuzz_hazard_emm.py --irq 1200`: 50/50.

  350 seeds (1400 simulations), 0 mismatches. The fuzzers ran locally at JOBS=4 (newdelltower
  was loaded by another job). The RMW probe below adds 60 more `--rmw` seeds, also all match.

## Performance (cycles; main `23bdc0c` vs integrated head)

`tb_protected_mode`, paging on, caches on, unless noted. Every row is **identical** at every
latency tried (0, 5 and 15).

| microbenchmark | shape | main = head (lat 0 / 5 / 15) |
|---|---|---|
| ub_busy | `dec ecx; jnz` x 20000 | 80180 / 80198 / 80248 |
| ub_poll | `cmp [mem],1; je; dec; jnz` x 20000 (vsync-wait shape) | 180238 / 180259 / 180348 |
| ub_repmovs | 64-byte `REP MOVSD` x 500 | 56248 / 56289 / 56407 |
| ub_callret | `call f; ret` x 10000 | 110232 / 110250 / 110340 |
| ub_pagecross | loop at page+4, then a loop straddling a page boundary, 10000 each | 200217 / 200249 / 200337 |
| ub_branchy | not-taken exit `je` + back edge x 10000 | 70183 / 70205 / 70265 |
| ub_tlbcold | 64 calls to 64 different pages x 50 rounds (TLB pressure; specdev's walk refusal) | 105213 / 131374 / 196792 |
| ub_smc | patch an immediate in another line, jump to it, x 5000 (D4) | 125193 / 145219 / 195286 |
| ub_rmbusy | real mode, `cmp/je/dec/jnz` x 20000 | 120171 / 120183 / 120213 |
| ub_cdbusy | the same with CR0.CD=1 (specdev refuses every spec fetch) | 320163 / 480167 / 880194 |
| ub98_cached (pc98 map) | ub_branchy shape from window 0, cacheable | 35162 / 35176 / 35216 |
| ub98_noalloc (pc98 map) | the same with `+win0_unmapped` (NO_ALLOC; nonalloc's cost) | 80146 / 120152 / 220172 (main) vs 80144 / 120146 / 220156 (head) |

Not covered: code executing from the PC-98 aperture (BIOS ROM, class DIRECT). That is
specdev's documented cost, and these benches cannot place code there. Measure it with the
core's boot golden at re-vendor.

## Synthesis risk (Quartus 17 `quartus_map` + `quartus_sta --post_map`, no fit)

The setup synthesised the whole `z486` as top, with every pin virtual:

- the PC-98 preset parameters (`Z486_PC98_MAP_PARAMS`, `RAM_BOUND_ENABLE`);
- 6-bit cache sets, x87 off;
- the production synthesis settings;
- a 12.5 ns clock.

The post-map delay model is rough (its worst register path is 33 ns, where the real fit is
about 17.5 ns). Use these numbers as one-variable deltas between commits, not as absolute
timing. Data arrival at the named endpoint, in ns:

| endpoint | 23bdc0c main | ebd6894 | 9008657 (+D4) | b7ae2ec (hazard head) | accf2ae (+specdev) | c1a791a head |
|---|---|---|---|---|---|---|
| I$ request capture (`icache_inst|req_*`) | 27.07 | 27.51 | 27.22 | 27.24 | **29.28** | **30.27** |
| `pf_fast_pending` / `pf_nocache` | 21.46 | 21.92 | 21.58 | 21.59 | **24.11** | **23.89** |
| D$/storeq/I$-addr -> `bus_unit ext_*` (D4's cone) | 18.50 | 19.67 | 20.02 | 19.58 | 19.53 | 20.34 |
| any -> `ext_addr_r` (the known critical ladder) | 28.45 | 28.73 | 29.24 | 29.47 | 29.07 | 30.17 |
| ALM estimate | 19250 | 19662 | 19269 | 19343 | 19248 | 19405 |

- **specdev (`fac8d54`) is the real one.** It adds +2.0 to +2.5 ns, one variable apart. The
  head's I$-request path is `tlb_lookup_addr_r -> TLB hit/way -> physical_addr ->
  fast_pf_phys -> icache_req_phys_addr -> z486_classify_phys -> pf_spec_attr_ok ->
  icache request accept` (fan-out 594 into the I$ request registers). In this model it still
  sits about 8.5 ns short of the worst register path (slack -12.3 vs -20.8), outside the top
  300. But the real fit's worst ladder includes the paging fast path, so this needs the
  deferred seed sweep.
  - Cheap mitigation if it bites: compute the spec attribute check one cycle later, for
    speculative launches only. They are latency-tolerant, so demand fetches are untouched.
- **D4 (`ba4fd3b`) adds +0.35 ns** on its own cone and about 0.5 ns on `ext_addr_r`, inside
  this model's run-to-run noise.
- **D3** was not separable. `rd_fast_probed_r` and `vipt_load_ex_probed_r` moved by +0.1 to
  +0.2 ns.
- **Head vs main on `ext_addr_r`, +1.7 ns.** This is not attributable to one change: the path
  restructured through `ext_direct_req`/`ext_src_r`. It is [DIRECTIONAL]; whole-design
  synthesis A/B is noisy here (AGENTS.md).

## Owner items

1. **specdev timing.** Before vendoring `fac8d54` into the 80 MHz core, run the seed sweep that
   was deferred. If the I$ request path shows up, register the spec attribute check (see above).
2. **specdev cost on BIOS-ROM branches.** Read the core's boot golden (`CYCLES used=930530`) at
   re-vendor. specdev refuses speculative target fetches into the DIRECT aperture, where the
   ROM is.
3. **RMW late-finish gap: SAFE by observation, not by construction.**
   - The gap: `d2_vipt_rmw` checks `!mem_servicing` on registered state only. An older bus
     operation handed to paging in the RMW's issue cycle (`mem_req_to_paging`) could make
     `mem_servicing` rise under the RMW's first uStep. Loads have the guard
     `!(i_rni_delay && d2_vipt_candidate)` in `mem_op_eligible` (`z486.sv`); RMW has no
     analogue.
   - **Reviewer's probe:** a sim-only check of `vipt_issue_rmw && dcache_vipt_probe_accepted &&
     mem_req_to_paging` in the same cycle. It was not committed. It **never fired** over:
     - the full protected suite (308 programs);
     - hz_rmw_late_finish, hz_rmw_cross_store, hz_rmw_after_paged_store, vipt_rmw_fast and
       vipt_rmw_interval at lat 0/3/5/8/13/20/32;
     - 60 `fuzz_hazard.py --rmw` seeds (72000-72059) with the probe as a `$fatal`.

     So no known instruction puts a paging-routed bus operation in the older instruction's RNI
     slot in the cycle an RMW_FAST issues. A directed test that forces it could not be
     constructed from the shapes tried, and the fuse (`623d0c3`) remains the guard.
   - **Recommendation: add the guard.** Make it the exact analogue of the load term:
     `!(i_rni_delay && (d2_vipt_candidate || d2_vipt_rmw_candidate))` in `mem_op_eligible`.
     - It is one OR-term on a registered signal and a decode-level signal, and adds no
       combinational term to D2 issue.
     - Expected cost is zero cycles, because the probe shows the coincidence never occurs.
       That is not proven: check Dhrystone and the suite's cycle counts when it lands.
     - The alternative is `!mem_req_to_paging` inside `d2_vipt_rmw`. It is cycle-neutral by
       construction, but it feeds demand arbitration back into D2 issue, which the existing
       design avoids on purpose. Not recommended.
   - Either form goes to the RMW lane's author as a separate `fix(z486)` with its fuse as the
     test.
4. **Optional squash.** Squash each `tests:`/`fix:` pair to keep every commit green (see
   "Nits left").
