// merge_sort_4 - 支援 7-bit values + 5-bit un tokens (tie-break)
module merge_sort_4(
    // Inputs: values are 7-bit ; tokens are 5-bit un
    input  logic [6:0] in0, in1, in2, in3,
    input  logic [4:0] in_char0, in_char1, in_char2, in_char3,

    // Outputs
    output logic [6:0] out0, out1, out2, out3,
    output logic [4:0] out_char0, out_char1, out_char2, out_char3
);

    //==========================================================
    // INTERNAL WIRES (values & tokens)
    //==========================================================
    logic [6:0] inter1 [3:0];
    logic [6:0] inter2 [3:0];
    logic [6:0] inter3 [3:0];

    logic [4:0] inter1_char [3:0];
    logic [4:0] inter2_char [3:0];
    logic [4:0] inter3_char [3:0];

    //==========================================================
    // Stage 1
    // pairwise compare: (0,1), (2,3)
    //==========================================================
    comparator comp1_1(.a(in0), .b(in1), .a_char(in_char0), .b_char(in_char1),
                       .min_out(inter1[0]), .max_out(inter1[1]),
                       .min_char(inter1_char[0]), .max_char(inter1_char[1]));

    comparator comp1_2(.a(in2), .b(in3), .a_char(in_char2), .b_char(in_char3),
                       .min_out(inter1[2]), .max_out(inter1[3]),
                       .min_char(inter1_char[2]), .max_char(inter1_char[3]));

    //==========================================================
    // Stage 2
    // merge: (0,2) and (1,3)
    //==========================================================
    comparator comp2_1(.a(inter1[0]), .b(inter1[2]),
                       .a_char(inter1_char[0]), .b_char(inter1_char[2]),
                       .min_out(inter2[0]), .max_out(inter2[2]),
                       .min_char(inter2_char[0]), .max_char(inter2_char[2]));

    comparator comp2_2(.a(inter1[1]), .b(inter1[3]),
                       .a_char(inter1_char[1]), .b_char(inter1_char[3]),
                       .min_out(inter2[1]), .max_out(inter2[3]),
                       .min_char(inter2_char[1]), .max_char(inter2_char[3]));

    //==========================================================
    // Stage 3
    // middle adjustment: (1,2)
    //==========================================================
    comparator comp3_1(.a(inter2[1]), .b(inter2[2]),
                       .a_char(inter2_char[1]), .b_char(inter2_char[2]),
                       .min_out(inter3[1]), .max_out(inter3[2]),
                       .min_char(inter3_char[1]), .max_char(inter3_char[2]));

    // retain boundary elements
    assign inter3[0] = inter2[0];
    assign inter3[3] = inter2[3];
    assign inter3_char[0] = inter2_char[0];
    assign inter3_char[3] = inter2_char[3];

    //==========================================================
    // Outputs (sorted order)
    //==========================================================
    assign out0 = inter3[0];
    assign out1 = inter3[1];
    assign out2 = inter3[2];
    assign out3 = inter3[3];

    assign out_char0 = inter3_char[0];
    assign out_char1 = inter3_char[1];
    assign out_char2 = inter3_char[2];
    assign out_char3 = inter3_char[3];

endmodule


//==============================================================
// comparator - compare on values (7-bit), tie-break using token
//==============================================================
module comparator(
    input  logic [6:0] a, b,           // 7-bit inputs
    input  logic [4:0] a_char, b_char, // 5-bit tie-break token
    output logic [6:0] min_out, max_out,
    output logic [4:0] min_char, max_char
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
        else begin
            // tie-break by token (smaller token = larger)
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