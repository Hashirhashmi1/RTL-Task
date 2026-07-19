`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 06:08:37 PM
// Design Name: 
// Module Name: fifo_8bit_tf
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

module tb_fifo;

    reg clk;
    reg rst;
    reg wr;
    reg rd;
    reg [7:0] data_in;
    wire [7:0] data_out;
    wire full;
    wire empty;

    // Instantiate Unit Under Test (UUT)
    fifo uut (
        .clk(clk), 
        .rst(rst), 
        .wr(wr), 
        .rd(rd),
        .data_in(data_in), 
        .data_out(data_out), 
        .full(full), 
        .empty(empty)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus block
    initial begin
        // Reset System
        rst = 1; wr = 0; rd = 0; data_in = 0; #20;
        rst = 0; #20;

        // Test Case 1: Write 3 values into FIFO
        data_in = 8'hAA; wr = 1; #20; 
        data_in = 8'hBB; wr = 1; #20; 
        data_in = 8'hCC; wr = 1; #20; 
        wr = 0; #20;

        // Test Case 2: Read values back
        rd = 1; #20; 
        rd = 1; #20; 
        rd = 1; #20; 
        rd = 0; #40;

        $finish;
    end

endmodule
