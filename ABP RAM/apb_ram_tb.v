`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 06:55:47 PM
// Design Name: 
// Module Name: apb_ram_tb
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

module tb_apb_ram;

    reg clk;
    reg rst_n;
    reg psel;
    reg penable;
    reg pwrite;
    reg [31:0] paddr;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    wire pready;
    wire pslverr;

    // Instantiate Unit Under Test (UUT)
    apb_ram uut (
        .clk(clk), .rst_n(rst_n), .psel(psel), .penable(penable), 
        .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata), 
        .prdata(prdata), .pready(pready), .pslverr(pslverr)
    );

   
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Stimulus Block
    initial begin
        // System initialization and Reset
        rst_n = 0; psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0; #20;
        rst_n = 1; #20;

        // --- TEST CASE 1: WRITE OPERATION TO ADDRESS 5 ---
     
        psel = 1; pwrite = 1; paddr = 32'd5; pwdata = 32'hDEADBEEF; #20;
        // 2. ACCESS State (Penable = 1)
        penable = 1; #20;
        // 3. TRANSFER State (Pready will be 1, wait for cycle to finish)
        psel = 0; penable = 0; #20;

        // --- TEST CASE 2: READ OPERATION FROM ADDRESS 5 ---
        // 1. SETUP State (Psel = 1, Pwrite = 0)
        psel = 1; pwrite = 0; paddr = 32'd5; #20;
        // 2. ACCESS State (Penable = 1)
        penable = 1; #20; // At this point prdata should update to 32'hDEADBEEF
        // 3. TRANSFER State
        psel = 0; penable = 0; #20;

        // --- TEST CASE 3: SLAVE ERROR CASE (Address >= 32) ---
        // Trying to write to out-of-bounds address 45
        psel = 1; pwrite = 1; paddr = 32'd45; pwdata = 32'h12345678; #20;
        penable = 1; #20; // Pslverr should jump to 1 here
        psel = 0; penable = 0; #40;

        $finish;
    end

endmodule
