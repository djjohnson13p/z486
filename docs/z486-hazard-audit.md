# z486 hazard audit: copies of memory state racing stores, invalidates and fills

Date: 2026-10-10. Written on branch `hazard-audit` (on `fix-spec-victim-store`: `8b3db69` tests,
`326ff23` fix); the follow-up branches `audit-nonalloc`, `audit-specdev` and `audit-rmwprobe`
closed its open leads. The commit ids below are those of the integrated, reviewed series
`cpu-fixes-review` (`docs/cpu-fixes-review-2026-10-10.md`). Nothing has been pushed.

## Why this audit

`326ff23` fixed a prefetcher defect. When the active branch-target line (`spec`) was demoted into
the victim slot (`spec_b`), a store landing in the same cycle killed only the active slot. The
victim kept the pre-store bytes, and a later branch swapped them back in. It took a day to find
and showed up only intermittently.

This audit looks for the same shape everywhere in the CPU: a copy of memory-derived state that is
moved, demoted, promoted, filled, swapped or replayed while a store, invalidate, snoop, flush,
paging change or fill completion targets the same line in the same or an adjacent cycle. The
event is applied to one copy and not the other.

Method:
- Three read-only static lanes covered the caches, paging and the data fast paths.
- The prefetcher and the `z486.sv` spec/RET interface were audited directly.
- Every candidate got a directed program that sweeps memory latency (0-32) and store/event
  alignment. The sweep is `tests/hazard/sweep.py`, with the fast paths on and off.
- Three differential fuzzers were added, plus a bench oracle (`+spec_check`) that checks every
  flush seeded from the branch-target buffer against memory.

## Result

**Five defects found and fixed**, each with a fail-first program. The five fixes are cycle-neutral
on the common path. Dhrystone is unchanged at **254235 cy / 121837 instr / CPI 2.087**.

| # | defect | fix commit | fail-first |
|---|---|---|---|
| D1 | The branch-target buffer survives **INVLPG** of its page, so remapped code runs from the old frame | `2d7cb45` fix(z486) | `hz_invlpg_spec` (data 0x6 at lat 0-32) |
| D2 | The branch-target buffer survives an **A20 gate change** (lines are linear-tagged; the caches are tagged after the mask) | `5ef52c8` fix(z486) | `hz_spec_a20_rm` on the new 4 MiB bench (data 0x1c) |
| D3 | A VIPT direct load **shares the preread of a store the L1 refused** that cycle, and resolves the pre-store value | `3a586ff` fix(l1_cache) | `hz_vipt_share_unposted` |
| D4 | The I$ fill reads memory **ahead of a posted store** into its line, and the 3-entry patch queue then loses that store | `ba4fd3b` fix(cache_unit) | `hz_patchq_overrun` (lat 5-32 fast, 13-32 fast-off) |
| D5 | The branch-target buffer (and `pf_xlat`) survive a **TR6 write** that remaps the page | `f2bc244` fix(z486) | `hz_tr6_spec` (data 0x11 at lat 0-32) |

Plus the victim-slot defect itself (C24, `326ff23`).

**Policenauts:** none of these is the game's stall. The owner ran the head (`edb0be7` before the
rebase, same RTL) on hardware and it still stalls 2 of 3. Only `pf_spec_req` off and `hwc` off
cure it. See "Policenauts status" below for what was fuzzed against that shape and what is still
open.

## Audit table

Verdicts:
- **DEFECT**: reproduced fail-first and fixed.
- **SAFE-c**: safe by construction, with the guard cited.
- **SAFE-t**: safe by test; the program hits the window and passes.
- **UNSURE**: not settled.

### Prefetcher (`prefetch.sv`) and the spec/RET interface (`z486.sv`)

