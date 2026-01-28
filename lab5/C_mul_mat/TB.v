`timescale 1ns/1ps

module tb_matrix_mul_C4x4;
    reg  signed [31:0] cur_4X4_0_0, cur_4X4_0_1, cur_4X4_0_2, cur_4X4_0_3;
    reg  signed [31:0] cur_4X4_1_0, cur_4X4_1_1, cur_4X4_1_2, cur_4X4_1_3;
    reg  signed [31:0] cur_4X4_2_0, cur_4X4_2_1, cur_4X4_2_2, cur_4X4_2_3;
    reg  signed [31:0] cur_4X4_3_0, cur_4X4_3_1, cur_4X4_3_2, cur_4X4_3_3;

    wire signed [31:0] result_0_0, result_0_1, result_0_2, result_0_3;
    wire signed [31:0] result_1_0, result_1_1, result_1_2, result_1_3;
    wire signed [31:0] result_2_0, result_2_1, result_2_2, result_2_3;
    wire signed [31:0] result_3_0, result_3_1, result_3_2, result_3_3;

    matrix_mul_C4x4 uut (
        .cur_4X4_0_0(cur_4X4_0_0), .cur_4X4_0_1(cur_4X4_0_1), .cur_4X4_0_2(cur_4X4_0_2), .cur_4X4_0_3(cur_4X4_0_3),
        .cur_4X4_1_0(cur_4X4_1_0), .cur_4X4_1_1(cur_4X4_1_1), .cur_4X4_1_2(cur_4X4_1_2), .cur_4X4_1_3(cur_4X4_1_3),
        .cur_4X4_2_0(cur_4X4_2_0), .cur_4X4_2_1(cur_4X4_2_1), .cur_4X4_2_2(cur_4X4_2_2), .cur_4X4_2_3(cur_4X4_2_3),
        .cur_4X4_3_0(cur_4X4_3_0), .cur_4X4_3_1(cur_4X4_3_1), .cur_4X4_3_2(cur_4X4_3_2), .cur_4X4_3_3(cur_4X4_3_3),

        .result_0_0(result_0_0), .result_0_1(result_0_1), .result_0_2(result_0_2), .result_0_3(result_0_3),
        .result_1_0(result_1_0), .result_1_1(result_1_1), .result_1_2(result_1_2), .result_1_3(result_1_3),
        .result_2_0(result_2_0), .result_2_1(result_2_1), .result_2_2(result_2_2), .result_2_3(result_2_3),
        .result_3_0(result_3_0), .result_3_1(result_3_1), .result_3_2(result_3_2), .result_3_3(result_3_3)
    );

    initial begin
        // 測試輸入
        cur_4X4_0_0 = 1;  cur_4X4_0_1 = 2;  cur_4X4_0_2 = 3;  cur_4X4_0_3 = 4;
        cur_4X4_1_0 = 5;  cur_4X4_1_1 = 6;  cur_4X4_1_2 = 7;  cur_4X4_1_3 = 8;
        cur_4X4_2_0 = 9;  cur_4X4_2_1 = 10; cur_4X4_2_2 = 11; cur_4X4_2_3 = 12;
        cur_4X4_3_0 = 13; cur_4X4_3_1 = 14; cur_4X4_3_2 = 15; cur_4X4_3_3 = 16;

        #10;
        $display("==== Result Matrix ====");
        $display("%d %d %d %d", result_0_0, result_0_1, result_0_2, result_0_3);
        $display("%d %d %d %d", result_1_0, result_1_1, result_1_2, result_1_3);
        $display("%d %d %d %d", result_2_0, result_2_1, result_2_2, result_2_3);
        $display("%d %d %d %d", result_3_0, result_3_1, result_3_2, result_3_3);
        $finish;
    end
endmodule