; hz_invlpg_data - PTE rewrite + INVLPG (or a CR3 switch) then an immediate
; data access to the remapped page, with 0..7 bytes of padding between the
; invalidate and the access so the access's D2 preread / EX resolve / direct
; store lands at every cycle offset from the invalidate.  Every data access
; kind that has its own translation copy is used: direct load (VIPT sidecar),
; posted store (st_take), RMW_FAST (rmw_fast_phys_r), microcode read (ucrd),
; PUSH from memory.  Page P (linear 0x50000) alternates between frames X and Y.
; Failure data = (kind << 16) | (pad << 8) | iteration.
BITS 32
ORG 0
CODE_BASE equ 0x10000
P_LIN   equ 0x50000
FX      equ 0x60000
FY      equ 0x61000
OFS     equ 0x104
P_PTE   equ 0x1000 + (P_LIN >> 12) * 4
PTE_FL  equ 0x23
PD1     equ 0x3000                  ; second page directory
PT1     equ 0x4000                  ; its page table (copy of 0x1000)

%macro MAP 2                        ; %1 = frame, %2 = 0 INVLPG / 1 CR3 switch
%if %2 == 0
    mov dword [P_PTE], %1 | PTE_FL
    invlpg [P_LIN]
%else
  %if %1 == FX
    xor eax, eax
  %else
    mov eax, PD1
  %endif
    mov cr3, eax
%endif
%endmacro

%macro SEED 0                       ; FX word = 0x1000+ebp, FY word = 0x2000+ebp
    lea eax, [ebp + 0x1000]
    mov [FX + OFS], eax
    lea eax, [ebp + 0x2000]
    mov [FY + OFS], eax
%endmacro

%macro FAILIF 2                     ; jne-style: %1 kind, %2 pad
    je %%ok
    mov eax, (%1 << 16) | (%2 << 8)
    or eax, ebp
    jmp fail
%%ok:
%endmacro

; one test: %1 kind, %2 pad bytes, %3 frame, %4 mode
%macro TEST1 4
    SEED
    MAP %3, %4
    times %2 nop
%if %1 == 1          ; direct load
    mov eax, [P_LIN + OFS]
    lea edx, [ebp + (%3 - FX) + 0x1000]
    cmp eax, edx
    FAILIF %1, %2
%elif %1 == 2        ; posted store, then read both frames through identity
    mov dword [P_LIN + OFS], 0x5a5a5a5a
    cmp dword [%3 + OFS], 0x5a5a5a5a
    FAILIF %1, %2
%elif %1 == 3        ; RMW_FAST
    add dword [P_LIN + OFS], 0x10000
    lea edx, [ebp + (%3 - FX) + 0x11000]
    cmp [%3 + OFS], edx
    FAILIF %1, %2
%elif %1 == 4        ; microcode read (IMUL r, m)
    mov ecx, 1
    imul ecx, [P_LIN + OFS]
    lea edx, [ebp + (%3 - FX) + 0x1000]
    cmp ecx, edx
    FAILIF %1, %2
%elif %1 == 5        ; PUSH m32
    push dword [P_LIN + OFS]
    pop ecx
    lea edx, [ebp + (%3 - FX) + 0x1000]
    cmp ecx, edx
    FAILIF %1, %2
%endif
    inc ebp
%endmacro

%macro SWEEP 1                      ; %1 mode
%assign kk 1
%rep 5
%assign pp 0
%rep 8
    TEST1 kk, pp, FY, %1
    TEST1 kk, pp, FX, %1
%assign pp pp+1
%endrep
%assign kk kk+1
%endrep
%endmacro

start:
    mov esp, 0x8000
    cld
    ; PD1/PT1: copy of PD0/PT0 with P -> FY
    mov esi, 0x1000
    mov edi, PT1
    mov ecx, 1024
    rep movsd
    mov dword [PT1 + (P_LIN >> 12) * 4], FY | PTE_FL
    mov dword [PD1], PT1 | 0x27
    mov edi, PD1 + 4
    xor eax, eax
    mov ecx, 1023
    rep stosd
    xor ebp, ebp
    mov dword [P_PTE], FX | PTE_FL      ; PD0 maps P -> FX
    xor eax, eax
    mov cr3, eax
    ; warm: touch P a few times
    mov eax, [P_LIN + OFS]
    mov eax, [P_LIN + OFS]

    SWEEP 0
    ; CR3 mode: PD0 maps P -> FX
    mov dword [P_PTE], FX | PTE_FL
    SWEEP 1

    mov al, 1
    out 0xe0, al
    hlt
fail:
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt
