module find_delta (
    input  logic [1:0] type_in,
    input  logic [15:0] MP,
    input  logic [15:0] HP,
    input  logic [15:0] ATK,
    input  logic [15:0] DEF,

    output logic [15:0] Delta_MP,
    output logic [15:0] Delta_HP,
    output logic [15:0] Delta_ATK,
    output logic [15:0] Delta_DEF
);
    //type A
    logic [15:0] out_attr_arr_A [0:3];    //MP, HP, ATK, DEF
    logic [15:0] result_A;
    assign result_A=(MP+HP+ATK+DEF)>>3;
    always_comb begin
        out_attr_arr_A[0]=result_A;
        out_attr_arr_A[1]=result_A;
        out_attr_arr_A[2]=result_A;
        out_attr_arr_A[3]=result_A;
    end
    //type B
    logic [15:0] A0,A1,A2,A3;
    logic [1:0] char_A0, char_A1, char_A2, char_A3;
    merge_sort_4 sort_inst(
        .in0(MP), .in1(HP), .in2(ATK), .in3(DEF),
        .in_char0(2'd0), .in_char1(2'd1), .in_char2(2'd2), .in_char3(2'd3),
        .out0(A0), .out1(A1), .out2(A2), .out3(A3),
        .out_char0(char_A0), .out_char1(char_A1), .out_char2(char_A2), .out_char3(char_A3)
    );
    logic [15:0] out_attr_arr_B [0:3];    //MP, HP, ATK, DEF
    always_comb begin
        out_attr_arr_B[char_A0]=A2-A0;
        out_attr_arr_B[char_A1]=A3-A1;
        out_attr_arr_B[char_A2]=0;
        out_attr_arr_B[char_A3]=0;
    end
    //type C
    logic [15:0] out_attr_arr_C [0:3];    //MP, HP, ATK, DEF
    always_comb begin
        if(MP<16383) out_attr_arr_C[0]=16383-MP;
        else out_attr_arr_C[0]=0;
        if(HP<16383) out_attr_arr_C[1]=16383-HP;
        else out_attr_arr_C[1]=0;
        if(ATK<16383) out_attr_arr_C[2]=16383-ATK;
        else out_attr_arr_C[2]=0;
        if(DEF<16383) out_attr_arr_C[3]=16383-DEF;
        else out_attr_arr_C[3]=0;
    end
    //type D
    logic [15:0] out_attr_arr_D_temp [0:3];
    logic [15:0] out_attr_arr_D [0:3];
    assign out_attr_arr_D_temp[0]= 3000+((65535-MP)>>4);
    assign out_attr_arr_D_temp[1]= 3000+((65535-HP)>>4);
    assign out_attr_arr_D_temp[2]= 3000+((65535-ATK)>>4);
    assign out_attr_arr_D_temp[3]= 3000+((65535-DEF)>>4);
    assign out_attr_arr_D[0]=(out_attr_arr_D_temp[0]>5047)? 5047:out_attr_arr_D_temp[0];
    assign out_attr_arr_D[1]=(out_attr_arr_D_temp[1]>5047)? 5047:out_attr_arr_D_temp[1];
    assign out_attr_arr_D[2]=(out_attr_arr_D_temp[2]>5047)? 5047:out_attr_arr_D_temp[2];
    assign out_attr_arr_D[3]=(out_attr_arr_D_temp[3]>5047)? 5047:out_attr_arr_D_temp[3];
    always_comb begin
        case(type_in)
            0:begin
                Delta_MP=out_attr_arr_A[0]; Delta_HP=out_attr_arr_A[1];
                Delta_ATK=out_attr_arr_A[2];Delta_DEF=out_attr_arr_A[3];
            end
            1:begin
                Delta_MP=out_attr_arr_B[0]; Delta_HP=out_attr_arr_B[1];
                Delta_ATK=out_attr_arr_B[2];Delta_DEF=out_attr_arr_B[3];
            end
            2:begin
                Delta_MP=out_attr_arr_C[0]; Delta_HP=out_attr_arr_C[1];
                Delta_ATK=out_attr_arr_C[2];Delta_DEF=out_attr_arr_C[3];
            end
            3:begin
                Delta_MP=out_attr_arr_D[0]; Delta_HP=out_attr_arr_D[1];
                Delta_ATK=out_attr_arr_D[2];Delta_DEF=out_attr_arr_D[3];
            end
            default:begin
                Delta_MP=out_attr_arr_A[0]; Delta_HP=out_attr_arr_A[1];
                Delta_ATK=out_attr_arr_A[2];Delta_DEF=out_attr_arr_A[3];
            end
        endcase
    end
endmodule

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