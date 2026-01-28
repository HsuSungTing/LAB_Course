`timescale 1ns/1ps

module tb_reorder_points;
    reg  [9:0] x1, y1;
    reg  [9:0] x2, y2;
    reg  [9:0] x3, y3;
    wire [9:0] out_x1, out_y1;
    wire [9:0] out_x2, out_y2;
    wire [9:0] out_x3, out_y3;

    // DUT
    reorder_points dut (
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .x3(x3), .y3(y3),
        .out_x1(out_x1), .out_y1(out_y1),
        .out_x2(out_x2), .out_y2(out_y2),
        .out_x3(out_x3), .out_y3(out_y3)
    );

    initial begin
        $dumpfile("tb_reorder_points.vcd"); // 生成波形文件
        $dumpvars(0, tb_reorder_points);

        // Case 1: cross > 0, 不交换
        x1 = 10'd0; y1 = 10'd0;
        x2 = 10'd1; y2 = 10'd0;
        x3 = 10'd0; y3 = 10'd1;
        #10;
        $display("Case1 out: (%d,%d) (%d,%d) (%d,%d)", 
                  out_x1, out_y1, out_x2, out_y2, out_x3, out_y3);

        // Case 2: cross < 0, 要交换 p2 和 p3
        x1 = 10'd0; y1 = 10'd0;
        x2 = 10'd0; y2 = 10'd1;
        x3 = 10'd1; y3 = 10'd0;
        #10;
        $display("Case2 out: (%d,%d) (%d,%d) (%d,%d)", 
                  out_x1, out_y1, out_x2, out_y2, out_x3, out_y3);

        // Case 3: 
        x1 = 10'd5; y1 = 10'd0;
        x2 = 10'd0; y2 = 10'd5;
        x3 = 10'd10; y3 = 10'd10;
        #10;
        $display("Case3 out: (%d,%d) (%d,%d) (%d,%d)", 
                  out_x1, out_y1, out_x2, out_y2, out_x3, out_y3);

        // Case 4: 
        x1 = 10'd0; y1 = 10'd3;
        x2 = 10'd20; y2 = 10'd20;
        x3 = 10'd5; y3 = 10'd0;
        #10;
        $display("Case3 out: (%d,%d) (%d,%d) (%d,%d)", 
                  out_x1, out_y1, out_x2, out_y2, out_x3, out_y3);

        // Case 5: 
        x1 = 10'd40; y1 = 10'd20;
        x2 = 10'd5; y2 = 10'd1;
        x3 = 10'd0; y3 = 10'd0;
        #10;
        $display("Case3 out: (%d,%d) (%d,%d) (%d,%d)", 
                  out_x1, out_y1, out_x2, out_y2, out_x3, out_y3);

        $finish;
    end
endmodule
