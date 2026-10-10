; smc_spec_demote_rm - a store into the buffered branch-target line in the cycle the line is
; demoted to the victim slot
;
; z486's prefetcher keeps two branch-target lines: the active one (spec) and a victim (spec_b).
; A new target request that misses both moves the active line into the victim slot. A store whose
; line is the active line must kill it; when that store lands in the very cycle of the demotion,
; the kill (spec_kill) clears only the active slot, and the copy into the victim keeps the
; pre-store bytes. A later branch to that line then swaps the stale victim back in and runs the
; old code. Found for the PC-9821 core: Policenauts' intro stopped in a V86 #UD loop, and on
; hardware only disabling the branch-target request (pf_spec_req) cured it.
;
; Each trial: a not-taken JNE to S buffers S's line; then the trial patches the imm16 of
; S's "mov ax, imm16" and, N nops later, jumps to the next line T (the demoting request), and
; from T calls S. A 486 must return the patched value. N = 0..7 sweeps the store/request
; alignment. Failure data = bitmask of the failing N.
BITS 16
ORG 0
start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x8000
    mov ax, cs
    mov ds, ax
    xor di, di

%macro trial 1
    mov word [S + 1], 0x1111         ; S returns 0x1111
    call S                           ; S's line is fetched and cached
    mov bx, 0x2222 + %1
    cmp ax, ax
    jne S                            ; not taken: requests (buffers) S's line
    mov [S + 1], bx                  ; patch S: must now return 0x2222 + N
    times %1 nop
    jmp t_%1                         ; a new target: demotes S's line to the victim slot
    align 16
t_%1:
    call S                           ; S again: the victim hit swaps the line back in
    cmp ax, 0x2222 + %1
    je ok_%1
    or di, 1 << %1
ok_%1:
%endmacro

    trial 0
    trial 1
    trial 2
    trial 3
    trial 4
    trial 5
    trial 6
    trial 7

    test di, di
    jnz fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    movzx eax, di
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt

    align 16
S:
    mov ax, 0x0000                   ; B8 iw: the imm16 at S + 1
    ret
