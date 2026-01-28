module MPCA(
    // Input signals
    input [127:0] packets,
    input  [11:0] channel_load,
    input   [8:0] channel_capacity,
    input  [63:0] KEY,
    // Output signals
    output [15:0] grant_channel
);

//Part 2 Comb Logic
wire [15:0] l_2,l_1,l_0,K0;
assign l_2= KEY[63:48];
assign l_1= KEY[47:32];
assign l_0= KEY[31:16];
assign K0= KEY[15:0];

wire [15:0] pkt [0:7];       //pkt0到pkt7
wire [15:0] ori_pkt [0:7];  //pkt0到pkt7

assign pkt[0]=packets[15:0]; assign pkt[1]=packets[31:16];
assign pkt[2]=packets[47:32]; assign pkt[3]=packets[63:48];
assign pkt[4]=packets[79:64]; assign pkt[5]=packets[95:80];
assign pkt[6]=packets[111:96]; assign pkt[7]=packets[127:112];

//chl_load
wire [3:0] chl_load_arr[0:2];
assign chl_load_arr[0]=channel_load[3:0];
assign chl_load_arr[1]=channel_load[7:4];
assign chl_load_arr[2]=channel_load[11:8];
//========

//===decrypt===
reg [15:0]ROR7_temp[0:2];
reg [15:0]K1,K2,K3;
always@(*)begin
    ROR7_temp[0]={K0[6:0],K0[15:7]};
    K1=(ROR7_temp[0]+l_0); //ROR7

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
wire [2:0]chl_cap_out_lyr7 [0:2];//output，會輸入RB!!很重要
wire [1:0] next_pivot_lyr7;      //output

allocate_pkt P7(
    .prefer_chl(ori_pkt[sorted_pkt_id[7]][6:5]), 
    .req_valid(ori_pkt[sorted_pkt_id[7]][15]), .cur_pivot(next_pivot_lyr6),
    .chl_0_cap(chl_cap_out_lyr6[0]),.chl_1_cap(chl_cap_out_lyr6[1]), 
    .chl_2_cap(chl_cap_out_lyr6[2]),.chl_0_cap_out(chl_cap_out_lyr7[0]), 
    .chl_1_cap_out(chl_cap_out_lyr7[1]),.chl_2_cap_out(chl_cap_out_lyr7[2]), 
    .next_pivot(next_pivot_lyr7), .target_chl(sorted_target_chl[7])
);
//================

//mask_valid or not
wire mask_valid[0:7];    //0一樣是priority最高的
//這邊的chl_load是用初始channel
find_mask_valid P0_mask(
    .p_score(sorted_pkt[0]),.prefer_ch(ori_pkt[sorted_pkt_id[0]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[0]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[0]]), .mask_valid(mask_valid[0])
);
find_mask_valid P1_mask(
    .p_score(sorted_pkt[1]),.prefer_ch(ori_pkt[sorted_pkt_id[1]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[1]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[1]]), .mask_valid(mask_valid[1])
);
find_mask_valid P2_mask(
    .p_score(sorted_pkt[2]), .prefer_ch(ori_pkt[sorted_pkt_id[2]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[2]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[2]]), .mask_valid(mask_valid[2])
);
find_mask_valid P3_mask(
    .p_score(sorted_pkt[3]), .prefer_ch(ori_pkt[sorted_pkt_id[3]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[3]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[3]]), .mask_valid(mask_valid[3])
);
find_mask_valid P4_mask(
    .p_score(sorted_pkt[4]), .prefer_ch(ori_pkt[sorted_pkt_id[4]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[4]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[4]]), .mask_valid(mask_valid[4])
);
find_mask_valid P5_mask(
    .p_score(sorted_pkt[5]), .prefer_ch(ori_pkt[sorted_pkt_id[5]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[5]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[5]]), .mask_valid(mask_valid[5])
);
find_mask_valid P6_mask(
    .p_score(sorted_pkt[6]), .prefer_ch(ori_pkt[sorted_pkt_id[6]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[6]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[6]]), .mask_valid(mask_valid[6])
);
find_mask_valid P7_mask(
    .p_score(sorted_pkt[7]), .prefer_ch(ori_pkt[sorted_pkt_id[7]][6:5]),
    .src_hint(ori_pkt[sorted_pkt_id[7]][4:2]),
    .chl_load(chl_load_arr[sorted_target_chl[7]]), .mask_valid(mask_valid[7])
);
//===================

