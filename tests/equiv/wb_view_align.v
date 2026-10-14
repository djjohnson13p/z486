// check-equiv: functions ../../gpr_write_merge.sv be_of_size align_of_size
// gpr_write_merge.sv pv3f (producer 3 as the views see it) in one view lane,
// with be_of_size/align_of_size pasted from the RTL.
// old: pv3f = align_of_size(size_wb, dst_wb[2], fwd_wb).
// new: pv3f = {fwd_wb[31:16], (size_wb == 0 && dst_wb[2]) ? fwd_wb[7:0]
//                                                       : fwd_wb[15:8], fwd_wb[7:0]}.
// A view lane b selects pv3f only under hitv3 = v_wb && en3[b] && !wb_is_alu,
// en3 = (dst_norm(3) == r) ? be_of_size(size_wb, dst_wb[2]) : 0 (the register
// match is folded into `match`); `other` is the rest of the priority chain.
// Every lane, size, AH bit, datum and chain value is free. MUTANT=1 drops the
// AH select of lane 1 and must be refuted.
module wb_view_align #(parameter MUTANT = 0)
  (input v_wb, input wb_is_alu, input match, input [1:0] size_wb, input [2:0] dst_wb,
   input [31:0] fwd_wb, input [1:0] lane, input [7:0] other, output mismatch);
// @@FUNCTIONS@@
  wire [31:0] pv3f_old = align_of_size(size_wb, dst_wb[2], fwd_wb);
  wire        ah = MUTANT ? 1'b0 : ((size_wb == 2'd0) && dst_wb[2]);
  wire [31:0] pv3f_new = {fwd_wb[31:16], ah ? fwd_wb[7:0] : fwd_wb[15:8], fwd_wb[7:0]};
  wire [3:0]  en3 = match ? be_of_size(size_wb, dst_wb[2]) : 4'h0;
  wire        hitv3 = v_wb && en3[lane] && !wb_is_alu;
  wire [7:0]  old_v = hitv3 ? pv3f_old[lane*8 +: 8] : other;
  wire [7:0]  new_v = hitv3 ? pv3f_new[lane*8 +: 8] : other;
  assign mismatch = old_v != new_v;
endmodule
