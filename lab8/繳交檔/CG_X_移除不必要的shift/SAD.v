// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SAD(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
	in_data1,
    T,
    in_data2,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input signed [5:0] in_data1;
input [3:0] T;
input signed [7:0] in_data2;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [91:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter d_model = 'd8;
//Part 1 FSM (FSM tag)
reg [3:0]cur_state,next_state;
parameter IDLE=4'd0, INPUT=4'd1, EVAL_KQV=4'd2, EVAL_A=4'd3;
parameter EVAL_scale=4'd4, EVAL_relu=4'd5, EVAL_SV=4'd6;
parameter OUTPUT=4'd8, CLEAR=4'd9;

//(FSM tag)
reg [3:0] w_in_row_cnt, w_in_col_cnt;   //Wk Wq Wv的input cnt
reg [1:0] w_cnt_stage;
reg [3:0] T_q;                          //pooli_size
reg [3:0] x_in_row_cnt, x_in_col_cnt;   //x的input cnt
reg [3:0] mul_D_row_cnt, mul_D_col_cnt; 

reg [9:0] global_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid==1'b1)next_state=INPUT;
            else next_state=IDLE;
        end
        INPUT: begin
            if(w_in_row_cnt==7&&w_in_col_cnt==7&&w_cnt_stage==2) next_state=EVAL_KQV;
            else next_state=INPUT;
        end
        EVAL_KQV: begin
            if(global_cnt>=63)next_state=EVAL_A;
            else next_state=EVAL_KQV;
        end
        EVAL_A: begin
            if(global_cnt>=127)next_state=EVAL_scale;
            else next_state=EVAL_A;
        end
        EVAL_scale: begin
            if(global_cnt>=191)next_state=EVAL_relu;
            else next_state=EVAL_scale;
        end
        EVAL_relu: begin
            if(global_cnt>=255)next_state=EVAL_SV;
            else next_state=EVAL_relu;
        end
        EVAL_SV: begin
            if(global_cnt>=319)next_state=OUTPUT;
            else next_state=EVAL_SV;
        end
        OUTPUT: begin
            if(mul_D_row_cnt==(T_q-1) && mul_D_col_cnt==7) next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//===step 0 take input===
//Part 3 Seq Logic (take input)
integer i,j;
reg signed [7:0] Wk [0:7][0:7];
reg signed [7:0] Wq [0:7][0:7];
reg signed [7:0] Wv [0:7][0:7];
reg signed [7:0] X [0:7][0:7];
reg signed [5:0] Y [0:3][0:3];
reg [2:0] y_in_row_cnt, y_in_col_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        T_q<=1; w_cnt_stage<=0; w_in_row_cnt<=0; w_in_col_cnt<=0;   //input cnt
        x_in_row_cnt<=0; x_in_col_cnt<=0;
        y_in_row_cnt<=0; y_in_col_cnt<=0;
    end
    else if(in_valid==1'b1)begin
        //T_q
        if(w_cnt_stage==0 && w_in_row_cnt==0 && w_in_col_cnt==0) T_q<=T;
        //Wk Wq Wv
        if(w_in_row_cnt==7 && w_in_col_cnt==7)begin
            w_cnt_stage<=w_cnt_stage+1; w_in_row_cnt<=0; w_in_col_cnt<=0;
        end
        else if(w_in_row_cnt<7 && w_in_col_cnt==7)begin  //小cnt都數到底
            w_cnt_stage<=w_cnt_stage;
            w_in_row_cnt<=w_in_row_cnt+1; w_in_col_cnt<=0;
        end
        else begin
            w_cnt_stage<=w_cnt_stage;
            w_in_row_cnt<=w_in_row_cnt;  w_in_col_cnt<=w_in_col_cnt+1;
        end
        // x
        if(x_in_row_cnt<T_q && x_in_col_cnt==7)begin    //小cnt都數到底
            x_in_row_cnt<=x_in_row_cnt+1; x_in_col_cnt<=0;
        end
        else begin
            x_in_row_cnt<=x_in_row_cnt;   x_in_col_cnt<=x_in_col_cnt+1;
        end
        // y
        if(y_in_row_cnt==3 && y_in_col_cnt==3)begin
            y_in_row_cnt<=4; y_in_col_cnt<=0;
        end
        else if(y_in_row_cnt<3 && y_in_col_cnt==3)begin    //小cnt都數到底
            y_in_row_cnt<=y_in_row_cnt+1; y_in_col_cnt<=0;
        end
        else begin
            y_in_row_cnt<=y_in_row_cnt;   y_in_col_cnt<=y_in_col_cnt+1;
        end
    end
    else if(cur_state==CLEAR)begin
        T_q<=1; w_cnt_stage<=0; w_in_row_cnt<=0; w_in_col_cnt<=0;   //input cnt
        x_in_row_cnt<=0; x_in_col_cnt<=0;
        y_in_row_cnt<=0; y_in_col_cnt<=0;
    end
end

//Part 3 Seq Logic Wq
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wq[i][j]<=8'd0; 
            end
        end
    end
    else if(in_valid==1'b1)begin
        if(w_cnt_stage==0) Wq[w_in_row_cnt][w_in_col_cnt]<=w_Q; 
    end
    else if(cur_state==CLEAR)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wq[i][j]<=8'd0; 
            end
        end
    end
end

//Part 3 Seq Logic Wk
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wk[i][j]<=8'd0; 
            end
        end
    end
    else if(in_valid==1'b1)begin
        if(w_cnt_stage==1) Wk[w_in_row_cnt][w_in_col_cnt]<=w_K; 
    end
    else if(cur_state==CLEAR)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wk[i][j]<=8'd0; 
            end
        end
    end
end

//Part 3 Seq Logic Wv
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wv[i][j]<=8'd0; 
            end
        end
    end
    else if(in_valid==1'b1)begin
        if(w_cnt_stage==2) Wv[w_in_row_cnt][w_in_col_cnt]<=w_V; 
    end
    else if(cur_state==CLEAR)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wv[i][j]<=8'd0; 
            end
        end
    end
end

//Part 3 Seq Logic X[]
reg cg_ctrl_X [0:7][0:7];
wire cg_clk_X [0:7][0:7];

genvar i_var,j_var;
generate
    for(i_var=0;i_var<8;i_var=i_var+1)begin
        for(j_var=0;j_var<8;j_var=j_var+1)begin
            GATED_OR GATED_X (
            .CLOCK(clk),.SLEEP_CTRL(cg_ctrl_X[i_var][j_var]&&cg_en),
            .RST_N(rst_n), .CLOCK_GATED(cg_clk_X[i_var][j_var])
            );

            always@(*)begin
                case(cur_state)
                    EVAL_A, EVAL_scale,EVAL_relu, EVAL_SV:cg_ctrl_X[i_var][j_var]=1; 
                    default: cg_ctrl_X[i_var][j_var]=0; 
                endcase
            end

            always@(posedge cg_clk_X[i_var][j_var] or negedge rst_n)begin
                if(!rst_n)begin
                    X[i_var][j_var]<=8'd0;
                end
                else if(in_valid==1'b1)begin
                    if(x_in_row_cnt<T_q && x_in_col_cnt<=7)begin 
                        if(i_var==x_in_row_cnt && j_var==x_in_col_cnt) X[i_var][j_var]<=in_data2;
                    end
                end
                else if(cur_state==CLEAR)begin
                    X[i_var][j_var]<=8'd0;
                end
            end
        end
    end
endgenerate

//Part 3 Seq Logic Y[]
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<4;j=j+1)begin
                Y [i][j]<=6'd0;
            end
        end
    end
    else if(in_valid==1'b1)begin
        if(y_in_row_cnt<=3 && y_in_col_cnt<=3)begin
            Y[y_in_row_cnt][y_in_col_cnt]<=in_data1;
        end
    end
    else if(cur_state==CLEAR)begin
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<4;j=j+1)begin
                Y[i][j]<=6'd0;
            end
        end
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        global_cnt<=0;
    end
    else if(cur_state==EVAL_KQV || cur_state==EVAL_A || cur_state==EVAL_scale||
    cur_state==EVAL_relu || cur_state==EVAL_SV || cur_state==OUTPUT)begin
        global_cnt<=global_cnt+1;
    end
    else if(cur_state==CLEAR)begin
        global_cnt<=0;
    end
end
//========================

//===step 1 EVAL_KQV===
//Part 3 Seq Logic
reg signed [18:0] K [0:7][0:7];    
reg signed [18:0] Q [0:7][0:7];    
reg signed [18:0] V [0:7][0:7];
reg [3:0] xw_big_cnt, xw_small_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                K[i][j]<=16'd0; Q[i][j]<=16'd0; V[i][j]<=16'd0;
            end
        end
        xw_big_cnt<=0; xw_small_cnt<=0;
    end
    else if(cur_state==EVAL_KQV)begin
        if(xw_big_cnt<7 && xw_small_cnt==7)begin        //big & small cnt
            xw_big_cnt<=xw_big_cnt+1; xw_small_cnt<=0;
        end
        else begin
            xw_big_cnt<=xw_big_cnt; xw_small_cnt<=xw_small_cnt+1;
        end
        //EVAL
        if(xw_big_cnt<=7 && xw_small_cnt<=7)begin
            K[xw_small_cnt][xw_big_cnt]<=X[xw_big_cnt][0]* Wk[0][xw_small_cnt]+
                                        X[xw_big_cnt][1]* Wk[1][xw_small_cnt]+
                                        X[xw_big_cnt][2]* Wk[2][xw_small_cnt]+
                                        X[xw_big_cnt][3]* Wk[3][xw_small_cnt]+
                                        X[xw_big_cnt][4]* Wk[4][xw_small_cnt]+
                                        X[xw_big_cnt][5]* Wk[5][xw_small_cnt]+
                                        X[xw_big_cnt][6]* Wk[6][xw_small_cnt]+
                                        X[xw_big_cnt][7]* Wk[7][xw_small_cnt];

            Q[xw_big_cnt][xw_small_cnt]<=X[xw_big_cnt][0]* Wq[0][xw_small_cnt]+
                                        X[xw_big_cnt][1]* Wq[1][xw_small_cnt]+
                                        X[xw_big_cnt][2]* Wq[2][xw_small_cnt]+
                                        X[xw_big_cnt][3]* Wq[3][xw_small_cnt]+
                                        X[xw_big_cnt][4]* Wq[4][xw_small_cnt]+
                                        X[xw_big_cnt][5]* Wq[5][xw_small_cnt]+
                                        X[xw_big_cnt][6]* Wq[6][xw_small_cnt]+
                                        X[xw_big_cnt][7]* Wq[7][xw_small_cnt];

            V[xw_big_cnt][xw_small_cnt]<=X[xw_big_cnt][0]* Wv[0][xw_small_cnt]+
                                        X[xw_big_cnt][1]* Wv[1][xw_small_cnt]+
                                        X[xw_big_cnt][2]* Wv[2][xw_small_cnt]+
                                        X[xw_big_cnt][3]* Wv[3][xw_small_cnt]+
                                        X[xw_big_cnt][4]* Wv[4][xw_small_cnt]+
                                        X[xw_big_cnt][5]* Wv[5][xw_small_cnt]+
                                        X[xw_big_cnt][6]* Wv[6][xw_small_cnt]+
                                        X[xw_big_cnt][7]* Wv[7][xw_small_cnt];
        end
    end
    else if(cur_state==OUTPUT)begin
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<7;j=j+1)begin
                K[i][j]<=K[i][j+1]; Q[i][j]<=Q[i][j+1]; V[i][j]<=V[i][j+1]; 
            end
            K[i][7]<=K[i][0]; Q[i][7]<=Q[i][0]; V[i][7]<=V[i][0]; 
        end
    end
    else if(cur_state==CLEAR)begin 
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                K[i][j]<=16'd0; Q[i][j]<=16'd0; V[i][j]<=16'd0;
            end
        end
        xw_big_cnt<=0; xw_small_cnt<=0;
    end
end
//=====================


//step 2 EVAL_A:    AS=QK^T
//step 3 EVAL_scale:AS=AS/3
//step 4 EVAL_relu  AS=AS_relu 
//step 5 EVAL_SV    P=AS*V

//Part 2 Comb Logic
reg signed [39:0] a_in [0:7];
reg signed [18:0] b_in [0:7];
wire signed [62:0] mul_out_step_2_5;

mul_comb mul_comb_inst(
    .a0(a_in[0]), .a1(a_in[1]),
    .a2(a_in[2]), .a3(a_in[3]),
    .a4(a_in[4]), .a5(a_in[5]),
    .a6(a_in[6]), .a7(a_in[7]),
    .b0(b_in[0]), .b1(b_in[1]),
    .b2(b_in[2]), .b3(b_in[3]),
    .b4(b_in[4]), .b5(b_in[5]),
    .b6(b_in[6]), .b7(b_in[7]),
    .sum(mul_out_step_2_5) 
);

//Part 2 Comb Logic
reg signed [39:0] AS[0:7][0:7];
reg signed [62:0] P [0:7][0:7];
reg [3:0] AS_big_cnt, AS_small_cnt;
always@(*)begin
    if(cur_state==EVAL_A)begin  //Q K^T
        a_in[0]=Q[AS_big_cnt][0];
        a_in[1]=Q[AS_big_cnt][1];
        a_in[2]=Q[AS_big_cnt][2];
        a_in[3]=Q[AS_big_cnt][3];
        a_in[4]=Q[AS_big_cnt][4];
        a_in[5]=Q[AS_big_cnt][5];
        a_in[6]=Q[AS_big_cnt][6];
        a_in[7]=Q[AS_big_cnt][7];

        b_in[0]=K[0][AS_small_cnt];
        b_in[1]=K[1][AS_small_cnt];
        b_in[2]=K[2][AS_small_cnt];
        b_in[3]=K[3][AS_small_cnt];
        b_in[4]=K[4][AS_small_cnt];
        b_in[5]=K[5][AS_small_cnt];
        b_in[6]=K[6][AS_small_cnt];
        b_in[7]=K[7][AS_small_cnt];
    end
    else begin                  //AS=AS*V
        a_in[0]=AS[AS_big_cnt][0];
        a_in[1]=AS[AS_big_cnt][1];
        a_in[2]=AS[AS_big_cnt][2];
        a_in[3]=AS[AS_big_cnt][3];
        a_in[4]=AS[AS_big_cnt][4];
        a_in[5]=AS[AS_big_cnt][5];
        a_in[6]=AS[AS_big_cnt][6];
        a_in[7]=AS[AS_big_cnt][7];

        b_in[0]=V[0][AS_small_cnt];
        b_in[1]=V[1][AS_small_cnt];
        b_in[2]=V[2][AS_small_cnt];
        b_in[3]=V[3][AS_small_cnt];
        b_in[4]=V[4][AS_small_cnt];
        b_in[5]=V[5][AS_small_cnt];
        b_in[6]=V[6][AS_small_cnt];
        b_in[7]=V[7][AS_small_cnt];
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        AS_big_cnt<=0; AS_small_cnt<=0;
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                AS[i][j]<=0; P[i][j]<=0;
            end
        end
    end
    else if(cur_state==EVAL_A)begin
        if(AS_big_cnt==7 && AS_small_cnt==7)begin     //大小cnt都數到底了
            AS_big_cnt<=0;              AS_small_cnt<=0;
        end
        else if(AS_big_cnt<7 && AS_small_cnt==7)begin //小cnt數到底了
            AS_big_cnt<=AS_big_cnt+1;  AS_small_cnt<=0;
        end
        else begin
            AS_big_cnt<=AS_big_cnt;    AS_small_cnt<=AS_small_cnt+1;
        end
        //EVAL
        AS[AS_big_cnt][AS_small_cnt]<=mul_out_step_2_5;
    end
    else if(cur_state==EVAL_scale)begin
        if(AS_big_cnt==7 && AS_small_cnt==7)begin     //大小cnt都數到底了
            AS_big_cnt<=0;              AS_small_cnt<=0;
        end
        else if(AS_big_cnt<7 && AS_small_cnt==7)begin //小cnt數到底了
            AS_big_cnt<=AS_big_cnt+1;  AS_small_cnt<=0;
        end
        else begin
            AS_big_cnt<=AS_big_cnt;    AS_small_cnt<=AS_small_cnt+1;
        end
        //EVAL
        AS[AS_big_cnt][AS_small_cnt]<=AS[AS_big_cnt][AS_small_cnt]/3;
    end
    else if(cur_state==EVAL_relu)begin              
        if(AS_big_cnt==7 && AS_small_cnt==7)begin     //大小cnt都數到底了
            AS_big_cnt<=0;  AS_small_cnt<=0;
        end
        else if(AS_big_cnt<7 && AS_small_cnt==7)begin //小cnt數到底了
            AS_big_cnt<=AS_big_cnt+1;  AS_small_cnt<=0;
        end
        else begin
            AS_big_cnt<=AS_big_cnt;    AS_small_cnt<=AS_small_cnt+1;
        end
        //EVAL
        if(AS[AS_big_cnt][AS_small_cnt]<0) AS[AS_big_cnt][AS_small_cnt]<=0;
    end
    else if(cur_state==EVAL_SV)begin
        if(AS_big_cnt==7 && AS_small_cnt==7)begin     //大小cnt都數到底了
            AS_big_cnt<=0;  AS_small_cnt<=0;
        end
        else if(AS_big_cnt<7 && AS_small_cnt==7)begin  //小cnt數到底了
            AS_big_cnt<=AS_big_cnt+1;  AS_small_cnt<=0;
        end
        else begin
            AS_big_cnt<=AS_big_cnt;    AS_small_cnt<=AS_small_cnt+1;
        end
        //EVAL (P=SV)
        P[AS_big_cnt][AS_small_cnt]<=mul_out_step_2_5;
    end
    else if(cur_state==CLEAR)begin
        AS_big_cnt<=0; AS_small_cnt<=0;
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                AS[i][j]<=0; P[i][j]<=0;
            end
        end
    end
end
//=============

//step 6 DET(Y)
//Part 2 Comb Logic
reg signed [5:0] k_in, p_in, l_in, o_in;
wire signed [13:0] part_1_det_out;      

det_eval_part1 det_eval_part1_inst(     //1-12
    .k(k_in), .p(p_in), .l(l_in), .o(o_in),
    .part_1_det_out(part_1_det_out)
);

reg signed [6:0] A_in, f_in;
reg signed [13:0] part_1_det_in_q;
wire signed [29:0] part_2_det_out;

det_eval_part2 det_eval_part2_inst(     //2-13
    .a(A_in), .f(f_in),
    .part_1_det_in(part_1_det_in_q),
    .part_2_det_out(part_2_det_out)
);

//Part 2 Comb Logic
always@(*)begin
    case(global_cnt)
        1:begin
            k_in=Y[2][2]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][2];
        end
        2:begin
            k_in=Y[2][1]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][1];
        end
        3:begin
            k_in=Y[2][1]; p_in=Y[3][2]; l_in=Y[2][2]; o_in=Y[3][1];
        end

        4:begin
            k_in=Y[2][2]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][2];
        end
        5:begin
            k_in=Y[2][0]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][0];
        end
        6:begin
            k_in=Y[2][0]; p_in=Y[3][2]; l_in=Y[2][2]; o_in=Y[3][0];
        end

        7:begin
            k_in=Y[2][1]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][1];
        end
        8:begin
            k_in=Y[2][0]; p_in=Y[3][3]; l_in=Y[2][3]; o_in=Y[3][0];
        end
        9:begin
            k_in=Y[2][0]; p_in=Y[3][1]; l_in=Y[2][1]; o_in=Y[3][0];
        end

        10:begin
            k_in=Y[2][1]; p_in=Y[3][2]; l_in=Y[2][2]; o_in=Y[3][1];
        end
        11:begin
            k_in=Y[2][0]; p_in=Y[3][2]; l_in=Y[2][2]; o_in=Y[3][0];
        end
        12:begin
            k_in=Y[2][0]; p_in=Y[3][1]; l_in=Y[2][1]; o_in=Y[3][0];
        end
        default:begin
            k_in=Y[2][0]; p_in=Y[3][1]; l_in=Y[2][1]; o_in=Y[3][0];
        end
    endcase