| candidate | hazard window | verdict | evidence / test |
|---|---|---|---|
| Active line demoted to the victim vs a store in that cycle | demotion edge; `spec_kill` cleared only `spec_valid`, and `spec_b_store_hit` compared the OLD victim | DEFECT (C24) | `326ff23`; `smc_spec_demote_rm` |
| Victim swapped back in (`spec_b_match`) vs a store/kill | swap edge | SAFE-c | `spec_b_match` requires `!spec_store_valid && !spec_global_kill` |
| Target fetch launched in the cycle a store hits the NEW target line | `spec_poison <= spec_kill` compares the line being REPLACED | SAFE-t | `hz_spec_launch_rm`: 7 store kinds x 3 forms x 0-7 NOPs, lat 0-32. The I$ lookup cannot overtake the store's patch (C6, `patch_held`), and after D4 cannot read memory ahead of it |
| A store landing in the flush cycle that seeds from the buffer | the kill is registered, so the seed uses `spec_line` | SAFE-t | `hz_spec_launch_rm` form 2 (line buffered before the store). An older store is reported before the younger branch's flush |
| A store reported, then a younger target fetch reads the I$ before the store's patch lands (a store that walks, posted grace) | report at paging acceptance; I$ lookup later | SAFE-t | `hz_spec_walk_store`: walk through an alias, 0-15 NOPs, wide and narrow fills, lat 0-32 |
| Ack in the flush cycle (`spec_data_now`) / adopted post-flush fill vs a same-cycle kill | `spec_valid` set and killed in one cycle | SAFE-c | the later `if (spec_kill) spec_valid <= 0` wins; the queue may hold younger-store-stale bytes, which a 486 allows until a jump |
| Buffer vs **INVLPG** | any cycle after the INVLPG | **DEFECT D1** | `hz_invlpg_spec`; fix kills in the TLB-invalidate cycle (also poisons a fetch in flight or launched then) |
| Buffer vs **TR6 write** | request R; the TLB write lands at `tlbt_go` >= R+1 | **DEFECT D5** | `hz_tr6_spec`; fix kills at the request AND at `tlbt_done` |
| Buffer vs **A20 gate** | any cycle after the edge | **DEFECT D2** | `hz_spec_a20_rm` (needs `obj_dir_bigmem`: the 512 KiB benches wrap 1 MiB onto 0, which hides it) |
| Buffer vs CPL change, CR0/CR3 writes, external snoop, whole-L1 flush | as listed | SAFE-c | `pf_spec_global_kill` (C17-C19); `spec_fetch_cpl_*`, `flush_async_spec` |
| Buffer vs stores that bypass the report | x87 stores, string stores, frames | SAFE-c | every write goes through paging (`pf_paging_store`) or a direct port (`fast_store_valid`); the x87 direct port is read-only |
| Buffer keeping lines from non-allocating template windows (DIRECT / NO_ALLOC; `pf_nocache` covers PCD/CD only) | memory changed there without a CPU store | NO_ALLOC: **fixed** (lead 1); DIRECT: SAFE-c | NO_ALLOC lines no longer enter the buffer (`pf_nocache` takes the I$'s own `icache_req_is_no_alloc`; `hz_nonalloc_target`). A DIRECT window's code is allocated by the I$ too, so the buffer is no staler than the I$ there; both rely on the platform's whole-L1 flush on bank flips and DMA (`pc9821_iobus.sv` `cache_flush_req`, which holds `pf_flush_kill_r`) |
| RET prediction: `ret_pred_r` vs the requested line; RSB change between D2 and issue; replay path; ownership on interrupt/fault | D2 push to WB | SAFE-c | the requesting and checking value is the same RSB entry; the cycle where the next instruction's issue meets an older CALL/RET is always wrong-path (flushed); replays re-enter EX with `probed_r` and are checked there; a slow path drops ownership. `SPEC OWNER MISMATCH` is a sim fuse, active in every fuzz run |
| `pf_xlat` vs TR6 write cycle | refresh at `tlbt_go` copies the replaced entry | closed by construction in D5 | the second kill at `tlbt_done` (not reproduced in a program: `hz_tr6_pfxlat` passes before and after) |

### L1 caches (`l1_icache`, `l1_cache`, `cache_unit`, `bus_unit`)

| candidate | window | verdict | evidence / test |
|---|---|---|---|
| I$ fill reading memory ahead of an older posted store; three younger patches evict it from the 3-entry `patchq` | D$ wide-fill install cycles leave the bus idle with drains blocked | **DEFECT D4** | `hz_patchq_overrun`; fix holds the I$ request while `storeq_line_hit` |
| Line delivered to the prefetcher (`line_r`) missing an evicted or held patch | fill vs patches | SAFE-c after D4 | an undrained store now blocks the fill; patches that arrive during the fill set `fill_line_snooped_r` and merge; a younger store into in-flight code needs a jump, which refetches |
| Patch in the line-resp / install / deferred-install cycle | install vs tag clear | SAFE-c | live conflict blocks, the registered one defers, `fill_line_snooped_r` sticks |
| Patch to the victim way in the install cycle | over-invalidation only | SAFE-c | |
| D$ fill vs queued stores; narrow beats under a valid victim tag; deferred tag install vs a store | | SAFE-c | merge of every live queue entry; no accept/lookup in S_FILL |
| D$ store forwarding vs fill/snoop; uncached/IO vs posted stores; patch-slot overwrite | | SAFE-c | C3/C5/C9/C15 guards, `direct_req_ordered`, the slot fuse |

### Paging (`paging_unit`, `paging_tlb`, `paging_walker`)

| candidate | window | verdict | evidence / test |
|---|---|---|---|
| Walk install vs INVLPG, same cycle | | SAFE-c | `invlpg_ack` needs idle paging; `tlb_write` gated by `!invalidate_page` |
| Walk vs CR3 write at the install cycle | | SAFE-c / SAFE-t | `walk_stale`; `cr3_walk_race*` |
| Fill vs fill / TR6 to the same set | | SAFE-c | `tlbt_go` waits for updates |
| Sidecar eviction queue, sidecar refill, preread vs mutation | capture C, write C+1 | SAFE-c | `vipt_mutation` poison, epoch; `hz_invlpg_data` |
| `pf_xlat` vs INVLPG/CR3/eviction with a same-cycle refresh | | SAFE-c | kill has priority; `hz_invlpg_code` |
| `rmw_fast_phys_r`, `st_phys`, `ucrd`/`vipt_slow_phys_r` across INVLPG/CR3 | within one instruction | SAFE-c | tokens cleared on flush/fault; `st_take` blocked during `stall_invlpg`; `hz_invlpg_data` kinds 2-5 |
| A/D write-back vs a guest store to the PTE | | SAFE-c | locked re-read and re-check; locked read drains the store queue; `pte_cache_coherence` |
| Shared-index sidecar eviction lost when updates are 1 cycle apart | | latent, unreachable | walks take at least 4 cycles; existing `$fatal` |

### Data fast paths (`data_access`, `data_unit`, `z486.sv` WR_FAST / RMW_FAST / VIPT / ucrd)

| candidate | window | verdict | evidence / test |
|---|---|---|---|
| Direct load sharing the preread of a store the L1 refuses that cycle (patch slot busy / queue full / lookup not granted), released by `mem_write_dly_grace` | share at C, resolve at C+1, store accepted at C+1 | **DEFECT D3** | `hz_vipt_share_unposted`; fix requires the store's acceptance for a share; sim fuse on a resolve of a shared preread without its store in S_LOOKUP |
| Load issued on the edge paging captures an older write | | SAFE-c | `d2_vipt_older_store` discards the preread |
| Miss moved to `vipt_load_slow_r` and replayed | | SAFE-c | submit waits for `!mem_servicing` |
| RMW_FAST read->write; back-to-back RMWs; crossing store then RMW | | SAFE-c / SAFE-t | `hz_rmw_cross_store(_pg)`, `hz_rmw_after_paged_store` |
| WR_FAST vs older slow store/load | | SAFE-c | needs paging idle |
| ucrd capture vs stores | | SAFE-c | probes only with paging idle |
| RET check vs a rewrite of the stack slot | | SAFE-c / SAFE-t | `hz_ret_rewrite(_np)` |
| RMW first uStep stalled after its probe (late `rd_fast_hit`) | | SAFE-t (resolved, see "UNSURE RMW item resolved") | fuse `RMW FIRST-USTEP FINISH WITHOUT ITS OWN PROBE` in `data_access.sv`; never fires; `hz_rmw_late_finish` |

## The fixes

**D1/D5 (`z486.sv`, `paging_unit.sv`).** `pf_spec_tlb_kill = (invlpg_request && invlpg_ack) ||
TR6-write request || tlbt_done` joins `pf_spec_global_kill`. `tlbt_done` was previously
unconnected; it is exported from `paging_unit` and also kills `pf_xlat`. Cost: a refetch after
INVLPG/TR6, which software already pays on a 486.

**D2 (`z486.sv`).** `pf_spec_a20_kill = pf_spec_a20_r != a20_enable`, the first cycle the new gate
value is presented.

**D3 (`l1_cache.sv`).** `vipt_probe_share` now also needs `cpu_valid && cpu_ready &&
can_accept_cpu`. A probe beside a refused store is rejected and replays like any other. The new
term reaches only the CPU's probed-flag flops, not D2 issue.

**D4 (`cache_unit.sv`, `l1_cache.sv`).** `icache_mem_valid` to the bus is held while
`storeq_line_hit`: a queued store in the I$ request's line, or the store enqueuing from S_LOOKUP.
The D$ already wins the bus, so the drain goes first. It costs cycles only when a fetch misses a
line with an undrained store, i.e. self-modifying code.

**Timing note (no fit was run; this lane does not run Quartus).** D3 and D4 add combinational
terms:
- D3 puts the accept cone into `vipt_probe_accepted`, which feeds flops only.
- D4 puts five 28-bit compares, from registers, ahead of the I$ request into `bus_unit`
  arbitration.

Both want a seed-sweep check on the 80 MHz build before they are vendored. D1, D2 and D5 are
OR-terms on an existing registered kill.

## Commits (`cpu-fixes-review`, on `personal/main` `23bdc0c`)

```
8b3db69 tests: smc_spec_demote_rm            326ff23 fix(prefetch): victim line vs a same-cycle store (C24)
1d7aba3 tests: hazard-audit guards (hz_spec_launch_rm, hz_cross_store_rm, hz_invlpg_data/_code,
        hz_tr6_pfxlat, hz_rmw_*, hz_ret_rewrite*, tests/hazard/sweep.py)
19fc2b0 tests: hz_invlpg_spec                2d7cb45 fix(z486): INVLPG kills the buffer (D1)
6a5fb7c tests: hz_spec_a20_rm + obj_dir_bigmem/test-bigmem
                                             5ef52c8 fix(z486): A20 edge kills the buffer (D2)
5f3aa58 tests: hz_vipt_share_unposted        3a586ff fix(l1_cache): share only with an accepted store (D3)
7c0d9d8 tests: hz_patchq_overrun             ba4fd3b fix(cache_unit): I$ fill waits for the drain (D4)
8d89c77 tests: hz_tr6_spec                   f2bc244 fix(z486): TR6 kills the buffer and pf_xlat (D5)
7e7746f / cd63106 / c1f3b54 / 8ee07d9  tests: fuzz_hazard{,_v86,_emm}.py
02d3c03 tests: hz_spec_walk_store            0f089de tests: +spec_check oracle
17afdcd docs: coherency-audit C8, C21-C24
36b57d7 tests: hz_nonalloc_target            413b539 fix(paging_unit): buffer refuses NO_ALLOC lines (lead 1)
ba25b1a tests: hz_spec_dev_reads, hz_spec_walk_abit, +watch_lo/+watch_hi
                                             fac8d54 fix(paging_unit): spec fetch never walks or reads devices (lead 2)
e571bf7 tests: hz_rmw_late_finish, fuzz_hazard.py --rmw
                                             623d0c3 chore(data_access): RMW late-finish fuse (lead 3)
        docs: this report
```

## Gates

- `make -C tests test-release JOBS=4`: **exit 0**.
  - 305/305 protected, all narrow/throttled variants, pc98-map, `test-bigmem` 1/1 x 2,
    x87 314/314.
  - `test-fuzz` 36/36, every unit bench, `check-equiv`.
  - Run on the pre-rebase head (identical RTL). After the rebase the protected suite is
    305/305 again.
- Dhrystone: **254235 cy / 121837 instr / CPI 2.087**, unchanged by every fix (measured after D3
  and after D4).
- `make test-l1-cache`, `test-l1-icache`, `test-cache-coherence`: PASS after D4.

## Fuzzing: volume and coverage

Every run compares a reference against three variants at the seed's memory latency:
- reference: `+z486_fast_off +z486_cache_off`, so no branch-target buffer, VIPT, patch queue or
  sharing;
- variants: fast on; fast off with caches; fast toggled at random (`+z486_fast_toggle=37..997`).

Latency is 0-32, and 30% of runs use narrow fills. Any `$fatal` counts as a mismatch, including
the existing `SPEC OWNER MISMATCH` / D1-window fuses and, in phase 2, `+spec_check`.

| fuzzer | shape | seeds (x4 sims) | result on head |
|---|---|---|---|
| `fuzz_hazard.py` | PM + paging: SMC by every store kind, own/alias linear, line-crossing; Jcc before/after; code/data page remaps with INVLPG/CR3; storms; WBINVD; hot/cold data | phase 1: 2134; phase 2 (+oracle): see below | 0 mismatch |
| `fuzz_hazard_v86.py` | V86 + paging, flat-SS ring-0 monitor, INT 60h window remaps, INT 61h monitor patches guest code, identity stores into window frames; `--irq` | phase 1: 305 (old window layout); phase 2: see below | 0 mismatch |
| `fuzz_hazard_emm.py` | V86 at IOPL 0: every INT/IRET trapped and emulated by the monitor (reflection through the guest IVT); VROOMM overlay stubs patched to `JMP FAR` and entered by an emulated IRET; rotating overlay buffers, unload + scribble; A/D clear + walk sweep; taken/not-taken branches, LOOP, JCXZ, indirect CALL, RET imm16, `XCHG [BP+2]`; `--irq` reflected to a guest handler | phase 2: see below | 0 mismatch |

Phase 2 (head with `+spec_check`) was still running when this report was written. The
integrated series' fuzz volume, gates and performance are in `docs/cpu-fixes-review-2026-10-10.md`.

**Sensitivity:**
- On the RTL before the audit (`326ff23`, and `23bdc0c` before the victim fix),
  `fuzz_hazard.py` mismatched **94 of 300 seeds**.
- Rerun on the four intermediate fix commits, all 94 already pass at `2d7cb45` (D1), so they are
  **all D1 (INVLPG)**.
- The fuzzer did not separate the victim defect, and it does not reach D4: its code lines stay
  warm. `hz_patchq_overrun` covers D4.
- The `+spec_check` oracle stops `hz_invlpg_spec` on the pre-fix RTL at the first stale seed
  (`SPEC STALE: line 00050000 (phys 00061000) byte 1 buffer 11 memory 22`).
- Oracle density: about 3 checked seeded flushes per `fuzz_hazard` seed, about 160 per
  `fuzz_hazard_v86` seed and about 200 per `fuzz_hazard_emm` seed. Each also skips a comparable
  number while stores are in flight.

Run with:
`python3 tests/hazard/fuzz_hazard_emm.py --count N --jobs J [--irq 1200] --keep-fail DIR`.
`--jobs` is capped at 8 unless `FUZZ_ALLOW_WIDE=1`.

## Policenauts status

Hardware facts (pn-stall lane):
- The CPU executes exactly what memory holds at the stub, so the stub's patch and fetch are
  coherent.
- The overlay manager's placement value was wrong earlier.
- Only `pf_spec_req` off (or `hwc` off, which includes it) cures it.

What this lane established against that:
- Every kill path of the buffer was audited (table above). INVLPG/TR6/A20 were the only gaps, and
  under EMM386 every monitor entry and exit changes CPL, which already kills the buffer. That is
  why D1 cannot be the game's defect, and why the V86 fuzzers could not see D1 even on the pre-fix
  RTL.
- Ownership (`spec_owner`, `spec_off`) is guarded by the existing `SPEC OWNER MISMATCH` fuse. No
  run hit it.
- The EMM386/VROOMM shape (IOPL-0 reflection, emulated IRET into a just-written `JMP FAR`,
  rotating overlay buffers, flat-SS monitor RETs, PM IRQ reflection, A/D-bit walks) has run
  without a mismatch or oracle hit.

Open leads, ranked:
1. (closed for NO_ALLOC, see "Lead 1 resolved") The buffer keeps lines that the I$ would not
   allocate (template DIRECT/NO_ALLOC windows):
   - safe only while every non-CPU change to those windows raises the whole-L1 flush;
   - worth a platform-side check that CD-ROM and sound DMA always do.
2. (closed, see "Lead 2 resolved") Speculative target fetches are real bus reads at wrong-path or not-taken targets, including
   RSB-predicted RET targets. On a PC-98 such a read can land in device memory with read side
   effects:
   - the EGC latch, GRCG compare reads;
   - page walks that set A bits on pages the program never touches.
   A 486 has no such fetches. A cheap experiment: refuse spec launches whose translation is not
   cacheable RAM.
3. (closed) The RMW late-finish item: see "UNSURE RMW item resolved".

### Lead 1 resolved (branch `audit-nonalloc`)

- Defect: `pf_nocache`, the buffer's cacheability bit, covered only PTE.PCD and CR0.CD. A line
  fetched from a NO_ALLOC template window (which the I$ does not install) still entered the active
  and victim target slots, and a non-CPU change to it (DMA, bank flip) without the whole-L1 flush
  was replayed stale. A 486 has no such buffer.
- Fail-first: `tests/programs/hz_nonalloc_target` (`make test-pc98-map`; window 0 at 0x80000, a
  not-taken JNE buffers the target, `+xdma_*` rewrites its immediate with no snoop and no flush,
  the next CALL must see the new bytes). FAIL before the fix (returns the stale 0x11223344), PASS
  with `+z486_fast_off`, PASS after.
- Fix: `pf_nocache` also takes `icache_req_is_no_alloc`, the I$'s own classification of the same
  request (`memory` -> `cache_unit` -> `paging_unit`). It is constant 0 without template windows
  and for cacheable RAM, so cacheable code is cycle-neutral.
- Scope: only NO_ALLOC. A DIRECT window's code IS allocated by the I$ (and invalidated on CPU
  writes to it), so there the buffer mirrors the I$ and is no staler than it; the same program
  placed in a DIRECT window fails even with `+z486_fast_off`, i.e. that is the I$'s platform-flush
  contract, not a buffer defect.
