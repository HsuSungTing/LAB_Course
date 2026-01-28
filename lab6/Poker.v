module Poker #(parameter IP_WIDTH = 9) (
    // Input signals
    IN_HOLE_CARD_NUM, IN_HOLE_CARD_SUIT, IN_PUB_CARD_NUM, IN_PUB_CARD_SUIT,
    // Output signals
    OUT_WINNER
);

input [IP_WIDTH*8-1:0] IN_HOLE_CARD_NUM;
input [IP_WIDTH*4-1:0] IN_HOLE_CARD_SUIT;
input [19:0] IN_PUB_CARD_NUM;
input [9:0] IN_PUB_CARD_SUIT;
output [IP_WIDTH-1:0] OUT_WINNER;

//Part 2 Comb Logic
reg [3:0] pub_num [0:4];   
reg [1:0] pub_suit[0:4];   

reg [7:0] hole_num [0:IP_WIDTH-1];  
reg [3:0] hole_suit[0:IP_WIDTH-1];  

wire [3:0] out_num [0:4][0:IP_WIDTH-1];    
wire [3:0] out_chosen_type [0:IP_WIDTH-1]; 
wire [23:0] player_score [0:IP_WIDTH-1];   

//===step 1 decode===
always@(*)begin
    pub_num[0]=IN_PUB_CARD_NUM[19:16]; pub_suit[0]=IN_PUB_CARD_SUIT[9:8];
    pub_num[1]=IN_PUB_CARD_NUM[15:12]; pub_suit[1]=IN_PUB_CARD_SUIT[7:6];
    pub_num[2]=IN_PUB_CARD_NUM[11:8];  pub_suit[2]=IN_PUB_CARD_SUIT[5:4]; 
    pub_num[3]=IN_PUB_CARD_NUM[7:4];   pub_suit[3]=IN_PUB_CARD_SUIT[3:2];  
    pub_num[4]=IN_PUB_CARD_NUM[3:0];   pub_suit[4]=IN_PUB_CARD_SUIT[1:0]; 
end 

genvar dc_i;    //decode i
generate
    for(dc_i=0;dc_i<IP_WIDTH;dc_i=dc_i+1)begin
        always@(*)begin
            hole_num[dc_i]= IN_HOLE_CARD_NUM[8*(dc_i+1)-1-:8];
            hole_suit[dc_i]=IN_HOLE_CARD_SUIT[4*(dc_i+1)-1-:4];
        end 
    end
endgenerate

genvar player_i;   
generate
    for(player_i=0;player_i<IP_WIDTH;player_i=player_i+1)begin
        sort_one_player sop_inst(
            .in_num_1(pub_num[0]),.in_num_2(pub_num[1]),.in_num_3(pub_num[2]),.in_num_4(pub_num[3]),.in_num_5(pub_num[4]),
            .in_num_6(hole_num[player_i][7:4]), .in_num_7(hole_num[player_i][3:0]),
            .in_suit_1(pub_suit[0]),.in_suit_2(pub_suit[1]),.in_suit_3(pub_suit[2]),.in_suit_4(pub_suit[3]),.in_suit_5(pub_suit[4]),
            .in_suit_6(hole_suit[player_i][3:2]),.in_suit_7(hole_suit[player_i][1:0]),
            .out_num_1(out_num[0][player_i]),.out_num_2(out_num[1][player_i]),.out_num_3(out_num[2][player_i]), 
            .out_num_4(out_num[3][player_i]),.out_num_5(out_num[4][player_i]),.chosen_type(out_chosen_type[player_i]));
    end
endgenerate

genvar sc_i;   
generate
    for(sc_i=0; sc_i<9; sc_i=sc_i+1)begin
        if(sc_i<IP_WIDTH) begin
            assign player_score[sc_i]= {out_chosen_type[sc_i],out_num[0][sc_i],out_num[1][sc_i],out_num[2][sc_i],out_num[3][sc_i],out_num[4][sc_i]};
        end
        else begin
            assign player_score[sc_i]= 24'd0;
        end
    end
endgenerate

