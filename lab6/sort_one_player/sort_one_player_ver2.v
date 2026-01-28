module sort_one_player(
    in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7,
    in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7,
    out_num_1, out_num_2, out_num_3, out_num_4, out_num_5, out_num_6, out_num_7,
    out_suit_1, out_suit_2, out_suit_3, out_suit_4, out_suit_5, out_suit_6, out_suit_7
);

input [3:0] in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7;
input [1:0] in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7;
output reg [3:0] out_num_1, out_num_2, out_num_3, out_num_4, out_num_5, out_num_6, out_num_7;
output reg [1:0] out_suit_1, out_suit_2, out_suit_3, out_suit_4, out_suit_5, out_suit_6, out_suit_7;

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