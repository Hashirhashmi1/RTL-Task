`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 09:16:36 PM
// Design Name: 
// Module Name: axi4_lite_tb
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

 
module axi4_lite_tb;
 
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
 
    // ---------------------------------------------------------------
    // Clock / reset
    // ---------------------------------------------------------------
    reg clk;
    reg rst_n;
 
    always #5 clk = ~clk;   // 100 MHz clock (10 ns period)
 
    // ---------------------------------------------------------------
    // Wires connecting MASTER <-> SLAVE (the actual AXI4-Lite bus)
    // ---------------------------------------------------------------
    wire [ADDR_WIDTH-1:0]     axi_awaddr;
    wire                      axi_awvalid;
    wire                      axi_awready;
 
    wire [DATA_WIDTH-1:0]     axi_wdata;
    wire [(DATA_WIDTH/8)-1:0] axi_wstrb;
    wire                      axi_wvalid;
    wire                      axi_wready;
 
    wire [1:0]                axi_bresp;
    wire                      axi_bvalid;
    wire                      axi_bready;
 
    wire [ADDR_WIDTH-1:0]     axi_araddr;
    wire                      axi_arvalid;
    wire                      axi_arready;
 
    wire [DATA_WIDTH-1:0]     axi_rdata;
    wire [1:0]                axi_rresp;
    wire                      axi_rvalid;
    wire                      axi_rready;
 
    // ---------------------------------------------------------------
    // Simple user-side signals to drive the Master
    // ---------------------------------------------------------------
    reg                       wr_en;
    reg  [ADDR_WIDTH-1:0]     wr_addr;
    reg  [DATA_WIDTH-1:0]     wr_data;
    wire                      wr_done;
    wire [1:0]                wr_resp;
 
    reg                       rd_en;
    reg  [ADDR_WIDTH-1:0]     rd_addr;
    wire [DATA_WIDTH-1:0]     rd_data;
    wire                      rd_done;
    wire [1:0]                rd_resp;
 
    wire                      busy;
 
    // ---------------------------------------------------------------
    // Instantiate the MASTER (separate module, not written inline here)
    // ---------------------------------------------------------------
    axi4_lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_master (
        .clk           (clk),
        .rst_n         (rst_n),
 
        .wr_en         (wr_en),
        .wr_addr       (wr_addr),
        .wr_data       (wr_data),
        .wr_done       (wr_done),
        .wr_resp       (wr_resp),
 
        .rd_en         (rd_en),
        .rd_addr       (rd_addr),
        .rd_data       (rd_data),
        .rd_done       (rd_done),
        .rd_resp       (rd_resp),
 
        .busy          (busy),
 
        .m_axi_awaddr  (axi_awaddr),
        .m_axi_awvalid (axi_awvalid),
        .m_axi_awready (axi_awready),
 
        .m_axi_wdata   (axi_wdata),
        .m_axi_wstrb   (axi_wstrb),
        .m_axi_wvalid  (axi_wvalid),
        .m_axi_wready  (axi_wready),
 
        .m_axi_bresp   (axi_bresp),
        .m_axi_bvalid  (axi_bvalid),
        .m_axi_bready  (axi_bready),
 
        .m_axi_araddr  (axi_araddr),
        .m_axi_arvalid (axi_arvalid),
        .m_axi_arready (axi_arready),
 
        .m_axi_rdata   (axi_rdata),
        .m_axi_rresp   (axi_rresp),
        .m_axi_rvalid  (axi_rvalid),
        .m_axi_rready  (axi_rready)
    );
 
    // ---------------------------------------------------------------
    // Instantiate the SLAVE
    // ---------------------------------------------------------------
    axi4_lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (16)
    ) u_slave (
        .clk           (clk),
        .rst_n         (rst_n),
 
        .s_axi_awaddr  (axi_awaddr),
        .s_axi_awvalid (axi_awvalid),
        .s_axi_awready (axi_awready),
 
        .s_axi_wdata   (axi_wdata),
        .s_axi_wstrb   (axi_wstrb),
        .s_axi_wvalid  (axi_wvalid),
        .s_axi_wready  (axi_wready),
 
        .s_axi_bresp   (axi_bresp),
        .s_axi_bvalid  (axi_bvalid),
        .s_axi_bready  (axi_bready),
 
        .s_axi_araddr  (axi_araddr),
        .s_axi_arvalid (axi_arvalid),
        .s_axi_arready (axi_arready),
 
        .s_axi_rdata   (axi_rdata),
        .s_axi_rresp   (axi_rresp),
        .s_axi_rvalid  (axi_rvalid),
        .s_axi_rready  (axi_rready)
    );
 
    // ---------------------------------------------------------------
    // Helper tasks: perform one write / one read via the simple
    // user-side interface, and wait for completion.
    //
    // IMPORTANT BEGINNER TIP - avoiding a "race condition":
    //   Notice we change wr_en/rd_en on the NEGEDGE (falling edge) of
    //   the clock, not the posedge. The Master's internal logic is all
    //   triggered on the POSEDGE. If a testbench changes an input at
    //   the exact same instant (posedge) that the DUT's flip-flops are
    //   also triggering, the simulator can't guarantee who "sees" the
    //   new value first - this is called a race condition, and it can
    //   cause flaky or wrong simulation results.
    //   By changing inputs on the NEGEDGE, they are rock-solid and
    //   stable for a full half clock cycle before the next POSEDGE
    //   samples them - completely eliminating the race.
    // ---------------------------------------------------------------
    task do_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            wr_addr = addr;
            wr_data = data;
            wr_en   = 1'b1;
            @(negedge clk);
            wr_en   = 1'b0;
 
            // wait until the master pulses wr_done
            wait (wr_done == 1'b1);
            $display("[%0t] WRITE addr=0x%0h data=0x%0h -> resp=%0d",
                      $time, addr, data, wr_resp);
            @(negedge clk);
        end
    endtask
 
    task do_read(input [ADDR_WIDTH-1:0] addr);
        begin
            @(negedge clk);
            rd_addr = addr;
            rd_en   = 1'b1;
            @(negedge clk);
            rd_en   = 1'b0;
 
            wait (rd_done == 1'b1);
            $display("[%0t] READ  addr=0x%0h -> data=0x%0h resp=%0d",
                      $time, addr, rd_data, rd_resp);
            @(negedge clk);
        end
    endtask
 
    // ---------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------
    initial begin
        // init
        clk     = 1'b0;
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_addr = 0;
        wr_data = 0;
        rd_en   = 0;
        rd_addr = 0;
 
        // hold reset for a few cycles
        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
 
        // --- Write then read back register 0 ---
        do_write(32'h0000_0000, 32'hDEAD_BEEF);
        do_read (32'h0000_0000);
 
        // --- Write then read back register 1 ---
        do_write(32'h0000_0004, 32'h1234_5678);
        do_read (32'h0000_0004);
 
        // --- Overwrite register 0 and confirm it updates ---
        do_write(32'h0000_0000, 32'hCAFE_F00D);
        do_read (32'h0000_0000);
 
        $display("=== All transactions completed ===");
        #20;
        $finish;
    end
 
    // Optional: dump waveform for viewing in GTKWave
    initial begin
        $dumpfile("axi4_lite_tb.vcd");
        $dumpvars(0, axi4_lite_tb);
    end
 
endmodule