reg player_n_win [0:8];
genvar cmp_i;   
always@(*)begin
    if(player_score[0]>=player_score[1]&&player_score[0]>=player_score[2]&&player_score[0]>=player_score[3]&&player_score[0]>=player_score[4]&&
    player_score[0]>=player_score[5]&&player_score[0]>=player_score[6]&&player_score[0]>=player_score[7]&&player_score[0]>=player_score[8])begin
        player_n_win[0]=1'b1;
    end
    else player_n_win[0]=1'b0;

    if(player_score[1]>=player_score[0]&&player_score[1]>=player_score[2]&&player_score[1]>=player_score[3]&&player_score[1]>=player_score[4]&&
    player_score[1]>=player_score[5]&&player_score[1]>=player_score[6]&&player_score[1]>=player_score[7]&&player_score[1]>=player_score[8])begin
        player_n_win[1]=1'b1;
    end
    else player_n_win[1]=1'b0;

    if(player_score[2]>=player_score[0]&&player_score[2]>=player_score[1]&&player_score[2]>=player_score[3]&&player_score[2]>=player_score[4]&&
    player_score[2]>=player_score[5]&&player_score[2]>=player_score[6]&&player_score[2]>=player_score[7]&&player_score[2]>=player_score[8])begin
        player_n_win[2]=1'b1;
    end
    else player_n_win[2]=1'b0;

    if(player_score[3]>=player_score[0]&&player_score[3]>=player_score[1]&&player_score[3]>=player_score[2]&&player_score[3]>=player_score[4]&&
    player_score[3]>=player_score[5]&&player_score[3]>=player_score[6]&&player_score[3]>=player_score[7]&&player_score[3]>=player_score[8])begin
        player_n_win[3]=1'b1;
    end
    else player_n_win[3]=1'b0;

    if(player_score[4]>=player_score[0]&&player_score[4]>=player_score[1]&&player_score[4]>=player_score[2]&&player_score[4]>=player_score[3]&&
    player_score[4]>=player_score[5]&&player_score[4]>=player_score[6]&&player_score[4]>=player_score[7]&&player_score[4]>=player_score[8])begin
        player_n_win[4]=1'b1;
    end
    else player_n_win[4]=1'b0;

    if(player_score[5]>=player_score[0]&&player_score[5]>=player_score[1]&&player_score[5]>=player_score[2]&&player_score[5]>=player_score[3]&&
    player_score[5]>=player_score[4]&&player_score[5]>=player_score[6]&&player_score[5]>=player_score[7]&&player_score[5]>=player_score[8])begin
        player_n_win[5]=1'b1;
    end
    else player_n_win[5]=1'b0;

    if(player_score[6]>=player_score[0]&&player_score[6]>=player_score[1]&&player_score[6]>=player_score[2]&&player_score[6]>=player_score[3]&&
    player_score[6]>=player_score[4]&&player_score[6]>=player_score[5]&&player_score[6]>=player_score[7]&&player_score[6]>=player_score[8])begin
        player_n_win[6]=1'b1;
    end
    else player_n_win[6]=1'b0;

    if(player_score[7]>=player_score[0]&&player_score[7]>=player_score[1]&&player_score[7]>=player_score[2]&&player_score[7]>=player_score[3]&&
    player_score[7]>=player_score[4]&&player_score[7]>=player_score[5]&&player_score[7]>=player_score[6]&&player_score[7]>=player_score[8])begin
        player_n_win[7]=1'b1;
    end
    else player_n_win[7]=1'b0;

    if(player_score[8]>=player_score[0]&&player_score[8]>=player_score[1]&&player_score[8]>=player_score[2]&&player_score[8]>=player_score[3]&&
    player_score[8]>=player_score[4]&&player_score[8]>=player_score[5]&&player_score[8]>=player_score[6]&&player_score[8]>=player_score[7])begin
        player_n_win[8]=1'b1;
    end
    else player_n_win[8]=1'b0;
end

genvar out_i;
generate
    for(out_i=0; out_i<IP_WIDTH; out_i=out_i+1)begin
        assign OUT_WINNER[out_i]=player_n_win[out_i];
    end
endgenerate

endmodule

