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

//Part 2 CFomb Logic
//依照目前的candidate_map，是否有唯一的候選
reg [3:0] single_cand[0:8][0:8]; //只剩一個candidate(反之則為0)
always@(*)begin
    for(i=0; i<9; i=i+1)begin
        for(j=0; j<9; j=j+1)begin
            if(candidate_map[i][j]==9'b1_0000_0000) single_cand[i][j]=4'd9;
            else if(candidate_map[i][j]==9'b01000_0000)single_cand[i][j]=4'd8;
            else if(candidate_map[i][j]==9'b00100_0000)single_cand[i][j]=4'd7;
            else if(candidate_map[i][j]==9'b00010_0000)single_cand[i][j]=4'd6;
            else if(candidate_map[i][j]==9'b00001_0000)single_cand[i][j]=4'd5;
            else if(candidate_map[i][j]==9'b00000_1000)single_cand[i][j]=4'd4;
            else if(candidate_map[i][j]==9'b00000_0100)single_cand[i][j]=4'd3;
            else if(candidate_map[i][j]==9'b00000_0010)single_cand[i][j]=4'd2;
            else if(candidate_map[i][j]==9'b00000_0001)single_cand[i][j]=4'd1;
            else single_cand[i][j]=4'd0;    //代表不是single solution
        end
    end
end

//PArt 3 Seq Logic
reg [3:0] HN_row_idx, HN_col_idx;
reg [3:0] HN_col_blk_idx, HN_row_blk_idx;   //兩個都是0~2
reg [8:0] HN_check_cand [0:8]; //可以是一個row或是一個col或是一個blk

always@(*)begin
    if(EVAL_HN_tag==2'd1)begin  //去承接目前EVAL_HN在比較的row
        for(i=0;i<9;i=i+1)begin 
            HN_check_cand[i]=candidate_map[HN_row_idx][i];
        end
    end
    else if(EVAL_HN_tag==2'd2)begin  //去承接目前的
        for(i=0;i<9;i=i+1)begin 
            HN_check_cand[i]=candidate_map[HN_row_idx][i];
        end
    end
    else if(EVAL_HN_tag==2'd3)begin  //去承接目前的blk
        HN_check_cand[0]=candidate_map[3*HN_row_idx][3*HN_col_idx];
        HN_check_cand[1]=candidate_map[3*HN_row_idx][3*HN_col_idx+1];
        HN_check_cand[2]=candidate_map[3*HN_row_idx][3*HN_col_idx+2];
        HN_check_cand[3]=candidate_map[3*HN_row_idx+1][3*HN_col_idx];
        HN_check_cand[4]=candidate_map[3*HN_row_idx+1][3*HN_col_idx+1];
        HN_check_cand[5]=candidate_map[3*HN_row_idx+1][3*HN_col_idx+2];
        HN_check_cand[6]=candidate_map[3*HN_row_idx+2][3*HN_col_idx];
        HN_check_cand[7]=candidate_map[3*HN_row_idx+2][3*HN_col_idx+1];
        HN_check_cand[8]=candidate_map[3*HN_row_idx+2][3*HN_col_idx+2];
    end
end

//Part 2 Comb Logic
reg [8:0] only_cand_check [0:8];
//把HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],
//HN_check_cand[3][0], HN_check_cand[4][0], HN_check_cand[5][0],
//HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]拼接起來

always@(*)begin
    for(i=0;i<=9;i=i+1)begin
        only_cand_check[i]=
    end
end
//Part 2 Comb Logic
reg [3:0] only_cand_ele_idx;    //檢查是1~9是否是持有1的唯一的候選
always @(*) begin
    // check 1
    if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b1_0000_0000) only_cand_one=4'd1;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_1000_0000) only_cand_one=4'd2;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0100_0000) only_cand_one=4'd3;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0010_0000) only_cand_one=4'd4;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0001_0000) only_cand_one=4'd5;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0000_1000) only_cand_one=4'd6;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0000_0100) only_cand_one=4'd7;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0000_0010) only_cand_one=4'd8;
    else if({HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],
        HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]}==9'b0_0000_0001) only_cand_one=4'd9;
    else only_cand_one=4'd0;
end


//Part 3 Seq Logic
reg empty_map [0:8][0:8];  //0代表該格是empty
reg [1:0] EVAL_HN_tag; 

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
            empty_map[in_row][in_col]<=1'b1;    //填入了就不是0了
        end
        else begin 
            candidate_map[cur_row][cur_col]<=8'd0;
            empty_map[in_row][in_col]<=empty_map[in_row][in_col];
        end
    end
    //EVAL_cand case 2
    else if(cur_state==EVAL_cand&& cur_col<4'd8)begin
        cur_row<=cur_row; cur_col<=cur_col+4'd1;
        if(empty_map[cur_row][cur_col]==1'b0) begin
            candidate_map[cur_row][cur_col]<=cur_candidate;
            empty_map[in_row][in_col]<=1'b1;    //填入了就不是0了
        end
        else begin 
            candidate_map[cur_row][cur_col]<=8'd0;
            empty_map[in_row][in_col]<=empty_map[in_row][in_col];
        end
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd0)begin   
        //只持續一個cycle
        //case 1: forward且有解 (map接受目前解)
        candidate_map[cur_row][cur_col]<=8'd0; EVAL_HN_tag<=2'd1;
        for(i=0; i<9; i=i+1)begin
            for(j=0; j<9; j=j+1)begin
                //如果目前有確定只有一個解的格子就填入
                if(single_cand[i][j]!=4'd0)candidate_map[i][j]<=single_cand[i][j];
                else candidate_map[i][j]<=candidate_map[i][j];
            end
        end
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd1)begin
        //case 2: forward且無解 (map洗掉目前解)

    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd2)begin
        //case 3: backward且有解 (map接受目前解)

    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3)begin
        //case 4: backward且無解 (map洗掉目前解)

    end
end


endmodule