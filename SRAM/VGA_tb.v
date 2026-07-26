`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 08:11:27 PM
// Design Name: 
// Module Name: VGA_tb
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

module top_tb;
reg clk;
reg reset;

wire hsync;
wire vsync;

wire [3:0] red;
wire [3:0] green;
wire [3:0] blue;

top DUT(

.clk(clk),
.reset(reset),

.hsync(hsync),
.vsync(vsync),

.red(red),
.green(green),
.blue(blue)

);

initial
begin
clk=0;
forever #5 clk=~clk;
end


initial
begin

$dumpfile("vga.vcd");
$dumpvars(0,top_tb);

reset=1;

#20;

reset=0;

#1000;

$finish;

end

endmodule
