; hz_tr6_spec - a TR6 write that remaps a code page vs the prefetcher's
; branch-target line buffer
;
; A 486 writes the TLB entry directly through TR7/TR6; the next fetch from that
; page uses the new frame. The branch-target buffer is tagged by linear line and
; holds bytes fetched through the old entry, so a TR6 write must kill it like
; INVLPG and a CR3 write do (hz_invlpg_spec). Page T maps frame A (a loop that
; returns 0x11111111); the loop runs four times so T's line is buffered; T's TLB
; way is looked up through TR6 and rewritten to frame B (returns 0x22222222),
; the PTE left alone; then a JMP to T must run frame B's code. pad = 0..7 NOPs
; between the TR6 write and the JMP. Failure data = (pad << 8) | EAX[7:0].
BITS 32
ORG 0
CODE_BASE equ 0x10000
T_LIN     equ 0x50000
T_OFF     equ T_LIN - CODE_BASE
FRAME_A   equ 0x60000
FRAME_B   equ 0x61000
T_PTE     equ 0x1000 + (T_LIN >> 12) * 4

start:
    mov esp, 0x8000
    cld
    mov esi, CODE_BASE + tmpl_a
    mov edi, FRAME_A
    mov ecx, 4
    rep movsd
    mov esi, CODE_BASE + tmpl_b
    mov edi, FRAME_B
    mov ecx, 4
    rep movsd

%assign pd 0
%rep 8
    mov dword [T_PTE], FRAME_A | 0x23
    xor eax, eax
    mov cr3, eax
    mov ecx, 4
    mov edx, a_%+pd
    jmp T_OFF                        ; four passes: T's line is buffered
a_%+pd:
    cmp eax, 0x11111111
    jne bad_%+pd
    mov eax, T_LIN | 0xfe1           ; TR6 lookup of T
    mov tr6, eax
    mov ecx, tr7
    test ecx, 0x10
    jz bad_%+pd
    and ecx, 0x0c
    or ecx, FRAME_B | 0x10           ; PFN B, HT, REP = the way holding T
    mov eax, T_LIN | 0xd40           ; V, D, U, W, C=0 (write)
    mov tr7, ecx
    mov tr6, eax
    times pd nop
    mov ecx, 1
    mov edx, b_%+pd
    jmp T_OFF
b_%+pd:
    cmp eax, 0x22222222
    je ok_%+pd
bad_%+pd:
    and eax, 0xff
    or eax, pd << 8
    jmp fail
ok_%+pd:
%assign pd pd+1
%endrep
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
tmpl_a:
    mov eax, 0x11111111
    dec ecx
    jnz tmpl_a
    jmp edx
    align 16
tmpl_b:
    mov eax, 0x22222222
    dec ecx
    jnz tmpl_b
    jmp edx
    align 16
