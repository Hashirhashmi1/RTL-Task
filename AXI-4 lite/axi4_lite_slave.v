`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 09:15:22 PM
// Design Name: 
// Module Name: axi4_lite_slave
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


module axi4_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 16     // 16 word registers => needs 4 addr bits (16*4=64B)
)(
    input  wire                      clk,
    input  wire                      rst_n,
 
    // -------------------------------------------------------------------
    // AXI4-Lite WRITE ADDRESS CHANNEL   (Master -> Slave)
    // -------------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire                      s_axi_awvalid,
    output reg                       s_axi_awready,
 
    // -------------------------------------------------------------------
    // AXI4-Lite WRITE DATA CHANNEL      (Master -> Slave)
    // -------------------------------------------------------------------
    input  wire [DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                      s_axi_wvalid,
    output reg                       s_axi_wready,
 
    // -------------------------------------------------------------------
    // AXI4-Lite WRITE RESPONSE CHANNEL  (Slave -> Master)
    // -------------------------------------------------------------------
    output reg  [1:0]                s_axi_bresp,
    output reg                       s_axi_bvalid,
    input  wire                      s_axi_bready,
 
    // -------------------------------------------------------------------
    // AXI4-Lite READ ADDRESS CHANNEL    (Master -> Slave)
    // -------------------------------------------------------------------
    input  wire [ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire                      s_axi_arvalid,
    output reg                       s_axi_arready,
 
    // -------------------------------------------------------------------
    // AXI4-Lite READ DATA CHANNEL       (Slave -> Master)
    // -------------------------------------------------------------------
    output reg  [DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                s_axi_rresp,
    output reg                       s_axi_rvalid,
    input  wire                      s_axi_rready
);
 
    // -------------------------------------------------------------------
    // The actual "memory" of the slave: 16 registers, 32 bits each.
    // Register N lives at byte address (N*4). Feel free to give these
    // meaning later (e.g. REG0 = control, REG1 = status, ...).
    // -------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] regfile [0:NUM_REGS-1];
 
    integer i;
    // simple word index derived from the byte address:
    // e.g. addr 0x00 -> index 0, addr 0x04 -> index 1, addr 0x08 -> index 2 ...
    wire [$clog2(NUM_REGS)-1:0] awindex = s_axi_awaddr[$clog2(NUM_REGS)+1:2];
    wire [$clog2(NUM_REGS)-1:0] arindex = s_axi_araddr[$clog2(NUM_REGS)+1:2];
 
    // -------------------------------------------------------------------
    // WRITE CHANNEL HANDSHAKE FLAGS
    //
    // AXI4-Lite lets AWVALID and WVALID arrive independently (not
    // necessarily the same cycle). We latch each one the moment it is
    // accepted, and only perform the actual register write once BOTH
    // the address and the data have arrived.
    // -------------------------------------------------------------------
    reg aw_done, w_done;                 // "have we captured address/data yet?"
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg [DATA_WIDTH-1:0] wdata_latched;
    reg [(DATA_WIDTH/8)-1:0] wstrb_latched;
 
    localparam [1:0] W_IDLE = 2'd0, W_WAIT = 2'd1, W_RESP = 2'd2;
    reg [1:0] wstate;
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_done       <= 1'b0;
            w_done        <= 1'b0;
            wstate        <= W_IDLE;
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
            wdata_latched  <= {DATA_WIDTH{1'b0}};
            wstrb_latched  <= {(DATA_WIDTH/8){1'b0}};
 
            for (i = 0; i < NUM_REGS; i = i + 1)
                regfile[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            case (wstate)
 
                // ---------------------------------------------------
                // W_IDLE: ready to accept a NEW address and/or data.
                // We assert AWREADY/WREADY = 1 (always ready) which is
                // the simplest legal AXI4-Lite slave behavior. As soon
                // as the master raises VALID, the handshake completes
                // that very cycle.
                // ---------------------------------------------------
                W_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_awready <= ~aw_done;
                    s_axi_wready  <= ~w_done;
 
                    if (s_axi_awvalid && s_axi_awready) begin
                        awaddr_latched <= s_axi_awaddr;
                        aw_done        <= 1'b1;
                    end
                    if (s_axi_wvalid && s_axi_wready) begin
                        wdata_latched  <= s_axi_wdata;
                        wstrb_latched  <= s_axi_wstrb;
                        w_done         <= 1'b1;
                    end
 
                    // Once we have captured BOTH address and data,
                    // perform the write and move on to the response.
                    if ((aw_done || (s_axi_awvalid && s_axi_awready)) &&
                        (w_done  || (s_axi_wvalid  && s_axi_wready))) begin
                        wstate <= W_RESP;
                    end
                end
 
                // ---------------------------------------------------
                // W_RESP: do the actual write, then tell the master
                // "OKAY" via the write-response channel.
                // ---------------------------------------------------
                W_RESP: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b0;
 
                    // Perform the write using the byte-strobes: only
                    // the bytes where wstrb bit = 1 get updated.
                    for (i = 0; i < (DATA_WIDTH/8); i = i + 1) begin
                        if (wstrb_latched[i])
                            regfile[awaddr_latched[$clog2(NUM_REGS)+1:2]][i*8 +: 8]
                                <= wdata_latched[i*8 +: 8];
                    end
 
                    s_axi_bresp  <= 2'b00; // OKAY
                    s_axi_bvalid <= 1'b1;
                    wstate       <= W_WAIT;
                end
 
                // ---------------------------------------------------
                // W_WAIT: hold BVALID high until the master accepts
                // the response with BREADY.
                // ---------------------------------------------------
                W_WAIT: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        aw_done      <= 1'b0;
                        w_done       <= 1'b0;
                        wstate       <= W_IDLE;
                    end
                end
 
                default: wstate <= W_IDLE;
            endcase
        end
    end
 
    // -------------------------------------------------------------------
    // READ CHANNEL
    //
    // Simple two-step flow:
    //   1) Accept ARADDR when ARVALID+ARREADY handshake, look up register
    //   2) Present RDATA and hold RVALID high until RREADY handshake
    // -------------------------------------------------------------------
    localparam [1:0] R_IDLE = 2'd0, R_DATA = 2'd1;
    reg r_state;
 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            r_state       <= R_IDLE;
        end else begin
            case (r_state)
                // Always ready to accept a new read address
                R_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;
 
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;
                        // Look up the register right away (combinational
                        // read from regfile), present it next cycle:
                        s_axi_rdata  <= regfile[arindex];
                        s_axi_rresp  <= 2'b00; // OKAY
                        s_axi_rvalid <= 1'b1;
                        r_state      <= R_DATA;
                    end
                end
 
                // Hold RVALID high until the master takes the data
                R_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        r_state      <= R_IDLE;
                    end
                end
 
                default: r_state <= R_IDLE;
            endcase
        end
    end
 
endmodule
