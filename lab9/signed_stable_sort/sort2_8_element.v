// merge_sort - 支援 7-bit values + 5-bit un tokens (tie-break)
module merge_sort(
    // Inputs: values are 7-bit ; tokens are 5-bit un
    input  logic [6:0] in0, in1, in2, in3, in4, in5, in6, in7,
    input  logic [4:0] in_char0, in_char1, in_char2, in_char3, in_char4, in_char5, in_char6, in_char7,
    // Outputs
    output logic [6:0] out0, out1, out2, out3, out4, out5, out6, out7,
    output logic [4:0] out_char0, out_char1, out_char2, out_char3, out_char4, out_char5, out_char6, out_char7
);

    // INTERNAL WIRES (values & tokens)
    logic [6:0] inter1  [7:0];
    logic [6:0] inter2  [7:0];
    logic [6:0] inter3  [3:0];d
    logic [6:0] inter4  [7:0];
    logic [6:0] inter5  [3:0];
    logic [6:0] inter6  [5:0];

    logic [4:0] inter1_char [7:0];
    logic [4:0] inter2_char [7:0];
    logic [4:0] inter3_char [3:0];
    logic [4:0] inter4_char [7:0];
    logic [4:0] inter5_char [3:0];
    logic [4:0] inter6_char [5:0];

    //================================================================
    // Stage 1
    //================================================================
    comparator comp1_1(.a(in0), .b(in1), .a_char(in_char0), .b_char(in_char1),
                       .min_out(inter1[0]), .max_out(inter1[1]),
                       .min_char(inter1_char[0]), .max_char(inter1_char[1]));
    comparator comp1_2(.a(in2), .b(in3), .a_char(in_char2), .b_char(in_char3),
                       .min_out(inter1[2]), .max_out(inter1[3]),
                       .min_char(inter1_char[2]), .max_char(inter1_char[3]));
    comparator comp1_3(.a(in4), .b(in5), .a_char(in_char4), .b_char(in_char5),
                       .min_out(inter1[4]), .max_out(inter1[5]),
                       .min_char(inter1_char[4]), .max_char(inter1_char[5]));
    comparator comp1_4(.a(in6), .b(in7), .a_char(in_char6), .b_char(in_char7),
                       .min_out(inter1[6]), .max_out(inter1[7]),
                       .min_char(inter1_char[6]), .max_char(inter1_char[7]));

    //================================================================
    // Stage 2
    //================================================================
    comparator comp2_1(.a(inter1[0]), .b(inter1[2]), .a_char(inter1_char[0]), .b_char(inter1_char[2]),
                       .min_out(inter2[0]), .max_out(inter2[1]),
                       .min_char(inter2_char[0]), .max_char(inter2_char[1]));
    comparator comp2_2(.a(inter1[1]), .b(inter1[3]), .a_char(inter1_char[1]), .b_char(inter1_char[3]),
                       .min_out(inter2[2]), .max_out(inter2[3]),
                       .min_char(inter2_char[2]), .max_char(inter2_char[3]));
    comparator comp2_3(.a(inter1[4]), .b(inter1[6]), .a_char(inter1_char[4]), .b_char(inter1_char[6]),
                       .min_out(inter2[4]), .max_out(inter2[5]),
                       .min_char(inter2_char[4]), .max_char(inter2_char[5]));
    comparator comp2_4(.a(inter1[5]), .b(inter1[7]), .a_char(inter1_char[5]), .b_char(inter1_char[7]),
                       .min_out(inter2[6]), .max_out(inter2[7]),
                       .min_char(inter2_char[6]), .max_char(inter2_char[7]));

    //================================================================
    // Stage 3
    //================================================================
    comparator comp3_1(.a(inter2[1]), .b(inter2[2]), .a_char(inter2_char[1]), .b_char(inter2_char[2]),
                       .min_out(inter3[0]), .max_out(inter3[1]),
                       .min_char(inter3_char[0]), .max_char(inter3_char[1]));
    comparator comp3_2(.a(inter2[5]), .b(inter2[6]), .a_char(inter2_char[5]), .b_char(inter2_char[6]),
                       .min_out(inter3[2]), .max_out(inter3[3]),
                       .min_char(inter3_char[2]), .max_char(inter3_char[3]));

    //================================================================
    // Stage 4
    //================================================================
    comparator comp4_1(.a(inter2[0]), .b(inter2[4]), .a_char(inter2_char[0]), .b_char(inter2_char[4]),
                       .min_out(inter4[0]), .max_out(inter4[4]),
                       .min_char(inter4_char[0]), .max_char(inter4_char[4]));
    comparator comp4_2(.a(inter3[0]), .b(inter3[2]), .a_char(inter3_char[0]), .b_char(inter3_char[2]),
                       .min_out(inter4[1]), .max_out(inter4[5]),
                       .min_char(inter4_char[1]), .max_char(inter4_char[5]));
    comparator comp4_3(.a(inter3[1]), .b(inter3[3]), .a_char(inter3_char[1]), .b_char(inter3_char[3]),
                       .min_out(inter4[2]), .max_out(inter4[6]),
                       .min_char(inter4_char[2]), .max_char(inter4_char[6]));
    comparator comp4_4(.a(inter2[3]), .b(inter2[7]), .a_char(inter2_char[3]), .b_char(inter2_char[7]),
                       .min_out(inter4[3]), .max_out(inter4[7]),
                       .min_char(inter4_char[3]), .max_char(inter4_char[7]));

    //================================================================
    // Stage 5
    //================================================================
    comparator comp5_1(.a(inter4[2]), .b(inter4[4]), .a_char(inter4_char[2]), .b_char(inter4_char[4]),
                       .min_out(inter5[0]), .max_out(inter5[2]),
                       .min_char(inter5_char[0]), .max_char(inter5_char[2]));
    comparator comp5_2(.a(inter4[3]), .b(inter4[5]), .a_char(inter4_char[3]), .b_char(inter4_char[5]),
                       .min_out(inter5[1]), .max_out(inter5[3]),
                       .min_char(inter5_char[1]), .max_char(inter5_char[3]));

    //================================================================
    // Stage 6
    //================================================================
    comparator comp6_1(.a(inter4[1]), .b(inter5[0]), .a_char(inter4_char[1]), .b_char(inter5_char[0]),
                       .min_out(inter6[0]), .max_out(inter6[1]),
                       .min_char(inter6_char[0]), .max_char(inter6_char[1]));
    comparator comp6_2(.a(inter5[1]), .b(inter5[2]), .a_char(inter5_char[1]), .b_char(inter5_char[2]),
                       .min_out(inter6[2]), .max_out(inter6[3]),
                       .min_char(inter6_char[2]), .max_char(inter6_char[3]));
    comparator comp6_3(.a(inter5[3]), .b(inter4[6]), .a_char(inter5_char[3]), .b_char(inter4_char[6]),
                       .min_out(inter6[4]), .max_out(inter6[5]),
                       .min_char(inter6_char[4]), .max_char(inter6_char[5]));

    //================================================================
    // Outputs
    //================================================================
    assign out0      = inter4[0]; assign out_char0 = inter4_char[0];
    assign out1      = inter6[0]; assign out_char1 = inter6_char[0];
    assign out2      = inter6[1]; assign out_char2 = inter6_char[1];
    assign out3      = inter6[2]; assign out_char3 = inter6_char[2];
    assign out4      = inter6[3]; assign out_char4 = inter6_char[3];
    assign out5      = inter6[4]; assign out_char5 = inter6_char[4];
    assign out6      = inter6[5]; assign out_char6 = inter6_char[5];
    assign out7      = inter4[7]; assign out_char7 = inter4_char[7];

endmodule


// comparator - compare on values (7-bit), tie-break using token (5-bit)
module comparator(
    input  logic [6:0] a, b,         // 7-bit inputs
    input  logic [4:0] a_char, b_char, // 5-bit tie-break token
    output logic [6:0] min_out, max_out,
    output logic [4:0] min_char, max_char
);
    always_comb begin
        if (a > b) begin
            max_out  = a;       max_char  = a_char;
            min_out  = b;       min_char  = b_char;
        end
        else if (a < b) begin
            max_out  = b;       max_char  = b_char;
            min_out  = a;       min_char  = a_char;
        end
        else begin
            // tie-break by token, smaller token considered larger
            if (a_char < b_char) begin
                max_out  = a;   max_char  = a_char;
                min_out  = b;   min_char  = b_char;
            end
            else begin
                max_out  = b;   max_char  = b_char;
                min_out  = a;   min_char  = a_char;
            end
        end
    end
endmodule