module matrix_mul_curxC_4x4 (
    // inputs: cur[row][col]
    input  signed [31:0] cur_4X4_0_0, input signed [31:0] cur_4X4_0_1, input signed [31:0] cur_4X4_0_2, input signed [31:0] cur_4X4_0_3,
    input  signed [31:0] cur_4X4_1_0, input signed [31:0] cur_4X4_1_1, input signed [31:0] cur_4X4_1_2, input signed [31:0] cur_4X4_1_3,
    input  signed [31:0] cur_4X4_2_0, input signed [31:0] cur_4X4_2_1, input signed [31:0] cur_4X4_2_2, input signed [31:0] cur_4X4_2_3,
    input  signed [31:0] cur_4X4_3_0, input signed [31:0] cur_4X4_3_1, input signed [31:0] cur_4X4_3_2, input signed [31:0] cur_4X4_3_3,

    // outputs: result[row][col]  = cur[row,:] * C[:,col]
    output signed [31:0] result_0_0, output signed [31:0] result_0_1, output signed [31:0] result_0_2, output signed [31:0] result_0_3,
    output signed [31:0] result_1_0, output signed [31:0] result_1_1, output signed [31:0] result_1_2, output signed [31:0] result_1_3,
    output signed [31:0] result_2_0, output signed [31:0] result_2_1, output signed [31:0] result_2_2, output signed [31:0] result_2_3,
    output signed [31:0] result_3_0, output signed [31:0] result_3_1, output signed [31:0] result_3_2, output signed [31:0] result_3_3
);

    // C matrix (columns):
    // col0 = [1,  1,  1,  1]
    // col1 = [1,  1, -1, -1]
    // col2 = [1, -1, -1,  1]
    // col3 = [1, -1,  1, -1]

    // result[row][0] = cur[row][0] + cur[row][1] + cur[row][2] + cur[row][3]
    assign result_0_0 = cur_4X4_0_0 + cur_4X4_0_1 + cur_4X4_0_2 + cur_4X4_0_3;
    assign result_1_0 = cur_4X4_1_0 + cur_4X4_1_1 + cur_4X4_1_2 + cur_4X4_1_3;
    assign result_2_0 = cur_4X4_2_0 + cur_4X4_2_1 + cur_4X4_2_2 + cur_4X4_2_3;
    assign result_3_0 = cur_4X4_3_0 + cur_4X4_3_1 + cur_4X4_3_2 + cur_4X4_3_3;

    // result[row][1] = cur[row][0] + cur[row][1] - cur[row][2] - cur[row][3]
    assign result_0_1 = cur_4X4_0_0 + cur_4X4_0_1 - cur_4X4_0_2 - cur_4X4_0_3;
    assign result_1_1 = cur_4X4_1_0 + cur_4X4_1_1 - cur_4X4_1_2 - cur_4X4_1_3;
    assign result_2_1 = cur_4X4_2_0 + cur_4X4_2_1 - cur_4X4_2_2 - cur_4X4_2_3;
    assign result_3_1 = cur_4X4_3_0 + cur_4X4_3_1 - cur_4X4_3_2 - cur_4X4_3_3;

    // result[row][2] = cur[row][0] - cur[row][1] - cur[row][2] + cur[row][3]
    assign result_0_2 = cur_4X4_0_0 - cur_4X4_0_1 - cur_4X4_0_2 + cur_4X4_0_3;
    assign result_1_2 = cur_4X4_1_0 - cur_4X4_1_1 - cur_4X4_1_2 + cur_4X4_1_3;
    assign result_2_2 = cur_4X4_2_0 - cur_4X4_2_1 - cur_4X4_2_2 + cur_4X4_2_3;
    assign result_3_2 = cur_4X4_3_0 - cur_4X4_3_1 - cur_4X4_3_2 + cur_4X4_3_3;

    // result[row][3] = cur[row][0] - cur[row][1] + cur[row][2] - cur[row][3]
    assign result_0_3 = cur_4X4_0_0 - cur_4X4_0_1 + cur_4X4_0_2 - cur_4X4_0_3;
    assign result_1_3 = cur_4X4_1_0 - cur_4X4_1_1 + cur_4X4_1_2 - cur_4X4_1_3;
    assign result_2_3 = cur_4X4_2_0 - cur_4X4_2_1 + cur_4X4_2_2 - cur_4X4_2_3;
    assign result_3_3 = cur_4X4_3_0 - cur_4X4_3_1 + cur_4X4_3_2 - cur_4X4_3_3;

endmodule