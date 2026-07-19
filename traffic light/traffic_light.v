`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 03:56:01 PM
// Design Name: 
// Module Name: traffic_light
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

`timescale 1ns / 1ps

module traffic_light(
    input clk,
    input rst,
    output reg [1:0] out
    );

    
    parameter [1:0] 
        s0 = 2'b00, // Red / Idle
        s1 = 2'b01, // Yellow
        s2 = 2'b10; // Green

    reg [1:0] state;

   
    always @(posedge clk) begin
        if (rst) begin
            out <= s0;      // Output becomes Red/Idle
            state <= s0;    // State goes to s0
        end else begin
            case (state)
                s0: begin
                    out <= s1;       // Output becomes Yellow
                    state <= s1;     // Next state is s1
                end
                
                s1: begin
                    out <= s2;       // Output becomes Green
                    state <= s2;     // Next state is s2
                end
                
                s2: begin
                    out <= s0;       // Output cycles back to Red
                    state <= s0;     // Cycle back to s0
                end
                
                default: begin
                    out <= s0;
                    state <= s0;
                end
            endcase
        end
    end

endmodule