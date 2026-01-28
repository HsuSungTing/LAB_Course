module merge_sort_4(
    input  logic [15:0] in0, in1, in2, in3,
    input  logic [1:0]  in_char0, in_char1, in_char2, in_char3,
    output logic [15:0] out0, out1, out2, out3,
    output logic [1:0]  out_char0, out_char1, out_char2, out_char3
);
    // INTERNAL WIRES (values & tokens)
    logic [15:0] inter1 [3:0];
    logic [15:0] inter2 [3:0];
    logic [15:0] inter3 [3:0];

    logic [1:0] inter1_char [3:0];
    logic [1:0] inter2_char [3:0];
    logic [1:0] inter3_char [3:0];

    // Stage 1 pairwise compare: (0,1), (2,3)
    comparator comp1_1(
        .a(in0), .b(in1),
        .a_char(in_char0), .b_char(in_char1),
        .min_out(inter1[0]), .max_out(inter1[1]),
        .min_char(inter1_char[0]), .max_char(inter1_char[1])
    );

    comparator comp1_2(
        .a(in2), .b(in3),
        .a_char(in_char2), .b_char(in_char3),
        .min_out(inter1[2]), .max_out(inter1[3]),
        .min_char(inter1_char[2]), .max_char(inter1_char[3])
    );

    // Stage 2 merge: (0,2) and (1,3)
    comparator comp2_1(
        .a(inter1[0]), .b(inter1[2]),
        .a_char(inter1_char[0]), .b_char(inter1_char[2]),
        .min_out(inter2[0]), .max_out(inter2[2]),
        .min_char(inter2_char[0]), .max_char(inter2_char[2])
    );

    comparator comp2_2(
        .a(inter1[1]), .b(inter1[3]),
        .a_char(inter1_char[1]), .b_char(inter1_char[3]),
        .min_out(inter2[1]), .max_out(inter2[3]),
        .min_char(inter2_char[1]), .max_char(inter2_char[3])
    );

    // Stage 3 middle adjustment: (1,2)
    comparator comp3_1(
        .a(inter2[1]), .b(inter2[2]),
        .a_char(inter2_char[1]), .b_char(inter2_char[2]),
        .min_out(inter3[1]), .max_out(inter3[2]),
        .min_char(inter3_char[1]), .max_char(inter3_char[2])
    );

    // retain boundary elements
    assign inter3[0] = inter2[0];
    assign inter3[3] = inter2[3];
    assign inter3_char[0] = inter2_char[0];
    assign inter3_char[3] = inter2_char[3];

    // Outputs (sorted order)
    assign out0 = inter3[0];
    assign out1 = inter3[1];
    assign out2 = inter3[2];
    assign out3 = inter3[3];

    assign out_char0 = inter3_char[0];
    assign out_char1 = inter3_char[1];
    assign out_char2 = inter3_char[2];
    assign out_char3 = inter3_char[3];
endmodule

module comparator(
    input  logic [15:0] a, b,           // 16-bit inputs
    input  logic [1:0]  a_char, b_char, // 2-bit tie-break token
    output logic [15:0] min_out, max_out,
    output logic [1:0]  min_char, max_char
);
    always_comb begin
        if (a > b) begin
            max_out  = a;  max_char = a_char;
            min_out  = b;  min_char = b_char;
        end
        else if (a < b) begin
            max_out  = b;  max_char = b_char;
            min_out  = a;  min_char = a_char;
        end
        else begin  // tie-break by token (smaller token = larger)
            if (a_char < b_char) begin
                max_out  = b;  max_char = b_char;
                min_out  = a;  min_char = a_char;
            end
            else begin
                max_out  = a;  max_char = a_char;
                min_out  = b;  min_char = b_char;
            end
        end
    end
endmodule