module sort_one_player(
    in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7,
    in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7,
    out_num_1, out_num_2, out_num_3, out_num_4, out_num_5, chosen_type //1-11
);

input [3:0] in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7;
input [1:0] in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7;
output reg [3:0] out_num_1, out_num_2, out_num_3, out_num_4, out_num_5;
output reg [3:0] chosen_type;

reg exist_map[0:3][0:12];   
reg [2:0] num_cnt [0:12];   
reg [2:0] suit_cnt [0:3];   

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
reg [3:0] four_kind_step1_used_row; 
reg four_kind_exist_bool;

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

reg three_kind_exist_bool;

//step 1 
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

//step 2 
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

//step 3 
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
reg [3:0] full_hs_step1_used_row; 
reg full_hs_exist_bool;

//step 1 
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

//step 1
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
reg [3:0] two_pair_step1_used_row, two_pair_step2_used_row; 
reg two_pair_exist_bool;

//step 1 
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

//step 2 
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

//step 3 
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
reg [3:0] one_pair_step2_used_row, one_pair_step3_used_row; 
reg one_pair_exist_bool;

//step 1 
always@(*)begin
    one_pair_num[0]=two_pair_num[0]; one_pair_num[1]=two_pair_num[1];
end

//step 2 
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

//step 3 
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

//step 4 
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

