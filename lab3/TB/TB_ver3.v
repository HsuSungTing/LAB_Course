`timescale 1ns/1ps
module tb_CONVEX;

// clk & reset
reg clk, rst_n;
initial begin
    clk = 0;
    forever #0.5 clk = ~clk; // 100MHz
end

// DUT I/O
reg         in_valid;
reg  [8:0]  pt_num;
reg  [9:0]  in_x, in_y;
wire        out_valid;
wire [9:0]  out_x, out_y;
wire [6:0]  drop_num;

// DUT
CONVEX dut(
    .rst_n(rst_n),
    .clk(clk),
    .in_valid(in_valid),
    .pt_num(pt_num),
    .in_x(in_x),
    .in_y(in_y),
    .out_valid(out_valid),
    .out_x(out_x),
    .out_y(out_y),
    .drop_num(drop_num)
);

// 測資 (20 組)
reg signed [9:0] test_x [0:19];
reg signed [9:0] test_y [0:19];
integer i;

initial begin
    test_x[0]  = 376;  test_y[0]  = 208;
    test_x[1]  = 268;  test_y[1]  = 221;
    test_x[2]  = 308;  test_y[2]  = 326;
    test_x[3]  = 268;  test_y[3]  = 221;
    test_x[4]  = 376;  test_y[4]  = 208;
    test_x[5]  = 308;  test_y[5]  = 326;
    test_x[6]  = 354;  test_y[6]  = 298;
    test_x[7]  = 268;  test_y[7]  = 221;
    test_x[8]  = 376;  test_y[8]  = 208;
    test_x[9]  = 354;  test_y[9]  = 298;
    test_x[10] = 308;  test_y[10] = 326;
    test_x[11] = 332;  test_y[11] = 389;
    test_x[12] = 308;  test_y[12] = 326;
    test_x[13] = 354;  test_y[13] = 298;
    test_x[14] = 268;  test_y[14] = 221;
    test_x[15] = 376;  test_y[15] = 208;
    test_x[16] = 332;  test_y[16] = 389;
    test_x[17] = 398;  test_y[17] = 342;
    test_x[18] = 268;  test_y[18] = 221;
    test_x[19] = 376;  test_y[19] = 208;
end

// 主流程
initial begin
    // 初始化
    in_valid = 0;
    pt_num   = 0;
    in_x     = 0;
    in_y     = 0;
    rst_n    = 1;

    // reset
    @(negedge clk);
    @(negedge clk);
    rst_n = 0;
    @(negedge clk);
    @(negedge clk);
    rst_n = 1;

    // 送 20 筆資料
    for(i=0; i<20; i=i+1) begin
        @(negedge clk);
        in_valid = 1;
        in_x = test_x[i];
        in_y = test_y[i];
        if(i==0) pt_num = 9'd20; // 第一筆要送 pt_num
        else     pt_num = 0;
        @(negedge clk);
        in_valid = 0;
        pt_num   = 0;
        in_x     = 0;
        in_y     = 0;
        wait_out_valid_cycle();
    end

    // 結束模擬
    #500 $finish;
end

// 任務：等 out_valid 回到 0
task wait_out_valid_cycle;
begin
    // 等 out_valid 變 1
    @(negedge clk);
    while(out_valid==0) @(negedge clk);

    // 等 out_valid 回到 0
    while(out_valid==1) @(negedge clk);
end
endtask

endmodule
