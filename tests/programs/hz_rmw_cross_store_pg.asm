; hz_rmw_cross_store_pg - paging on: an RMW_FAST (ADD m32,r) issued in the cycle its
; predecessor's dword-crossing store-imm is captured by paging, to the same first dword.
;
; With paging on the capture claims the L1 preread port (early_idx_drive) and does not post;
; an RMW D2 probe to the same set/word is SHARED (l1_cache vipt_probe_share needs no accepted
; demand). The RMW then stalls in its first uStep while the crossing store's two halves pass
; through the L1; the last preread before paging releases is the SECOND dword, which the
; RMW's resolve (rd_fast_hit / fast_opr_data, evaluated at rd_fast_finish) then consumes.
; Expected (486): dword0 = store bytes over 0x11111111, + 1.
; Trials: store offset k = 1..3, nop padding 0..3; data = bitmask of failing trials.
BITS 32
ORG 0
BUF equ 0x3000
start:
    xor edi, edi
%macro trial 3
    mov dword [BUF], 0x11111111
    mov dword [BUF + 4], 0x22222222
    mov eax, [BUF]
    mov eax, [BUF + 4]
    mov ecx, 1
    times %2 nop
    mov dword [BUF + %1], 0xAABBCCDD   ; crossing store-imm, paging path
    add [BUF], ecx                     ; RMW_FAST on the first dword
    cmp dword [BUF], %3
    je %%ok
    or edi, 1 << ((%1 - 1) * 4 + %2)
%%ok:
%endmacro
%assign p 0
%rep 4
    trial 1, p, 0xBBCCDD12
    trial 2, p, 0xCCDD1112
    trial 3, p, 0xDD111112
%assign p p + 1
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
