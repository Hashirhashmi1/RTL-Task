`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 06:52:24 PM
// Design Name: 
// Module Name: apb_ram
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

module apb_ram (
    input clk,               
    input rst_n,             
    input psel,              
    input penable,           
    input pwrite,            
    input [31:0] paddr,      
    input [31:0] pwdata,     
    output reg [31:0] prdata,
    output reg pready,       
    output reg pslverr      
);

   
    parameter [1:0]
        IDLE     = 2'b00,
        SETUP    = 2'b01,
        ACCESS   = 2'b10,
        TRANSFER = 2'b11;

    reg [1:0] state;

    // Memory: logic [31:0] mem [32] 
    reg [31:0] mem [0:31];
    integer i;

    // Sequential logic 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            pready  <= 1'b0;
            pslverr <= 1'b0;
            prdata  <= 32'b0;
            // Clear memory array on reset
            for (i = 0; i < 32; i = i + 1) begin
                mem[i] <= 32'b0;
            end
        end 
        else begin
            case (state)

                IDLE: begin
                    pready  <= 1'b0;
                    pslverr <= 1'b0;
                    if (psel) begin
                        state <= SETUP;
                    end else begin
                        state <= IDLE;
                    end
                end

                SETUP: begin
                    if (psel) begin
                        state <= ACCESS;
                    end else begin
                        state <= SETUP;
                    end
                end

                ACCESS: begin
                    // if (Penable && Psel) logic from page 3 of your notes
                    if (penable && psel) begin
                        state  <= TRANSFER;
                        pready <= 1'b1; // Slave becomes ready

                        // Address check 
                        if (paddr < 32) begin
                            pslverr <= 1'b0;
                            if (pwrite) begin
                                mem[paddr] <= pwdata; // Write operation
                            end else begin
                                prdata     <= mem[paddr]; // Read operation
                            end
                        end 
                        else begin
                            pslverr <= 1'b1; // Error if address >= 32
                            prdata  <= 32'b0;
                        end
                    end
                end

                TRANSFER: begin
                    pready  <= 1'b0;
                    pslverr <= 1'b0;
                    state   <= IDLE; // Back to IDLE after transfer
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
