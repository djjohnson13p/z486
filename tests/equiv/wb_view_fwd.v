// check-equiv: functions ../../gpr_write_merge.sv align_of_size
// gpr_write_merge.sv producer 3 in the three views (byte_ex/byte_ea/byte_cap,
// select_view), as data_unit.sv wires it: data_wb = load_wb_commit_data
// (= load_wb_is_alu ? load_wb_alu_result : load_wb_data), fwd_wb = load_wb_data.
// old: a view lane takes pv3 = align_of_size(size, hb, data_wb) under hitv3.
// new: it takes pv3f = align_of_size(size, hb, fwd_wb) under hitv3.
// hitv3 = hit3 && !wb_is_alu, so the M3 ALU result is never selected and the
// two agree for every input; `other` is the rest of the priority chain.
// The whole-module proof (both revisions' full text, every output) is in the
// commit message. MUTANT=1 drops !wb_is_alu from hitv3 on the new side and
// must be refuted.
module wb_view_fwd #(parameter MUTANT = 0)
  (input hit3, input wb_is_alu, input [1:0] size, input hb,
   input [31:0] alu, input [31:0] data, input [31:0] other, output mismatch);
// @@FUNCTIONS@@
  wire [31:0] data_wb = wb_is_alu ? alu : data;
  wire [31:0] pv3  = align_of_size(size, hb, data_wb);
  wire [31:0] pv3f = align_of_size(size, hb, data);
  wire hitv3_old = hit3 && !wb_is_alu;
  wire hitv3_new = MUTANT ? hit3 : (hit3 && !wb_is_alu);
  wire [31:0] old_v = hitv3_old ? pv3 : other;
  wire [31:0] new_v = hitv3_new ? pv3f : other;
  assign mismatch = old_v != new_v;
endmodule
