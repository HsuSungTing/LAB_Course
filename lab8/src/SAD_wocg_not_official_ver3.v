module SAD(
    //Input signals
    clk,rst_n,in_valid,in_data1,T,in_data2,w_Q,w_K,w_V,
    //Output signals
    out_valid,out_data
);

input clk;
input rst_n;
input in_valid;
input signed [5:0] in_data1;
input [3:0] T;
input signed [7:0] in_data2;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [91:0] out_data;

parameter d_model = 'd8;

//Part 1 FSM (FSM tag)
reg [3:0]cur_state,next_state;
parameter IDLE=4'd0, INPUT=4'd1, EVAL_KQV=4'd2, EVAL_A=4'd3;
parameter EVAL_scale=4'd4, EVAL_relu=4'd5, EVAL_SV=4'd6, EVAL_mul_D=4'd7;
parameter OUTPUT=4'd8, CLEAR=4'd9;

//(FSM tag)
reg [3:0] w_in_row_cnt, w_in_col_cnt;   //Wk Wq Wv的input cnt
reg [1:0] w_cnt_stage;
reg [3:0] T_q;                          //pooli_size
reg [3:0] x_in_row_cnt, x_in_col_cnt;   //x的input cnt
reg [3:0] out_row_cnt, out_col_cnt;   

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
            if(global_cnt>=191)next_state=EVAL_SV;
            else next_state=EVAL_relu;
        end
        EVAL_SV: begin
            if(global_cnt>=255)next_state=EVAL_mul_D;
            else next_state=EVAL_SV;
        end
        EVAL_mul_D: begin
            if(global_cnt>=319)next_state=OUTPUT;
            else next_state=EVAL_mul_D;
        end
        OUTPUT: begin
            if(out_row_cnt==(T_q-1) && out_col_cnt==7) next_state=CLEAR;
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
        w_cnt_stage<=0; w_in_row_cnt<=0; w_in_col_cnt<=0;   //input cnt
        x_in_row_cnt<=0; x_in_col_cnt<=0;
        y_in_row_cnt<=0; y_in_col_cnt<=0;
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wk[i][j]<=8'd0; Wq[i][j]<=8'd0; Wv[i][j]<=8'd0; 
                X[i][j]<=8'd0;
            end
        end

        for(i=0;i<4;i=i+1)begin
            for(j=0;j<4;j=j+1)begin
                Y [i][j]<=6'd0;
            end
        end
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

        if(w_cnt_stage==0) Wq[w_in_row_cnt][w_in_col_cnt]<=w_Q; 
        else if(w_cnt_stage==1) Wk[w_in_row_cnt][w_in_col_cnt]<=w_K; 
        else if(w_cnt_stage==2) Wv[w_in_row_cnt][w_in_col_cnt]<=w_V; 

        // x
        if(x_in_row_cnt==T_q-1 && x_in_col_cnt==7)begin
            x_in_row_cnt<=x_in_row_cnt+1; x_in_col_cnt<=0;
        end
        else if(x_in_row_cnt<T_q-1 && x_in_col_cnt==7)begin    //小cnt都數到底
            x_in_row_cnt<=x_in_row_cnt+1; x_in_col_cnt<=0;
        end
        else begin
            x_in_row_cnt<=x_in_row_cnt;   x_in_col_cnt<=x_in_col_cnt+1;
        end

        if(x_in_row_cnt<=T_q-1 && x_in_col_cnt<=7)begin 
            X[x_in_row_cnt][x_in_col_cnt]<=in_data2;
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

        if(y_in_row_cnt<=3 && y_in_col_cnt<=3)begin
            Y [y_in_row_cnt][y_in_col_cnt]<=in_data1;
        end
    end
    else if(cur_state==CLEAR)begin
        w_in_row_cnt<=0; w_in_col_cnt<=0;   //input cnt
        x_in_row_cnt<=0; x_in_col_cnt<=0;
        y_in_row_cnt<=0; y_in_col_cnt<=0;
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                Wk[i][j]<=8'd0; Wq[i][j]<=8'd0; Wv[i][j]<=8'd0; 
                X[i][j]<=8'd0;
            end
        end

        for(i=0;i<4;i=i+1)begin
            for(j=0;j<4;j=j+1)begin
                Y [i][j]<=6'd0;
            end
        end
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        global_cnt<=0;
    end
    else if(cur_state==EVAL_KQV|cur_state==EVAL_A||cur_state==EVAL_scale||
    cur_state==EVAL_relu || cur_state==EVAL_SV || cur_state==EVAL_mul_D)begin
        global_cnt<=global_cnt+1;
    end
    else if(cur_state==CLEAR)begin
        global_cnt<=0;
    end
end
//========================

//===step 1 EVAL_KQV===
//Part 3 Seq Logic
reg signed [15:0] K [0:7][0:7];    
reg signed [15:0] Q [0:7][0:7];    
reg signed [15:0] V [0:7][0:7];
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
        //big & small cnt
        if(xw_big_cnt<7 && xw_small_cnt==7)begin
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
    else if(cur_state==CLEAR)begin      //做不必要的shift最好
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                K[i][j]<=16'd0; Q[i][j]<=16'd0; V[i][j]<=16'd0;
            end
        end
        xw_big_cnt<=0; xw_small_cnt<=0;
    end
