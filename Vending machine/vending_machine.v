`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/19/2026 05:38:46 PM
// Design Name: 
// Module Name: vending_machine
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

module vending_machine(
    input clk,
    input rst,
    input coin_5,      
    input coin_10,     
    output reg item_dispense, 
    output reg change_out     
    );


    parameter [1:0] 
        s0_0rs  = 2'b00, 
        s1_5rs  = 2'b01, 
        s2_10rs = 2'b10, 
        s3_15rs = 2'b11; 

    reg [1:0] state;

    
    always @(posedge clk) begin
        if (rst) begin
            item_dispense <= 1'b0;
            change_out    <= 1'b0;
            state         <= s0_0rs;
        end else begin
            case (state)
                
                s0_0rs: begin
                    item_dispense <= 1'b0;
                    change_out    <= 1'b0;
                    if (coin_5)       state <= s1_5rs;
                    else if (coin_10) state <= s2_10rs;
                    else              state <= s0_0rs;
                end

                s1_5rs: begin
                    if (coin_5)       state <= s2_10rs;
                    else if (coin_10) state <= s3_15rs;
                    else              state <= s1_5rs;
                end

                s2_10rs: begin
                    if (coin_5)       state <= s3_15rs;
                    else if (coin_10) begin
                        // 20rs case: dispense item and give 5rs change
                        item_dispense <= 1'b1;
                        change_out    <= 1'b1;
                        state         <= s0_0rs; 
                    end
                    else              state <= s2_10rs;
                end

                s3_15rs: begin
                    // 15rs reached: dispense item, no change
                    item_dispense <= 1'b1;
                    change_out    <= 1'b0;
                    state         <= s0_0rs; 
                end
                default: state <= s0_0rs;
            endcase
        end
    end

endmodule
