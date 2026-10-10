; hz_rmw_late_finish - guard for the RMW_FAST late finish (docs/z486-hazard-audit.md, "UNSURE RMW
; item resolved"). An RMW_FAST first micro-step that stalled AFTER its D2 preread was accepted would
; finish against whatever the L1 preread registers hold by then (they reload every idle cycle), i.e.
; another access's data. data_access.sv carries the simulation fuse "RMW FIRST-USTEP FINISH WITHOUT
; ITS OWN PROBE"; this program puts many kinds of predecessor directly in front of a run of RMWs
; (ADD, XOR, LOCK OR, INC, XCHG) so a latency sweep can trip it. Expected values are the
; architectural results. Failure data = index of the first failing trial.
BITS 16
ORG 0
start:
    cli
    xor ax, ax
    mov ss, ax
    mov sp, 0x8000
    mov ax, cs
    mov ds, ax
    mov es, ax
    cld
    xor ebp, ebp              ; trial index
    xor edx, edx              ; failing-trial mask low bits

%macro trial 1
    inc ebp
    mov dword [buf], 0x10101010
    mov dword [buf + 4], 0x20202020
    mov dword [buf + 8], 0x30303030
    mov dword [buf + 12], 0x40404040
    mov dword [buf + 32], 0x77777777
    mov eax, [buf]
    mov eax, [buf + 8]
    mov eax, [buf + 12]
    mov eax, [buf + 32]
    mov ecx, 1
    mov bx, buf
    mov si, buf + 32
    mov di, scratch
    %1
    add [buf], ecx
    xor dword [buf + 4], 0x01010101
    lock or dword [buf + 8], 0x0f
    inc dword [buf + 12]
    xchg [buf + 12], ecx
    cmp dword [buf], 0x10101011
    jne %%bad
    cmp dword [buf + 4], 0x21212121
    jne %%bad
    cmp dword [buf + 8], 0x3030303f
    jne %%bad
    cmp dword [buf + 12], 1
    jne %%bad
    cmp ecx, 0x40404041
    je %%ok
%%bad:
    test edx, edx
    jnz %%ok
    mov edx, ebp
%%ok:
%endmacro

%macro P_NONE 0
%endmacro
%macro P_STORE 0
    mov [bx + 64], ecx
%endmacro
%macro P_STORE2 0
    mov [bx + 64], ecx
    mov [bx + 68], ecx
%endmacro
%macro P_CROSS 0
    mov [bx + 83], ecx
%endmacro
%macro P_LOAD 0
    mov eax, [bx + 4]
%endmacro
%macro P_COLD 0
    mov eax, [coldline]
%endmacro
%macro P_RMW 0
    add [bx + 64], ecx
%endmacro
%macro P_PUSH 0
    push ecx
    pop eax
%endmacro
%macro P_STOSD 0
    stosd
%endmacro
%macro P_MOVSD 0
    movsd
%endmacro
%macro P_LODSD 0
    lodsd
%endmacro
%macro P_CMPMEM 0
    cmp [bx + 32], ecx
%endmacro
%macro P_STOREW 0
    mov word [bx + 65], cx
%endmacro
%macro P_CALL 0
    call near subr
%endmacro
%macro P_OUT 0
    out 0xe8, al
%endmacro
%macro P_XCHGM 0
    xchg [bx + 64], ecx
    mov ecx, 1
%endmacro
%macro P_STOREB 0
    mov byte [bx + 67], cl
%endmacro
%macro P_STORE_SAMEW 0
    mov [bx], ecx
    mov dword [buf], 0x10101010
%endmacro

    trial P_NONE
    trial P_STORE
    trial P_STORE2
    trial P_CROSS
    trial P_LOAD
    trial P_COLD
    trial P_RMW
    trial P_PUSH
    trial P_STOSD
    trial P_MOVSD
    trial P_LODSD
    trial P_CMPMEM
    trial P_STOREW
    trial P_CALL
    trial P_OUT
    trial P_XCHGM
    trial P_STOREB
    trial P_STORE_SAMEW

    test edx, edx
    jnz fail
    mov al, 1
    out 0xe0, al
    hlt
fail:
    mov eax, edx
    out 0xe4, eax
    mov al, 0xff
    out 0xe0, al
    hlt

subr:
    ret

    align 64
buf:      times 128 db 0
scratch:  times 64 db 0
    align 64
coldline: times 64 db 0
