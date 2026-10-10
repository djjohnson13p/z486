; hz_spec_walk_store - a store that waits in paging (its TLB entry was just
; invalidated, so it walks) while a younger branch requests the stored line
;
; The prefetcher kills a buffered or in-flight branch-target line when a store
; into it is REPORTED (at paging acceptance). A posted store whose translation
; misses lets younger non-memory instructions run behind it; a branch among
; them may launch its target fetch after the report but before the store has
; reached the D-cache and patched the I-cache, and must not keep the old line.
; Each trial invalidates the alias page A (linear 0x200000 -> the stub's frame),
; patches S's imm32 through A (a page walk), runs N = 0..15 NOPs, a not-taken
; JNE S (the target request), then CALLs S, which must return the new value.
; Two passes: S's line warm in the I-cache, then also in the branch-target
; victim. Failure data = (pass << 8) | N.
BITS 32
ORG 0
CODE_BASE equ 0x10000
S_LIN     equ CODE_BASE + (S - $$)
A_LIN     equ 0x200000 + (S_LIN & 0xfff)    ; S through the alias page
A_PTE     equ 0x1000 + (0x200000 >> 12) * 4

start:
    mov esp, 0x8000
    mov eax, S_LIN & 0xfffff000
    or eax, 0x23
    mov [A_PTE], eax
    xor esi, esi                     ; pass
pass_loop:
%assign n 0
%rep 16
    mov dword [S_LIN + 1], 0x11111111
    call S                           ; S warm in the I-cache
    cmp esi, 1
    jne short nb_%+n
    cmp esp, esp
    jne S                            ; pass 1: S's line buffered first
nb_%+n:
    jmp short e_%+n                  ; a new target between
    align 16
e_%+n:
    invlpg [A_LIN]
    mov eax, 0x22220000 + n
    mov [A_LIN + 1], eax             ; through the alias: walks
    times n nop
    cmp esp, esp
    jne S                            ; not taken: requests S's line
    call S
    cmp eax, 0x22220000 + n
    je ok_%+n
    mov eax, esi
    shl eax, 8
    or eax, n
    jmp fail
ok_%+n:
%assign n n+1
%endrep
    inc esi
    cmp esi, 2
    jb pass_loop
    mov al, 1
    out 0xe0, al
    hlt
fail:
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
    align 16
S:
    mov eax, 0
    ret
