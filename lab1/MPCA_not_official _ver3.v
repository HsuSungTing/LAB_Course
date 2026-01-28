module MPCA(
    // Input signals
    input [127:0] packets,
    input  [11:0] channel_load,
    input   [8:0] channel_capacity,
    input  [63:0] KEY,
    // Output signals
    output reg [15:0] grant_channel
);

//Part 2 Comb Logic
wire [15:0] l_2,l_1,l_0,K0;
assign l_2= KEY[63:48];
assign l_1= KEY[47:32];
assign l_0= KEY[31:16];
assign K0= KEY[15:0];

reg [15:0] pkt [0:7];       //pkt0到pkt7
wire [15:0] ori_pkt [0:7];  //pkt0到pkt7

always @(*) begin
    pkt[0]=packets[15:0]; pkt[1]=packets[31:16]; pkt[2]=packets[47:32];
    pkt[3]=packets[63:48]; pkt[4]=packets[79:64]; pkt[5]=packets[95:80];
    pkt[6]=packets[111:96]; pkt[7]=packets[127:112];
end

//===decrypt===
reg [15:0]ROR7_temp[0:2];
reg [15:0]K1,K2,K3;
always@(*)begin
    ROR7_temp[0]={K0[6:0],K0[15:7]};
    K1=(ROR7_temp[0]+l_0)^16'd0; //ROR7

    ROR7_temp[1]={K1[6:0],K1[15:7]};
    K2=(ROR7_temp[1]+l_1)^16'd1;

    ROR7_temp[2]={K2[6:0],K2[15:7]};
    K3=(ROR7_temp[2]+l_2)^16'd2;
end

find_ori_pkt P1_0(
    .K0(K0), .K1(K1), .K2(K2),.K3(K3),
    .pkt_1_in(pkt[1]), .pkt_0_in(pkt[0]),
    .pkt_1_out(ori_pkt[1]), .pkt_0_out(ori_pkt[0]));

find_ori_pkt P3_2(
    .K0(K0), .K1(K1), .K2(K2),.K3(K3),
    .pkt_1_in(pkt[3]), .pkt_0_in(pkt[2]),
    .pkt_1_out(ori_pkt[3]), .pkt_0_out(ori_pkt[2]));

find_ori_pkt P5_4(
    .K0(K0), .K1(K1), .K2(K2),.K3(K3),
    .pkt_1_in(pkt[5]), .pkt_0_in(pkt[4]),
    .pkt_1_out(ori_pkt[5]), .pkt_0_out(ori_pkt[4]));

find_ori_pkt P7_6(
    .K0(K0), .K1(K1), .K2(K2),.K3(K3),
    .pkt_1_in(pkt[7]), .pkt_0_in(pkt[6]),
    .pkt_1_out(ori_pkt[7]), .pkt_0_out(ori_pkt[6]));
//==============

wire signed [6:0] p_score [0:7];   //priority score

find_priority_score PS0(.ori_pkt(ori_pkt[0]),.priority_score(p_score[0]));
find_priority_score PS1(.ori_pkt(ori_pkt[1]),.priority_score(p_score[1]));
find_priority_score PS2(.ori_pkt(ori_pkt[2]),.priority_score(p_score[2]));
find_priority_score PS3(.ori_pkt(ori_pkt[3]),.priority_score(p_score[3]));
find_priority_score PS4(.ori_pkt(ori_pkt[4]),.priority_score(p_score[4]));
find_priority_score PS5(.ori_pkt(ori_pkt[5]),.priority_score(p_score[5]));
find_priority_score PS6(.ori_pkt(ori_pkt[6]),.priority_score(p_score[6]));
find_priority_score PS7(.ori_pkt(ori_pkt[7]),.priority_score(p_score[7]));

//===sort===
wire signed [6:0] sorted_pkt [0:7]; //(priority score )sorted_pkt [0] priority最大
wire [2:0] sorted_pkt_id [0:7];     //sorted_pkt_id [0] priority最大
wire [1:0] sorted_target_chl [0:7]; //sorted_target_chl[0] priority最大