//===straight flush(royoal flush)===
reg [1:0] r_or_s_flush_suit_idx;
reg r_or_s_flush_exist_bool_step1;
always@(*)begin
    if(suit_cnt[0]>=4'd5)begin
        r_or_s_flush_suit_idx=2'd0; r_or_s_flush_exist_bool_step1=1'b1;
    end
    else if(suit_cnt[1]>=4'd5)begin
        r_or_s_flush_suit_idx=2'd1; r_or_s_flush_exist_bool_step1=1'b1;
    end
    else if(suit_cnt[2]>=4'd5)begin
        r_or_s_flush_suit_idx=2'd2; r_or_s_flush_exist_bool_step1=1'b1;
    end
    else if(suit_cnt[3]>=4'd5)begin
        r_or_s_flush_suit_idx=2'd3; r_or_s_flush_exist_bool_step1=1'b1;
    end
    else begin
        r_or_s_flush_suit_idx=2'd0; r_or_s_flush_exist_bool_step1=1'b0;
    end
end

wire [3:0] s_flush_num [0:4];
wire r_or_s_flush_exist_bool_step2;

straight straight_inst2(
    .in_num_cnt_0({2'd0,exist_map[r_or_s_flush_suit_idx][0]}),  .in_num_cnt_1({2'd0,exist_map[r_or_s_flush_suit_idx][1]}), 
    .in_num_cnt_2({2'd0,exist_map[r_or_s_flush_suit_idx][2]}),  .in_num_cnt_3({2'd0,exist_map[r_or_s_flush_suit_idx][3]}),
    .in_num_cnt_4({2'd0,exist_map[r_or_s_flush_suit_idx][4]}),  .in_num_cnt_5({2'd0,exist_map[r_or_s_flush_suit_idx][5]}), 
    .in_num_cnt_6({2'd0,exist_map[r_or_s_flush_suit_idx][6]}),  .in_num_cnt_7({2'd0,exist_map[r_or_s_flush_suit_idx][7]}),
    .in_num_cnt_8({2'd0,exist_map[r_or_s_flush_suit_idx][8]}),  .in_num_cnt_9({2'd0,exist_map[r_or_s_flush_suit_idx][9]}), 
    .in_num_cnt_10({2'd0,exist_map[r_or_s_flush_suit_idx][10]}),.in_num_cnt_11({2'd0,exist_map[r_or_s_flush_suit_idx][11]}),
    .in_num_cnt_12({2'd0,exist_map[r_or_s_flush_suit_idx][12]}),
    .out_straight_num_0(s_flush_num[0]), .out_straight_num_1(s_flush_num[1]), 
    .out_straight_num_2(s_flush_num[2]), .out_straight_num_3(s_flush_num[3]), 
    .out_straight_num_4(s_flush_num[4]),.straight_exist_bool(r_or_s_flush_exist_bool_step2)
);

reg royal_flush_bool, straight_flush_bool;

//straight_flush_bool
always@(*)begin
    if(r_or_s_flush_exist_bool_step1==1'b1&&r_or_s_flush_exist_bool_step2==1'b1)straight_flush_bool=1'b1;
    else straight_flush_bool=1'b0;
end

//royal flush
always@(*)begin
    if(s_flush_num[0]==4'd14&&straight_flush_bool==1'b1)royal_flush_bool=1'b1; 
    else royal_flush_bool=1'b0; 
end
//===============================================

//===high card===
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

//===Flush===
//step 1
reg [1:0] flush_suit_idx;
reg flush_suit_exist_bool;
always@(*)begin
    if(suit_cnt[0]>=4'd5)begin
        flush_suit_idx=2'd0; flush_suit_exist_bool=1'b1;
    end
    else if(suit_cnt[1]>=4'd5)begin
        flush_suit_idx=2'd1; flush_suit_exist_bool=1'b1;
    end
    else if(suit_cnt[2]>=4'd5)begin
        flush_suit_idx=2'd2; flush_suit_exist_bool=1'b1;
    end
    else if(suit_cnt[3]>=4'd5)begin
        flush_suit_idx=2'd3; flush_suit_exist_bool=1'b1;
    end
    else begin
        flush_suit_idx=2'd0; flush_suit_exist_bool=1'b0;
    end
end

wire [3:0] final_Flush_num [0:4]; 
wire final_flush_exist_bool;         

//===suit 1===
high_card hc_inst1(
    .in_num_cnt_0({2'd0,exist_map[flush_suit_idx][0]}),  .in_num_cnt_1({2'd0,exist_map[flush_suit_idx][1]}), 
    .in_num_cnt_2({2'd0,exist_map[flush_suit_idx][2]}),  .in_num_cnt_3({2'd0,exist_map[flush_suit_idx][3]}),
    .in_num_cnt_4({2'd0,exist_map[flush_suit_idx][4]}),  .in_num_cnt_5({2'd0,exist_map[flush_suit_idx][5]}), 
    .in_num_cnt_6({2'd0,exist_map[flush_suit_idx][6]}),  .in_num_cnt_7({2'd0,exist_map[flush_suit_idx][7]}),
    .in_num_cnt_8({2'd0,exist_map[flush_suit_idx][8]}),  .in_num_cnt_9({2'd0,exist_map[flush_suit_idx][9]}), 
    .in_num_cnt_10({2'd0,exist_map[flush_suit_idx][10]}),.in_num_cnt_11({2'd0,exist_map[flush_suit_idx][11]}),
    .in_num_cnt_12({2'd0,exist_map[flush_suit_idx][12]}),
    .out_hc_num_0(final_Flush_num[0]), .out_hc_num_1(final_Flush_num[1]), .out_hc_num_2(final_Flush_num[2]),
    .out_hc_num_3(final_Flush_num[3]), .out_hc_num_4(final_Flush_num[4]), .hc_exist_bool(final_flush_exist_bool)
);
//===============

    //===output===
    always@(*)begin
        if(royal_flush_bool==1'b1)begin
            chosen_type=4'd11;
            out_num_1=s_flush_num[0]; out_num_2=s_flush_num[1]; out_num_3=s_flush_num[2];
            out_num_4=s_flush_num[3]; out_num_5=s_flush_num[4];
        end
        else if(straight_flush_bool==1'b1)begin
            chosen_type=4'd10;
            out_num_1=s_flush_num[0]; out_num_2=s_flush_num[1]; out_num_3=s_flush_num[2];
            out_num_4=s_flush_num[3]; out_num_5=s_flush_num[4];
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
        else if(flush_suit_exist_bool==1'b1&&final_flush_exist_bool==1'b1)begin
            chosen_type=4'd7;//final_Flush_num
            out_num_1=final_Flush_num[0]; out_num_2=final_Flush_num[1]; out_num_3=final_Flush_num[2];
            out_num_4=final_Flush_num[3]; out_num_5=final_Flush_num[4];
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
    //===straight===
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