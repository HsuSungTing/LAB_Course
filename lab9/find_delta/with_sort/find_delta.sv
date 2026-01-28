module find_delta (
    input  logic [1:0] type_in,
    input  logic [15:0] MP,
    input  logic [15:0] HP,
    input  logic [15:0] ATK,
    input  logic [15:0] DEF,

    output logic [15:0] Delta_MP,
    output logic [15:0] Delta_HP,
    output logic [15:0] Delta_ATK,
    output logic [15:0] Delta_DEF,

    output logic [15:0] sorted_A0,
    output logic [15:0] sorted_A1,
    output logic [15:0] sorted_A2,
    output logic [15:0] sorted_A3
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
    //out sig
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
    //sorted sig
    always_comb begin
        sorted_A0=A0;   sorted_A1=A1;
        sorted_A2=A2;   sorted_A3=A3;
    end
endmodule