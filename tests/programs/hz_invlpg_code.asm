; hz_invlpg_code - code running in page T remaps its OWN page (PTE store +
; INVLPG, or a CR3 switch), then leaves the prefetch queue with an indirect
; JMP (no branch-target buffer request) to T+0x40.  On a 486 the jump refetches
; through a fresh walk, so T+0x40 must run frame B's code.  This exercises the
; last-prefetch translation (pf_xlat) and the four-way TLB with the invalidate
; landing while code fetch of the same page is in flight.  The entry point is
; slid over a 16-byte NOP sled (entry = T + k, k = 0..15) so the invalidate
; sits at every alignment, and the padding between the invalidate and the JMP
; is swept 0..7 by separate prologues.
; Failure data = (mode << 16) | (pad << 8) | k.
BITS 32
ORG 0
CODE_BASE equ 0x10000
T_LIN     equ 0x50000
T_OFF     equ T_LIN - CODE_BASE
FRAME_A   equ 0x60000
FRAME_B   equ 0x61000
T_PTE     equ 0x1000 + (T_LIN >> 12) * 4
PTE_FL    equ 0x23
PD1       equ 0x3000
PT1       equ 0x4000
TLEN      equ 0x60

start:
    mov esp, 0x8000
    cld
    ; PD1: copy of PD0 with T -> FRAME_B
    mov esi, 0x1000
    mov edi, PT1
    mov ecx, 1024
    rep movsd
    mov dword [PT1 + (T_LIN >> 12) * 4], FRAME_B | PTE_FL
    mov dword [PD1], PT1 | 0x27
    mov edi, PD1 + 4
    xor eax, eax
    mov ecx, 1023
    rep stosd

    xor ebx, ebx                     ; mode (0 INVLPG, 1 CR3)
mode_loop:
    xor ebp, ebp                     ; pad
pad_loop:
    ; build frame A and frame B: prologue[mode][pad] at 0, tails at 0x40
    mov eax, ebx
    shl eax, 3
    add eax, ebp
    imul eax, eax, TLEN
    lea esi, [CODE_BASE + prologues + eax]
    mov edi, FRAME_A
    mov ecx, TLEN / 4
    rep movsd
    sub esi, TLEN
    mov edi, FRAME_B
    mov ecx, TLEN / 4
    rep movsd
    mov esi, CODE_BASE + tail_a
    mov edi, FRAME_A + 0x40
    mov ecx, 4
    rep movsd
    mov esi, CODE_BASE + tail_b
    mov edi, FRAME_B + 0x40
    mov ecx, 4
    rep movsd
    xor edi, edi                     ; k
k_loop:
    mov dword [T_PTE], FRAME_A | PTE_FL
    xor eax, eax
    mov cr3, eax                     ; PD0, empty TLB
    mov ecx, PD1
    mov esi, T_OFF + 0x40
    mov edx, back
    lea eax, [edi + T_OFF]
    jmp eax
back:
    cmp eax, 0x22222222
    je ok
    mov eax, ebx
    shl eax, 8
    or eax, ebp
    shl eax, 8
    or eax, edi
    jmp fail
ok:
    inc edi
    cmp edi, 16
    jb k_loop
    inc ebp
    cmp ebp, 8
    jb pad_loop
    inc ebx
    cmp ebx, 2
    jb mode_loop

    xor eax, eax
    mov cr3, eax
    mov al, 1
    out 0xe0, al
    hlt
fail:
    out 0xe4, eax
    xor ecx, ecx
    mov cr3, ecx
    mov al, 0xff
    out 0xe0, al
    hlt

    align 16
tail_a:
    mov eax, 0x11111111
    jmp edx
    align 16
tail_b:
    mov eax, 0x22222222
    jmp edx
    align 16

prologues:
%assign md 0
%rep 2
%assign pd 0
%rep 8

    times 16 nop
%if md == 0
    mov dword [T_PTE], FRAME_B | PTE_FL
    invlpg [T_LIN]
%else
    mov cr3, ecx
%endif
    times pd nop
    jmp esi
    times ((md*8+pd+1)*TLEN) - ($ - prologues) db 0xcc
%assign pd pd+1
%endrep
%assign md md+1
%endrep
