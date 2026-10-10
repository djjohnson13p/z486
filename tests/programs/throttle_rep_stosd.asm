; CPU-throttle pacing: a REP string instruction must be paced like any other
; code.  One REP STOSD of 12288 dwords is a single instruction, so a throttle
; that acts only at instruction boundaries cannot slow it (the old park ran it
; 32.5x too fast at its slowest setting).  The CPU's clock is gated, so the
; whole instruction, mid-REP included, takes the requested time.
;
; Port 0xFC reads the testbench's real-time clock (clk_sys cycles).  The program
; reports, through data port 0xE4, the clocks taken by (1) the REP STOSD, then
; (2) 4096 iterations of a DEC/JNZ loop; tests/test_throttle_rate.py runs it
; at full speed and at a throttled setting and compares the two.  The memory
; effect is checked here: every dword must hold the pattern.

BITS 32
org 0

STATUS_PORT equ 0xE0
DATA_PORT   equ 0xE4
CYCLE_PORT  equ 0xFC

BUF         equ 0x20000
COUNT       equ 12288
PATTERN     equ 0xA5C3E1F0

start:
    ; Warm the code and the TLB with a short run first.
    mov edi, BUF
    mov ecx, 64
    mov eax, PATTERN
    cld
    rep stosd

    times 8 nop
    in eax, CYCLE_PORT
    mov esi, eax
    mov edi, BUF
    mov ecx, COUNT
    mov eax, PATTERN
    rep stosd
    mov edx, eax                 ; consume: the REP has retired
    in eax, CYCLE_PORT
    sub eax, esi
    out DATA_PORT, eax           ; (1) REP STOSD clocks

    mov ecx, 4096
    in eax, CYCLE_PORT
    mov esi, eax
.spin:
    dec ecx
    jnz .spin
    in eax, CYCLE_PORT
    sub eax, esi
    out DATA_PORT, eax           ; (2) DEC/JNZ loop clocks

    ; Architectural result: the whole buffer holds the pattern.
    mov esi, BUF
    mov ecx, COUNT
.check:
    cmp dword [esi], PATTERN
    jne fail
    add esi, 4
    dec ecx
    jnz .check

    mov al, 1
    out STATUS_PORT, al
    hlt
fail:
    mov eax, esi
    out DATA_PORT, eax
    mov al, 0xFF
    out STATUS_PORT, al
    hlt
