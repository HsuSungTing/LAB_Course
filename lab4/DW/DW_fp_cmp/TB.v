`timescale 1ns/1ps

module tb_DW_fp_cmp;
// Parameter 設定
localparam inst_sig_width = 23;
localparam inst_exp_width = 8;
localparam inst_ieee_compliance = 0;

// 測試輸入輸出
reg  [inst_sig_width+inst_exp_width:0] a, b;
reg  zctr;
wire aeqb, altb, agtb;
wire unordered;
wire z0, z1;
wire [7:0] status0, status1;

// DUT 實例化
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) UUT (
    .a(a),
    .b(b),
    .zctr(zctr),
    .aeqb(aeqb),
    .altb(altb),
    .agtb(agtb),
    .unordered(unordered),
    .z0(z0),
    .z1(z1),
    .status0(status0),
    .status1(status1)
);

// 測試程序
initial begin
    $display("==== Start DW_fp_cmp Testbench ====");

    zctr = 1'b1;  // 固定選 min/max 模式

    // 測試 1: A == B (1.0 vs 1.0)
    a = 32'h3F800000; // 1.0
    b = 32'h3F800000; // 1.0
    #10;
    $display("A=1.0, B=1.0 -> aeqb=%b, altb=%b, agtb=%b, z0=%b, z1=%b", aeqb, altb, agtb, z0, z1);

    // 測試 2: A > B (2.0 vs 1.0)
    a = 32'h40000000; // 2.0
    b = 32'h3F800000; // 1.0
    #10;
    $display("A=2.0, B=1.0 -> aeqb=%b, altb=%b, agtb=%b, z0=%b, z1=%b", aeqb, altb, agtb, z0, z1);

    // 測試 3: A < B (0.5 vs 1.0)
    a = 32'h3F000000; // 0.5
    b = 32'h3F800000; // 1.0
    #10;
    $display("A=0.5, B=1.0 -> aeqb=%b, altb=%b, agtb=%b, z0=%b, z1=%b", aeqb, altb, agtb, z0, z1);

    // 測試 4: A 正, B 負 (1.0 vs -1.0)
    a = 32'h3F800000; // 1.0
    b = 32'hBF800000; // -1.0
    #10;
    $display("A=1.0, B=-1.0 -> aeqb=%b, altb=%b, agtb=%b, z0=%b, z1=%b", aeqb, altb, agtb, z0, z1);

    // 測試 5: A 負, B 正 (-2.0 vs 2.0)
    a = 32'hC0000000; // -2.0
    b = 32'h40000000; // 2.0
    #10;
    $display("A=-2.0, B=2.0 -> aeqb=%b, altb=%b, agtb=%b, z0=%b, z1=%b", aeqb, altb, agtb, z0, z1);

    $display("==== End Testbench ====");
    $finish;
end

endmodule