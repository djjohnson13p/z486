; hz_rmw_cross_store - an RMW_FAST (ADD m32,r) issued in the cycle its predecessor's
; dword-crossing store is captured by paging, to the same first dword.
;
; The crossing store claims the L1 preread port (early_idx_drive) at its capture, and an RMW
; D2 probe to the same set/word is SHARED with it. The store's first half is accepted later,
; then its second half (the next dword) - the last preread before paging releases is that
; second dword, while the RMW still resolves in its (stalled) first uStep. A 486 adds to the
; post-store first dword. Trials: store offset k = 1..3, nop padding 0..3.
; Failure data = bitmask of failing trials (bit = (k-1)*4 + pad).
BITS 16
ORG 0
start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x8000
    mov ax, cs
    mov ds, ax
    xor edi, edi

%macro trial 3              ; k, pad, expected dword0
    mov dword [buf], 0x11111111
    mov dword [buf + 4], 0x22222222
    mov eax, [buf]             ; prime the line
    mov eax, [buf + 4]
    mov bx, buf
    mov eax, 0xAABBCCDD
    mov ecx, 1
    mov [scratch + 3], eax     ; a crossing paging write: dcache_req_write_r = 1
    times %2 nop
    mov [bx + %1], eax         ; crossing store, paging path
    add [bx], ecx              ; RMW_FAST on the first dword
    cmp dword [buf], %3
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

    align 16
buf:     dd 0, 0, 0, 0
scratch: dd 0, 0, 0, 0
