#!/usr/bin/env python3
"""Prepare/run actual-RTL selected EX-read proofs. Default: prepare only.

Slang is the default frontend; --frontend legacy preserves the old diagnostic.
--run invokes Yosys sequentially, with a per-case wall timeout. The calling
gate must also apply its host memory/commit guard. Every invocation gets a
fresh output directory; existing evidence is never overwritten.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4

HERE = Path(__file__).resolve().parent
CPU = HERE.parent
REF = HERE / "reference/selected_ex"
ORIGIN = "85d8190c452e065f9253add1cc86516282c4d8ea"


def canonical(path: Path) -> bytes:
    return path.read_bytes().replace(b"\r\n", b"\n")


def sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha(path: Path) -> str:
    return sha_bytes(path.read_bytes())


def source(path: Path) -> str:
    return canonical(path).decode("utf-8")


def exact_replace(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError(f"Expected exactly one mutation anchor: {old!r}")
    return text.replace(old, new, 1)


def without_comments(text: str) -> str:
    return re.sub(r"//[^\n]*|/\*.*?\*/", "", text, flags=re.S)


def function(text: str, name: str) -> str:
    pattern = r"^function automatic[^\n]*\b" + re.escape(name) + r"\b.*?^endfunction\s*$"
    matches = list(re.finditer(pattern, text, re.S | re.M))
    if len(matches) != 1:
        raise ValueError(f"Cannot bind one actual function {name}")
    return matches[0].group(0).rstrip()


def balanced(text: str, opening: int) -> tuple[str, int]:
    if text[opening] != "(":
        raise ValueError("Not an opening parenthesis")
    depth = 1
    for index in range(opening + 1, len(text)):
        if text[index] == "(":
            depth += 1
        elif text[index] == ")":
            depth -= 1
            if depth == 0:
                return text[opening + 1:index], index + 1
    raise ValueError("Unbalanced source connection")


def instance_ports(text: str, module: str, instance: str) -> dict[str, str]:
    text = without_comments(text)
    match = re.search(r"\b" + re.escape(module) + r"\s+" + re.escape(instance) + r"\s*\(", text)
    if not match:
        raise ValueError(f"Cannot bind actual {module} {instance} instance")
    body, _ = balanced(text, match.end() - 1)
    ports = {}
    index = 0
    while index < len(body):
        match = re.search(r"\.([a-zA-Z0-9_]+)\s*\(", body[index:])
        if not match:
            break
        expr, end = balanced(body, index + match.end() - 1)
        name = match.group(1)
        if name in ports:
            raise ValueError(f"Duplicate named connection {name}")
        ports[name] = expr.strip()
        index = end
    return ports


def module_ports(text: str) -> list[tuple[str, int, str]]:
    text = without_comments(text)
    match = re.search(r"module\s+gpr_write_merge\s+import\s+z486_pkg::\*;\s*\(", text)
    if not match:
        raise ValueError("Cannot bind actual merge header")
    header, _ = balanced(text, match.end() - 1)
    result = []
    for decl in header.split(","):
        match = re.fullmatch(r"\s*(input|output)\s+logic\s*(?:\[(\d+):(\d+)\])?\s*([a-z_0-9]+)\s*", decl)
        if not match:
            raise ValueError(f"Unsupported actual module port {decl!r}")
        direction, high, low, name = match.groups()
        width = abs(int(high) - int(low)) + 1 if high else 1
        result.append((direction, width, name))
    return result


def yosys_module(text: str, new_name: str, constants: str) -> str:
    # Resolve the only package dependency without rewriting its constants.
    text = exact_replace(text, "module gpr_write_merge\n    import z486_pkg::*;",
                         "module " + new_name)
    text, count = re.subn(r"// synthesis translate_off\n.*?// synthesis translate_on", "", text, flags=re.S)
    if count != 1:
        raise ValueError("Unexpected simulation-fuse inventory")
    end_header = text.index("\n);") + len("\n);")
    return text[:end_header] + "\n" + constants + "\n" + text[end_header:]


def declaration(direction: str, width: int, name: str) -> str:
    return f"{direction} wire " + (f"[{width - 1}:0] " if width > 1 else "") + name


def normalized(expr: str) -> str:
    return re.sub(r"\s+", "", expr)


def clocked_blocks(text: str) -> list[str]:
    """Bind the unchanged clocked data-unit text, excluding comments/strings."""
    text = without_comments(text)
    tokens = list(re.finditer(r'"(?:\\.|[^"\\])*"|\balways_ff\b|\bbegin\b|\bend\b', text))
    blocks = []
    for index, token in enumerate(tokens):
        if token.group() != "always_ff":
            continue
        depth = 0
        started = False
        for following in tokens[index + 1:]:
            if following.group() == "always_ff":
                raise ValueError("Unbounded clocked block")
            if following.group() == "begin":
                started = True
                depth += 1
            elif following.group() == "end":
                depth -= 1
                if started and depth == 0:
                    blocks.append(normalized(text[token.start():following.end()]))
                    break
        else:
            raise ValueError("Unterminated clocked block")
    if not blocks:
        raise ValueError("No bound data-unit clocked blocks")
    return blocks


def miter(old_merge: str, new_merge: str, old_du: str, new_du: str, wiring: bool) -> str:
    old_ports, new_ports = module_ports(old_merge), module_ports(new_merge)
    old_in = [(w, n) for d, w, n in old_ports if d == "input"]
    old_out = [(w, n) for d, w, n in old_ports if d == "output"]
    expected_new = old_ports + [("input", 3, "ex_sel_full"), ("input", 3, "ex_sel_byte"),
                                ("output", 32, "ex_full_value"), ("output", 16, "ex_byte_value")]
    if new_ports != expected_new:
        raise ValueError("Unexpected production merge interface change")
    old_conn = instance_ports(old_du, "gpr_write_merge", "gpr_merge")
    new_conn = instance_ports(new_du, "gpr_write_merge", "gpr_merge")
    for _, _, name in old_ports:
        if normalized(old_conn[name]) != normalized(new_conn[name]):
            raise ValueError(f"Existing production connection changed: {name}")
    old_shift = instance_ports(old_du, "shifter", "shifter_inst")
    new_shift = instance_ports(new_du, "shifter", "shifter_inst")
    for name in old_shift:
        if name != "gpr_dst_shift_size" and normalized(old_shift[name]) != normalized(new_shift[name]):
            raise ValueError(f"Other production shifter connection changed: {name}")
    free = [declaration("input", w, n) for w, n in old_in
            if not (wiring and n in ("vis_ex", "vis_ea", "vis_cap"))]
    if wiring:
        free += ["input wire [2:0] dst_reg_sel_r", "input wire [1:0] shift_data_size"]
    else:
        free += ["input wire [2:0] ex_sel_full", "input wire [2:0] ex_sel_byte"]
    lines = ["module selected_ex_miter (", "    " + ",\n    ".join(free + ["output wire mismatch"]), ");"]
    for width, name in old_out:
        lines += [declaration("", width, "old_" + name).strip() + ";",
                  declaration("", width, "new_" + name).strip() + ";"]
    lines += ["wire [31:0] ex_full_value;", "wire [15:0] ex_byte_value;"]
    if wiring:
        for name in ("vis_ex", "vis_ea", "vis_cap"):
            lines.append("wire [7:0] " + name + " = " + new_conn[name] + ";")
        lines += ["wire [2:0] ex_sel_full = " + new_conn["ex_sel_full"] + ";",
                  "wire [2:0] ex_sel_byte = " + new_conn["ex_sel_byte"] + ";"]
    inputs = [f".{n}({n})" for _, n in old_in]
    for kind in ("old", "new"):
        connections = inputs + [f".{n}({kind}_{n})" for _, n in old_out]
        if kind == "new":
            connections += [f".{n}({n})" for n in ("ex_sel_full", "ex_sel_byte", "ex_full_value", "ex_byte_value")]
        lines.append(f"merge_{kind} dut_{kind} (" + ", ".join(connections) + ");")
    comparisons = [f"(old_{n} != new_{n})" for _, n in old_out]
    comparisons += ["(ex_full_value != old_ex_value[ex_sel_full*32 +: 32])",
                    "(ex_byte_value != old_ex_value[ex_sel_byte*32 +: 16])"]
    if wiring:
        old_fun = function(old_du, "read_gpr_load_forwarded_late")
        old_fun = old_fun.replace("read_gpr_load_forwarded_late", "old_read_gpr_load_forwarded_late")
        new_fun = function(new_du, "format_gpr_selected_late")
        lines += ["wire [31:0] gpr_ex_view [0:7];",
                  "genvar i; generate for (i=0; i<8; i=i+1) begin: g_view",
                  "assign gpr_ex_view[i] = old_ex_value[i*32 +: 32];", "end endgenerate", old_fun, new_fun]
        for name, width, producer in (("ex_full_value", 32, "ex_full_value"),
                                      ("ex_byte_value", 16, "ex_byte_value")):
            net = new_conn[name]
            if not re.fullmatch(r"[a-zA-Z_][a-zA-Z_0-9]*", net):
                raise ValueError("Selected EX output is not a named wire")
            lines.append(declaration("", width, net).strip() + " = " + producer + ";")
        old_expr = old_shift["gpr_dst_shift_size"].replace("read_gpr_load_forwarded_late", "old_read_gpr_load_forwarded_late")
        new_expr = new_shift["gpr_dst_shift_size"]
        lines += ["wire [31:0] old_formatted = " + old_expr + ";",
                  "wire [31:0] new_formatted = " + new_expr + ";"]
        comparisons.append("(old_formatted != new_formatted)")
    lines += ["assign mismatch = " + " ||\n    ".join(comparisons) + ";", "endmodule", ""]
    return "\n".join(lines)


def resolve_tooling(yosys: str, frontend: str, plugin: str | None) -> dict:
    """Bind an explicit tool/plugin before creating or executing any case."""
    executable = shutil.which(yosys)
    if executable is None:
        raise ValueError("Yosys is required; absence is not a skipped pass")
    executable = Path(executable).resolve(strict=True)
    if not executable.is_file():
        raise ValueError("Yosys executable is not a file")
    plugin_path = None
    if frontend == "slang":
        explicit = plugin or os.environ.get("YOSYS_SLANG_PLUGIN")
        if explicit:
            plugin_path = Path(explicit).resolve(strict=True)
            if not plugin_path.is_file():
                raise ValueError("Explicit Slang plugin is not a file")
        else:
            candidates = [executable.parent.parent / "share/yosys/plugins/slang.so",
                          executable.parent.parent / "lib/yosys/plugins/slang.so"]
            if os.environ.get("YOSYS_DATDIR"):
                candidates.append(Path(os.environ["YOSYS_DATDIR"]) / "plugins/slang.so")
            available = sorted({p.resolve() for p in candidates if p.is_file()})
            if len(available) != 1:
                raise ValueError("Slang plugin is required; set --slang-plugin or YOSYS_SLANG_PLUGIN "
                                 "to one installed plugin (missing/ambiguous is a failure, never a skip)")
            plugin_path = available[0]
    elif plugin:
        raise ValueError("--slang-plugin requires --frontend slang")
    command = [str(executable), "-T", "-Q"]
    if plugin_path:
        command += ["-m", str(plugin_path)]
    return {"frontend": frontend, "yosys": str(executable), "yosys_sha256": sha(executable),
            "slang_plugin": str(plugin_path) if plugin_path else None,
            "slang_plugin_sha256": sha(plugin_path) if plugin_path else None,
            "command_prefix": command}


def prepare(out: Path, tooling: dict) -> dict:
    manifest = json.loads((REF / "manifest.json").read_text())
    if manifest["origin_commit"] != ORIGIN:
        raise ValueError("Wrong frozen CPU origin")
    for name, expected in manifest["git_blobs"].items():
        data = canonical(REF / name)
        actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if actual != expected:
            raise ValueError("Changed reference Git blob: " + name)
    for name, expected in manifest["unchanged_git_blobs"].items():
        data = canonical(CPU / name)
        actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if actual != expected:
            raise ValueError("Changed protected production Git blob: " + name)
    if canonical(REF / "z486_pkg.sv") != canonical(CPU / "z486_pkg.sv"):
        raise ValueError("CPU package constants changed")
    constants = re.findall(r"^localparam \[1:0\] EA_FWD_[A-Z]+\s*=.*?;[^\n]*", source(REF / "z486_pkg.sv"), re.M)
    if len(constants) != 4:
        raise ValueError("Unexpected package dependency inventory")
    constants_text = "\n".join(constants)
    old_merge, new_merge = source(REF / "gpr_write_merge.sv"), source(CPU / "gpr_write_merge.sv")
    old_du, new_du = source(REF / "data_unit.sv"), source(CPU / "data_unit.sv")
    old_clocked = clocked_blocks(old_du)
    if old_clocked != clocked_blocks(new_du):
        raise ValueError("Production clocked data-unit text changed")
    # Each mutant changes an actual source copy, not the miter's expected value.
    cases = [
        ("module_control", False, new_merge, new_du, True),
        ("destination_wiring_control", True, new_merge, new_du, True),
        ("priority_mutant", False, exact_replace(new_merge,
            "for (int k = 0; k < 8; k++) begin\n            if (visibility[k]",
            "for (int k = 7; k >= 0; k--) begin\n            if (visibility[k]"), new_du, False),
        ("m3_mutant", False, exact_replace(new_merge,
            "!((k == 3) && wb_is_alu))", "1'b1)"), new_du, False),
        ("visibility_mutant", False, exact_replace(new_merge,
            "assign ex_full_value = select_view(ex_sel_full, vis_ex);",
            "assign ex_full_value = select_view(ex_sel_full, vis_cap);"), new_du, False),
        ("ah_index_mutant", True, new_merge, exact_replace(new_du,
            ".ex_sel_byte({1'b0, dst_reg_sel_r[1:0]})", ".ex_sel_byte(dst_reg_sel_r)"), False),
        ("size_11_mutant", True, new_merge, exact_replace(new_du,
            "(size == 2'd1) ? {16'd0, full_src[15:0]} :",
            "(size == 2'd3) ? {16'd0, full_src[15:0]} :"), False),
    ]
    out.mkdir(parents=True, exist_ok=False)
    receipt_cases = []
    frontend_line = ("read_slang --threads 1 --no-implicit-memories --top selected_ex_miter "
                     "old_module.sv new_module.sv miter.sv\n") if tooling["frontend"] == "slang" else (
                     "read_verilog -sv old_module.sv new_module.sv miter.sv\n")
    for name, wiring, merge_variant, du_variant, expected_equivalent in cases:
        case = out / name
        case.mkdir()
        texts = {"old_module.sv": yosys_module(old_merge, "merge_old", constants_text),
                 "new_module.sv": yosys_module(merge_variant, "merge_new", constants_text),
                 "miter.sv": miter(old_merge, merge_variant, old_du, du_variant, wiring),
                 "proof.ys": frontend_line + "prep -top selected_ex_miter\nflatten\nopt_clean\n"
                             "sat -prove mismatch 0 -verify -show-inputs\n"}
        for filename, text in texts.items():
            (case / filename).write_text(text, encoding="utf-8")
        receipt_cases.append({"name": name, "expected_equivalent": expected_equivalent,
                              "actual_merge_variant_sha256": sha_bytes(merge_variant.encode()),
                              "actual_data_unit_variant_sha256": sha_bytes(du_variant.encode()),
                              "command": tooling["command_prefix"] + ["-s", "proof.ys"],
                              "prepared_sha256": {n: sha(case / n) for n in texts}})
    bindings = [CPU / "gpr_write_merge.sv", CPU / "data_unit.sv", CPU / "z486_pkg.sv", CPU / "shifter.sv", Path(__file__),
                REF / "manifest.json", *(REF / n for n in manifest["git_blobs"])]
    bindings.append(Path(tooling["yosys"]))
    if tooling["slang_plugin"]:
        bindings.append(Path(tooling["slang_plugin"]))
    receipt = {"created_utc": datetime.now(timezone.utc).isoformat(), "origin": ORIGIN,
               "scope": "actual combinational merge bodies plus actual destination formatter/port wiring",
               "simulation_fuses_excluded_as_synthesis": True,
               "unchanged_data_unit_clocked_blocks": len(old_clocked),
               "unchanged_clocked_block_sha256": [sha_bytes(b.encode()) for b in old_clocked],
               "shifter_unchanged_at_origin_git_blob": manifest["unchanged_git_blobs"]["shifter.sv"],
               "independent_data_wb_and_fwd_wb": True, "inputs_free_all_producers_and_visibility": True,
               "destination_wiring_visibility": "actual unchanged data_unit constants",
               "tooling": tooling,
               "model_or_compiler_launched": False, "proofs_passed": False,
               "input_sha256": {str(p): sha(p) for p in bindings}, "cases": receipt_cases}
    (out / "preparation.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    return receipt


def verify_prepared(out: Path, receipt: dict) -> None:
    for filename, expected in receipt["input_sha256"].items():
        if sha(Path(filename)) != expected:
            raise ValueError("Input changed after preparation: " + filename)
    for case in receipt["cases"]:
        for filename, expected in case["prepared_sha256"].items():
            if sha(out / case["name"] / filename) != expected:
                raise ValueError("Prepared proof changed: " + case["name"] + "/" + filename)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path)
    ap.add_argument("--run", action="store_true")
    ap.add_argument("--yosys", default="yosys")
    ap.add_argument("--frontend", choices=("slang", "legacy"), default="slang",
                    help="Slang is required by the release gate; legacy retains the old parser diagnostic")
    ap.add_argument("--slang-plugin", help="explicit installed plugin file; otherwise YOSYS_SLANG_PLUGIN or one adjacent installed plugin")
    ap.add_argument("--wall-seconds", type=float, default=120)
    args = ap.parse_args()
    if not 1 <= args.wall_seconds <= 300:
        ap.error("--wall-seconds must be 1..300")
    out = (args.out or HERE / "obj_dir/selected-ex-equiv" /
           (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S") + "-" + uuid4().hex[:8])).resolve()
    tooling = resolve_tooling(args.yosys, args.frontend, args.slang_plugin)
    receipt = prepare(out, tooling)
    verify_prepared(out, receipt)
    print(f"selected-ex: prepared {len(receipt['cases'])} actual-source cases in {out}")
    if not args.run:
        print("selected-ex: no compiler/model launched; proof verdict pending")
        return 0
    results = []
    for case in receipt["cases"]:
        verify_prepared(out, receipt)
        folder = out / case["name"]
        log_path = folder / "yosys.log"
        with log_path.open("wb") as log:
            try:
                run = subprocess.run(case["command"], cwd=folder,
                                     stdout=log, stderr=subprocess.STDOUT, timeout=args.wall_seconds)
                exit_code = run.returncode
            except subprocess.TimeoutExpired:
                exit_code = None
        log = log_path.read_text(encoding="utf-8", errors="replace")
        equivalent = exit_code == 0 and "SAT proof finished - no model found: SUCCESS!" in log
        counterexample = exit_code not in (None, 0) and "SAT proof finished - model found: FAIL!" in log
        accepted = equivalent if case["expected_equivalent"] else counterexample
        results.append({"name": case["name"], "exit_code": exit_code, "equivalent": equivalent,
                        "counterexample": counterexample, "accepted": accepted, "log_sha256": sha(log_path)})
        print(f"selected-ex: {case['name']} {'PASS' if accepted else 'FAIL'}")
        if not accepted:
            break
    verify_prepared(out, receipt)
    passed = len(results) == len(receipt["cases"]) and all(x["accepted"] for x in results)
    (out / "results.json").write_text(json.dumps({"model_or_compiler_launched": True,
        "preparation_sha256": sha(out / "preparation.json"), "tooling": tooling,
        "passed": passed, "results": results}, indent=2) + "\n", encoding="utf-8")
    print(f"selected-ex: {'PASS' if passed else 'FAIL'} (combinational rewrite equivalence only)")
    return 0 if passed else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, KeyError, AssertionError) as error:
        print(f"selected-ex: FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)
