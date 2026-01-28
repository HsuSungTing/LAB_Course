module diff_compare(
    input  logic [15:0] X,
    output logic [15:0] Y_sub,
    output logic [15:0] Y_not
);

    // 方法 1：真正減法器
    assign Y_sub = 16'd16383 - X;

    // 方法 2：bitwise NOT only on lower 14 bits
    assign Y_not = {2'b00, ~X[13:0]};

endmodule
