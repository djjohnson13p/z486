; hz_spec_a20_rm - an A20 gate change vs the prefetcher's branch-target buffer
;
; The buffer (spec and its victim spec_b) is tagged by LINEAR line address. The
; A20 gate masks physical bit 20 after paging, so one linear line above 1 MiB
; names two different physical lines depending on the gate. The I/D caches are
; tagged after the mask and stay correct; a buffered target line fetched with
; the gate in one state must not be used after it changes (a 486 applies A20M#
; before its cache lookup, so it can never run the other copy).
;
; Two copies of the same code: the HMA copy at FFFF:0110 (linear 0x100100) and
; the low copy at 0000:0100 (where that linear line lands with A20 masked).
; R (FFFF:0110) returns 0x1111 from the HMA copy and 0x2222 from the low copy;
; D (FFFF:0130) calls R NEAR, so R's line is requested through the buffer.
; Case 1 calls D with A20 open, masks it (testbench port 0xF0) and calls D
; again: R must return 0x2222. Case 2 is the reverse (port 0xF4 opens).
; Cases 3/4 repeat 1/2 with two calls before the switch.
; Needs bench memory above 1 MiB: runs on obj_dir_bigmem (make test-bigmem).
; Failure data = bitmask of failing cases.
BITS 16
ORG 0
start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x8000
    mov ax, cs
    mov ds, ax
    cld
    out 0xf4, al                     ; A20 open while copying
    mov ax, 0xffff
    mov es, ax
    mov si, stub
    mov di, 0x0110
    mov cx, stub_end - stub
    rep movsb                        ; HMA copy: linear 0x100100
    xor ax, ax
    mov es, ax
    mov si, stub
    mov di, 0x0100
    mov cx, stub_end - stub
    rep movsb                        ; low copy: physical 0x000100
    mov word [es:0x0101], 0x2222     ; the low copy's R returns 0x2222
    xor di, di

%macro case 3                        ; id, port before, port after
    out %2, al
    call 0xffff:0x0130
%if %1 > 2
    call 0xffff:0x0130
%endif
    mov bx, ax
    out %3, al
    call 0xffff:0x0130
    mov cx, ax
    out 0xf4, al
%if %2 == 0xf4
    cmp bx, 0x1111
%else
    cmp bx, 0x2222
%endif
    jne fail_%1
%if %3 == 0xf4
    cmp cx, 0x1111
%else
    cmp cx, 0x2222
%endif
    je ok_%1
fail_%1:
    or di, 1 << %1
ok_%1:
%endmacro

    case 1, 0xf4, 0xf0
    case 2, 0xf0, 0xf4
    case 3, 0xf4, 0xf0
    case 4, 0xf0, 0xf4
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

; Copied to offset 0x0110 of the target segment: R at +0x00, D at +0x20.
stub:
    db 0xb8, 0x11, 0x11              ; R: mov ax, 0x1111
    db 0xc3                          ;    ret
    times 0x20 - ($ - stub) db 0x90
    db 0xe8, 0xdd, 0xff              ; D: call near 0x0110 (0x0110 - 0x0133)
    db 0xcb                          ;    retf
stub_end:
