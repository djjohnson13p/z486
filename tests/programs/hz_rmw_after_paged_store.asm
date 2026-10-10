; hz_rmw_after_paged_store - paging on: a non-crossing store that takes the PAGING path
; (TLB miss after INVLPG, or a sidecar miss after a load from another page), immediately
; followed by an RMW_FAST to the same dword. The RMW's D2 probe can be SHARED with the
; store's capture (early_idx_drive, no accept) and its first uStep then stalls in the
; store's mem_write_wait; the RMW must still add to the post-store value.
; Trials: mode m (0 = INVLPG first, 1 = other-page load first), store width/offset s
; (0 dword @0, 1 byte @1, 2 word @2), pad 0..3. data = bitmask of failing trials.
BITS 32
ORG 0
BUF equ 0x3000
OTHER equ 0x5000
start:
    xor edi, edi
    xor esi, esi
%macro trial 4              ; mode, store kind, pad, expected
    mov dword [BUF], 0x11111111
    mov eax, [BUF]
    mov ecx, 1
  %if %1 == 0
    invlpg [BUF]
  %else
    mov eax, [OTHER]
  %endif
    times %3 nop
  %if %2 == 0
    mov dword [BUF], 0xAABBCCDD
  %elif %2 == 1
    mov byte [BUF + 1], 0x55
  %else
    mov word [BUF + 2], 0x6677
  %endif
    add [BUF], ecx
    cmp dword [BUF], %4
    je %%ok
    or edi, 1 << (esi_bit)
%%ok:
%endmacro
%assign bitn 0
%assign m 0
%rep 2
%assign p 0
%rep 4
%define esi_bit bitn
    trial m, 0, p, 0xAABBCCDE
%assign bitn bitn + 1
%define esi_bit bitn
    trial m, 1, p, 0x11115512
%assign bitn bitn + 1
%define esi_bit bitn
    trial m, 2, p, 0x66771112
%assign bitn bitn + 1
%assign p p + 1
%endrep
%assign m m + 1
%endrep
    test edi, edi
    jnz fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    mov eax, edi
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
