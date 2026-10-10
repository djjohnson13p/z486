; hz_invlpg_spec - INVLPG (and CR3) vs the prefetcher's branch-target line buffer
;
; A code page T (linear 0x50000, CS offset 0x40000) is first mapped to frame A
; (code that loads 0x11111111) and its line is buffered by repeated branches.
; The PTE is then pointed at frame B (code that loads 0x22222222) and the page
; is invalidated; the next branch to T must execute frame B's code, as a 486
; (which has no branch-target buffer) re-walks after INVLPG.
;   case 1: T held in the PRIMARY spec line (rel jnz loop inside T), INVLPG
;   case 2: T held in the VICTIM line (CALL T / RET), INVLPG
;   case 3: control - case 1 with a CR3 reload instead of INVLPG
; Failure data = bitmask of failing cases.
BITS 32
ORG 0
CODE_BASE equ 0x10000
T_LIN     equ 0x50000
T_OFF     equ T_LIN - CODE_BASE
FRAME_A   equ 0x60000
FRAME_B   equ 0x61000
FRAME_C   equ 0x62000
FRAME_D   equ 0x63000
T_PTE     equ 0x1000 + (T_LIN >> 12) * 4
PTE_FL    equ 0x23

start:
    mov esp, 0x8000
    xor edi, edi
    cld
    ; frames A/B: loop templates, frames C/D: call templates
    mov esi, CODE_BASE + tmpl_a
    mov ebp, FRAME_A
    call copy16
    mov esi, CODE_BASE + tmpl_b
    mov ebp, FRAME_B
    call copy16
    mov esi, CODE_BASE + tmpl_c
    mov ebp, FRAME_C
    call copy16
    mov esi, CODE_BASE + tmpl_d
    mov ebp, FRAME_D
    call copy16

; ---------------- case 1: primary spec line, INVLPG ----------------
    mov dword [T_PTE], FRAME_A | PTE_FL
    mov eax, cr3
    mov cr3, eax
    mov ecx, 4
    mov edx, c1_back
    jmp T_OFF
c1_back:
    cmp eax, 0x11111111
    jne c1_fail
    mov dword [T_PTE], FRAME_B | PTE_FL
    invlpg [T_LIN]
    mov ecx, 1
    mov edx, c1_back2
    jmp T_OFF
c1_back2:
    cmp eax, 0x22222222
    je c1_ok
c1_fail:
    or edi, 1 << 1
c1_ok:

; ---------------- case 2: victim spec line (CALL/RET), INVLPG ----------------
    mov esp, 0x8000
    mov dword [T_PTE], FRAME_C | PTE_FL
    mov eax, cr3                     ; start from an empty branch-target buffer
    mov cr3, eax
    mov ecx, 1
    mov edx, c2_a
    call T_OFF
c2_a:
    mov esp, 0x8000
    mov ecx, 1
    mov edx, c2_b
    call T_OFF
c2_b:
    mov esp, 0x8000
    mov ecx, 1
    mov edx, c2_c
    call T_OFF
c2_c:
    mov esp, 0x8000
    cmp eax, 0x33333333
    jne c2_fail
    mov dword [T_PTE], FRAME_D | PTE_FL
    invlpg [T_LIN]
    mov ecx, 1
    mov edx, c2_d
    call T_OFF
c2_d:
    mov esp, 0x8000
    cmp eax, 0x44444444
    je c2_ok
c2_fail:
    or edi, 1 << 2
c2_ok:

; ---------------- case 3: control, CR3 reload ----------------
    mov dword [T_PTE], FRAME_A | PTE_FL
    mov eax, cr3
    mov cr3, eax
    mov ecx, 4
    mov edx, c3_back
    jmp T_OFF
c3_back:
    cmp eax, 0x11111111
    jne c3_fail
    mov dword [T_PTE], FRAME_B | PTE_FL
    mov eax, cr3
    mov cr3, eax
    mov ecx, 1
    mov edx, c3_back2
    jmp T_OFF
c3_back2:
    cmp eax, 0x22222222
    je c3_ok
c3_fail:
    or edi, 1 << 3
c3_ok:

    test edi, edi
    jnz fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    mov eax, edi
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt

copy16:                     ; copy 16 bytes [esi] -> [ebp]
    mov eax, [esi]
    mov [ebp], eax
    mov eax, [esi+4]
    mov [ebp+4], eax
    mov eax, [esi+8]
    mov [ebp+8], eax
    mov eax, [esi+12]
    mov [ebp+12], eax
    ret

    align 16
tmpl_a:
    mov eax, 0x11111111
    dec ecx
    jnz tmpl_a
    jmp edx
    align 16
tmpl_b:
    mov eax, 0x22222222
    dec ecx
    jnz tmpl_b
    jmp edx
    align 16
tmpl_c:
    mov eax, 0x33333333
    ret
    align 16
tmpl_d:
    mov eax, 0x44444444
    ret
    align 16
