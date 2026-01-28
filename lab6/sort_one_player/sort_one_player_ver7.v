module sort_one_player(
    in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7,
    in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7,
    out_num_1, out_num_2, out_num_3, out_num_4, out_num_5, chosen_type //1-11
);

input [3:0] in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7;
input [1:0] in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7;
output reg [3:0] out_num_1, out_num_2, out_num_3, out_num_4, out_num_5;
output reg [3:0] chosen_type;

reg exist_map[0:3][0:12];   //[花色][對應數字 2-14]
reg [2:0] num_cnt [0:12];   //2-14不分花色出現過的次數
reg [2:0] suit_cnt [0:3];   //四種suit出現的次數

integer i,j;
always@(*)begin
    for(i=0;i<13;i=i+1)begin
        for(j=0;j<4;j=j+1)begin
            if     (in_num_1==i+2 && j==in_suit_1)exist_map[j][i]=1'b1;
            else if(in_num_2==i+2 && j==in_suit_2)exist_map[j][i]=1'b1;
            else if(in_num_3==i+2 && j==in_suit_3)exist_map[j][i]=1'b1;
            else if(in_num_4==i+2 && j==in_suit_4)exist_map[j][i]=1'b1;
            else if(in_num_5==i+2 && j==in_suit_5)exist_map[j][i]=1'b1;
            else if(in_num_6==i+2 && j==in_suit_6)exist_map[j][i]=1'b1;
            else if(in_num_7==i+2 && j==in_suit_7)exist_map[j][i]=1'b1;
            else exist_map[j][i]=1'b0;
        end
    end
end

always@(*)begin
    for(i=0;i<13;i=i+1)begin
        num_cnt[i]=exist_map[0][i]+exist_map[1][i]+exist_map[2][i]+exist_map[3][i];
    end
end

always@(*)begin
    for(i=0;i<4;i=i+1)begin
        suit_cnt[i]=exist_map[i][0]+exist_map[i][1]+exist_map[i][2]+exist_map[i][3]
            +exist_map[i][4]+exist_map[i][5]+exist_map[i][6]+exist_map[i][7]
            +exist_map[i][8]+exist_map[i][9]+exist_map[i][10]+exist_map[i][11]
            +exist_map[i][12];
    end
end

//===4 kinds===
reg [3:0] four_kind_num [0:4];
reg [3:0] four_kind_step1_used_row; //標記step 1後每個row是否用過
reg four_kind_exist_bool;
//必須要four_kind_exist_bool==1且four_kind_step1_used_row!=15才算

