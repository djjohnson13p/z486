; intr_rerequest.asm - INTR re-asserted right after its acknowledge
;
; A 486 samples INTR as a LEVEL at each instruction boundary: there is no
; requirement that INTR go low between two requests.  An 8259 drops INT when
; the acknowledged IRQ enters service and raises it again as soon as a request
; of higher priority than the in-service one is pending - which can be the
; very next clock, or the same one (a higher IR arriving at the acknowledge).
; Under a gated (throttled) CPU clock a low gap shorter than one CPU clock
; period is never seen by the CPU at all.
;
; The bench (+intr_rerequest=3, +intr_regap=G in the JSON) keeps INTR low for
; only G platform cycles after each of the next three second INTA cycles and
; then raises it again, so one signal produces four requests.  Each must be
; acknowledged once the handler's IRET sets IF again.  Before the fix the
; interrupt latch's re-arm waited for INTR to be SEEN low at a CPU clock edge,
; so a request that held INTR through the acknowledge (or dropped it between
; two enabled edges) was never taken while INTR=1 and IF=1 (the PC-9821
; core's DOOM wedge at 2-4 MHz, IRR=0x81 ISR=00 IF=1 INTR=1, no INTA).
;
; Fail codes: 1 = timeout with fewer than four handler entries (data = count
; in the high word), 2 = more than four entries.

BITS 16
org 0

STATUS_PORT equ 0xE0
DATA_PORT   equ 0xE4
STATUS_PASS equ 0x01
STATUS_FAIL equ 0xFF
SIGNAL_PORT equ 0xE8
INTR_VECTOR equ 0x20

start:
    cli
    cld
    mov ax, cs
    mov ds, ax
    xor ax, ax
    mov es, ax
    mov word [es:INTR_VECTOR*4], isr_intr
    mov word [es:INTR_VECTOR*4+2], 0x1000
    mov word [intr_count], 0

    sti
    mov al, 1
    mov dx, SIGNAL_PORT
    out dx, al

    mov cx, 3000
.wait:
    cmp word [intr_count], 4
    jae .done
    dec cx
    jnz .wait
    ; timeout: report how many were taken
    movzx eax, word [intr_count]
    shl eax, 16
    or eax, 1
    jmp fail

.done:
    ; let a spurious extra request show up, if any
    mov cx, 200
.settle:
    dec cx
    jnz .settle
    cmp word [intr_count], 4
    jne .toomany
    mov al, STATUS_PASS
    mov dx, STATUS_PORT
    out dx, al
    hlt
    jmp $

.toomany:
    movzx eax, word [intr_count]
    shl eax, 16
    or eax, 2
    jmp fail

isr_intr:
    inc word [cs:intr_count]
    iret

fail:
    mov dx, DATA_PORT
    out dx, eax
    mov al, STATUS_FAIL
    mov dx, STATUS_PORT
    out dx, al
    hlt
    jmp $

align 2
intr_count: dw 0
