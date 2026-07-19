`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 03:14:21 PM
// Design Name: 
// Module Name: fsm_1101
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


module moore_1101(
    input clk,
    input reset,
    input x,
    output reg y
);

parameter s0=3'd0,
          s1=3'd1,
          s2=3'd2,
          s3=3'd3,
          s4=3'd4;

reg [2:0] present_state, next_state;


always @(posedge clk or posedge reset)
begin
    if(reset)
        present_state <= s0;
    else
        present_state <= next_state;
end

// Next State Logic
always @(*)
begin
    case(present_state)

    s0:
        if(x)
            next_state = s1;
        else
            next_state = s0;

    s1:
        if(x)
            next_state = s2;
        else
            next_state = s0;

    s2:
        if(x)
            next_state = s2;
        else
            next_state = s3;

    s3:
        if(x)
            next_state = s4;
        else
            next_state = s0;

    s4:
        if(x)
            next_state = s2;
        else
            next_state = s0;

    default:
        next_state = s0;

    endcase
end

// Output Logic
always @(*)
begin
    if(present_state == s4)
        y = 1'b1;
    else
        y = 1'b0;
end

endmodule
           
