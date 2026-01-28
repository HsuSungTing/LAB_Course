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
parameter IDLE=3'd0, INPUT=3'd1, EVAL_cand=3'd2, EVAL_HN=3'd3, EVAL_BT=3'd4;
parameter OUTPUT=3'd5, CLEAR=3'd6;
reg EVAL_HN_done, EVAL_BT_done, HN_once_done;
reg [2:0] cur_state, next_state;
reg [3:0] cur_row, cur_col;     //for EVAL_cand
reg [3:0] in_row, in_col;
reg [3:0] out_row, out_col;
reg [6:0] prev_empty_cnt, empty_cnt;

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
            if(HN_once_done==1'b1&&prev_empty_cnt==empty_cnt) next_state=EVAL_BT;
            else if(EVAL_HN_done==1'b1) next_state=OUTPUT;
            else next_state=EVAL_HN;
        end
        EVAL_BT: begin
            if(EVAL_BT_done==1'b1) next_state=OUTPUT;
            else next_state=EVAL_BT;
        end
        OUTPUT: begin
            if(out_row==4'd8&&out_col==4'd8)next_state=CLEAR;
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
reg [3:0] cur_blk [0:2][0:2];   //choose cur_blk with cur_row, cur_col

always@(*)begin
    if(cur_row>=4'd6)row_to_blk_idx=2'd2;
    else if(cur_row>=4'd3)row_to_blk_idx=2'd1;
    else row_to_blk_idx=2'd0;

    if(cur_col>=4'd6) col_to_blk_idx=2'd2;
    else if(cur_col>=4'd3)col_to_blk_idx=2'd1;
    else col_to_blk_idx=2'd0;
end

always@(*)begin
    cur_blk[0][0]=map[(3*row_to_blk_idx)][(3*col_to_blk_idx)];
    cur_blk[0][1]=map[(3*row_to_blk_idx)][(3*col_to_blk_idx)+4'd1];
    cur_blk[0][2]=map[(3*row_to_blk_idx)][(3*col_to_blk_idx)+4'd2];
    cur_blk[1][0]=map[(3*row_to_blk_idx)+4'd1][(3*col_to_blk_idx)];
    cur_blk[1][1]=map[(3*row_to_blk_idx)+4'd1][(3*col_to_blk_idx)+4'd1];
    cur_blk[1][2]=map[(3*row_to_blk_idx)+4'd1][(3*col_to_blk_idx)+4'd2];
    cur_blk[2][0]=map[(3*row_to_blk_idx)+4'd2][(3*col_to_blk_idx)];
    cur_blk[2][1]=map[(3*row_to_blk_idx)+4'd2][(3*col_to_blk_idx)+4'd1];
    cur_blk[2][2]=map[(3*row_to_blk_idx)+4'd2][(3*col_to_blk_idx)+4'd2];
end

//Part 2 Comb Logic: prev_col, prev_row
reg [8:0] candidate_map [0:8][0:8];
reg [8:0] cur_candidate; //MSB is 9 LSB is 1

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

//Part 2 Comb Logic
reg [3:0] cand_ptr [0:8][0:8];    //for BT
reg [3:0] cur_sol;               //for BT
always@(*)begin
    if(cur_candidate[0]==1'b1 && cand_ptr[cur_row][cur_col]<4'd1)cur_sol=4'd1;
    else if(cur_candidate[1]==1'b1 && cand_ptr[cur_row][cur_col]<4'd2)cur_sol=4'd2;
    else if(cur_candidate[2]==1'b1 && cand_ptr[cur_row][cur_col]<4'd3)cur_sol=4'd3;
    else if(cur_candidate[3]==1'b1 && cand_ptr[cur_row][cur_col]<4'd4)cur_sol=4'd4;
    else if(cur_candidate[4]==1'b1 && cand_ptr[cur_row][cur_col]<4'd5)cur_sol=4'd5;
    else if(cur_candidate[5]==1'b1 && cand_ptr[cur_row][cur_col]<4'd6)cur_sol=4'd6;
    else if(cur_candidate[6]==1'b1 && cand_ptr[cur_row][cur_col]<4'd7)cur_sol=4'd7;
    else if(cur_candidate[7]==1'b1 && cand_ptr[cur_row][cur_col]<4'd8)cur_sol=4'd8;
    else if(cur_candidate[8]==1'b1 && cand_ptr[cur_row][cur_col]<4'd9)cur_sol=4'd9;
    else cur_sol=4'd15; //no_solution
end

//Part 2 Comb Logic
reg confirm_map [0:8][0:8];
reg empty_map [0:8][0:8];  //0 means empty
always @(*) begin
    empty_cnt=7'd81-(
    confirm_map[0][0]+confirm_map[0][1]+confirm_map[0][2]+confirm_map[0][3]+confirm_map[0][4]+confirm_map[0][5]+confirm_map[0][6]+confirm_map[0][7]+confirm_map[0][8]
    +confirm_map[1][0]+confirm_map[1][1]+confirm_map[1][2]+confirm_map[1][3]+confirm_map[1][4]+confirm_map[1][5]+confirm_map[1][6]+confirm_map[1][7]+confirm_map[1][8]
    +confirm_map[2][0]+confirm_map[2][1]+confirm_map[2][2]+confirm_map[2][3]+confirm_map[2][4]+confirm_map[2][5]+confirm_map[2][6]+confirm_map[2][7]+confirm_map[2][8]
    +confirm_map[3][0]+confirm_map[3][1]+confirm_map[3][2]+confirm_map[3][3]+confirm_map[3][4]+confirm_map[3][5]+confirm_map[3][6]+confirm_map[3][7]+confirm_map[3][8]
    +confirm_map[4][0]+confirm_map[4][1]+confirm_map[4][2]+confirm_map[4][3]+confirm_map[4][4]+confirm_map[4][5]+confirm_map[4][6]+confirm_map[4][7]+confirm_map[4][8]
    +confirm_map[5][0]+confirm_map[5][1]+confirm_map[5][2]+confirm_map[5][3]+confirm_map[5][4]+confirm_map[5][5]+confirm_map[5][6]+confirm_map[5][7]+confirm_map[5][8]
    +confirm_map[6][0]+confirm_map[6][1]+confirm_map[6][2]+confirm_map[6][3]+confirm_map[6][4]+confirm_map[6][5]+confirm_map[6][6]+confirm_map[6][7]+confirm_map[6][8]
    +confirm_map[7][0]+confirm_map[7][1]+confirm_map[7][2]+confirm_map[7][3]+confirm_map[7][4]+confirm_map[7][5]+confirm_map[7][6]+confirm_map[7][7]+confirm_map[7][8]
    +confirm_map[8][0]+confirm_map[8][1]+confirm_map[8][2]+confirm_map[8][3]+confirm_map[8][4]+confirm_map[8][5]+confirm_map[8][6]+confirm_map[8][7]+confirm_map[8][8]);
end


//Part 2 Comb Logic
reg [3:0] single_cand[0:8][0:8]; //if only candidate(else: 0)
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
            else single_cand[i][j]=4'd0;    //not single solution
        end
    end
end

//PArt 3 Seq Logic
reg [1:0] EVAL_HN_tag;
reg [3:0] HN_row_idx, HN_col_idx;
reg [1:0] HN_col_blk_idx, HN_row_blk_idx;   //0~2
reg [8:0] HN_check_cand [0:8];      //could be a row or a col or a blk

always@(*)begin
    if(EVAL_HN_tag==2'd1)begin      //to store EVAL_HN row
        HN_check_cand[0]=candidate_map[HN_row_idx][0];
        HN_check_cand[1]=candidate_map[HN_row_idx][1];
        HN_check_cand[2]=candidate_map[HN_row_idx][2];
        HN_check_cand[3]=candidate_map[HN_row_idx][3];
        HN_check_cand[4]=candidate_map[HN_row_idx][4];
        HN_check_cand[5]=candidate_map[HN_row_idx][5];
        HN_check_cand[6]=candidate_map[HN_row_idx][6];
        HN_check_cand[7]=candidate_map[HN_row_idx][7];
        HN_check_cand[8]=candidate_map[HN_row_idx][8];
    end
    else if(EVAL_HN_tag==2'd2)begin //to store EVAL_HN col
        HN_check_cand[0]=candidate_map[0][HN_col_idx];
        HN_check_cand[1]=candidate_map[1][HN_col_idx];
        HN_check_cand[2]=candidate_map[2][HN_col_idx];
        HN_check_cand[3]=candidate_map[3][HN_col_idx];
        HN_check_cand[4]=candidate_map[4][HN_col_idx];
        HN_check_cand[5]=candidate_map[5][HN_col_idx];
        HN_check_cand[6]=candidate_map[6][HN_col_idx];
        HN_check_cand[7]=candidate_map[7][HN_col_idx];
        HN_check_cand[8]=candidate_map[8][HN_col_idx];
    end
    else if(EVAL_HN_tag==2'd3)begin //to store EVAL_HN blk
        HN_check_cand[0]= candidate_map[(3*HN_row_blk_idx)][(3*HN_col_blk_idx)];
        HN_check_cand[1]= candidate_map[(3*HN_row_blk_idx)][(3*HN_col_blk_idx)+2'd1];
        HN_check_cand[2]= candidate_map[(3*HN_row_blk_idx)][(3*HN_col_blk_idx)+2'd2];
        HN_check_cand[3]= candidate_map[(3*HN_row_blk_idx)+2'd1][(3*HN_col_blk_idx)];
        HN_check_cand[4]= candidate_map[(3*HN_row_blk_idx)+2'd1][(3*HN_col_blk_idx)+2'd1];
        HN_check_cand[5]= candidate_map[(3*HN_row_blk_idx)+2'd1][(3*HN_col_blk_idx)+2'd2];
        HN_check_cand[6]= candidate_map[(3*HN_row_blk_idx)+2'd2][(3*HN_col_blk_idx)];
        HN_check_cand[7]= candidate_map[(3*HN_row_blk_idx)+2'd2][(3*HN_col_blk_idx)+2'd1];
        HN_check_cand[8]= candidate_map[(3*HN_row_blk_idx)+2'd2][(3*HN_col_blk_idx)+2'd2];
    end
    else begin
        HN_check_cand[0]=9'b0; HN_check_cand[1]=9'b0; HN_check_cand[2]=9'b0; 
        HN_check_cand[3]=9'b0; HN_check_cand[4]=9'b0; HN_check_cand[5]=9'b0;
        HN_check_cand[6]=9'b0; HN_check_cand[7]=9'b0; HN_check_cand[8]=9'b0;
    end
end

//Part 2 Comb Logic
reg [8:0] only_cand_check [0:8];
always @(*) begin
    only_cand_check[0]={HN_check_cand[0][0],HN_check_cand[1][0],HN_check_cand[2][0],HN_check_cand[3][0],HN_check_cand[4][0],HN_check_cand[5][0],HN_check_cand[6][0],HN_check_cand[7][0],HN_check_cand[8][0]};
    only_cand_check[1]={HN_check_cand[0][1],HN_check_cand[1][1],HN_check_cand[2][1],HN_check_cand[3][1],HN_check_cand[4][1],HN_check_cand[5][1],HN_check_cand[6][1],HN_check_cand[7][1],HN_check_cand[8][1]};
    only_cand_check[2]={HN_check_cand[0][2],HN_check_cand[1][2],HN_check_cand[2][2],HN_check_cand[3][2],HN_check_cand[4][2],HN_check_cand[5][2],HN_check_cand[6][2],HN_check_cand[7][2],HN_check_cand[8][2]};
    only_cand_check[3]={HN_check_cand[0][3],HN_check_cand[1][3],HN_check_cand[2][3],HN_check_cand[3][3],HN_check_cand[4][3],HN_check_cand[5][3],HN_check_cand[6][3],HN_check_cand[7][3],HN_check_cand[8][3]};
    only_cand_check[4]={HN_check_cand[0][4],HN_check_cand[1][4],HN_check_cand[2][4],HN_check_cand[3][4],HN_check_cand[4][4],HN_check_cand[5][4],HN_check_cand[6][4],HN_check_cand[7][4],HN_check_cand[8][4]};
    only_cand_check[5]={HN_check_cand[0][5],HN_check_cand[1][5],HN_check_cand[2][5],HN_check_cand[3][5],HN_check_cand[4][5],HN_check_cand[5][5],HN_check_cand[6][5],HN_check_cand[7][5],HN_check_cand[8][5]};
    only_cand_check[6]={HN_check_cand[0][6],HN_check_cand[1][6],HN_check_cand[2][6],HN_check_cand[3][6],HN_check_cand[4][6],HN_check_cand[5][6],HN_check_cand[6][6],HN_check_cand[7][6],HN_check_cand[8][6]};
    only_cand_check[7]={HN_check_cand[0][7],HN_check_cand[1][7],HN_check_cand[2][7],HN_check_cand[3][7],HN_check_cand[4][7],HN_check_cand[5][7],HN_check_cand[6][7],HN_check_cand[7][7],HN_check_cand[8][7]};
    only_cand_check[8]={HN_check_cand[0][8],HN_check_cand[1][8],HN_check_cand[2][8],HN_check_cand[3][8],HN_check_cand[4][8],HN_check_cand[5][8],HN_check_cand[6][8],HN_check_cand[7][8],HN_check_cand[8][8]};
end

//Part 2 Comb Logic
reg [3:0] only_cand_ele[0:8];    
//store value (1~9),idx is the idx of nly_cand_col, nly_cand_row
always @(*) begin
    // digit 0 → bit[8]
    if(only_cand_check[0]==9'b1_0000_0000)      only_cand_ele[0]=4'd1;
    else if(only_cand_check[1]==9'b1_0000_0000) only_cand_ele[0]=4'd2;
    else if(only_cand_check[2]==9'b1_0000_0000) only_cand_ele[0]=4'd3;
    else if(only_cand_check[3]==9'b1_0000_0000) only_cand_ele[0]=4'd4;
    else if(only_cand_check[4]==9'b1_0000_0000) only_cand_ele[0]=4'd5;
    else if(only_cand_check[5]==9'b1_0000_0000) only_cand_ele[0]=4'd6;
    else if(only_cand_check[6]==9'b1_0000_0000) only_cand_ele[0]=4'd7;
    else if(only_cand_check[7]==9'b1_0000_0000) only_cand_ele[0]=4'd8;
    else if(only_cand_check[8]==9'b1_0000_0000) only_cand_ele[0]=4'd9;
    else                                        only_cand_ele[0]=4'd15;
    // digit 1 → bit[7]
    if(only_cand_check[0]==9'b0_1000_0000)      only_cand_ele[1]=4'd1;
    else if(only_cand_check[1]==9'b0_1000_0000) only_cand_ele[1]=4'd2;
    else if(only_cand_check[2]==9'b0_1000_0000) only_cand_ele[1]=4'd3;
    else if(only_cand_check[3]==9'b0_1000_0000) only_cand_ele[1]=4'd4;
    else if(only_cand_check[4]==9'b0_1000_0000) only_cand_ele[1]=4'd5;
    else if(only_cand_check[5]==9'b0_1000_0000) only_cand_ele[1]=4'd6;
    else if(only_cand_check[6]==9'b0_1000_0000) only_cand_ele[1]=4'd7;
    else if(only_cand_check[7]==9'b0_1000_0000) only_cand_ele[1]=4'd8;
    else if(only_cand_check[8]==9'b0_1000_0000) only_cand_ele[1]=4'd9;
    else                                        only_cand_ele[1]=4'd15;
    // digit 2 → bit[6]
    if(only_cand_check[0]==9'b0_0100_0000)      only_cand_ele[2]=4'd1;
    else if(only_cand_check[1]==9'b0_0100_0000) only_cand_ele[2]=4'd2;
    else if(only_cand_check[2]==9'b0_0100_0000) only_cand_ele[2]=4'd3;
    else if(only_cand_check[3]==9'b0_0100_0000) only_cand_ele[2]=4'd4;
    else if(only_cand_check[4]==9'b0_0100_0000) only_cand_ele[2]=4'd5;
    else if(only_cand_check[5]==9'b0_0100_0000) only_cand_ele[2]=4'd6;
    else if(only_cand_check[6]==9'b0_0100_0000) only_cand_ele[2]=4'd7;
    else if(only_cand_check[7]==9'b0_0100_0000) only_cand_ele[2]=4'd8;
    else if(only_cand_check[8]==9'b0_0100_0000) only_cand_ele[2]=4'd9;
    else                                        only_cand_ele[2]=4'd15;
    // digit 3 → bit[5]
    if(only_cand_check[0]==9'b0_0010_0000)      only_cand_ele[3]=4'd1;
    else if(only_cand_check[1]==9'b0_0010_0000) only_cand_ele[3]=4'd2;
    else if(only_cand_check[2]==9'b0_0010_0000) only_cand_ele[3]=4'd3;
    else if(only_cand_check[3]==9'b0_0010_0000) only_cand_ele[3]=4'd4;
    else if(only_cand_check[4]==9'b0_0010_0000) only_cand_ele[3]=4'd5;
    else if(only_cand_check[5]==9'b0_0010_0000) only_cand_ele[3]=4'd6;
    else if(only_cand_check[6]==9'b0_0010_0000) only_cand_ele[3]=4'd7;
    else if(only_cand_check[7]==9'b0_0010_0000) only_cand_ele[3]=4'd8;
    else if(only_cand_check[8]==9'b0_0010_0000) only_cand_ele[3]=4'd9;
    else                                        only_cand_ele[3]=4'd15;
    // digit 4 → bit[4]
    if(only_cand_check[0]==9'b0_0001_0000)      only_cand_ele[4]=4'd1;
    else if(only_cand_check[1]==9'b0_0001_0000) only_cand_ele[4]=4'd2;
    else if(only_cand_check[2]==9'b0_0001_0000) only_cand_ele[4]=4'd3;
    else if(only_cand_check[3]==9'b0_0001_0000) only_cand_ele[4]=4'd4;
    else if(only_cand_check[4]==9'b0_0001_0000) only_cand_ele[4]=4'd5;
    else if(only_cand_check[5]==9'b0_0001_0000) only_cand_ele[4]=4'd6;
    else if(only_cand_check[6]==9'b0_0001_0000) only_cand_ele[4]=4'd7;
    else if(only_cand_check[7]==9'b0_0001_0000) only_cand_ele[4]=4'd8;
    else if(only_cand_check[8]==9'b0_0001_0000) only_cand_ele[4]=4'd9;
    else                                        only_cand_ele[4]=4'd15;
    // digit 5 → bit[3]
    if(only_cand_check[0]==9'b0_0000_1000)      only_cand_ele[5]=4'd1;
    else if(only_cand_check[1]==9'b0_0000_1000) only_cand_ele[5]=4'd2;
    else if(only_cand_check[2]==9'b0_0000_1000) only_cand_ele[5]=4'd3;
    else if(only_cand_check[3]==9'b0_0000_1000) only_cand_ele[5]=4'd4;
    else if(only_cand_check[4]==9'b0_0000_1000) only_cand_ele[5]=4'd5;
    else if(only_cand_check[5]==9'b0_0000_1000) only_cand_ele[5]=4'd6;
    else if(only_cand_check[6]==9'b0_0000_1000) only_cand_ele[5]=4'd7;
    else if(only_cand_check[7]==9'b0_0000_1000) only_cand_ele[5]=4'd8;
    else if(only_cand_check[8]==9'b0_0000_1000) only_cand_ele[5]=4'd9;
    else                                        only_cand_ele[5]=4'd15;
    // digit 6 → bit[2]
    if(only_cand_check[0]==9'b0_0000_0100)      only_cand_ele[6]=4'd1;
    else if(only_cand_check[1]==9'b0_0000_0100) only_cand_ele[6]=4'd2;
    else if(only_cand_check[2]==9'b0_0000_0100) only_cand_ele[6]=4'd3;
    else if(only_cand_check[3]==9'b0_0000_0100) only_cand_ele[6]=4'd4;
    else if(only_cand_check[4]==9'b0_0000_0100) only_cand_ele[6]=4'd5;
    else if(only_cand_check[5]==9'b0_0000_0100) only_cand_ele[6]=4'd6;
    else if(only_cand_check[6]==9'b0_0000_0100) only_cand_ele[6]=4'd7;
    else if(only_cand_check[7]==9'b0_0000_0100) only_cand_ele[6]=4'd8;
    else if(only_cand_check[8]==9'b0_0000_0100) only_cand_ele[6]=4'd9;
    else                                        only_cand_ele[6]=4'd15;
    // digit 7 → bit[1]
    if(only_cand_check[0]==9'b0_0000_0010)      only_cand_ele[7]=4'd1;
    else if(only_cand_check[1]==9'b0_0000_0010) only_cand_ele[7]=4'd2;
    else if(only_cand_check[2]==9'b0_0000_0010) only_cand_ele[7]=4'd3;
    else if(only_cand_check[3]==9'b0_0000_0010) only_cand_ele[7]=4'd4;
    else if(only_cand_check[4]==9'b0_0000_0010) only_cand_ele[7]=4'd5;
    else if(only_cand_check[5]==9'b0_0000_0010) only_cand_ele[7]=4'd6;
    else if(only_cand_check[6]==9'b0_0000_0010) only_cand_ele[7]=4'd7;
    else if(only_cand_check[7]==9'b0_0000_0010) only_cand_ele[7]=4'd8;
    else if(only_cand_check[8]==9'b0_0000_0010) only_cand_ele[7]=4'd9;
    else                                        only_cand_ele[7]=4'd15;
    // digit 8 → bit[0]
    if(only_cand_check[0]==9'b0_0000_0001)      only_cand_ele[8]=4'd1;
    else if(only_cand_check[1]==9'b0_0000_0001) only_cand_ele[8]=4'd2;
    else if(only_cand_check[2]==9'b0_0000_0001) only_cand_ele[8]=4'd3;
    else if(only_cand_check[3]==9'b0_0000_0001) only_cand_ele[8]=4'd4;
    else if(only_cand_check[4]==9'b0_0000_0001) only_cand_ele[8]=4'd5;
    else if(only_cand_check[5]==9'b0_0000_0001) only_cand_ele[8]=4'd6;
    else if(only_cand_check[6]==9'b0_0000_0001) only_cand_ele[8]=4'd7;
    else if(only_cand_check[7]==9'b0_0000_0001) only_cand_ele[8]=4'd8;
    else if(only_cand_check[8]==9'b0_0000_0001) only_cand_ele[8]=4'd9;
    else                                        only_cand_ele[8]=4'd15;
end

//Part 2 Comb Logic: only_cand_ele[i] (only pos info on map)
reg [3:0] only_cand_col [0:8];
reg [3:0] only_cand_row [0:8];

always@(*)begin
    if(EVAL_HN_tag==2'd1)begin   
        only_cand_row[0]=HN_row_idx; only_cand_col[0]=4'd0;
        only_cand_row[1]=HN_row_idx; only_cand_col[1]=4'd1;
        only_cand_row[2]=HN_row_idx; only_cand_col[2]=4'd2;
        only_cand_row[3]=HN_row_idx; only_cand_col[3]=4'd3;
        only_cand_row[4]=HN_row_idx; only_cand_col[4]=4'd4;
        only_cand_row[5]=HN_row_idx; only_cand_col[5]=4'd5;
        only_cand_row[6]=HN_row_idx; only_cand_col[6]=4'd6;
        only_cand_row[7]=HN_row_idx; only_cand_col[7]=4'd7;
        only_cand_row[8]=HN_row_idx; only_cand_col[8]=4'd8;
    end
    else if(EVAL_HN_tag==2'd2)begin  
        only_cand_row[0]=4'd0; only_cand_col[0]=HN_col_idx;
        only_cand_row[1]=4'd1; only_cand_col[1]=HN_col_idx;
        only_cand_row[2]=4'd2; only_cand_col[2]=HN_col_idx;
        only_cand_row[3]=4'd3; only_cand_col[3]=HN_col_idx;
        only_cand_row[4]=4'd4; only_cand_col[4]=HN_col_idx;
        only_cand_row[5]=4'd5; only_cand_col[5]=HN_col_idx;
        only_cand_row[6]=4'd6; only_cand_col[6]=HN_col_idx;
        only_cand_row[7]=4'd7; only_cand_col[7]=HN_col_idx;
        only_cand_row[8]=4'd8; only_cand_col[8]=HN_col_idx;
    end
    else if(EVAL_HN_tag==2'd3)begin 
        only_cand_row[0]=3*HN_row_blk_idx;      only_cand_col[0]=3*HN_col_blk_idx;
        only_cand_row[1]=3*HN_row_blk_idx;      only_cand_col[1]=3*HN_col_blk_idx+1'd1;
        only_cand_row[2]=3*HN_row_blk_idx;      only_cand_col[2]=3*HN_col_blk_idx+2'd2;
        only_cand_row[3]=3*HN_row_blk_idx+1'd1; only_cand_col[3]=3*HN_col_blk_idx;
        only_cand_row[4]=3*HN_row_blk_idx+1'd1; only_cand_col[4]=3*HN_col_blk_idx+1'd1;
        only_cand_row[5]=3*HN_row_blk_idx+1'd1; only_cand_col[5]=3*HN_col_blk_idx+2'd2;
        only_cand_row[6]=3*HN_row_blk_idx+2'd2; only_cand_col[6]=3*HN_col_blk_idx;
        only_cand_row[7]=3*HN_row_blk_idx+2'd2; only_cand_col[7]=3*HN_col_blk_idx+1'd1;
        only_cand_row[8]=3*HN_row_blk_idx+2'd2; only_cand_col[8]=3*HN_col_blk_idx+2'd2;
    end
    else begin
        only_cand_col[0]=4'd15; only_cand_row[0]=4'd15;
        only_cand_col[1]=4'd15; only_cand_row[1]=4'd15;
        only_cand_col[2]=4'd15; only_cand_row[2]=4'd15;
        only_cand_col[3]=4'd15; only_cand_row[3]=4'd15;
        only_cand_col[4]=4'd15; only_cand_row[4]=4'd15;
        only_cand_col[5]=4'd15; only_cand_row[5]=4'd15;
        only_cand_col[6]=4'd15; only_cand_row[6]=4'd15;
        only_cand_col[7]=4'd15; only_cand_row[7]=4'd15;
        only_cand_col[8]=4'd15; only_cand_row[8]=4'd15;
    end
end

//Part 2 Comb Logic
reg full_bool;
always @(*) begin
    if(map[0][0]!=4'd0&&map[0][1]!=4'd0&&map[0][2]!=4'd0&&map[0][3]!=4'd0&&map[0][4]!=4'd0&&map[0][5]!=4'd0&&map[0][6]!=4'd0&&map[0][7]!=4'd0&&map[0][8]!=4'd0&&
       map[1][0]!=4'd0&&map[1][1]!=4'd0&&map[1][2]!=4'd0&&map[1][3]!=4'd0&&map[1][4]!=4'd0&&map[1][5]!=4'd0&&map[1][6]!=4'd0&&map[1][7]!=4'd0&&map[1][8]!=4'd0&&
       map[2][0]!=4'd0&&map[2][1]!=4'd0&&map[2][2]!=4'd0&&map[2][3]!=4'd0&&map[2][4]!=4'd0&&map[2][5]!=4'd0&&map[2][6]!=4'd0&&map[2][7]!=4'd0&&map[2][8]!=4'd0&&
       map[3][0]!=4'd0&&map[3][1]!=4'd0&&map[3][2]!=4'd0&&map[3][3]!=4'd0&&map[3][4]!=4'd0&&map[3][5]!=4'd0&&map[3][6]!=4'd0&&map[3][7]!=4'd0&&map[3][8]!=4'd0&&
       map[4][0]!=4'd0&&map[4][1]!=4'd0&&map[4][2]!=4'd0&&map[4][3]!=4'd0&&map[4][4]!=4'd0&&map[4][5]!=4'd0&&map[4][6]!=4'd0&&map[4][7]!=4'd0&&map[4][8]!=4'd0&&
       map[5][0]!=4'd0&&map[5][1]!=4'd0&&map[5][2]!=4'd0&&map[5][3]!=4'd0&&map[5][4]!=4'd0&&map[5][5]!=4'd0&&map[5][6]!=4'd0&&map[5][7]!=4'd0&&map[5][8]!=4'd0&&
       map[6][0]!=4'd0&&map[6][1]!=4'd0&&map[6][2]!=4'd0&&map[6][3]!=4'd0&&map[6][4]!=4'd0&&map[6][5]!=4'd0&&map[6][6]!=4'd0&&map[6][7]!=4'd0&&map[6][8]!=4'd0&&
       map[7][0]!=4'd0&&map[7][1]!=4'd0&&map[7][2]!=4'd0&&map[7][3]!=4'd0&&map[7][4]!=4'd0&&map[7][5]!=4'd0&&map[7][6]!=4'd0&&map[7][7]!=4'd0&&map[7][8]!=4'd0&&
       map[8][0]!=4'd0&&map[8][1]!=4'd0&&map[8][2]!=4'd0&&map[8][3]!=4'd0&&map[8][4]!=4'd0&&map[8][5]!=4'd0&&map[8][6]!=4'd0&&map[8][7]!=4'd0&&map[8][8]!=4'd0)
        full_bool=1'b1;
    else full_bool=1'b0;
end

//Part 2 Comb Logic
integer m,n;
reg [8:0] updated_map[0:8][0:8];
always@(*)begin
    for(i=0;i<9;i=i+1)begin
        for(j=0;j<9;j=j+1)begin
            updated_map[i][j]=candidate_map[i][j];
            if(EVAL_HN_tag==2'd0)begin
                if(single_cand[i][j]!=4'd0)updated_map[i][j]=4'd0;
                else begin
                    for(m=0;m<9;m=m+1)begin
                        for(n=0;n<9;n=n+1)begin
                            if(single_cand[m][n]!=4'd0 &&
                            (m==i||n==j||((m/3==i/3)&&(n/3==j/3))))begin
                                updated_map[i][j][single_cand[m][n]-1'b1]=1'b0;
                            end
                        end
                    end
                end
            end
            else begin  //row, col, blk reduction
                if(only_cand_ele[0]!=4'd15&&(i==only_cand_row[0]&&j==only_cand_col[0]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[1]!=4'd15&&(i==only_cand_row[1]&&j==only_cand_col[1]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[2]!=4'd15&&(i==only_cand_row[2]&&j==only_cand_col[2]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[3]!=4'd15&&(i==only_cand_row[3]&&j==only_cand_col[3]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[4]!=4'd15&&(i==only_cand_row[4]&&j==only_cand_col[4]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[5]!=4'd15&&(i==only_cand_row[5]&&j==only_cand_col[5]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[6]!=4'd15&&(i==only_cand_row[6]&&j==only_cand_col[6]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[7]!=4'd15&&(i==only_cand_row[7]&&j==only_cand_col[7]))updated_map[i][j]=9'd0;
                else if(only_cand_ele[8]!=4'd15&&(i==only_cand_row[8]&&j==only_cand_col[8]))updated_map[i][j]=9'd0;
                else begin
                    if(only_cand_ele[0]!=4'd15&&(i==only_cand_row[0]||j==only_cand_col[0]||(3*(i/3))+(j/3)==3*(only_cand_row[0]/3)+(only_cand_col[0]/3)))
                        updated_map[i][j][only_cand_ele[0]-1'd1]=1'b0; // wash if command candidate
                    if(only_cand_ele[1]!=4'd15&&(i==only_cand_row[1]||j==only_cand_col[1]||(3*(i/3))+(j/3)==3*(only_cand_row[1]/3)+(only_cand_col[1]/3)))
                        updated_map[i][j][only_cand_ele[1]-1'd1]=1'b0; 
                    if(only_cand_ele[2]!=4'd15&&(i==only_cand_row[2]||j==only_cand_col[2]||(3*(i/3))+(j/3)==3*(only_cand_row[2]/3)+(only_cand_col[2]/3)))
                        updated_map[i][j][only_cand_ele[2]-1'd1]=1'b0; 
                    if(only_cand_ele[3]!=4'd15&&(i==only_cand_row[3]||j==only_cand_col[3]||(3*(i/3))+(j/3)==3*(only_cand_row[3]/3)+(only_cand_col[3]/3)))
                        updated_map[i][j][only_cand_ele[3]-1'd1]=1'b0; 
                    if(only_cand_ele[4]!=4'd15&&(i==only_cand_row[4]||j==only_cand_col[4]||(3*(i/3))+(j/3)==3*(only_cand_row[4]/3)+(only_cand_col[4]/3)))
                        updated_map[i][j][only_cand_ele[4]-1'd1]=1'b0; 
                    if(only_cand_ele[5]!=4'd15&&(i==only_cand_row[5]||j==only_cand_col[5]||(3*(i/3))+(j/3)==3*(only_cand_row[5]/3)+(only_cand_col[5]/3)))
                        updated_map[i][j][only_cand_ele[5]-1'd1]=1'b0; 
                    if(only_cand_ele[6]!=4'd15&&(i==only_cand_row[6]||j==only_cand_col[6]||(3*(i/3))+(j/3)==3*(only_cand_row[6]/3)+(only_cand_col[6]/3)))
                        updated_map[i][j][only_cand_ele[6]-1'd1]=1'b0; 
                    if(only_cand_ele[7]!=4'd15&&(i==only_cand_row[7]||j==only_cand_col[7]||(3*(i/3))+(j/3)==3*(only_cand_row[7]/3)+(only_cand_col[7]/3)))
                        updated_map[i][j][only_cand_ele[7]-1'd1]=1'b0; 
                    if(only_cand_ele[8]!=4'd15&&(i==only_cand_row[8]||j==only_cand_col[8]||(3*(i/3))+(j/3)==3*(only_cand_row[8]/3)+(only_cand_col[8]/3)))
                        updated_map[i][j][only_cand_ele[8]-1'd1]=1'b0; 
                end
            end
        end
    end
end

//Part 2 Comb Logic
reg [3:0] pre_col,pre_row;
reg [3:0] next_col,next_row;
always@(*)begin
    if({cur_row,cur_col}>{4'd8,4'd7}&&empty_map[8][7]==1'b0){pre_row,pre_col}={4'd8,4'd7};
    else if({cur_row,cur_col}>{4'd8,4'd6}&&empty_map[8][6]==1'b0){pre_row,pre_col}={4'd8,4'd6};
    else if({cur_row,cur_col}>{4'd8,4'd5}&&empty_map[8][5]==1'b0){pre_row,pre_col}={4'd8,4'd5};
    else if({cur_row,cur_col}>{4'd8,4'd4}&&empty_map[8][4]==1'b0){pre_row,pre_col}={4'd8,4'd4};
    else if({cur_row,cur_col}>{4'd8,4'd3}&&empty_map[8][3]==1'b0){pre_row,pre_col}={4'd8,4'd3};
    else if({cur_row,cur_col}>{4'd8,4'd2}&&empty_map[8][2]==1'b0){pre_row,pre_col}={4'd8,4'd2};
    else if({cur_row,cur_col}>{4'd8,4'd1}&&empty_map[8][1]==1'b0){pre_row,pre_col}={4'd8,4'd1};
    else if({cur_row,cur_col}>{4'd8,4'd0}&&empty_map[8][0]==1'b0){pre_row,pre_col}={4'd8,4'd0};
    else if({cur_row,cur_col}>{4'd7,4'd8}&&empty_map[7][8]==1'b0){pre_row,pre_col}={4'd7,4'd8};
    else if({cur_row,cur_col}>{4'd7,4'd7}&&empty_map[7][7]==1'b0){pre_row,pre_col}={4'd7,4'd7};
    else if({cur_row,cur_col}>{4'd7,4'd6}&&empty_map[7][6]==1'b0){pre_row,pre_col}={4'd7,4'd6};
    else if({cur_row,cur_col}>{4'd7,4'd5}&&empty_map[7][5]==1'b0){pre_row,pre_col}={4'd7,4'd5};
    else if({cur_row,cur_col}>{4'd7,4'd4}&&empty_map[7][4]==1'b0){pre_row,pre_col}={4'd7,4'd4};
    else if({cur_row,cur_col}>{4'd7,4'd3}&&empty_map[7][3]==1'b0){pre_row,pre_col}={4'd7,4'd3};
    else if({cur_row,cur_col}>{4'd7,4'd2}&&empty_map[7][2]==1'b0){pre_row,pre_col}={4'd7,4'd2};
    else if({cur_row,cur_col}>{4'd7,4'd1}&&empty_map[7][1]==1'b0){pre_row,pre_col}={4'd7,4'd1};
    else if({cur_row,cur_col}>{4'd7,4'd0}&&empty_map[7][0]==1'b0){pre_row,pre_col}={4'd7,4'd0};
    else if({cur_row,cur_col}>{4'd6,4'd8}&&empty_map[6][8]==1'b0){pre_row,pre_col}={4'd6,4'd8};
    else if({cur_row,cur_col}>{4'd6,4'd7}&&empty_map[6][7]==1'b0){pre_row,pre_col}={4'd6,4'd7};
    else if({cur_row,cur_col}>{4'd6,4'd6}&&empty_map[6][6]==1'b0){pre_row,pre_col}={4'd6,4'd6};
    else if({cur_row,cur_col}>{4'd6,4'd5}&&empty_map[6][5]==1'b0){pre_row,pre_col}={4'd6,4'd5};
    else if({cur_row,cur_col}>{4'd6,4'd4}&&empty_map[6][4]==1'b0){pre_row,pre_col}={4'd6,4'd4};
    else if({cur_row,cur_col}>{4'd6,4'd3}&&empty_map[6][3]==1'b0){pre_row,pre_col}={4'd6,4'd3};
    else if({cur_row,cur_col}>{4'd6,4'd2}&&empty_map[6][2]==1'b0){pre_row,pre_col}={4'd6,4'd2};
    else if({cur_row,cur_col}>{4'd6,4'd1}&&empty_map[6][1]==1'b0){pre_row,pre_col}={4'd6,4'd1};
    else if({cur_row,cur_col}>{4'd6,4'd0}&&empty_map[6][0]==1'b0){pre_row,pre_col}={4'd6,4'd0};
    else if({cur_row,cur_col}>{4'd5,4'd8}&&empty_map[5][8]==1'b0){pre_row,pre_col}={4'd5,4'd8};
    else if({cur_row,cur_col}>{4'd5,4'd7}&&empty_map[5][7]==1'b0){pre_row,pre_col}={4'd5,4'd7};
    else if({cur_row,cur_col}>{4'd5,4'd6}&&empty_map[5][6]==1'b0){pre_row,pre_col}={4'd5,4'd6};
    else if({cur_row,cur_col}>{4'd5,4'd5}&&empty_map[5][5]==1'b0){pre_row,pre_col}={4'd5,4'd5};
    else if({cur_row,cur_col}>{4'd5,4'd4}&&empty_map[5][4]==1'b0){pre_row,pre_col}={4'd5,4'd4};
    else if({cur_row,cur_col}>{4'd5,4'd3}&&empty_map[5][3]==1'b0){pre_row,pre_col}={4'd5,4'd3};
    else if({cur_row,cur_col}>{4'd5,4'd2}&&empty_map[5][2]==1'b0){pre_row,pre_col}={4'd5,4'd2};
    else if({cur_row,cur_col}>{4'd5,4'd1}&&empty_map[5][1]==1'b0){pre_row,pre_col}={4'd5,4'd1};
    else if({cur_row,cur_col}>{4'd5,4'd0}&&empty_map[5][0]==1'b0){pre_row,pre_col}={4'd5,4'd0};
    else if({cur_row,cur_col}>{4'd4,4'd8}&&empty_map[4][8]==1'b0){pre_row,pre_col}={4'd4,4'd8};
    else if({cur_row,cur_col}>{4'd4,4'd7}&&empty_map[4][7]==1'b0){pre_row,pre_col}={4'd4,4'd7};
    else if({cur_row,cur_col}>{4'd4,4'd6}&&empty_map[4][6]==1'b0){pre_row,pre_col}={4'd4,4'd6};
    else if({cur_row,cur_col}>{4'd4,4'd5}&&empty_map[4][5]==1'b0){pre_row,pre_col}={4'd4,4'd5};
    else if({cur_row,cur_col}>{4'd4,4'd4}&&empty_map[4][4]==1'b0){pre_row,pre_col}={4'd4,4'd4};
    else if({cur_row,cur_col}>{4'd4,4'd3}&&empty_map[4][3]==1'b0){pre_row,pre_col}={4'd4,4'd3};
    else if({cur_row,cur_col}>{4'd4,4'd2}&&empty_map[4][2]==1'b0){pre_row,pre_col}={4'd4,4'd2};
    else if({cur_row,cur_col}>{4'd4,4'd1}&&empty_map[4][1]==1'b0){pre_row,pre_col}={4'd4,4'd1};
    else if({cur_row,cur_col}>{4'd4,4'd0}&&empty_map[4][0]==1'b0){pre_row,pre_col}={4'd4,4'd0};
    else if({cur_row,cur_col}>{4'd3,4'd8}&&empty_map[3][8]==1'b0){pre_row,pre_col}={4'd3,4'd8};
    else if({cur_row,cur_col}>{4'd3,4'd7}&&empty_map[3][7]==1'b0){pre_row,pre_col}={4'd3,4'd7};
    else if({cur_row,cur_col}>{4'd3,4'd6}&&empty_map[3][6]==1'b0){pre_row,pre_col}={4'd3,4'd6};
    else if({cur_row,cur_col}>{4'd3,4'd5}&&empty_map[3][5]==1'b0){pre_row,pre_col}={4'd3,4'd5};
    else if({cur_row,cur_col}>{4'd3,4'd4}&&empty_map[3][4]==1'b0){pre_row,pre_col}={4'd3,4'd4};
    else if({cur_row,cur_col}>{4'd3,4'd3}&&empty_map[3][3]==1'b0){pre_row,pre_col}={4'd3,4'd3};
    else if({cur_row,cur_col}>{4'd3,4'd2}&&empty_map[3][2]==1'b0){pre_row,pre_col}={4'd3,4'd2};
    else if({cur_row,cur_col}>{4'd3,4'd1}&&empty_map[3][1]==1'b0){pre_row,pre_col}={4'd3,4'd1};
    else if({cur_row,cur_col}>{4'd3,4'd0}&&empty_map[3][0]==1'b0){pre_row,pre_col}={4'd3,4'd0};
    else if({cur_row,cur_col}>{4'd2,4'd8}&&empty_map[2][8]==1'b0){pre_row,pre_col}={4'd2,4'd8};
    else if({cur_row,cur_col}>{4'd2,4'd7}&&empty_map[2][7]==1'b0){pre_row,pre_col}={4'd2,4'd7};
    else if({cur_row,cur_col}>{4'd2,4'd6}&&empty_map[2][6]==1'b0){pre_row,pre_col}={4'd2,4'd6};
    else if({cur_row,cur_col}>{4'd2,4'd5}&&empty_map[2][5]==1'b0){pre_row,pre_col}={4'd2,4'd5};
    else if({cur_row,cur_col}>{4'd2,4'd4}&&empty_map[2][4]==1'b0){pre_row,pre_col}={4'd2,4'd4};
    else if({cur_row,cur_col}>{4'd2,4'd3}&&empty_map[2][3]==1'b0){pre_row,pre_col}={4'd2,4'd3};
    else if({cur_row,cur_col}>{4'd2,4'd2}&&empty_map[2][2]==1'b0){pre_row,pre_col}={4'd2,4'd2};
    else if({cur_row,cur_col}>{4'd2,4'd1}&&empty_map[2][1]==1'b0){pre_row,pre_col}={4'd2,4'd1};
    else if({cur_row,cur_col}>{4'd2,4'd0}&&empty_map[2][0]==1'b0){pre_row,pre_col}={4'd2,4'd0};
    else if({cur_row,cur_col}>{4'd1,4'd8}&&empty_map[1][8]==1'b0){pre_row,pre_col}={4'd1,4'd8};
    else if({cur_row,cur_col}>{4'd1,4'd7}&&empty_map[1][7]==1'b0){pre_row,pre_col}={4'd1,4'd7};
    else if({cur_row,cur_col}>{4'd1,4'd6}&&empty_map[1][6]==1'b0){pre_row,pre_col}={4'd1,4'd6};
    else if({cur_row,cur_col}>{4'd1,4'd5}&&empty_map[1][5]==1'b0){pre_row,pre_col}={4'd1,4'd5};
    else if({cur_row,cur_col}>{4'd1,4'd4}&&empty_map[1][4]==1'b0){pre_row,pre_col}={4'd1,4'd4};
    else if({cur_row,cur_col}>{4'd1,4'd3}&&empty_map[1][3]==1'b0){pre_row,pre_col}={4'd1,4'd3};
    else if({cur_row,cur_col}>{4'd1,4'd2}&&empty_map[1][2]==1'b0){pre_row,pre_col}={4'd1,4'd2};
    else if({cur_row,cur_col}>{4'd1,4'd1}&&empty_map[1][1]==1'b0){pre_row,pre_col}={4'd1,4'd1};
    else if({cur_row,cur_col}>{4'd1,4'd0}&&empty_map[1][0]==1'b0){pre_row,pre_col}={4'd1,4'd0};
    else if({cur_row,cur_col}>{4'd0,4'd8}&&empty_map[0][8]==1'b0){pre_row,pre_col}={4'd0,4'd8};
    else if({cur_row,cur_col}>{4'd0,4'd7}&&empty_map[0][7]==1'b0){pre_row,pre_col}={4'd0,4'd7};
    else if({cur_row,cur_col}>{4'd0,4'd6}&&empty_map[0][6]==1'b0){pre_row,pre_col}={4'd0,4'd6};
    else if({cur_row,cur_col}>{4'd0,4'd5}&&empty_map[0][5]==1'b0){pre_row,pre_col}={4'd0,4'd5};
    else if({cur_row,cur_col}>{4'd0,4'd4}&&empty_map[0][4]==1'b0){pre_row,pre_col}={4'd0,4'd4};
    else if({cur_row,cur_col}>{4'd0,4'd3}&&empty_map[0][3]==1'b0){pre_row,pre_col}={4'd0,4'd3};
    else if({cur_row,cur_col}>{4'd0,4'd2}&&empty_map[0][2]==1'b0){pre_row,pre_col}={4'd0,4'd2};
    else if({cur_row,cur_col}>{4'd0,4'd1}&&empty_map[0][1]==1'b0){pre_row,pre_col}={4'd0,4'd1};
    else if({cur_row,cur_col}>{4'd0,4'd0}&&empty_map[0][0]==1'b0){pre_row,pre_col}={4'd0,4'd0};
    else {pre_row,pre_col}={4'd15,4'd15};
end

always @(*) begin
    if({cur_row,cur_col}<{4'd0,4'd1} && empty_map[0][1]==1'b0) {next_row,next_col}={4'd0,4'd1};
    else if({cur_row,cur_col}<{4'd0,4'd2} && empty_map[0][2]==1'b0) {next_row,next_col}={4'd0,4'd2};
    else if({cur_row,cur_col}<{4'd0,4'd3} && empty_map[0][3]==1'b0) {next_row,next_col}={4'd0,4'd3};
    else if({cur_row,cur_col}<{4'd0,4'd4} && empty_map[0][4]==1'b0) {next_row,next_col}={4'd0,4'd4};
    else if({cur_row,cur_col}<{4'd0,4'd5} && empty_map[0][5]==1'b0) {next_row,next_col}={4'd0,4'd5};
    else if({cur_row,cur_col}<{4'd0,4'd6} && empty_map[0][6]==1'b0) {next_row,next_col}={4'd0,4'd6};
    else if({cur_row,cur_col}<{4'd0,4'd7} && empty_map[0][7]==1'b0) {next_row,next_col}={4'd0,4'd7};
    else if({cur_row,cur_col}<{4'd0,4'd8} && empty_map[0][8]==1'b0) {next_row,next_col}={4'd0,4'd8};
    else if({cur_row,cur_col}<{4'd1,4'd0} && empty_map[1][0]==1'b0) {next_row,next_col}={4'd1,4'd0};
    else if({cur_row,cur_col}<{4'd1,4'd1} && empty_map[1][1]==1'b0) {next_row,next_col}={4'd1,4'd1};
    else if({cur_row,cur_col}<{4'd1,4'd2} && empty_map[1][2]==1'b0) {next_row,next_col}={4'd1,4'd2};
    else if({cur_row,cur_col}<{4'd1,4'd3} && empty_map[1][3]==1'b0) {next_row,next_col}={4'd1,4'd3};
    else if({cur_row,cur_col}<{4'd1,4'd4} && empty_map[1][4]==1'b0) {next_row,next_col}={4'd1,4'd4};
    else if({cur_row,cur_col}<{4'd1,4'd5} && empty_map[1][5]==1'b0) {next_row,next_col}={4'd1,4'd5};
    else if({cur_row,cur_col}<{4'd1,4'd6} && empty_map[1][6]==1'b0) {next_row,next_col}={4'd1,4'd6};
    else if({cur_row,cur_col}<{4'd1,4'd7} && empty_map[1][7]==1'b0) {next_row,next_col}={4'd1,4'd7};
    else if({cur_row,cur_col}<{4'd1,4'd8} && empty_map[1][8]==1'b0) {next_row,next_col}={4'd1,4'd8};
    else if({cur_row,cur_col}<{4'd2,4'd0} && empty_map[2][0]==1'b0) {next_row,next_col}={4'd2,4'd0};
    else if({cur_row,cur_col}<{4'd2,4'd1} && empty_map[2][1]==1'b0) {next_row,next_col}={4'd2,4'd1};
    else if({cur_row,cur_col}<{4'd2,4'd2} && empty_map[2][2]==1'b0) {next_row,next_col}={4'd2,4'd2};
    else if({cur_row,cur_col}<{4'd2,4'd3} && empty_map[2][3]==1'b0) {next_row,next_col}={4'd2,4'd3};
    else if({cur_row,cur_col}<{4'd2,4'd4} && empty_map[2][4]==1'b0) {next_row,next_col}={4'd2,4'd4};
    else if({cur_row,cur_col}<{4'd2,4'd5} && empty_map[2][5]==1'b0) {next_row,next_col}={4'd2,4'd5};
    else if({cur_row,cur_col}<{4'd2,4'd6} && empty_map[2][6]==1'b0) {next_row,next_col}={4'd2,4'd6};
    else if({cur_row,cur_col}<{4'd2,4'd7} && empty_map[2][7]==1'b0) {next_row,next_col}={4'd2,4'd7};
    else if({cur_row,cur_col}<{4'd2,4'd8} && empty_map[2][8]==1'b0) {next_row,next_col}={4'd2,4'd8};
    else if({cur_row,cur_col}<{4'd3,4'd0} && empty_map[3][0]==1'b0) {next_row,next_col}={4'd3,4'd0};
    else if({cur_row,cur_col}<{4'd3,4'd1} && empty_map[3][1]==1'b0) {next_row,next_col}={4'd3,4'd1};
    else if({cur_row,cur_col}<{4'd3,4'd2} && empty_map[3][2]==1'b0) {next_row,next_col}={4'd3,4'd2};
    else if({cur_row,cur_col}<{4'd3,4'd3} && empty_map[3][3]==1'b0) {next_row,next_col}={4'd3,4'd3};
    else if({cur_row,cur_col}<{4'd3,4'd4} && empty_map[3][4]==1'b0) {next_row,next_col}={4'd3,4'd4};
    else if({cur_row,cur_col}<{4'd3,4'd5} && empty_map[3][5]==1'b0) {next_row,next_col}={4'd3,4'd5};
    else if({cur_row,cur_col}<{4'd3,4'd6} && empty_map[3][6]==1'b0) {next_row,next_col}={4'd3,4'd6};
    else if({cur_row,cur_col}<{4'd3,4'd7} && empty_map[3][7]==1'b0) {next_row,next_col}={4'd3,4'd7};
    else if({cur_row,cur_col}<{4'd3,4'd8} && empty_map[3][8]==1'b0) {next_row,next_col}={4'd3,4'd8};
    else if({cur_row,cur_col}<{4'd4,4'd0} && empty_map[4][0]==1'b0) {next_row,next_col}={4'd4,4'd0};
    else if({cur_row,cur_col}<{4'd4,4'd1} && empty_map[4][1]==1'b0) {next_row,next_col}={4'd4,4'd1};
    else if({cur_row,cur_col}<{4'd4,4'd2} && empty_map[4][2]==1'b0) {next_row,next_col}={4'd4,4'd2};
    else if({cur_row,cur_col}<{4'd4,4'd3} && empty_map[4][3]==1'b0) {next_row,next_col}={4'd4,4'd3};
    else if({cur_row,cur_col}<{4'd4,4'd4} && empty_map[4][4]==1'b0) {next_row,next_col}={4'd4,4'd4};
    else if({cur_row,cur_col}<{4'd4,4'd5} && empty_map[4][5]==1'b0) {next_row,next_col}={4'd4,4'd5};
    else if({cur_row,cur_col}<{4'd4,4'd6} && empty_map[4][6]==1'b0) {next_row,next_col}={4'd4,4'd6};
    else if({cur_row,cur_col}<{4'd4,4'd7} && empty_map[4][7]==1'b0) {next_row,next_col}={4'd4,4'd7};
    else if({cur_row,cur_col}<{4'd4,4'd8} && empty_map[4][8]==1'b0) {next_row,next_col}={4'd4,4'd8};
    else if({cur_row,cur_col}<{4'd5,4'd0} && empty_map[5][0]==1'b0) {next_row,next_col}={4'd5,4'd0};
    else if({cur_row,cur_col}<{4'd5,4'd1} && empty_map[5][1]==1'b0) {next_row,next_col}={4'd5,4'd1};
    else if({cur_row,cur_col}<{4'd5,4'd2} && empty_map[5][2]==1'b0) {next_row,next_col}={4'd5,4'd2};
    else if({cur_row,cur_col}<{4'd5,4'd3} && empty_map[5][3]==1'b0) {next_row,next_col}={4'd5,4'd3};
    else if({cur_row,cur_col}<{4'd5,4'd4} && empty_map[5][4]==1'b0) {next_row,next_col}={4'd5,4'd4};
    else if({cur_row,cur_col}<{4'd5,4'd5} && empty_map[5][5]==1'b0) {next_row,next_col}={4'd5,4'd5};
    else if({cur_row,cur_col}<{4'd5,4'd6} && empty_map[5][6]==1'b0) {next_row,next_col}={4'd5,4'd6};
    else if({cur_row,cur_col}<{4'd5,4'd7} && empty_map[5][7]==1'b0) {next_row,next_col}={4'd5,4'd7};
    else if({cur_row,cur_col}<{4'd5,4'd8} && empty_map[5][8]==1'b0) {next_row,next_col}={4'd5,4'd8};
    else if({cur_row,cur_col}<{4'd6,4'd0} && empty_map[6][0]==1'b0) {next_row,next_col}={4'd6,4'd0};
    else if({cur_row,cur_col}<{4'd6,4'd1} && empty_map[6][1]==1'b0) {next_row,next_col}={4'd6,4'd1};
    else if({cur_row,cur_col}<{4'd6,4'd2} && empty_map[6][2]==1'b0) {next_row,next_col}={4'd6,4'd2};
    else if({cur_row,cur_col}<{4'd6,4'd3} && empty_map[6][3]==1'b0) {next_row,next_col}={4'd6,4'd3};
    else if({cur_row,cur_col}<{4'd6,4'd4} && empty_map[6][4]==1'b0) {next_row,next_col}={4'd6,4'd4};
    else if({cur_row,cur_col}<{4'd6,4'd5} && empty_map[6][5]==1'b0) {next_row,next_col}={4'd6,4'd5};
    else if({cur_row,cur_col}<{4'd6,4'd6} && empty_map[6][6]==1'b0) {next_row,next_col}={4'd6,4'd6};
    else if({cur_row,cur_col}<{4'd6,4'd7} && empty_map[6][7]==1'b0) {next_row,next_col}={4'd6,4'd7};
    else if({cur_row,cur_col}<{4'd6,4'd8} && empty_map[6][8]==1'b0) {next_row,next_col}={4'd6,4'd8};
    else if({cur_row,cur_col}<{4'd7,4'd0} && empty_map[7][0]==1'b0) {next_row,next_col}={4'd7,4'd0};
    else if({cur_row,cur_col}<{4'd7,4'd1} && empty_map[7][1]==1'b0) {next_row,next_col}={4'd7,4'd1};
    else if({cur_row,cur_col}<{4'd7,4'd2} && empty_map[7][2]==1'b0) {next_row,next_col}={4'd7,4'd2};
    else if({cur_row,cur_col}<{4'd7,4'd3} && empty_map[7][3]==1'b0) {next_row,next_col}={4'd7,4'd3};
    else if({cur_row,cur_col}<{4'd7,4'd4} && empty_map[7][4]==1'b0) {next_row,next_col}={4'd7,4'd4};
    else if({cur_row,cur_col}<{4'd7,4'd5} && empty_map[7][5]==1'b0) {next_row,next_col}={4'd7,4'd5};
    else if({cur_row,cur_col}<{4'd7,4'd6} && empty_map[7][6]==1'b0) {next_row,next_col}={4'd7,4'd6};
    else if({cur_row,cur_col}<{4'd7,4'd7} && empty_map[7][7]==1'b0) {next_row,next_col}={4'd7,4'd7};
    else if({cur_row,cur_col}<{4'd7,4'd8} && empty_map[7][8]==1'b0) {next_row,next_col}={4'd7,4'd8};
    else if({cur_row,cur_col}<{4'd8,4'd0} && empty_map[8][0]==1'b0) {next_row,next_col}={4'd8,4'd0};
    else if({cur_row,cur_col}<{4'd8,4'd1} && empty_map[8][1]==1'b0) {next_row,next_col}={4'd8,4'd1};
    else if({cur_row,cur_col}<{4'd8,4'd2} && empty_map[8][2]==1'b0) {next_row,next_col}={4'd8,4'd2};
    else if({cur_row,cur_col}<{4'd8,4'd3} && empty_map[8][3]==1'b0) {next_row,next_col}={4'd8,4'd3};
    else if({cur_row,cur_col}<{4'd8,4'd4} && empty_map[8][4]==1'b0) {next_row,next_col}={4'd8,4'd4};
    else if({cur_row,cur_col}<{4'd8,4'd5} && empty_map[8][5]==1'b0) {next_row,next_col}={4'd8,4'd5};
    else if({cur_row,cur_col}<{4'd8,4'd6} && empty_map[8][6]==1'b0) {next_row,next_col}={4'd8,4'd6};
    else if({cur_row,cur_col}<{4'd8,4'd7} && empty_map[8][7]==1'b0) {next_row,next_col}={4'd8,4'd7};
    else if({cur_row,cur_col}<{4'd8,4'd8} && empty_map[8][8]==1'b0) {next_row,next_col}={4'd8,4'd8};
    else {next_row,next_col}={4'd15,4'd15};
end

//Part 3 Seq Logic
reg forward;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_row<=4'd0; in_col<=4'd0; cur_row<=4'd0; cur_col<=4'd0;
        HN_row_idx<=4'd0; HN_col_idx<=4'd0;
        HN_row_blk_idx<=2'd0; HN_col_blk_idx<=2'd0;  
        EVAL_HN_tag<=2'd0; HN_once_done<=1'b0; EVAL_HN_done<=1'b0; 
        forward<=1'b1; EVAL_BT_done<=1'b0; prev_empty_cnt<=4'd0;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=9'd0; cand_ptr[i][j]<=4'd0;
                map[i][j]<=4'd0; empty_map[i][j]<=1'b0;
            end
        end
    end
    //input case 1 (in_col歸0、in_row+1)
    else if(in_valid==1'b1 && in_col==4'd8)begin
        in_row<=in_row+4'd1; in_col<=4'd0; map[in_row][in_col]<=in;
        if(in==4'd0)empty_map[in_row][in_col]<=1'b0; 
        else empty_map[in_row][in_col]<=1'b1; 
    end
    //input case 2
    else if(in_valid==1'b1 && in_col<4'd8)begin
        in_row<=in_row; in_col<=in_col+4'd1; map[in_row][in_col]<=in;
        if(in==4'd0) empty_map[in_row][in_col]<=1'b0; 
        else empty_map[in_row][in_col]<=1'b1; 
    end
    //EVAL_cand case 1 (找candiadte而已)
    else if(cur_state==EVAL_cand && cur_col==4'd8)begin
        cur_row<=cur_row+4'd1; cur_col<=4'd0;
        if(empty_map[cur_row][cur_col]==1'b0) candidate_map[cur_row][cur_col]<=cur_candidate;
        else candidate_map[cur_row][cur_col]<=8'd0;  
    end
    //EVAL_cand case 2 (找candiadte而已)
    else if(cur_state==EVAL_cand&& cur_col<4'd8)begin
        cur_row<=cur_row; cur_col<=cur_col+4'd1;
        if(empty_map[cur_row][cur_col]==1'b0) candidate_map[cur_row][cur_col]<=cur_candidate;
        else candidate_map[cur_row][cur_col]<=8'd0;
    end
    //case 5 做完
    else if(cur_state==EVAL_HN && full_bool==1'b1)begin
        EVAL_HN_done<=1'b1; //done
    end
    //case 4 做完一次
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3 && HN_once_done==1'b1)begin
        cur_row<=4'd0; cur_col<=4'd0;   //for BT
        HN_once_done<=1'b0; EVAL_HN_tag<=2'd0; prev_empty_cnt<=empty_cnt;
        HN_row_idx<=4'd0; HN_col_idx<=4'd0; HN_row_blk_idx<=2'd0; HN_col_blk_idx<=2'd0;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                confirm_map[i][j]<=empty_map[i][j]; //之後修改都是改在empty_map
            end
        end
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd0)begin   
        //case 1: nake_single (只持續一個cycle)
        candidate_map[cur_row][cur_col]<=8'd0; EVAL_HN_tag<=2'd1;
        for(i=0; i<9; i=i+1)begin
            for(j=0; j<9; j=j+1)begin   
                if(single_cand[i][j]!=4'd0)begin
                    map[i][j]<=single_cand[i][j]; empty_map[i][j]<=1'b1;
                end
                else begin 
                    map[i][j]<=map[i][j]; empty_map[i][j]<=empty_map[i][j];
                end
            end
        end
        for(i=0; i<9; i=i+1)begin
            for(j=0; j<9; j=j+1)begin   
                candidate_map[i][j]<=updated_map[i][j];
            end
        end
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd1 && HN_row_idx<=4'd8)begin
        //case 2: check_row_HN
        if(only_cand_ele[0]!=4'd15)begin map[only_cand_row[0]][only_cand_col[0]]<=only_cand_ele[0]; empty_map[only_cand_row[0]][only_cand_col[0]]<=1'b1;end //唯一候選1
        if(only_cand_ele[1]!=4'd15)begin map[only_cand_row[1]][only_cand_col[1]]<=only_cand_ele[1]; empty_map[only_cand_row[1]][only_cand_col[1]]<=1'b1;end //唯一候選2
        if(only_cand_ele[2]!=4'd15)begin map[only_cand_row[2]][only_cand_col[2]]<=only_cand_ele[2]; empty_map[only_cand_row[2]][only_cand_col[2]]<=1'b1;end //唯一候選3
        if(only_cand_ele[3]!=4'd15)begin map[only_cand_row[3]][only_cand_col[3]]<=only_cand_ele[3]; empty_map[only_cand_row[3]][only_cand_col[3]]<=1'b1;end //唯一候選4
        if(only_cand_ele[4]!=4'd15)begin map[only_cand_row[4]][only_cand_col[4]]<=only_cand_ele[4]; empty_map[only_cand_row[4]][only_cand_col[4]]<=1'b1;end //唯一候選5
        if(only_cand_ele[5]!=4'd15)begin map[only_cand_row[5]][only_cand_col[5]]<=only_cand_ele[5]; empty_map[only_cand_row[5]][only_cand_col[5]]<=1'b1;end //唯一候選6
        if(only_cand_ele[6]!=4'd15)begin map[only_cand_row[6]][only_cand_col[6]]<=only_cand_ele[6]; empty_map[only_cand_row[6]][only_cand_col[6]]<=1'b1;end //唯一候選7
        if(only_cand_ele[7]!=4'd15)begin map[only_cand_row[7]][only_cand_col[7]]<=only_cand_ele[7]; empty_map[only_cand_row[7]][only_cand_col[7]]<=1'b1;end //唯一候選8
        if(only_cand_ele[8]!=4'd15)begin map[only_cand_row[8]][only_cand_col[8]]<=only_cand_ele[8]; empty_map[only_cand_row[8]][only_cand_col[8]]<=1'b1;end //唯一候選9
        HN_row_idx<= HN_row_idx+1'd1;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=updated_map[i][j]; 
            end
        end
        if(HN_row_idx==4'd8) EVAL_HN_tag<=2'd2;
        else  EVAL_HN_tag<=EVAL_HN_tag;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd2 && HN_col_idx<=4'd8)begin
        //case 3: check_col_HN
        if(only_cand_ele[0]!=4'd15)begin map[only_cand_row[0]][only_cand_col[0]]<=only_cand_ele[0]; empty_map[only_cand_row[0]][only_cand_col[0]]<=1'b1;end //唯一候選1
        if(only_cand_ele[1]!=4'd15)begin map[only_cand_row[1]][only_cand_col[1]]<=only_cand_ele[1]; empty_map[only_cand_row[1]][only_cand_col[1]]<=1'b1;end //唯一候選2
        if(only_cand_ele[2]!=4'd15)begin map[only_cand_row[2]][only_cand_col[2]]<=only_cand_ele[2]; empty_map[only_cand_row[2]][only_cand_col[2]]<=1'b1;end //唯一候選3
        if(only_cand_ele[3]!=4'd15)begin map[only_cand_row[3]][only_cand_col[3]]<=only_cand_ele[3]; empty_map[only_cand_row[3]][only_cand_col[3]]<=1'b1;end //唯一候選4
        if(only_cand_ele[4]!=4'd15)begin map[only_cand_row[4]][only_cand_col[4]]<=only_cand_ele[4]; empty_map[only_cand_row[4]][only_cand_col[4]]<=1'b1;end //唯一候選5
        if(only_cand_ele[5]!=4'd15)begin map[only_cand_row[5]][only_cand_col[5]]<=only_cand_ele[5]; empty_map[only_cand_row[5]][only_cand_col[5]]<=1'b1;end //唯一候選6
        if(only_cand_ele[6]!=4'd15)begin map[only_cand_row[6]][only_cand_col[6]]<=only_cand_ele[6]; empty_map[only_cand_row[6]][only_cand_col[6]]<=1'b1;end //唯一候選7
        if(only_cand_ele[7]!=4'd15)begin map[only_cand_row[7]][only_cand_col[7]]<=only_cand_ele[7]; empty_map[only_cand_row[7]][only_cand_col[7]]<=1'b1;end //唯一候選8
        if(only_cand_ele[8]!=4'd15)begin map[only_cand_row[8]][only_cand_col[8]]<=only_cand_ele[8]; empty_map[only_cand_row[8]][only_cand_col[8]]<=1'b1;end //唯一候選9
        HN_col_idx<= HN_col_idx+1'd1;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=updated_map[i][j];
            end
        end
        if(HN_col_idx==4'd8) EVAL_HN_tag<=2'd3;
        else EVAL_HN_tag<=EVAL_HN_tag;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3)begin
        //case 4: check_blk_HN
        if(only_cand_ele[0]!=4'd15)begin map[only_cand_row[0]][only_cand_col[0]]<=only_cand_ele[0]; empty_map[only_cand_row[0]][only_cand_col[0]]<=1'b1;end //唯一候選1
        if(only_cand_ele[1]!=4'd15)begin map[only_cand_row[1]][only_cand_col[1]]<=only_cand_ele[1]; empty_map[only_cand_row[1]][only_cand_col[1]]<=1'b1;end //唯一候選2
        if(only_cand_ele[2]!=4'd15)begin map[only_cand_row[2]][only_cand_col[2]]<=only_cand_ele[2]; empty_map[only_cand_row[2]][only_cand_col[2]]<=1'b1;end //唯一候選3
        if(only_cand_ele[3]!=4'd15)begin map[only_cand_row[3]][only_cand_col[3]]<=only_cand_ele[3]; empty_map[only_cand_row[3]][only_cand_col[3]]<=1'b1;end //唯一候選4
        if(only_cand_ele[4]!=4'd15)begin map[only_cand_row[4]][only_cand_col[4]]<=only_cand_ele[4]; empty_map[only_cand_row[4]][only_cand_col[4]]<=1'b1;end //唯一候選5
        if(only_cand_ele[5]!=4'd15)begin map[only_cand_row[5]][only_cand_col[5]]<=only_cand_ele[5]; empty_map[only_cand_row[5]][only_cand_col[5]]<=1'b1;end //唯一候選6
        if(only_cand_ele[6]!=4'd15)begin map[only_cand_row[6]][only_cand_col[6]]<=only_cand_ele[6]; empty_map[only_cand_row[6]][only_cand_col[6]]<=1'b1;end //唯一候選7
        if(only_cand_ele[7]!=4'd15)begin map[only_cand_row[7]][only_cand_col[7]]<=only_cand_ele[7]; empty_map[only_cand_row[7]][only_cand_col[7]]<=1'b1;end //唯一候選8
        if(only_cand_ele[8]!=4'd15)begin map[only_cand_row[8]][only_cand_col[8]]<=only_cand_ele[8]; empty_map[only_cand_row[8]][only_cand_col[8]]<=1'b1;end //唯一候選9
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=updated_map[i][j];
            end
        end
        if(HN_row_blk_idx==2'd2&&HN_col_blk_idx==2'd2)HN_once_done<=1'b1;
        else HN_once_done<=HN_once_done;
        if(HN_col_blk_idx==2'd2)begin
            HN_col_blk_idx<=2'd0; HN_row_blk_idx<=HN_row_blk_idx+2'd1;
        end
        else begin
            HN_col_blk_idx<=HN_col_blk_idx+2'd1; HN_row_blk_idx<=HN_row_blk_idx;
        end
    end
    else if(cur_state==EVAL_BT&&empty_cnt==7'd0)begin
        //BT case 0 done
        EVAL_BT_done<=1'b1;
    end
    else if(cur_state==EVAL_BT&&cur_row==4'd0&&cur_col==4'd0&&empty_map[0][0]==1'b0)begin
        //BT case 0-1 done
        map[cur_row][cur_col]<=cur_sol; confirm_map[cur_row][cur_col]<=1'b1;
        cand_ptr[cur_row][cur_col]<=cur_sol;
        cur_row<=next_row; cur_col<=next_col; forward<=1'b1;
    end
    else if(cur_state==EVAL_BT&&cur_row==4'd0&&cur_col==4'd0&&empty_map[0][0]==1'b1)begin
        //BT case 0-2 done
        cur_row<=next_row; cur_col<=next_col; forward<=1'b1;
    end
    else if(cur_state==EVAL_BT && forward==1'b1&&cur_sol!=4'd15)begin
        //BT case 1 forward且有解，紀錄目前的解並往前
        map[cur_row][cur_col]<=cur_sol; confirm_map[cur_row][cur_col]<=1'b1;
        cand_ptr[cur_row][cur_col]<=cur_sol;
        cur_row<=next_row; cur_col<=next_col; forward<=1'b1;
    end
    else if(cur_state==EVAL_BT && forward==1'b1&&cur_sol==4'd15)begin
        //BT case 2 forward且無解，洗掉目前的格子並開始往後
        map[cur_row][cur_col]<=4'd0; confirm_map[cur_row][cur_col]<=1'b0;
        cand_ptr[cur_row][cur_col]<=4'd0;
        cur_row<=pre_row; cur_col<=pre_col; forward<=1'b0;
    end
    else if(cur_state==EVAL_BT && forward==1'b0&&cur_sol!=4'd15)begin
        //BT case 3 backward且有解，紀錄目前的解並往前
        map[cur_row][cur_col]<=cur_sol; confirm_map[cur_row][cur_col]<=1'b1;
        cand_ptr[cur_row][cur_col]<=cur_sol;
        cur_row<=next_row; cur_col<=next_col; forward<=1'b1;
    end
    else if(cur_state==EVAL_BT && forward==1'b0&&cur_sol==4'd15)begin
        //BT case 4 backward且無解，洗掉目前的格子並開始往後
        map[cur_row][cur_col]<=4'd0; confirm_map[cur_row][cur_col]<=1'b0;
        cand_ptr[cur_row][cur_col]<=4'd0;
        cur_row<=pre_row; cur_col<=pre_col; forward<=1'b0;
    end
    else if(cur_state==CLEAR)begin
        in_row<=4'd0; in_col<=4'd0; cur_row<=4'd0; cur_col<=4'd0;
        HN_row_idx<=4'd0; HN_col_idx<=4'd0;
        HN_row_blk_idx<=2'd0; HN_col_blk_idx<=2'd0;
        EVAL_HN_tag<=2'd0; HN_once_done<=1'b0; EVAL_HN_done<=1'b0;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=9'd0; map[i][j]<=9'd0;
                confirm_map[i][j]<=1'b0; empty_map[i][j]<=1'b0;
            end
        end
    end
end

//===for debug===
reg [4:0]debug_case;
always@(*)begin
    if(in_valid==1'b1 && in_col==4'd8)begin
        debug_case=4'd0;
    end
    //input case 2
    else if(in_valid==1'b1 && in_col<4'd8)begin
        debug_case=4'd1;
    end
    //EVAL_cand case 1 (找candiadte而已)
    else if(cur_state==EVAL_cand && cur_col==4'd8)begin
        debug_case=4'd2;
    end
    //EVAL_cand case 2 (找candiadte而已)
    else if(cur_state==EVAL_cand&& cur_col<4'd8)begin
        debug_case=4'd3;
    end
    //case 5 做完
    else if(cur_state==EVAL_HN && full_bool==1'b1)begin
        debug_case=4'd4;
    end
    //case 4 做完一次
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3 && HN_once_done==1'b1)begin
        debug_case=4'd5;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd0)begin   
        debug_case=4'd6;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd1 && HN_row_idx<=4'd8)begin
        debug_case=4'd7;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd2 && HN_col_idx<=4'd8)begin
        debug_case=4'd8;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3)begin
        debug_case=4'd9;
    end
    else if(cur_state==EVAL_BT&&empty_cnt==7'd0)begin
        debug_case=4'd10;
    end
    else if(cur_state==EVAL_BT&&cur_row==4'd0&&cur_col==4'd0&&empty_map[0][0]==1'b0)begin
        debug_case=4'd11;
    end
    else if(cur_state==EVAL_BT&&cur_row==4'd0&&cur_col==4'd0&&empty_map[0][0]==1'b1)begin
        debug_case=4'd12;
    end
    else if(cur_state==EVAL_BT && forward==1'b1&&cur_sol!=4'd15)begin
        debug_case=4'd13;
    end
    else if(cur_state==EVAL_BT && forward==1'b1&&cur_sol==4'd15)begin
        debug_case=4'd14;
    end
    else if(cur_state==EVAL_BT && forward==1'b0&&cur_sol!=4'd15)begin
        debug_case=4'd15;
    end
    else if(cur_state==EVAL_BT && forward==1'b0&&cur_sol==4'd15)begin
        debug_case=5'd16;
    end
    else if(cur_state==CLEAR)begin
        debug_case=5'd17;
    end
    else debug_case=5'd18;
end
//===============

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=1'b0; out<=4'd0; out_row<=4'd0; out_col<=4'd0;
    end
    else if(cur_state==OUTPUT && out_row<=4'd8 && out_col<=4'd8)begin
        if(out_col==4'd8)begin 
            out_row<=out_row+4'd1; out_col<=4'd0;
        end
        else begin 
            out_row<=out_row; out_col<=out_col+4'd1;
        end
        out_valid<=1'b1; out<=map[out_row][out_col];
    end
    else begin
        out_valid<=1'b0; out<=4'd0; out_row<=4'd0; out_col<=4'd0;
    end
end

endmodule