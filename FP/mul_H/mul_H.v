module mul_H (
    input  signed [12:0] a00, a01, a02, a03,
    input  signed [12:0] a10, a11, a12, a13,
    input  signed [12:0] a20, a21, a22, a23,
    input  signed [12:0] a30, a31, a32, a33,
    output signed [15:0] b00, b01, b02, b03,
    output signed [15:0] b10, b11, b12, b13,
    output signed [15:0] b20, b21, b22, b23,
    output signed [15:0] b30, b31, b32, b33
);

    // Row 0
    assign b00 =  a00 +  a01 +  a02 +  a03; // row0 * col0 (1,1,1,1)
    assign b01 =  a00 -  a01 +  a02 -  a03; // row0 * col1 (1,-1,1,-1)
    assign b02 =  a00 +  a01 -  a02 -  a03; // row0 * col2 (1,1,-1,-1)
    assign b03 =  a00 -  a01 -  a02 +  a03; // row0 * col3 (1,-1,-1,1)

    // Row 1
    assign b10 =  a10 +  a11 +  a12 +  a13;
    assign b11 =  a10 -  a11 +  a12 -  a13;
    assign b12 =  a10 +  a11 -  a12 -  a13;
    assign b13 =  a10 -  a11 -  a12 +  a13;

    // Row 2
    assign b20 =  a20 +  a21 +  a22 +  a23;
    assign b21 =  a20 -  a21 +  a22 -  a23;
    assign b22 =  a20 +  a21 -  a22 -  a23;
    assign b23 =  a20 -  a21 -  a22 +  a23;

    // Row 3
    assign b30 =  a30 +  a31 +  a32 +  a33;
    assign b31 =  a30 -  a31 +  a32 -  a33;
    assign b32 =  a30 +  a31 -  a32 -  a33;
    assign b33 =  a30 -  a31 -  a32 +  a33;

endmodule
