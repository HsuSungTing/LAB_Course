`include "Poker.v"

module WinRate (
    // Input signals
    clk,rst_n,in_valid,in_hole_num,in_hole_suit,in_pub_num,in_pub_suit,
    // Output signals
    out_valid,out_win_rate
);

input clk, rst_n, in_valid;
input [71:0] in_hole_num;
input [35:0] in_hole_suit;
input [11:0] in_pub_num;    
input [5:0] in_pub_suit;    

output reg out_valid;
output reg [62:0] out_win_rate;

//Part 1 FSM (&FSM Tag)
reg [2:0] cur_state, next_state;
parameter IDLE=3'd0, EVAL_rmv_used=3'd1, EVAL_winrate=3'd2, OUTPUT=3'd3, CLEAR=4'd4;

reg [6:0] EVAL_rmv_used_cnt;
reg EVAL_winrate_done;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

//Part 1 FSM
always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid==1'b1) next_state=EVAL;
            else next_state=IDLE;
        end
        EVAL_rmv_used: begin
            if(EVAL_rmv_used_cnt==72)next_state=EVAL_winrate;
            else next_state=EVAL_rmv_used
        end
        EVAL_winrate: begin
            if(EVAL_winrate_done==1'b1) next_state=OUT;
            else next_state=EVAL;
        end
        OUT: next_state=CLEAR;
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 3 Seq
reg [71:0] in_hole_num_q;
reg [35:0] in_hole_suit_q;
reg [11:0] in_pub_num_q;
reg [5:0] in_pub_suit_q;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_hole_num_q<=72'd0; in_hole_suit_q<=36'd0;
        in_pub_num_q<=12'd0; in_pub_suit_q<=6'd0;
    end
    else if(in_valid==1'b1)begin
        in_hole_num_q<=in_hole_num; in_hole_suit_q<=in_hole_suit;
        in_pub_num_q<=in_pub_num; in_pub_suit_q<=in_pub_suit;
    end
    else if(cur_state==CLEAR)begin
        in_hole_num_q<=72'd0; in_hole_suit_q<=36'd0;
        in_pub_num_q<=12'd0; in_pub_suit_q<=6'd0;
    end
end

//Part 2 Comb Logic
//確定的3張公牌
reg [3:0] pub_0_num, pub_1_num, pub_2_num;
reg [1:0] pub_0_suit, pub_1_suit, pub_2_suit;

always@(*)begin
    pub_2_num=in_pub_num_q[3:0];    pub_2_suit=in_pub_suit_q[1:0];
    pub_1_num=in_pub_num_q[7:4];    pub_1_suit=in_pub_suit_q[3:2];
    pub_0_num=in_pub_num_q[11:8];   pub_0_suit=in_pub_suit_q[5:4];
end

//===Part 2 Comb Logic===
//===已經用過的21張牌===
integer i,j;
reg [5:0] used_card [0:20]; //前兩個bit是花色
always@(*)begin
    for(i=0;i<18;i=i+1)begin
        used_card[i]={in_hole_suit_q[2*(i+1)-1-:2],in_hole_num_q[4*(i+1)-1-:4]};
    end
    used_card[18]={pub_0_suit,pub_0_num};
    used_card[19]={pub_1_suit,pub_1_num};
    used_card[20]={pub_2_suit,pub_2_num};
end

//Part 3 Seq Logic for EVAL_winrate
reg [3:0] cur_pub_3_num, cur_pub_4_num;
reg [1:0] cur_pub_3_suit, cur_pub_4_suit;

//Part 2 Comb Logic
wire [8:0] out_winner;
Poker #(.IP_WIDTH(9)) Poker_inst (
    .IN_HOLE_CARD_NUM(in_hole_num_q), .IN_HOLE_CARD_SUIT(in_hole_suit_q),
    .IN_PUB_CARD_NUM({pub_0_num,pub_1_num,pub_2_num,cur_pub_3_num,cur_pub_4_num}),
    .IN_PUB_CARD_SUIT({pub_0_suit,pub_1_suit,pub_2_suit,cur_pub_3_suit,cur_pub_4_suit}),
    .OUT_WINNER(out_winner)
);

//Part 3 Seq Logic
//===EVAL_rmv_used===
reg no_used_map [0:3][0:12];
reg [5:0] remain_31_card [0:30];
reg [5:0] remain_31_card_ptr;
reg [1:0] suit_ptr; //for 掃52個element
reg [3:0] num_ptr;  //for 掃52個element

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===step 1===
        EVAL_rmv_used_cnt<=7'd0;
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<13;j=j+1)begin
                no_used_map[i][j]<=1'b1;
            end
        end
        //===step 2===
        for(i=0;i<31;i=i+1) begin
            remain_31_card[i]<=6'b0;
        end
        remain_31_card_ptr<=6'd0; suit_ptr<=2'd0; num_ptr<=4'd0;
    end
    else if(cur_state==EVAL_rmv_used&&EVAL_rmv_used_cnt<=7'd20)begin
        //case 0 前21個cycle把用過的card remove
        EVAL_rmv_used_cnt<=EVAL_rmv_used_cnt+1'd1;
        if(EVAL_rmv_used_cnt<=7'd20)begin
            no_used_map[used_card[EVAL_rmv_used_cnt][5:4]][used_card[EVAL_rmv_used_cnt][3:0]-2]<=1'b0;
        end
    end
    else if(cur_state==EVAL_rmv_used&&EVAL_rmv_used_cnt>=7'd21&&EVAL_rmv_used_cnt<=7'd72)begin
        //case 1 21-72就是掃過52個格子，找出31個card並記錄
        if(num_ptr==4'd12)begin
            num_ptr<=4'd0; suit_ptr<=suit_ptr+1'd1;
        end
        else begin
            num_ptr<=num_ptr+4'd1; suit_ptr<=suit_ptr;
        end

        if(no_used_map[suit_ptr][num_ptr]==1'b1)begin
            //有找到可以放的就記下來，會恰31個
            remain_31_card_ptr<=remain_31_card_ptr+1'd1;
            remain_31_card[remain_31_card_ptr]<={suit_ptr, (num_ptr+2'd2)};
        end
    end
end

endmodule