`timescale 1ns/1ps

module mul_H_tb;

    // DUT 输入
    reg signed [12:0] a00, a01, a02, a03;
    reg signed [12:0] a10, a11, a12, a13;
    reg signed [12:0] a20, a21, a22, a23;
    reg signed [12:0] a30, a31, a32, a33;

    // DUT 输出（13-bit unsigned）
    wire [12:0] b00, b01, b02, b03;
    wire [12:0] b10, b11, b12, b13;
    wire [12:0] b20, b21, b22, b23;
    wire [12:0] b30, b31, b32, b33;

    // 实例化 DUT
    mul_H dut(
        .a00(a00), .a01(a01), .a02(a02), .a03(a03),
        .a10(a10), .a11(a11), .a12(a12), .a13(a13),
        .a20(a20), .a21(a21), .a22(a22), .a23(a23),
        .a30(a30), .a31(a31), .a32(a32), .a33(a33),
        .b00(b00), .b01(b01), .b02(b02), .b03(b03),
        .b10(b10), .b11(b11), .b12(b12), .b13(b13),
        .b20(b20), .b21(b21), .b22(b22), .b23(b23),
        .b30(b30), .b31(b31), .b32(b32), .b33(b33)
    );

    // ---------------------------------------
    // 自动计算 GOLDEN 绝对值函数
    // ---------------------------------------
    function [12:0] abs_val;
        input signed [15:0] x;
    begin
        abs_val = (x < 0) ? -x : x;
    end
    endfunction

    // 用来计算黄金值 (golden reference model)
    task compute_golden;
        output [12:0] g00, g01, g02, g03;
        output [12:0] g10, g11, g12, g13;
        output [12:0] g20, g21, g22, g23;
        output [12:0] g30, g31, g32, g33;

        reg signed [15:0] r00, r01, r02, r03;
        reg signed [15:0] r10, r11, r12, r13;
        reg signed [15:0] r20, r21, r22, r23;
        reg signed [15:0] r30, r31, r32, r33;

    begin
        // Row0
        r00 = a00 + a01 + a02 + a03;
        r01 = a00 - a01 + a02 - a03;
        r02 = a00 + a01 - a02 - a03;
        r03 = a00 - a01 - a02 + a03;

        // Row1
        r10 = a10 + a11 + a12 + a13;
        r11 = a10 - a11 + a12 - a13;
        r12 = a10 + a11 - a12 - a13;
        r13 = a10 - a11 - a12 + a13;

        // Row2
        r20 = a20 + a21 + a22 + a23;
        r21 = a20 - a21 + a22 - a23;
        r22 = a20 + a21 - a22 - a23;
        r23 = a20 - a21 - a22 + a23;

        // Row3
        r30 = a30 + a31 + a32 + a33;
        r31 = a30 - a31 + a32 - a33;
        r32 = a30 + a31 - a32 - a33;
        r33 = a30 - a31 - a32 + a33;

        // Golden absolute values
        g00 = abs_val(r00); g01 = abs_val(r01); g02 = abs_val(r02); g03 = abs_val(r03);
        g10 = abs_val(r10); g11 = abs_val(r11); g12 = abs_val(r12); g13 = abs_val(r13);
        g20 = abs_val(r20); g21 = abs_val(r21); g22 = abs_val(r22); g23 = abs_val(r23);
        g30 = abs_val(r30); g31 = abs_val(r31); g32 = abs_val(r32); g33 = abs_val(r33);
    end
    endtask

    // ---------------------------------------
    // Testbench 主流程
    // ---------------------------------------
    integer i;

    reg [12:0] g00, g01, g02, g03;
    reg [12:0] g10, g11, g12, g13;
    reg [12:0] g20, g21, g22, g23;
    reg [12:0] g30, g31, g32, g33;

    initial begin
        
        $display("===== mul_H Testbench with Golden Checker START =====");

        // -----------------------------
        // Test 1：固定产生负数
        // -----------------------------
        a00 = -10; a01 = -20; a02 = 5;  a03 = -7;
        a10 = -5;  a11 = 6;   a12 = -7; a13 = 8;
        a20 = -1;  a21 = 2;   a22 = 3;  a23 = -20;
        a30 = 9;   a31 = -50; a32 = 11; a33 = 12;
        #5;

        compute_golden(g00, g01, g02, g03,
                       g10, g11, g12, g13,
                       g20, g21, g22, g23,
                       g30, g31, g32, g33);

        $display("\n[Test 1 - Known Negative Case]");
        $display("DUT b00=%d   Golden=%d", b00, g00);
        $display("DUT b01=%d   Golden=%d", b01, g01);
        $display("DUT b02=%d   Golden=%d", b02, g02);
        $display("DUT b03=%d   Golden=%d", b03, g03);

        // -----------------------------
        // Test 2：全部正数
        // -----------------------------
        a00 = 10; a01 = 20; a02 = 30; a03 = 40;
        a10 = 5;  a11 = 6;  a12 = 7;  a13 = 8;
        a20 = 1;  a21 = 2;  a22 = 3;  a23 = 4;
        a30 = 9;  a31 = 10; a32 = 11; a33 = 12;
        #5;

        compute_golden(g00, g01, g02, g03,
                       g10, g11, g12, g13,
                       g20, g21, g22, g23,
                       g30, g31, g32, g33);

        $display("\n[Test 2 - All Positive]");
        $display("DUT b00=%d   Golden=%d", b00, g00);

        // -----------------------------
        // Test 3~8 ：随机输入，6组
        // -----------------------------
        for (i = 1; i <= 6; i = i + 1) begin
            // 给随机数
            a00 = $random % 4096;
            a01 = $random % 4096;
            a02 = $random % 4096;
            a03 = $random % 4096;

            a10 = $random % 4096;
            a11 = $random % 4096;
            a12 = $random % 4096;
            a13 = $random % 4096;

            a20 = $random % 4096;
            a21 = $random % 4096;
            a22 = $random % 4096;
            a23 = $random % 4096;

            a30 = $random % 4096;
            a31 = $random % 4096;
            a32 = $random % 4096;
            a33 = $random % 4096;

            #5;

            compute_golden(g00, g01, g02, g03,
                           g10, g11, g12, g13,
                           g20, g21, g22, g23,
                           g30, g31, g32, g33);

            $display("\n[Random Test %0d]", i);
            $display("DUT b00=%d   Golden=%d", b00, g00);
            $display("DUT b01=%d   Golden=%d", b01, g01);
            $display("DUT b02=%d   Golden=%d", b02, g02);
            $display("DUT b03=%d   Golden=%d", b03, g03);
        end

        $display("\n===== Testbench END =====");
        $finish;
    end

endmodule
