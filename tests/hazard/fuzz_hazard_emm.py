#!/usr/bin/env python3
"""fuzz_hazard_emm.py - EMM386 reflection + Borland VROOMM overlay stubs.

The shape the Policenauts stall runs in, as close as a bench gets:
  - a V86 guest at IOPL 0, so every INT n and IRET traps (#GP) to a ring-0
    monitor with a FLAT 32-bit stack, which emulates them: INT n is reflected
    through the guest's IVT (the monitor writes the V86 stack frame by flat
    linear stores and IRETDs to the handler), IRET pops that frame; INT 60h/61h
    are monitor services (remap an EMS-style code window with INVLPG / CR3;
    clear the A and D bits of a block of PTEs and INVLPG them, so the guest's
    next accesses walk and write A/D back);
  - Borland overlay stubs: a far call into a stub that holds `INT 3Fh <k>`
    reaches the guest's overlay manager (reflected), which copies overlay k into
    the NEXT of four rotating buffers (so its address moves), patches the stub to
    `JMP FAR buf:k` with data stores, rewinds the return IP to the stub and
    IRETs (emulated) into the just-written far JMP; other ops unload stubs back
    to `INT 3Fh` and scribble over old buffers with data, as the game does;
  - the guest's own self-modifying near stubs, loops, CALL/RET, the VROOMM
    return-address rewrite (XCHG [BP+2]), hot/cold data and a page-walking
    sweep over many pages;
  - with --irq, random INTR into the monitor, reflected to a guest IRQ handler
    (IVT 08h) that calls, loops, stores and patches its own stub, then IRETs.
The guest folds every result into EBX; HLT makes the monitor report it.
Reference: +z486_fast_off +z486_cache_off; variants: fast on, fast off with
caches, fast toggled at random.

  fuzz_hazard_emm.py --count N [--first S] [--jobs J] [--ops K] [--irq P] [--keep-fail DIR]
"""
import argparse
import concurrent.futures as cf
import os
import random
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))
import test_protected_mode as tpm  # noqa: E402
from fuzz_hazard import run_one   # noqa: E402
from fuzz_hazard_v86 import config  # noqa: E402

CODE = 0x10000
F_OFF = 0xC002              # guest near stubs CS:F_OFF + 6*i: B8 iw C3 CC CC
NF = 24
STUB_SEG = 0x1E00           # overlay stubs STUB_SEG:8*k: CD 3F k (or EA ofs seg)
NOV = 12
BUF_SEGS = (0x3000, 0x3080, 0x3100, 0x3180)   # four overlay buffers, 0x800 each
WIN_SEG, WIN_LIN = 0xD000, 0xD0000
WF = (0x60000, 0x61000)
NW = 16
SWEEP = 0x50000             # 16 pages walked after an A/D clear
PT = 0x1000


def pte(lin):
    return PT + (lin >> 12) * 4


