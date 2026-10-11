; pc98_direct_read_shapes - uncached single-beat demand reads of every width and
; alignment in the PC-98 VGA/device windows, including page-unit crossings.  A
; direct read is one bus beat with no line fill, so a fabric that answers it in
; the cycle valid rises (+zero_wait) completes it on the accept edge.  The CPU
; must neither wedge (a flag left set for a completion already seen) nor return
; the wrong lanes (read-return metadata not yet latched in that cycle).
BITS 32
ORG 0
start:
    mov esp, 0x8000
    mov dword [0xA8000], 0x44332211
    mov dword [0xA8004], 0x88776655
    mov dword [0xE0000], 0xCAFEF00D
    mov dword [0xE0004], 0x0BADBEEF
    mov eax, [0xA8000]
    cmp eax, 0x44332211
    jne fail
    movzx eax, byte [0xA8001]
    cmp eax, 0x22
    jne fail
    movzx eax, byte [0xA8003]
    cmp eax, 0x44
    jne fail
    movzx eax, word [0xA8002]
    cmp eax, 0x4433
    jne fail
    mov eax, [0xA8002]            ; crossing dword
    cmp eax, 0x66554433
    jne fail
    movzx eax, word [0xA8003]     ; crossing word
    cmp eax, 0x5544
    jne fail
    mov eax, [0xA8001]            ; crossing dword
    cmp eax, 0x55443322
    jne fail
    mov eax, [0xE0000]
    cmp eax, 0xCAFEF00D
    jne fail
    movzx eax, byte [0xE0002]
    cmp eax, 0xFE
    jne fail
    mov eax, [0xE0003]            ; crossing dword
    cmp eax, 0xADBEEFCA
    jne fail
    ; back-to-back reads with a dependent use between them
    mov ecx, [0xA8004]
    add ecx, [0xE0004]
    cmp ecx, 0x88776655 + 0x0BADBEEF
    jne fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    mov al, 0xff
    out 0xe0, al
    hlt
