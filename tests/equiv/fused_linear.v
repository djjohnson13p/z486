// check-equiv: functions ../../address_unit.sv fused_linear
// address_unit.sv fused_linear (the shipped text, pasted) against the two-adder
// forms it replaced:
//   EA arm:    effective_linear = wrap16 ? {16'd0, (a + b)[15:0]} + seg
//                                        : (a + b) + seg
//              with a/b = ea_add_a/ea_add_b and wrap16 = ea_is_16bit_r || !issue_eff_mask;
//   stack arm: relocate_issue(issue_stack_offset), issue_stack_offset =
//              stack_dir ? (ss32 ? esp : {16'd0, esp[15:0]})
//                        : (ss32 ? esp - k : {16'd0, esp[15:0] - k16}), k = data32 ? 4 : 2,
//              relocate_issue(o) = (mask ? o : {16'd0, o[15:0]}) + seg,
//              against fused_linear(esp, stack_dir ? 0 : -k, seg, !(ss32 && mask)).
// Every input bit is free. MUTANT=1 drops the 16-bit wrap of the offset sum in
// the reference (a carry out of bit 15 reaches the relocation), which the
// fused form must be told apart from.
module fused_linear #(parameter MUTANT = 0)
  (input [31:0] a, input [31:0] b, input [31:0] seg, input wrap16,
   input [31:0] esp, input stack_dir, input data32, input ss32, input mask,
   output mismatch);
// @@FUNCTIONS@@
  wire [31:0] ab = a + b;
  wire [31:0] ab16 = MUTANT ? ({15'd0, a[15:0]} + {15'd0, b[15:0]}) : {16'd0, ab[15:0]};
  wire [31:0] ea_ref = wrap16 ? ab16 + seg : ab + seg;
  wire [31:0] ea_new = fused_linear(a, b, seg, wrap16);
  wire [31:0] off = stack_dir ? (ss32 ? esp : {16'd0, esp[15:0]})
                              : (ss32 ? esp - (data32 ? 32'd4 : 32'd2)
                                      : {16'd0, esp[15:0] - (data32 ? 16'd4 : 16'd2)});
  wire [31:0] st_ref = (mask ? off : {16'd0, off[15:0]}) + seg;
  wire [31:0] stride = stack_dir ? 32'd0 : (data32 ? -32'd4 : -32'd2);
  wire [31:0] st_new = fused_linear(esp, stride, seg, !(ss32 && mask));
  assign mismatch = (ea_ref != ea_new) || (st_ref != st_new);
endmodule
