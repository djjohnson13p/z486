//
// CPU throttle: a clock-enable generator for a GATED z486 clock.
//
// z486 itself knows nothing about speed.  The platform runs z486 from a gated
// copy of clk_sys and this module decides which clk_sys edges the CPU gets.  A
// pause is therefore architecturally invisible by construction: every flop and
// memory inside z486 simply sees fewer clock edges, mid-instruction and
// mid-REP included, so no state needs a "paused" term (docs/throttle-design.md
// section 4, docs/throttle.md for the contract).
//
// Modules in this file:
//   cpu_throttle   Bresenham-even rate generator.  cpu_ce is a REGISTERED
//                  enable: cpu_ce high during a clk cycle means the CPU gets
//                  the clock edge that ENDS this cycle.  Feed it straight to a
//                  clock-gate cell's ena (Cyclone V: ALTCLKCTRL, which latches
//                  ena while its clock is low).  Platform logic that talks to
//                  the CPU uses the same bit as "bus_ce": the CPU samples its
//                  inputs and updates its outputs only at an edge with it high.
//   cpu_clk_gate   Behavioural glitch-free gate (low-phase latch + AND) for
//                  simulation and for targets without a clock-control block.
//   cpu_pulse_hold Holds a one-clk_sys pulse input until the CPU's next
//                  enabled edge.  The platform needs one per pulse input.
//
module cpu_throttle #(
    // The platform clock the CPU clock is gated from, in kHz.  A compile-time
    // parameter so a setting means the same effective MHz at any clk_sys.
    parameter int CLOCK_RATE_KHZ = 50000
)(
    input  logic       clk,         // ungated platform clock
    input  logic       reset_n,
    input  logic [3:0] speed_sel,   // 0 = full speed (cpu_ce constant 1); 14, 15 reserved = full
    output logic       cpu_ce       // registered: the CPU gets the edge ending this cycle
);

// Effective z486 clock-edge rates in kHz.  Plain rate labels (owner, 2026-10-10: exponential steps, 0.5 MHz minimum): this is the rate
// of CPU clock edges, not a machine equivalence (docs/throttle-design.md
// section 5 - calibration against the Xe10 is a later step).
function automatic int rate_khz(input logic [3:0] sel);
    case (sel)
        4'd1:    rate_khz = 33000;
        4'd2:    rate_khz = 25000;
        4'd3:    rate_khz = 16000;
        4'd4:    rate_khz = 12000;
        4'd5:    rate_khz = 8000;
        4'd6:    rate_khz = 6000;
        4'd7:    rate_khz = 4000;
        4'd8:    rate_khz = 3000;
        4'd9:    rate_khz = 2000;
        4'd10:   rate_khz = 1500;
        4'd11:   rate_khz = 1000;
        4'd12:   rate_khz = 750;
        4'd13:   rate_khz = 500;
        default: rate_khz = 0;      // full speed
    endcase
endfunction

localparam int AW = $clog2(CLOCK_RATE_KHZ + 1) + 1;

logic [3:0]    sel_r;
logic [AW-1:0] acc;

// A selection with no rate (0, and the reserved 14 and 15) or at or above the
// platform rate is full speed, which also makes the unselected branch
// const-fold in a build whose clk_sys is low.
wire [AW-1:0] inc     = AW'(rate_khz(sel_r));
wire          full    = (rate_khz(sel_r) == 0) || (rate_khz(sel_r) >= CLOCK_RATE_KHZ);
wire [AW-1:0] sum     = acc + inc;
wire          fire    = sum >= AW'(CLOCK_RATE_KHZ);

always_ff @(posedge clk) begin
    sel_r <= speed_sel;
    if (!reset_n || full) begin
        // Reset runs the CPU at full rate, so a reset held for two or more
        // cycles always reaches the CPU (docs/throttle.md, Reset).
        acc    <= '0;
        cpu_ce <= 1'b1;
    end else begin
        cpu_ce <= fire;
        acc    <= fire ? sum - AW'(CLOCK_RATE_KHZ) : sum;
    end
end

endmodule


module cpu_clk_gate (
    input  logic clk,
    input  logic ena,       // changes only just after a rising clk edge
    output logic gclk
);
    // ena is latched while clk is low, so it cannot glitch gclk.
    logic ena_l;
    always_latch if (!clk) ena_l = ena;
    assign gclk = clk & ena_l;
endmodule


// A pulse presented for one clk_sys cycle, but only sampled by the CPU on its
// enabled edges: hold it until the cycle that ends in one.  The producer must
// not present another pulse while one is still waiting - back-pressure on
// `stall` - and must keep the pulse's data valid until it is consumed.
module cpu_pulse_hold (
    input  logic clk,
    input  logic reset_n,
    input  logic bus_ce,    // the cpu_ce of the cycle (the CPU edge ends it)
    input  logic pulse_i,
    output logic pulse_o,   // to the CPU input
    output logic stall      // the presented pulse is not consumed this cycle
);
    logic pend;
    assign pulse_o = pulse_i | pend;
    assign stall   = pulse_o & ~bus_ce;
    always_ff @(posedge clk)
        if (!reset_n) pend <= 1'b0;
        else          pend <= stall;
    // synthesis translate_off
    always @(posedge clk)
        if (reset_n && pulse_i && pend)
            $fatal(1, "cpu_pulse_hold: a pulse was presented while one was still waiting");
    // synthesis translate_on
endmodule