- Cost: code executed from a NO_ALLOC window loses the buffer's target hit (loop-backs and
  branch-backs refetch). Trade for the owner; on the PC-9821 that is the window-0 overlay and
  memory above the RAM bound.

The pn-stall lane's capture of the first wrong value should name the instruction shape. That
shape becomes the next directed program here.

## Lead 2 resolved: speculative target fetches no longer walk or read device memory

Fail-first (`tests/programs/hz_spec_dev_reads`, `hz_spec_walk_abit`, and the `+watch_lo/+watch_hi/
+expect_watch_reads` window in `tb_protected_mode`), both FAIL on the old RTL and PASS with
`+z486_fast_off`:
- a not-taken `JNE` to a warm-TLB PCD page made 13 bus reads in the watch window (first at the target
  line, 0x71100); the same branch to the A0000 window made 1 more;
- a not-taken `JNE` to a mapped, never-touched page walked the page tables and set `PTE.A`.

Fix (`paging_unit`, `prefetch`, `cache_unit`/`memory`): the prefetcher exports `pf_spec`
(`spec_inflight`) and the paging unit launches a speculative request only when
- it already has a translation (the one-entry prefetch sidecar or a TLB hit with the user check
  passing). A miss never starts a walker, and a permission fail never records a fault;
- the page is not PCD and CR0.CD is clear;
- the physical address is not in the VGA window (`VGA_BASE..VGA_TOP`) and `cache_unit` calls its
  window class CACHEABLE (`icache_req_spec_ok`: no VGA/aperture/alias/WIN0/NO_ALLOC-bound class, not
  the device-MMIO window).
