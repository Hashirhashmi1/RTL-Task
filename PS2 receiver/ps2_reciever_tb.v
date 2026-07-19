`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 08:29:17 PM
// Design Name: 
// Module Name: ps2_reciever_tb
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

`timescale 1ns / 1ps

module tb_ps2_receiver;

    reg clk;
    reg reset;
    reg ps2_clk;
    reg ps2_data;
    wire [7:0] rx_data;
    wire data_valid;
    wire frame_error;

    // Instantiate Unit Under Test (UUT)
    ps2_receiver uut (
        .clk(clk), .reset(reset), .ps2_clk(ps2_clk), 
        .ps2_data(ps2_data), .rx_data(rx_data), 
        .data_valid(data_valid), .frame_error(frame_error)
    );

    // System Clock
    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    // Task to send 11-bit PS2 frame (Start, 8-Data, Parity, Stop)
    task send_ps2_key(input [7:0] code, input send_correct_stop);
        integer i;
        reg odd_parity;
        begin
            odd_parity = !(^code); // Calculate odd parity

            // 1. Start Bit (0)
            ps2_data = 1'b0; #40; ps2_clk = 1'b0; #40; ps2_clk = 1'b1;

            // 2. 8 Data bits (LSB First)
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = code[i]; #40; ps2_clk = 1'b0; #40; ps2_clk = 1'b1;
            end

            // 3. Parity Bit
            ps2_data = odd_parity; #40; ps2_clk = 1'b0; #40; ps2_clk = 1'b1;

            // 4. Stop Bit (1 if correct, 0 to test error)
            ps2_data = send_correct_stop ? 1'b1 : 1'b0; 
            #40; ps2_clk = 1'b0; #40; ps2_clk = 1'b1;
            
            #200; // Delay between keys
        end
    endtask // <-- YAHAN ERROR THA, YEH ENDTASK MISSING THA!

    // Alag se clean initial block stimulus ke liye
    initial begin
        // Initialize
        reset = 1; ps2_clk = 1; ps2_data = 1; #40;
        reset = 0; #40;

        // TC1: Send Key 'A' -> 8'h1C (Should be successful)
        send_ps2_key(8'h1C, 1'b1);

        // TC2: Send Key 'B' -> 8'h32 (Should be successful)
        send_ps2_key(8'h32, 1'b1);

        // TC3: Send Key 'C' -> 8'h21 but with WRONG Stop Bit to trigger Frame Error
        send_ps2_key(8'h21, 1'b0);

        #200;
        $finish;
    end

endmodule
