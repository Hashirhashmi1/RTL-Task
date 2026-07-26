`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2026 11:12:26 PM
// Design Name: 
// Module Name: AHB_litee
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


module ahb_lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,

    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output reg                   wr_done,

    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   rd_done,

    output reg  [ADDR_WIDTH-1:0] HADDR,
    output reg                   HWRITE,
    output reg  [1:0]            HTRANS,
    output reg  [2:0]            HSIZE,
    output reg  [DATA_WIDTH-1:0] HWDATA,
    input  wire [DATA_WIDTH-1:0] HRDATA,
    input  wire                  HREADY,
    input  wire                  HRESP
);

    localparam [1:0] IDLE = 2'd0, ADDR = 2'd1, DATA = 2'd2;
    localparam [1:0] TRANS_IDLE = 2'b00, TRANS_NONSEQ = 2'b10;

    reg [1:0] state;
    reg                   write_l;
    reg [ADDR_WIDTH-1:0]  addr_l;
    reg [DATA_WIDTH-1:0]  data_l;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state   <= IDLE;
            HADDR   <= 0;
            HWRITE  <= 0;
            HTRANS  <= TRANS_IDLE;
            HSIZE   <= 3'b010;
            HWDATA  <= 0;
            wr_done <= 0;
            rd_done <= 0;
            rd_data <= 0;
        end else begin
            wr_done <= 0;
            rd_done <= 0;

            case (state)
                IDLE: begin
                    HTRANS <= TRANS_IDLE;
                    if (wr_en || rd_en) begin
                        write_l <= wr_en;
                        addr_l  <= wr_en ? wr_addr : rd_addr;
                        data_l  <= wr_data;
                        state   <= ADDR;
                    end
                end

                ADDR: begin
                    HADDR  <= addr_l;
                    HWRITE <= write_l;
                    HTRANS <= TRANS_NONSEQ;
                    if (HREADY)
                        state <= DATA;
                end

                DATA: begin
                    HTRANS <= TRANS_IDLE;
                    HWDATA <= data_l;
                    if (HREADY) begin
                        if (!write_l) begin
                            rd_data <= HRDATA;
                            rd_done <= 1'b1;
                        end else begin
                            wr_done <= 1'b1;
                        end
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


module ahb_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 16
)(
    input  wire                  HCLK,
    input  wire                  HRESETn,

    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire                  HWRITE,
    input  wire [1:0]            HTRANS,
    input  wire [DATA_WIDTH-1:0] HWDATA,
    output wire [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADY,
    output wire                  HRESP
);

    localparam [1:0] TRANS_NONSEQ = 2'b10;

    reg [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];
    integer i;

    reg                   valid_phase;
    reg                   write_phase;
    reg [ADDR_WIDTH-1:0]  addr_phase;

    assign HREADY = 1'b1;   // zero wait-state slave
    assign HRESP  = 1'b0;   // always OKAY

    wire [$clog2(NUM_REGS)-1:0] windex = addr_phase[$clog2(NUM_REGS)+1:2];
    assign HRDATA = regfile[windex];   // combinational read, same-cycle as write

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            valid_phase <= 1'b0;
            write_phase <= 1'b0;
            addr_phase  <= 0;
            for (i = 0; i < NUM_REGS; i = i + 1)
                regfile[i] <= 0;
        end else begin
            // address phase -> latch for next cycle's data phase
            valid_phase <= (HTRANS == TRANS_NONSEQ);
            write_phase <= HWRITE;
            addr_phase  <= HADDR;

            // data phase
            if (valid_phase && write_phase)
                regfile[windex] <= HWDATA;
        end
    end

endmodule