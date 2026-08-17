//////////////////////////////////////////////////////////////////////////////////
// Create Date: 08/11/2026 08:03:04 PM
// Design Name:       Kyber/ML-KEM Glitch Testing Platform
// Project Name:      Artix-7 Internal Clock Domain Isolation
// Tool Versions:     AMD Vivado v2026.1
//
// Dependencies:      Xilinx Unisim Primitives (STARTUPE2, BUFG)
// 
// Revision:
// Revision 0.01 - Initial file creation and clock distribution pipeline
//
// Additional Comments:
// - Routes raw CFGMCLK from STARTUPE2 onto the Global Clock Tree via BUFG.
// - Requires matching primary clock constraint in XDC (create_clock -period 15.385).
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
// Target Devices: Artix-7 (xc7a15t / QMTECH)
// Description:       Top-level wrapper instantiating the STARTUPE2 primitive and 
//                    BUFG buffer to generate an internal ~65 MHz clock source 
//                    (CFGMCLK). Used for evaluating physical fault injection 
//                    and power/clock glitching vulnerabilities on Post-Quantum 
//                    Cryptography (PQC) hardware targets (ML-KEM).
//////////////////////////////////////////////////////////////////////////////////

module top (
    // No external clk_in port needed!
    output reg led = 1'b0
);


    // 1. Internal ~65 MHz clock from Artix-7 internal oscillator
    wire raw_cfgmclk;
    wire internal_clk;

    // Tap raw internal configuration clock
    STARTUPE2 startup_inst (
        .CFGMCLK(raw_cfgmclk)
    );

    // Instantiate Global Clock Buffer to route CFGMCLK onto FPGA clock tree
    BUFG bufg_inst (
        .I(raw_cfgmclk),
        .O(internal_clk)
    );

    // 2. Heartbeat counter (~0.5s toggle at ~65 MHz)
    reg [24:0] counter = 25'd0;

    always @(posedge internal_clk) begin
        if (counter >= 25'd32_500_000) begin
            counter <= 25'd0;
            led     <= ~led;
        end else begin
            counter <= counter + 1'b1;
        end
    end

    // 3. ILA clocked by buffered internal clock
    ila_0 debug_ila (
        .clk(internal_clk),
        .probe0(1'b1),
        .probe1(counter),
        .probe2(led)
    );

endmodule
