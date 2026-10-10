; hz_patchq_overrun - I$ patch queue (3 entries) overrun on a cold, sequentially prefetched
; target line. Generated once by a throwaway script; this file is the source.
;
; Per case (cold code, executed once): slow instructions let the prefetcher run ahead, then
; P stores into the imm8 of `mov al, 0` at T (the next sequential line, not yet requested),
; a cold D$ load Y blocks the posted-store drain while its fill owns the bus (its wide-fill
; install cycles leave the bus idle with drains still blocked, so the prefetcher's fill of T's
; line can launch ahead of P's drain), and X1..X3 store to three other DWORDs while that fill
; is in flight. Execution falls through into T (the 486 allows the stale prefetched bytes
; there), returns, and then CALLs T after a jump: the I-cache line must hold P's byte.
; Failure: port 0xE4 = (count << 16) | (first failing case + 1).
BITS 32
ORG 0
start:
    mov esp, 0x3F000
    xor edi, edi
    mov ecx, 0x12345601
    mov ebx, 3

; case 0: s=0 u=0 m=0
    align 16
    push dword after_0
    mov ebp, 0x10000 + T_0 + 1
    mov esi, 0x40000
    mov edx, 0x60000
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_0:
    mov al, 0
    ret
after_0:
    jmp short $+2
    call T_0
    cmp al, 1
    je ok_0
    add edi, 0x10000
    test di, di
    jnz ok_0
    or edi, 1
ok_0:
; case 1: s=0 u=0 m=1
    align 16
    push dword after_1
    mov ebp, 0x10000 + T_1 + 1
    mov esi, 0x40040
    mov edx, 0x60040
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_1:
    mov al, 0
    ret
after_1:
    jmp short $+2
    call T_1
    cmp al, 1
    je ok_1
    add edi, 0x10000
    test di, di
    jnz ok_1
    or edi, 2
ok_1:
; case 2: s=0 u=1 m=0
    align 16
    push dword after_2
    mov ebp, 0x10000 + T_2 + 1
    mov esi, 0x40080
    mov edx, 0x60080
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_2:
    mov al, 0
    ret
after_2:
    jmp short $+2
    call T_2
    cmp al, 1
    je ok_2
    add edi, 0x10000
    test di, di
    jnz ok_2
    or edi, 3
ok_2:
; case 3: s=0 u=1 m=1
    align 16
    push dword after_3
    mov ebp, 0x10000 + T_3 + 1
    mov esi, 0x400c0
    mov edx, 0x600c0
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_3:
    mov al, 0
    ret
after_3:
    jmp short $+2
    call T_3
    cmp al, 1
    je ok_3
    add edi, 0x10000
    test di, di
    jnz ok_3
    or edi, 4
ok_3:
; case 4: s=0 u=2 m=0
    align 16
    push dword after_4
    mov ebp, 0x10000 + T_4 + 1
    mov esi, 0x40100
    mov edx, 0x60100
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_4:
    mov al, 0
    ret
after_4:
    jmp short $+2
    call T_4
    cmp al, 1
    je ok_4
    add edi, 0x10000
    test di, di
    jnz ok_4
    or edi, 5
ok_4:
; case 5: s=0 u=2 m=1
    align 16
    push dword after_5
    mov ebp, 0x10000 + T_5 + 1
    mov esi, 0x40140
    mov edx, 0x60140
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_5:
    mov al, 0
    ret
after_5:
    jmp short $+2
    call T_5
    cmp al, 1
    je ok_5
    add edi, 0x10000
    test di, di
    jnz ok_5
    or edi, 6
ok_5:
; case 6: s=0 u=3 m=0
    align 16
    push dword after_6
    mov ebp, 0x10000 + T_6 + 1
    mov esi, 0x40180
    mov edx, 0x60180
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_6:
    mov al, 0
    ret
after_6:
    jmp short $+2
    call T_6
    cmp al, 1
    je ok_6
    add edi, 0x10000
    test di, di
    jnz ok_6
    or edi, 7
ok_6:
; case 7: s=0 u=3 m=1
    align 16
    push dword after_7
    mov ebp, 0x10000 + T_7 + 1
    mov esi, 0x401c0
    mov edx, 0x601c0
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_7:
    mov al, 0
    ret
after_7:
    jmp short $+2
    call T_7
    cmp al, 1
    je ok_7
    add edi, 0x10000
    test di, di
    jnz ok_7
    or edi, 8
ok_7:
; case 8: s=0 u=4 m=0
    align 16
    push dword after_8
    mov ebp, 0x10000 + T_8 + 1
    mov esi, 0x40200
    mov edx, 0x60200
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_8:
    mov al, 0
    ret
after_8:
    jmp short $+2
    call T_8
    cmp al, 1
    je ok_8
    add edi, 0x10000
    test di, di
    jnz ok_8
    or edi, 9
ok_8:
; case 9: s=0 u=4 m=1
    align 16
    push dword after_9
    mov ebp, 0x10000 + T_9 + 1
    mov esi, 0x40240
    mov edx, 0x60240
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_9:
    mov al, 0
    ret
after_9:
    jmp short $+2
    call T_9
    cmp al, 1
    je ok_9
    add edi, 0x10000
    test di, di
    jnz ok_9
    or edi, 10
ok_9:
; case 10: s=0 u=5 m=0
    align 16
    push dword after_10
    mov ebp, 0x10000 + T_10 + 1
    mov esi, 0x40280
    mov edx, 0x60280
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_10:
    mov al, 0
    ret
after_10:
    jmp short $+2
    call T_10
    cmp al, 1
    je ok_10
    add edi, 0x10000
    test di, di
    jnz ok_10
    or edi, 11
ok_10:
; case 11: s=0 u=5 m=1
    align 16
    push dword after_11
    mov ebp, 0x10000 + T_11 + 1
    mov esi, 0x402c0
    mov edx, 0x602c0
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_11:
    mov al, 0
    ret
after_11:
    jmp short $+2
    call T_11
    cmp al, 1
    je ok_11
    add edi, 0x10000
    test di, di
    jnz ok_11
    or edi, 12
ok_11:
; case 12: s=0 u=6 m=0
    align 16
    push dword after_12
    mov ebp, 0x10000 + T_12 + 1
    mov esi, 0x40300
    mov edx, 0x60300
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_12:
    mov al, 0
    ret
after_12:
    jmp short $+2
    call T_12
    cmp al, 1
    je ok_12
    add edi, 0x10000
    test di, di
    jnz ok_12
    or edi, 13
ok_12:
; case 13: s=0 u=6 m=1
    align 16
    push dword after_13
    mov ebp, 0x10000 + T_13 + 1
    mov esi, 0x40340
    mov edx, 0x60340
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_13:
    mov al, 0
    ret
after_13:
    jmp short $+2
    call T_13
    cmp al, 1
    je ok_13
    add edi, 0x10000
    test di, di
    jnz ok_13
    or edi, 14
ok_13:
; case 14: s=0 u=7 m=0
    align 16
    push dword after_14
    mov ebp, 0x10000 + T_14 + 1
    mov esi, 0x40380
    mov edx, 0x60380
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_14:
    mov al, 0
    ret
after_14:
    jmp short $+2
    call T_14
    cmp al, 1
    je ok_14
    add edi, 0x10000
    test di, di
    jnz ok_14
    or edi, 15
ok_14:
; case 15: s=0 u=7 m=1
    align 16
    push dword after_15
    mov ebp, 0x10000 + T_15 + 1
    mov esi, 0x403c0
    mov edx, 0x603c0
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_15:
    mov al, 0
    ret
after_15:
    jmp short $+2
    call T_15
    cmp al, 1
    je ok_15
    add edi, 0x10000
    test di, di
    jnz ok_15
    or edi, 16
ok_15:
; case 16: s=0 u=8 m=0
    align 16
    push dword after_16
    mov ebp, 0x10000 + T_16 + 1
    mov esi, 0x40400
    mov edx, 0x60400
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_16:
    mov al, 0
    ret
after_16:
    jmp short $+2
    call T_16
    cmp al, 1
    je ok_16
    add edi, 0x10000
    test di, di
    jnz ok_16
    or edi, 17
ok_16:
; case 17: s=0 u=8 m=1
    align 16
    push dword after_17
    mov ebp, 0x10000 + T_17 + 1
    mov esi, 0x40440
    mov edx, 0x60440
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_17:
    mov al, 0
    ret
after_17:
    jmp short $+2
    call T_17
    cmp al, 1
    je ok_17
    add edi, 0x10000
    test di, di
    jnz ok_17
    or edi, 18
ok_17:
; case 18: s=0 u=9 m=0
    align 16
    push dword after_18
    mov ebp, 0x10000 + T_18 + 1
    mov esi, 0x40480
    mov edx, 0x60480
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_18:
    mov al, 0
    ret
after_18:
    jmp short $+2
    call T_18
    cmp al, 1
    je ok_18
    add edi, 0x10000
    test di, di
    jnz ok_18
    or edi, 19
ok_18:
; case 19: s=0 u=9 m=1
    align 16
    push dword after_19
    mov ebp, 0x10000 + T_19 + 1
    mov esi, 0x404c0
    mov edx, 0x604c0
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_19:
    mov al, 0
    ret
after_19:
    jmp short $+2
    call T_19
    cmp al, 1
    je ok_19
    add edi, 0x10000
    test di, di
    jnz ok_19
    or edi, 20
ok_19:
; case 20: s=0 u=10 m=0
    align 16
    push dword after_20
    mov ebp, 0x10000 + T_20 + 1
    mov esi, 0x40500
    mov edx, 0x60500
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_20:
    mov al, 0
    ret
after_20:
    jmp short $+2
    call T_20
    cmp al, 1
    je ok_20
    add edi, 0x10000
    test di, di
    jnz ok_20
    or edi, 21
ok_20:
; case 21: s=0 u=10 m=1
    align 16
    push dword after_21
    mov ebp, 0x10000 + T_21 + 1
    mov esi, 0x40540
    mov edx, 0x60540
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_21:
    mov al, 0
    ret
after_21:
    jmp short $+2
    call T_21
    cmp al, 1
    je ok_21
    add edi, 0x10000
    test di, di
    jnz ok_21
    or edi, 22
ok_21:
; case 22: s=0 u=11 m=0
    align 16
    push dword after_22
    mov ebp, 0x10000 + T_22 + 1
    mov esi, 0x40580
    mov edx, 0x60580
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_22:
    mov al, 0
    ret
after_22:
    jmp short $+2
    call T_22
    cmp al, 1
    je ok_22
    add edi, 0x10000
    test di, di
    jnz ok_22
    or edi, 23
ok_22:
; case 23: s=0 u=11 m=1
    align 16
    push dword after_23
    mov ebp, 0x10000 + T_23 + 1
    mov esi, 0x405c0
    mov edx, 0x605c0
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_23:
    mov al, 0
    ret
after_23:
    jmp short $+2
    call T_23
    cmp al, 1
    je ok_23
    add edi, 0x10000
    test di, di
    jnz ok_23
    or edi, 24
ok_23:
; case 24: s=0 u=12 m=0
    align 16
    push dword after_24
    mov ebp, 0x10000 + T_24 + 1
    mov esi, 0x40600
    mov edx, 0x60600
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_24:
    mov al, 0
    ret
after_24:
    jmp short $+2
    call T_24
    cmp al, 1
    je ok_24
    add edi, 0x10000
    test di, di
    jnz ok_24
    or edi, 25
ok_24:
; case 25: s=0 u=12 m=1
    align 16
    push dword after_25
    mov ebp, 0x10000 + T_25 + 1
    mov esi, 0x40640
    mov edx, 0x60640
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_25:
    mov al, 0
    ret
after_25:
    jmp short $+2
    call T_25
    cmp al, 1
    je ok_25
    add edi, 0x10000
    test di, di
    jnz ok_25
    or edi, 26
ok_25:
; case 26: s=0 u=13 m=0
    align 16
    push dword after_26
    mov ebp, 0x10000 + T_26 + 1
    mov esi, 0x40680
    mov edx, 0x60680
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_26:
    mov al, 0
    ret
after_26:
    jmp short $+2
    call T_26
    cmp al, 1
    je ok_26
    add edi, 0x10000
    test di, di
    jnz ok_26
    or edi, 27
ok_26:
; case 27: s=0 u=13 m=1
    align 16
    push dword after_27
    mov ebp, 0x10000 + T_27 + 1
    mov esi, 0x406c0
    mov edx, 0x606c0
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_27:
    mov al, 0
    ret
after_27:
    jmp short $+2
    call T_27
    cmp al, 1
    je ok_27
    add edi, 0x10000
    test di, di
    jnz ok_27
    or edi, 28
ok_27:
; case 28: s=0 u=14 m=0
    align 16
    push dword after_28
    mov ebp, 0x10000 + T_28 + 1
    mov esi, 0x40700
    mov edx, 0x60700
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_28:
    mov al, 0
    ret
after_28:
    jmp short $+2
    call T_28
    cmp al, 1
    je ok_28
    add edi, 0x10000
    test di, di
    jnz ok_28
    or edi, 29
ok_28:
; case 29: s=0 u=14 m=1
    align 16
    push dword after_29
    mov ebp, 0x10000 + T_29 + 1
    mov esi, 0x40740
    mov edx, 0x60740
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_29:
    mov al, 0
    ret
after_29:
    jmp short $+2
    call T_29
    cmp al, 1
    je ok_29
    add edi, 0x10000
    test di, di
    jnz ok_29
    or edi, 30
ok_29:
; case 30: s=0 u=15 m=0
    align 16
    push dword after_30
    mov ebp, 0x10000 + T_30 + 1
    mov esi, 0x40780
    mov edx, 0x60780
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_30:
    mov al, 0
    ret
after_30:
    jmp short $+2
    call T_30
    cmp al, 1
    je ok_30
    add edi, 0x10000
    test di, di
    jnz ok_30
    or edi, 31
ok_30:
; case 31: s=0 u=15 m=1
    align 16
    push dword after_31
    mov ebp, 0x10000 + T_31 + 1
    mov esi, 0x407c0
    mov edx, 0x607c0
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_31:
    mov al, 0
    ret
after_31:
    jmp short $+2
    call T_31
    cmp al, 1
    je ok_31
    add edi, 0x10000
    test di, di
    jnz ok_31
    or edi, 32
ok_31:
; case 32: s=0 u=16 m=0
    align 16
    push dword after_32
    mov ebp, 0x10000 + T_32 + 1
    mov esi, 0x40800
    mov edx, 0x60800
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_32:
    mov al, 0
    ret
after_32:
    jmp short $+2
    call T_32
    cmp al, 1
    je ok_32
    add edi, 0x10000
    test di, di
    jnz ok_32
    or edi, 33
ok_32:
; case 33: s=0 u=16 m=1
    align 16
    push dword after_33
    mov ebp, 0x10000 + T_33 + 1
    mov esi, 0x40840
    mov edx, 0x60840
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_33:
    mov al, 0
    ret
after_33:
    jmp short $+2
    call T_33
    cmp al, 1
    je ok_33
    add edi, 0x10000
    test di, di
    jnz ok_33
    or edi, 34
ok_33:
; case 34: s=0 u=17 m=0
    align 16
    push dword after_34
    mov ebp, 0x10000 + T_34 + 1
    mov esi, 0x40880
    mov edx, 0x60880
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_34:
    mov al, 0
    ret
after_34:
    jmp short $+2
    call T_34
    cmp al, 1
    je ok_34
    add edi, 0x10000
    test di, di
    jnz ok_34
    or edi, 35
ok_34:
; case 35: s=0 u=17 m=1
    align 16
    push dword after_35
    mov ebp, 0x10000 + T_35 + 1
    mov esi, 0x408c0
    mov edx, 0x608c0
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_35:
    mov al, 0
    ret
after_35:
    jmp short $+2
    call T_35
    cmp al, 1
    je ok_35
    add edi, 0x10000
    test di, di
    jnz ok_35
    or edi, 36
ok_35:
; case 36: s=0 u=18 m=0
    align 16
    push dword after_36
    mov ebp, 0x10000 + T_36 + 1
    mov esi, 0x40900
    mov edx, 0x60900
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_36:
    mov al, 0
    ret
after_36:
    jmp short $+2
    call T_36
    cmp al, 1
    je ok_36
    add edi, 0x10000
    test di, di
    jnz ok_36
    or edi, 37
ok_36:
; case 37: s=0 u=18 m=1
    align 16
    push dword after_37
    mov ebp, 0x10000 + T_37 + 1
    mov esi, 0x40940
    mov edx, 0x60940
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_37:
    mov al, 0
    ret
after_37:
    jmp short $+2
    call T_37
    cmp al, 1
    je ok_37
    add edi, 0x10000
    test di, di
    jnz ok_37
    or edi, 38
ok_37:
; case 38: s=0 u=19 m=0
    align 16
    push dword after_38
    mov ebp, 0x10000 + T_38 + 1
    mov esi, 0x40980
    mov edx, 0x60980
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_38:
    mov al, 0
    ret
after_38:
    jmp short $+2
    call T_38
    cmp al, 1
    je ok_38
    add edi, 0x10000
    test di, di
    jnz ok_38
    or edi, 39
ok_38:
; case 39: s=0 u=19 m=1
    align 16
    push dword after_39
    mov ebp, 0x10000 + T_39 + 1
    mov esi, 0x409c0
    mov edx, 0x609c0
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_39:
    mov al, 0
    ret
after_39:
    jmp short $+2
    call T_39
    cmp al, 1
    je ok_39
    add edi, 0x10000
    test di, di
    jnz ok_39
    or edi, 40
ok_39:
; case 40: s=0 u=20 m=0
    align 16
    push dword after_40
    mov ebp, 0x10000 + T_40 + 1
    mov esi, 0x40a00
    mov edx, 0x60a00
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_40:
    mov al, 0
    ret
after_40:
    jmp short $+2
    call T_40
    cmp al, 1
    je ok_40
    add edi, 0x10000
    test di, di
    jnz ok_40
    or edi, 41
ok_40:
; case 41: s=0 u=20 m=1
    align 16
    push dword after_41
    mov ebp, 0x10000 + T_41 + 1
    mov esi, 0x40a40
    mov edx, 0x60a40
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_41:
    mov al, 0
    ret
after_41:
    jmp short $+2
    call T_41
    cmp al, 1
    je ok_41
    add edi, 0x10000
    test di, di
    jnz ok_41
    or edi, 42
ok_41:
; case 42: s=0 u=21 m=0
    align 16
    push dword after_42
    mov ebp, 0x10000 + T_42 + 1
    mov esi, 0x40a80
    mov edx, 0x60a80
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_42:
    mov al, 0
    ret
after_42:
    jmp short $+2
    call T_42
    cmp al, 1
    je ok_42
    add edi, 0x10000
    test di, di
    jnz ok_42
    or edi, 43
ok_42:
; case 43: s=0 u=21 m=1
    align 16
    push dword after_43
    mov ebp, 0x10000 + T_43 + 1
    mov esi, 0x40ac0
    mov edx, 0x60ac0
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_43:
    mov al, 0
    ret
after_43:
    jmp short $+2
    call T_43
    cmp al, 1
    je ok_43
    add edi, 0x10000
    test di, di
    jnz ok_43
    or edi, 44
ok_43:
; case 44: s=0 u=22 m=0
    align 16
    push dword after_44
    mov ebp, 0x10000 + T_44 + 1
    mov esi, 0x40b00
    mov edx, 0x60b00
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_44:
    mov al, 0
    ret
after_44:
    jmp short $+2
    call T_44
    cmp al, 1
    je ok_44
    add edi, 0x10000
    test di, di
    jnz ok_44
    or edi, 45
ok_44:
; case 45: s=0 u=22 m=1
    align 16
    push dword after_45
    mov ebp, 0x10000 + T_45 + 1
    mov esi, 0x40b40
    mov edx, 0x60b40
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_45:
    mov al, 0
    ret
after_45:
    jmp short $+2
    call T_45
    cmp al, 1
    je ok_45
    add edi, 0x10000
    test di, di
    jnz ok_45
    or edi, 46
ok_45:
; case 46: s=0 u=23 m=0
    align 16
    push dword after_46
    mov ebp, 0x10000 + T_46 + 1
    mov esi, 0x40b80
    mov edx, 0x60b80
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_46:
    mov al, 0
    ret
after_46:
    jmp short $+2
    call T_46
    cmp al, 1
    je ok_46
    add edi, 0x10000
    test di, di
    jnz ok_46
    or edi, 47
ok_46:
; case 47: s=0 u=23 m=1
    align 16
    push dword after_47
    mov ebp, 0x10000 + T_47 + 1
    mov esi, 0x40bc0
    mov edx, 0x60bc0
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_47:
    mov al, 0
    ret
after_47:
    jmp short $+2
    call T_47
    cmp al, 1
    je ok_47
    add edi, 0x10000
    test di, di
    jnz ok_47
    or edi, 48
ok_47:
; case 48: s=2 u=0 m=0
    align 16
    push dword after_48
    mov ebp, 0x10000 + T_48 + 1
    mov esi, 0x40c00
    mov edx, 0x60c00
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_48:
    mov al, 0
    ret
after_48:
    jmp short $+2
    call T_48
    cmp al, 1
    je ok_48
    add edi, 0x10000
    test di, di
    jnz ok_48
    or edi, 49
ok_48:
; case 49: s=2 u=0 m=1
    align 16
    push dword after_49
    mov ebp, 0x10000 + T_49 + 1
    mov esi, 0x40c40
    mov edx, 0x60c40
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_49:
    mov al, 0
    ret
after_49:
    jmp short $+2
    call T_49
    cmp al, 1
    je ok_49
    add edi, 0x10000
    test di, di
    jnz ok_49
    or edi, 50
ok_49:
; case 50: s=2 u=1 m=0
    align 16
    push dword after_50
    mov ebp, 0x10000 + T_50 + 1
    mov esi, 0x40c80
    mov edx, 0x60c80
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_50:
    mov al, 0
    ret
after_50:
    jmp short $+2
    call T_50
    cmp al, 1
    je ok_50
    add edi, 0x10000
    test di, di
    jnz ok_50
    or edi, 51
ok_50:
; case 51: s=2 u=1 m=1
    align 16
    push dword after_51
    mov ebp, 0x10000 + T_51 + 1
    mov esi, 0x40cc0
    mov edx, 0x60cc0
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_51:
    mov al, 0
    ret
after_51:
    jmp short $+2
    call T_51
    cmp al, 1
    je ok_51
    add edi, 0x10000
    test di, di
    jnz ok_51
    or edi, 52
ok_51:
; case 52: s=2 u=2 m=0
    align 16
    push dword after_52
    mov ebp, 0x10000 + T_52 + 1
    mov esi, 0x40d00
    mov edx, 0x60d00
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_52:
    mov al, 0
    ret
after_52:
    jmp short $+2
    call T_52
    cmp al, 1
    je ok_52
    add edi, 0x10000
    test di, di
    jnz ok_52
    or edi, 53
ok_52:
; case 53: s=2 u=2 m=1
    align 16
    push dword after_53
    mov ebp, 0x10000 + T_53 + 1
    mov esi, 0x40d40
    mov edx, 0x60d40
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_53:
    mov al, 0
    ret
after_53:
    jmp short $+2
    call T_53
    cmp al, 1
    je ok_53
    add edi, 0x10000
    test di, di
    jnz ok_53
    or edi, 54
ok_53:
; case 54: s=2 u=3 m=0
    align 16
    push dword after_54
    mov ebp, 0x10000 + T_54 + 1
    mov esi, 0x40d80
    mov edx, 0x60d80
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_54:
    mov al, 0
    ret
after_54:
    jmp short $+2
    call T_54
    cmp al, 1
    je ok_54
    add edi, 0x10000
    test di, di
    jnz ok_54
    or edi, 55
ok_54:
; case 55: s=2 u=3 m=1
    align 16
    push dword after_55
    mov ebp, 0x10000 + T_55 + 1
    mov esi, 0x40dc0
    mov edx, 0x60dc0
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_55:
    mov al, 0
    ret
after_55:
    jmp short $+2
    call T_55
    cmp al, 1
    je ok_55
    add edi, 0x10000
    test di, di
    jnz ok_55
    or edi, 56
ok_55:
; case 56: s=2 u=4 m=0
    align 16
    push dword after_56
    mov ebp, 0x10000 + T_56 + 1
    mov esi, 0x40e00
    mov edx, 0x60e00
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_56:
    mov al, 0
    ret
after_56:
    jmp short $+2
    call T_56
    cmp al, 1
    je ok_56
    add edi, 0x10000
    test di, di
    jnz ok_56
    or edi, 57
ok_56:
; case 57: s=2 u=4 m=1
    align 16
    push dword after_57
    mov ebp, 0x10000 + T_57 + 1
    mov esi, 0x40e40
    mov edx, 0x60e40
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_57:
    mov al, 0
    ret
after_57:
    jmp short $+2
    call T_57
    cmp al, 1
    je ok_57
    add edi, 0x10000
    test di, di
    jnz ok_57
    or edi, 58
ok_57:
; case 58: s=2 u=5 m=0
    align 16
    push dword after_58
    mov ebp, 0x10000 + T_58 + 1
    mov esi, 0x40e80
    mov edx, 0x60e80
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_58:
    mov al, 0
    ret
after_58:
    jmp short $+2
    call T_58
    cmp al, 1
    je ok_58
    add edi, 0x10000
    test di, di
    jnz ok_58
    or edi, 59
ok_58:
; case 59: s=2 u=5 m=1
    align 16
    push dword after_59
    mov ebp, 0x10000 + T_59 + 1
    mov esi, 0x40ec0
    mov edx, 0x60ec0
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_59:
    mov al, 0
    ret
after_59:
    jmp short $+2
    call T_59
    cmp al, 1
    je ok_59
    add edi, 0x10000
    test di, di
    jnz ok_59
    or edi, 60
ok_59:
; case 60: s=2 u=6 m=0
    align 16
    push dword after_60
    mov ebp, 0x10000 + T_60 + 1
    mov esi, 0x40f00
    mov edx, 0x60f00
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_60:
    mov al, 0
    ret
after_60:
    jmp short $+2
    call T_60
    cmp al, 1
    je ok_60
    add edi, 0x10000
    test di, di
    jnz ok_60
    or edi, 61
ok_60:
; case 61: s=2 u=6 m=1
    align 16
    push dword after_61
    mov ebp, 0x10000 + T_61 + 1
    mov esi, 0x40f40
    mov edx, 0x60f40
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_61:
    mov al, 0
    ret
after_61:
    jmp short $+2
    call T_61
    cmp al, 1
    je ok_61
    add edi, 0x10000
    test di, di
    jnz ok_61
    or edi, 62
ok_61:
; case 62: s=2 u=7 m=0
    align 16
    push dword after_62
    mov ebp, 0x10000 + T_62 + 1
    mov esi, 0x40f80
    mov edx, 0x60f80
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_62:
    mov al, 0
    ret
after_62:
    jmp short $+2
    call T_62
    cmp al, 1
    je ok_62
    add edi, 0x10000
    test di, di
    jnz ok_62
    or edi, 63
ok_62:
; case 63: s=2 u=7 m=1
    align 16
    push dword after_63
    mov ebp, 0x10000 + T_63 + 1
    mov esi, 0x40fc0
    mov edx, 0x60fc0
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_63:
    mov al, 0
    ret
after_63:
    jmp short $+2
    call T_63
    cmp al, 1
    je ok_63
    add edi, 0x10000
    test di, di
    jnz ok_63
    or edi, 64
ok_63:
; case 64: s=2 u=8 m=0
    align 16
    push dword after_64
    mov ebp, 0x10000 + T_64 + 1
    mov esi, 0x41000
    mov edx, 0x61000
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_64:
    mov al, 0
    ret
after_64:
    jmp short $+2
    call T_64
    cmp al, 1
    je ok_64
    add edi, 0x10000
    test di, di
    jnz ok_64
    or edi, 65
ok_64:
; case 65: s=2 u=8 m=1
    align 16
    push dword after_65
    mov ebp, 0x10000 + T_65 + 1
    mov esi, 0x41040
    mov edx, 0x61040
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_65:
    mov al, 0
    ret
after_65:
    jmp short $+2
    call T_65
    cmp al, 1
    je ok_65
    add edi, 0x10000
    test di, di
    jnz ok_65
    or edi, 66
ok_65:
; case 66: s=2 u=9 m=0
    align 16
    push dword after_66
    mov ebp, 0x10000 + T_66 + 1
    mov esi, 0x41080
    mov edx, 0x61080
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_66:
    mov al, 0
    ret
after_66:
    jmp short $+2
    call T_66
    cmp al, 1
    je ok_66
    add edi, 0x10000
    test di, di
    jnz ok_66
    or edi, 67
ok_66:
; case 67: s=2 u=9 m=1
    align 16
    push dword after_67
    mov ebp, 0x10000 + T_67 + 1
    mov esi, 0x410c0
    mov edx, 0x610c0
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_67:
    mov al, 0
    ret
after_67:
    jmp short $+2
    call T_67
    cmp al, 1
    je ok_67
    add edi, 0x10000
    test di, di
    jnz ok_67
    or edi, 68
ok_67:
; case 68: s=2 u=10 m=0
    align 16
    push dword after_68
    mov ebp, 0x10000 + T_68 + 1
    mov esi, 0x41100
    mov edx, 0x61100
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_68:
    mov al, 0
    ret
after_68:
    jmp short $+2
    call T_68
    cmp al, 1
    je ok_68
    add edi, 0x10000
    test di, di
    jnz ok_68
    or edi, 69
ok_68:
; case 69: s=2 u=10 m=1
    align 16
    push dword after_69
    mov ebp, 0x10000 + T_69 + 1
    mov esi, 0x41140
    mov edx, 0x61140
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_69:
    mov al, 0
    ret
after_69:
    jmp short $+2
    call T_69
    cmp al, 1
    je ok_69
    add edi, 0x10000
    test di, di
    jnz ok_69
    or edi, 70
ok_69:
; case 70: s=2 u=11 m=0
    align 16
    push dword after_70
    mov ebp, 0x10000 + T_70 + 1
    mov esi, 0x41180
    mov edx, 0x61180
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_70:
    mov al, 0
    ret
after_70:
    jmp short $+2
    call T_70
    cmp al, 1
    je ok_70
    add edi, 0x10000
    test di, di
    jnz ok_70
    or edi, 71
ok_70:
; case 71: s=2 u=11 m=1
    align 16
    push dword after_71
    mov ebp, 0x10000 + T_71 + 1
    mov esi, 0x411c0
    mov edx, 0x611c0
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_71:
    mov al, 0
    ret
after_71:
    jmp short $+2
    call T_71
    cmp al, 1
    je ok_71
    add edi, 0x10000
    test di, di
    jnz ok_71
    or edi, 72
ok_71:
; case 72: s=2 u=12 m=0
    align 16
    push dword after_72
    mov ebp, 0x10000 + T_72 + 1
    mov esi, 0x41200
    mov edx, 0x61200
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_72:
    mov al, 0
    ret
after_72:
    jmp short $+2
    call T_72
    cmp al, 1
    je ok_72
    add edi, 0x10000
    test di, di
    jnz ok_72
    or edi, 73
ok_72:
; case 73: s=2 u=12 m=1
    align 16
    push dword after_73
    mov ebp, 0x10000 + T_73 + 1
    mov esi, 0x41240
    mov edx, 0x61240
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_73:
    mov al, 0
    ret
after_73:
    jmp short $+2
    call T_73
    cmp al, 1
    je ok_73
    add edi, 0x10000
    test di, di
    jnz ok_73
    or edi, 74
ok_73:
; case 74: s=2 u=13 m=0
    align 16
    push dword after_74
    mov ebp, 0x10000 + T_74 + 1
    mov esi, 0x41280
    mov edx, 0x61280
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_74:
    mov al, 0
    ret
after_74:
    jmp short $+2
    call T_74
    cmp al, 1
    je ok_74
    add edi, 0x10000
    test di, di
    jnz ok_74
    or edi, 75
ok_74:
; case 75: s=2 u=13 m=1
    align 16
    push dword after_75
    mov ebp, 0x10000 + T_75 + 1
    mov esi, 0x412c0
    mov edx, 0x612c0
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_75:
    mov al, 0
    ret
after_75:
    jmp short $+2
    call T_75
    cmp al, 1
    je ok_75
    add edi, 0x10000
    test di, di
    jnz ok_75
    or edi, 76
ok_75:
; case 76: s=2 u=14 m=0
    align 16
    push dword after_76
    mov ebp, 0x10000 + T_76 + 1
    mov esi, 0x41300
    mov edx, 0x61300
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_76:
    mov al, 0
    ret
after_76:
    jmp short $+2
    call T_76
    cmp al, 1
    je ok_76
    add edi, 0x10000
    test di, di
    jnz ok_76
    or edi, 77
ok_76:
; case 77: s=2 u=14 m=1
    align 16
    push dword after_77
    mov ebp, 0x10000 + T_77 + 1
    mov esi, 0x41340
    mov edx, 0x61340
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_77:
    mov al, 0
    ret
after_77:
    jmp short $+2
    call T_77
    cmp al, 1
    je ok_77
    add edi, 0x10000
    test di, di
    jnz ok_77
    or edi, 78
ok_77:
; case 78: s=2 u=15 m=0
    align 16
    push dword after_78
    mov ebp, 0x10000 + T_78 + 1
    mov esi, 0x41380
    mov edx, 0x61380
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_78:
    mov al, 0
    ret
after_78:
    jmp short $+2
    call T_78
    cmp al, 1
    je ok_78
    add edi, 0x10000
    test di, di
    jnz ok_78
    or edi, 79
ok_78:
; case 79: s=2 u=15 m=1
    align 16
    push dword after_79
    mov ebp, 0x10000 + T_79 + 1
    mov esi, 0x413c0
    mov edx, 0x613c0
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_79:
    mov al, 0
    ret
after_79:
    jmp short $+2
    call T_79
    cmp al, 1
    je ok_79
    add edi, 0x10000
    test di, di
    jnz ok_79
    or edi, 80
ok_79:
; case 80: s=2 u=16 m=0
    align 16
    push dword after_80
    mov ebp, 0x10000 + T_80 + 1
    mov esi, 0x41400
    mov edx, 0x61400
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_80:
    mov al, 0
    ret
after_80:
    jmp short $+2
    call T_80
    cmp al, 1
    je ok_80
    add edi, 0x10000
    test di, di
    jnz ok_80
    or edi, 81
ok_80:
; case 81: s=2 u=16 m=1
    align 16
    push dword after_81
    mov ebp, 0x10000 + T_81 + 1
    mov esi, 0x41440
    mov edx, 0x61440
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_81:
    mov al, 0
    ret
after_81:
    jmp short $+2
    call T_81
    cmp al, 1
    je ok_81
    add edi, 0x10000
    test di, di
    jnz ok_81
    or edi, 82
ok_81:
; case 82: s=2 u=17 m=0
    align 16
    push dword after_82
    mov ebp, 0x10000 + T_82 + 1
    mov esi, 0x41480
    mov edx, 0x61480
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_82:
    mov al, 0
    ret
after_82:
    jmp short $+2
    call T_82
    cmp al, 1
    je ok_82
    add edi, 0x10000
    test di, di
    jnz ok_82
    or edi, 83
ok_82:
; case 83: s=2 u=17 m=1
    align 16
    push dword after_83
    mov ebp, 0x10000 + T_83 + 1
    mov esi, 0x414c0
    mov edx, 0x614c0
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_83:
    mov al, 0
    ret
after_83:
    jmp short $+2
    call T_83
    cmp al, 1
    je ok_83
    add edi, 0x10000
    test di, di
    jnz ok_83
    or edi, 84
ok_83:
; case 84: s=2 u=18 m=0
    align 16
    push dword after_84
    mov ebp, 0x10000 + T_84 + 1
    mov esi, 0x41500
    mov edx, 0x61500
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_84:
    mov al, 0
    ret
after_84:
    jmp short $+2
    call T_84
    cmp al, 1
    je ok_84
    add edi, 0x10000
    test di, di
    jnz ok_84
    or edi, 85
ok_84:
; case 85: s=2 u=18 m=1
    align 16
    push dword after_85
    mov ebp, 0x10000 + T_85 + 1
    mov esi, 0x41540
    mov edx, 0x61540
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_85:
    mov al, 0
    ret
after_85:
    jmp short $+2
    call T_85
    cmp al, 1
    je ok_85
    add edi, 0x10000
    test di, di
    jnz ok_85
    or edi, 86
ok_85:
; case 86: s=2 u=19 m=0
    align 16
    push dword after_86
    mov ebp, 0x10000 + T_86 + 1
    mov esi, 0x41580
    mov edx, 0x61580
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_86:
    mov al, 0
    ret
after_86:
    jmp short $+2
    call T_86
    cmp al, 1
    je ok_86
    add edi, 0x10000
    test di, di
    jnz ok_86
    or edi, 87
ok_86:
; case 87: s=2 u=19 m=1
    align 16
    push dword after_87
    mov ebp, 0x10000 + T_87 + 1
    mov esi, 0x415c0
    mov edx, 0x615c0
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_87:
    mov al, 0
    ret
after_87:
    jmp short $+2
    call T_87
    cmp al, 1
    je ok_87
    add edi, 0x10000
    test di, di
    jnz ok_87
    or edi, 88
ok_87:
; case 88: s=2 u=20 m=0
    align 16
    push dword after_88
    mov ebp, 0x10000 + T_88 + 1
    mov esi, 0x41600
    mov edx, 0x61600
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_88:
    mov al, 0
    ret
after_88:
    jmp short $+2
    call T_88
    cmp al, 1
    je ok_88
    add edi, 0x10000
    test di, di
    jnz ok_88
    or edi, 89
ok_88:
; case 89: s=2 u=20 m=1
    align 16
    push dword after_89
    mov ebp, 0x10000 + T_89 + 1
    mov esi, 0x41640
    mov edx, 0x61640
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_89:
    mov al, 0
    ret
after_89:
    jmp short $+2
    call T_89
    cmp al, 1
    je ok_89
    add edi, 0x10000
    test di, di
    jnz ok_89
    or edi, 90
ok_89:
; case 90: s=2 u=21 m=0
    align 16
    push dword after_90
    mov ebp, 0x10000 + T_90 + 1
    mov esi, 0x41680
    mov edx, 0x61680
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_90:
    mov al, 0
    ret
after_90:
    jmp short $+2
    call T_90
    cmp al, 1
    je ok_90
    add edi, 0x10000
    test di, di
    jnz ok_90
    or edi, 91
ok_90:
; case 91: s=2 u=21 m=1
    align 16
    push dword after_91
    mov ebp, 0x10000 + T_91 + 1
    mov esi, 0x416c0
    mov edx, 0x616c0
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_91:
    mov al, 0
    ret
after_91:
    jmp short $+2
    call T_91
    cmp al, 1
    je ok_91
    add edi, 0x10000
    test di, di
    jnz ok_91
    or edi, 92
ok_91:
; case 92: s=2 u=22 m=0
    align 16
    push dword after_92
    mov ebp, 0x10000 + T_92 + 1
    mov esi, 0x41700
    mov edx, 0x61700
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_92:
    mov al, 0
    ret
after_92:
    jmp short $+2
    call T_92
    cmp al, 1
    je ok_92
    add edi, 0x10000
    test di, di
    jnz ok_92
    or edi, 93
ok_92:
; case 93: s=2 u=22 m=1
    align 16
    push dword after_93
    mov ebp, 0x10000 + T_93 + 1
    mov esi, 0x41740
    mov edx, 0x61740
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_93:
    mov al, 0
    ret
after_93:
    jmp short $+2
    call T_93
    cmp al, 1
    je ok_93
    add edi, 0x10000
    test di, di
    jnz ok_93
    or edi, 94
ok_93:
; case 94: s=2 u=23 m=0
    align 16
    push dword after_94
    mov ebp, 0x10000 + T_94 + 1
    mov esi, 0x41780
    mov edx, 0x61780
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_94:
    mov al, 0
    ret
after_94:
    jmp short $+2
    call T_94
    cmp al, 1
    je ok_94
    add edi, 0x10000
    test di, di
    jnz ok_94
    or edi, 95
ok_94:
; case 95: s=2 u=23 m=1
    align 16
    push dword after_95
    mov ebp, 0x10000 + T_95 + 1
    mov esi, 0x417c0
    mov edx, 0x617c0
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_95:
    mov al, 0
    ret
after_95:
    jmp short $+2
    call T_95
    cmp al, 1
    je ok_95
    add edi, 0x10000
    test di, di
    jnz ok_95
    or edi, 96
ok_95:
; case 96: s=4 u=0 m=0
    align 16
    push dword after_96
    mov ebp, 0x10000 + T_96 + 1
    mov esi, 0x41800
    mov edx, 0x61800
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_96:
    mov al, 0
    ret
after_96:
    jmp short $+2
    call T_96
    cmp al, 1
    je ok_96
    add edi, 0x10000
    test di, di
    jnz ok_96
    or edi, 97
ok_96:
; case 97: s=4 u=0 m=1
    align 16
    push dword after_97
    mov ebp, 0x10000 + T_97 + 1
    mov esi, 0x41840
    mov edx, 0x61840
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_97:
    mov al, 0
    ret
after_97:
    jmp short $+2
    call T_97
    cmp al, 1
    je ok_97
    add edi, 0x10000
    test di, di
    jnz ok_97
    or edi, 98
ok_97:
; case 98: s=4 u=1 m=0
    align 16
    push dword after_98
    mov ebp, 0x10000 + T_98 + 1
    mov esi, 0x41880
    mov edx, 0x61880
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_98:
    mov al, 0
    ret
after_98:
    jmp short $+2
    call T_98
    cmp al, 1
    je ok_98
    add edi, 0x10000
    test di, di
    jnz ok_98
    or edi, 99
ok_98:
; case 99: s=4 u=1 m=1
    align 16
    push dword after_99
    mov ebp, 0x10000 + T_99 + 1
    mov esi, 0x418c0
    mov edx, 0x618c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_99:
    mov al, 0
    ret
after_99:
    jmp short $+2
    call T_99
    cmp al, 1
    je ok_99
    add edi, 0x10000
    test di, di
    jnz ok_99
    or edi, 100
ok_99:
; case 100: s=4 u=2 m=0
    align 16
    push dword after_100
    mov ebp, 0x10000 + T_100 + 1
    mov esi, 0x41900
    mov edx, 0x61900
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_100:
    mov al, 0
    ret
after_100:
    jmp short $+2
    call T_100
    cmp al, 1
    je ok_100
    add edi, 0x10000
    test di, di
    jnz ok_100
    or edi, 101
ok_100:
; case 101: s=4 u=2 m=1
    align 16
    push dword after_101
    mov ebp, 0x10000 + T_101 + 1
    mov esi, 0x41940
    mov edx, 0x61940
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_101:
    mov al, 0
    ret
after_101:
    jmp short $+2
    call T_101
    cmp al, 1
    je ok_101
    add edi, 0x10000
    test di, di
    jnz ok_101
    or edi, 102
ok_101:
; case 102: s=4 u=3 m=0
    align 16
    push dword after_102
    mov ebp, 0x10000 + T_102 + 1
    mov esi, 0x41980
    mov edx, 0x61980
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_102:
    mov al, 0
    ret
after_102:
    jmp short $+2
    call T_102
    cmp al, 1
    je ok_102
    add edi, 0x10000
    test di, di
    jnz ok_102
    or edi, 103
ok_102:
; case 103: s=4 u=3 m=1
    align 16
    push dword after_103
    mov ebp, 0x10000 + T_103 + 1
    mov esi, 0x419c0
    mov edx, 0x619c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_103:
    mov al, 0
    ret
after_103:
    jmp short $+2
    call T_103
    cmp al, 1
    je ok_103
    add edi, 0x10000
    test di, di
    jnz ok_103
    or edi, 104
ok_103:
; case 104: s=4 u=4 m=0
    align 16
    push dword after_104
    mov ebp, 0x10000 + T_104 + 1
    mov esi, 0x41a00
    mov edx, 0x61a00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_104:
    mov al, 0
    ret
after_104:
    jmp short $+2
    call T_104
    cmp al, 1
    je ok_104
    add edi, 0x10000
    test di, di
    jnz ok_104
    or edi, 105
ok_104:
; case 105: s=4 u=4 m=1
    align 16
    push dword after_105
    mov ebp, 0x10000 + T_105 + 1
    mov esi, 0x41a40
    mov edx, 0x61a40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_105:
    mov al, 0
    ret
after_105:
    jmp short $+2
    call T_105
    cmp al, 1
    je ok_105
    add edi, 0x10000
    test di, di
    jnz ok_105
    or edi, 106
ok_105:
; case 106: s=4 u=5 m=0
    align 16
    push dword after_106
    mov ebp, 0x10000 + T_106 + 1
    mov esi, 0x41a80
    mov edx, 0x61a80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_106:
    mov al, 0
    ret
after_106:
    jmp short $+2
    call T_106
    cmp al, 1
    je ok_106
    add edi, 0x10000
    test di, di
    jnz ok_106
    or edi, 107
ok_106:
; case 107: s=4 u=5 m=1
    align 16
    push dword after_107
    mov ebp, 0x10000 + T_107 + 1
    mov esi, 0x41ac0
    mov edx, 0x61ac0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_107:
    mov al, 0
    ret
after_107:
    jmp short $+2
    call T_107
    cmp al, 1
    je ok_107
    add edi, 0x10000
    test di, di
    jnz ok_107
    or edi, 108
ok_107:
; case 108: s=4 u=6 m=0
    align 16
    push dword after_108
    mov ebp, 0x10000 + T_108 + 1
    mov esi, 0x41b00
    mov edx, 0x61b00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_108:
    mov al, 0
    ret
after_108:
    jmp short $+2
    call T_108
    cmp al, 1
    je ok_108
    add edi, 0x10000
    test di, di
    jnz ok_108
    or edi, 109
ok_108:
; case 109: s=4 u=6 m=1
    align 16
    push dword after_109
    mov ebp, 0x10000 + T_109 + 1
    mov esi, 0x41b40
    mov edx, 0x61b40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_109:
    mov al, 0
    ret
after_109:
    jmp short $+2
    call T_109
    cmp al, 1
    je ok_109
    add edi, 0x10000
    test di, di
    jnz ok_109
    or edi, 110
ok_109:
; case 110: s=4 u=7 m=0
    align 16
    push dword after_110
    mov ebp, 0x10000 + T_110 + 1
    mov esi, 0x41b80
    mov edx, 0x61b80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_110:
    mov al, 0
    ret
after_110:
    jmp short $+2
    call T_110
    cmp al, 1
    je ok_110
    add edi, 0x10000
    test di, di
    jnz ok_110
    or edi, 111
ok_110:
; case 111: s=4 u=7 m=1
    align 16
    push dword after_111
    mov ebp, 0x10000 + T_111 + 1
    mov esi, 0x41bc0
    mov edx, 0x61bc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_111:
    mov al, 0
    ret
after_111:
    jmp short $+2
    call T_111
    cmp al, 1
    je ok_111
    add edi, 0x10000
    test di, di
    jnz ok_111
    or edi, 112
ok_111:
; case 112: s=4 u=8 m=0
    align 16
    push dword after_112
    mov ebp, 0x10000 + T_112 + 1
    mov esi, 0x41c00
    mov edx, 0x61c00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_112:
    mov al, 0
    ret
after_112:
    jmp short $+2
    call T_112
    cmp al, 1
    je ok_112
    add edi, 0x10000
    test di, di
    jnz ok_112
    or edi, 113
ok_112:
; case 113: s=4 u=8 m=1
    align 16
    push dword after_113
    mov ebp, 0x10000 + T_113 + 1
    mov esi, 0x41c40
    mov edx, 0x61c40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_113:
    mov al, 0
    ret
after_113:
    jmp short $+2
    call T_113
    cmp al, 1
    je ok_113
    add edi, 0x10000
    test di, di
    jnz ok_113
    or edi, 114
ok_113:
; case 114: s=4 u=9 m=0
    align 16
    push dword after_114
    mov ebp, 0x10000 + T_114 + 1
    mov esi, 0x41c80
    mov edx, 0x61c80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_114:
    mov al, 0
    ret
after_114:
    jmp short $+2
    call T_114
    cmp al, 1
    je ok_114
    add edi, 0x10000
    test di, di
    jnz ok_114
    or edi, 115
ok_114:
; case 115: s=4 u=9 m=1
    align 16
    push dword after_115
    mov ebp, 0x10000 + T_115 + 1
    mov esi, 0x41cc0
    mov edx, 0x61cc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_115:
    mov al, 0
    ret
after_115:
    jmp short $+2
    call T_115
    cmp al, 1
    je ok_115
    add edi, 0x10000
    test di, di
    jnz ok_115
    or edi, 116
ok_115:
; case 116: s=4 u=10 m=0
    align 16
    push dword after_116
    mov ebp, 0x10000 + T_116 + 1
    mov esi, 0x41d00
    mov edx, 0x61d00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_116:
    mov al, 0
    ret
after_116:
    jmp short $+2
    call T_116
    cmp al, 1
    je ok_116
    add edi, 0x10000
    test di, di
    jnz ok_116
    or edi, 117
ok_116:
; case 117: s=4 u=10 m=1
    align 16
    push dword after_117
    mov ebp, 0x10000 + T_117 + 1
    mov esi, 0x41d40
    mov edx, 0x61d40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_117:
    mov al, 0
    ret
after_117:
    jmp short $+2
    call T_117
    cmp al, 1
    je ok_117
    add edi, 0x10000
    test di, di
    jnz ok_117
    or edi, 118
ok_117:
; case 118: s=4 u=11 m=0
    align 16
    push dword after_118
    mov ebp, 0x10000 + T_118 + 1
    mov esi, 0x41d80
    mov edx, 0x61d80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_118:
    mov al, 0
    ret
after_118:
    jmp short $+2
    call T_118
    cmp al, 1
    je ok_118
    add edi, 0x10000
    test di, di
    jnz ok_118
    or edi, 119
ok_118:
; case 119: s=4 u=11 m=1
    align 16
    push dword after_119
    mov ebp, 0x10000 + T_119 + 1
    mov esi, 0x41dc0
    mov edx, 0x61dc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_119:
    mov al, 0
    ret
after_119:
    jmp short $+2
    call T_119
    cmp al, 1
    je ok_119
    add edi, 0x10000
    test di, di
    jnz ok_119
    or edi, 120
ok_119:
; case 120: s=4 u=12 m=0
    align 16
    push dword after_120
    mov ebp, 0x10000 + T_120 + 1
    mov esi, 0x41e00
    mov edx, 0x61e00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_120:
    mov al, 0
    ret
after_120:
    jmp short $+2
    call T_120
    cmp al, 1
    je ok_120
    add edi, 0x10000
    test di, di
    jnz ok_120
    or edi, 121
ok_120:
; case 121: s=4 u=12 m=1
    align 16
    push dword after_121
    mov ebp, 0x10000 + T_121 + 1
    mov esi, 0x41e40
    mov edx, 0x61e40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_121:
    mov al, 0
    ret
after_121:
    jmp short $+2
    call T_121
    cmp al, 1
    je ok_121
    add edi, 0x10000
    test di, di
    jnz ok_121
    or edi, 122
ok_121:
; case 122: s=4 u=13 m=0
    align 16
    push dword after_122
    mov ebp, 0x10000 + T_122 + 1
    mov esi, 0x41e80
    mov edx, 0x61e80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_122:
    mov al, 0
    ret
after_122:
    jmp short $+2
    call T_122
    cmp al, 1
    je ok_122
    add edi, 0x10000
    test di, di
    jnz ok_122
    or edi, 123
ok_122:
; case 123: s=4 u=13 m=1
    align 16
    push dword after_123
    mov ebp, 0x10000 + T_123 + 1
    mov esi, 0x41ec0
    mov edx, 0x61ec0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_123:
    mov al, 0
    ret
after_123:
    jmp short $+2
    call T_123
    cmp al, 1
    je ok_123
    add edi, 0x10000
    test di, di
    jnz ok_123
    or edi, 124
ok_123:
; case 124: s=4 u=14 m=0
    align 16
    push dword after_124
    mov ebp, 0x10000 + T_124 + 1
    mov esi, 0x41f00
    mov edx, 0x61f00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_124:
    mov al, 0
    ret
after_124:
    jmp short $+2
    call T_124
    cmp al, 1
    je ok_124
    add edi, 0x10000
    test di, di
    jnz ok_124
    or edi, 125
ok_124:
; case 125: s=4 u=14 m=1
    align 16
    push dword after_125
    mov ebp, 0x10000 + T_125 + 1
    mov esi, 0x41f40
    mov edx, 0x61f40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_125:
    mov al, 0
    ret
after_125:
    jmp short $+2
    call T_125
    cmp al, 1
    je ok_125
    add edi, 0x10000
    test di, di
    jnz ok_125
    or edi, 126
ok_125:
; case 126: s=4 u=15 m=0
    align 16
    push dword after_126
    mov ebp, 0x10000 + T_126 + 1
    mov esi, 0x41f80
    mov edx, 0x61f80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_126:
    mov al, 0
    ret
after_126:
    jmp short $+2
    call T_126
    cmp al, 1
    je ok_126
    add edi, 0x10000
    test di, di
    jnz ok_126
    or edi, 127
ok_126:
; case 127: s=4 u=15 m=1
    align 16
    push dword after_127
    mov ebp, 0x10000 + T_127 + 1
    mov esi, 0x41fc0
    mov edx, 0x61fc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_127:
    mov al, 0
    ret
after_127:
    jmp short $+2
    call T_127
    cmp al, 1
    je ok_127
    add edi, 0x10000
    test di, di
    jnz ok_127
    or edi, 128
ok_127:
; case 128: s=4 u=16 m=0
    align 16
    push dword after_128
    mov ebp, 0x10000 + T_128 + 1
    mov esi, 0x42000
    mov edx, 0x62000
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_128:
    mov al, 0
    ret
after_128:
    jmp short $+2
    call T_128
    cmp al, 1
    je ok_128
    add edi, 0x10000
    test di, di
    jnz ok_128
    or edi, 129
ok_128:
; case 129: s=4 u=16 m=1
    align 16
    push dword after_129
    mov ebp, 0x10000 + T_129 + 1
    mov esi, 0x42040
    mov edx, 0x62040
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_129:
    mov al, 0
    ret
after_129:
    jmp short $+2
    call T_129
    cmp al, 1
    je ok_129
    add edi, 0x10000
    test di, di
    jnz ok_129
    or edi, 130
ok_129:
; case 130: s=4 u=17 m=0
    align 16
    push dword after_130
    mov ebp, 0x10000 + T_130 + 1
    mov esi, 0x42080
    mov edx, 0x62080
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_130:
    mov al, 0
    ret
after_130:
    jmp short $+2
    call T_130
    cmp al, 1
    je ok_130
    add edi, 0x10000
    test di, di
    jnz ok_130
    or edi, 131
ok_130:
; case 131: s=4 u=17 m=1
    align 16
    push dword after_131
    mov ebp, 0x10000 + T_131 + 1
    mov esi, 0x420c0
    mov edx, 0x620c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_131:
    mov al, 0
    ret
after_131:
    jmp short $+2
    call T_131
    cmp al, 1
    je ok_131
    add edi, 0x10000
    test di, di
    jnz ok_131
    or edi, 132
ok_131:
; case 132: s=4 u=18 m=0
    align 16
    push dword after_132
    mov ebp, 0x10000 + T_132 + 1
    mov esi, 0x42100
    mov edx, 0x62100
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_132:
    mov al, 0
    ret
after_132:
    jmp short $+2
    call T_132
    cmp al, 1
    je ok_132
    add edi, 0x10000
    test di, di
    jnz ok_132
    or edi, 133
ok_132:
; case 133: s=4 u=18 m=1
    align 16
    push dword after_133
    mov ebp, 0x10000 + T_133 + 1
    mov esi, 0x42140
    mov edx, 0x62140
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_133:
    mov al, 0
    ret
after_133:
    jmp short $+2
    call T_133
    cmp al, 1
    je ok_133
    add edi, 0x10000
    test di, di
    jnz ok_133
    or edi, 134
ok_133:
; case 134: s=4 u=19 m=0
    align 16
    push dword after_134
    mov ebp, 0x10000 + T_134 + 1
    mov esi, 0x42180
    mov edx, 0x62180
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_134:
    mov al, 0
    ret
after_134:
    jmp short $+2
    call T_134
    cmp al, 1
    je ok_134
    add edi, 0x10000
    test di, di
    jnz ok_134
    or edi, 135
ok_134:
; case 135: s=4 u=19 m=1
    align 16
    push dword after_135
    mov ebp, 0x10000 + T_135 + 1
    mov esi, 0x421c0
    mov edx, 0x621c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_135:
    mov al, 0
    ret
after_135:
    jmp short $+2
    call T_135
    cmp al, 1
    je ok_135
    add edi, 0x10000
    test di, di
    jnz ok_135
    or edi, 136
ok_135:
; case 136: s=4 u=20 m=0
    align 16
    push dword after_136
    mov ebp, 0x10000 + T_136 + 1
    mov esi, 0x42200
    mov edx, 0x62200
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_136:
    mov al, 0
    ret
after_136:
    jmp short $+2
    call T_136
    cmp al, 1
    je ok_136
    add edi, 0x10000
    test di, di
    jnz ok_136
    or edi, 137
ok_136:
; case 137: s=4 u=20 m=1
    align 16
    push dword after_137
    mov ebp, 0x10000 + T_137 + 1
    mov esi, 0x42240
    mov edx, 0x62240
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_137:
    mov al, 0
    ret
after_137:
    jmp short $+2
    call T_137
    cmp al, 1
    je ok_137
    add edi, 0x10000
    test di, di
    jnz ok_137
    or edi, 138
ok_137:
; case 138: s=4 u=21 m=0
    align 16
    push dword after_138
    mov ebp, 0x10000 + T_138 + 1
    mov esi, 0x42280
    mov edx, 0x62280
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_138:
    mov al, 0
    ret
after_138:
    jmp short $+2
    call T_138
    cmp al, 1
    je ok_138
    add edi, 0x10000
    test di, di
    jnz ok_138
    or edi, 139
ok_138:
; case 139: s=4 u=21 m=1
    align 16
    push dword after_139
    mov ebp, 0x10000 + T_139 + 1
    mov esi, 0x422c0
    mov edx, 0x622c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_139:
    mov al, 0
    ret
after_139:
    jmp short $+2
    call T_139
    cmp al, 1
    je ok_139
    add edi, 0x10000
    test di, di
    jnz ok_139
    or edi, 140
ok_139:
; case 140: s=4 u=22 m=0
    align 16
    push dword after_140
    mov ebp, 0x10000 + T_140 + 1
    mov esi, 0x42300
    mov edx, 0x62300
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_140:
    mov al, 0
    ret
after_140:
    jmp short $+2
    call T_140
    cmp al, 1
    je ok_140
    add edi, 0x10000
    test di, di
    jnz ok_140
    or edi, 141
ok_140:
; case 141: s=4 u=22 m=1
    align 16
    push dword after_141
    mov ebp, 0x10000 + T_141 + 1
    mov esi, 0x42340
    mov edx, 0x62340
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_141:
    mov al, 0
    ret
after_141:
    jmp short $+2
    call T_141
    cmp al, 1
    je ok_141
    add edi, 0x10000
    test di, di
    jnz ok_141
    or edi, 142
ok_141:
; case 142: s=4 u=23 m=0
    align 16
    push dword after_142
    mov ebp, 0x10000 + T_142 + 1
    mov esi, 0x42380
    mov edx, 0x62380
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_142:
    mov al, 0
    ret
after_142:
    jmp short $+2
    call T_142
    cmp al, 1
    je ok_142
    add edi, 0x10000
    test di, di
    jnz ok_142
    or edi, 143
ok_142:
; case 143: s=4 u=23 m=1
    align 16
    push dword after_143
    mov ebp, 0x10000 + T_143 + 1
    mov esi, 0x423c0
    mov edx, 0x623c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_143:
    mov al, 0
    ret
after_143:
    jmp short $+2
    call T_143
    cmp al, 1
    je ok_143
    add edi, 0x10000
    test di, di
    jnz ok_143
    or edi, 144
ok_143:
; case 144: s=8 u=0 m=0
    align 16
    push dword after_144
    mov ebp, 0x10000 + T_144 + 1
    mov esi, 0x42400
    mov edx, 0x62400
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_144:
    mov al, 0
    ret
after_144:
    jmp short $+2
    call T_144
    cmp al, 1
    je ok_144
    add edi, 0x10000
    test di, di
    jnz ok_144
    or edi, 145
ok_144:
; case 145: s=8 u=0 m=1
    align 16
    push dword after_145
    mov ebp, 0x10000 + T_145 + 1
    mov esi, 0x42440
    mov edx, 0x62440
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 0 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_145:
    mov al, 0
    ret
after_145:
    jmp short $+2
    call T_145
    cmp al, 1
    je ok_145
    add edi, 0x10000
    test di, di
    jnz ok_145
    or edi, 146
ok_145:
; case 146: s=8 u=1 m=0
    align 16
    push dword after_146
    mov ebp, 0x10000 + T_146 + 1
    mov esi, 0x42480
    mov edx, 0x62480
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_146:
    mov al, 0
    ret
after_146:
    jmp short $+2
    call T_146
    cmp al, 1
    je ok_146
    add edi, 0x10000
    test di, di
    jnz ok_146
    or edi, 147
ok_146:
; case 147: s=8 u=1 m=1
    align 16
    push dword after_147
    mov ebp, 0x10000 + T_147 + 1
    mov esi, 0x424c0
    mov edx, 0x624c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 1 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_147:
    mov al, 0
    ret
after_147:
    jmp short $+2
    call T_147
    cmp al, 1
    je ok_147
    add edi, 0x10000
    test di, di
    jnz ok_147
    or edi, 148
ok_147:
; case 148: s=8 u=2 m=0
    align 16
    push dword after_148
    mov ebp, 0x10000 + T_148 + 1
    mov esi, 0x42500
    mov edx, 0x62500
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_148:
    mov al, 0
    ret
after_148:
    jmp short $+2
    call T_148
    cmp al, 1
    je ok_148
    add edi, 0x10000
    test di, di
    jnz ok_148
    or edi, 149
ok_148:
; case 149: s=8 u=2 m=1
    align 16
    push dword after_149
    mov ebp, 0x10000 + T_149 + 1
    mov esi, 0x42540
    mov edx, 0x62540
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 2 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_149:
    mov al, 0
    ret
after_149:
    jmp short $+2
    call T_149
    cmp al, 1
    je ok_149
    add edi, 0x10000
    test di, di
    jnz ok_149
    or edi, 150
ok_149:
; case 150: s=8 u=3 m=0
    align 16
    push dword after_150
    mov ebp, 0x10000 + T_150 + 1
    mov esi, 0x42580
    mov edx, 0x62580
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_150:
    mov al, 0
    ret
after_150:
    jmp short $+2
    call T_150
    cmp al, 1
    je ok_150
    add edi, 0x10000
    test di, di
    jnz ok_150
    or edi, 151
ok_150:
; case 151: s=8 u=3 m=1
    align 16
    push dword after_151
    mov ebp, 0x10000 + T_151 + 1
    mov esi, 0x425c0
    mov edx, 0x625c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 3 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_151:
    mov al, 0
    ret
after_151:
    jmp short $+2
    call T_151
    cmp al, 1
    je ok_151
    add edi, 0x10000
    test di, di
    jnz ok_151
    or edi, 152
ok_151:
; case 152: s=8 u=4 m=0
    align 16
    push dword after_152
    mov ebp, 0x10000 + T_152 + 1
    mov esi, 0x42600
    mov edx, 0x62600
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_152:
    mov al, 0
    ret
after_152:
    jmp short $+2
    call T_152
    cmp al, 1
    je ok_152
    add edi, 0x10000
    test di, di
    jnz ok_152
    or edi, 153
ok_152:
; case 153: s=8 u=4 m=1
    align 16
    push dword after_153
    mov ebp, 0x10000 + T_153 + 1
    mov esi, 0x42640
    mov edx, 0x62640
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 4 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_153:
    mov al, 0
    ret
after_153:
    jmp short $+2
    call T_153
    cmp al, 1
    je ok_153
    add edi, 0x10000
    test di, di
    jnz ok_153
    or edi, 154
ok_153:
; case 154: s=8 u=5 m=0
    align 16
    push dword after_154
    mov ebp, 0x10000 + T_154 + 1
    mov esi, 0x42680
    mov edx, 0x62680
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_154:
    mov al, 0
    ret
after_154:
    jmp short $+2
    call T_154
    cmp al, 1
    je ok_154
    add edi, 0x10000
    test di, di
    jnz ok_154
    or edi, 155
ok_154:
; case 155: s=8 u=5 m=1
    align 16
    push dword after_155
    mov ebp, 0x10000 + T_155 + 1
    mov esi, 0x426c0
    mov edx, 0x626c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 5 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_155:
    mov al, 0
    ret
after_155:
    jmp short $+2
    call T_155
    cmp al, 1
    je ok_155
    add edi, 0x10000
    test di, di
    jnz ok_155
    or edi, 156
ok_155:
; case 156: s=8 u=6 m=0
    align 16
    push dword after_156
    mov ebp, 0x10000 + T_156 + 1
    mov esi, 0x42700
    mov edx, 0x62700
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_156:
    mov al, 0
    ret
after_156:
    jmp short $+2
    call T_156
    cmp al, 1
    je ok_156
    add edi, 0x10000
    test di, di
    jnz ok_156
    or edi, 157
ok_156:
; case 157: s=8 u=6 m=1
    align 16
    push dword after_157
    mov ebp, 0x10000 + T_157 + 1
    mov esi, 0x42740
    mov edx, 0x62740
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 6 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_157:
    mov al, 0
    ret
after_157:
    jmp short $+2
    call T_157
    cmp al, 1
    je ok_157
    add edi, 0x10000
    test di, di
    jnz ok_157
    or edi, 158
ok_157:
; case 158: s=8 u=7 m=0
    align 16
    push dword after_158
    mov ebp, 0x10000 + T_158 + 1
    mov esi, 0x42780
    mov edx, 0x62780
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_158:
    mov al, 0
    ret
after_158:
    jmp short $+2
    call T_158
    cmp al, 1
    je ok_158
    add edi, 0x10000
    test di, di
    jnz ok_158
    or edi, 159
ok_158:
; case 159: s=8 u=7 m=1
    align 16
    push dword after_159
    mov ebp, 0x10000 + T_159 + 1
    mov esi, 0x427c0
    mov edx, 0x627c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 7 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_159:
    mov al, 0
    ret
after_159:
    jmp short $+2
    call T_159
    cmp al, 1
    je ok_159
    add edi, 0x10000
    test di, di
    jnz ok_159
    or edi, 160
ok_159:
; case 160: s=8 u=8 m=0
    align 16
    push dword after_160
    mov ebp, 0x10000 + T_160 + 1
    mov esi, 0x42800
    mov edx, 0x62800
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_160:
    mov al, 0
    ret
after_160:
    jmp short $+2
    call T_160
    cmp al, 1
    je ok_160
    add edi, 0x10000
    test di, di
    jnz ok_160
    or edi, 161
ok_160:
; case 161: s=8 u=8 m=1
    align 16
    push dword after_161
    mov ebp, 0x10000 + T_161 + 1
    mov esi, 0x42840
    mov edx, 0x62840
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 8 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_161:
    mov al, 0
    ret
after_161:
    jmp short $+2
    call T_161
    cmp al, 1
    je ok_161
    add edi, 0x10000
    test di, di
    jnz ok_161
    or edi, 162
ok_161:
; case 162: s=8 u=9 m=0
    align 16
    push dword after_162
    mov ebp, 0x10000 + T_162 + 1
    mov esi, 0x42880
    mov edx, 0x62880
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_162:
    mov al, 0
    ret
after_162:
    jmp short $+2
    call T_162
    cmp al, 1
    je ok_162
    add edi, 0x10000
    test di, di
    jnz ok_162
    or edi, 163
ok_162:
; case 163: s=8 u=9 m=1
    align 16
    push dword after_163
    mov ebp, 0x10000 + T_163 + 1
    mov esi, 0x428c0
    mov edx, 0x628c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 9 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_163:
    mov al, 0
    ret
after_163:
    jmp short $+2
    call T_163
    cmp al, 1
    je ok_163
    add edi, 0x10000
    test di, di
    jnz ok_163
    or edi, 164
ok_163:
; case 164: s=8 u=10 m=0
    align 16
    push dword after_164
    mov ebp, 0x10000 + T_164 + 1
    mov esi, 0x42900
    mov edx, 0x62900
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_164:
    mov al, 0
    ret
after_164:
    jmp short $+2
    call T_164
    cmp al, 1
    je ok_164
    add edi, 0x10000
    test di, di
    jnz ok_164
    or edi, 165
ok_164:
; case 165: s=8 u=10 m=1
    align 16
    push dword after_165
    mov ebp, 0x10000 + T_165 + 1
    mov esi, 0x42940
    mov edx, 0x62940
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 10 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_165:
    mov al, 0
    ret
after_165:
    jmp short $+2
    call T_165
    cmp al, 1
    je ok_165
    add edi, 0x10000
    test di, di
    jnz ok_165
    or edi, 166
ok_165:
; case 166: s=8 u=11 m=0
    align 16
    push dword after_166
    mov ebp, 0x10000 + T_166 + 1
    mov esi, 0x42980
    mov edx, 0x62980
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_166:
    mov al, 0
    ret
after_166:
    jmp short $+2
    call T_166
    cmp al, 1
    je ok_166
    add edi, 0x10000
    test di, di
    jnz ok_166
    or edi, 167
ok_166:
; case 167: s=8 u=11 m=1
    align 16
    push dword after_167
    mov ebp, 0x10000 + T_167 + 1
    mov esi, 0x429c0
    mov edx, 0x629c0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 11 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_167:
    mov al, 0
    ret
after_167:
    jmp short $+2
    call T_167
    cmp al, 1
    je ok_167
    add edi, 0x10000
    test di, di
    jnz ok_167
    or edi, 168
ok_167:
; case 168: s=8 u=12 m=0
    align 16
    push dword after_168
    mov ebp, 0x10000 + T_168 + 1
    mov esi, 0x42a00
    mov edx, 0x62a00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_168:
    mov al, 0
    ret
after_168:
    jmp short $+2
    call T_168
    cmp al, 1
    je ok_168
    add edi, 0x10000
    test di, di
    jnz ok_168
    or edi, 169
ok_168:
; case 169: s=8 u=12 m=1
    align 16
    push dword after_169
    mov ebp, 0x10000 + T_169 + 1
    mov esi, 0x42a40
    mov edx, 0x62a40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 12 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_169:
    mov al, 0
    ret
after_169:
    jmp short $+2
    call T_169
    cmp al, 1
    je ok_169
    add edi, 0x10000
    test di, di
    jnz ok_169
    or edi, 170
ok_169:
; case 170: s=8 u=13 m=0
    align 16
    push dword after_170
    mov ebp, 0x10000 + T_170 + 1
    mov esi, 0x42a80
    mov edx, 0x62a80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_170:
    mov al, 0
    ret
after_170:
    jmp short $+2
    call T_170
    cmp al, 1
    je ok_170
    add edi, 0x10000
    test di, di
    jnz ok_170
    or edi, 171
ok_170:
; case 171: s=8 u=13 m=1
    align 16
    push dword after_171
    mov ebp, 0x10000 + T_171 + 1
    mov esi, 0x42ac0
    mov edx, 0x62ac0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 13 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_171:
    mov al, 0
    ret
after_171:
    jmp short $+2
    call T_171
    cmp al, 1
    je ok_171
    add edi, 0x10000
    test di, di
    jnz ok_171
    or edi, 172
ok_171:
; case 172: s=8 u=14 m=0
    align 16
    push dword after_172
    mov ebp, 0x10000 + T_172 + 1
    mov esi, 0x42b00
    mov edx, 0x62b00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_172:
    mov al, 0
    ret
after_172:
    jmp short $+2
    call T_172
    cmp al, 1
    je ok_172
    add edi, 0x10000
    test di, di
    jnz ok_172
    or edi, 173
ok_172:
; case 173: s=8 u=14 m=1
    align 16
    push dword after_173
    mov ebp, 0x10000 + T_173 + 1
    mov esi, 0x42b40
    mov edx, 0x62b40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 14 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_173:
    mov al, 0
    ret
after_173:
    jmp short $+2
    call T_173
    cmp al, 1
    je ok_173
    add edi, 0x10000
    test di, di
    jnz ok_173
    or edi, 174
ok_173:
; case 174: s=8 u=15 m=0
    align 16
    push dword after_174
    mov ebp, 0x10000 + T_174 + 1
    mov esi, 0x42b80
    mov edx, 0x62b80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_174:
    mov al, 0
    ret
after_174:
    jmp short $+2
    call T_174
    cmp al, 1
    je ok_174
    add edi, 0x10000
    test di, di
    jnz ok_174
    or edi, 175
ok_174:
; case 175: s=8 u=15 m=1
    align 16
    push dword after_175
    mov ebp, 0x10000 + T_175 + 1
    mov esi, 0x42bc0
    mov edx, 0x62bc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 15 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_175:
    mov al, 0
    ret
after_175:
    jmp short $+2
    call T_175
    cmp al, 1
    je ok_175
    add edi, 0x10000
    test di, di
    jnz ok_175
    or edi, 176
ok_175:
; case 176: s=8 u=16 m=0
    align 16
    push dword after_176
    mov ebp, 0x10000 + T_176 + 1
    mov esi, 0x42c00
    mov edx, 0x62c00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_176:
    mov al, 0
    ret
after_176:
    jmp short $+2
    call T_176
    cmp al, 1
    je ok_176
    add edi, 0x10000
    test di, di
    jnz ok_176
    or edi, 177
ok_176:
; case 177: s=8 u=16 m=1
    align 16
    push dword after_177
    mov ebp, 0x10000 + T_177 + 1
    mov esi, 0x42c40
    mov edx, 0x62c40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 16 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_177:
    mov al, 0
    ret
after_177:
    jmp short $+2
    call T_177
    cmp al, 1
    je ok_177
    add edi, 0x10000
    test di, di
    jnz ok_177
    or edi, 178
ok_177:
; case 178: s=8 u=17 m=0
    align 16
    push dword after_178
    mov ebp, 0x10000 + T_178 + 1
    mov esi, 0x42c80
    mov edx, 0x62c80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_178:
    mov al, 0
    ret
after_178:
    jmp short $+2
    call T_178
    cmp al, 1
    je ok_178
    add edi, 0x10000
    test di, di
    jnz ok_178
    or edi, 179
ok_178:
; case 179: s=8 u=17 m=1
    align 16
    push dword after_179
    mov ebp, 0x10000 + T_179 + 1
    mov esi, 0x42cc0
    mov edx, 0x62cc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 17 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_179:
    mov al, 0
    ret
after_179:
    jmp short $+2
    call T_179
    cmp al, 1
    je ok_179
    add edi, 0x10000
    test di, di
    jnz ok_179
    or edi, 180
ok_179:
; case 180: s=8 u=18 m=0
    align 16
    push dword after_180
    mov ebp, 0x10000 + T_180 + 1
    mov esi, 0x42d00
    mov edx, 0x62d00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_180:
    mov al, 0
    ret
after_180:
    jmp short $+2
    call T_180
    cmp al, 1
    je ok_180
    add edi, 0x10000
    test di, di
    jnz ok_180
    or edi, 181
ok_180:
; case 181: s=8 u=18 m=1
    align 16
    push dword after_181
    mov ebp, 0x10000 + T_181 + 1
    mov esi, 0x42d40
    mov edx, 0x62d40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 18 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_181:
    mov al, 0
    ret
after_181:
    jmp short $+2
    call T_181
    cmp al, 1
    je ok_181
    add edi, 0x10000
    test di, di
    jnz ok_181
    or edi, 182
ok_181:
; case 182: s=8 u=19 m=0
    align 16
    push dword after_182
    mov ebp, 0x10000 + T_182 + 1
    mov esi, 0x42d80
    mov edx, 0x62d80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_182:
    mov al, 0
    ret
after_182:
    jmp short $+2
    call T_182
    cmp al, 1
    je ok_182
    add edi, 0x10000
    test di, di
    jnz ok_182
    or edi, 183
ok_182:
; case 183: s=8 u=19 m=1
    align 16
    push dword after_183
    mov ebp, 0x10000 + T_183 + 1
    mov esi, 0x42dc0
    mov edx, 0x62dc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 19 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_183:
    mov al, 0
    ret
after_183:
    jmp short $+2
    call T_183
    cmp al, 1
    je ok_183
    add edi, 0x10000
    test di, di
    jnz ok_183
    or edi, 184
ok_183:
; case 184: s=8 u=20 m=0
    align 16
    push dword after_184
    mov ebp, 0x10000 + T_184 + 1
    mov esi, 0x42e00
    mov edx, 0x62e00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_184:
    mov al, 0
    ret
after_184:
    jmp short $+2
    call T_184
    cmp al, 1
    je ok_184
    add edi, 0x10000
    test di, di
    jnz ok_184
    or edi, 185
ok_184:
; case 185: s=8 u=20 m=1
    align 16
    push dword after_185
    mov ebp, 0x10000 + T_185 + 1
    mov esi, 0x42e40
    mov edx, 0x62e40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 20 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_185:
    mov al, 0
    ret
after_185:
    jmp short $+2
    call T_185
    cmp al, 1
    je ok_185
    add edi, 0x10000
    test di, di
    jnz ok_185
    or edi, 186
ok_185:
; case 186: s=8 u=21 m=0
    align 16
    push dword after_186
    mov ebp, 0x10000 + T_186 + 1
    mov esi, 0x42e80
    mov edx, 0x62e80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_186:
    mov al, 0
    ret
after_186:
    jmp short $+2
    call T_186
    cmp al, 1
    je ok_186
    add edi, 0x10000
    test di, di
    jnz ok_186
    or edi, 187
ok_186:
; case 187: s=8 u=21 m=1
    align 16
    push dword after_187
    mov ebp, 0x10000 + T_187 + 1
    mov esi, 0x42ec0
    mov edx, 0x62ec0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 21 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_187:
    mov al, 0
    ret
after_187:
    jmp short $+2
    call T_187
    cmp al, 1
    je ok_187
    add edi, 0x10000
    test di, di
    jnz ok_187
    or edi, 188
ok_187:
; case 188: s=8 u=22 m=0
    align 16
    push dword after_188
    mov ebp, 0x10000 + T_188 + 1
    mov esi, 0x42f00
    mov edx, 0x62f00
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_188:
    mov al, 0
    ret
after_188:
    jmp short $+2
    call T_188
    cmp al, 1
    je ok_188
    add edi, 0x10000
    test di, di
    jnz ok_188
    or edi, 189
ok_188:
; case 189: s=8 u=22 m=1
    align 16
    push dword after_189
    mov ebp, 0x10000 + T_189 + 1
    mov esi, 0x42f40
    mov edx, 0x62f40
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 22 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_189:
    mov al, 0
    ret
after_189:
    jmp short $+2
    call T_189
    cmp al, 1
    je ok_189
    add edi, 0x10000
    test di, di
    jnz ok_189
    or edi, 190
ok_189:
; case 190: s=8 u=23 m=0
    align 16
    push dword after_190
    mov ebp, 0x10000 + T_190 + 1
    mov esi, 0x42f80
    mov edx, 0x62f80
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    align 16, nop
T_190:
    mov al, 0
    ret
after_190:
    jmp short $+2
    call T_190
    cmp al, 1
    je ok_190
    add edi, 0x10000
    test di, di
    jnz ok_190
    or edi, 191
ok_190:
; case 191: s=8 u=23 m=1
    align 16
    push dword after_191
    mov ebp, 0x10000 + T_191 + 1
    mov esi, 0x42fc0
    mov edx, 0x62fc0
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    imul eax, ebx
    times 23 nop
    mov [ebp], cl
    mov eax, [esi]
    mov [edx], ecx
    mov [edx+4], ecx
    mov [edx+8], ecx
    mov [edx+12], ecx
    align 16, nop
T_191:
    mov al, 0
    ret
after_191:
    jmp short $+2
    call T_191
    cmp al, 1
    je ok_191
    add edi, 0x10000
    test di, di
    jnz ok_191
    or edi, 192
ok_191:
    test edi, edi
    jnz fail
    mov al, 0x01
    out 0xE0, al
    hlt
fail:
    mov eax, edi
    out 0xE4, eax
    mov al, 0xff
    out 0xE0, al
    hlt

