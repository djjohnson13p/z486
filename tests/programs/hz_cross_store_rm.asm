; hz_cross_store_rm - a misaligned dword store that ends in the next code line
;
; S's line is warm in the I-cache; a dword store at S - 2 writes the last two
; bytes of the line before and the first two of S's line (S: B8 iw = mov ax,
; imm16; ret). A CALL S must then run the patched code. N = 0..7 NOPs between the
; store and the CALL. Failure data = (N << 16) | AX returned.
BITS 16
ORG 0
start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x8000
    mov ax, cs
    mov ds, ax
%assign n 0
%rep 8
    mov word [S + 1], 0x2211
    call S
    mov dword [S - 2], 0x00b89090 | ((0x22 + n) << 24)
    times n nop
    call S
    cmp ax, 0x2222 + n
    je ok_%+n
    mov dx, n
    jmp fail
ok_%+n:
%assign n n+1
%endrep
    mov al, 1
    out 0xe0, al
    hlt
fail:
    shl edx, 16
    mov dx, ax
    mov eax, edx
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
    align 16
    times 14 nop
    nop
    nop
S:
    mov ax, 0x0000
    ret