module merge_sort_4_three_stage(
    input  logic [15:0] in0, in1, in2, in3,
    input  logic [1:0]  in_char0, in_char1, in_char2, in_char3,
    output logic [15:0] out0, out1, out2, out3,
    output logic [1:0]  out_char0, out_char1, out_char2, out_char3
);

    // stage1 <-> stage2 中間信號
    logic [15:0] s1[3:0], s2[3:0];
    logic [1:0]  s1c[3:0], s2c[3:0];

    // Stage1
    stage1 S1(
        .in0(in0), .in1(in1), .in2(in2), .in3(in3),
        .in_char0(in_char0), .in_char1(in_char1), .in_char2(in_char2), .in_char3(in_char3),
        .s1_0(s1[0]), .s1_1(s1[1]), .s1_2(s1[2]), .s1_3(s1[3]),
        .s1_c0(s1c[0]), .s1_c1(s1c[1]), .s1_c2(s1c[2]), .s1_c3(s1c[3])
    );

    // Stage2
    stage2 S2(
        .s1_0(s1[0]), .s1_1(s1[1]), .s1_2(s1[2]), .s1_3(s1[3]),
        .s1_c0(s1c[0]), .s1_c1(s1c[1]), .s1_c2(s1c[2]), .s1_c3(s1c[3]),
        .s2_0(s2[0]), .s2_1(s2[1]), .s2_2(s2[2]), .s2_3(s2[3]),
        .s2_c0(s2c[0]), .s2_c1(s2c[1]), .s2_c2(s2c[2]), .s2_c3(s2c[3])
    );

    // Stage3 (修正版，確保四元素完全排序)
    stage3 S3(
        .s2_0(s2[0]), .s2_1(s2[1]), .s2_2(s2[2]), .s2_3(s2[3]),
        .s2_c0(s2c[0]), .s2_c1(s2c[1]), .s2_c2(s2c[2]), .s2_c3(s2c[3]),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3),
        .out_c0(out_char0), .out_c1(out_char1), .out_c2(out_char2), .out_c3(out_char3)
    );

endmodule

module stage1(
    input  logic [15:0] in0, in1, in2, in3,
    input  logic [1:0]  in_char0, in_char1, in_char2, in_char3,
    output logic [15:0] s1_0, s1_1, s1_2, s1_3,
    output logic [1:0]  s1_c0, s1_c1, s1_c2, s1_c3
);

    comparator c1(
        .a(in0), .b(in1),
        .a_char(in_char0), .b_char(in_char1),
        .min_out(s1_0), .max_out(s1_1),
        .min_char(s1_c0), .max_char(s1_c1)
    );

    comparator c2(
        .a(in2), .b(in3),
        .a_char(in_char2), .b_char(in_char3),
        .min_out(s1_2), .max_out(s1_3),
        .min_char(s1_c2), .max_char(s1_c3)
    );

endmodule

module stage2(
    input  logic [15:0] s1_0, s1_1, s1_2, s1_3,
    input  logic [1:0]  s1_c0, s1_c1, s1_c2, s1_c3,
    output logic [15:0] s2_0, s2_1, s2_2, s2_3,
    output logic [1:0]  s2_c0, s2_c1, s2_c2, s2_c3
);

    comparator c1(
        .a(s1_0), .b(s1_2),
        .a_char(s1_c0), .b_char(s1_c2),
        .min_out(s2_0), .max_out(s2_2),
        .min_char(s2_c0), .max_char(s2_c2)
    );

    comparator c2(
        .a(s1_1), .b(s1_3),
        .a_char(s1_c1), .b_char(s1_c3),
        .min_out(s2_1), .max_out(s2_3),
        .min_char(s2_c1), .max_char(s2_c3)
    );

endmodule

module stage3(
    input  logic [15:0] s2_0, s2_1, s2_2, s2_3,
    input  logic [1:0]  s2_c0, s2_c1, s2_c2, s2_c3,
    output logic [15:0] out0, out1, out2, out3,
    output logic [1:0]  out_c0, out_c1, out_c2, out_c3
);

    comparator c1(
        .a(s2_1), .b(s2_2),
        .a_char(s2_c1), .b_char(s2_c2),
        .min_out(out1), .max_out(out2),
        .min_char(out_c1), .max_char(out_c2)
    );

    // boundaries
    assign out0  = s2_0;
    assign out3  = s2_3;
    assign out_c0 = s2_c0;
    assign out_c3 = s2_c3;

endmodule