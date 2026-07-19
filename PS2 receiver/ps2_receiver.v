`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 08:21:56 PM
// Design Name: 
// Module Name: ps2_receiver
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

module ps2_receiver (
    input wire clk,          
    input wire reset,      
    input wire ps2_clk,      
    input wire ps2_data,     
    output reg [7:0] rx_data, 
    output reg data_valid,   
    output reg frame_error   
);

    parameter IDLE   = 3'b000;
    parameter DATA   = 3'b010;
    parameter PARITY = 3'b011;
    parameter STOP   = 3'b100;
    parameter ERROR  = 3'b101;

    reg [2:0] current_state;
    reg [3:0] bit_count;      
    reg [7:0] shift_reg;      

    always @(negedge ps2_clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            bit_count     <= 4'd0;
            shift_reg     <= 8'd0;
            rx_data       <= 8'd0;
            data_valid    <= 1'b0;
            frame_error   <= 1'b0;
        end else begin
            data_valid  <= 1'b0; 
            frame_error <= 1'b0;

            case (current_state)
                IDLE: begin
                    bit_count <= 4'd0;
                    if (ps2_data == 1'b0) // Start bit (0) detected
                        current_state <= DATA; // Directly move to DATA to capture Bit 0
                end

                DATA: begin
                    shift_reg[bit_count] <= ps2_data; // Captures bit 0 to 7 perfectly
                    if (bit_count == 4'd7) begin
                        current_state <= PARITY;
                    end else begin
                        bit_count <= bit_count + 4'd1;
                    end
                end

                PARITY: begin
                    // Parity bit comes here, moving to STOP
                    current_state <= STOP; 
                end

                STOP: begin
                    if (ps2_data == 1'b1) begin // Valid Stop bit (1)
                        rx_data       <= shift_reg;
                        data_valid    <= 1'b1;
                        current_state <= IDLE;
                    end else begin             // Invalid Stop bit (0)
                        frame_error   <= 1'b1; 
                        current_state <= ERROR;
                    end
                end

                ERROR: begin
                    current_state <= IDLE; 
                end

                default: current_state <= IDLE;
            endcase
        end
    end

endmodule