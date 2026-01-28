module SUDOKU(
    //Input Port
    clk,rst_n,in_valid,in,
    //Output Port
    out_valid,out
);

input clk, rst_n, in_valid;
input [3:0] in;
output reg out_valid;
output reg [3:0] out;

//Part 1 FSM (& tag)
parameter IDLE=3'd0, INPUT=3'd1, EVAL_cand=3'd2, EVAL_HN=3'd3;
parameter OUTPUT=3'd3, CLEAR=3'd4;
reg [6:0] input_cnt, out_cnt;
reg EVAL_cand_done, EVAL_HN_done;
reg [2:0] cur_state, next_state;
reg [3:0] cur_row, cur_col;     //for EVAL_cand
reg [3:0] in_row, in_col;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid==1'b1) next_state=INPUT;
            else next_state=IDLE;
        end
        INPUT: begin 
            if(in_row==4'd8&&in_col==4'd8)next_state=EVAL_cand;
            else next_state=INPUT;
        end
        EVAL_cand: begin
            if(cur_row==4'd8&&cur_col==4'd8)next_state=EVAL_HN;
            else next_state=EVAL_cand;
        end
        EVAL_HN: begin  //hidden and single
            if(EVAL_HN_done==1'b1)next_state=OUTPUT;
            else next_state=EVAL_HN;
        end
        OUTPUT: begin
            if(out_cnt>=7'd80)next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 2 Comb Logic
integer i,j;
reg [3:0] map [0:8][0:8];
reg [1:0] row_to_blk_idx, col_to_blk_idx;
reg [3:0] cur_blk [0:2][0:2];   //用cur_row, cur_col選出cur_blk

always@(*)begin
    if(cur_row>=4'd6)row_to_blk_idx=2'd2;
    else if(cur_row>=4'd3)row_to_blk_idx=2'd1;
    else row_to_blk_idx=2'd0;

    if(cur_col>=4'd6) col_to_blk_idx=2'd2;
    else if(cur_col>=4'd3)col_to_blk_idx=2'd1;
    else col_to_blk_idx=2'd0;
end

always@(*)begin
    for(i=0;i<3;i=i+1)begin
        for(j=0;j<3;j=j+1)begin
            cur_blk[i][j]=map[(3*row_to_blk_idx)+i][(3*col_to_blk_idx)+j];
        end
    end
end

//Part 2 Comb Logic: prev_col、prev_row
reg [8:0] candidate_map [0:8][0:8];
reg [8:0] cur_candidate; //MSB是9 LSB是1

always@(*)begin
    for(i=1;i<10;i=i+1)begin
        if(map[cur_row][0]!=i && map[cur_row][1]!=i && map[cur_row][2]!=i 
        && map[cur_row][3]!=i && map[cur_row][4]!=i && map[cur_row][5]!=i
        && map[cur_row][6]!=i && map[cur_row][7]!=i && map[cur_row][8]!=i
        && map[0][cur_col]!=i && map[1][cur_col]!=i && map[2][cur_col]!=i
        && map[3][cur_col]!=i && map[4][cur_col]!=i && map[5][cur_col]!=i
        && map[6][cur_col]!=i && map[7][cur_col]!=i && map[8][cur_col]!=i
        && cur_blk[0][0]!=i && cur_blk[0][1]!=i && cur_blk[0][2]!=i
        && cur_blk[1][0]!=i && cur_blk[1][1]!=i && cur_blk[1][2]!=i
        && cur_blk[2][0]!=i && cur_blk[2][1]!=i && cur_blk[2][2]!=i)begin
            cur_candidate[i-1]=1'b1;
        end
        else cur_candidate[i-1]=1'b0;
    end
end

//Part 3 Seq Logic
reg empty_map [0:8][0:8];  //0代表該格是empty

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_row<=4'd0; in_col<=4'd0;
        cur_row<=4'd0; cur_col<=4'd0;
    end
    //input case 1 (in_col歸0、in_row+1)
    else if(in_valid==1'b1 && in_col==4'd8)begin
        in_row<=in_row+4'd1; in_col<=4'd0;
        map[in_row][in_col]<=in;
        if(in==4'd0) empty_map[in_row][in_col]<=1'b0;
        else empty_map[in_row][in_col]<=1'b1;
    end
    //input case 2
    else if(in_valid==1'b1 && in_col<4'd8)begin
        in_row<=in_row; in_col<=in_col+4'd1;
        map[in_row][in_col]<=in;
        if(in==4'd0) empty_map[in_row][in_col]<=1'b0;
        else empty_map[in_row][in_col]<=1'b1;
    end
    //EVAL_cand case 1
    else if(cur_state==EVAL_cand && cur_col==4'd8)begin
        cur_row<=cur_row+4'd1; cur_col<=4'd0;
        if(empty_map[cur_row][cur_col]==1'b0) begin
            candidate_map[cur_row][cur_col]<=cur_candidate;
        end
        else candidate_map[cur_row][cur_col]<=8'd0;
    end
    //EVAL_cand case 2
    else if(cur_state==EVAL_cand&& cur_col<4'd8)begin
        cur_row<=cur_row; cur_col<=cur_col+4'd1;
        if(empty_map[cur_row][cur_col]==1'b0) begin
            candidate_map[cur_row][cur_col]<=cur_candidate;
        end
        else candidate_map[cur_row][cur_col]<=8'd0;
    end
    else if(cur_state==EVAL_HN)begin
        //case 1: forward且有解 (map接受目前解)
    end
    else if(cur_state==EVAL_HN)begin
        //case 2 forward且無解 (map洗掉目前解)
    end
    else if(cur_state==EVAL_HN)begin
        //case 3 backward且有解 (map接受目前解)
    end
    else if(cur_state==EVAL_HN)begin
        //case 4 backward且無解 (map洗掉目前解)
    end
end


endmodule