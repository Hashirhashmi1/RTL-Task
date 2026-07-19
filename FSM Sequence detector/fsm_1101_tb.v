`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 03:26:36 PM
// Design Name: 
// Module Name: fsm_1101_tb
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


`timescale 1ns/1ps

`timescale 1ns/1ps

module tb_moore_1101;

reg clk;
reg reset;
reg x;
wire y;

// Instantiate DUT
moore_1101 uut(
    .clk(clk),
    .reset(reset),
    .x(x),
    .y(y)
);

// Clock generation
always #5 clk = ~clk;

initial
begin
    clk = 0;
    reset = 1;
    x = 0;

    #10 reset = 0;

    // Input sequence: 1101
    x = 1; #10;
    x = 1; #10;
    x = 0; #10;
    x = 1; #10;   // Detection

     

    #20;
    $finish;
end

endmodule

