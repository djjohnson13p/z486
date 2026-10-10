; hz_spec_walk_abit - a branch that is never taken must not set Accessed bits
;
; The branch-target buffer launches a fetch at the target of a not-taken branch.
; When the target's page is not in the TLB that fetch starts a page walk, and
; the walk sets PTE.A (and PDE.A) on a page the program never touched. A 486
; makes no such fetch. The page below is mapped but never accessed; its PTE.A
; must still be clear when the loop is done, and no bus read may land in it
; (the program does not read its frame, only the PTE).
;
; Failure data (port 0xe4): 1 = the PTE's Accessed bit was set.
BITS 32
ORG 0
CODE_BASE equ 0x10000
PTE_BASE  equ 0x1000
L_COLD    equ 0x301000
PTE_COLD  equ PTE_BASE + (L_COLD >> 12) * 4

start:
    mov esp, 0x8000
    mov dword [PTE_COLD], 0x72000 | 0x03
    invlpg [L_COLD]
    xor ebx, ebx
%assign n 0
%rep 12
    cmp esp, esp                               ; ZF=1: the JNE is not taken
    jne near (L_COLD + 0x100 - CODE_BASE)
    times n nop
    inc ebx
    align 16
%assign n n+1
%endrep
    mov eax, [PTE_COLD]
    test al, 0x20
    jnz fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    mov eax, 1
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
