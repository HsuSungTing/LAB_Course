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

// 測資
reg signed [9:0] test_x [0:232];
reg signed [9:0] test_y [0:232];
integer i, f, r;

// 讀檔
initial begin
    f = $fopen("points233.dat","r");
    if(f==0) begin
        $display("Error: cannot open points233.dat");
        $finish;
    end
    for(i=0; i<233; i=i+1) begin
        r = $fscanf(f, "%d %d\n", test_x[i], test_y[i]);
    end
    $fclose(f);
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

    // 送 233 筆資料
    for(i=0; i<233; i=i+1) begin
        @(negedge clk);
        in_valid = 1;
        in_x = test_x[i];
        in_y = test_y[i];
        if(i==0) pt_num = 9'd233; // 第一筆送 pt_num
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
    @(negedge clk);
    while(out_valid==0) @(negedge clk);
    while(out_valid==1) @(negedge clk);
end
endtask

endmodule
