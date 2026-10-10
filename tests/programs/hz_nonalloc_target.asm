; hz_nonalloc_target - the branch-target buffer must not keep a line the I-cache would not allocate
;
; The prefetcher's branch-target buffer (active spec line + victim) holds code fetched from
; memory. The I-cache deliberately does not install a NO_ALLOC template window's lines (device
; memory, bank-switched windows, DMA targets: something other than the CPU can change them),
; and a 486 has no target buffer at all - its prefetch queue is refilled after every control
; transfer. Buffering such a line lets a non-CPU change go unseen: the next branch to the
; target replays the old bytes.
;
; Here the window is the PC-98 window-0 overlay (0x80000-0x9FFFF, NO_ALLOC). A not-taken JNE
; buffers T's line; a bus-side write (+xdma_*, a DMA with no snoop and no whole-L1 flush)
; then changes T's immediate; after the serialising JMP, CALL T must return the new value.
BITS 32
ORG 0
start:
    mov esp, 0x70000
    call T                           ; T returns 0x11223344
    cmp eax, 0x11223344
    jne fail
    cmp eax, eax
    jne T                            ; not taken: requests (buffers) T's line
    mov ebx, [fs:0x1000]             ; the DMA write of T+1 is armed on this read
    times 40 nop                     ; let the DMA land
    jmp short serialize
serialize:
    call T                           ; a 486 refetches: the DMA'd bytes
    cmp eax, 0x55667788
    jne fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
times 0x200-($-$$) db 0x90
T:
    mov eax, 0x11223344
    ret
