// check-equiv: functions ../../ucode_recipes.svh recipe_effective_entry recipe_action recipe_entry_action
// decoder.sv handoff_d2.entry.ucode_action (D1 -> skeleton).
// old: recipe_action(handoff_entry_point), where handoff_entry_point =
//      lock ? entry : recipe_effective_entry(entry, opcode, modrm).
// new: recipe_entry_action(entry, opcode, modrm, lock), the action decoded from
//      the raw entry with each overlay's qualifier beside it.
// The three functions are pasted from the GENERATED ucode_recipes.svh, so the
// proof covers the shipped text. Every entry/opcode/ModR/M/LOCK input is free.
// MUTANT=1 drops the LOCK term from the new side (a LOCK-prefixed RMW would take
// the RMW_FAST action) and must be refuted.
module recipe_entry_action #(parameter MUTANT = 0)
  (input [11:0] entry, input [7:0] opcode, input [7:0] modrm, input lock,
   output mismatch);
  localparam logic [2:0] RECIPE_ACTION_NONE = 3'd0;
  localparam logic [2:0] RECIPE_ACTION_X87_OVERLAY = 3'd1;
  localparam logic [2:0] RECIPE_ACTION_INVLPG = 3'd2;
  localparam logic [2:0] RECIPE_ACTION_RMW_FAST = 3'd3;
  localparam logic [2:0] RECIPE_ACTION_CACHE_FLUSH = 3'd4;
// @@FUNCTIONS@@
  wire [11:0] eff = lock ? entry : recipe_effective_entry(entry, opcode, modrm);
  wire [2:0] old_a = recipe_action(eff);
  wire [2:0] new_a = recipe_entry_action(entry, opcode, modrm, MUTANT ? 1'b0 : lock);
  assign mismatch = old_a != new_a;
endmodule