//===find total load===
reg [5:0] total_load [0:2]; //故意多開bit避免overflow
wire [3:0] chl_load_cnt [0:2];

count_value C_ch0(
    .input0(sorted_target_chl[0]),.input1(sorted_target_chl[1]),
    .input2(sorted_target_chl[2]),.input3(sorted_target_chl[3]),
    .input4(sorted_target_chl[4]),.input5(sorted_target_chl[5]),
    .input6(sorted_target_chl[6]),.input7(sorted_target_chl[7]),
    .target_value(2'd0),.count_out(chl_load_cnt[0])
);

count_value C_ch1(
    .input0(sorted_target_chl[0]),.input1(sorted_target_chl[1]),
    .input2(sorted_target_chl[2]),.input3(sorted_target_chl[3]),
    .input4(sorted_target_chl[4]),.input5(sorted_target_chl[5]),
    .input6(sorted_target_chl[6]),.input7(sorted_target_chl[7]),
    .target_value(2'd1),.count_out(chl_load_cnt[1])
);

count_value C_ch2(
    .input0(sorted_target_chl[0]),.input1(sorted_target_chl[1]),
    .input2(sorted_target_chl[2]),.input3(sorted_target_chl[3]),
    .input4(sorted_target_chl[4]),.input5(sorted_target_chl[5]),
    .input6(sorted_target_chl[6]),.input7(sorted_target_chl[7]),
    .target_value(2'd2),.count_out(chl_load_cnt[2])
);

always@(*)begin
    total_load[0]=chl_load_arr[0]+chl_load_cnt[0];
    total_load[1]=chl_load_arr[1]+chl_load_cnt[1];
    total_load[2]=chl_load_arr[2]+chl_load_cnt[2];
end
//=====================

//===rebalance===
//part A:判定是否需要RB (目前確定是要大於)
wire need_RB_bool_0,need_RB_bool_1,need_RB_bool_2;
reg [1:0] chl_to_RB;    //3代表不用RB
reg [1:0] other_chl_A,other_chl_B;  //為了判斷是否需要RB

//gpt寫的，可以再次檢驗
//找到最大的chl
always @(*) begin
    if((total_load[0]>=total_load[1])&&(total_load[0]>=total_load[2])) begin //input0 最大或與他人相等 → 優先選 0
        chl_to_RB=2'd0; other_chl_A=2'd1; other_chl_B=2'd2;
    end
    else if((total_load[1]>=total_load[0])&&(total_load[1]>=total_load[2]))begin //input1 比 input0 大，且 >= input2 → 選 1
        chl_to_RB=2'd1; other_chl_A=2'd0; other_chl_B=2'd2;
    end
    else begin  //否則就是 input2 最大
        chl_to_RB=2'd2; other_chl_A=2'd0; other_chl_B=2'd1;
    end
end

//判斷是否需要RB
add_div2 AD0(
    .in0(total_load[1]), .in1(total_load[2]), 
    .cmp_tar(total_load[0]), .need_RB_bool(need_RB_bool_0)
);
add_div2 AD1(
    .in0(total_load[0]), .in1(total_load[2]), 
    .cmp_tar(total_load[1]), .need_RB_bool(need_RB_bool_1)
);
add_div2 AD2(
    .in0(total_load[0]), .in1(total_load[1]), 
    .cmp_tar(total_load[2]), .need_RB_bool(need_RB_bool_2)
);

reg need_RB_bool;
always@(*)begin
    if(need_RB_bool_0==1'b1&&chl_to_RB==2'd0)need_RB_bool=1'b1;
    else if(need_RB_bool_1==1'b1&&chl_to_RB==2'd1)need_RB_bool=1'b1;
    else if(need_RB_bool_2==1'b1&&chl_to_RB==2'd2)need_RB_bool=1'b1;
    else need_RB_bool=1'b0;
end

//Part B:find victim pkt
reg give_up_RB;
reg [2:0] victim_pkt_idx;   //8代表放棄RB 
//這邊的idx是在sorted_pkt_id[0:7]、sorted_target_chl[0:7]的順序
always @(*) begin
    if(sorted_target_chl[7]==chl_to_RB && mask_valid[7]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd7;
    end
    else if(sorted_target_chl[6]==chl_to_RB && mask_valid[6]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd6;
    end
    else if(sorted_target_chl[5]==chl_to_RB && mask_valid[5]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd5;
    end
    else if(sorted_target_chl[4]==chl_to_RB && mask_valid[4]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd4;
    end
    else if(sorted_target_chl[3]==chl_to_RB && mask_valid[3]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd3;
    end
    else if(sorted_target_chl[2]==chl_to_RB && mask_valid[2]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd2;
    end
    else if(sorted_target_chl[1]==chl_to_RB && mask_valid[1]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd1;
    end
    else if(sorted_target_chl[0]==chl_to_RB && mask_valid[0]==1'b1) begin
        give_up_RB = 1'b0; victim_pkt_idx = 3'd0;
    end
    else begin give_up_RB = 1'b1; victim_pkt_idx = 3'd0; end
end

//Part C:check chl+1 chl+2 & RB
reg [1:0]chl_plus_1,chl_plus_2;

always@(*)begin
    if(chl_to_RB==2'd0)begin chl_plus_1=2'd1; chl_plus_2=2'd2; end
    else if(chl_to_RB==2'd1)begin chl_plus_1=2'd2; chl_plus_2=2'd0;end
    else if(chl_to_RB==2'd2)begin chl_plus_1=2'd0; chl_plus_2=2'd1;end
    else begin chl_plus_1=2'd3; chl_plus_2=2'd3;end
end

reg RB_valid;           //判斷RB成功或失敗
reg [1:0] dst_ch1;      //要被放置的chl
always@(*)begin
    if(chl_cap_out_lyr7[chl_plus_1]>3'd0 && total_load[chl_plus_1]<5'd15)begin
        dst_ch1=chl_plus_1; RB_valid=1'b1;
    end
    else if(chl_cap_out_lyr7[chl_plus_2]>3'd0 && total_load[chl_plus_2]<5'd15)begin
        dst_ch1=chl_plus_2; RB_valid=1'b1;
    end
    else begin dst_ch1=2'd3; RB_valid=1'b0;end
end

//Part D: adjust OUTPUT
reg [1:0]chl_after_RB[0:7]; 
//這邊的順序是在sorted_pkt_id[0:7]、sorted_target_chl[0:7]的順序

always@(*)begin
    //不用RB或是放棄RB
    if(need_RB_bool==0||give_up_RB==1'b1)begin
        chl_after_RB[0]=sorted_target_chl[0]; chl_after_RB[1]=sorted_target_chl[1];
        chl_after_RB[2]=sorted_target_chl[2]; chl_after_RB[3]=sorted_target_chl[3];
        chl_after_RB[4]=sorted_target_chl[4]; chl_after_RB[5]=sorted_target_chl[5];
        chl_after_RB[6]=sorted_target_chl[6]; chl_after_RB[7]=sorted_target_chl[7];
    end
    //RB 失敗，把chl_after_RB[victim_pkt_idx]設成2'd11
    else if(RB_valid==1'b0)begin
        if(victim_pkt_idx==3'd0)chl_after_RB[0]=2'b11;
        else chl_after_RB[0]=sorted_target_chl[0];

        if(victim_pkt_idx==3'd1)chl_after_RB[1]=2'b11;
        else chl_after_RB[1]=sorted_target_chl[1];

        if(victim_pkt_idx==3'd2)chl_after_RB[2]=2'b11;
        else chl_after_RB[2]=sorted_target_chl[2];

        if(victim_pkt_idx==3'd3)chl_after_RB[3]=2'b11;
        else chl_after_RB[3]=sorted_target_chl[3];

        if(victim_pkt_idx==3'd4)chl_after_RB[4]=2'b11;
        else chl_after_RB[4]=sorted_target_chl[4];

        if(victim_pkt_idx==3'd5)chl_after_RB[5]=2'b11;
        else chl_after_RB[5]=sorted_target_chl[5];

        if(victim_pkt_idx==3'd6)chl_after_RB[6]=2'b11;
        else chl_after_RB[6]=sorted_target_chl[6];

        if(victim_pkt_idx==3'd7)chl_after_RB[7]=2'b11;
        else chl_after_RB[7]=sorted_target_chl[7];
    end
    else if(RB_valid==1'b1)begin
        if(victim_pkt_idx==3'd0)chl_after_RB[0]=dst_ch1;
        else chl_after_RB[0]=sorted_target_chl[0];

        if(victim_pkt_idx==3'd1)chl_after_RB[1]=dst_ch1;
        else chl_after_RB[1]=sorted_target_chl[1];

        if(victim_pkt_idx==3'd2)chl_after_RB[2]=dst_ch1;
        else chl_after_RB[2]=sorted_target_chl[2];

        if(victim_pkt_idx==3'd3)chl_after_RB[3]=dst_ch1;
        else chl_after_RB[3]=sorted_target_chl[3];

        if(victim_pkt_idx==3'd4)chl_after_RB[4]=dst_ch1;
        else chl_after_RB[4]=sorted_target_chl[4];

        if(victim_pkt_idx==3'd5)chl_after_RB[5]=dst_ch1;
        else chl_after_RB[5]=sorted_target_chl[5];

        if(victim_pkt_idx==3'd6)chl_after_RB[6]=dst_ch1;
        else chl_after_RB[6]=sorted_target_chl[6];

        if(victim_pkt_idx==3'd7)chl_after_RB[7]=dst_ch1;
        else chl_after_RB[7]=sorted_target_chl[7];
    end    
    else begin
        chl_after_RB[0]=sorted_target_chl[0]; chl_after_RB[1]=sorted_target_chl[1];
        chl_after_RB[2]=sorted_target_chl[2]; chl_after_RB[3]=sorted_target_chl[3];
        chl_after_RB[4]=sorted_target_chl[4]; chl_after_RB[5]=sorted_target_chl[5];
        chl_after_RB[6]=sorted_target_chl[6]; chl_after_RB[7]=sorted_target_chl[7];
    end
end
//===============

//===排序輸出===
reg [1:0] out_pkt [0:7];
always@(*)begin
    if(sorted_pkt_id[0]==3'd7)out_pkt[7]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd7)out_pkt[7]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd7)out_pkt[7]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd7)out_pkt[7]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd7)out_pkt[7]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd7)out_pkt[7]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd7)out_pkt[7]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd7)out_pkt[7]=chl_after_RB[7];
    else out_pkt[7]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd6)out_pkt[6]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd6)out_pkt[6]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd6)out_pkt[6]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd6)out_pkt[6]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd6)out_pkt[6]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd6)out_pkt[6]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd6)out_pkt[6]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd6)out_pkt[6]=chl_after_RB[7];
    else out_pkt[6]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd5)out_pkt[5]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd5)out_pkt[5]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd5)out_pkt[5]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd5)out_pkt[5]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd5)out_pkt[5]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd5)out_pkt[5]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd5)out_pkt[5]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd5)out_pkt[5]=chl_after_RB[7];
    else out_pkt[5]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd4)out_pkt[4]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd4)out_pkt[4]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd4)out_pkt[4]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd4)out_pkt[4]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd4)out_pkt[4]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd4)out_pkt[4]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd4)out_pkt[4]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd4)out_pkt[4]=chl_after_RB[7];
    else out_pkt[4]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd3)out_pkt[3]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd3)out_pkt[3]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd3)out_pkt[3]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd3)out_pkt[3]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd3)out_pkt[3]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd3)out_pkt[3]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd3)out_pkt[3]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd3)out_pkt[3]=chl_after_RB[7];
    else out_pkt[3]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd2)out_pkt[2]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd2)out_pkt[2]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd2)out_pkt[2]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd2)out_pkt[2]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd2)out_pkt[2]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd2)out_pkt[2]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd2)out_pkt[2]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd2)out_pkt[2]=chl_after_RB[7];
    else out_pkt[2]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd1)out_pkt[1]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd1)out_pkt[1]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd1)out_pkt[1]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd1)out_pkt[1]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd1)out_pkt[1]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd1)out_pkt[1]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd1)out_pkt[1]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd1)out_pkt[1]=chl_after_RB[7];
    else out_pkt[1]=chl_after_RB[0];
