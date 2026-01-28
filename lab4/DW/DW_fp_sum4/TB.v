`timescale 1ns/1ps

module tb_DW_fp_sum4_wrap;

// Parameter 設定
localparam inst_sig_width       = 23;
localparam inst_exp_width       = 8;
localparam inst_ieee_compliance = 0;
localparam inst_arch_type       = 0;

reg  [inst_sig_width+inst_exp_width:0] a, b, c, d;
reg  [2:0] rnd;
wire [inst_sig_width+inst_exp_width:0] z;
wire [7:0] status;

// DUT
DW_fp_sum4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) UUT (
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .rnd(rnd),
    .z(z),
    .status(status)
);

// 將 IEEE754 二進制轉回實數 (TB 用於顯示)
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

initial begin
    $display("==== Start DW_fp_sum4_wrap Testbench ====");
    rnd = 3'b000; // 固定捨入模式

    // Case 1: 1.0 + 2.0 + 3.0 + 4.0 = 10.0
    a = 32'h3F800000; // 1.0
    b = 32'h40000000; // 2.0
    c = 32'h40400000; // 3.0
    d = 32'h40800000; // 4.0
    #10;
    $display("1+2+3+4 = %f (0x%h)", fp32_to_real(z), z);

    // Case 2: 5.0 + (-2.0) + 1.0 + (-1.0) = 3.0
    a = 32'h40A00000; // 5.0
    b = 32'hC0000000; // -2.0
    c = 32'h3F800000; // 1.0
    d = 32'hBF800000; // -1.0
    #10;
    $display("5+(-2)+1+(-1) = %f (0x%h)", fp32_to_real(z), z);

    // Case 3: -1 + -2 + -3 + -4 = -10
    a = 32'hBF800000; // -1.0
    b = 32'hC0000000; // -2.0
    c = 32'hC0400000; // -3.0
    d = 32'hC0800000; // -4.0
    #10;
    $display("-1-2-3-4 = %f (0x%h)", fp32_to_real(z), z);

    // Case 4: 0 + 1.5 + 2.5 + 3.0 = 7.0
    a = 32'h00000000; // 0.0
    b = 32'h3FC00000; // 1.5
    c = 32'h40200000; // 2.5
    d = 32'h40400000; // 3.0
    #10;
    $display("0+1.5+2.5+3 = %f (0x%h)", fp32_to_real(z), z);

    // Case 5: 指數差大: 1e10 + 1 + 2 + 3 ≈ 1e10
    a = 32'h501502F9; // ~1e10
    b = 32'h3F800000; // 1.0
    c = 32'h40000000; // 2.0
    d = 32'h40400000; // 3.0
    #10;
    $display("1e10+1+2+3 ≈ %f (0x%h)", fp32_to_real(z), z);

    $display("==== End Testbench ====");
    $finish;
end

endmodule