Otherwise it acks at once with a new `pf_refused` pulse (no data, no fault). The prefetcher drops the
buffer entry, and an adopted fetch (a taken branch whose in-flight spec fetch was refused) is simply
re-requested by the normal `pf_can_fetch` path: no spec flag, so a real fetch may walk. `pf_spec`
falls when a flush adopts the fetch, so a request that waits in paging and then becomes the real
target is not refused.

Hard-wired defaults: with no template window enabled `icache_req_spec_ok` is constant 1, so an
upstream-style build only gains the PCD/CR0.CD/VGA/TLB-hit conditions. The PC-9821 core drives
nothing new: its existing window parameters and `ram_cache_top` are the cacheability map.

Cost: Dhrystone unchanged (254235 cy / 121837 instr / CPI 2.087). The common path is untouched (warm
TLB, cacheable RAM). What now costs a fetch latency, as on a 486: a taken branch whose target page is
not in the TLB (the walk starts after the branch resolves, no longer in its shadow), and a taken
branch into code in a non-cacheable class, such as ROM in a NO_ALLOC window or beyond `ram_cache_top`
(it used to be prefetched into the target buffer). This is a trade for the owner (BIOS ROM
branches are the likely visible case). Timing note: `icache_req_spec_ok` is now an input of
`fast_pf_candidate`, a new combinational path from the window compare into `icache_req_valid`.

