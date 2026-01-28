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
parameter IDLE=3'd0, INPUT=3'd1, Eval=3'd2, Output=3'd3, CLEAR=3'd4;
reg [6:0] input_cnt, out_cnt;
reg EVAL_done;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)cur_state<=Idle;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid==1'b1) next_state=INPUT;
            else next_state=IDLE;
        end
        INPUT: begin 
            if(input_cnt>=7'd80)next_state=EVAL;
            else next_state=INPUT;
        end
        EVAL: begin
            if(EVAL_done==1'b1)next_state=OUTPUT;
            else next_state=EVAL;
        end
        OUTPUT: begin
            if(out_cnt>=7'd80)next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 2 Comb Logic: prev_col、prev_row
reg [3:0] cur_row, cur_col;
reg [3:0] prev_row, prev_col;
always @(*) begin
    if({4'd8,4'd8}<{cur_row,cur_col} && empty_map[8][8]==1'b0) {prev_row, prev_col}={4'd8,4'd8};
    else if({4'd8,4'd7}<{cur_row,cur_col} && empty_map[8][7]==1'b0) {prev_row, prev_col}={4'd8,4'd7};
    else if({4'd8,4'd6}<{cur_row,cur_col} && empty_map[8][6]==1'b0) {prev_row, prev_col}={4'd8,4'd6};
    else if({4'd8,4'd5}<{cur_row,cur_col} && empty_map[8][5]==1'b0) {prev_row, prev_col}={4'd8,4'd5};
    else if({4'd8,4'd4}<{cur_row,cur_col} && empty_map[8][4]==1'b0) {prev_row, prev_col}={4'd8,4'd4};
    else if({4'd8,4'd3}<{cur_row,cur_col} && empty_map[8][3]==1'b0) {prev_row, prev_col}={4'd8,4'd3};
    else if({4'd8,4'd2}<{cur_row,cur_col} && empty_map[8][2]==1'b0) {prev_row, prev_col}={4'd8,4'd2};
    else if({4'd8,4'd1}<{cur_row,cur_col} && empty_map[8][1]==1'b0) {prev_row, prev_col}={4'd8,4'd1};
    else if({4'd8,4'd0}<{cur_row,cur_col} && empty_map[8][0]==1'b0) {prev_row, prev_col}={4'd8,4'd0};

    else if({4'd7,4'd8}<{cur_row,cur_col} && empty_map[7][8]==1'b0) {prev_row, prev_col}={4'd7,4'd8};
    else if({4'd7,4'd7}<{cur_row,cur_col} && empty_map[7][7]==1'b0) {prev_row, prev_col}={4'd7,4'd7};
    else if({4'd7,4'd6}<{cur_row,cur_col} && empty_map[7][6]==1'b0) {prev_row, prev_col}={4'd7,4'd6};
    else if({4'd7,4'd5}<{cur_row,cur_col} && empty_map[7][5]==1'b0) {prev_row, prev_col}={4'd7,4'd5};
    else if({4'd7,4'd4}<{cur_row,cur_col} && empty_map[7][4]==1'b0) {prev_row, prev_col}={4'd7,4'd4};
    else if({4'd7,4'd3}<{cur_row,cur_col} && empty_map[7][3]==1'b0) {prev_row, prev_col}={4'd7,4'd3};
    else if({4'd7,4'd2}<{cur_row,cur_col} && empty_map[7][2]==1'b0) {prev_row, prev_col}={4'd7,4'd2};
    else if({4'd7,4'd1}<{cur_row,cur_col} && empty_map[7][1]==1'b0) {prev_row, prev_col}={4'd7,4'd1};
    else if({4'd7,4'd0}<{cur_row,cur_col} && empty_map[7][0]==1'b0) {prev_row, prev_col}={4'd7,4'd0};

    else if({4'd6,4'd8}<{cur_row,cur_col} && empty_map[6][8]==1'b0) {prev_row, prev_col}={4'd6,4'd8};
    else if({4'd6,4'd7}<{cur_row,cur_col} && empty_map[6][7]==1'b0) {prev_row, prev_col}={4'd6,4'd7};
    else if({4'd6,4'd6}<{cur_row,cur_col} && empty_map[6][6]==1'b0) {prev_row, prev_col}={4'd6,4'd6};
    else if({4'd6,4'd5}<{cur_row,cur_col} && empty_map[6][5]==1'b0) {prev_row, prev_col}={4'd6,4'd5};
    else if({4'd6,4'd4}<{cur_row,cur_col} && empty_map[6][4]==1'b0) {prev_row, prev_col}={4'd6,4'd4};
    else if({4'd6,4'd3}<{cur_row,cur_col} && empty_map[6][3]==1'b0) {prev_row, prev_col}={4'd6,4'd3};
    else if({4'd6,4'd2}<{cur_row,cur_col} && empty_map[6][2]==1'b0) {prev_row, prev_col}={4'd6,4'd2};
    else if({4'd6,4'd1}<{cur_row,cur_col} && empty_map[6][1]==1'b0) {prev_row, prev_col}={4'd6,4'd1};
    else if({4'd6,4'd0}<{cur_row,cur_col} && empty_map[6][0]==1'b0) {prev_row, prev_col}={4'd6,4'd0};

    else if({4'd5,4'd8}<{cur_row,cur_col} && empty_map[5][8]==1'b0) {prev_row, prev_col}={4'd5,4'd8};
    else if({4'd5,4'd7}<{cur_row,cur_col} && empty_map[5][7]==1'b0) {prev_row, prev_col}={4'd5,4'd7};
    else if({4'd5,4'd6}<{cur_row,cur_col} && empty_map[5][6]==1'b0) {prev_row, prev_col}={4'd5,4'd6};
    else if({4'd5,4'd5}<{cur_row,cur_col} && empty_map[5][5]==1'b0) {prev_row, prev_col}={4'd5,4'd5};
    else if({4'd5,4'd4}<{cur_row,cur_col} && empty_map[5][4]==1'b0) {prev_row, prev_col}={4'd5,4'd4};
    else if({4'd5,4'd3}<{cur_row,cur_col} && empty_map[5][3]==1'b0) {prev_row, prev_col}={4'd5,4'd3};
    else if({4'd5,4'd2}<{cur_row,cur_col} && empty_map[5][2]==1'b0) {prev_row, prev_col}={4'd5,4'd2};
    else if({4'd5,4'd1}<{cur_row,cur_col} && empty_map[5][1]==1'b0) {prev_row, prev_col}={4'd5,4'd1};
    else if({4'd5,4'd0}<{cur_row,cur_col} && empty_map[5][0]==1'b0) {prev_row, prev_col}={4'd5,4'd0};

    else if({4'd4,4'd8}<{cur_row,cur_col} && empty_map[4][8]==1'b0) {prev_row, prev_col}={4'd4,4'd8};
    else if({4'd4,4'd7}<{cur_row,cur_col} && empty_map[4][7]==1'b0) {prev_row, prev_col}={4'd4,4'd7};
    else if({4'd4,4'd6}<{cur_row,cur_col} && empty_map[4][6]==1'b0) {prev_row, prev_col}={4'd4,4'd6};
    else if({4'd4,4'd5}<{cur_row,cur_col} && empty_map[4][5]==1'b0) {prev_row, prev_col}={4'd4,4'd5};
    else if({4'd4,4'd4}<{cur_row,cur_col} && empty_map[4][4]==1'b0) {prev_row, prev_col}={4'd4,4'd4};
    else if({4'd4,4'd3}<{cur_row,cur_col} && empty_map[4][3]==1'b0) {prev_row, prev_col}={4'd4,4'd3};
    else if({4'd4,4'd2}<{cur_row,cur_col} && empty_map[4][2]==1'b0) {prev_row, prev_col}={4'd4,4'd2};
    else if({4'd4,4'd1}<{cur_row,cur_col} && empty_map[4][1]==1'b0) {prev_row, prev_col}={4'd4,4'd1};
    else if({4'd4,4'd0}<{cur_row,cur_col} && empty_map[4][0]==1'b0) {prev_row, prev_col}={4'd4,4'd0};

    else if({4'd3,4'd8}<{cur_row,cur_col} && empty_map[3][8]==1'b0) {prev_row, prev_col}={4'd3,4'd8};
    else if({4'd3,4'd7}<{cur_row,cur_col} && empty_map[3][7]==1'b0) {prev_row, prev_col}={4'd3,4'd7};
    else if({4'd3,4'd6}<{cur_row,cur_col} && empty_map[3][6]==1'b0) {prev_row, prev_col}={4'd3,4'd6};
    else if({4'd3,4'd5}<{cur_row,cur_col} && empty_map[3][5]==1'b0) {prev_row, prev_col}={4'd3,4'd5};
    else if({4'd3,4'd4}<{cur_row,cur_col} && empty_map[3][4]==1'b0) {prev_row, prev_col}={4'd3,4'd4};
    else if({4'd3,4'd3}<{cur_row,cur_col} && empty_map[3][3]==1'b0) {prev_row, prev_col}={4'd3,4'd3};
    else if({4'd3,4'd2}<{cur_row,cur_col} && empty_map[3][2]==1'b0) {prev_row, prev_col}={4'd3,4'd2};
    else if({4'd3,4'd1}<{cur_row,cur_col} && empty_map[3][1]==1'b0) {prev_row, prev_col}={4'd3,4'd1};
    else if({4'd3,4'd0}<{cur_row,cur_col} && empty_map[3][0]==1'b0) {prev_row, prev_col}={4'd3,4'd0};

    else if({4'd2,4'd8}<{cur_row,cur_col} && empty_map[2][8]==1'b0) {prev_row, prev_col}={4'd2,4'd8};
    else if({4'd2,4'd7}<{cur_row,cur_col} && empty_map[2][7]==1'b0) {prev_row, prev_col}={4'd2,4'd7};
    else if({4'd2,4'd6}<{cur_row,cur_col} && empty_map[2][6]==1'b0) {prev_row, prev_col}={4'd2,4'd6};
    else if({4'd2,4'd5}<{cur_row,cur_col} && empty_map[2][5]==1'b0) {prev_row, prev_col}={4'd2,4'd5};
    else if({4'd2,4'd4}<{cur_row,cur_col} && empty_map[2][4]==1'b0) {prev_row, prev_col}={4'd2,4'd4};
    else if({4'd2,4'd3}<{cur_row,cur_col} && empty_map[2][3]==1'b0) {prev_row, prev_col}={4'd2,4'd3};
    else if({4'd2,4'd2}<{cur_row,cur_col} && empty_map[2][2]==1'b0) {prev_row, prev_col}={4'd2,4'd2};
    else if({4'd2,4'd1}<{cur_row,cur_col} && empty_map[2][1]==1'b0) {prev_row, prev_col}={4'd2,4'd1};
    else if({4'd2,4'd0}<{cur_row,cur_col} && empty_map[2][0]==1'b0) {prev_row, prev_col}={4'd2,4'd0};

    else if({4'd1,4'd8}<{cur_row,cur_col} && empty_map[1][8]==1'b0) {prev_row, prev_col}={4'd1,4'd8};
    else if({4'd1,4'd7}<{cur_row,cur_col} && empty_map[1][7]==1'b0) {prev_row, prev_col}={4'd1,4'd7};
    else if({4'd1,4'd6}<{cur_row,cur_col} && empty_map[1][6]==1'b0) {prev_row, prev_col}={4'd1,4'd6};
    else if({4'd1,4'd5}<{cur_row,cur_col} && empty_map[1][5]==1'b0) {prev_row, prev_col}={4'd1,4'd5};
    else if({4'd1,4'd4}<{cur_row,cur_col} && empty_map[1][4]==1'b0) {prev_row, prev_col}={4'd1,4'd4};
    else if({4'd1,4'd3}<{cur_row,cur_col} && empty_map[1][3]==1'b0) {prev_row, prev_col}={4'd1,4'd3};
    else if({4'd1,4'd2}<{cur_row,cur_col} && empty_map[1][2]==1'b0) {prev_row, prev_col}={4'd1,4'd2};
    else if({4'd1,4'd1}<{cur_row,cur_col} && empty_map[1][1]==1'b0) {prev_row, prev_col}={4'd1,4'd1};
    else if({4'd1,4'd0}<{cur_row,cur_col} && empty_map[1][0]==1'b0) {prev_row, prev_col}={4'd1,4'd0};

    else if({4'd0,4'd8}<{cur_row,cur_col} && empty_map[0][8]==1'b0) {prev_row, prev_col}={4'd0,4'd8};
    else if({4'd0,4'd7}<{cur_row,cur_col} && empty_map[0][7]==1'b0) {prev_row, prev_col}={4'd0,4'd7};
    else if({4'd0,4'd6}<{cur_row,cur_col} && empty_map[0][6]==1'b0) {prev_row, prev_col}={4'd0,4'd6};
    else if({4'd0,4'd5}<{cur_row,cur_col} && empty_map[0][5]==1'b0) {prev_row, prev_col}={4'd0,4'd5};
    else if({4'd0,4'd4}<{cur_row,cur_col} && empty_map[0][4]==1'b0) {prev_row, prev_col}={4'd0,4'd4};
    else if({4'd0,4'd3}<{cur_row,cur_col} && empty_map[0][3]==1'b0) {prev_row, prev_col}={4'd0,4'd3};
    else if({4'd0,4'd2}<{cur_row,cur_col} && empty_map[0][2]==1'b0) {prev_row, prev_col}={4'd0,4'd2};
    else if({4'd0,4'd1}<{cur_row,cur_col} && empty_map[0][1]==1'b0) {prev_row, prev_col}={4'd0,4'd1};
    else if({4'd0,4'd0}<{cur_row,cur_col} && empty_map[0][0]==1'b0) {prev_row, prev_col}={4'd0,4'd0};
end

//Part 2 Comb Logic
reg [3:0] next_row, next_col;
always@(*)begin
    if({4'd0, 4'd1}>{cur_row,cur_col}){next_row, next_col}={4'd0, 4'd1};
    else if({4'd0, 4'd2}>{cur_row,cur_col})next_row, next_col}={4'd0, 4'd2};
    else if({4'd0, 4'd3}>{cur_row,cur_col})next_row, next_col}={4'd0, 4'd3};

end

//Part 3 Seq Logic
reg [3:0] S_map [0:8][0:8];
reg empty_map [0:8][0:8];  //0代表該格是empty
reg [3:0] in_row, in_col;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_row<=4'd0; in_col<=4'd0;
    end
    //input case 1 (in_col歸0、in_row+1)
    else if(in_valid==1'b1 && in_col==4'd8)begin
        in_row<=in_row+4'd1; in_col<=4'd0;
        S_map[in_row][in_col]<=in;
        if(in==4'd0) empty_map[in_row][in_col]<=1'b0;
        else empty_map[in_row][in_col]<=1'b1;
    end
    //input case 2
    else if(in_valid==1'b1 && in_col<4'd8)begin
        in_row<=in_row; in_col<=in_col+4'd1;
        S_map[in_row][in_col]<=in;
        if(in==4'd0) empty_map[in_row][in_col]<=1'b0;
        else empty_map[in_row][in_col]<=1'b1;
    end
    else if(cur_state==EVAL)begin
        //case 1: forward且有解 (S_map接受目前解)
    end
    else if(cur_state==EVAL)begin
        //case 2 forward且無解 (S_map洗掉目前解)
    end
    else if(cur_state==EVAL)begin
        //case 3 backward且有解 (S_map接受目前解)
    end
    else if(cur_state==EVAL)begin
        //case 4 backward且無解 (S_map洗掉目前解)
    end
end


endmodule