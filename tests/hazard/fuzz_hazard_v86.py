#!/usr/bin/env python3
"""fuzz_hazard_v86.py - the V86 + paging (EMM386-style) variant of fuzz_hazard.py.

A ring-0 32-bit monitor with a FLAT 32-bit stack (so its RETs are direct,
RSB-predicted loads) runs a V86 guest under paging, as EMM386 runs DOS:
  - the guest patches its own 16-bit `mov ax, imm16; ret` stubs (MOV w/b, ADD,
    INC, XCHG, STOSW, MOVSW) through its code segment or through a second
    linear alias of the stubs' frame, some imm16s crossing a line, then calls
    them (optionally behind a not-taken Jcc that buffers the line, or one before
    the store), and patches upcoming instructions followed by a JMP;
  - INT 60h (an IDT gate, IOPL 3) asks the monitor to remap an EMS-style code
    window (D000:0) and data window (D400:0) between two frames each, with
    INVLPG or a CR3 reload, the monitor doing CALL/RET pairs on its flat stack
    in between; the guest then far-calls into the window / loads from it;
  - INT 61h makes the MONITOR patch a guest stub (ring-0 store to the guest's
    code through the flat linear address) before IRETD, and the guest calls it;
  - stores into the window's frames through their identity addresses, then a
    far call through the window (a linear alias by page offset);
  - hot-window loads/stores/RMWs and cold-line loads; with --irq, random INTR
    into a ring-0 handler that does CALL/RET work and IRETDs.
The guest folds every result into EBX; HLT (#GP in V86) makes the monitor
report it on port 0xE4. Reference: +z486_fast_off +z486_cache_off; variants: the
fast paths on, fast off with caches, and the fast paths toggled at random.

  fuzz_hazard_v86.py --count N [--first S] [--jobs J] [--ops K] [--irq P] [--keep-fail DIR]
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

CODE = 0x10000             # guest CS = 0x1000, monitor CS base = 0x10000
F_OFF = 0xC002             # stub i at CS:F_OFF + 6*i (B8 iw C3 CC CC)
NF = 40
F_ALIAS_SEG = 0x9C00       # linear 0x9C000 -> frame 0x1C000 (the stubs' page)
WIN_SEG, DWIN_SEG = 0xD000, 0xD400
WIN_LIN, DWIN_LIN = 0xD0000, 0xD4000
WF = (0x60000, 0x61000)    # code-window frames: stub j at +8*j (B8 iw CB ..)
DF = (0x62000, 0x63000)    # data-window frames
NW = 16
PT = 0x1000


def pte(lin):
    return PT + (lin >> 12) * 4


class Gen:
    def __init__(self, seed, nops, irq):
        self.r = random.Random(seed)
        self.G = []          # guest (BITS 16)
        self.n = 0
        self.nops = nops
        self.irq = irq
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
        for _ in range(self.r.choice([0, 0, 1, 2, 3, 4, 5, 6, 7])):
            self.e("nop")

    def r16(self):
        return self.r.randrange(1 << 16)

    def patch(self, seg, off):
        """Store into the imm16 at seg:off (seg is ES=own or GS=alias)."""
        r = self.r
        k = r.randrange(8)
        v = self.r16()
        if k == 0:
            self.e(f"mov word [{seg}:{off:#x}], {v:#x}")
        elif k == 1:
            self.e(f"mov byte [{seg}:{off + r.randrange(2):#x}], {v & 0xff:#x}")
        elif k == 2:
            self.e(f"mov si, {v:#x}")
            self.e(f"add [{seg}:{off:#x}], si")
        elif k == 3:
            self.e(f"inc word [{seg}:{off:#x}]")
        elif k == 4:
            self.e(f"mov si, {v:#x}")
            self.e(f"xchg [{seg}:{off:#x}], si")
        elif k == 5 and seg == "es":
            self.e(f"mov di, {off:#x}")
            self.e(f"mov ax, {v:#x}")
            self.e("stosw")
        elif k == 6 and seg == "es":
            self.e(f"mov si, {self.r.randrange(0, 0x80) * 2:#x}")
            self.e(f"mov di, {off:#x}")
            self.e("movsw")
        else:
            self.e(f"not word [{seg}:{off:#x}]")

    def stub(self, i, alias):
        return (F_OFF + 6 * i - 0xC000) if alias else (F_OFF + 6 * i)

    def jcc(self, i):
        self.e("cmp sp, sp")
        self.e(f"jne near {F_OFF + 6 * i:#x}")

    def op(self):
        r = self.r
        k = r.randrange(100)
        if k < 22:                                   # guest SMC into a stub, then call it
            i = r.randrange(NF)
            alias = r.random() < 0.4
            if r.random() < 0.3:
                self.jcc(i)
            self.patch("gs" if alias else "es", self.stub(i, alias) + 1)
            self.pad()
            if r.random() < 0.4:
                self.jcc(i)
            if r.random() < 0.85:
                self.e(f"call {F_OFF + 6 * i:#x}")
                self.fold()
        elif k < 30:
            self.e(f"call {F_OFF + 6 * r.randrange(NF):#x}")
            self.fold()
        elif k < 34:
            self.jcc(r.randrange(NF))
        elif k < 39:                                 # patch an upcoming instruction
            lb = self.lab()
            self.e(f"mov word [es:{lb} + 1], {self.r16():#x}")
            self.pad()
            self.e(f"jmp {lb}")
            self.G.append(f"{lb}:")
            self.e("mov ax, 0")
            self.fold()
        elif k < 52:                                 # INT 60h: remap the windows
            self.e(f"mov ax, {r.randrange(4):#x}")   # AL bit0 code frame, AH bit0 data frame
            if r.random() < 0.5:
                self.e("mov ah, al")
                self.e("shr ah, 1")
            self.e(f"mov cl, {int(r.random() < 0.25)}")  # 1 = CR3 reload instead of INVLPG
            self.e("int 0x60")
            self.pad()
            if r.random() < 0.7:
                self.e(f"call {WIN_SEG:#x}:{8 * r.randrange(NW):#x}")
                self.fold()
            if r.random() < 0.6:
                self.e("push ds")
                self.e(f"mov ax, {DWIN_SEG:#x}")
                self.e("mov ds, ax")
                self.e(f"mov ax, [{2 * r.randrange(2048):#x}]")
                if r.random() < 0.4:
                    self.e(f"add [{2 * r.randrange(2048):#x}], bx")
                self.e("pop ds")
                self.fold()
        elif k < 58:                                 # INT 61h: the monitor patches a stub
            i = r.randrange(NF)
            self.e(f"mov si, {i}")
            self.e(f"mov dx, {self.r16():#x}")
            self.e("int 0x61")
            self.pad()
            self.e(f"call {F_OFF + 6 * i:#x}")
            self.fold()
        elif k < 63:                                 # store into a window frame by identity
            fr = r.choice(WF)
            j = r.randrange(NW)
            self.e("push ds")
            self.e(f"mov ax, {fr >> 4:#x}")
            self.e("mov ds, ax")
            self.e(f"mov word [{8 * j + 1:#x}], {self.r16():#x}")
            self.e("pop ds")
            self.pad()
            self.e(f"call {WIN_SEG:#x}:{8 * j:#x}")
            self.fold()
        elif k < 80:                                 # hot window (DS = 0x2000)
            a = r.randrange(0, 0xfe)
            if r.random() < 0.7:
                a &= ~1
            kk = r.randrange(5)
            if kk == 0:
                self.e(f"mov ax, [{a:#x}]")
                self.fold()
            elif kk == 1:
                self.e(f"mov [{a:#x}], bx")
            elif kk == 2:
                self.e(f"add [{a:#x}], bx")
            elif kk == 3:
                self.e(f"mov [{a:#x}], bx")
                self.e(f"mov ax, [{a:#x}]")
                self.fold()
            else:
                self.e(f"inc word [{a & ~1:#x}]")
        elif k < 94:                                 # cold line (FS = 0x4000)
            if self.cold < 0xff00:
                self.e(f"mov ax, [fs:{self.cold:#x}]")
                self.cold += 0x40
                self.fold()
        else:
            self.e("mov ax, 0")                      # a guest RET through the stack
            lb = self.lab()
            self.e(f"call {lb}")
            self.e("jmp short " + lb + "_x")
            self.G.append(f"{lb}:")
            self.e(f"mov ax, {self.r16():#x}")
            self.e("ret")
            self.G.append(f"{lb}_x:")
            self.fold()

    def program(self):
        r = self.r
        for _ in range(self.nops):
            self.op()
        stubs = []
        for i in range(NF):
            v = self.r16()
            stubs.append((F_OFF + 6 * i, 0xb8 | (v << 8) | (0xc3 << 24), 0xcccc))
        wins = []
        for f in WF:
            for j in range(NW):
                v = self.r16()
                wins.append((f + 8 * j, 0xb8 | (v << 8) | (0xcb << 24)))
        dseed = self.r.randrange(1 << 32)
        eflags = 0x00023202 if self.irq else 0x00023002   # VM, IOPL 3, (IF)
        mon_init = []
        for off, d0, w1 in stubs:
            mon_init.append(f"    mov dword [{CODE + off:#x}], {d0:#x}")
            mon_init.append(f"    mov word [{CODE + off + 4:#x}], {w1:#x}")
        for a, d0 in wins:
            mon_init.append(f"    mov dword [{a:#x}], {d0:#x}")
            mon_init.append(f"    mov dword [{a + 4:#x}], 0xcccccccc")
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
    mov dword [{pte(0x9C000):#x}], 0x1c027
    mov dword [{pte(WIN_LIN):#x}], {WF[0] | 0x27:#x}
    mov dword [{pte(DWIN_LIN):#x}], {DF[0] | 0x27:#x}
    xor eax, eax
    mov cr3, eax
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
{chr(10).join(mon_init)}
    mov edi, {DF[0]:#x}
    mov eax, {dseed:#x}
    mov ecx, 2048
dfill:
    stosd
    add eax, 0x9e3779b9
    loop dfill
    mov edi, 0x20000
    mov ecx, 64
hfill:
    stosd
    rol eax, 7
    loop hfill
    wbinvd
    push dword 0x9c00                ; GS (the stubs' alias)
    push dword 0x4000                ; FS (cold)
    push dword 0x2000                ; DS (hot)
    push dword 0x1000                ; ES (own code)
    push dword 0x0000                ; SS
    push dword 0x7000                ; SP
    push dword {eflags:#x}
    push dword 0x1000                ; CS
    push dword v86
    iretd

; ---- ring-0 monitor (flat 32-bit stack: its RETs are predicted direct loads) ----
mon_sub:
    add dword [0x7ff00], 1
    ret
mon_sub2:
    call mon_sub
    ret
int60:                               ; AL bit0: code window frame, AH bit0: data window frame, CL: 1 = CR3
    pushad
    push ds
    mov bx, 0x10
    mov ds, bx
    call mon_sub
    mov edx, {WF[0] | 0x27:#x}
    test al, 1
    jz .c0
    mov edx, {WF[1] | 0x27:#x}
.c0:
    mov [{pte(WIN_LIN):#x}], edx
    mov edx, {DF[0] | 0x27:#x}
    test ah, 1
    jz .d0
    mov edx, {DF[1] | 0x27:#x}
.d0:
    mov [{pte(DWIN_LIN):#x}], edx
    call mon_sub2
    test cl, 1
    jnz .cr3
    invlpg [{WIN_LIN:#x}]
    invlpg [{DWIN_LIN:#x}]
    jmp .done
.cr3:
    mov eax, cr3
    mov cr3, eax
.done:
    call mon_sub
    pop ds
    popad
    iretd
int61:                               ; patch guest stub SI's imm16 with DX
    pushad
    push ds
    mov ax, 0x10
    mov ds, ax
    movzx esi, si
    imul esi, esi, 6
    call mon_sub
    mov [esi + {CODE + F_OFF + 1:#x}], dx
    call mon_sub2
    pop ds
    popad
    iretd
irq:
    push eax
    push ds
    mov ax, 0x10
    mov ds, ax
    call mon_sub2
    pop ds
    pop eax
    iretd
gp:                                  ; only the guest's final HLT may fault
    mov eax, ebx
    cmp dword [esp + 4], ghlt
    jne .bad
    cmp dword [esp + 8], 0x1000
    je .rep
.bad:
    mov eax, [esp + 4]
    or eax, 0xbad00000
.rep:
    out 0xe4, eax
    mov al, 1
    out 0xe0, al
    hlt

; ---- V86 guest ----
BITS 16
v86:
    xor ebx, ebx
{guest}
    ; fold the hot window, then HLT (#GP -> the monitor reports EBX)
    xor si, si
    mov cx, 0x80
gfold:
    lodsw
    movzx eax, ax
    rol ebx, 5
    xor ebx, eax
    loop gfold
ghlt:
    hlt

align 8
gdt:
    dq 0
    dw 0xffff, 0x0000                ; 0x08 code: base 0x10000, 4 GiB, 32-bit
    db 0x01, 10011010b, 0xcf, 0
    dw 0xffff, 0x0000                ; 0x10 data: flat, 4 GiB
    db 0x00, 10010010b, 0xcf, 0
    dw 0xffff, 0x0000                ; 0x18 (unused)
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
    times (0x60 - 0x21) dq 0
    dw int60, 0x08
    db 0, 11101110b
    dw 0
    dw int61, 0x08
    db 0, 11101110b
    dw 0
    times (256 - 0x62) dq 0
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


def config(name, lat):
    seg = {"base": 0x10000, "limit": 0xffff, "flags": 0xa9e0}   # ints: run_simulation
    dseg = {"base": 0, "limit": 0xffff, "flags": 0x29e0}        # passes them verbatim
    return {"asm": name + ".asm", "start_mode": "real", "cr0": 0, "cr3": 0, "eip": 0,
            "initial_selectors": {"DS": 0, "SS": 0, "ES": 0, "FS": 0, "GS": 0, "CS": 0x1000},
            "d_init": 0,
            "seg_cache": {"CS": seg, "DS": dseg, "SS": dseg, "ES": dseg, "FS": dseg, "GS": dseg},
            "page_tables": [[0, 0, 128, "RWU"]], "mem_latency": lat, "cycles": 3_000_000}


def seed_job(seed, nops, irq, keep_dir):
    r = random.Random(seed * 104729 + 3)
    lat = r.randrange(0, 33)
    narrow = r.random() < 0.3
    toggle = r.choice([37, 101, 257, 997])
    work = Path(tempfile.mkdtemp(prefix=f"fzv_{seed}_"))
    stem = work / f"fzv_{seed}"
    stem.with_suffix(".asm").write_text(Gen(seed, nops, irq).program())
    cfg = config(stem.name, lat)
    if not tpm.assemble(stem.with_suffix(".asm"), stem.with_suffix(".bin"),
                        stem.with_suffix(".lst")):
        return seed, f"lat {lat}", "ASM FAIL", {}
    tpm.build_memory_image(cfg, stem.with_suffix(".bin"), stem.with_suffix(".hex"))
    base = [f"+mem_latency={lat}"] + (["+no_line_fill"] if narrow else [])
    # IRQs never reach the checksum, so the uncached reference (several times
    # slower per instruction) takes them less often instead of drowning in them.
    ref = run_one(stem, cfg, base + ["+z486_fast_off", "+z486_cache_off"] +
                  ([f"+fuzz_irq_period={irq * 8}"] if irq else []))
    if irq:
        base.append(f"+fuzz_irq_period={irq}")
    res = {
        "fast": run_one(stem, cfg, base),
        "fastoff": run_one(stem, cfg, base + ["+z486_fast_off"]),
        f"toggle{toggle}": run_one(stem, cfg, base + [f"+z486_fast_toggle={toggle}"]),
    }
    if any(v != ref for v in res.values()) and keep_dir:
        Path(keep_dir).mkdir(parents=True, exist_ok=True)
        shutil.copy(stem.with_suffix(".asm"), Path(keep_dir) / f"fzv_{seed}.asm")
    shutil.rmtree(work, ignore_errors=True)
    return seed, f"lat {lat}{' narrow' if narrow else ''}{f' irq{irq}' if irq else ''}", ref, res


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--count", type=int, default=8)
    ap.add_argument("--first", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--ops", type=int, default=400)
    ap.add_argument("--irq", type=int, default=0, help="+fuzz_irq_period (0 = no IRQs)")
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
                not ref.startswith(("FATAL", "TIMEOUT", "NOPASS", "NONE", "ASM"))
            bad += not ok
            print(f"SEED {seed} {desc} ref {ref} " +
                  " ".join(f"{k} {v}" for k, v in res.items()) +
                  (" MATCH" if ok else " MISMATCH"), flush=True)
    print(f"fuzz_hazard_v86: {n - bad}/{n} seeds match")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
