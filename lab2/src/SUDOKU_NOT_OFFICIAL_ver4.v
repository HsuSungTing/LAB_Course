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
reg [8:0] HN_check_cand [0:8];      //可以是一個row或是一個col或是一個blk

always@(*)begin
    if(EVAL_HN_tag==2'd1)begin      //去承接目前EVAL_HN在比較的row
        for(i=0;i<9;i=i+1)begin 
            HN_check_cand[i]=candidate_map[HN_row_idx][i];
        end
    end
    else if(EVAL_HN_tag==2'd2)begin  //去承接目前的EVAL_HN在比較的col
        for(i=0;i<9;i=i+1)begin 
            HN_check_cand[i]=candidate_map[i][HN_col_idx];
        end
    end
    else if(EVAL_HN_tag==2'd3)begin  //EVAL_HN在比較的blk
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
            {HN_check_cand[0][i],HN_check_cand[1][i],HN_check_cand[2][i],
            HN_check_cand[3][i],HN_check_cand[4][i],HN_check_cand[5][i],
            HN_check_cand[6][i],HN_check_cand[7][i],HN_check_cand[8][i]};
    end
end

//Part 2 Comb Logic
reg [3:0] only_cand_ele_idx[0:8];    //檢查是1~9是否是持有1的唯一的候選
always @(*) begin
    // 這邊的i是check i+1是否為某人的唯一的候選，如果是的話，是誰([3:0])
    for(i=0;i<9;i=i+1)begin
        if(only_cand_check[i]==9'b1_0000_0000) only_cand_ele_idx[i]=4'd0;
        else if(only_cand_check[i]==9'b0_1000_0000) only_cand_ele_idx[i]=4'd1;
        else if(only_cand_check[i]==9'b0_0100_0000) only_cand_ele_idx[i]=4'd2;
        else if(only_cand_check[i]==9'b0_0010_0000) only_cand_ele_idx[i]=4'd3;
        else if(only_cand_check[i]==9'b0_0001_0000) only_cand_ele_idx[i]=4'd4;
        else if(only_cand_check[i]==9'b0_0000_1000) only_cand_ele_idx[i]=4'd5;
        else if(only_cand_check[i]==9'b0_0000_0100) only_cand_ele_idx[i]=4'd6;
        else if(only_cand_check[i]==9'b0_0000_0010) only_cand_ele_idx[i]=4'd7;
        else if(only_cand_check[i]==9'b0_0000_0001) only_cand_ele_idx[i]=4'd8; //代表element 8為唯一候選者
        else only_cand_ele_idx[i]=4'd15;       //代表不存在唯一候選者(後續不會影響candidate_map)
    end
end

//Part 2 Comb Logic: only_cand_ele_idx[i]對應到map上的位置
//只有位置資訊!!!
reg [3:0] only_cand_col [0:8];
reg [3:0] only_cand_row [0:8];

always@(*)begin
    if(EVAL_HN_tag==2'd1)begin      //掃單一一個row，該row在Map上的位置
        for(i=0;i<9;i=i+1)begin
            only_cand_col[i]=i;
            only_cand_row[i]=HN_row_idx;
        end
    end
    else if(EVAL_HN_tag==2'd2)begin  //掃單一一個col，該col在Map上的位置
        for(i=0;i<9;i=i+1)begin
            only_cand_col[i]=HN_col_idx;
            only_cand_row[i]=i;
        end
    end
    else if(EVAL_HN_tag==2'd3)begin //掃單一一個blk，該blk在Map上的位置
        only_cand_row[0]=3*HN_row_blk_idx;only_cand_col[0]=3*HN_col_blk_idx;
        only_cand_row[1]=3*HN_row_blk_idx;only_cand_col[1]=3*HN_col_blk_idx+1'd1;
        only_cand_row[2]=3*HN_row_blk_idx;only_cand_col[2]=3*HN_col_blk_idx+1'd2;
        only_cand_row[3]=3*HN_row_blk_idx+1'd1;only_cand_col[3]=3*HN_col_blk_idx;
        only_cand_row[4]=3*HN_row_blk_idx+1'd1;only_cand_col[4]=3*HN_col_blk_idx+1'd1;
        only_cand_row[5]=3*HN_row_blk_idx+1'd1;only_cand_col[5]=3*HN_col_blk_idx+1'd2;
        only_cand_row[6]=3*HN_row_blk_idx+1'd2;only_cand_col[6]=3*HN_col_blk_idx;
        only_cand_row[7]=3*HN_row_blk_idx+1'd2;only_cand_col[7]=3*HN_col_blk_idx+1'd1;
        only_cand_row[8]=3*HN_row_blk_idx+1'd2;only_cand_col[8]=3*HN_col_blk_idx+1'd2;
    end
end

//Part 2 Comb Logic
reg [3:0] only_cand_blk [0:8]; 
//0 1 2
//3 4 5
//6 7 8

always@(*)begin
    for(i=0;i<9;i=i+1)begin
        //0
        if((only_cand_row[i]<4'd3) && (only_cand_col[i]<4'd3)) only_cand_blk[i]=4'd0;
        //1
        else if((only_cand_row[i]<4'd3) && (only_cand_col[i]>=4'd3&&only_cand_col[i]<4'd6)) only_cand_blk[i]=4'd1;
        //2
        else if((only_cand_row[i]<4'd3) && (only_cand_col[i]>=4'd6)) only_cand_blk[i]=4'd2;
        //3
        else if((only_cand_row[i]<4'd6&&only_cand_row[i]>=4'd3) && (only_cand_col[i]<4'd3)) only_cand_blk[i]=4'd3;
        //4
        else if((only_cand_row[i]<4'd6&&only_cand_row[i]>=4'd3) && (only_cand_col[i]>=4'd3 && only_cand_col[i]<4'd6)) only_cand_blk[i]=4'd4;
        //5
        else if((only_cand_row[i]<4'd6&&only_cand_row[i]>=4'd3) && (only_cand_col[i]>=4'd6)) only_cand_blk[i]=4'd5;
        //6
        else if((only_cand_row[i]>=4'd6) && (only_cand_col[i]<4'd3)) only_cand_blk[i]=4'd6;
        //7
        else if((only_cand_row[i]>=4'd6) && (only_cand_col[i]>=4'd3 && only_cand_col[i]<4'd6)) only_cand_blk[i]=4'd7;
        //8
        else if((only_cand_row[i]>=4'd6) && (only_cand_col[i]>=4'd6)) only_cand_blk[i]=4'd8;
        else only_cand_blk[i]=4'd15;
    end
end

//Part 2 Comb Logic: 
//掃整個map，看目前的row col是否和九個only_cand在同個row或同col或是同個blk
reg [8:0] updated_cand_map [0:8][0:8]; //經過row比對之後消除共同持有的candidate
reg [3:0] cand_map_blk_dix [0:8][0:8];

always @(*) begin
    // block 0
    cand_map_blk_dix[0][0]=4'd0; cand_map_blk_dix[0][1]=4'd0; cand_map_blk_dix[0][2]=4'd0;
    cand_map_blk_dix[1][0]=4'd0; cand_map_blk_dix[1][1]=4'd0; cand_map_blk_dix[1][2]=4'd0;
    cand_map_blk_dix[2][0]=4'd0; cand_map_blk_dix[2][1]=4'd0; cand_map_blk_dix[2][2]=4'd0;
    // block 1
    cand_map_blk_dix[0][3]=4'd1; cand_map_blk_dix[0][4]=4'd1; cand_map_blk_dix[0][5]=4'd1;
    cand_map_blk_dix[1][3]=4'd1; cand_map_blk_dix[1][4]=4'd1; cand_map_blk_dix[1][5]=4'd1;
    cand_map_blk_dix[2][3]=4'd1; cand_map_blk_dix[2][4]=4'd1; cand_map_blk_dix[2][5]=4'd1;
    // block 2
    cand_map_blk_dix[0][6]=4'd2; cand_map_blk_dix[0][7]=4'd2; cand_map_blk_dix[0][8]=4'd2;
    cand_map_blk_dix[1][6]=4'd2; cand_map_blk_dix[1][7]=4'd2; cand_map_blk_dix[1][8]=4'd2;
    cand_map_blk_dix[2][6]=4'd2; cand_map_blk_dix[2][7]=4'd2; cand_map_blk_dix[2][8]=4'd2;
    // block 3
    cand_map_blk_dix[3][0]=4'd3; cand_map_blk_dix[3][1]=4'd3; cand_map_blk_dix[3][2]=4'd3;
    cand_map_blk_dix[4][0]=4'd3; cand_map_blk_dix[4][1]=4'd3; cand_map_blk_dix[4][2]=4'd3;
    cand_map_blk_dix[5][0]=4'd3; cand_map_blk_dix[5][1]=4'd3; cand_map_blk_dix[5][2]=4'd3;
    // block 4
    cand_map_blk_dix[3][3]=4'd4; cand_map_blk_dix[3][4]=4'd4; cand_map_blk_dix[3][5]=4'd4;
    cand_map_blk_dix[4][3]=4'd4; cand_map_blk_dix[4][4]=4'd4; cand_map_blk_dix[4][5]=4'd4;
    cand_map_blk_dix[5][3]=4'd4; cand_map_blk_dix[5][4]=4'd4; cand_map_blk_dix[5][5]=4'd4;
    // block 5
    cand_map_blk_dix[3][6]=4'd5; cand_map_blk_dix[3][7]=4'd5; cand_map_blk_dix[3][8]=4'd5;
    cand_map_blk_dix[4][6]=4'd5; cand_map_blk_dix[4][7]=4'd5; cand_map_blk_dix[4][8]=4'd5;
    cand_map_blk_dix[5][6]=4'd5; cand_map_blk_dix[5][7]=4'd5; cand_map_blk_dix[5][8]=4'd5;
    // block 6
    cand_map_blk_dix[6][0]=4'd6; cand_map_blk_dix[6][1]=4'd6; cand_map_blk_dix[6][2]=4'd6;
    cand_map_blk_dix[7][0]=4'd6; cand_map_blk_dix[7][1]=4'd6; cand_map_blk_dix[7][2]=4'd6;
    cand_map_blk_dix[8][0]=4'd6; cand_map_blk_dix[8][1]=4'd6; cand_map_blk_dix[8][2]=4'd6;
    // block 7
    cand_map_blk_dix[6][3]=4'd7; cand_map_blk_dix[6][4]=4'd7; cand_map_blk_dix[6][5]=4'd7;
    cand_map_blk_dix[7][3]=4'd7; cand_map_blk_dix[7][4]=4'd7; cand_map_blk_dix[7][5]=4'd7;
    cand_map_blk_dix[8][3]=4'd7; cand_map_blk_dix[8][4]=4'd7; cand_map_blk_dix[8][5]=4'd7;
    // block 8
    cand_map_blk_dix[6][6]=4'd8; cand_map_blk_dix[6][7]=4'd8; cand_map_blk_dix[6][8]=4'd8;
    cand_map_blk_dix[7][6]=4'd8; cand_map_blk_dix[7][7]=4'd8; cand_map_blk_dix[7][8]=4'd8;
    cand_map_blk_dix[8][6]=4'd8; cand_map_blk_dix[8][7]=4'd8; cand_map_blk_dix[8][8]=4'd8;
end

always@(*)begin
    for(i=0;i<9;i=i+1)begin
        for(j=0;j<9;j=j+1)begin  //令k為[i][j]的blk index
            updated_cand_map[i][j]= candidate_map[i][j];
            if(only_cand_ele_idx[0]!=4'd15&&(i==only_cand_row[0]||j==only_cand_col[0]||cand_map_blk_dix[i][j]==only_cand_blk[0])&&candidate_map[i][j][only_cand_ele_idx[0]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[0]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[1]!=4'd15&&(i==only_cand_row[1]||j==only_cand_col[1]||cand_map_blk_dix[i][j]==only_cand_blk[1])&&candidate_map[i][j][only_cand_ele_idx[1]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[1]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[2]!=4'd15&&(i==only_cand_row[2]||j==only_cand_col[2]||cand_map_blk_dix[i][j]==only_cand_blk[2])&&candidate_map[i][j][only_cand_ele_idx[2]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[2]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[3]!=4'd15&&(i==only_cand_row[3]||j==only_cand_col[3]||cand_map_blk_dix[i][j]==only_cand_blk[3])&&candidate_map[i][j][only_cand_ele_idx[3]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[3]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[4]!=4'd15&&(i==only_cand_row[4]||j==only_cand_col[4]||cand_map_blk_dix[i][j]==only_cand_blk[4])&&candidate_map[i][j][only_cand_ele_idx[4]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[4]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[5]!=4'd15&&(i==only_cand_row[5]||j==only_cand_col[5]||cand_map_blk_dix[i][j]==only_cand_blk[5])&&candidate_map[i][j][only_cand_ele_idx[5]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[5]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[6]!=4'd15&&(i==only_cand_row[6]||j==only_cand_col[6]||cand_map_blk_dix[i][j]==only_cand_blk[6])&&candidate_map[i][j][only_cand_ele_idx[6]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[6]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[7]!=4'd15&&(i==only_cand_row[7]||j==only_cand_col[7]||cand_map_blk_dix[i][j]==only_cand_blk[7])&&candidate_map[i][j][only_cand_ele_idx[7]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[7]]=1'b0; // 只要有共同candidate就洗掉
            if(only_cand_ele_idx[8]!=4'd15&&(only_cand_ele_idx[8]!=4'd15&&i==only_cand_row[8]||j==only_cand_col[8]||cand_map_blk_dix[i][j]==only_cand_blk[8])&&candidate_map[i][j][only_cand_ele_idx[8]]==1'b1)
                updated_cand_map[i][j][only_cand_ele_idx[8]]=1'b0; // 只要有共同candidate就洗掉
        end
    end
end

//Part 3 Seq Logic
reg empty_map [0:8][0:8];  //0代表該格是empty
reg [1:0] EVAL_HN_tag; 
reg [5:0] sol_cnt, empty_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_row<=4'd0; in_col<=4'd0; cur_row<=4'd0; cur_col<=4'd0;
        HN_row_idx<=4'd0; HN_col_idx<=4'd0;
        HN_row_blk_idx<=2'd0; HN_col_blk_idx<=2'd0; empty_cnt<=6'd0;
    end
    //input case 1 (in_col歸0、in_row+1)
    else if(in_valid==1'b1 && in_col==4'd8)begin
        in_row<=in_row+4'd1; in_col<=4'd0; map[in_row][in_col]<=in;
        if(in==4'd0)begin 
            empty_map[in_row][in_col]<=1'b0; empty_cnt<=empty_cnt+1'd1;
        end
        else begin 
            empty_map[in_row][in_col]<=1'b1; empty_cnt<=empty_cnt;
        end
    end
    //input case 2
    else if(in_valid==1'b1 && in_col<4'd8)begin
        in_row<=in_row; in_col<=in_col+4'd1; map[in_row][in_col]<=in;
        if(in==4'd0)begin 
            empty_map[in_row][in_col]<=1'b0; empty_cnt<=empty_cnt+1'd1;
        end
        else begin
            empty_map[in_row][in_col]<=1'b1; empty_cnt<=empty_cnt;
        end
    end
    //EVAL_cand case 1 (找candiadte而已)
    else if(cur_state==EVAL_cand && cur_col==4'd8)begin
        cur_row<=cur_row+4'd1; cur_col<=4'd0;
        if(empty_map[cur_row][cur_col]==1'b0) begin
            candidate_map[cur_row][cur_col]<=cur_candidate;
        end
        else begin 
            candidate_map[cur_row][cur_col]<=8'd0;  //不是空的就不會有candidate
        end
    end
    //EVAL_cand case 2 (找candiadte而已)
    else if(cur_state==EVAL_cand&& cur_col<4'd8)begin
        cur_row<=cur_row; cur_col<=cur_col+4'd1;
        if(empty_map[cur_row][cur_col]==1'b0) begin
            candidate_map[cur_row][cur_col]<=cur_candidate;
        end
        else begin 
            candidate_map[cur_row][cur_col]<=8'd0;
        end
    end
    //case 5 做完一次
    else if(cur_state==EVAL_HN && sol_cnt>=empty_cnt)begin
        EVAL_HN_done<=1'b1;
        //其他訊號不變
    end
    //case 4 做完一次
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3 && HN_once_done==1'b1)begin
        HN_once_done<=1'b0; EVAL_HN_tag<=2'd0;
        //其他訊號不變
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd0)begin   
        //case 1: forward且有解 (map接受目前解) (只持續一個cycle)
        candidate_map[cur_row][cur_col]<=8'd0; EVAL_HN_tag<=2'd1;
        for(i=0; i<9; i=i+1)begin
            for(j=0; j<9; j=j+1)begin   //如果目前有確定只有一個解的格子就填入
                if(single_cand[i][j]!=4'd0)candidate_map[i][j]<=single_cand[i][j];
                else candidate_map[i][j]<=candidate_map[i][j];
            end
        end
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd1 && HN_row_idx<=4'd8)begin
        //case 2: check_row_HN
        if(only_cand_ele_idx[0]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[0]]<=4'd1; sol_cnt<=sol_cnt+1'd1; end //唯一候選1
        if(only_cand_ele_idx[1]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[1]]<=4'd2; sol_cnt<=sol_cnt+1'd1; end //唯一候選2
        if(only_cand_ele_idx[2]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[2]]<=4'd3; sol_cnt<=sol_cnt+1'd1; end //唯一候選3
        if(only_cand_ele_idx[3]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[3]]<=4'd4; sol_cnt<=sol_cnt+1'd1; end //唯一候選4
        if(only_cand_ele_idx[4]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[4]]<=4'd5; sol_cnt<=sol_cnt+1'd1; end //唯一候選5
        if(only_cand_ele_idx[5]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[5]]<=4'd6; sol_cnt<=sol_cnt+1'd1; end //唯一候選6
        if(only_cand_ele_idx[6]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[6]]<=4'd7; sol_cnt<=sol_cnt+1'd1; end //唯一候選7
        if(only_cand_ele_idx[7]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[7]]<=4'd8; sol_cnt<=sol_cnt+1'd1; end //唯一候選8
        if(only_cand_ele_idx[8]!=4'd15)begin map[HN_row_idx][only_cand_ele_idx[8]]<=4'd9; sol_cnt<=sol_cnt+1'd1; end //唯一候選9

        //然後再update 27個row col blk element，這邊沒問題，我們在nake_single一次update 81個
        HN_row_idx<= HN_row_idx+1'd1;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                //要確定真的持有該唯一解才能消除row col blk中其他人的candidate
                candidate_map[i][j]<=updated_cand_map[i][j]; 
            end
        end
        if(HN_row_idx==4'd8) EVAL_HN_tag<=2'd2;
        else  EVAL_HN_tag<=EVAL_HN_tag;

    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd2 && HN_col_idx<=4'd8)begin
        //case 3: backward且有解 (map接受目前解)
        if(only_cand_ele_idx[0]!=4'd15)begin map[only_cand_ele_idx[0]][HN_col_blk_idx]<=4'd1; sol_cnt<=sol_cnt+1'd1; end //唯一候選1
        if(only_cand_ele_idx[1]!=4'd15)begin map[only_cand_ele_idx[1]][HN_col_blk_idx]<=4'd2; sol_cnt<=sol_cnt+1'd1; end //唯一候選2
        if(only_cand_ele_idx[2]!=4'd15)begin map[only_cand_ele_idx[2]][HN_col_blk_idx]<=4'd3; sol_cnt<=sol_cnt+1'd1; end //唯一候選3
        if(only_cand_ele_idx[3]!=4'd15)begin map[only_cand_ele_idx[3]][HN_col_blk_idx]<=4'd4; sol_cnt<=sol_cnt+1'd1; end //唯一候選4
        if(only_cand_ele_idx[4]!=4'd15)begin map[only_cand_ele_idx[4]][HN_col_blk_idx]<=4'd5; sol_cnt<=sol_cnt+1'd1; end //唯一候選5
        if(only_cand_ele_idx[5]!=4'd15)begin map[only_cand_ele_idx[5]][HN_col_blk_idx]<=4'd6; sol_cnt<=sol_cnt+1'd1; end //唯一候選6
        if(only_cand_ele_idx[6]!=4'd15)begin map[only_cand_ele_idx[6]][HN_col_blk_idx]<=4'd7; sol_cnt<=sol_cnt+1'd1; end //唯一候選7
        if(only_cand_ele_idx[7]!=4'd15)begin map[only_cand_ele_idx[7]][HN_col_blk_idx]<=4'd8; sol_cnt<=sol_cnt+1'd1; end //唯一候選8
        if(only_cand_ele_idx[8]!=4'd15)begin map[only_cand_ele_idx[8]][HN_col_blk_idx]<=4'd9; sol_cnt<=sol_cnt+1'd1; end //唯一候選9

        //然後再update 27個row col blk element，這邊沒問題，我們在nake_single一次update 81個
        HN_col_idx<= HN_col_idx+1'd1;
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=updated_cand_map[i][j];
            end
        end
        if(HN_col_idx==4'd8) EVAL_HN_tag<=2'd3;
        else EVAL_HN_tag<=EVAL_HN_tag;
    end
    else if(cur_state==EVAL_HN && EVAL_HN_tag==2'd3)begin
        //case 4: backward且無解 (map洗掉目前解)
        if(only_cand_ele_idx[0]!=4'd15)begin map[only_cand_row[0]][only_cand_col[0]]<=4'd1; sol_cnt<=sol_cnt+1'd1; end //唯一候選1
        if(only_cand_ele_idx[1]!=4'd15)begin map[only_cand_row[1]][only_cand_col[1]]<=4'd2; sol_cnt<=sol_cnt+1'd1; end //唯一候選2
        if(only_cand_ele_idx[2]!=4'd15)begin map[only_cand_row[2]][only_cand_col[2]]<=4'd3; sol_cnt<=sol_cnt+1'd1; end //唯一候選3
        if(only_cand_ele_idx[3]!=4'd15)begin map[only_cand_row[3]][only_cand_col[3]]<=4'd4; sol_cnt<=sol_cnt+1'd1; end //唯一候選4
        if(only_cand_ele_idx[4]!=4'd15)begin map[only_cand_row[4]][only_cand_col[4]]<=4'd5; sol_cnt<=sol_cnt+1'd1; end //唯一候選5
        if(only_cand_ele_idx[5]!=4'd15)begin map[only_cand_row[5]][only_cand_col[5]]<=4'd6; sol_cnt<=sol_cnt+1'd1; end //唯一候選6
        if(only_cand_ele_idx[6]!=4'd15)begin map[only_cand_row[6]][only_cand_col[6]]<=4'd7; sol_cnt<=sol_cnt+1'd1; end //唯一候選7
        if(only_cand_ele_idx[7]!=4'd15)begin map[only_cand_row[7]][only_cand_col[7]]<=4'd8; sol_cnt<=sol_cnt+1'd1; end //唯一候選8
        if(only_cand_ele_idx[8]!=4'd15)begin map[only_cand_row[8]][only_cand_col[8]]<=4'd9; sol_cnt<=sol_cnt+1'd1; end //唯一候選9
               
        for(i=0;i<9;i=i+1)begin
            for(j=0;j<9;j=j+1)begin
                candidate_map[i][j]<=updated_cand_map[i][j];
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
end


endmodule