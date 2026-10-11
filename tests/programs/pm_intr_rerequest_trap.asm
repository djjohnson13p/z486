; pm_intr_rerequest_trap.asm - INTR re-asserted right after its acknowledge,
; through a protected-mode IDT TRAP gate (IF stays set in the handler, so a
; still-asserted INTR nests at the handler's first instruction boundary).
; See intr_rerequest.asm for the shape: a 486 samples INTR as a level at each
; instruction boundary, so INTR held (or re-raised within less than one CPU
; clock) through the acknowledge is a new request and must be taken once IF is
; set again.  The bench (+intr_rerequest=3, +intr_regap=G) makes one signal
; four requests; the handler counts them.  pm_intr_rerequest_trap.asm is the
; same program through a TRAP gate, where IF stays set in the handler and a
; still-asserted INTR is taken at the handler's first instruction boundary.
;
; Fail codes: 1 = timeout with fewer than four handler entries, 2 = more than
; four; the count is in the high word of the data port.

BITS 16
org 0

STATUS_PORT equ 0xE0
DATA_PORT   equ 0xE4
SIGNAL_PORT equ 0xE8
SIGNAL_VECTOR_PORT equ 0xF4
STATUS_PASS equ 0x01
STATUS_FAIL equ 0xFF
INTR_VECTOR equ 0x20
GATE_TYPE   equ 10001111b       ; P=1 DPL=0 32-bit trap gate
SEL_CODE0 equ 0x08
SEL_DATA0 equ 0x10
PM_STACK_TOP equ 0x9000

start:
    cli
    cld
    lgdt [cs:gdt_desc]
    lidt [cs:idt_desc]
    mov eax, cr0
    or  eax, 1
    mov cr0, eax
    db 0x66, 0xEA
    dd pm32_entry
    dw SEL_CODE0

BITS 32
pm32_entry:
    mov ax, SEL_DATA0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, PM_STACK_TOP
    mov dword [intr_count], 0

    mov dx, SIGNAL_VECTOR_PORT
    mov al, INTR_VECTOR
    out dx, al

    sti
    mov dx, SIGNAL_PORT
    mov al, 1
    out dx, al

    mov ecx, 3000
.wait:
    cmp dword [intr_count], 4
    jae .done
    dec ecx
    jnz .wait
    mov eax, [intr_count]
    shl eax, 16
    or eax, 1
    jmp fail

.done:
    mov ecx, 200
.settle:
    dec ecx
    jnz .settle
    cmp dword [intr_count], 4
    jne .toomany
    mov al, STATUS_PASS
    mov dx, STATUS_PORT
    out dx, al
    hlt
    jmp $

.toomany:
    mov eax, [intr_count]
    shl eax, 16
    or eax, 2
    jmp fail

isr_intr:
    inc dword [intr_count]
    iretd

fail:
    mov dx, DATA_PORT
    out dx, eax
    mov al, STATUS_FAIL
    mov dx, STATUS_PORT
    out dx, al
    hlt
    jmp $

BITS 16
align 8
gdt:
    dq 0x0000000000000000   ; null
    dq 0x00CF9B010000FFFF   ; ring 0 code, base=0x10000, 4GB
    dq 0x00CF93010000FFFF   ; ring 0 data, base=0x10000, 4GB
gdt_end:
gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt + 0x00010000

align 8
idt:
    times INTR_VECTOR dq 0
    dw isr_intr
    dw SEL_CODE0
    db 0
    db GATE_TYPE
    dw 0
    times (256 - INTR_VECTOR - 1) dq 0
idt_end:
idt_desc:
    dw idt_end - idt - 1
    dd idt + 0x00010000

BITS 32
align 4
intr_count: dd 0
