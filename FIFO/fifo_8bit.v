`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 06:07:31 PM
// Design Name: 
// Module Name: fifo_8bit
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

module fifo(
    input clk,
    input rst,
    input wr,              
    input rd,              
    input [7:0] data_in,   
    output reg [7:0] data_out,
    output full,
    output empty
    );

    reg [2:0] wr_ptr;
    reg [2:0] rd_ptr;
    reg [3:0] count;
    reg [7:0] memory [0:7]; 

    
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 0;
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
        end 
        else if (wr && !full) begin
            memory[wr_ptr] <= data_in;  
            wr_ptr         <= wr_ptr + 1;
            count          <= count + 1;
        end 
        else if (rd && !empty) begin
            data_out <= memory[rd_ptr]; 
            rd_ptr   <= rd_ptr + 1;
            count          <= count - 1;
        end
    end

    assign empty = (count == 0);
    assign full  = (count == 8); 

endmodule
