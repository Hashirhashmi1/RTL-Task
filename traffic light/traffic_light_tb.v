`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 03:58:24 PM
// Design Name: 
// Module Name: traffic_light_tb
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

module tb_traffic_light;

    reg clk;
    reg rst;
    wire [1:0] out;

    traffic_light uut (
        .clk(clk),
        .rst(rst),
        .out(out)
    );
    // Clock generator
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    // Simulation stimulus
    initial begin
        rst = 1; #20;   // Apply reset
        rst = 0; #200;  // Let it run the one-way cycle
        $finish;
    end

endmodule