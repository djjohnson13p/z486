// segmentation_unit.sv lar_result/llim_result/lbas_result, read by address_unit.sv
// exec_ind_r under exec with ind_op LAR(6)/LLIM(7)/LBAS(8).
// old: keyed by seg_target = z486.sv seg_cmd_target (i_issue ? init_final_seg : uc_seg_target).
// new: keyed by exec_seg_target = uc_seg_target.
// The read-back is modelled as an arbitrary table rb[target] (every descriptor
// value free). The rewrite holds under the invariant z486.sv asserts in
// simulation: no LAR/LLIM/LBAS word executes in an issue cycle.
// MUTANT=1 keys the new side by init_final_seg and must be refuted.
module lar_exec_target #(parameter MUTANT = 0)
  (input i_issue, input exec, input [3:0] ind_op,
   input [3:0] init_final_seg, input [3:0] uc_seg_target,
   input [32*16-1:0] rb, input [31:0] exec_ind_q, output mismatch);
  wire rd = (ind_op == 4'd6) || (ind_op == 4'd7) || (ind_op == 4'd8);
  wire [3:0] seg_cmd_target = i_issue ? init_final_seg : uc_seg_target;
  wire [3:0] new_key = MUTANT ? init_final_seg : uc_seg_target;
  wire [31:0] old_v = rb[seg_cmd_target*32 +: 32];
  wire [31:0] new_v = rb[new_key*32 +: 32];
  wire [31:0] old_d = (exec && rd) ? old_v : exec_ind_q;
  wire [31:0] new_d = (exec && rd) ? new_v : exec_ind_q;
  wire invariant = !(exec && rd && i_issue);
  assign mismatch = invariant && (old_d != new_d);
endmodule
