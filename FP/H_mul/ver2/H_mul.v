module mul_H (
    input  signed [12:0] a00, a01, a02, a03,
    input  signed [12:0] a10, a11, a12, a13,
    input  signed [12:0] a20, a21, a22, a23,
    input  signed [12:0] a30, a31, a32, a33,
    output [12:0] b00, b01, b02, b03,
    output [12:0] b10, b11, b12, b13,
    output [12:0] b20, b21, b22, b23,
    output [12:0] b30, b31, b32, b33
);

    // 原始计算结果 (16-bit signed)
    wire signed [15:0] r00 = a00 + a01 + a02 + a03;
    wire signed [15:0] r01 = a00 - a01 + a02 - a03;
    wire signed [15:0] r02 = a00 + a01 - a02 - a03;
    wire signed [15:0] r03 = a00 - a01 - a02 + a03;

    wire signed [15:0] r10 = a10 + a11 + a12 + a13;
    wire signed [15:0] r11 = a10 - a11 + a12 - a13;
    wire signed [15:0] r12 = a10 + a11 - a12 - a13;
    wire signed [15:0] r13 = a10 - a11 - a12 + a13;

    wire signed [15:0] r20 = a20 + a21 + a22 + a23;
    wire signed [15:0] r21 = a20 - a21 + a22 - a23;
    wire signed [15:0] r22 = a20 + a21 - a22 - a23;
    wire signed [15:0] r23 = a20 - a21 - a22 + a23;

    wire signed [15:0] r30 = a30 + a31 + a32 + a33;
    wire signed [15:0] r31 = a30 - a31 + a32 - a33;
    wire signed [15:0] r32 = a30 + a31 - a32 - a33;
    wire signed [15:0] r33 = a30 - a31 - a32 + a33;

    // 绝对值输出（使用直接负号 -rXX）
    assign b00 = (r00 < 0) ? -r00 : r00;
    assign b01 = (r01 < 0) ? -r01 : r01;
    assign b02 = (r02 < 0) ? -r02 : r02;
    assign b03 = (r03 < 0) ? -r03 : r03;

    assign b10 = (r10 < 0) ? -r10 : r10;
    assign b11 = (r11 < 0) ? -r11 : r11;
    assign b12 = (r12 < 0) ? -r12 : r12;
    assign b13 = (r13 < 0) ? -r13 : r13;

    assign b20 = (r20 < 0) ? -r20 : r20;
    assign b21 = (r21 < 0) ? -r21 : r21;
    assign b22 = (r22 < 0) ? -r22 : r22;
    assign b23 = (r23 < 0) ? -r23 : r23;

    assign b30 = (r30 < 0) ? -r30 : r30;
    assign b31 = (r31 < 0) ? -r31 : r31;
    assign b32 = (r32 < 0) ? -r32 : r32;
    assign b33 = (r33 < 0) ? -r33 : r33;

endmodule