end

always@(*)begin
    if(sorted_pkt_id[0]==3'd0)out_pkt[0]=chl_after_RB[0];
    else if(sorted_pkt_id[1]==3'd0)out_pkt[0]=chl_after_RB[1];
    else if(sorted_pkt_id[2]==3'd0)out_pkt[0]=chl_after_RB[2];
    else if(sorted_pkt_id[3]==3'd0)out_pkt[0]=chl_after_RB[3];
    else if(sorted_pkt_id[4]==3'd0)out_pkt[0]=chl_after_RB[4];
    else if(sorted_pkt_id[5]==3'd0)out_pkt[0]=chl_after_RB[5];
    else if(sorted_pkt_id[6]==3'd0)out_pkt[0]=chl_after_RB[6];
    else if(sorted_pkt_id[7]==3'd0)out_pkt[0]=chl_after_RB[7];
    else out_pkt[0]=chl_after_RB[0];
end

assign grant_channel={out_pkt[7],out_pkt[6],out_pkt[5],out_pkt[4],
    out_pkt[3],out_pkt[2],out_pkt[1],out_pkt[0]};
//=============
endmodule

module find_mask_valid(
    input signed [6:0]p_score,input [1:0]prefer_ch,input [2:0]src_hint,
    input [3:0] chl_load, output reg mask_valid
);
    wire [6:0] mask_score_temp;
    assign mask_score_temp=(p_score & 7'd6)+prefer_ch+(src_hint^3'd3)+chl_load;
    wire [3:0] devided_load;
    div3_case div3 (.in_val(chl_load), .out_val(devided_load));

    wire [3:0] mask_score;
    mod10_7bit mod0 (.in(mask_score_temp) ,.out(mask_score));
    
    always@(*)begin
        if(mask_score>=6'd7+devided_load)mask_valid=1'b0;
        else mask_valid=1'b1;
    end
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

    reg [1:0]pivot_0, pivot_1, pivot_2; 

    always@(*)begin
        if(cur_pivot==2'd3)pivot_0=prefer_chl;  //第一次fall back
        else pivot_0=cur_pivot;                 //非第一次fall back
    end

    always@(*)begin
        if(cur_pivot==2'd3)begin                //第一次fall back
            case(prefer_chl)
                2'd0:pivot_1=2'd1;
                2'd1:pivot_1=2'd2;
                2'd2:pivot_1=2'd0;
                default:pivot_1=2'd0;
            endcase
        end
        else begin                              //非第一次fall back
            case(cur_pivot)
                2'd0:pivot_1=2'd1;
                2'd1:pivot_1=2'd2;
                2'd2:pivot_1=2'd0;
                default:pivot_1=2'd0;
            endcase
        end
    end

    always@(*)begin
        if(cur_pivot==2'd3)begin                //第一次fall back
            case(prefer_chl)
                2'd0:pivot_2=2'd2;
                2'd1:pivot_2=2'd0;
                2'd2:pivot_2=2'd1;
                default:pivot_2=2'd0;
            endcase
        end
        else begin                              //非第一次fall back
            case(cur_pivot)
                2'd0:pivot_2=2'd2;
                2'd1:pivot_2=2'd0;
                2'd2:pivot_2=2'd1;
                default:pivot_2=2'd0;
            endcase
        end
    end

    always@(*)begin
        //case 0
        if(req_valid==1'b0)begin    //不用allocate，也不影響Pivot
            chl_0_cap_out=chl_0_cap; chl_1_cap_out=chl_1_cap; chl_2_cap_out=chl_2_cap;
            next_pivot=cur_pivot; target_chl=2'd3;
        end
        //case 1
        else if(chl_cap[prefer_chl]>3'd0)begin
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
        else if(chl_cap[pivot_0]>3'd0)begin  //fall back成功 case 2-0
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

module comparator(
    input  signed [6:0] a, b,           //7-bit signed inputs
    input  [2:0]        a_char, b_char, //5-bit unsigned tokens
    output signed [6:0] min_out, max_out,
    output [2:0]        min_char, max_char
);

    // 比较信号
    wire a_gt_b = (a > b);
    wire a_lt_b = (a < b);
    wire a_eq_b = ~a_gt_b & ~a_lt_b;

    // a == b 时，用 token 决定
    wire [6:0] max_val_eq, min_val_eq;
    wire [2:0] max_char_eq, min_char_eq;
    assign {max_val_eq, max_char_eq, min_val_eq, min_char_eq} =
        (a_char < b_char) ? {a, a_char, b, b_char} : {b, b_char, a, a_char};

    // 并行计算其他情况
    wire [6:0] max_val_a_gt_b = a;
    wire [6:0] min_val_a_gt_b = b;
    wire [6:0] max_val_b_gt_a = b;
    wire [6:0] min_val_b_gt_a = a;

    // 输出选择 mux
    assign max_out = a_gt_b ? max_val_a_gt_b :
                     a_lt_b ? max_val_b_gt_a :
                              max_val_eq;

    assign min_out = a_gt_b ? min_val_a_gt_b :
                     a_lt_b ? min_val_b_gt_a :
                              min_val_eq;

    assign max_char = a_gt_b ? a_char :
                      a_lt_b ? b_char :
                               max_char_eq;

    assign min_char = a_gt_b ? b_char :
                      a_lt_b ? a_char :
                               min_char_eq;
endmodule

//gpt說OK
module div3_case( input  [3:0] in_val, output reg [3:0] out_val  );
always @(*) begin
    case (in_val)
        4'd0 : out_val = 4'd0;
        4'd1 : out_val = 4'd0;
        4'd2 : out_val = 4'd0;
        4'd3 : out_val = 4'd1;
        4'd4 : out_val = 4'd1;
        4'd5 : out_val = 4'd1;
        4'd6 : out_val = 4'd2;
        4'd7 : out_val = 4'd2;
        4'd8 : out_val = 4'd2;
        4'd9 : out_val = 4'd3;
        4'd10: out_val = 4'd3;
        4'd11: out_val = 4'd3;
        4'd12: out_val = 4'd4;
        4'd13: out_val = 4'd4;
        4'd14: out_val = 4'd4;
        4'd15: out_val = 4'd5;
        default: out_val = 4'd0;
    endcase
end
endmodule

//gpt檢查過OK
module mod10_7bit(input [6:0] in, output reg [3:0] out);
always @(*) begin
    case(in)
        7'd0:  out = 4'd0;
        7'd1:  out = 4'd1;
        7'd2:  out = 4'd2;
        7'd3:  out = 4'd3;
        7'd4:  out = 4'd4;
        7'd5:  out = 4'd5;
        7'd6:  out = 4'd6;
        7'd7:  out = 4'd7;
        7'd8:  out = 4'd8;
        7'd9:  out = 4'd9;
        7'd10: out = 4'd0;

        7'd11: out = 4'd1;
        7'd12: out = 4'd2;
        7'd13: out = 4'd3;
        7'd14: out = 4'd4;
        7'd15: out = 4'd5;
        7'd16: out = 4'd6;
        7'd17: out = 4'd7;
        7'd18: out = 4'd8;
        7'd19: out = 4'd9;
        7'd20: out = 4'd0;

        7'd21: out = 4'd1;
        7'd22: out = 4'd2;
        7'd23: out = 4'd3;
        7'd24: out = 4'd4;
        7'd25: out = 4'd5;
        7'd26: out = 4'd6;
        7'd27: out = 4'd7;
        7'd28: out = 4'd8;
        7'd29: out = 4'd9;
        7'd30: out = 4'd0;

        7'd31: out = 4'd1;
        7'd32: out = 4'd2;
        7'd33: out = 4'd3;
        7'd34: out = 4'd4;
        7'd35: out = 4'd5;
        7'd36: out = 4'd6;
        7'd37: out = 4'd7;
        7'd38: out = 4'd8;
        7'd39: out = 4'd9;
        7'd40: out = 4'd0;

        7'd41: out = 4'd1;
        7'd42: out = 4'd2;
        7'd43: out = 4'd3;
        7'd44: out = 4'd4;
        7'd45: out = 4'd5;
        7'd46: out = 4'd6;
        7'd47: out = 4'd7;
        7'd48: out = 4'd8;
        7'd49: out = 4'd9;
        7'd50: out = 4'd0;

        7'd51: out = 4'd1;
        7'd52: out = 4'd2;
        7'd53: out = 4'd3;
        7'd54: out = 4'd4;
        7'd55: out = 4'd5;
        7'd56: out = 4'd6;
        7'd57: out = 4'd7;
        7'd58: out = 4'd8;
        7'd59: out = 4'd9;
        7'd60: out = 4'd0;

        7'd61: out = 4'd1;
        7'd62: out = 4'd2;
        7'd63: out = 4'd3;
        7'd64: out = 4'd4;
        7'd65: out = 4'd5;
        7'd66: out = 4'd6;
        7'd67: out = 4'd7;
        7'd68: out = 4'd8;
        7'd69: out = 4'd9;
        7'd70: out = 4'd0;

        7'd71: out = 4'd1;
        7'd72: out = 4'd2;
        7'd73: out = 4'd3;
        7'd74: out = 4'd4;
        7'd75: out = 4'd5;
        7'd76: out = 4'd6;
        7'd77: out = 4'd7;
        7'd78: out = 4'd8;
        7'd79: out = 4'd9;
        7'd80: out = 4'd0;

        7'd81: out = 4'd1;
        7'd82: out = 4'd2;
        7'd83: out = 4'd3;
        7'd84: out = 4'd4;
        7'd85: out = 4'd5;
        7'd86: out = 4'd6;
        7'd87: out = 4'd7;
        7'd88: out = 4'd8;
        7'd89: out = 4'd9;
        7'd90: out = 4'd0;

        7'd91: out = 4'd1;
        7'd92: out = 4'd2;
        7'd93: out = 4'd3;
        7'd94: out = 4'd4;
        7'd95: out = 4'd5;
        7'd96: out = 4'd6;
        7'd97: out = 4'd7;
        7'd98: out = 4'd8;
        7'd99: out = 4'd9;
        7'd100: out = 4'd0;

        7'd101: out = 4'd1;
        7'd102: out = 4'd2;
        7'd103: out = 4'd3;
        7'd104: out = 4'd4;
        7'd105: out = 4'd5;
        7'd106: out = 4'd6;
        7'd107: out = 4'd7;
        7'd108: out = 4'd8;
        7'd109: out = 4'd9;
        7'd110: out = 4'd0;

        7'd111: out = 4'd1;
        7'd112: out = 4'd2;
        7'd113: out = 4'd3;
        7'd114: out = 4'd4;
        7'd115: out = 4'd5;
        7'd116: out = 4'd6;
        7'd117: out = 4'd7;
        7'd118: out = 4'd8;
        7'd119: out = 4'd9;
        7'd120: out = 4'd0;

        7'd121: out = 4'd1;
        7'd122: out = 4'd2;
        7'd123: out = 4'd3;
        7'd124: out = 4'd4;
        7'd125: out = 4'd5;
        7'd126: out = 4'd6;
        7'd127: out = 4'd7;
        default: out = 4'd0;
    endcase
end
endmodule


module count_value (
    input [1:0] input0,input [1:0] input1,input [1:0] input2,input [1:0]input3,
    input [1:0] input4,input [1:0] input5,input [1:0] input6,input [1:0]input7,
    input [1:0] target_value,
    output wire [3:0] count_out
);
    wire match0 = (input0 == target_value);
    wire match1 = (input1 == target_value);
    wire match2 = (input2 == target_value);
    wire match3 = (input3 == target_value);
    wire match4 = (input4 == target_value);
    wire match5 = (input5 == target_value);
    wire match6 = (input6 == target_value);
    wire match7 = (input7 == target_value);
    assign count_out = match0 + match1 + match2 + match3 + match4 + match5 + match6 + match7;
endmodule

module add_div2 (
    input[5:0] in0,input[5:0] in1, input[5:0] cmp_tar,
    output reg need_RB_bool
);
    reg [6:0] sum; reg [5:0] out;
    always @(*) begin
        sum = in0 + in1;
        case (sum)  //助教說要無條件捨去
            7'd0  : out = 6'd0;
            7'd1  : out = 6'd0;
            7'd2  : out = 6'd1;
            7'd3  : out = 6'd1;
            7'd4  : out = 6'd2;
            7'd5  : out = 6'd2;
            7'd6  : out = 6'd3;
            7'd7  : out = 6'd3;
            7'd8  : out = 6'd4;
            7'd9  : out = 6'd4;
            7'd10 : out = 6'd5;
            7'd11 : out = 6'd5;
            7'd12 : out = 6'd6;
            7'd13 : out = 6'd6;
            7'd14 : out = 6'd7;
            7'd15 : out = 6'd7;
            7'd16 : out = 6'd8;
            7'd17 : out = 6'd8;
            7'd18 : out = 6'd9;
            7'd19 : out = 6'd9;
            7'd20 : out = 6'd10;
            7'd21 : out = 6'd10;
            7'd22 : out = 6'd11;
            7'd23 : out = 6'd11;
            7'd24 : out = 6'd12;
            7'd25 : out = 6'd12;
            7'd26 : out = 6'd13;
            7'd27 : out = 6'd13;
            7'd28 : out = 6'd14;
            7'd29 : out = 6'd14;
            7'd30 : out = 6'd15;
            7'd31 : out = 6'd15;
            7'd32 : out = 6'd16;
            7'd33 : out = 6'd16;
            7'd34 : out = 6'd17;
            7'd35 : out = 6'd17;
            7'd36 : out = 6'd18;
            7'd37 : out = 6'd18;
            7'd38 : out = 6'd19;
            7'd39 : out = 6'd19;
            7'd40 : out = 6'd20;
            7'd41 : out = 6'd20;
            7'd42 : out = 6'd21;
            7'd43 : out = 6'd21;
            7'd44 : out = 6'd22;
            7'd45 : out = 6'd22;
            7'd46 : out = 6'd23;
            7'd47 : out = 6'd23;
            7'd48 : out = 6'd24;
            7'd49 : out = 6'd24;
            7'd50 : out = 6'd25;
            7'd51 : out = 6'd25;
            7'd52 : out = 6'd26;
            7'd53 : out = 6'd26;
            7'd54 : out = 6'd27;
            7'd55 : out = 6'd27;
            7'd56 : out = 6'd28;
            7'd57 : out = 6'd28;
            7'd58 : out = 6'd29;
            7'd59 : out = 6'd29;
            7'd60 : out = 6'd30;
            7'd61 : out = 6'd30;
            7'd62 : out = 6'd31;
            7'd63 : out = 6'd31;
            7'd64 : out = 6'd32;
            default: out = 6'd0; // 保險用
        endcase
    end
    //目前確定是大於才要RB
    always@(*)begin
        if(cmp_tar>out)need_RB_bool=1'b1;
        else need_RB_bool=1'b0;
    end
endmodule