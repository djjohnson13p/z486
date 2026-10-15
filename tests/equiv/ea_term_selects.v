// check-equiv: tempinduct
// check-equiv: functions ../../address_unit.sv ea_term_selects ea_pick
// address_unit.sv ea_pick_a/ea_pick_b (the shipped functions, pasted) against
// ea_simple_a/ea_simple_b, the scale/scale-to-base/valid selects of
// ea_scale_operands' terms. The fields and ea_sel_r load on the same free
// d2_start edge from free d2 inputs, as address_unit's always_ff does; the GPR
// values and the displacement are free every cycle; base_value is 0 when the
// base is not valid (data_unit read_ea_gpr: `valid ? gpr_ea_view[idx] : 32'd0`),
// index_value likewise. Sequential: induction from a loaded state.
// MUTANT=1 loads the selects with scale and scale-to-base swapped in role
// (an index scaled on the base arm), which the proof must refute.
module ea_term_selects #(parameter MUTANT = 0)
  (input clk, input d2_start, input [7:0] base_sel, input [7:0] index_sel,
   input s2b_in, input [1:0] scale_in,
   input [31:0] base_raw, input [31:0] index_raw, input [31:0] displacement,
   output mismatch);
// @@FUNCTIONS@@
  reg bv = 1'b0, iv = 1'b0, s2b = 1'b0; reg [1:0] scale = 2'd0;
  reg [12:0] sel = 13'h1010;   // ea_term_selects(0, 0, 0, 0), ea_sel_r's power-up value
  always @(posedge clk)
    if (d2_start) begin
      bv <= |base_sel; iv <= |index_sel; s2b <= s2b_in; scale <= scale_in;
      sel <= ea_term_selects(|base_sel, |index_sel, MUTANT ? !s2b_in : s2b_in, scale_in);
    end
  wire [31:0] base_value  = bv ? base_raw : 32'd0;
  wire [31:0] index_value = iv ? index_raw : 32'd0;
  // ea_scale_operands (z486_pkg.sv), restated
  wire [31:0] base_term  = s2b ? (base_value << scale) : base_value;
  wire [31:0] index_term = s2b ? 32'd0 : (index_value << scale);
  wire two_regs = bv && iv && !s2b;
  wire [31:0] simple_a = bv ? base_term : index_term;
  wire [31:0] simple_b = two_regs ? index_term : displacement;
  wire [31:0] pick_a = ea_pick(sel[3:0], base_value) | ea_pick(sel[7:4], index_value);
  wire [31:0] pick_b = ({32{sel[12]}} & displacement) | ea_pick(sel[11:8], index_value);
  assign mismatch = (pick_a != simple_a) || (pick_b != simple_b);
endmodule
