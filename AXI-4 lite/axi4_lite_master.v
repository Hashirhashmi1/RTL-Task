`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 09:14:31 PM
// Design Name: 
// Module Name: axi4_lite_master
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


module axi4_lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
  
    input  wire                      clk,
    input  wire                      rst_n,      // active-LOW reset
 
    input  wire                      wr_en,      // pulse 1 cycle to start a write
    input  wire [ADDR_WIDTH-1:0]     wr_addr,
    input  wire [DATA_WIDTH-1:0]     wr_data,
    output reg                       wr_done,    // pulses 1 cycle when write finishes
    output reg  [1:0]                wr_resp,    // 00=OKAY, 10=SLVERR, etc.
 
    input  wire                      rd_en,      // pulse 1 cycle to start a read
    input  wire [ADDR_WIDTH-1:0]     rd_addr,
    output reg  [DATA_WIDTH-1:0]     rd_data,
    output reg                       rd_done,    // pulses 1 cycle when read finishes
    output reg  [1:0]                rd_resp,
 
    output wire                      busy,       // 1 = master currently mid-transaction
 
    // AXI4-Lite WRITE ADDRESS CHANNEL  (Master -> Slave)
    output reg  [ADDR_WIDTH-1:0]     m_axi_awaddr,
    output reg                       m_axi_awvalid,
    input  wire                      m_axi_awready,
 
    // AXI4-Lite WRITE DATA CHANNEL   (Master -> Slave)
 
    output reg  [DATA_WIDTH-1:0]     m_axi_wdata,
    output reg  [(DATA_WIDTH/8)-1:0] m_axi_wstrb,  // byte-lane enables (1 bit per byte)
    output reg                       m_axi_wvalid,
    input  wire                      m_axi_wready,
 
 
    // AXI4-Lite WRITE RESPONSE CHANNEL (Slave -> Master)
    input  wire [1:0]                m_axi_bresp,
    input  wire                      m_axi_bvalid,
    output reg                       m_axi_bready,
 

    // AXI4-Lite READ ADDRESS CHANNEL  (Master -> Slave)
  
    output reg  [ADDR_WIDTH-1:0]     m_axi_araddr,
    output reg                       m_axi_arvalid,
    input  wire                      m_axi_arready,
 
 
    // AXI4-Lite READ DATA CHANNEL    (Slave -> Master)
  
    input  wire [DATA_WIDTH-1:0]     m_axi_rdata,
    input  wire [1:0]                m_axi_rresp,
    input  wire                      m_axi_rvalid,
    output reg                       m_axi_rready
);
 

    localparam [2:0]
        S_IDLE       = 3'd0,  // waiting for wr_en / rd_en
        S_WR_ADDR    = 3'd1,  // driving AWVALID, waiting for AWREADY
        S_WR_DATA    = 3'd2,  // driving WVALID,  waiting for WREADY
        S_WR_RESP    = 3'd3,  // driving BREADY,  waiting for BVALID
        S_RD_ADDR    = 3'd4,  // driving ARVALID, waiting for ARREADY
        S_RD_DATA    = 3'd5;  // driving RREADY,  waiting for RVALID
 
    reg [2:0] state, next_state;
 
    assign busy = (state != S_IDLE);
 
    // Sequential logic: state register

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end
 
    // ---------------------------------------------------------------
    // Combinational logic: next-state decisions
    //
    // Note: AXI4-Lite allows AWVALID/WVALID to be asserted together or
    // separately. To keep this beginner-friendly, we send the write
    // address phase and write data phase one after another (simple and
    // always legal, even though the spec would also allow sending them
    // in parallel for extra performance).
    // ---------------------------------------------------------------Z
    always @(*) begin
        next_state = state; // default: stay put
        case (state)
            S_IDLE: begin
                if (wr_en)
                    next_state = S_WR_ADDR;
                else if (rd_en)
                    next_state = S_RD_ADDR;
            end
 
            S_WR_ADDR:
                // Move on once the Slave has accepted the address
                if (m_axi_awvalid && m_axi_awready)
                    next_state = S_WR_DATA;
 
            S_WR_DATA:
                // Move on once the Slave has accepted the data
                if (m_axi_wvalid && m_axi_wready)
                    next_state = S_WR_RESP;
 
            S_WR_RESP:
                // Move on once the Slave has sent its write response
                if (m_axi_bvalid && m_axi_bready)
                    next_state = S_IDLE;
 
            S_RD_ADDR:
                // Move on once the Slave has accepted the read address
                if (m_axi_arvalid && m_axi_arready)
                    next_state = S_RD_DATA;
 
            S_RD_DATA:
                // Move on once the Slave has sent back read data
                if (m_axi_rvalid && m_axi_rready)
                    next_state = S_IDLE;
 
            default: next_state = S_IDLE;
        endcase
    end
 
    // ---------------------------------------------------------------
    // Sequential logic: outputs and captured request info
    //
    // We latch wr_addr/wr_data/rd_addr the moment the request is made,
    // so the values stay stable for the whole transaction even if the
    // user changes wr_addr/wr_data on later cycles.
    // ---------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_awaddr  <= {ADDR_WIDTH{1'b0}};
            m_axi_awvalid <= 1'b0;
 
            m_axi_wdata   <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb   <= {(DATA_WIDTH/8){1'b0}};
            m_axi_wvalid  <= 1'b0;
 
            m_axi_bready  <= 1'b0;
 
            m_axi_araddr  <= {ADDR_WIDTH{1'b0}};
            m_axi_arvalid <= 1'b0;
 
            m_axi_rready  <= 1'b0;
 
            wr_done  <= 1'b0;
            wr_resp  <= 2'b00;
            rd_data  <= {DATA_WIDTH{1'b0}};
            rd_done  <= 1'b0;
            rd_resp  <= 2'b00;
        end else begin
 
            // These are pulse outputs: default them low each cycle,
            // then set high only in the exact cycle the event happens.
            wr_done <= 1'b0;
            rd_done <= 1'b0;
 
            case (state)
                // -------------------------------------------------
                S_IDLE: begin
                    m_axi_awvalid <= 1'b0;
                    m_axi_wvalid  <= 1'b0;
                    m_axi_bready  <= 1'b0;
                    m_axi_arvalid <= 1'b0;
                    m_axi_rready  <= 1'b0;
 
                    if (wr_en) begin
                        // Latch the write request and raise AWVALID
                        m_axi_awaddr  <= wr_addr;
                        m_axi_awvalid <= 1'b1;
                        m_axi_wdata   <= wr_data;
                        m_axi_wstrb   <= {(DATA_WIDTH/8){1'b1}}; // write all bytes
                    end else if (rd_en) begin
                        // Latch the read request and raise ARVALID
                        m_axi_araddr  <= rd_addr;
                        m_axi_arvalid <= 1'b1;
                    end
                end
 
              
                S_WR_ADDR: begin
                    if (m_axi_awvalid && m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;   // address phase done
                        m_axi_wvalid  <= 1'b1;   // start data phase
                    end
                end
 
                S_WR_DATA: begin
                    if (m_axi_wvalid && m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;    // data phase done
                        m_axi_bready <= 1'b1;    // now ready to accept response
                    end
                end
 
                S_WR_RESP: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        wr_resp      <= m_axi_bresp;
                        wr_done      <= 1'b1;    // tell the user: write is complete!
                        m_axi_bready <= 1'b0;
                    end
                end
 
                S_RD_ADDR: begin
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;   // address phase done
                        m_axi_rready  <= 1'b1;   // now ready to accept data
                    end
                end
 
                S_RD_DATA: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        rd_data      <= m_axi_rdata;
                        rd_resp      <= m_axi_rresp;
                        rd_done      <= 1'b1;    // tell the user: read is complete!
                        m_axi_rready <= 1'b0;
                    end
                end
 
                default: ;
            endcase
        end
    end
 
endmodule
