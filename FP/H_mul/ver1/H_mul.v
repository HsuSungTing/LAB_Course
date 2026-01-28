module hadamard4x4_nosignext (
    input  signed [9:0] a00, a01, a02, a03,
    input  signed [9:0] a10, a11, a12, a13,
    input  signed [9:0] a20, a21, a22, a23,
    input  signed [9:0] a30, a31, a32, a33,
    output signed [12:0] b00, b01, b02, b03,
    output signed [12:0] b10, b11, b12, b13,
    output signed [12:0] b20, b21, b22, b23,
    output signed [12:0] b30, b31, b32, b33
);

assign b00 = a00 + a10 + a20 + a30; // + + + +
assign b10 = a00 - a10 + a20 - a30; // + - + -
assign b20 = a00 + a10 - a20 - a30; // + + - -
assign b30 = a00 - a10 - a20 + a30; // + - - +

assign b01 = a01 + a11 + a21 + a31;
assign b11 = a01 - a11 + a21 - a31;
assign b21 = a01 + a11 - a21 - a31;
assign b31 = a01 - a11 - a21 + a31;

assign b02 = a02 + a12 + a22 + a32;
assign b12 = a02 - a12 + a22 - a32;
assign b22 = a02 + a12 - a22 - a32;
assign b32 = a02 - a12 - a22 + a32;

assign b03 = a03 + a13 + a23 + a33;
assign b13 = a03 - a13 + a23 - a33;
assign b23 = a03 + a13 - a23 - a33;
assign b33 = a03 - a13 - a23 + a33;

endmodule
