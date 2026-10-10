; hz_tr6_pfxlat - a TR6 write that replaces the four-way TLB entry of the
; page code is running from, vs the last-prefetch translation (pf_xlat).
; Code in page Q (frame A) looks up its own TLB way, then writes that way with
; Q -> frame B through TR7/TR6 and runs straight on, with demand loads that
; keep the shared lookup register off Q, to Q+0x300.  Frames A and B differ
; only at Q+0x300, so a fetch of that line through the TLB returns B's code.
; Entry slides over a 16-byte NOP sled (k = 0..15) and the gap before the TR6
; write is swept (pad = 0..7).  Failure data = (pad << 8) | k; 0xdead.. = the
; lookup missed.
BITS 32
ORG 0
CODE_BASE equ 0x10000
Q_LIN     equ 0x50000
Q_OFF     equ Q_LIN - CODE_BASE
FRAME_A   equ 0x60000
FRAME_B   equ 0x61000
Q_PTE     equ 0x1000 + (Q_LIN >> 12) * 4
TLEN      equ 0x340

start:
    mov esp, 0x8000
    cld
    xor ebp, ebp
pad_loop:
    imul eax, ebp, TLEN
    lea esi, [CODE_BASE + bodies + eax]
    mov edi, FRAME_A
    mov ecx, TLEN / 4
    rep movsd
    sub esi, TLEN
    mov edi, FRAME_B
    mov ecx, TLEN / 4
    rep movsd
    mov dword [FRAME_A + 0x300], 0x111111b8
    mov dword [FRAME_B + 0x300], 0x222222b8
    xor edi, edi
k_loop:
    mov dword [Q_PTE], FRAME_A | 0x23
    xor eax, eax
    mov cr3, eax
    mov edx, back
    lea eax, [edi + Q_OFF]
    jmp eax
back:
    cmp eax, 0x11222222
    je ok
    cmp eax, 0x11111111
    jne bad
    mov eax, ebp
    shl eax, 8
    or eax, edi
bad:
    jmp fail
ok:
    inc edi
    cmp edi, 16
    jb k_loop
    inc ebp
    cmp ebp, 8
    jb pad_loop
    xor eax, eax
    mov cr3, eax
    mov al, 1
    out 0xe0, al
    hlt
fail:
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt

    align 16
bodies:
%assign pd 0
%rep 8
    times 16 nop
    mov eax, Q_LIN | 0xfe1           ; TR6 lookup of Q
    mov tr6, eax
    mov ecx, tr7
    test ecx, 0x10
    jnz short $+2+5+2
    mov eax, 0xdead0000
    jmp edx

    and ecx, 0x0c
    or ecx, FRAME_B | 0x10           ; PFN B, HT, REP = the way holding Q
    mov eax, Q_LIN | 0xd40           ; V, D, U, W, C=0
    mov tr7, ecx
    times pd nop
    mov tr6, eax
%rep 80
    mov ebx, [0x7000]
%endrep
    times 0x300 - ($ - bodies - pd*TLEN) nop
    mov eax, 0x11111111              ; patched per frame: A 0x11111111, B 0x11222222
    jmp edx
    times ((pd+1)*TLEN) - ($ - bodies) db 0xcc
%assign pd pd+1
%endrep
