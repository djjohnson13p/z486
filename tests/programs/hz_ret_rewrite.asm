; hz_ret_rewrite - a near RET (direct-load RET with an RSB prediction) whose stack slot was
; rewritten by the immediately preceding instruction, so the store and the RET's VIPT probe /
; prediction check land in adjacent cycles. Variants: 0 mov [esp],eax  1 add dword [esp],d
; (RMW_FAST)  2 xchg [esp],eax  3 pop ecx/push eax  4 mov [esp],ax (partial)
; Pads 0..3 shift fetch alignment. The 486 returns to the rewritten target. data = bitmask.
BITS 32
ORG 0
start:
    xor edi, edi
    mov esp, 0x7000
%assign bit 0
%macro rtrial 2
    mov eax, alt_%[bit]
    mov ecx, 0
    mov eax, eax
    call f_%[bit]
ret_%[bit]:
    or edi, 1 << bit
    jmp done_%[bit]
    align 16
f_%[bit]:
    times %2 nop
  %if %1 == 0
    mov [esp], eax
  %elif %1 == 1
    add dword [esp], alt_%[bit] - ret_%[bit]
  %elif %1 == 2
    xchg [esp], eax
  %elif %1 == 3
    pop ecx
    push eax
  %elif %1 == 4
    mov [esp], ax
  %else
    mov byte [esp], al
  %endif
    ret
    align 4
alt_%[bit]:
    nop
done_%[bit]:
%assign bit bit + 1
%endmacro
; variants 4/5 need alt to share the upper bytes with ret: keep the code < 64 KiB / 256 B apart
%assign v 0
%rep 5
%assign p 0
%rep 4
    rtrial v, p
%assign p p + 1
%endrep
%assign v v + 1
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