merge_sort sort0(
    //Inputs:values are 7-bit signed; tokens are 3-bit unsigned
    .in0(p_score[0]), .in1(p_score[1]), .in2(p_score[2]), .in3(p_score[3]),
    .in4(p_score[4]), .in5(p_score[5]), .in6(p_score[6]), .in7(p_score[7]),
    .in_char0(3'd0), .in_char1(3'd1), .in_char2(3'd2), .in_char3(3'd3), 
    .in_char4(3'd4), .in_char5(3'd5), .in_char6(3'd6), .in_char7(3'd7),
    //Outputs
    .out0(sorted_pkt[7]),.out1(sorted_pkt[6]),.out2(sorted_pkt[5]),.out3(sorted_pkt[4]),
    .out4(sorted_pkt[3]),.out5(sorted_pkt[2]),.out6(sorted_pkt[1]),.out7(sorted_pkt[0]),
    .out_char0(sorted_pkt_id[7]),.out_char1(sorted_pkt_id[6]), 
    .out_char2(sorted_pkt_id[5]),.out_char3(sorted_pkt_id[4]), 
    .out_char4(sorted_pkt_id[3]),.out_char5(sorted_pkt_id[2]), 
    .out_char6(sorted_pkt_id[1]),.out_char7(sorted_pkt_id[0])
);
//=========

//===for debug===
reg req_valid_arr[0:7];
reg [1:0] prefer_chl_arr[0:7];

always@(*)begin
    prefer_chl_arr[0]=ori_pkt[sorted_pkt_id[0]][6:5];
    req_valid_arr[0]=ori_pkt[sorted_pkt_id[0]][15];

    prefer_chl_arr[1]=ori_pkt[sorted_pkt_id[1]][6:5];
    req_valid_arr[1]=ori_pkt[sorted_pkt_id[1]][15];

    prefer_chl_arr[2]=ori_pkt[sorted_pkt_id[2]][6:5];
    req_valid_arr[2]=ori_pkt[sorted_pkt_id[2]][15];

    prefer_chl_arr[3]=ori_pkt[sorted_pkt_id[3]][6:5];
    req_valid_arr[3]=ori_pkt[sorted_pkt_id[3]][15];

    prefer_chl_arr[4]=ori_pkt[sorted_pkt_id[4]][6:5];
    req_valid_arr[4]=ori_pkt[sorted_pkt_id[4]][15];

    prefer_chl_arr[5]=ori_pkt[sorted_pkt_id[5]][6:5];
    req_valid_arr[5]=ori_pkt[sorted_pkt_id[5]][15];

    prefer_chl_arr[6]=ori_pkt[sorted_pkt_id[6]][6:5];
    req_valid_arr[6]=ori_pkt[sorted_pkt_id[6]][15];

    prefer_chl_arr[7]=ori_pkt[sorted_pkt_id[7]][6:5];
    req_valid_arr[7]=ori_pkt[sorted_pkt_id[7]][15];
end
//===============

//===allocation===
//layer 0(priority最大)
wire [2:0]chl_cap_in_lyr0 [0:2];
wire [2:0]chl_cap_out_lyr0 [0:2];
wire [1:0] next_pivot_lyr0; //output

assign chl_cap_in_lyr0[2]=channel_capacity[8:6];
assign chl_cap_in_lyr0[1]=channel_capacity[5:3];
assign chl_cap_in_lyr0[0]=channel_capacity[2:0];