end

always@(*)begin
    case(global_cnt)
        2: begin A_in=Y[0][0]; f_in=Y[1][1]; end
        3: begin A_in=Y[0][0]; f_in=-Y[1][2];end
        4: begin A_in=Y[0][0]; f_in=Y[1][3]; end

        5: begin A_in=-Y[0][1]; f_in=Y[1][0]; end
        6: begin A_in=-Y[0][1]; f_in=-Y[1][2];end
        7: begin A_in=-Y[0][1]; f_in=Y[1][3]; end

        8: begin A_in=Y[0][2]; f_in=Y[1][0]; end
        9: begin A_in=Y[0][2]; f_in=-Y[1][1];end
        10:begin A_in=Y[0][2]; f_in=Y[1][3]; end

        11:begin A_in=-Y[0][3]; f_in=Y[1][0]; end 
        12:begin A_in=-Y[0][3]; f_in=-Y[1][1];end 
        13:begin A_in=-Y[0][3]; f_in=Y[1][2]; end 
        default: begin A_in=-Y[0][3]; f_in=Y[1][2]; end 
    endcase
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        part_1_det_in_q<=0;
    end
    else if(global_cnt>=1 && global_cnt<=12)begin
        part_1_det_in_q<=part_1_det_out;
    end
    else if(cur_state==CLEAR)begin
        part_1_det_in_q<=0;
    end
