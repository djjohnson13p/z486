// check-equiv: functions ../../prefetch.sv sum_line_eq
// prefetch.sv sum_line_eq (pasted from the RTL): the speculative target-line
// compares spec_match_now / spec_b_match / spec_inflight_match.
// old: k == (a + b)[31:4]  (spec_addr / spec_b_addr against spec_linear).
// new: sum_line_eq(a, b, k), the carry-free form. Every a, b, k bit is free.
// MUTANT=1 flips b's bit 3 on the new side (a low-nibble carry error) and must
// be refuted.
module spec_line_eq #(parameter MUTANT = 0)
  (input [31:0] a, input [31:0] b, input [31:4] k, output mismatch);
// @@FUNCTIONS@@
  wire [31:0] sum = a + b;
  wire old_eq = (k == sum[31:4]);
  wire new_eq = sum_line_eq(a, MUTANT ? (b ^ 32'h8) : b, k);
  assign mismatch = old_eq != new_eq;
endmodule