Not covered: a mispredicted RET (RSB) is gated by the same check, but cannot be isolated by a
bench, because the predicted return address is the line after the CALL, which a 486's sequential
prefetch also reads (the reference made the same 12 reads). The RSB-predicted fetch in a cold or PCD
page is covered by the generic conditions above.

## UNSURE RMW item resolved

Question: can an RMW_FAST first micro-step stall AFTER its D2 preread was accepted and then finish
(`rd_fast_finish && rd_fast_probed_r`, `data_access.sv`) against another access's preread? The
L1 preread registers reload on every idle cycle (`l1_cache.sv`, `idle_preread`), so a finish later
than the cycle after the RMW's own accepted probe would read foreign data (a tag match from a
different set would pass `vipt_hit_vec`).

Fuse added (`data_access.sv`, simulation only): `RMW FIRST-USTEP FINISH WITHOUT ITS OWN PROBE`
fires if `rd_fast_finish && rd_fast_probed_r` and the previous cycle had no accepted own probe
(`vipt_issue_rmw && dcache_vipt_probe_accepted`, or `rmw_replay_try &&
dcache_vipt_probe_direct_accepted`). It never fired:
- the 305-program suite at `+cpu_speed` 0-3 (about 1100 finishes per speed, all with the probe in
  the cycle before; the only stalled first uSteps seen had `probed=0`, i.e. the replay path, which
  sets the flag together with the accepted probe);