//step 1
always@(*)begin
    if(num_cnt[12]>=3'd4) begin
    four_kind_num[0]=4'd14; four_kind_num[1]=4'd14; four_kind_num[2]=4'd14; four_kind_num[3]=4'd14; four_kind_step1_used_row=12;
    end
    else if(num_cnt[11]>=3'd4) begin
        four_kind_num[0]=4'd13; four_kind_num[1]=4'd13; four_kind_num[2]=4'd13; four_kind_num[3]=4'd13; four_kind_step1_used_row=11;
    end
    else if(num_cnt[10]>=3'd4) begin
        four_kind_num[0]=4'd12; four_kind_num[1]=4'd12; four_kind_num[2]=4'd12; four_kind_num[3]=4'd12; four_kind_step1_used_row=10;
    end
    else if(num_cnt[9]>=3'd4) begin
        four_kind_num[0]=4'd11; four_kind_num[1]=4'd11; four_kind_num[2]=4'd11; four_kind_num[3]=4'd11; four_kind_step1_used_row=9;
    end
    else if(num_cnt[8]>=3'd4) begin
        four_kind_num[0]=4'd10; four_kind_num[1]=4'd10; four_kind_num[2]=4'd10; four_kind_num[3]=4'd10; four_kind_step1_used_row=8;
    end
    else if(num_cnt[7]>=3'd4) begin
        four_kind_num[0]=4'd9; four_kind_num[1]=4'd9; four_kind_num[2]=4'd9; four_kind_num[3]=4'd9; four_kind_step1_used_row=7;
    end
    else if(num_cnt[6]>=3'd4) begin
        four_kind_num[0]=4'd8; four_kind_num[1]=4'd8; four_kind_num[2]=4'd8; four_kind_num[3]=4'd8; four_kind_step1_used_row=6;
    end
    else if(num_cnt[5]>=3'd4) begin
        four_kind_num[0]=4'd7; four_kind_num[1]=4'd7; four_kind_num[2]=4'd7; four_kind_num[3]=4'd7; four_kind_step1_used_row=5;
    end
    else if(num_cnt[4]>=3'd4) begin
        four_kind_num[0]=4'd6; four_kind_num[1]=4'd6; four_kind_num[2]=4'd6; four_kind_num[3]=4'd6; four_kind_step1_used_row=4;
    end
    else if(num_cnt[3]>=3'd4) begin
        four_kind_num[0]=4'd5; four_kind_num[1]=4'd5; four_kind_num[2]=4'd5; four_kind_num[3]=4'd5; four_kind_step1_used_row=3;
    end
    else if(num_cnt[2]>=3'd4) begin
        four_kind_num[0]=4'd4; four_kind_num[1]=4'd4; four_kind_num[2]=4'd4; four_kind_num[3]=4'd4; four_kind_step1_used_row=2;
    end
    else if(num_cnt[1]>=3'd4) begin
        four_kind_num[0]=4'd3; four_kind_num[1]=4'd3; four_kind_num[2]=4'd3; four_kind_num[3]=4'd3; four_kind_step1_used_row=1;
    end
    else if(num_cnt[0]>=3'd4) begin
        four_kind_num[0]=4'd2; four_kind_num[1]=4'd2; four_kind_num[2]=4'd2; four_kind_num[3]=4'd2; four_kind_step1_used_row=0;
    end
    else begin  //NULL
        four_kind_num[0]=4'd15; four_kind_num[1]=4'd15; four_kind_num[2]=4'd15; four_kind_num[3]=4'd15; four_kind_step1_used_row=15;
    end
end

//step 2
always@(*)begin
    if(num_cnt[12]>=3'd1 && four_kind_step1_used_row!=12) begin
        four_kind_num[4]=4'd14; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[11]>=3'd1 && four_kind_step1_used_row!=11) begin
        four_kind_num[4]=4'd13; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[10]>=3'd1 && four_kind_step1_used_row!=10) begin
        four_kind_num[4]=4'd12; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[9]>=3'd1 && four_kind_step1_used_row!=9) begin
        four_kind_num[4]=4'd11; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[8]>=3'd1 && four_kind_step1_used_row!=8) begin
        four_kind_num[4]=4'd10; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[7]>=3'd1 && four_kind_step1_used_row!=7) begin
        four_kind_num[4]=4'd9; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[6]>=3'd1 && four_kind_step1_used_row!=6) begin
        four_kind_num[4]=4'd8; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[5]>=3'd1 && four_kind_step1_used_row!=5) begin
        four_kind_num[4]=4'd7; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[4]>=3'd1 && four_kind_step1_used_row!=4) begin
        four_kind_num[4]=4'd6; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[3]>=3'd1 && four_kind_step1_used_row!=3) begin
        four_kind_num[4]=4'd5; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[2]>=3'd1 && four_kind_step1_used_row!=2) begin
        four_kind_num[4]=4'd4; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[1]>=3'd1 && four_kind_step1_used_row!=1) begin
        four_kind_num[4]=4'd3; four_kind_exist_bool=1'b1;
    end
    else if(num_cnt[0]>=3'd1 && four_kind_step1_used_row!=0) begin
        four_kind_num[4]=4'd2; four_kind_exist_bool=1'b1;
    end
    else begin
        four_kind_num[4]=4'd15; four_kind_exist_bool=1'b0;
    end
end
//=============

//===3 kind===
reg [3:0] three_kind_num [0:4];
reg [3:0] three_kind_step1_used_row, three_kind_step2_used_row;
//標記step 1、step 2、step 3後每個row是否用過
//必須要three_kind_exist_bool==1且three_kind_step1_used_row!=15、three_kind_step2_used_row!=15才算
reg three_kind_exist_bool;

//step 1 選3個
always@(*)begin
    if(num_cnt[12]>=3'd3) begin
        three_kind_num[0]=4'd14; three_kind_num[1]=4'd14; three_kind_num[2]=4'd14; three_kind_step1_used_row=12;
    end
    else if(num_cnt[11]>=3'd3) begin
        three_kind_num[0]=4'd13; three_kind_num[1]=4'd13; three_kind_num[2]=4'd13; three_kind_step1_used_row=11;
    end
    else if(num_cnt[10]>=3'd3) begin
        three_kind_num[0]=4'd12; three_kind_num[1]=4'd12; three_kind_num[2]=4'd12; three_kind_step1_used_row=10;
    end
    else if(num_cnt[9]>=3'd3) begin
        three_kind_num[0]=4'd11; three_kind_num[1]=4'd11; three_kind_num[2]=4'd11; three_kind_step1_used_row=9;
    end
    else if(num_cnt[8]>=3'd3) begin
        three_kind_num[0]=4'd10; three_kind_num[1]=4'd10; three_kind_num[2]=4'd10; three_kind_step1_used_row=8;
    end
    else if(num_cnt[7]>=3'd3) begin
        three_kind_num[0]=4'd9; three_kind_num[1]=4'd9; three_kind_num[2]=4'd9; three_kind_step1_used_row=7;
    end
    else if(num_cnt[6]>=3'd3) begin
        three_kind_num[0]=4'd8; three_kind_num[1]=4'd8; three_kind_num[2]=4'd8; three_kind_step1_used_row=6;
    end
    else if(num_cnt[5]>=3'd3) begin
        three_kind_num[0]=4'd7; three_kind_num[1]=4'd7; three_kind_num[2]=4'd7; three_kind_step1_used_row=5;
    end
    else if(num_cnt[4]>=3'd3) begin
        three_kind_num[0]=4'd6; three_kind_num[1]=4'd6; three_kind_num[2]=4'd6; three_kind_step1_used_row=4;
    end
    else if(num_cnt[3]>=3'd3) begin
        three_kind_num[0]=4'd5; three_kind_num[1]=4'd5; three_kind_num[2]=4'd5; three_kind_step1_used_row=3;
    end
    else if(num_cnt[2]>=3'd3) begin
        three_kind_num[0]=4'd4; three_kind_num[1]=4'd4; three_kind_num[2]=4'd4; three_kind_step1_used_row=2;
    end
    else if(num_cnt[1]>=3'd3) begin
        three_kind_num[0]=4'd3; three_kind_num[1]=4'd3; three_kind_num[2]=4'd3; three_kind_step1_used_row=1;
    end
    else if(num_cnt[0]>=3'd3) begin
        three_kind_num[0]=4'd2; three_kind_num[1]=4'd2; three_kind_num[2]=4'd2; three_kind_step1_used_row=0;
    end
    else begin  //NULL
        three_kind_num[0]=4'd15; three_kind_num[1]=4'd15; three_kind_num[2]=4'd15; three_kind_step1_used_row=15;
    end
end

//step 2 選一個
always@(*)begin
    if(num_cnt[12]>=3'd1 && three_kind_step1_used_row!=12) begin
        three_kind_num[3]=4'd14; three_kind_step2_used_row=12;
    end
    else if(num_cnt[11]>=3'd1 && three_kind_step1_used_row!=11) begin
        three_kind_num[3]=4'd13; three_kind_step2_used_row=11;
    end
    else if(num_cnt[10]>=3'd1 && three_kind_step1_used_row!=10) begin
        three_kind_num[3]=4'd12; three_kind_step2_used_row=10;
    end
    else if(num_cnt[9]>=3'd1 && three_kind_step1_used_row!=9) begin
        three_kind_num[3]=4'd11; three_kind_step2_used_row=9;
    end
    else if(num_cnt[8]>=3'd1 && three_kind_step1_used_row!=8) begin
        three_kind_num[3]=4'd10; three_kind_step2_used_row=8;
    end
    else if(num_cnt[7]>=3'd1 && three_kind_step1_used_row!=7) begin
        three_kind_num[3]=4'd9; three_kind_step2_used_row=7;
    end
    else if(num_cnt[6]>=3'd1 && three_kind_step1_used_row!=6) begin
        three_kind_num[3]=4'd8; three_kind_step2_used_row=6;
    end
    else if(num_cnt[5]>=3'd1 && three_kind_step1_used_row!=5) begin
        three_kind_num[3]=4'd7; three_kind_step2_used_row=5;
    end
    else if(num_cnt[4]>=3'd1 && three_kind_step1_used_row!=4) begin
        three_kind_num[3]=4'd6; three_kind_step2_used_row=4;
    end
    else if(num_cnt[3]>=3'd1 && three_kind_step1_used_row!=3) begin
        three_kind_num[3]=4'd5; three_kind_step2_used_row=3;
    end
    else if(num_cnt[2]>=3'd1 && three_kind_step1_used_row!=2) begin
        three_kind_num[3]=4'd4; three_kind_step2_used_row=2;
    end
    else if(num_cnt[1]>=3'd1 && three_kind_step1_used_row!=1) begin
        three_kind_num[3]=4'd3; three_kind_step2_used_row=1;
    end
    else if(num_cnt[0]>=3'd1 && three_kind_step1_used_row!=0) begin
        three_kind_num[3]=4'd2; three_kind_step2_used_row=0;
    end
    else begin  //NULL
        three_kind_num[3]=4'd15; three_kind_step2_used_row=15;
    end
end

//step 3 選一個
always@(*)begin
    if(num_cnt[12]>=3'd1 && three_kind_step1_used_row!=12 && three_kind_step2_used_row!=12) begin
        three_kind_num[4]=4'd14; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[11]>=3'd1 && three_kind_step1_used_row!=11 && three_kind_step2_used_row!=11) begin
        three_kind_num[4]=4'd13; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[10]>=3'd1 && three_kind_step1_used_row!=10 && three_kind_step2_used_row!=10) begin
        three_kind_num[4]=4'd12; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[9]>=3'd1 && three_kind_step1_used_row!=9 && three_kind_step2_used_row!=9) begin
        three_kind_num[4]=4'd11; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[8]>=3'd1 && three_kind_step1_used_row!=8 && three_kind_step2_used_row!=8) begin
        three_kind_num[4]=4'd10; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[7]>=3'd1 && three_kind_step1_used_row!=7 && three_kind_step2_used_row!=7) begin
        three_kind_num[4]=4'd9; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[6]>=3'd1 && three_kind_step1_used_row!=6 && three_kind_step2_used_row!=6) begin
        three_kind_num[4]=4'd8; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[5]>=3'd1 && three_kind_step1_used_row!=5 && three_kind_step2_used_row!=5) begin
        three_kind_num[4]=4'd7; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[4]>=3'd1 && three_kind_step1_used_row!=4 && three_kind_step2_used_row!=4) begin
        three_kind_num[4]=4'd6; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[3]>=3'd1 && three_kind_step1_used_row!=3 && three_kind_step2_used_row!=3) begin
        three_kind_num[4]=4'd5; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[2]>=3'd1 && three_kind_step1_used_row!=2 && three_kind_step2_used_row!=2) begin
        three_kind_num[4]=4'd4; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[1]>=3'd1 && three_kind_step1_used_row!=1 && three_kind_step2_used_row!=1) begin
        three_kind_num[4]=4'd3; three_kind_exist_bool=1'b1;
    end
    else if(num_cnt[0]>=3'd1 && three_kind_step1_used_row!=0 && three_kind_step2_used_row!=0) begin
        three_kind_num[4]=4'd2; three_kind_exist_bool=1'b1;
    end
    else begin
        three_kind_num[4]=4'd15; three_kind_exist_bool=1'b0;
    end
end
//============

//===full house===
reg [3:0] full_hs_num [0:4];
reg [3:0] full_hs_step1_used_row; //標記step 1後每個row是否用過
reg full_hs_exist_bool;

//step 1 先挑3個相同的數字
always@(*)begin
    if(num_cnt[12]>=3'd3)begin
        full_hs_num[0]=4'd14; full_hs_num[1]=4'd14; full_hs_num[2]=4'd14; full_hs_step1_used_row=4'd12;
    end
    else if(num_cnt[11]>=3'd3)begin
        full_hs_num[0]=4'd13; full_hs_num[1]=4'd13; full_hs_num[2]=4'd13; full_hs_step1_used_row=4'd11;
    end
    else if(num_cnt[10]>=3'd3)begin
        full_hs_num[0]=4'd12; full_hs_num[1]=4'd12; full_hs_num[2]=4'd12; full_hs_step1_used_row=4'd10;
    end
    else if(num_cnt[9]>=3'd3)begin
        full_hs_num[0]=4'd11; full_hs_num[1]=4'd11; full_hs_num[2]=4'd11; full_hs_step1_used_row=4'd9;
    end
    else if(num_cnt[8]>=3'd3)begin
        full_hs_num[0]=4'd10; full_hs_num[1]=4'd10; full_hs_num[2]=4'd10; full_hs_step1_used_row=4'd8;
    end
    else if(num_cnt[7]>=3'd3)begin
        full_hs_num[0]=4'd9; full_hs_num[1]=4'd9; full_hs_num[2]=4'd9; full_hs_step1_used_row=4'd7;
    end
    else if(num_cnt[6]>=3'd3)begin
        full_hs_num[0]=4'd8; full_hs_num[1]=4'd8; full_hs_num[2]=4'd8; full_hs_step1_used_row=4'd6;
    end
    else if(num_cnt[5]>=3'd3)begin
        full_hs_num[0]=4'd7; full_hs_num[1]=4'd7; full_hs_num[2]=4'd7; full_hs_step1_used_row=4'd5;
    end
    else if(num_cnt[4]>=3'd3)begin
        full_hs_num[0]=4'd6; full_hs_num[1]=4'd6; full_hs_num[2]=4'd6; full_hs_step1_used_row=4'd4;
    end
    else if(num_cnt[3]>=3'd3)begin
        full_hs_num[0]=4'd5; full_hs_num[1]=4'd5; full_hs_num[2]=4'd5; full_hs_step1_used_row=4'd3;
    end
    else if(num_cnt[2]>=3'd3)begin
        full_hs_num[0]=4'd4; full_hs_num[1]=4'd4; full_hs_num[2]=4'd4; full_hs_step1_used_row=4'd2;
    end
    else if(num_cnt[1]>=3'd3)begin
        full_hs_num[0]=4'd3; full_hs_num[1]=4'd3; full_hs_num[2]=4'd3; full_hs_step1_used_row=4'd1;
    end
    else if(num_cnt[0]>=3'd3)begin
        full_hs_num[0]=4'd2; full_hs_num[1]=4'd2; full_hs_num[2]=4'd2; full_hs_step1_used_row=4'd0;
    end
    else begin
        full_hs_num[0]=4'd15; full_hs_num[1]=4'd15; full_hs_num[2]=4'd15; full_hs_step1_used_row=4'd15;
    end
end

//step 1 先挑3個相同的數字
always@(*)begin
    if(num_cnt[12]>=3'd2 && full_hs_step1_used_row!=4'd12)begin
        full_hs_num[3]=4'd14; full_hs_num[4]=4'd14; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[11]>=3'd2 && full_hs_step1_used_row!=4'd11)begin
        full_hs_num[3]=4'd13; full_hs_num[4]=4'd13; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[10]>=3'd2 && full_hs_step1_used_row!=4'd10)begin
        full_hs_num[3]=4'd12; full_hs_num[4]=4'd12; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[9]>=3'd2 && full_hs_step1_used_row!=4'd9)begin
        full_hs_num[3]=4'd11; full_hs_num[4]=4'd11; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[8]>=3'd2 && full_hs_step1_used_row!=4'd8)begin
        full_hs_num[3]=4'd10; full_hs_num[4]=4'd10; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[7]>=3'd2 && full_hs_step1_used_row!=4'd7)begin
        full_hs_num[3]=4'd9; full_hs_num[4]=4'd9; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[6]>=3'd2 && full_hs_step1_used_row!=4'd6)begin
        full_hs_num[3]=4'd8; full_hs_num[4]=4'd8; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[5]>=3'd2 && full_hs_step1_used_row!=4'd5)begin
        full_hs_num[3]=4'd7; full_hs_num[4]=4'd7; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[4]>=3'd2 && full_hs_step1_used_row!=4'd4)begin
        full_hs_num[3]=4'd6; full_hs_num[4]=4'd6; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[3]>=3'd2 && full_hs_step1_used_row!=4'd3)begin
        full_hs_num[3]=4'd5; full_hs_num[4]=4'd5; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[2]>=3'd2 && full_hs_step1_used_row!=4'd2)begin
        full_hs_num[3]=4'd4; full_hs_num[4]=4'd4; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[1]>=3'd2 && full_hs_step1_used_row!=4'd1)begin
        full_hs_num[3]=4'd3; full_hs_num[4]=4'd3; full_hs_exist_bool=1'b1;
    end
    else if(num_cnt[0]>=3'd2 && full_hs_step1_used_row!=4'd0)begin
        full_hs_num[3]=4'd2; full_hs_num[4]=4'd2; full_hs_exist_bool=1'b1;
    end
    else begin  //NULL
        full_hs_num[3]=4'd15; full_hs_num[4]=4'd15; full_hs_exist_bool=1'b0;
    end
end
//================

//===2 pair===
reg [3:0] two_pair_num [0:4];
reg [3:0] two_pair_step1_used_row, two_pair_step2_used_row; //標記step 1後每個row是否用過
reg two_pair_exist_bool;

//step 1 先挑較大的兩個數字
always@(*)begin
    if(num_cnt[12]>=3'd2)begin
        two_pair_num[0]=4'd14; two_pair_num[1]=4'd14; two_pair_step1_used_row=4'd12;
    end
    else if(num_cnt[11]>=3'd2)begin
        two_pair_num[0]=4'd13; two_pair_num[1]=4'd13; two_pair_step1_used_row=4'd11;
    end
    else if(num_cnt[10]>=3'd2)begin
        two_pair_num[0]=4'd12; two_pair_num[1]=4'd12; two_pair_step1_used_row=4'd10;
    end
    else if(num_cnt[9]>=3'd2)begin
        two_pair_num[0]=4'd11; two_pair_num[1]=4'd11; two_pair_step1_used_row=4'd9;
    end
    else if(num_cnt[8]>=3'd2)begin
        two_pair_num[0]=4'd10; two_pair_num[1]=4'd10; two_pair_step1_used_row=4'd8;
    end
    else if(num_cnt[7]>=3'd2)begin
        two_pair_num[0]=4'd9; two_pair_num[1]=4'd9; two_pair_step1_used_row=4'd7;
    end
    else if(num_cnt[6]>=3'd2)begin
        two_pair_num[0]=4'd8; two_pair_num[1]=4'd8; two_pair_step1_used_row=4'd6;
    end
    else if(num_cnt[5]>=3'd2)begin
        two_pair_num[0]=4'd7; two_pair_num[1]=4'd7; two_pair_step1_used_row=4'd5;
    end
    else if(num_cnt[4]>=3'd2)begin
        two_pair_num[0]=4'd6; two_pair_num[1]=4'd6; two_pair_step1_used_row=4'd4;
    end
    else if(num_cnt[3]>=3'd2)begin
        two_pair_num[0]=4'd5; two_pair_num[1]=4'd5; two_pair_step1_used_row=4'd3;
    end
    else if(num_cnt[2]>=3'd2)begin
        two_pair_num[0]=4'd4; two_pair_num[1]=4'd4; two_pair_step1_used_row=4'd2;
    end
    else if(num_cnt[1]>=3'd2)begin
        two_pair_num[0]=4'd3; two_pair_num[1]=4'd3; two_pair_step1_used_row=4'd1;
    end
    else if(num_cnt[0]>=3'd2)begin
        two_pair_num[0]=4'd2; two_pair_num[1]=4'd2; two_pair_step1_used_row=4'd0;
    end
    else begin
        two_pair_num[0]=4'd2; two_pair_num[1]=4'd2; two_pair_step1_used_row=4'd0;
    end
end

//step 2 挑較小的兩個數字
always@(*)begin
    if(num_cnt[12]>=3'd2 && two_pair_step1_used_row!=4'd12)begin
        two_pair_num[2]=4'd14; two_pair_num[3]=4'd14; two_pair_step2_used_row=4'd12;
    end
    else if(num_cnt[11]>=3'd2 && two_pair_step1_used_row!=4'd11)begin
        two_pair_num[2]=4'd13; two_pair_num[3]=4'd13; two_pair_step2_used_row=4'd11;
    end
    else if(num_cnt[10]>=3'd2 && two_pair_step1_used_row!=4'd10)begin
        two_pair_num[2]=4'd12; two_pair_num[3]=4'd12; two_pair_step2_used_row=4'd10;
    end
    else if(num_cnt[9]>=3'd2 && two_pair_step1_used_row!=4'd9)begin
        two_pair_num[2]=4'd11; two_pair_num[3]=4'd11; two_pair_step2_used_row=4'd9;
    end
    else if(num_cnt[8]>=3'd2 && two_pair_step1_used_row!=4'd8)begin
        two_pair_num[2]=4'd10; two_pair_num[3]=4'd10; two_pair_step2_used_row=4'd8;
    end
    else if(num_cnt[7]>=3'd2 && two_pair_step1_used_row!=4'd7)begin
        two_pair_num[2]=4'd9; two_pair_num[3]=4'd9; two_pair_step2_used_row=4'd7;
    end
    else if(num_cnt[6]>=3'd2 && two_pair_step1_used_row!=4'd6)begin
        two_pair_num[2]=4'd8; two_pair_num[3]=4'd8; two_pair_step2_used_row=4'd6;
    end
    else if(num_cnt[5]>=3'd2 && two_pair_step1_used_row!=4'd5)begin
        two_pair_num[2]=4'd7; two_pair_num[3]=4'd7; two_pair_step2_used_row=4'd5;
    end
    else if(num_cnt[4]>=3'd2 && two_pair_step1_used_row!=4'd4)begin
        two_pair_num[2]=4'd6; two_pair_num[3]=4'd6; two_pair_step2_used_row=4'd4;
    end
    else if(num_cnt[3]>=3'd2 && two_pair_step1_used_row!=4'd3)begin
        two_pair_num[2]=4'd5; two_pair_num[3]=4'd5; two_pair_step2_used_row=4'd3;
    end
    else if(num_cnt[2]>=3'd2 && two_pair_step1_used_row!=4'd2)begin
        two_pair_num[2]=4'd4; two_pair_num[3]=4'd4; two_pair_step2_used_row=4'd2;
    end
    else if(num_cnt[1]>=3'd2 && two_pair_step1_used_row!=4'd1)begin
        two_pair_num[2]=4'd3; two_pair_num[3]=4'd3; two_pair_step2_used_row=4'd1;
    end
    else if(num_cnt[0]>=3'd2 && two_pair_step1_used_row!=4'd0)begin
        two_pair_num[2]=4'd2; two_pair_num[3]=4'd2; two_pair_step2_used_row=4'd0;
    end
    else begin
        two_pair_num[2]=4'd15; two_pair_num[3]=4'd15; two_pair_step2_used_row=4'd15;
    end
end

//step 3 挑最大的剩餘數字
always@(*)begin
    if(num_cnt[12]>=3'd1 && two_pair_step1_used_row!=4'd12 && two_pair_step2_used_row!=4'd12)begin
        two_pair_num[4]=4'd14; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[11]>=3'd1 && two_pair_step1_used_row!=4'd11 && two_pair_step2_used_row!=4'd11)begin
        two_pair_num[4]=4'd13; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[10]>=3'd1 && two_pair_step1_used_row!=4'd10 && two_pair_step2_used_row!=4'd10)begin
        two_pair_num[4]=4'd12; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[9]>=3'd1 && two_pair_step1_used_row!=4'd9 && two_pair_step2_used_row!=4'd9)begin
        two_pair_num[4]=4'd11; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[8]>=3'd1 && two_pair_step1_used_row!=4'd8 && two_pair_step2_used_row!=4'd8)begin
        two_pair_num[4]=4'd10; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[7]>=3'd1 && two_pair_step1_used_row!=4'd7 && two_pair_step2_used_row!=4'd7)begin
        two_pair_num[4]=4'd9; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[6]>=3'd1 && two_pair_step1_used_row!=4'd6 && two_pair_step2_used_row!=4'd6)begin
        two_pair_num[4]=4'd8; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[5]>=3'd1 && two_pair_step1_used_row!=4'd5 && two_pair_step2_used_row!=4'd5)begin
        two_pair_num[4]=4'd7; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[4]>=3'd1 && two_pair_step1_used_row!=4'd4 && two_pair_step2_used_row!=4'd4)begin
        two_pair_num[4]=4'd6; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[3]>=3'd1 && two_pair_step1_used_row!=4'd3 && two_pair_step2_used_row!=4'd3)begin
        two_pair_num[4]=4'd5; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[2]>=3'd1 && two_pair_step1_used_row!=4'd2 && two_pair_step2_used_row!=4'd2)begin
        two_pair_num[4]=4'd4; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[1]>=3'd1 && two_pair_step1_used_row!=4'd1 && two_pair_step2_used_row!=4'd1)begin
        two_pair_num[4]=4'd3; two_pair_exist_bool=1'b1;
    end
    else if(num_cnt[0]>=3'd1 && two_pair_step1_used_row!=4'd0 && two_pair_step2_used_row!=4'd0)begin
        two_pair_num[4]=4'd2; two_pair_exist_bool=1'b1;
    end
    else begin
        two_pair_num[4]=4'd15; two_pair_exist_bool=1'b0;
    end
end
//===========

//===1 pair===
reg [3:0] one_pair_num [0:4];
//two_pair_step1_used_row
reg [3:0] one_pair_step2_used_row, one_pair_step3_used_row; //標記step 1後每個row是否用過
reg one_pair_exist_bool;

//step 1 先挑較大的兩個數字(和2 pair結果必相同)
always@(*)begin
    one_pair_num[0]=two_pair_num[0]; one_pair_num[1]=two_pair_num[1];
end

//step 2 挑較剩餘最大的數字
always@(*)begin
    if(num_cnt[12]>=3'd1 && two_pair_step1_used_row!=4'd12) begin 
        one_pair_num[2]=4'd14; one_pair_step2_used_row=4'd12; 
    end
    else if(num_cnt[11]>=3'd1 && two_pair_step1_used_row!=4'd11) begin 
        one_pair_num[2]=4'd13; one_pair_step2_used_row=4'd11; 
    end
    else if(num_cnt[10]>=3'd1 && two_pair_step1_used_row!=4'd10) begin 
        one_pair_num[2]=4'd12; one_pair_step2_used_row=4'd10; 
    end
    else if(num_cnt[9]>=3'd1 && two_pair_step1_used_row!=4'd9) begin 
        one_pair_num[2]=4'd11; one_pair_step2_used_row=4'd9; 
    end
    else if(num_cnt[8]>=3'd1 && two_pair_step1_used_row!=4'd8) begin 
        one_pair_num[2]=4'd10; one_pair_step2_used_row=4'd8; 
    end
    else if(num_cnt[7]>=3'd1 && two_pair_step1_used_row!=4'd7) begin 
        one_pair_num[2]=4'd9; one_pair_step2_used_row=4'd7; 
    end
    else if(num_cnt[6]>=3'd1 && two_pair_step1_used_row!=4'd6) begin 
        one_pair_num[2]=4'd8; one_pair_step2_used_row=4'd6; 
    end
    else if(num_cnt[5]>=3'd1 && two_pair_step1_used_row!=4'd5) begin 
        one_pair_num[2]=4'd7; one_pair_step2_used_row=4'd5; 
    end
    else if(num_cnt[4]>=3'd1 && two_pair_step1_used_row!=4'd4) begin 
        one_pair_num[2]=4'd6; one_pair_step2_used_row=4'd4; 
    end
    else if(num_cnt[3]>=3'd1 && two_pair_step1_used_row!=4'd3) begin 
        one_pair_num[2]=4'd5; one_pair_step2_used_row=4'd3; 
    end
    else if(num_cnt[2]>=3'd1 && two_pair_step1_used_row!=4'd2) begin 
        one_pair_num[2]=4'd4; one_pair_step2_used_row=4'd2; 
    end
    else if(num_cnt[1]>=3'd1 && two_pair_step1_used_row!=4'd1) begin 
        one_pair_num[2]=4'd3; one_pair_step2_used_row=4'd1;
    end
    else if(num_cnt[0]>=3'd1 && two_pair_step1_used_row!=4'd0) begin 
        one_pair_num[2]=4'd2; one_pair_step2_used_row=4'd0; 
    end
    else begin  //NULL
        one_pair_num[2]=4'd15; one_pair_step2_used_row=4'd15; 
    end
end

//step 3 挑較剩餘最大的數字
always@(*)begin
    if(num_cnt[12]>=3'd1 && two_pair_step1_used_row!=4'd12 && one_pair_step2_used_row!=4'd12) begin 
        one_pair_num[3]=4'd14; one_pair_step3_used_row=4'd12; 
    end
    else if(num_cnt[11]>=3'd1 && two_pair_step1_used_row!=4'd11 && one_pair_step2_used_row!=4'd11) begin 
        one_pair_num[3]=4'd13; one_pair_step3_used_row=4'd11; 
    end
    else if(num_cnt[10]>=3'd1 && two_pair_step1_used_row!=4'd10 && one_pair_step2_used_row!=4'd10) begin 
        one_pair_num[3]=4'd12; one_pair_step3_used_row=4'd10; 
    end
    else if(num_cnt[9]>=3'd1 && two_pair_step1_used_row!=4'd9 && one_pair_step2_used_row!=4'd9) begin 
        one_pair_num[3]=4'd11; one_pair_step3_used_row=4'd9; 
    end
    else if(num_cnt[8]>=3'd1 && two_pair_step1_used_row!=4'd8 && one_pair_step2_used_row!=4'd8) begin 
        one_pair_num[3]=4'd10; one_pair_step3_used_row=4'd8; 
    end
    else if(num_cnt[7]>=3'd1 && two_pair_step1_used_row!=4'd7 && one_pair_step2_used_row!=4'd7) begin 
        one_pair_num[3]=4'd9; one_pair_step3_used_row=4'd7; 
    end
    else if(num_cnt[6]>=3'd1 && two_pair_step1_used_row!=4'd6 && one_pair_step2_used_row!=4'd6) begin 
        one_pair_num[3]=4'd8; one_pair_step3_used_row=4'd6; 
    end
    else if(num_cnt[5]>=3'd1 && two_pair_step1_used_row!=4'd5 && one_pair_step2_used_row!=4'd5) begin 
        one_pair_num[3]=4'd7; one_pair_step3_used_row=4'd5; 
    end
    else if(num_cnt[4]>=3'd1 && two_pair_step1_used_row!=4'd4 && one_pair_step2_used_row!=4'd4) begin 
        one_pair_num[3]=4'd6; one_pair_step3_used_row=4'd4; 
    end
    else if(num_cnt[3]>=3'd1 && two_pair_step1_used_row!=4'd3 && one_pair_step2_used_row!=4'd3) begin 
        one_pair_num[3]=4'd5; one_pair_step3_used_row=4'd3; 
    end
    else if(num_cnt[2]>=3'd1 && two_pair_step1_used_row!=4'd2 && one_pair_step2_used_row!=4'd2) begin 
        one_pair_num[3]=4'd4; one_pair_step3_used_row=4'd2; 
    end
    else if(num_cnt[1]>=3'd1 && two_pair_step1_used_row!=4'd1 && one_pair_step2_used_row!=4'd1) begin 
        one_pair_num[3]=4'd3; one_pair_step3_used_row=4'd1; 
    end
    else if(num_cnt[0]>=3'd1 && two_pair_step1_used_row!=4'd0 && one_pair_step2_used_row!=4'd0) begin 
        one_pair_num[3]=4'd2; one_pair_step3_used_row=4'd0; 
    end
    else begin
        one_pair_num[3]=4'd15; one_pair_step3_used_row=4'd15; 
    end
end

//step 4 挑最大的剩餘數字
always@(*)begin
    if(num_cnt[12]>=3'd1 && two_pair_step1_used_row!=4'd12 && one_pair_step2_used_row!=4'd12 && one_pair_step3_used_row!=4'd12) begin
        one_pair_num[4]=4'd14; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[11]>=3'd1 && two_pair_step1_used_row!=4'd11 && one_pair_step2_used_row!=4'd11 && one_pair_step3_used_row!=4'd11) begin
        one_pair_num[4]=4'd13; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[10]>=3'd1 && two_pair_step1_used_row!=4'd10 && one_pair_step2_used_row!=4'd10 && one_pair_step3_used_row!=4'd10) begin
        one_pair_num[4]=4'd12; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[9]>=3'd1 && two_pair_step1_used_row!=4'd9 && one_pair_step2_used_row!=4'd9 && one_pair_step3_used_row!=4'd9) begin
        one_pair_num[4]=4'd11; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[8]>=3'd1 && two_pair_step1_used_row!=4'd8 && one_pair_step2_used_row!=4'd8 && one_pair_step3_used_row!=4'd8) begin
        one_pair_num[4]=4'd10; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[7]>=3'd1 && two_pair_step1_used_row!=4'd7 && one_pair_step2_used_row!=4'd7 && one_pair_step3_used_row!=4'd7) begin
        one_pair_num[4]=4'd9; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[6]>=3'd1 && two_pair_step1_used_row!=4'd6 && one_pair_step2_used_row!=4'd6 && one_pair_step3_used_row!=4'd6) begin
        one_pair_num[4]=4'd8; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[5]>=3'd1 && two_pair_step1_used_row!=4'd5 && one_pair_step2_used_row!=4'd5 && one_pair_step3_used_row!=4'd5) begin
        one_pair_num[4]=4'd7; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[4]>=3'd1 && two_pair_step1_used_row!=4'd4 && one_pair_step2_used_row!=4'd4 && one_pair_step3_used_row!=4'd4) begin
        one_pair_num[4]=4'd6; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[3]>=3'd1 && two_pair_step1_used_row!=4'd3 && one_pair_step2_used_row!=4'd3 && one_pair_step3_used_row!=4'd3) begin
        one_pair_num[4]=4'd5; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[2]>=3'd1 && two_pair_step1_used_row!=4'd2 && one_pair_step2_used_row!=4'd2 && one_pair_step3_used_row!=4'd2) begin
        one_pair_num[4]=4'd4; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[1]>=3'd1 && two_pair_step1_used_row!=4'd1 && one_pair_step2_used_row!=4'd1 && one_pair_step3_used_row!=4'd1) begin
        one_pair_num[4]=4'd3; one_pair_exist_bool=1'b1;
    end
    else if(num_cnt[0]>=3'd1 && two_pair_step1_used_row!=4'd0 && one_pair_step2_used_row!=4'd0 && one_pair_step3_used_row!=4'd0) begin
        one_pair_num[4]=4'd2; one_pair_exist_bool=1'b1;
    end
    else begin
        one_pair_num[4]=4'd15; one_pair_exist_bool=1'b0;
    end
end
//============

//===straight===
//無視花色，只要數字連續就好
wire [3:0] straight_num [0:4];
wire straight_exist_bool;

straight straight_inst1(
    .in_num_cnt_0(num_cnt[0]), .in_num_cnt_1(num_cnt[1]), .in_num_cnt_2(num_cnt[2]), .in_num_cnt_3(num_cnt[3]),
    .in_num_cnt_4(num_cnt[4]), .in_num_cnt_5(num_cnt[5]), .in_num_cnt_6(num_cnt[6]), .in_num_cnt_7(num_cnt[7]),
    .in_num_cnt_8(num_cnt[8]), .in_num_cnt_9(num_cnt[9]), .in_num_cnt_10(num_cnt[10]),.in_num_cnt_11(num_cnt[11]),
    .in_num_cnt_12(num_cnt[12]),
    .out_straight_num_0(straight_num[0]), .out_straight_num_1(straight_num[1]), 
    .out_straight_num_2(straight_num[2]), .out_straight_num_3(straight_num[3]), 
    .out_straight_num_4(straight_num[4]),.straight_exist_bool(straight_exist_bool)
);
//==============

//===straight flush(成立後再額外看royoal flush)===
//===suit 0===
wire [3:0] s_flush_num [0:3][0:4];
wire s_flush_exist_bool [0:3];
reg [3:0] final_s_flush_num [0:4];

straight straight_inst2(
    .in_num_cnt_0({2'd0,exist_map[0][0]}), .in_num_cnt_1({2'd0,exist_map[0][1]}), .in_num_cnt_2({2'd0,exist_map[0][2]}), .in_num_cnt_3({2'd0,exist_map[0][3]}),
    .in_num_cnt_4({2'd0,exist_map[0][4]}), .in_num_cnt_5({2'd0,exist_map[0][5]}), .in_num_cnt_6({2'd0,exist_map[0][6]}), .in_num_cnt_7({2'd0,exist_map[0][7]}),
    .in_num_cnt_8({2'd0,exist_map[0][8]}), .in_num_cnt_9({2'd0,exist_map[0][9]}), .in_num_cnt_10({2'd0,exist_map[0][10]}),.in_num_cnt_11({2'd0,exist_map[0][11]}),
    .in_num_cnt_12({2'd0,exist_map[0][12]}),
    .out_straight_num_0(s_flush_num[0][0]), .out_straight_num_1(s_flush_num[0][1]), 
    .out_straight_num_2(s_flush_num[0][2]), .out_straight_num_3(s_flush_num[0][3]), 
    .out_straight_num_4(s_flush_num[0][4]),.straight_exist_bool(s_flush_exist_bool[0])
);
//===suit 1===
straight straight_inst3(
    .in_num_cnt_0({2'd0,exist_map[1][0]}), .in_num_cnt_1({2'd0,exist_map[1][1]}), .in_num_cnt_2({2'd0,exist_map[1][2]}), .in_num_cnt_3({2'd0,exist_map[1][3]}),
    .in_num_cnt_4({2'd0,exist_map[1][4]}), .in_num_cnt_5({2'd0,exist_map[1][5]}), .in_num_cnt_6({2'd0,exist_map[1][6]}), .in_num_cnt_7({2'd0,exist_map[1][7]}),
    .in_num_cnt_8({2'd0,exist_map[1][8]}), .in_num_cnt_9({2'd0,exist_map[1][9]}), .in_num_cnt_10({2'd0,exist_map[1][10]}),.in_num_cnt_11({2'd0,exist_map[1][11]}),
    .in_num_cnt_12({2'd0,exist_map[1][12]}),
    .out_straight_num_0(s_flush_num[1][0]), .out_straight_num_1(s_flush_num[1][1]), 
    .out_straight_num_2(s_flush_num[1][2]), .out_straight_num_3(s_flush_num[1][3]), 
    .out_straight_num_4(s_flush_num[1][4]),.straight_exist_bool(s_flush_exist_bool[1])
);
//===suit 2===
straight straight_inst4(
    .in_num_cnt_0({2'd0,exist_map[2][0]}), .in_num_cnt_1({2'd0,exist_map[2][1]}), .in_num_cnt_2({2'd0,exist_map[2][2]}), .in_num_cnt_3({2'd0,exist_map[2][3]}),
    .in_num_cnt_4({2'd0,exist_map[2][4]}), .in_num_cnt_5({2'd0,exist_map[2][5]}), .in_num_cnt_6({2'd0,exist_map[2][6]}), .in_num_cnt_7({2'd0,exist_map[2][7]}),
    .in_num_cnt_8({2'd0,exist_map[2][8]}), .in_num_cnt_9({2'd0,exist_map[2][9]}), .in_num_cnt_10({2'd0,exist_map[2][10]}),.in_num_cnt_11({2'd0,exist_map[2][11]}),
    .in_num_cnt_12({2'd0,exist_map[2][12]}),
    .out_straight_num_0(s_flush_num[2][0]), .out_straight_num_1(s_flush_num[2][1]), 
    .out_straight_num_2(s_flush_num[2][2]), .out_straight_num_3(s_flush_num[2][3]), 
    .out_straight_num_4(s_flush_num[2][4]),.straight_exist_bool(s_flush_exist_bool[2])
);
//===suit 3===
straight straight_inst5(
    .in_num_cnt_0({2'd0,exist_map[3][0]}), .in_num_cnt_1({2'd0,exist_map[3][1]}), .in_num_cnt_2({2'd0,exist_map[3][2]}), .in_num_cnt_3({2'd0,exist_map[3][3]}),
    .in_num_cnt_4({2'd0,exist_map[3][4]}), .in_num_cnt_5({2'd0,exist_map[3][5]}), .in_num_cnt_6({2'd0,exist_map[3][6]}), .in_num_cnt_7({2'd0,exist_map[3][7]}),
    .in_num_cnt_8({2'd0,exist_map[3][8]}), .in_num_cnt_9({2'd0,exist_map[3][9]}), .in_num_cnt_10({2'd0,exist_map[3][10]}),.in_num_cnt_11({2'd0,exist_map[3][11]}),
    .in_num_cnt_12({2'd0,exist_map[3][12]}),
    .out_straight_num_0(s_flush_num[3][0]), .out_straight_num_1(s_flush_num[3][1]), 
    .out_straight_num_2(s_flush_num[3][2]), .out_straight_num_3(s_flush_num[3][3]), 
    .out_straight_num_4(s_flush_num[3][4]),.straight_exist_bool(s_flush_exist_bool[3])
);

reg royal_flush_bool, straight_flush_bool;

//straight_flush_bool
always@(*)begin
    if(s_flush_exist_bool[0]==1'b0&&s_flush_exist_bool[1]==1'b0&&s_flush_exist_bool[2]==1'b0&&s_flush_exist_bool[3]==1'b0)straight_flush_bool=1'b0;
    else straight_flush_bool=1'b1;
end

always@(*)begin
    //royal flush在花色0
    if(s_flush_num[0][0]==4'd14&&s_flush_exist_bool[0]==1'b1)begin
        royal_flush_bool=1'b1; 
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[0][i];
    end
    //royal flush在花色1
    else if(s_flush_num[1][0]==4'd14&&s_flush_exist_bool[1]==1'b1)begin
        royal_flush_bool=1'b1;
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[1][i];
    end
    //royal flush在花色2
    else if(s_flush_num[2][0]==4'd14&&s_flush_exist_bool[2]==1'b1)begin
        royal_flush_bool=1'b1;
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[2][i];
    end
    //royal flush在花色3
    else if(s_flush_num[3][0]==4'd14&&s_flush_exist_bool[3]==1'b1)begin
        royal_flush_bool=1'b1;
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[3][i];
    end
    //straight flush在花色0
    else if(straight_flush_bool==1'b1 && 
    {s_flush_exist_bool[0],s_flush_num[0][0]}>={s_flush_exist_bool[1],s_flush_num[1][0]} &&
    {s_flush_exist_bool[0],s_flush_num[0][0]}>={s_flush_exist_bool[2],s_flush_num[2][0]} &&
    {s_flush_exist_bool[0],s_flush_num[0][0]}>={s_flush_exist_bool[3],s_flush_num[3][0]})begin
        royal_flush_bool=1'b0; 
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[0][i];
    end
    //straight flush在花色1
    else if(straight_flush_bool==1'b1 && 
    {s_flush_exist_bool[1],s_flush_num[1][0]}>={s_flush_exist_bool[0],s_flush_num[0][0]} &&
    {s_flush_exist_bool[1],s_flush_num[1][0]}>={s_flush_exist_bool[2],s_flush_num[2][0]} &&
    {s_flush_exist_bool[1],s_flush_num[1][0]}>={s_flush_exist_bool[3],s_flush_num[3][0]})begin
        royal_flush_bool=1'b0; 
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[1][i];
    end
    //straight flush在花色2
    else if(straight_flush_bool==1'b1 && 
    {s_flush_exist_bool[2],s_flush_num[2][0]}>={s_flush_exist_bool[0],s_flush_num[0][0]} &&
    {s_flush_exist_bool[2],s_flush_num[2][0]}>={s_flush_exist_bool[1],s_flush_num[1][0]} &&
    {s_flush_exist_bool[2],s_flush_num[2][0]}>={s_flush_exist_bool[3],s_flush_num[3][0]})begin
        royal_flush_bool=1'b0; 
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[2][i];
    end
    //straight flush在花色3
    else if(straight_flush_bool==1'b1 && 
    {s_flush_exist_bool[3],s_flush_num[3][0]}>={s_flush_exist_bool[0],s_flush_num[0][0]} &&
    {s_flush_exist_bool[3],s_flush_num[3][0]}>={s_flush_exist_bool[1],s_flush_num[1][0]} &&
    {s_flush_exist_bool[3],s_flush_num[3][0]}>={s_flush_exist_bool[2],s_flush_num[2][0]})begin
        royal_flush_bool=1'b0; 
        for(i=0;i<5;i=i+1)final_s_flush_num[i]=s_flush_num[3][i];
    end
    else begin
        royal_flush_bool=1'b0; for(i=0;i<5;i=i+1)final_s_flush_num[i]=4'd15;
    end
end
//===============================================

//===high card 要有五張不同的卡才算===
wire [3:0] hc_num [0:4];
wire hc_exist_bool;
high_card hc_inst0(
    .in_num_cnt_0(num_cnt[0]), .in_num_cnt_1(num_cnt[1]), .in_num_cnt_2(num_cnt[2]), .in_num_cnt_3(num_cnt[3]),
    .in_num_cnt_4(num_cnt[4]), .in_num_cnt_5(num_cnt[5]), .in_num_cnt_6(num_cnt[6]), .in_num_cnt_7(num_cnt[7]),
    .in_num_cnt_8(num_cnt[8]), .in_num_cnt_9(num_cnt[9]), .in_num_cnt_10(num_cnt[10]),.in_num_cnt_11(num_cnt[11]),
    .in_num_cnt_12(num_cnt[12]),
    .out_hc_num_0(hc_num[0]), .out_hc_num_1(hc_num[1]), .out_hc_num_2(hc_num[2]),
    .out_hc_num_3(hc_num[3]), .out_hc_num_4(hc_num[4]), .hc_exist_bool(hc_exist_bool)
);
//===============

//===Flush 要有五張不同的卡才算===
wire [3:0] Flush_num [0:3][0:4];    //每個suit的結果
wire Flush_exist_bool[0:3];         //每個suit的結果
reg [3:0] final_flush_num [0:4];
reg final_flush_exist_bool;

//===suit 1===
high_card hc_inst1(
    .in_num_cnt_0({2'd0,exist_map[0][0]}), .in_num_cnt_1({2'd0,exist_map[0][1]}), .in_num_cnt_2({2'd0,exist_map[0][2]}), .in_num_cnt_3({2'd0,exist_map[0][3]}),
    .in_num_cnt_4({2'd0,exist_map[0][4]}), .in_num_cnt_5({2'd0,exist_map[0][5]}), .in_num_cnt_6({2'd0,exist_map[0][6]}), .in_num_cnt_7({2'd0,exist_map[0][7]}),
    .in_num_cnt_8({2'd0,exist_map[0][8]}), .in_num_cnt_9({2'd0,exist_map[0][9]}), .in_num_cnt_10({2'd0,exist_map[0][10]}),.in_num_cnt_11({2'd0,exist_map[0][11]}),
    .in_num_cnt_12({2'd0,exist_map[0][12]}),
    .out_hc_num_0(Flush_num[0][0]), .out_hc_num_1(Flush_num[0][1]), .out_hc_num_2(Flush_num[0][2]),
    .out_hc_num_3(Flush_num[0][3]), .out_hc_num_4(Flush_num[0][4]), .hc_exist_bool(Flush_exist_bool[0])
);
//===============

//===suit 2===
high_card hc_inst2(
    .in_num_cnt_0({2'd0,exist_map[1][0]}), .in_num_cnt_1({2'd0,exist_map[1][1]}), .in_num_cnt_2({2'd0,exist_map[1][2]}), .in_num_cnt_3({2'd0,exist_map[1][3]}),
    .in_num_cnt_4({2'd0,exist_map[1][4]}), .in_num_cnt_5({2'd0,exist_map[1][5]}), .in_num_cnt_6({2'd0,exist_map[1][6]}), .in_num_cnt_7({2'd0,exist_map[1][7]}),
    .in_num_cnt_8({2'd0,exist_map[1][8]}), .in_num_cnt_9({2'd0,exist_map[1][9]}), .in_num_cnt_10({2'd0,exist_map[1][10]}),.in_num_cnt_11({2'd0,exist_map[1][11]}),
    .in_num_cnt_12({2'd0,exist_map[1][12]}),
    .out_hc_num_0(Flush_num[1][0]), .out_hc_num_1(Flush_num[1][1]), .out_hc_num_2(Flush_num[1][2]),
    .out_hc_num_3(Flush_num[1][3]), .out_hc_num_4(Flush_num[1][4]), .hc_exist_bool(Flush_exist_bool[1])
);
//===============

//===suit 3===
high_card hc_inst3(
    .in_num_cnt_0({2'd0,exist_map[2][0]}), .in_num_cnt_1({2'd0,exist_map[2][1]}), .in_num_cnt_2({2'd0,exist_map[2][2]}), .in_num_cnt_3({2'd0,exist_map[2][3]}),
    .in_num_cnt_4({2'd0,exist_map[2][4]}), .in_num_cnt_5({2'd0,exist_map[2][5]}), .in_num_cnt_6({2'd0,exist_map[2][6]}), .in_num_cnt_7({2'd0,exist_map[2][7]}),
    .in_num_cnt_8({2'd0,exist_map[2][8]}), .in_num_cnt_9({2'd0,exist_map[2][9]}), .in_num_cnt_10({2'd0,exist_map[2][10]}), .in_num_cnt_11({2'd0,exist_map[2][11]}),
    .in_num_cnt_12({2'd0,exist_map[2][12]}),
    .out_hc_num_0(Flush_num[2][0]), .out_hc_num_1(Flush_num[2][1]), .out_hc_num_2(Flush_num[2][2]),
    .out_hc_num_3(Flush_num[2][3]), .out_hc_num_4(Flush_num[2][4]), .hc_exist_bool(Flush_exist_bool[2])
);
//===============

//===suit 4===
high_card hc_inst4(
    .in_num_cnt_0({2'd0,exist_map[3][0]}), .in_num_cnt_1({2'd0,exist_map[3][1]}), .in_num_cnt_2({2'd0,exist_map[3][2]}), .in_num_cnt_3({2'd0,exist_map[3][3]}),
    .in_num_cnt_4({2'd0,exist_map[3][4]}), .in_num_cnt_5({2'd0,exist_map[3][5]}), .in_num_cnt_6({2'd0,exist_map[3][6]}), .in_num_cnt_7({2'd0,exist_map[3][7]}),
    .in_num_cnt_8({2'd0,exist_map[3][8]}), .in_num_cnt_9({2'd0,exist_map[3][9]}), .in_num_cnt_10({2'd0,exist_map[3][10]}), .in_num_cnt_11({2'd0,exist_map[3][11]}),
    .in_num_cnt_12({2'd0,exist_map[3][12]}),
    .out_hc_num_0(Flush_num[3][0]), .out_hc_num_1(Flush_num[3][1]), .out_hc_num_2(Flush_num[3][2]),
    .out_hc_num_3(Flush_num[3][3]), .out_hc_num_4(Flush_num[3][4]), .hc_exist_bool(Flush_exist_bool[3])
);
//===============

//4*5+1
wire [20:0] flush_suit1_score,flush_suit2_score,flush_suit3_score,flush_suit4_score; //17 bit
assign flush_suit1_score = {Flush_exist_bool[0], Flush_num[0][0], Flush_num[0][1], Flush_num[0][2], Flush_num[0][3], Flush_num[0][4]};
assign flush_suit2_score = {Flush_exist_bool[1], Flush_num[1][0], Flush_num[1][1], Flush_num[1][2], Flush_num[1][3], Flush_num[1][4]};
assign flush_suit3_score = {Flush_exist_bool[2], Flush_num[2][0], Flush_num[2][1], Flush_num[2][2], Flush_num[2][3], Flush_num[2][4]};
assign flush_suit4_score = {Flush_exist_bool[3], Flush_num[3][0], Flush_num[3][1], Flush_num[3][2], Flush_num[3][3], Flush_num[3][4]};

always@(*)begin
    if(Flush_exist_bool[0]==1'b1 && flush_suit1_score>=flush_suit2_score &&
    flush_suit1_score>=flush_suit3_score && flush_suit1_score>=flush_suit4_score) begin
        final_flush_exist_bool = 1'b1;
        for(i=0;i<5;i=i+1) final_flush_num[i] = Flush_num[0][i];
    end
    else if(Flush_exist_bool[1]==1'b1 && flush_suit2_score>=flush_suit1_score &&
    flush_suit2_score>=flush_suit3_score && flush_suit2_score>=flush_suit4_score) begin
        final_flush_exist_bool = 1'b1;
        for(i=0;i<5;i=i+1) final_flush_num[i] = Flush_num[1][i];
    end
    else if(Flush_exist_bool[2]==1'b1 && flush_suit3_score>=flush_suit1_score &&
    flush_suit3_score>=flush_suit2_score && flush_suit3_score>=flush_suit4_score) begin
        final_flush_exist_bool = 1'b1;
        for(i=0;i<5;i=i+1) final_flush_num[i] = Flush_num[2][i];
    end
    else if(Flush_exist_bool[3]==1'b1 && flush_suit4_score>=flush_suit1_score &&
    flush_suit4_score>=flush_suit2_score && flush_suit4_score>=flush_suit3_score) begin
        final_flush_exist_bool = 1'b1;
        for(i=0;i<5;i=i+1) final_flush_num[i] = Flush_num[3][i];
    end
    else begin
        final_flush_exist_bool = 1'b0;
        for(i=0;i<5;i=i+1) final_flush_num[i] = 4'd15;
    end
end

    //===output===
    always@(*)begin
        if(royal_flush_bool==1'b1)begin
            chosen_type=4'd11;
            out_num_1=final_s_flush_num[0]; out_num_2=final_s_flush_num[1]; out_num_3=final_s_flush_num[2];
            out_num_4=final_s_flush_num[3]; out_num_5=final_s_flush_num[4];
        end
        else if(straight_flush_bool==1'b1)begin
            chosen_type=4'd10;
            out_num_1=final_s_flush_num[0]; out_num_2=final_s_flush_num[1]; out_num_3=final_s_flush_num[2];
            out_num_4=final_s_flush_num[3]; out_num_5=final_s_flush_num[4];
        end
        else if(four_kind_step1_used_row!=15 && four_kind_exist_bool==1'b1)begin
            chosen_type=4'd9;
            out_num_1=four_kind_num[0]; out_num_2=four_kind_num[1]; out_num_3=four_kind_num[2];
            out_num_4=four_kind_num[3]; out_num_5=four_kind_num[4];
        end
        else if(full_hs_step1_used_row!=15 && full_hs_exist_bool==1'b1)begin
            chosen_type=4'd8;
            out_num_1=full_hs_num[0]; out_num_2=full_hs_num[1]; out_num_3=full_hs_num[2];
            out_num_4=full_hs_num[3]; out_num_5=full_hs_num[4];
        end
        else if(final_flush_exist_bool==1'b1)begin
            chosen_type=4'd7;
            out_num_1=final_flush_num[0]; out_num_2=final_flush_num[1]; out_num_3=final_flush_num[2];
            out_num_4=final_flush_num[3]; out_num_5=final_flush_num[4];
        end
        else if(straight_exist_bool==1'b1)begin
            chosen_type=4'd6;
            out_num_1=straight_num[0]; out_num_2=straight_num[1]; out_num_3=straight_num[2];
            out_num_4=straight_num[3]; out_num_5=straight_num[4];
        end
        else if(three_kind_step1_used_row!=15&&three_kind_step2_used_row!=15&&three_kind_exist_bool==1'b1)begin
            chosen_type=4'd5;
            out_num_1=three_kind_num[0]; out_num_2=three_kind_num[1]; out_num_3=three_kind_num[2];
            out_num_4=three_kind_num[3]; out_num_5=three_kind_num[4];
        end
        else if(two_pair_step1_used_row!=15&&two_pair_step2_used_row!=15&&two_pair_exist_bool==1'b1)begin
            chosen_type=4'd4;
            out_num_1=two_pair_num[0]; out_num_2=two_pair_num[1]; out_num_3=two_pair_num[2];
            out_num_4=two_pair_num[3]; out_num_5=two_pair_num[4];
        end
        else if(two_pair_step1_used_row!=15&&one_pair_step2_used_row!=15&&one_pair_step3_used_row!=15&&one_pair_exist_bool==1'b1)begin
            chosen_type=4'd3;
            out_num_1=one_pair_num[0]; out_num_2=one_pair_num[1]; out_num_3=one_pair_num[2];
            out_num_4=one_pair_num[3]; out_num_5=one_pair_num[4];
        end
        else if(hc_exist_bool==1'b1)begin
            chosen_type=4'd2;
            out_num_1=hc_num[0]; out_num_2=hc_num[1]; out_num_3=hc_num[2];
            out_num_4=hc_num[3]; out_num_5=hc_num[4];
        end
        else begin  //NULL
            chosen_type=4'd1;
            out_num_1=4'd15; out_num_2=4'd15; out_num_3=4'd15; out_num_4=4'd15; out_num_5=4'd15;
        end
    end
    //============
endmodule

//for straight and straight flush
module straight(
    input  [2:0] in_num_cnt_0, in_num_cnt_1, in_num_cnt_2, in_num_cnt_3,
    input  [2:0] in_num_cnt_4, in_num_cnt_5, in_num_cnt_6, in_num_cnt_7,
    input  [2:0] in_num_cnt_8, in_num_cnt_9, in_num_cnt_10, in_num_cnt_11,
    input  [2:0] in_num_cnt_12,
    output [3:0] out_straight_num_0, out_straight_num_1, out_straight_num_2,
    output [3:0] out_straight_num_3, out_straight_num_4,
    output reg straight_exist_bool
);
    //===straight(無視花色，只要數字連續就好)===
    reg [3:0] straight_num [0:4];
    always@(*)begin
        if(in_num_cnt_12>=3'd1 && in_num_cnt_11>=3'd1 && in_num_cnt_10>=3'd1 && in_num_cnt_9>=3'd1 && in_num_cnt_8>=3'd1) begin
            // A K Q J 10
            straight_num[0]=4'd14; straight_num[1]=4'd13; straight_num[2]=4'd12; straight_num[3]=4'd11; straight_num[4]=4'd10;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_11>=3'd1 && in_num_cnt_10>=3'd1 && in_num_cnt_9>=3'd1 && in_num_cnt_8>=3'd1 && in_num_cnt_7>=3'd1) begin
            // K Q J 10 9
            straight_num[0]=4'd13; straight_num[1]=4'd12; straight_num[2]=4'd11; straight_num[3]=4'd10; straight_num[4]=4'd9;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_10>=3'd1 && in_num_cnt_9>=3'd1 && in_num_cnt_8>=3'd1 && in_num_cnt_7>=3'd1 && in_num_cnt_6>=3'd1) begin
            // Q J 10 9 8
            straight_num[0]=4'd12; straight_num[1]=4'd11; straight_num[2]=4'd10; straight_num[3]=4'd9; straight_num[4]=4'd8;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_9>=3'd1 && in_num_cnt_8>=3'd1 && in_num_cnt_7>=3'd1 && in_num_cnt_6>=3'd1 && in_num_cnt_5>=3'd1) begin
            // J 10 9 8 7
            straight_num[0]=4'd11; straight_num[1]=4'd10; straight_num[2]=4'd9; straight_num[3]=4'd8; straight_num[4]=4'd7;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_8>=3'd1 && in_num_cnt_7>=3'd1 && in_num_cnt_6>=3'd1 && in_num_cnt_5>=3'd1 && in_num_cnt_4>=3'd1) begin
            // 10 9 8 7 6
            straight_num[0]=4'd10; straight_num[1]=4'd9; straight_num[2]=4'd8; straight_num[3]=4'd7; straight_num[4]=4'd6;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_7>=3'd1 && in_num_cnt_6>=3'd1 && in_num_cnt_5>=3'd1 && in_num_cnt_4>=3'd1 && in_num_cnt_3>=3'd1) begin
            // 9 8 7 6 5
            straight_num[0]=4'd9; straight_num[1]=4'd8; straight_num[2]=4'd7; straight_num[3]=4'd6; straight_num[4]=4'd5;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_6>=3'd1 && in_num_cnt_5>=3'd1 && in_num_cnt_4>=3'd1 && in_num_cnt_3>=3'd1 && in_num_cnt_2>=3'd1) begin
            // 8 7 6 5 4
            straight_num[0]=4'd8; straight_num[1]=4'd7; straight_num[2]=4'd6; straight_num[3]=4'd5; straight_num[4]=4'd4;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_5>=3'd1 && in_num_cnt_4>=3'd1 && in_num_cnt_3>=3'd1 && in_num_cnt_2>=3'd1 && in_num_cnt_1>=3'd1) begin
            // 7 6 5 4 3
            straight_num[0]=4'd7; straight_num[1]=4'd6; straight_num[2]=4'd5; straight_num[3]=4'd4; straight_num[4]=4'd3;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_4>=3'd1 && in_num_cnt_3>=3'd1 && in_num_cnt_2>=3'd1 && in_num_cnt_1>=3'd1 && in_num_cnt_0>=3'd1) begin
            // 6 5 4 3 2
            straight_num[0]=4'd6; straight_num[1]=4'd5; straight_num[2]=4'd4; straight_num[3]=4'd3; straight_num[4]=4'd2;
            straight_exist_bool=1'b1;
        end
        else if(in_num_cnt_12>=3'd1 && in_num_cnt_0>=3'd1 && in_num_cnt_1>=3'd1 && in_num_cnt_2>=3'd1 && in_num_cnt_3>=3'd1) begin
            // 5 4 3 2 A
            straight_num[0]=4'd5; straight_num[1]=4'd4; straight_num[2]=4'd3; straight_num[3]=4'd2; straight_num[4]=4'd1;
            straight_exist_bool=1'b1;
        end
        else begin  //NULL
            straight_num[0]=4'd15; straight_num[1]=4'd15; straight_num[2]=4'd15; straight_num[3]=4'd15; straight_num[4]=4'd15;
            straight_exist_bool=1'b0;
        end
    end
    //===================
    assign out_straight_num_0=straight_num[0]; 
    assign out_straight_num_1=straight_num[1]; 
    assign out_straight_num_2=straight_num[2];
    assign out_straight_num_3=straight_num[3]; 
    assign out_straight_num_4=straight_num[4];
endmodule

module high_card(
    input  [2:0] in_num_cnt_0, in_num_cnt_1, in_num_cnt_2, in_num_cnt_3,
    input  [2:0] in_num_cnt_4, in_num_cnt_5, in_num_cnt_6, in_num_cnt_7,
    input  [2:0] in_num_cnt_8, in_num_cnt_9, in_num_cnt_10, in_num_cnt_11,
    input  [2:0] in_num_cnt_12,
    output reg [3:0] out_hc_num_0, out_hc_num_1, out_hc_num_2,
    output reg [3:0] out_hc_num_3, out_hc_num_4,
    output reg hc_exist_bool
);
    reg [3:0] hc_step_1_row,hc_step_2_row,hc_step_3_row,hc_step_4_row,hc_step_5_row;

    reg [3:0] hc_num [0:4];
    always@(*)begin
        if(in_num_cnt_12>=3'd1) begin 
            hc_num[0]=4'd14; hc_step_1_row=4'd12; 
        end
        else if(in_num_cnt_11>=3'd1) begin 
            hc_num[0]=4'd13; hc_step_1_row=4'd11; 
        end
        else if(in_num_cnt_10>=3'd1) begin 
            hc_num[0]=4'd12; hc_step_1_row=4'd10; 
        end
        else if(in_num_cnt_9>=3'd1) begin 
            hc_num[0]=4'd11; hc_step_1_row=4'd9; 
        end
        else if(in_num_cnt_8>=3'd1) begin 
            hc_num[0]=4'd10; hc_step_1_row=4'd8; 
        end
        else if(in_num_cnt_7>=3'd1) begin 
            hc_num[0]=4'd9; hc_step_1_row=4'd7;
        end
        else if(in_num_cnt_6>=3'd1) begin 
            hc_num[0]=4'd8; hc_step_1_row=4'd6; 
        end
        else if(in_num_cnt_5>=3'd1) begin 
            hc_num[0]=4'd7; hc_step_1_row=4'd5; 
        end
        else if(in_num_cnt_4>=3'd1) begin 
            hc_num[0]=4'd6; hc_step_1_row=4'd4; 
        end
        else if(in_num_cnt_3>=3'd1) begin 
            hc_num[0]=4'd5; hc_step_1_row=4'd3; 
        end
        else if(in_num_cnt_2>=3'd1) begin 
            hc_num[0]=4'd4; hc_step_1_row=4'd2; 
        end
        else if(in_num_cnt_1>=3'd1) begin 
            hc_num[0]=4'd3; hc_step_1_row=4'd1; 
        end
        else if(in_num_cnt_0>=3'd1) begin 
            hc_num[0]=4'd2; hc_step_1_row=4'd0; 
        end
        else begin
            hc_num[0]=4'd15; hc_step_1_row=4'd15; 
        end
    end

    always@(*)begin
        if(in_num_cnt_12>=3'd1 && hc_step_1_row!=4'd12) begin
            hc_num[1]=4'd14; hc_step_2_row=4'd12;
        end
        else if(in_num_cnt_11>=3'd1 && hc_step_1_row!=4'd11) begin
            hc_num[1]=4'd13; hc_step_2_row=4'd11;
        end
        else if(in_num_cnt_10>=3'd1 && hc_step_1_row!=4'd10) begin
            hc_num[1]=4'd12; hc_step_2_row=4'd10;
        end
        else if(in_num_cnt_9>=3'd1 && hc_step_1_row!=4'd9) begin
            hc_num[1]=4'd11; hc_step_2_row=4'd9;
        end
        else if(in_num_cnt_8>=3'd1 && hc_step_1_row!=4'd8) begin
            hc_num[1]=4'd10; hc_step_2_row=4'd8;
        end
        else if(in_num_cnt_7>=3'd1 && hc_step_1_row!=4'd7) begin
            hc_num[1]=4'd9; hc_step_2_row=4'd7;
        end
        else if(in_num_cnt_6>=3'd1 && hc_step_1_row!=4'd6) begin
            hc_num[1]=4'd8; hc_step_2_row=4'd6;
        end
        else if(in_num_cnt_5>=3'd1 && hc_step_1_row!=4'd5) begin
            hc_num[1]=4'd7; hc_step_2_row=4'd5;
        end
        else if(in_num_cnt_4>=3'd1 && hc_step_1_row!=4'd4) begin
            hc_num[1]=4'd6; hc_step_2_row=4'd4;
        end
        else if(in_num_cnt_3>=3'd1 && hc_step_1_row!=4'd3) begin
            hc_num[1]=4'd5; hc_step_2_row=4'd3;
        end
        else if(in_num_cnt_2>=3'd1 && hc_step_1_row!=4'd2) begin
            hc_num[1]=4'd4; hc_step_2_row=4'd2;
        end
        else if(in_num_cnt_1>=3'd1 && hc_step_1_row!=4'd1) begin
            hc_num[1]=4'd3; hc_step_2_row=4'd1;
        end
        else if(in_num_cnt_0>=3'd1 && hc_step_1_row!=4'd0) begin
            hc_num[1]=4'd2; hc_step_2_row=4'd0;
        end
        else begin
            hc_num[1]=4'd15; hc_step_2_row=4'd15;
        end
    end

    always@(*)begin
        if(in_num_cnt_12>=3'd1 && hc_step_1_row!=4'd12 && hc_step_2_row!=4'd12) begin
            hc_num[2]=4'd14; hc_step_3_row=4'd12;
        end
        else if(in_num_cnt_11>=3'd1 && hc_step_1_row!=4'd11 && hc_step_2_row!=4'd11) begin
            hc_num[2]=4'd13; hc_step_3_row=4'd11;
        end
        else if(in_num_cnt_10>=3'd1 && hc_step_1_row!=4'd10 && hc_step_2_row!=4'd10) begin
            hc_num[2]=4'd12; hc_step_3_row=4'd10;
        end
        else if(in_num_cnt_9>=3'd1 && hc_step_1_row!=4'd9 && hc_step_2_row!=4'd9) begin
            hc_num[2]=4'd11; hc_step_3_row=4'd9;
        end
        else if(in_num_cnt_8>=3'd1 && hc_step_1_row!=4'd8 && hc_step_2_row!=4'd8) begin
            hc_num[2]=4'd10; hc_step_3_row=4'd8;
        end
        else if(in_num_cnt_7>=3'd1 && hc_step_1_row!=4'd7 && hc_step_2_row!=4'd7) begin
            hc_num[2]=4'd9; hc_step_3_row=4'd7;
        end
        else if(in_num_cnt_6>=3'd1 && hc_step_1_row!=4'd6 && hc_step_2_row!=4'd6) begin
            hc_num[2]=4'd8; hc_step_3_row=4'd6;
        end
        else if(in_num_cnt_5>=3'd1 && hc_step_1_row!=4'd5 && hc_step_2_row!=4'd5) begin
            hc_num[2]=4'd7; hc_step_3_row=4'd5;
        end
        else if(in_num_cnt_4>=3'd1 && hc_step_1_row!=4'd4 && hc_step_2_row!=4'd4) begin
            hc_num[2]=4'd6; hc_step_3_row=4'd4;
        end
        else if(in_num_cnt_3>=3'd1 && hc_step_1_row!=4'd3 && hc_step_2_row!=4'd3) begin
            hc_num[2]=4'd5; hc_step_3_row=4'd3;
        end
        else if(in_num_cnt_2>=3'd1 && hc_step_1_row!=4'd2 && hc_step_2_row!=4'd2) begin
            hc_num[2]=4'd4; hc_step_3_row=4'd2;
        end
        else if(in_num_cnt_1>=3'd1 && hc_step_1_row!=4'd1 && hc_step_2_row!=4'd1) begin
            hc_num[2]=4'd3; hc_step_3_row=4'd1;
        end
        else if(in_num_cnt_0>=3'd1 && hc_step_1_row!=4'd0 && hc_step_2_row!=4'd0) begin
            hc_num[2]=4'd2; hc_step_3_row=4'd0;
        end
        else begin
            hc_num[2]=4'd15; hc_step_3_row=4'd15;
        end
    end

    always@(*)begin
        if(in_num_cnt_12>=3'd1 && hc_step_1_row!=4'd12 && hc_step_2_row!=4'd12 && hc_step_3_row!=4'd12) begin
            hc_num[3]=4'd14; hc_step_4_row=4'd12;
        end
        else if(in_num_cnt_11>=3'd1 && hc_step_1_row!=4'd11 && hc_step_2_row!=4'd11 && hc_step_3_row!=4'd11) begin
            hc_num[3]=4'd13; hc_step_4_row=4'd11;
        end
        else if(in_num_cnt_10>=3'd1 && hc_step_1_row!=4'd10 && hc_step_2_row!=4'd10 && hc_step_3_row!=4'd10) begin
            hc_num[3]=4'd12; hc_step_4_row=4'd10;
        end
        else if(in_num_cnt_9>=3'd1 && hc_step_1_row!=4'd9 && hc_step_2_row!=4'd9 && hc_step_3_row!=4'd9) begin
            hc_num[3]=4'd11; hc_step_4_row=4'd9;
        end
        else if(in_num_cnt_8>=3'd1 && hc_step_1_row!=4'd8 && hc_step_2_row!=4'd8 && hc_step_3_row!=4'd8) begin
            hc_num[3]=4'd10; hc_step_4_row=4'd8;
        end
        else if(in_num_cnt_7>=3'd1 && hc_step_1_row!=4'd7 && hc_step_2_row!=4'd7 && hc_step_3_row!=4'd7) begin
            hc_num[3]=4'd9; hc_step_4_row=4'd7;
        end
        else if(in_num_cnt_6>=3'd1 && hc_step_1_row!=4'd6 && hc_step_2_row!=4'd6 && hc_step_3_row!=4'd6) begin
            hc_num[3]=4'd8; hc_step_4_row=4'd6;
        end
        else if(in_num_cnt_5>=3'd1 && hc_step_1_row!=4'd5 && hc_step_2_row!=4'd5 && hc_step_3_row!=4'd5) begin
            hc_num[3]=4'd7; hc_step_4_row=4'd5;
        end
        else if(in_num_cnt_4>=3'd1 && hc_step_1_row!=4'd4 && hc_step_2_row!=4'd4 && hc_step_3_row!=4'd4) begin
            hc_num[3]=4'd6; hc_step_4_row=4'd4;
        end
        else if(in_num_cnt_3>=3'd1 && hc_step_1_row!=4'd3 && hc_step_2_row!=4'd3 && hc_step_3_row!=4'd3) begin
            hc_num[3]=4'd5; hc_step_4_row=4'd3;
        end
        else if(in_num_cnt_2>=3'd1 && hc_step_1_row!=4'd2 && hc_step_2_row!=4'd2 && hc_step_3_row!=4'd2) begin
            hc_num[3]=4'd4; hc_step_4_row=4'd2;
        end
        else if(in_num_cnt_1>=3'd1 && hc_step_1_row!=4'd1 && hc_step_2_row!=4'd1 && hc_step_3_row!=4'd1) begin
            hc_num[3]=4'd3; hc_step_4_row=4'd1;
        end
        else if(in_num_cnt_0>=3'd1 && hc_step_1_row!=4'd0 && hc_step_2_row!=4'd0 && hc_step_3_row!=4'd0) begin
            hc_num[3]=4'd2; hc_step_4_row=4'd0;
        end
        else begin
            hc_num[3]=4'd15; hc_step_4_row=4'd15;
        end
    end

    always@(*)begin
        if(in_num_cnt_12>=3'd1 && hc_step_1_row!=4'd12 && hc_step_2_row!=4'd12 && hc_step_3_row!=4'd12 && hc_step_4_row!=4'd12) begin
            hc_num[4]=4'd14; hc_step_5_row=4'd12;
        end
        else if(in_num_cnt_11>=3'd1 && hc_step_1_row!=4'd11 && hc_step_2_row!=4'd11 && hc_step_3_row!=4'd11 && hc_step_4_row!=4'd11) begin
            hc_num[4]=4'd13; hc_step_5_row=4'd11;
        end
        else if(in_num_cnt_10>=3'd1 && hc_step_1_row!=4'd10 && hc_step_2_row!=4'd10 && hc_step_3_row!=4'd10 && hc_step_4_row!=4'd10) begin
            hc_num[4]=4'd12; hc_step_5_row=4'd10;
        end
        else if(in_num_cnt_9>=3'd1 && hc_step_1_row!=4'd9 && hc_step_2_row!=4'd9 && hc_step_3_row!=4'd9 && hc_step_4_row!=4'd9) begin
            hc_num[4]=4'd11; hc_step_5_row=4'd9;
        end
        else if(in_num_cnt_8>=3'd1 && hc_step_1_row!=4'd8 && hc_step_2_row!=4'd8 && hc_step_3_row!=4'd8 && hc_step_4_row!=4'd8) begin
            hc_num[4]=4'd10; hc_step_5_row=4'd8;
        end
        else if(in_num_cnt_7>=3'd1 && hc_step_1_row!=4'd7 && hc_step_2_row!=4'd7 && hc_step_3_row!=4'd7 && hc_step_4_row!=4'd7) begin
            hc_num[4]=4'd9; hc_step_5_row=4'd7;
        end
        else if(in_num_cnt_6>=3'd1 && hc_step_1_row!=4'd6 && hc_step_2_row!=4'd6 && hc_step_3_row!=4'd6 && hc_step_4_row!=4'd6) begin
            hc_num[4]=4'd8; hc_step_5_row=4'd6;
        end
        else if(in_num_cnt_5>=3'd1 && hc_step_1_row!=4'd5 && hc_step_2_row!=4'd5 && hc_step_3_row!=4'd5 && hc_step_4_row!=4'd5) begin
            hc_num[4]=4'd7; hc_step_5_row=4'd5;
        end
        else if(in_num_cnt_4>=3'd1 && hc_step_1_row!=4'd4 && hc_step_2_row!=4'd4 && hc_step_3_row!=4'd4 && hc_step_4_row!=4'd4) begin
            hc_num[4]=4'd6; hc_step_5_row=4'd4;
        end
        else if(in_num_cnt_3>=3'd1 && hc_step_1_row!=4'd3 && hc_step_2_row!=4'd3 && hc_step_3_row!=4'd3 && hc_step_4_row!=4'd3) begin
            hc_num[4]=4'd5; hc_step_5_row=4'd3;
        end
        else if(in_num_cnt_2>=3'd1 && hc_step_1_row!=4'd2 && hc_step_2_row!=4'd2 && hc_step_3_row!=4'd2 && hc_step_4_row!=4'd2) begin
            hc_num[4]=4'd4; hc_step_5_row=4'd2;
        end
        else if(in_num_cnt_1>=3'd1 && hc_step_1_row!=4'd1 && hc_step_2_row!=4'd1 && hc_step_3_row!=4'd1 && hc_step_4_row!=4'd1) begin
            hc_num[4]=4'd3; hc_step_5_row=4'd1;
        end
        else if(in_num_cnt_0>=3'd1 && hc_step_1_row!=4'd0 && hc_step_2_row!=4'd0 && hc_step_3_row!=4'd0 && hc_step_4_row!=4'd0) begin
            hc_num[4]=4'd2; hc_step_5_row=4'd0;
        end
        else begin
            hc_num[4]=4'd15; hc_step_5_row=4'd15;
        end
    end

    always@(*)begin
        out_hc_num_0=hc_num[0]; out_hc_num_1=hc_num[1]; out_hc_num_2=hc_num[2];
        out_hc_num_3=hc_num[3]; out_hc_num_4=hc_num[4];
        if(hc_step_1_row!=15 && hc_step_2_row!=15 && hc_step_3_row!=15 && hc_step_4_row!=15 && hc_step_5_row!=15)begin
            hc_exist_bool=1'b1;
        end
        else hc_exist_bool=1'b0;
    end
    //========================================
endmodule