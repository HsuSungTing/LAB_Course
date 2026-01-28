`timescale 1ns/1ps

module tb_DW_fp_sum3;

// Parameter 設定 (IEEE754 單精度)
localparam inst_sig_width       = 23;
localparam inst_exp_width       = 8;
localparam inst_ieee_compliance = 0;
localparam inst_arch_type       = 0;

// 測試輸入輸出
reg  [inst_sig_width+inst_exp_width:0] a, b, c;
reg  [2:0] rnd;
wire [inst_sig_width+inst_exp_width:0] z;
wire [7:0] status;

// DUT
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) UUT (
    .a(a),
    .b(b),
    .c(c),
    .rnd(rnd),
    .z(z),
    .status(status)
);

// 將 IEEE754 二進制轉回實數 (僅用於 TB 顯示)
function real fp32_to_real(input [31:0] fp);
    reg [22:0] frac;
    reg [7:0]  exp;
    reg sign;
    real frac_real;
    integer i;
begin
    sign = fp[31];
    exp  = fp[30:23];
    frac = fp[22:0];
    frac_real = 1.0;
    for (i=0; i<23; i=i+1)
        if (frac[i]) frac_real = frac_real + (1.0 / (2.0**(23-i)));
    fp32_to_real = ((sign)? -1.0:1.0) * frac_real * (2.0**(exp-127));
end
endfunction

// 測試程序
initial begin
    $display("==== Start DW_fp_sum3 Testbench ====");
    rnd = 3'b000;  // 固定捨去

    // Case 1: 1.0 + 2.0 + 3.0 = 6.0
    a = 32'h3F800000; // 1.0
    b = 32'h40000000; // 2.0
    c = 32'h40400000; // 3.0
    #10;
    $display("1.0+2.0+3.0 = %f (z=0x%h)", fp32_to_real(z), z);

    // Case 2: 5.0 + (-2.0) + 1.0 = 4.0
    a = 32'h40A00000; // 5.0
    b = 32'hC0000000; // -2.0
    c = 32'h3F800000; // 1.0
    #10;
    $display("5.0+(-2.0)+1.0 = %f (z=0x%h)", fp32_to_real(z), z);

    // Case 3: -1.0 + -2.0 + -3.0 = -6.0
    a = 32'hBF800000; // -1.0
    b = 32'hC0000000; // -2.0
    c = 32'hC0400000; // -3.0
    #10;
    $display("-1.0+(-2.0)+(-3.0) = %f (z=0x%h)", fp32_to_real(z), z);

    // Case 4: 0.0 + 1.5 + 2.5 = 4.0
    a = 32'h00000000; // 0.0
    b = 32'h3FC00000; // 1.5
    c = 32'h40200000; // 2.5
    #10;
    $display("0.0+1.5+2.5 = %f (z=0x%h)", fp32_to_real(z), z);

    // Case 5: 1e10 + 1.0 + 1.0 ≈ 1e10 (測試 exponent 差異)
    a = 32'h501502F9; // 約 1e10
    b = 32'h3F800000; // 1.0
    c = 32'h3F800000; // 1.0
    #10;
    $display("1e10+1.0+1.0 ≈ %f (z=0x%h)", fp32_to_real(z), z);

    $display("==== End Testbench ====");
    $finish;
end

endmodule