- `hz_rmw_late_finish` (new): 18 predecessor kinds (paging stores, crossing store, load, cold
  fill, RMW, push/pop, string ops, call, OUT, XCHG, same-word store) in front of a run of
  ADD/XOR/LOCK OR/INC/XCHG, latency 0-32, fast on/off, plus `+no_line_fill`, and the three existing
  `hz_rmw_*` programs at 0-32;
- `fuzz_hazard.py --rmw` (new mode: 70% RMW storms, byte/word/dword, LOCK, line- and
  page-crossing, absolute/base/index forms, preceded by loads / stores / cold fills / RMWs / CR3
  reloads), see the counts in the commit message.

Why it cannot happen (RTL): issue of an RMW needs, on registered state, `d2_vipt_rmw`
(`dcache_vipt_probe_ready`, `!ucrd_busy`, `!vipt_load_replay_r.valid`, `!vipt_load_slow_busy`,
`!mem_servicing`, `!rmw_fast_active_r || rmw_store_accepted`) and `d2_ready_base` (`!stall`). A
denied probe never sets `rd_fast_probed_r` and `stall_rmw_probe` holds the word until
`rmw_replay_try` is accepted, which sets the flag in the same edge as the accepted probe. After an
accepted probe the first uStep's only remaining stalls (`uc_slot_live`) are conditions that were
false at issue and have no source in the next cycle: no older request in flight
(`mem_servicing` false at issue), no older load/replay, no older RMW store, no ucrd, and flushes /
faults / interrupts clear `rd_fast_valid_r`. This is a by-observation argument for the
`mem_accepted`-at-issue corner (a predecessor's busop accepted in the issue cycle); no stimulus
reached it, and the fuse stays as the permanent guard.

## Files

- `docs/z486-hazard-audit.md` (this report), `docs/coherency-audit.md` (C8, C21-C24)
- `tests/hazard/`: `sweep.py`, `gen_spec_launch.py`, `fuzz_hazard.py`,
  `fuzz_hazard_v86.py`, `fuzz_hazard_emm.py`
- `tests/programs/hz_*`: the 16 programs named above, plus `hz_rmw_late_finish`
- `tests/tb_protected_mode.sv` `+spec_check`; `tests/Makefile` `obj_dir_bigmem` / `test-bigmem`;
  `tests/test_protected_mode.py` `requires_bigmem`