class Gen:
    def __init__(self, seed, nops):
        self.r = random.Random(seed)
        self.G = []
        self.n = 0
        self.nops = nops
        self.cold = 0

    def e(self, s):
        self.G.append("    " + s)

    def lab(self):
        self.n += 1
        return f"g{self.n}"

    def fold(self):
        self.e("movzx eax, ax")
        self.e("rol ebx, 5")
        self.e("xor ebx, eax")

    def pad(self):
        for _ in range(self.r.choice([0, 0, 1, 2, 3, 5, 7])):
            self.e("nop")

    def r16(self):
        return self.r.randrange(1 << 16)

    def op(self):
        r = self.r
        k = r.randrange(100)
        if k < 22:                                    # call an overlay through its stub
            self.e(f"call {STUB_SEG:#x}:{8 * r.randrange(NOV):#x}")
            self.fold()
        elif k < 28:                                  # unload a stub (and scribble a buffer)
            j = r.randrange(NOV)
            self.e("push ds")
            self.e(f"mov ax, {STUB_SEG:#x}")
            self.e("mov ds, ax")
            self.e(f"mov word [{8 * j:#x}], 0x3fcd")
            self.e(f"mov byte [{8 * j + 2:#x}], {j}")
            if r.random() < 0.6:                       # data over overlay j's old copies:
                self.e(f"mov ax, {r.choice(BUF_SEGS):#x}")   # only stub j could reach them,
                self.e("mov ds, ax")                        # and it is unloaded now
                for _ in range(r.randrange(1, 4)):
                    self.e(f"mov word [{8 * j + 2 * r.randrange(4):#x}], {self.r16():#x}")
            self.e("pop ds")
            self.pad()
        elif k < 42:                                  # guest SMC into a near stub
            i = r.randrange(NF)
            if r.random() < 0.3:
                self.e("cmp sp, sp")
                self.e(f"jne near {F_OFF + 6 * i:#x}")
            kk = r.randrange(4)
            a = F_OFF + 6 * i + 1
            if kk == 0:
                self.e(f"mov word [es:{a:#x}], {self.r16():#x}")
            elif kk == 1:
                self.e(f"inc word [es:{a:#x}]")
            elif kk == 2:
                self.e(f"mov si, {self.r16():#x}")
                self.e(f"xchg [es:{a:#x}], si")
            else:
                self.e(f"mov byte [es:{a + r.randrange(2):#x}], {r.randrange(256):#x}")
            self.pad()
            self.e(f"call {F_OFF + 6 * i:#x}")
            self.fold()
        elif k < 50:                                  # a loop with a back edge and an exit test
            lb = self.lab()
            n = r.randrange(2, 6)
            self.e(f"mov cx, {n}")
            self.e("xor ax, ax")
            self.G.append(f"{lb}:")
            self.e(f"add ax, [{2 * r.randrange(0x80):#x}]")
            self.e(f"cmp cx, {r.randrange(1, 6)}")
            self.e(f"je {lb}_x")
            self.e(f"call {F_OFF + 6 * r.randrange(NF):#x}")
            self.G.append(f"{lb}_x:")
            self.e(f"loop {lb}")
            self.fold()
        elif k < 56:                                  # VROOMM return-address rewrite
            lb = self.lab()
            self.e(f"call {lb}")
            self.e("inc ax")
            self.e("inc ax")
            self.e(f"jmp short {lb}_x")
            self.G.append(f"{lb}:")
            self.e("push bp")
            self.e("mov bp, sp")
            self.e(f"mov ax, {self.r16():#x}")
            self.e("push ax")
            self.e("mov ax, [bp + 2]")
            self.e("add ax, 2")
            self.e("xchg ax, [bp + 2]")
            self.e("pop ax")
            self.e("pop bp")
            self.e("ret")
            self.G.append(f"{lb}_x:")
            self.fold()
        elif k < 62:                                  # INT 60h: remap the code window
            self.e(f"mov ax, {r.randrange(2)}")
            self.e(f"mov cl, {int(r.random() < 0.25)}")
            self.e("int 0x60")
            self.pad()
            self.e(f"call {WIN_SEG:#x}:{8 * r.randrange(NW):#x}")
            self.fold()
        elif k < 66:                                  # INT 61h: clear A/D, then walk the sweep
            self.e("int 0x61")
            self.e("push ds")
            self.e(f"mov ax, {SWEEP >> 4:#x}")
            self.e("mov ds, ax")
            for _ in range(r.randrange(2, 6)):
                p = r.randrange(16)
                if r.random() < 0.5:
                    self.e(f"add [{p * 0x1000 + 2 * r.randrange(0x800):#x}], bx")
                else:
                    self.e(f"mov ax, [{p * 0x1000 + 2 * r.randrange(0x800):#x}]")
                    self.e("rol ebx, 3")
                    self.e("xor bx, ax")
            self.e("pop ds")
        elif k < 82:                                  # hot window (DS = 0x2000)
            a = r.randrange(0, 0xfe) & ~1
            kk = r.randrange(4)
            if kk == 0:
                self.e(f"mov ax, [{a:#x}]")
                self.fold()
            elif kk == 1:
                self.e(f"mov [{a:#x}], bx")
            elif kk == 2:
                self.e(f"add [{a:#x}], bx")
            else:
                self.e(f"mov [{a:#x}], bx")
                self.e(f"mov ax, [{a:#x}]")
                self.fold()
        elif k < 90:                                  # cold line (FS = 0x4000)
            if self.cold < 0xff00:
                self.e(f"mov ax, [fs:{self.cold:#x}]")
                self.cold += 0x40
                self.fold()
        else:
            self.branchy()

    def branchy(self):
        """Data-dependent control flow: taken and not-taken Jcc (short and
        near, folded beside CMP/TEST), counted back edges (DEC/JNZ, LOOP),
        JCXZ, JMP SHORT, direct and indirect near calls and RET imm16."""
        r = self.r
        base = self.lab()
        nl = r.randrange(3, 7)
        labs = [f"{base}_{i}" for i in range(nl)] + [f"{base}_end"]
        self.e("xor dx, dx")
        for i in range(nl):
            self.G.append(f"{labs[i]}:")
            fwd = r.choice(labs[i + 1:])
            k = r.randrange(8)
            if k == 0:
                self.e(f"mov ax, [{2 * r.randrange(0x80):#x}]")
                self.e(f"test ax, {1 << r.randrange(16):#x}")
                self.e(f"{r.choice(['jz', 'jnz', 'js', 'jns', 'jp', 'jnp'])} {fwd}")
                self.e("add dx, ax")
            elif k == 1:
                self.e(f"mov ax, [{2 * r.randrange(0x80):#x}]")
                self.e(f"cmp ax, {self.r16():#x}")
                self.e(f"{r.choice(['jb', 'jae', 'jl', 'jge', 'jbe', 'ja'])} near {fwd}")
                self.e("xor dx, ax")
            elif k == 2:
                lp = self.lab()
                self.e(f"mov cx, {r.randrange(1, 5)}")
                self.G.append(f"{lp}:")
                self.e(f"add dx, [{2 * r.randrange(0x80):#x}]")
                self.e(f"loop {lp}")
            elif k == 3:
                lp = self.lab()
                self.e(f"mov si, {r.randrange(1, 5)}")
                self.G.append(f"{lp}:")
                self.e("rol dx, 3")
                self.e("dec si")
                self.e(f"jnz {lp}")
            elif k == 4:
                self.e(f"mov cx, {r.randrange(2)}")
                self.e(f"jcxz {fwd}")
                self.e("inc dx")
            elif k == 5:
                sub = self.lab()
                self.e(f"call {sub}")
                self.e(f"jmp short {sub}_x")
                self.G.append(f"{sub}:")
                self.e(f"add dx, {self.r16():#x}")
                self.e("ret 0" if r.random() < 0.5 else "ret")
                self.G.append(f"{sub}_x:")
            elif k == 6:
                self.e(f"mov si, {F_OFF + 6 * r.randrange(NF):#x}")
                self.e("call si")
                self.e("add dx, ax")
            else:
                self.e(f"jmp short {fwd}")
                self.e("inc dx")
        self.G.append(f"{labs[-1]}:")
        self.e("mov ax, dx")
        self.fold()

    def program(self, irq):
        r = self.r
        for _ in range(self.nops):
            self.op()
        init = []
        for i in range(NF):
            init.append(f"    mov dword [{CODE + F_OFF + 6 * i:#x}], {0xb8 | (self.r16() << 8) | (0xc3 << 24):#x}")
            init.append(f"    mov word [{CODE + F_OFF + 6 * i + 4:#x}], 0xcccc")
        for kk in range(NOV):
            init.append(f"    mov dword [{(STUB_SEG << 4) + 8 * kk:#x}], {0x3fcd | (kk << 16):#x}")
            init.append(f"    mov dword [{(STUB_SEG << 4) + 8 * kk + 4:#x}], 0xcccccccc")
        for f in WF:
            for j in range(NW):
                init.append(f"    mov dword [{f + 8 * j:#x}], 0xb8cc01eb")
                init.append(f"    mov dword [{f + 8 * j + 4:#x}], {self.r16() | 0xcccb0000:#x}")
        eflags = 0x00020202 if irq else 0x00020002
        guest = "\n".join(self.G)
        return f"""BITS 16
ORG 0
start:
    cli
    cld
    mov ax, cs
    mov ds, ax
    lgdt [gdt_desc]
    lidt [idt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pm32
BITS 32
pm32:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x7f000
    mov ax, 0x20
    ltr ax
    mov dword [{pte(WIN_LIN):#x}], {WF[0] | 0x27:#x}
    xor eax, eax
    mov cr3, eax
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
{chr(10).join(init)}
    mov dword [0x08 * 4], 0x10000000 + irqh   ; guest IVT: IRQ0 -> 1000:irqh
    mov dword [0x3f * 4], 0x10000000 + ovlh   ; INT 3Fh -> 1000:ovlh
    mov edi, 0x20000
    mov eax, 0x13579bdf
    mov ecx, 64
hfill:
    stosd
    rol eax, 7
    loop hfill
    wbinvd
    push dword 0
    push dword 0x4000                ; FS (cold)
    push dword 0x2000                ; DS (hot)
    push dword 0x1000                ; ES (own code)
    push dword 0                     ; SS
    push dword 0x7000                ; SP
    push dword {eflags:#x}           ; VM, IOPL 0
    push dword 0x1000
    push dword v86
    iretd

; ---- ring-0 monitor: a flat 32-bit stack, so its RETs are predicted ----
mon_sub:
    add dword [0x7ff00], 1
    ret
mon_sub2:
    call mon_sub
    ret
; reflect: EBP = frame (EIP at [ebp]), ECX = vector, EDX = return IP
reflect:
    movzx esi, word [ebp + 16]       ; SS
    shl esi, 4
    movzx edi, word [ebp + 12]       ; SP
    sub edi, 6
    mov [ebp + 12], di
    add esi, edi
    mov [esi], dx                    ; IP
    mov ax, [ebp + 4]
    mov [esi + 2], ax                ; CS
    mov eax, [ebp + 8]
    mov [esi + 4], ax                ; FLAGS
    and dword [ebp + 8], ~0x300      ; the handler runs with IF and TF clear
    mov eax, [ecx * 4]
    movzx edx, ax
    mov [ebp], edx                   ; IP from the IVT
    shr eax, 16
    mov [ebp + 4], eax               ; CS
    call mon_sub
    ret
gp:
    add esp, 4                       ; error code
    pushad
    push ds
    mov ax, 0x10
    mov ds, ax
    lea ebp, [esp + 36]              ; EIP, CS, EFLAGS, ESP, SS
    call mon_sub2
    movzx esi, word [ebp + 4]
    shl esi, 4
    add esi, [ebp]
    mov al, [esi]
    cmp al, 0xcd
    je .int
    cmp al, 0xcf
    je .iret
    cmp al, 0xf4
    je .hlt
    jmp .bad
.int:
    movzx ecx, byte [esi + 1]
    cmp ecx, 0x60
    je .svc60
    cmp ecx, 0x61
    je .svc61
    mov edx, [ebp]
    add edx, 2
    call reflect
    jmp .out
.svc60:                              ; AL bit0 = frame, CL bit0 = CR3 reload
    add dword [ebp], 2
    mov eax, [esp + 32]              ; the guest's EAX / ECX from PUSHAD
    mov edx, {WF[0] | 0x27:#x}
    test al, 1
    jz .w0
    mov edx, {WF[1] | 0x27:#x}
.w0:
    mov [{pte(WIN_LIN):#x}], edx
    call mon_sub
    test byte [esp + 28], 1
    jnz .w1
    invlpg [{WIN_LIN:#x}]
    jmp .out
.w1:
    mov eax, cr3
    mov cr3, eax
    jmp .out
.svc61:                              ; clear A/D of the sweep's 16 PTEs, INVLPG each
    add dword [ebp], 2
    mov ecx, 16
    mov esi, {pte(SWEEP):#x}
    mov edi, {SWEEP:#x}
.s61:
    and dword [esi], ~0x60
    invlpg [edi]
    add esi, 4
    add edi, 0x1000
    call mon_sub
    loop .s61
    jmp .out
.iret:
    movzx esi, word [ebp + 16]
    shl esi, 4
    movzx edi, word [ebp + 12]
    add esi, edi
    add word [ebp + 12], 6
    movzx eax, word [esi]
    mov [ebp], eax                   ; IP
    movzx eax, word [esi + 2]
    mov [ebp + 4], eax               ; CS
    movzx eax, word [esi + 4]
    and eax, 0x0ed5
    or eax, 0x00020002               ; VM, IOPL 0
    mov [ebp + 8], eax
    call mon_sub
    jmp .out
.hlt:
    mov eax, [esp + 20]              ; the guest's EBX
    out 0xe4, eax
    mov al, 1
    out 0xe0, al
    hlt
.bad:
    mov eax, [ebp]
    or eax, 0xbad00000
    out 0xe4, eax
    mov al, 1
    out 0xe0, al
    hlt
.out:
    pop ds
    popad
    iretd
irq:                                 ; reflect INTR to the guest's IVT 08h
    pushad
    push ds
    mov ax, 0x10
    mov ds, ax
    lea ebp, [esp + 36]
    mov ecx, 0x08
    mov edx, [ebp]
    call reflect
    pop ds
    popad
    iretd

; ---- V86 guest ----
BITS 16
v86:
    xor ebx, ebx
{guest}
    xor si, si
    mov cx, 0x80
gfold:
    lodsw
    movzx eax, ax
    rol ebx, 5
    xor ebx, eax
    loop gfold
    hlt

; INT 3Fh (reflected): load overlay k into the next buffer, patch the stub to
; JMP FAR buf:8*k, return to the stub start. Frame: [bp+2] IP after CD 3F.
ovlh:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push si
    push di
    push ds
    push es
    mov ax, {STUB_SEG:#x}
    mov ds, ax
    mov si, [bp + 2]
    movzx bx, byte [si]              ; k
    mov ax, [cs:ovl_cnt]
    inc word [cs:ovl_cnt]
    mov di, ax
    and di, 3
    shl di, 1
    mov cx, [cs:ovl_buf + di]        ; the next buffer
    mov es, cx
    mov di, bx
    shl di, 3                        ; 8 * k
    mov byte [es:di], 0xb8           ; mov ax, (k * 0x0101) ^ count
    imul ax, ax, 0x3b
    xor ax, bx
    mov [es:di + 1], ax
    mov byte [es:di + 3], 0xcb       ; retf
    mov byte [si - 2], 0xea          ; patch the stub: JMP FAR es:di
    mov [si - 1], di
    mov [si + 1], es
    sub word [bp + 2], 2             ; return into the patched stub
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
    iret
ovl_cnt: dw 0
ovl_buf: dw {", ".join(hex(s) for s in BUF_SEGS)}

; the guest IRQ handler: calls, a loop, stores and its own SMC, all private
irqh:
    push ax
    push cx
    push ds
    mov ax, 0x6f00
    mov ds, ax
    inc word [0]
    mov cx, 3
.l:
    add [2], cx
    call irq_sub
    loop .l
    inc word [es:irq_stub + 1]
    call irq_stub
    mov [4], ax
    pop ds
    pop cx
    pop ax
    iret
irq_sub:
    add word [6], 1
    ret
irq_stub:
    mov ax, 0
    ret

align 8
gdt:
    dq 0
    dw 0xffff, 0x0000                ; 0x08 code: base 0x10000, 32-bit
    db 0x01, 10011010b, 0xcf, 0
    dw 0xffff, 0x0000                ; 0x10 data: flat
    db 0x00, 10010010b, 0xcf, 0
    dw 0xffff, 0x0000
    db 0x00, 10010010b, 0xcf, 0
    dw 0x0067, tss                   ; 0x20 TSS
    db 0x01, 10001001b, 0, 0
gdt_end:
gdt_desc:
    dw gdt_end - gdt - 1
    dd gdt + 0x10000
align 8
idt:
    times 13 dq 0
    dw gp, 0x08
    db 0, 10001110b
    dw 0
    times (0x20 - 14) dq 0
    dw irq, 0x08
    db 0, 10001110b
    dw 0
    times (256 - 0x21) dq 0
idt_end:
idt_desc:
    dw idt_end - idt - 1
    dd idt + 0x10000
align 4
tss:
    dd 0, 0x7f000, 0x10
    times 22 dd 0
    dw 0, 104
%if ($ - $$) > {F_OFF - 2:#x}
%error program overlaps the stub area
%endif
"""


