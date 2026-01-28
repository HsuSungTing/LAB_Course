`timescale 1ns/1ps

module tb_single_port_sync_ram;

    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 32;
    localparam DEPTH      = 16;

    reg                     clk;
    reg  [ADDR_WIDTH-1:0]   A;
    reg  [DATA_WIDTH-1:0]   DI;
    wire [DATA_WIDTH-1:0]   DO;
    reg                     CS;
    reg                     WEN;
    reg                     OE;

    // DUT
    single_port_sync_ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .A(A),
        .DI(DI),
        .DO(DO),
        .CS(CS),
        .WEN(WEN),
        .OE(OE)
    );

    // clock: 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // -------------------------
        // init
        // -------------------------
        A   = 0;
        DI  = 0;
        CS  = 0;
        WEN = 1;
        OE  = 0;

        repeat (2) @(posedge clk);

        // =====================================================
        // WRITE PHASE (6 writes total, WEN = 0)
        // =====================================================

        // WRITE 0
        @(negedge clk);
        A   = 4'h1;
        DI  = 32'h1111_1111;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // WRITE 1
        @(negedge clk);
        A   = 4'h2;
        DI  = 32'h2222_2222;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // WRITE 2
        @(negedge clk);
        A   = 4'h3;
        DI  = 32'h3333_3333;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // WRITE 3
        @(negedge clk);
        A   = 4'h4;
        DI  = 32'h4444_4444;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // WRITE 4
        @(negedge clk);
        A   = 4'h5;
        DI  = 32'h5555_5555;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // WRITE 5
        @(negedge clk);
        A   = 4'h6;
        DI  = 32'h6666_6666;
        CS  = 1; OE = 1; WEN = 0;
        @(posedge clk);

        // =====================================================
        // READ PHASE (read back all written data)
        // =====================================================

        // READ 1
        @(negedge clk);
        A   = 4'h1;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=1 DO=%h (expect 11111111)", DO);

        // READ 2
        @(negedge clk);
        A   = 4'h2;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=2 DO=%h (expect 22222222)", DO);

        // READ 3
        @(negedge clk);
        A   = 4'h3;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=3 DO=%h (expect 33333333)", DO);

        // READ 4
        @(negedge clk);
        A   = 4'h4;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=4 DO=%h (expect 44444444)", DO);

        // READ 5
        @(negedge clk);
        A   = 4'h5;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=5 DO=%h (expect 55555555)", DO);

        // READ 6
        @(negedge clk);
        A   = 4'h6;
        CS  = 1; OE = 1; WEN = 1;
        @(posedge clk);
        #5 $display("[READ] A=6 DO=%h (expect 66666666)", DO);

        // -------------------------
        // finish
        // -------------------------
        #20;
        $finish;
    end

endmodule
