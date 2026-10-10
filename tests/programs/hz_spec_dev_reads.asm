; hz_spec_dev_reads - a branch that is never taken must not read its target
;
; A 486 fetches only what the program runs plus the sequential lines after it.
; The branch-target buffer launches a bus read at the target of a branch that
; the program never takes. On a PC-98 that read can land in device memory with
; read side effects (EGC latch, GRCG compare, attribute VRAM), and a page walk
; that goes with it sets Accessed bits on pages the program never touched.
; The testbench watches physical 0x71000..0xa0fff (+watch_lo/+watch_hi) and
; fails if any bus read lands in it (+expect_watch_reads=0). Nothing the
; program does itself reads there: the TLB warm-ups below are stores.
;
;   L_PCD  -> 0x71000  PTE.PCD=1, TLB warm        (uncacheable code page)
;   L_VGA  -> 0xa0000  TLB warm, in the A0000 window (device memory)
;
; (The cold-page case, where the same fetch also walks and sets PTE.A, is
; hz_spec_walk_abit.)
BITS 32
ORG 0
CODE_BASE equ 0x10000
PTE_BASE  equ 0x1000
L_PCD     equ 0x300000
L_VGA     equ 0x302000
PTE_PCD   equ PTE_BASE + (L_PCD  >> 12) * 4
PTE_VGA   equ PTE_BASE + (L_VGA  >> 12) * 4

start:
    mov esp, 0x8000
    mov dword [PTE_PCD],  0x71000 | 0x13       ; P|RW|PCD
    mov dword [PTE_VGA],  0xa0000 | 0x03
    invlpg [L_PCD]
    invlpg [L_VGA]
    mov byte [L_PCD + 0x10], 0                 ; store: loads the TLB, no bus read
    mov byte [L_VGA + 0x10], 0
    xor ebx, ebx
%assign n 0
%rep 12
    cmp esp, esp                               ; ZF=1: every JNE below is not taken
    jne near (L_PCD  + 0x100 - CODE_BASE)
    times n nop
    cmp esp, esp
    jne near (L_VGA  + 0x100 - CODE_BASE)
    times n nop
    inc ebx
    align 16
%assign n n+1
%endrep
    mov al, 1
    out 0xe0, al
    hlt