def seed_job(seed, nops, irq, keep_dir):
    r = random.Random(seed * 15485863 + 7)
    lat = r.randrange(0, 33)
    narrow = r.random() < 0.3
    toggle = r.choice([37, 101, 257, 997])
    work = Path(tempfile.mkdtemp(prefix=f"fze_{seed}_"))
    stem = work / f"fze_{seed}"
    stem.with_suffix(".asm").write_text(Gen(seed, nops).program(irq))
    cfg = config(stem.name, lat)
    if not tpm.assemble(stem.with_suffix(".asm"), stem.with_suffix(".bin"),
                        stem.with_suffix(".lst")):
        return seed, f"lat {lat}", "ASM FAIL", {}
    tpm.build_memory_image(cfg, stem.with_suffix(".bin"), stem.with_suffix(".hex"))
    # +spec_check: the bench's branch-target buffer oracle (a stale seeded line
    # is a $fatal, i.e. a FATAL result, even when the checksum survives it).
    base = [f"+mem_latency={lat}", "+spec_check"] + (["+no_line_fill"] if narrow else [])
    # FUZZ_EXTRA="+zero_wait": plusargs for every run (the reference too)
    base += os.environ.get("FUZZ_EXTRA", "").split()
    ref = run_one(stem, cfg, base + ["+z486_fast_off", "+z486_cache_off"] +
                  ([f"+fuzz_irq_period={irq * 8}"] if irq else []))
    if irq:
        base.append(f"+fuzz_irq_period={irq}")
    res = {
        "fast": run_one(stem, cfg, base),
        "fastoff": run_one(stem, cfg, base + ["+z486_fast_off"]),
        f"toggle{toggle}": run_one(stem, cfg, base + [f"+z486_fast_toggle={toggle}"]),
    }
    # FUZZ_THROTTLE="2 5 7": also run at those CPU throttle settings (the CPU's
    # clock gated, memory and I/O at full rate) against the same reference.
    for sel in os.environ.get("FUZZ_THROTTLE", "").replace(",", " ").split():
        res[f"thr{sel}"] = run_one(stem, cfg, base + [f"+cpu_speed={sel}"])
    if any(v != ref for v in res.values()) and keep_dir:
        Path(keep_dir).mkdir(parents=True, exist_ok=True)
        shutil.copy(stem.with_suffix(".asm"), Path(keep_dir) / f"fze_{seed}.asm")
    shutil.rmtree(work, ignore_errors=True)
    return seed, f"lat {lat}{' narrow' if narrow else ''}{f' irq{irq}' if irq else ''}", ref, res


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--count", type=int, default=8)
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--ops", type=int, default=400)
    ap.add_argument("--irq", type=int, default=0)
    ap.add_argument("--keep-fail", default="")
    a = ap.parse_args()
    if a.jobs > 8 and not os.environ.get("FUZZ_ALLOW_WIDE"):
        print("--jobs capped at 8 (set FUZZ_ALLOW_WIDE=1 on a dedicated host)")
        a.jobs = 8
    bad = n = 0
    with cf.ProcessPoolExecutor(max_workers=a.jobs) as ex:
        futs = [ex.submit(seed_job, s, a.ops, a.irq, a.keep_fail)
                for s in range(a.first, a.first + a.count)]
        for f in cf.as_completed(futs):
            seed, desc, ref, res = f.result()
            n += 1
            ok = bool(res) and all(v == ref for v in res.values()) and \
                not ref.startswith(("FATAL", "TIMEOUT", "NOPASS", "NONE", "ASM", "bad"))
            bad += not ok
            print(f"SEED {seed} {desc} ref {ref} " +
                  " ".join(f"{k} {v}" for k, v in res.items()) +
                  (" MATCH" if ok else " MISMATCH"), flush=True)
    print(f"fuzz_hazard_emm: {n - bad}/{n} seeds match")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
