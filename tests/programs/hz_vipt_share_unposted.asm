; hz_vipt_share_unposted - a VIPT load whose D2 probe is SHARED with an older same-dword store
; that the L1 cannot accept because the I$ store-patch slot is busy (store_patch_busy: an
; external snoop, then the patch it stranded). The store is captured by paging with paging
; off (early write refused), sits in PG_MEM_TLB with mem_write_dly_grace, and its delay slot
; releases the load's D2 issue. l1_cache's vipt_probe_share does not require the demand to be
; accepted, and vipt_lookup_store_match only merges a store already in S_LOOKUP.
; The tb's one-shot +xdma_snoop (armed by the fill read of TRIG, +xdma_delay=N from the sweep)
; supplies the snoop (the chain runs once first so its code is I$-resident and the xdma,
; which waits for an idle read port, can land inside it); a chain of store-hit / store / load triples follows so some triple meets
; it. data = the failing iteration number + 1.
BITS 32
ORG 0
BUF  equ 0x3000
BUF2 equ 0x3040
TRIG equ 0x5100
start:
    mov eax, [BUF]          ; prime both lines
    mov eax, [BUF2]
    mov eax, 0x10000000
    mov ebx, 0
    call chain              ; warm-up pass: the chain's code is I$-resident afterwards
    mov eax, 0x20000000
    mov edx, [TRIG]         ; miss: the fill's read arms the xdma
    call chain
    mov al, 1
    out 0xe0, al
    hlt
chain:
%assign i 0
%rep 64
    mov [BUF2], ebx         ; a store hit: its I$ patch can be stranded by the snoop
    mov [BUF], eax          ; the store the load must see
    mov ecx, [BUF]          ; VIPT load, same dword
    cmp ecx, eax
    jne near fail_%[i]
    inc eax
    times (i % 4) nop
%assign i i + 1
%endrep
    ret
%assign i 0
%rep 64
fail_%[i]:
    mov eax, i + 1
    jmp near fail
%assign i i + 1
%endrep
fail:
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