end

//Part 3 Seq Logic
reg signed [33:0] Det_Y;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Det_Y<=0;
    end
    else if(global_cnt>=2 && global_cnt<=13)begin
        Det_Y<=Det_Y+part_2_det_out;
    end
    else if(cur_state==CLEAR)begin
        Det_Y<=0;
    end
end

//step 7 D * AS and OUTPUT
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;   out_data<=92'd0;
        mul_D_row_cnt<=0; mul_D_col_cnt<=0;
    end
    else if(cur_state==OUTPUT)begin
        if(mul_D_row_cnt<T_q && mul_D_col_cnt==7)begin
            mul_D_row_cnt<=mul_D_row_cnt+1; mul_D_col_cnt<=0;
        end
        else begin
            mul_D_row_cnt<=mul_D_row_cnt; mul_D_col_cnt<=mul_D_col_cnt+1;
        end
        out_valid<=1;   out_data<=Det_Y * P[mul_D_row_cnt][mul_D_col_cnt];
    end
    else begin
        out_valid<=0;   out_data<=92'd0;
        mul_D_row_cnt<=0; mul_D_col_cnt<=0;
    end
end
//=============
endmodule


module mul_comb (
    input  signed [39:0] a0, input  signed [39:0] a1,
    input  signed [39:0] a2, input  signed [39:0] a3,
    input  signed [39:0] a4, input  signed [39:0] a5,
    input  signed [39:0] a6, input  signed [39:0] a7,
    input  signed [18:0] b0, input  signed [18:0] b1,
    input  signed [18:0] b2, input  signed [18:0] b3,
    input  signed [18:0] b4, input  signed [18:0] b5,
    input  signed [18:0] b6, input  signed [18:0] b7,
    output signed [62:0] sum
);
    // products: each 59-bit signed
    wire signed [59:0] p0 = a0 * b0;
    wire signed [59:0] p1 = a1 * b1;
    wire signed [59:0] p2 = a2 * b2;
    wire signed [59:0] p3 = a3 * b3;
    wire signed [59:0] p4 = a4 * b4;
    wire signed [59:0] p5 = a5 * b5;
    wire signed [59:0] p6 = a6 * b6;
    wire signed [59:0] p7 = a7 * b7;

    assign sum = ((p0 + p1) + (p2 + p3)) + ((p4 + p5) + (p6 + p7));
endmodule

module det_eval_part1(
    input  signed [5:0] k,
    input  signed [5:0] p,
    input  signed [5:0] l,
    input  signed [5:0] o,
    output signed [13:0] part_1_det_out
);
    // x = (k * p) - (l * o)
    assign part_1_det_out = (k * p) - (l * o);
endmodule

module det_eval_part2(
    input  signed [6:0]  a,
    input  signed [6:0]  f,
    input  signed [13:0] part_1_det_in,
    output signed [29:0] part_2_det_out
);
    wire signed [15:0] af_prod;
    assign af_prod = a * f;

    // af_prod (12 bits) * part_1_det_in (13 bits) -> 12+13 = 25 bits 保守取 26 bits signed
    assign part_2_det_out = af_prod * part_1_det_in;
endmodule