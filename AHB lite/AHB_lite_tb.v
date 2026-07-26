`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2026 11:10:18 PM
// Design Name: 
// Module Name: AHB_lite_tb
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


`timescale 1ns/1ps

module ahb_lite_tb;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    reg HCLK, HRESETn;
    always #5 HCLK = ~HCLK;

    wire [ADDR_WIDTH-1:0] HADDR;
    wire                  HWRITE;
    wire [1:0]            HTRANS;
    wire [2:0]            HSIZE;
    wire [DATA_WIDTH-1:0] HWDATA;
    wire [DATA_WIDTH-1:0] HRDATA;
    wire                  HREADY;
    wire                  HRESP;

    reg                   wr_en;
    reg  [ADDR_WIDTH-1:0] wr_addr;
    reg  [DATA_WIDTH-1:0] wr_data;
    wire                  wr_done;

    reg                   rd_en;
    reg  [ADDR_WIDTH-1:0] rd_addr;
    wire [DATA_WIDTH-1:0] rd_data;
    wire                  rd_done;

    ahb_lite_master #(ADDR_WIDTH, DATA_WIDTH) u_master (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .wr_en(wr_en), .wr_addr(wr_addr), .wr_data(wr_data), .wr_done(wr_done),
        .rd_en(rd_en), .rd_addr(rd_addr), .rd_data(rd_data), .rd_done(rd_done),
        .HADDR(HADDR), .HWRITE(HWRITE), .HTRANS(HTRANS), .HSIZE(HSIZE),
        .HWDATA(HWDATA), .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP)
    );

    ahb_lite_slave #(ADDR_WIDTH, DATA_WIDTH, 16) u_slave (
        .HCLK(HCLK), .HRESETn(HRESETn),
        .HADDR(HADDR), .HWRITE(HWRITE), .HTRANS(HTRANS),
        .HWDATA(HWDATA), .HRDATA(HRDATA), .HREADY(HREADY), .HRESP(HRESP)
    );

    // stimulus applied on negedge to avoid racing HCLK-triggered logic
    task do_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
        begin
            @(negedge HCLK);
            wr_addr = a; wr_data = d; wr_en = 1;
            @(negedge HCLK);
            wr_en = 0;
            wait (wr_done);
            $display("[%0t] WRITE addr=0x%0h data=0x%0h", $time, a, d);
            @(negedge HCLK);
        end
    endtask

    task do_read(input [ADDR_WIDTH-1:0] a);
        begin
            @(negedge HCLK);
            rd_addr = a; rd_en = 1;
            @(negedge HCLK);
            rd_en = 0;
            wait (rd_done);
            $display("[%0t] READ  addr=0x%0h data=0x%0h", $time, a, rd_data);
            @(negedge HCLK);
        end
    endtask

    initial begin
        HCLK = 0; HRESETn = 0;
        wr_en = 0; wr_addr = 0; wr_data = 0;
        rd_en = 0; rd_addr = 0;

        repeat (4) @(negedge HCLK);
        HRESETn = 1;
        repeat (2) @(negedge HCLK);

        do_write(32'h0, 32'hDEAD_BEEF);
        do_read (32'h0);

        do_write(32'h4, 32'h1234_5678);
        do_read (32'h4);

        $display("=== done ===");
        #20 $finish;
    end

endmodule