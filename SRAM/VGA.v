`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 08:10:05 PM
// Design Name: 
// Module Name: VGA
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


// Address Generator
module address_generator(
    input clk,
    input reset,
    output reg [5:0] addr
);

always @(posedge clk or posedge reset)
begin
    if(reset)
        addr <= 0;
    else
        addr <= addr + 1;
end

endmodule


// SRAM 64 x 8

module sram(
    input clk,
    input we,
    input [5:0] addr,
    input [7:0] din,
    output reg [7:0] dout
);

reg [7:0] memory [0:63];

integer i;

initial
begin
    for(i=0;i<64;i=i+1)
        memory[i]=i;      
end

always @(posedge clk)
begin
    if(we)
        memory[addr]<=din;

    dout<=memory[addr];
end

endmodule

// VGA Controller

module vga_controller(

input clk,
input reset,
input [7:0] pixel,

output reg hsync,
output reg vsync,

output reg [3:0] red,
output reg [3:0] green,
output reg [3:0] blue,

output reg [5:0] mem_addr

);

reg [2:0] h_count;
reg [2:0] v_count;

always @(posedge clk or posedge reset)
begin

if(reset)
begin
h_count<=0;
v_count<=0;
mem_addr<=0;
end

else
begin

if(h_count==7)
begin
h_count<=0;

if(v_count==7)
v_count<=0;
else
v_count<=v_count+1;

end

else
h_count<=h_count+1;

mem_addr<=v_count*8+h_count;

end

end

always @(*)
begin

hsync=(h_count<7);
vsync=(v_count<7);

red   = pixel[7:4];
green = pixel[7:4];
blue  = pixel[7:4];

end

endmodule
// Top Module


module top(

input clk,
input reset,

output hsync,
output vsync,

output [3:0] red,
output [3:0] green,
output [3:0] blue

);

wire [5:0] address;
wire [5:0] vga_address;

wire [7:0] data;

address_generator AG(

.clk(clk),
.reset(reset),
.addr(address)

);

sram SRAM(

.clk(clk),
.we(1'b0),
.addr(vga_address),
.din(8'b0),
.dout(data)

);

vga_controller VGA(

.clk(clk),
.reset(reset),

.pixel(data),

.hsync(hsync),
.vsync(vsync),

.red(red),
.green(green),
.blue(blue),

.mem_addr(vga_address)

);

endmodule