allocate_pkt P0(
    .prefer_chl(ori_pkt[sorted_pkt_id[0]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[0]][15]), .cur_pivot(2'd3),
    .chl_0_cap(chl_cap_in_lyr0[0]),.chl_1_cap(chl_cap_in_lyr0[1]), 
    .chl_2_cap(chl_cap_in_lyr0[2]),.chl_0_cap_out(chl_cap_out_lyr0[0]), 
    .chl_1_cap_out(chl_cap_out_lyr0[1]),.chl_2_cap_out(chl_cap_out_lyr0[2]), 
    .next_pivot(next_pivot_lyr0), .target_chl(sorted_target_chl[0])
);

//layer1
wire [2:0]chl_cap_out_lyr1 [0:2];//output
wire [1:0] next_pivot_lyr1; //output

allocate_pkt P1(
    .prefer_chl(ori_pkt[sorted_pkt_id[1]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[1]][15]), .cur_pivot(next_pivot_lyr0),
    .chl_0_cap(chl_cap_out_lyr0[0]),.chl_1_cap(chl_cap_out_lyr0[1]), 
    .chl_2_cap(chl_cap_out_lyr0[2]),.chl_0_cap_out(chl_cap_out_lyr1[0]), 
    .chl_1_cap_out(chl_cap_out_lyr1[1]),.chl_2_cap_out(chl_cap_out_lyr1[2]), 
    .next_pivot(next_pivot_lyr1), .target_chl(sorted_target_chl[1])
);

//layer2
wire [2:0]chl_cap_out_lyr2 [0:2];//output
wire [1:0] next_pivot_lyr2; //output

allocate_pkt P2(
    .prefer_chl(ori_pkt[sorted_pkt_id[2]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[2]][15]), .cur_pivot(next_pivot_lyr1),
    .chl_0_cap(chl_cap_out_lyr1[0]),.chl_1_cap(chl_cap_out_lyr1[1]), 
    .chl_2_cap(chl_cap_out_lyr1[2]),.chl_0_cap_out(chl_cap_out_lyr2[0]), 
    .chl_1_cap_out(chl_cap_out_lyr2[1]),.chl_2_cap_out(chl_cap_out_lyr2[2]), 
    .next_pivot(next_pivot_lyr2), .target_chl(sorted_target_chl[2])
);

//layer3
wire [2:0]chl_cap_out_lyr3 [0:2];//output
wire [1:0] next_pivot_lyr3; //output

allocate_pkt P3(
    .prefer_chl(ori_pkt[sorted_pkt_id[3]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[3]][15]), .cur_pivot(next_pivot_lyr2),
    .chl_0_cap(chl_cap_out_lyr2[0]),.chl_1_cap(chl_cap_out_lyr2[1]), 
    .chl_2_cap(chl_cap_out_lyr2[2]),.chl_0_cap_out(chl_cap_out_lyr3[0]), 
    .chl_1_cap_out(chl_cap_out_lyr3[1]),.chl_2_cap_out(chl_cap_out_lyr3[2]), 
    .next_pivot(next_pivot_lyr3), .target_chl(sorted_target_chl[3])
);

//layer4
wire [2:0]chl_cap_out_lyr4 [0:2];//output
wire [1:0] next_pivot_lyr4; //output

allocate_pkt P4(
    .prefer_chl(ori_pkt[sorted_pkt_id[4]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[4]][15]), .cur_pivot(next_pivot_lyr3),
    .chl_0_cap(chl_cap_out_lyr3[0]),.chl_1_cap(chl_cap_out_lyr3[1]), 
    .chl_2_cap(chl_cap_out_lyr3[2]),.chl_0_cap_out(chl_cap_out_lyr4[0]), 
    .chl_1_cap_out(chl_cap_out_lyr4[1]),.chl_2_cap_out(chl_cap_out_lyr4[2]), 
    .next_pivot(next_pivot_lyr4), .target_chl(sorted_target_chl[4])
);

//layer5
wire [2:0]chl_cap_out_lyr5 [0:2];//output
wire [1:0] next_pivot_lyr5; //output

allocate_pkt P5(
    .prefer_chl(ori_pkt[sorted_pkt_id[5]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[5]][15]), .cur_pivot(next_pivot_lyr4),
    .chl_0_cap(chl_cap_out_lyr4[0]),.chl_1_cap(chl_cap_out_lyr4[1]), 
    .chl_2_cap(chl_cap_out_lyr4[2]),.chl_0_cap_out(chl_cap_out_lyr5[0]), 
    .chl_1_cap_out(chl_cap_out_lyr5[1]),.chl_2_cap_out(chl_cap_out_lyr5[2]), 
    .next_pivot(next_pivot_lyr5), .target_chl(sorted_target_chl[5])
);

//layer6
wire [2:0]chl_cap_out_lyr6 [0:2];//output
wire [1:0] next_pivot_lyr6; //output

allocate_pkt P6(
    .prefer_chl(ori_pkt[sorted_pkt_id[6]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[6]][15]), .cur_pivot(next_pivot_lyr5),
    .chl_0_cap(chl_cap_out_lyr5[0]),.chl_1_cap(chl_cap_out_lyr5[1]), 
    .chl_2_cap(chl_cap_out_lyr5[2]),.chl_0_cap_out(chl_cap_out_lyr6[0]), 
    .chl_1_cap_out(chl_cap_out_lyr6[1]),.chl_2_cap_out(chl_cap_out_lyr6[2]), 
    .next_pivot(next_pivot_lyr6), .target_chl(sorted_target_chl[6])
);

//layer7
wire [2:0]chl_cap_out_lyr7 [0:2];//output
wire [1:0] next_pivot_lyr7; //output

allocate_pkt P7(
    .prefer_chl(ori_pkt[sorted_pkt_id[7]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[7]][15]), .cur_pivot(next_pivot_lyr6),
    .chl_0_cap(chl_cap_out_lyr6[0]),.chl_1_cap(chl_cap_out_lyr6[1]), 
    .chl_2_cap(chl_cap_out_lyr6[2]),.chl_0_cap_out(chl_cap_out_lyr7[0]), 
    .chl_1_cap_out(chl_cap_out_lyr7[1]),.chl_2_cap_out(chl_cap_out_lyr7[2]), 
    .next_pivot(next_pivot_lyr7), .target_chl(sorted_target_chl[7])
);

//================

endmodule

module allocate_pkt(
    input [1:0] prefer_chl, input req_valid, input [1:0] cur_pivot,
    input [2:0] chl_0_cap, input [2:0] chl_1_cap, input [2:0] chl_2_cap, 
    output reg[2:0] chl_0_cap_out, output reg[2:0] chl_1_cap_out,output reg[2:0] chl_2_cap_out, 
    output reg [1:0] next_pivot, output reg [1:0] target_chl
);
    wire [2:0] chl_cap [0:2];
    assign chl_cap [0]=chl_0_cap;
    assign chl_cap [1]=chl_1_cap;
    assign chl_cap [2]=chl_2_cap;

    reg [1:0]pivot_0, pivot_1, pivot_2;    //故意讓他overflow
    always@(*)begin
        if(cur_pivot==2'd3)begin    //第一次fall back (pivot_0設成prefer_chl)
            pivot_0=prefer_chl;
            if(prefer_chl==2'd2)pivot_1=2'd0;
            else pivot_1=prefer_chl+2'd1;
            if(prefer_chl==2'd1)pivot_2=2'd0;
            else if(prefer_chl==2'd2)pivot_2=2'd1;
            else pivot_2=2'd2;
        end
        else begin                  //非第一次fall back
            pivot_0=cur_pivot;
            if(cur_pivot==2'd2)pivot_1=2'd0;
            else pivot_1=cur_pivot+2'd1;
            if(cur_pivot==2'd1)pivot_2=2'd0;
            else if(cur_pivot==2'd2)pivot_2=2'd1;
            else pivot_2=2'd2;
        end
    end

    always@(*)begin
        //case 0
        if(req_valid==1'b0)begin    //不用allocate，也不影響Pivot
            chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
            next_pivot=cur_pivot; target_chl=2'd3;
        end
        else begin
        //case 1
            if(chl_cap[prefer_chl]>3'd0)begin
                if(prefer_chl==2'd0)begin
                    target_chl=2'd0; next_pivot=cur_pivot; 
                    chl_0_cap_out=chl_0_cap-3'd1; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                end
                else if(prefer_chl==2'd1)begin
                    target_chl=2'd1; next_pivot=cur_pivot; 
                    chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap-3'd1; chl_2_cap_out=chl_2_cap;
                end
                else begin//prefer_chl==2'd2
                    target_chl=2'd2; next_pivot=cur_pivot; 
                    chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap-3'd1;
                end
            end
        //case 2
            else begin  
                if(chl_cap[pivot_0]>3'd0)begin  //fall back成功 case 2-0
                    if(pivot_0==2'd0)begin
                        target_chl=2'd0; next_pivot=2'd1; 
                        chl_0_cap_out=chl_0_cap-3'd1; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                    else if(pivot_0==2'd1)begin
                        target_chl=2'd1; next_pivot=2'd2; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap-3'd1; chl_2_cap_out=chl_2_cap;
                    end
                    else begin  //pivot_0==2'd2
                        target_chl=2'd2; next_pivot=2'd0; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap-3'd1;
                    end
                end
                else if(chl_cap[pivot_1]>3'd0)begin //fall back成功 case 2-1
                    if(pivot_1==2'd0)begin
                        target_chl=2'd0; next_pivot=2'd0;   //直接完成mod 
                        chl_0_cap_out=chl_0_cap-3'd1; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                    else if(pivot_1==2'd1)begin
                        target_chl=2'd1; next_pivot=2'd1; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap-3'd1; chl_2_cap_out=chl_2_cap;
                    end
                    else begin  //pivot_1==2'd2
                        target_chl=2'd2; next_pivot=2'd2; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap-3'd1;
                    end
                end
                else if(chl_cap[pivot_2]>3'd0)begin //fall back成功 case 2-2
                    if(pivot_2==2'd0)begin
                        target_chl=2'd0; next_pivot=2'd2;   //直接完成mod (只看Pivot_0)
                        chl_0_cap_out=chl_0_cap-3'd1; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                    else if(pivot_2==2'd1)begin
                        target_chl=2'd1; next_pivot=2'd0; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap-3'd1; chl_2_cap_out=chl_2_cap;
                    end
                    else begin  //pivot_2==2'd2
                        target_chl=2'd2; next_pivot=2'd1; 
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap-3'd1;
                    end
                end
                else begin                          //fall back無效 case 2-3
                    if(pivot_0==2'd0)begin
                        target_chl=2'd3; next_pivot=2'd2;   //直接完成mod (只看Pivot_0+2 %3)
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                    else if(pivot_0==2'd1)begin
                        target_chl=2'd3; next_pivot=2'd0;   //直接完成mod (只看Pivot_0+2 %3)
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                    else begin  //pivot_2==2'd2
                        target_chl=2'd3; next_pivot=2'd1;   //直接完成mod (只看Pivot_0+2 %3)
                        chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
                    end
                end
            end
        end
    end
endmodule

module find_ori_pkt(
    input [15:0]K0, input [15:0]K1, input [15:0]K2,input [15:0]K3,
    input [15:0]pkt_1_in, input [15:0]pkt_0_in,
    output [15:0]pkt_1_out, output [15:0]pkt_0_out
);
wire [15:0] y3,x3,y2,x2,y1,x1,y0,x0;
wire [15:0] ROR2_temp [0:3];
wire [15:0] ROL7_temp [0:3];

assign ROR2_temp[3]= pkt_1_in ^ pkt_0_in;
assign y3= {ROR2_temp[3][1:0],ROR2_temp[3][15:2]};  //ROR2
assign ROL7_temp[3]= (pkt_0_in ^ K3) - y3;
assign x3= {ROL7_temp[3][8:0], ROL7_temp[3][15:9]}; //ROL7

assign ROR2_temp[2]= y3 ^ x3;
assign y2= {ROR2_temp[2][1:0],ROR2_temp[2][15:2]};  //ROR2
assign ROL7_temp[2]= (x3 ^ K2) - y2;
assign x2= {ROL7_temp[2][8:0],ROL7_temp[2][15:9]};  //ROL7

assign ROR2_temp[1]= y2 ^ x2;
assign y1= {ROR2_temp[1][1:0],ROR2_temp[1][15:2]};
assign ROL7_temp[1]=(x2 ^ K1) - y1;
assign x1= {ROL7_temp[1][8:0],ROL7_temp[1][15:9]};      //ROL7

assign ROR2_temp[0]=y1 ^ x1;
assign y0= {ROR2_temp[0][1:0],ROR2_temp[0][15:2]};
assign ROL7_temp[0]=(x1 ^ K0) - y0;
assign x0= {ROL7_temp[0][8:0],ROL7_temp[0][15:9]};      //ROL7

assign pkt_1_out=y0; assign pkt_0_out=x0;
endmodule

module find_priority_score(
    input [15:0]ori_pkt ,
    output signed [6:0] priority_score
);
    reg [1:0]qos; reg [3:0]pkt_len; reg [1:0]congestion; reg [2:0]src_hint;
    reg mode;

    always@(*)begin
        qos=ori_pkt[14:13]; pkt_len=ori_pkt[12:9];
        congestion=ori_pkt[8:7]; src_hint=ori_pkt[4:2];
        mode=ori_pkt[1];
    end

    reg [6:0]qos_extd, pkt_len_extd, congestion_extd, src_hint_extd;
    
    //手動sign extend到 7 bit
    always@(*)begin
        //mode 0直接把sign bit0，補到7 bits
        if(mode==0)qos_extd={5'b00000,qos};
        else if(qos[1]==1'b1)qos_extd={5'b11111,qos};
        else qos_extd={5'b00000,qos};

        if(mode==0)pkt_len_extd={3'b000,pkt_len};
        else if(pkt_len[3]==1'b1)pkt_len_extd={3'b111,pkt_len};
        else pkt_len_extd={3'b000,pkt_len};

        if(mode==0)congestion_extd={5'b00000,congestion};
        else if(congestion[1]==1'b1)congestion_extd={5'b11111,congestion};
        else congestion_extd={5'b00000,congestion};

        if(mode==0)src_hint_extd={4'b0000,src_hint};
        else if(src_hint[2]==1'b1)src_hint_extd={4'b1111,src_hint};
        else src_hint_extd={4'b0000,src_hint};
    end

    wire signed [6:0]qos_sign, pkt_len_sign, congestion_sign, src_hint_sign;
    assign qos_sign=$signed(qos_extd);
    assign pkt_len_sign=$signed(pkt_len_extd);
    assign congestion_sign=$signed(congestion_extd);
    assign src_hint_sign=$signed(src_hint_extd);

    assign priority_score=(qos_sign-7'd2)*(7'd4)+(pkt_len_sign-7'd8)*(-7'd2)
        +(7'd1-congestion_sign)*7'd3+(src_hint_sign-7'd4);
endmodule

//merge_sort - 支援 7-bit signed values + 3-bit unsigned tokens (tie-break)
module merge_sort(
    //Inputs: values are 7-bit signed; tokens are 3-bit unsigned
    in0, in1, in2, in3, in4, in5, in6, in7,
    in_char0, in_char1, in_char2, in_char3, in_char4, in_char5, in_char6, in_char7,
    // Outputs
    out0, out1, out2, out3, out4, out5, out6, out7,
    out_char0, out_char1, out_char2, out_char3, out_char4, out_char5, out_char6, out_char7
);
    // INPUT / OUTPUT DECLARATION
    input  signed [6:0] in0, in1, in2, in3, in4, in5, in6, in7; // 7-bit signed
    input  [2:0]       in_char0, in_char1, in_char2, in_char3, in_char4, in_char5, in_char6, in_char7; // 3-bit unsigned tokens

    output signed [6:0] out0, out1, out2, out3, out4, out5, out6, out7;
    output [2:0]        out_char0, out_char1, out_char2, out_char3, out_char4, out_char5, out_char6, out_char7;

    // INTERNAL WIRES (signed for values, unsigned for chars)
    wire signed [6:0] inter1  [7:0];
    wire signed [6:0] inter2  [7:0];
    wire signed [6:0] inter3  [3:0];
    wire signed [6:0] inter4  [7:0];
    wire signed [6:0] inter5  [3:0];
    wire signed [6:0] inter6  [5:0];

    wire [2:0] inter1_char [7:0];
    wire [2:0] inter2_char [7:0];
    wire [2:0] inter3_char [3:0];
    wire [2:0] inter4_char [7:0];
    wire [2:0] inter5_char [3:0];
    wire [2:0] inter6_char [5:0];

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
    assign out0      = inter4[0];
    assign out_char0 = inter4_char[0];
    assign out1      = inter6[0];
    assign out_char1 = inter6_char[0];
    assign out2      = inter6[1];
    assign out_char2 = inter6_char[1];
    assign out3      = inter6[2];
    assign out_char3 = inter6_char[2];
    assign out4      = inter6[3];
    assign out_char4 = inter6_char[3];
    assign out5      = inter6[4];
    assign out_char5 = inter6_char[4];
    assign out6      = inter6[5];
    assign out_char6 = inter6_char[5];
    assign out7      = inter4[7];
    assign out_char7 = inter4_char[7];

endmodule

//comparator-signed compare on values (7-bit signed), unsigned compare on token for tie-break
module comparator(
    input  signed [6:0] a, b,        // 7-bit signed inputs
    input  [2:0]         a_char, b_char, // 3-bit unsigned tokens
    output reg signed [6:0] min_out, max_out,
    output reg [2:0]        min_char, max_char
);
    always @(*) begin
        if (a > b) begin
            // a greater (signed)
            max_out = a; max_char = a_char;
            min_out = b; min_char = b_char;
        end
        else if (a < b) begin
            // b greater (signed)
            max_out = b; max_char = b_char;
            min_out = a; min_char = a_char;
        end
        else begin
            // a == b (signed equal) -> tie-break by token (unsigned)
            // NOTE: 保留原始行為：token 值較小者視為「較大」
            if (a_char < b_char) begin
                max_out = a; max_char = a_char;
                min_out = b; min_char = b_char;
            end
            else begin
                max_out = b; max_char = b_char;
                min_out = a; min_char = a_char;
            end
        end
    end
endmodule