`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 05:40:24 PM
// Design Name: 
// Module Name: Vending_machine_tb
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

module tb_vending_machine;

    reg clk;
    reg rst;
    reg coin_5;
    reg coin_10;
    wire item_dispense;
    wire change_out;

    // Instantiate Unit Under Test (UUT)
    vending_machine uut (
        .clk(clk),
        .rst(rst),
        .coin_5(coin_5),
        .coin_10(coin_10),
        .item_dispense(item_dispense),
        .change_out(change_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus block
    initial begin
        rst = 1; coin_5 = 0; coin_10 = 0; #20;
        rst = 0; #20;

        // TC1: 5rs + 10rs = 15rs (Exact amount)
        coin_5 = 1; #20; coin_5 = 0; 
        coin_10 = 1; #20; coin_10 = 0; 
        #20; 

        // TC2: 10rs + 10rs = 20rs (Change case)
        coin_10 = 1; #20; coin_10 = 0; 
        coin_10 = 1; #20; coin_10 = 0; 
        #40;

        $finish;
    end

endmodule