end
//=====================

//step 2 EVAL_A:    ASP=QK^T
//step 3 EVAL_scale:ASP=ASP/3
//step 4 EVAL_relu  ASP=ASP_relu 
//step 5 EVAL_SV    ASP=ASP*V

//Part 3 Seq Logic
reg signed [47:0] ASP [0:7][0:7];   //D*P就邊做邊輸出, 不要存(林天神說可以)
reg [3:0] A_big_cnt, A_small_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        A_big_cnt<=0; A_small_cnt<=0;
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                ASP[i][j]<=0;
            end
        end
    end
    else if(cur_state==EVAL_A)begin
        //cnt control
        if(A_big_cnt==7 && A_small_cnt==7)begin
            A_big_cnt<=0;  A_small_cnt<=0;
        end
        else if(A_big_cnt<7 && A_small_cnt==7)begin
            A_big_cnt<=A_big_cnt+1;  A_small_cnt<=0;
        end
        else begin
            A_big_cnt<=A_big_cnt;    A_small_cnt<=A_small_cnt+1;
        end
        //EVAL
        ASP [A_big_cnt][A_small_cnt]<=Q[A_big_cnt][0]*K[0][A_small_cnt]+
                                        Q[A_big_cnt][1]*K[1][A_small_cnt]+
                                        Q[A_big_cnt][2]*K[2][A_small_cnt]+
                                        Q[A_big_cnt][3]*K[3][A_small_cnt]+
                                        Q[A_big_cnt][4]*K[4][A_small_cnt]+
                                        Q[A_big_cnt][5]*K[5][A_small_cnt]+
                                        Q[A_big_cnt][6]*K[6][A_small_cnt]+
                                        Q[A_big_cnt][7]*K[7][A_small_cnt];
    end
    else if(cur_state==EVAL_scale)begin
        //cnt control
        if(A_big_cnt==7 && A_small_cnt==7)begin
            A_big_cnt<=0;  A_small_cnt<=0;
        end
        else if(A_big_cnt<7 && A_small_cnt==7)begin
            A_big_cnt<=A_big_cnt+1;  A_small_cnt<=0;
        end
        else begin
            A_big_cnt<=A_big_cnt;    A_small_cnt<=A_small_cnt+1;
        end
        //EVAL
        ASP [A_big_cnt][A_small_cnt]<=ASP [A_big_cnt][A_small_cnt]/3;
    end
    else if(cur_state==EVAL_relu)begin
        //cnt control
        if(A_big_cnt==7 && A_small_cnt==7)begin
            A_big_cnt<=0;  A_small_cnt<=0;
        end
        else if(A_big_cnt<7 && A_small_cnt==7)begin
            A_big_cnt<=A_big_cnt+1;  A_small_cnt<=0;
        end
        else begin
            A_big_cnt<=A_big_cnt;    A_small_cnt<=A_small_cnt+1;
        end
        //EVAL
        if(ASP [A_big_cnt][A_small_cnt]<0) ASP [A_big_cnt][A_small_cnt]<=0;
    end
    else if(cur_state==EVAL_SV)begin
        //cnt control
        if(A_big_cnt==7 && A_small_cnt==7)begin
            A_big_cnt<=0;  A_small_cnt<=0;
        end
        else if(A_big_cnt<7 && A_small_cnt==7)begin
            A_big_cnt<=A_big_cnt+1;  A_small_cnt<=0;
        end
        else begin
            A_big_cnt<=A_big_cnt;    A_small_cnt<=A_small_cnt+1;
        end
        //EVAL (P=SV)
        ASP [A_big_cnt][A_small_cnt]<=ASP[A_big_cnt][0]*V[0][A_small_cnt]+
                                        ASP[A_big_cnt][1]*V[1][A_small_cnt]+
                                        ASP[A_big_cnt][2]*V[2][A_small_cnt]+
                                        ASP[A_big_cnt][3]*V[3][A_small_cnt]+
                                        ASP[A_big_cnt][4]*V[4][A_small_cnt]+
                                        ASP[A_big_cnt][5]*V[5][A_small_cnt]+
                                        ASP[A_big_cnt][6]*V[6][A_small_cnt]+
                                        ASP[A_big_cnt][7]*V[7][A_small_cnt];
    end
end

//用global_cnt控制就好，拆16+1 cycle

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=0;   out_data<=92'd0;
    end
    else begin
        out_valid<=0;   out_data<=92'd0;
    end
end

//Part 2 Comb Logic
endmodule

module det_eval_part1(
    k,p,l,o,
    part_1_det_out
);
    //先x=kp-lo
    assign part_1_det_out=(k*p)-(l*o);

endmodule

module det_eval_part2(
    neg_bool,a,f,part_1_det_in
    part_2_det_out
);
    //再a*f*x, 一定要切,分兩段
    always@(*)begin
        if(neg_bool==0) part_2_det_out=a*f*part_1_det_in;
        else part_2_det_out=-a*f*part_1_det_in;
    end

endmodule