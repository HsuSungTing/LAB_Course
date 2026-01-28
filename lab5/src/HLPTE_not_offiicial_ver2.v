module HLPTE(
    // input signals
    clk,rst_n,in_valid_data,in_valid_param,
    data,index,mode,QP,
    // output signals
    out_valid,out_value
);

input                    clk, rst_n, in_valid_data, in_valid_param;
input              [7:0] data;
input              [3:0] index;
input                    mode;
input              [4:0] QP;
output reg               out_valid;
output reg signed [31:0] out_value;

//Part 1: FSM (FSM Tag)
reg [3:0] cur_state, next_state;
parameter IDLE=4'd0, INPUT_1=4'd1, WAIT=4'd2, INPUT_2=4'd3, READ_sram_and_diverse=4'd14;
parameter EVAL_intra_4X4=4'd4,EVAL_4X4=4'd5,EVAL_intra_16X16=4'd6,EVAL_16X16=4'd7; 
parameter OUT_4X4=4'd8, OUT_16X16=4'd9, EVAL_rec_4X4=4'd10,EVAL_rec_16X16=4'd11; 
parameter CLEAR_small=4'd12, CLEAR_big=4'd13;

//FSM Tag
reg [2:0] in_valid_param_cnt;
reg READ_sram_done;
reg EVAL_intra_4X4_done, EVAL_intra_16X16_done;

//input buf for input_data
reg [7:0] data_q;

//input buf for in_valid_param
reg mode_q_arr[0:3];
reg [4:0] QP_q;
reg [3:0] set_idx_q;

//只是放到這裡
reg [3:0] in_sram_idx; 
reg [4:0] in_sram_row, in_sram_col;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid_data==1'b1)next_state=INPUT_1;
            else next_state=IDLE;
        end
        INPUT_1: begin  //放滿了
            if(in_sram_idx==15&&in_sram_row==31&&in_sram_col==31)next_state=WAIT;
            else next_state=INPUT_1;
        end
        WAIT: begin
            if(in_valid_param==1'b1)next_state=INPUT_2;
            else next_state=WAIT;
        end
        INPUT_2: begin
            if(in_valid_param_cnt>=3'd3)next_state=READ_sram_and_diverse;
            else next_state=INPUT_2;
        end
        READ_sram_and_diverse: begin
            if(READ_sram_done==1'b1&&mode_q_arr[0]==1'b1)next_state=EVAL_intra_4X4;
            else if(READ_sram_done==1'b1&&mode_q_arr[0]==1'b0)next_state=EVAL_intra_16X16;
            else next_state=READ_sram_and_diverse;
        end

        EVAL_intra_4X4: begin
            if(EVAL_intra_4X4_done==1'b1) next_state=EVAL_4X4;
            else next_state=EVAL_intra_4X4;
        end
        EVAL_4X4: begin
        end
        OUT_4X4: begin
        end
        EVAL_rec_4X4: begin
            next_state=EVAL_intra_4X4;
        end

        EVAL_intra_16X16: begin
            if(EVAL_intra_16X16_done==1'b1) next_state=EVAL_16X16;
            else next_state=EVAL_intra_16X16;
        end
        EVAL_16X16: begin
        end
        OUT_16X16: begin
        end
        EVAL_rec_16X16: begin
        end
        
        CLEAR_small: next_state=WAIT;
        CLEAR_big: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 3 Seq Logic
reg sram_WEB;
reg [7:0] sram_din;
reg [13:0] sram_addr;
wire [7:0] sram_dout;

//Part 2 Comb Logic
reg [4:0] read_sram_row, read_sram_col; //(只是放到這裡來)
always @(*)begin
    if(cur_state==INPUT_1)begin //sram write
        sram_WEB=1'b0;
        sram_addr={in_sram_idx, in_sram_row, in_sram_col};
        sram_din=data_q;
    end
    else if(cur_state==READ_sram_and_diverse)begin
        sram_WEB=1'b1;
        sram_addr={set_idx_q, read_sram_row, read_sram_col};
        sram_din=data_q;
    end
    else begin
        sram_WEB=1'b1;
        sram_addr={set_idx_q, read_sram_row, read_sram_col};
        sram_din=data_q;
    end
end

//Part 3 Seq Logic: sram input
//reg [3:0] in_sram_idx; 
//reg [4:0] in_sram_row, in_sram_col;
MEM_wrapper sram(.clk(clk),.A(sram_addr),.DI(sram_din),.WEB(sram_WEB),.CS(1'b1),.OE(1'b1),.DO(sram_dout));

//Part 3 Seq Logic INPUT_1 (data存入也會慢一拍)
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) data_q<=8'd0;
    else if(in_valid_data==1'b1) data_q<=data;
    else data_q<=8'd0;
end

//Part 3 Seq Logic INPUT_2 (data存入也會慢一拍)
integer i,j;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        in_valid_param_cnt<=3'd0;
        QP_q<=5'd0; set_idx_q<=4'd0;
        for(i=0;i<4;i=i+1)mode_q_arr[i]<=1'b0;
    end
    else if(in_valid_param==1'b1)begin
        in_valid_param_cnt<=in_valid_param_cnt+1'd1;
        if(in_valid_param_cnt<=3)mode_q_arr[in_valid_param_cnt]<=mode;
        if(in_valid_param_cnt==0)begin
            QP_q<=QP; set_idx_q<=index;
        end
    end
    else if(cur_state==CLEAR_small)begin
        in_valid_param_cnt<=3'd0;
        QP_q<=5'd0; set_idx_q<=4'd0;
        for(i=0;i<4;i=i+1)mode_q_arr[i]<=1'b0;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        in_sram_idx<=4'd0; in_sram_row<=5'd0; in_sram_col<=5'd0;
    end
    else if(cur_state==INPUT_1)begin
        if(in_sram_col==31&&in_sram_row==31)begin       //存完一張img了
            in_sram_col<=4'd0; in_sram_row<=4'd0; 
            in_sram_idx<=in_sram_idx+1;
        end
        else if(in_sram_col==31&&in_sram_row<31)begin   //下個row
            in_sram_col<=4'd0; in_sram_row<=in_sram_row+1; 
            in_sram_idx<=in_sram_idx;
        end
        else begin                                      //下個element
            in_sram_col<=in_sram_col+1'd1; in_sram_row<=in_sram_row; 
            in_sram_idx<=in_sram_idx;
        end
    end
end

//Part 3 Seq Logic Read SRAM (存入img_reg)
reg [10:0] read_sram_cnt;
reg [4:0] save_reg_row, save_reg_col;
//reg [4:0] read_sram_row, read_sram_col;
reg [7:0] img_reg [0:31][0:31]; //助教開了，我們就開，但其他人是只開16*16;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        read_sram_cnt<=11'd0; READ_sram_done<=1'b0;
        save_reg_row<=5'd0; save_reg_col<=5'd0;
        read_sram_row<=5'd0; read_sram_col<=5'd0;
        for(i=0;i<32;i=i+1)begin
            for(j=0;j<32;j=j+1)begin
                img_reg[i][j]<=8'd0;
            end
        end
    end
    else if(cur_state==READ_sram_and_diverse&&read_sram_cnt<=1024)begin  //會用一個cnt
        read_sram_cnt<=read_sram_cnt+1'd1;
        save_reg_row<=read_sram_row;    //會慢一拍
        save_reg_col<=read_sram_col;    //會慢一拍
        //柏叡目前說可以
        if(read_sram_cnt>=1&&read_sram_cnt<=1024)img_reg[save_reg_row][save_reg_col]<=sram_dout;

        if(read_sram_cnt>=0&&read_sram_cnt<=1023)begin
            if(read_sram_col==31)begin
                read_sram_col<=5'd0; read_sram_row<=read_sram_row+1'd1;
            end
            else begin
                read_sram_col<=read_sram_col+1'd1; read_sram_row<=read_sram_row;
            end 
        end

        if(read_sram_cnt==1024)READ_sram_done<=1'b1;
        else READ_sram_done<=READ_sram_done;
    end
end

//Part 2 Comb Logic

//===INTRA_Prediction_DC===
reg [7:0] add8_in0, add8_in1, add8_in2, add8_in3, add8_in4, add8_in5, add8_in6, add8_in7;
wire [15:0]add8_out;

AdderTree8 ADD8(
    .in0(add8_in0),.in1(add8_in1),.in2(add8_in2),.in3(add8_in3),
    .in4(add8_in4),.in5(add8_in5),.in6(add8_in6),.in7(add8_in7),
    .sum_out(add8_out)
);
//==============
//Part 3 Seq Logic
reg [4:0] lf_up_row, lf_up_col; //最左上角的row和col，非常重要

//Part 2 Cpmb Logic: 要先決定邊界
reg [7:0] left_ele [0:15]; 
reg [7:0] up_ele[0:15];
always@(*)begin
    //只要不是在最左邊(lf_up_col==0)，就不是NULL
    if(lf_up_col!=5'd0&&cur_state==EVAL_intra_4X4)begin
        left_ele[0]  = img_reg[lf_up_row+0][lf_up_col-1];
        left_ele[1]  = img_reg[lf_up_row+1][lf_up_col-1];
        left_ele[2]  = img_reg[lf_up_row+2][lf_up_col-1];
        left_ele[3]  = img_reg[lf_up_row+3][lf_up_col-1];
        left_ele[4]  = 8'd0;
        left_ele[5]  = 8'd0;
        left_ele[6]  = 8'd0;
        left_ele[7]  = 8'd0;
        left_ele[8]  = 8'd0;
        left_ele[9]  = 8'd0;
        left_ele[10] = 8'd0;
        left_ele[11] = 8'd0;
        left_ele[12] = 8'd0;
        left_ele[13] = 8'd0;
        left_ele[14] = 8'd0;
        left_ele[15] = 8'd0;
    end
    else if(lf_up_col!=5'd0&&cur_state==EVAL_intra_16X16)begin
        left_ele[0]  = img_reg[lf_up_row+0][lf_up_col-1];
        left_ele[1]  = img_reg[lf_up_row+1][lf_up_col-1];
        left_ele[2]  = img_reg[lf_up_row+2][lf_up_col-1];
        left_ele[3]  = img_reg[lf_up_row+3][lf_up_col-1];
        left_ele[4]  = img_reg[lf_up_row+4][lf_up_col-1];
        left_ele[5]  = img_reg[lf_up_row+5][lf_up_col-1];
        left_ele[6]  = img_reg[lf_up_row+6][lf_up_col-1];
        left_ele[7]  = img_reg[lf_up_row+7][lf_up_col-1];
        left_ele[8]  = img_reg[lf_up_row+8][lf_up_col-1];
        left_ele[9]  = img_reg[lf_up_row+9][lf_up_col-1];
        left_ele[10] = img_reg[lf_up_row+10][lf_up_col-1];
        left_ele[11] = img_reg[lf_up_row+11][lf_up_col-1];
        left_ele[12] = img_reg[lf_up_row+12][lf_up_col-1];
        left_ele[13] = img_reg[lf_up_row+13][lf_up_col-1];
        left_ele[14] = img_reg[lf_up_row+14][lf_up_col-1];
        left_ele[15] = img_reg[lf_up_row+15][lf_up_col-1];
    end
    else begin
        for(i=0;i<15;i=i+1)left_ele[i]=8'd0;
    end
end

always@(*)begin
    //只要不是在最上面(lf_up_row==0)，就不是NULL
    if(lf_up_row!=5'd0&&cur_state==EVAL_intra_4X4)begin
        up_ele[0]  = img_reg[lf_up_row-1][lf_up_col+0];
        up_ele[1]  = img_reg[lf_up_row-1][lf_up_col+1];
        up_ele[2]  = img_reg[lf_up_row-1][lf_up_col+2];
        up_ele[3]  = img_reg[lf_up_row-1][lf_up_col+3];
        up_ele[4]  = 8'd0;
        up_ele[5]  = 8'd0;
        up_ele[6]  = 8'd0;
        up_ele[7]  = 8'd0;
        up_ele[8]  = 8'd0;
        up_ele[9]  = 8'd0;
        up_ele[10] = 8'd0;
        up_ele[11] = 8'd0;
        up_ele[12] = 8'd0;
        up_ele[13] = 8'd0;
        up_ele[14] = 8'd0;
        up_ele[15] = 8'd0;
    end
    else if(lf_up_row!=5'd0&&cur_state==EVAL_intra_16X16)begin
        up_ele[0]  = img_reg[lf_up_row-1][lf_up_col+0];
        up_ele[1]  = img_reg[lf_up_row-1][lf_up_col+1];
        up_ele[2]  = img_reg[lf_up_row-1][lf_up_col+2];
        up_ele[3]  = img_reg[lf_up_row-1][lf_up_col+3];
        up_ele[4]  = img_reg[lf_up_row-1][lf_up_col+4];
        up_ele[5]  = img_reg[lf_up_row-1][lf_up_col+5];
        up_ele[6]  = img_reg[lf_up_row-1][lf_up_col+6];
        up_ele[7]  = img_reg[lf_up_row-1][lf_up_col+7];
        up_ele[8]  = img_reg[lf_up_row-1][lf_up_col+8];
        up_ele[9]  = img_reg[lf_up_row-1][lf_up_col+9];
        up_ele[10] = img_reg[lf_up_row-1][lf_up_col+10];
        up_ele[11] = img_reg[lf_up_row-1][lf_up_col+11];
        up_ele[12] = img_reg[lf_up_row-1][lf_up_col+12];
        up_ele[13] = img_reg[lf_up_row-1][lf_up_col+13];
        up_ele[14] = img_reg[lf_up_row-1][lf_up_col+14];
        up_ele[15] = img_reg[lf_up_row-1][lf_up_col+15];
    end
    else begin
        for(i=0;i<15;i=i+1)up_ele[i]=8'd0;
    end
end

//Part 3 Seq Logic
reg [9:0] DC_predict;               //算出DC的predict讓SAD使用，最多32*255，開10 bit夠

reg [17:0] SAD_DC, SAD_H, SAD_V;    //最多255*255，SAD只會用來比大小
reg [7:0] SAD_cnt;
reg [4:0] cur_SAD_row_offset, cur_SAD_col_offset;
reg [1:0] intra_mode;               //DC(0) or H(1) or V(2)

//Part 2 Comb Logic
reg [2:0] DC_cnt;
reg [2:0] DC_case;  //決定要>>2(0) or >>3(1) or >>4(2) or>>5(3) or 128 (7)

always@(*)begin
    //case 16X16 T&L 都有
    if(cur_state==EVAL_intra_16X16 && lf_up_row>0 && lf_up_col>0)begin
        DC_case=3'd3;   //>>5
        if(DC_cnt==0)begin
            add8_in0=left_ele[0];
            add8_in1=left_ele[1];
            add8_in2=left_ele[2];
            add8_in3=left_ele[3];
            add8_in4=left_ele[4];
            add8_in5=left_ele[5];
            add8_in6=left_ele[6];
            add8_in7=left_ele[7];
        end
        else if(DC_cnt==1)begin
            add8_in0=left_ele[8];
            add8_in1=left_ele[9];
            add8_in2=left_ele[10];
            add8_in3=left_ele[11];
            add8_in4=left_ele[12];
            add8_in5=left_ele[13];
            add8_in6=left_ele[14];
            add8_in7=left_ele[15];
        end
        else if(DC_cnt==2)begin
            add8_in0=up_ele[0];
            add8_in1=up_ele[1];
            add8_in2=up_ele[2];
            add8_in3=up_ele[3];
            add8_in4=up_ele[4];
            add8_in5=up_ele[5];
            add8_in6=up_ele[6];
            add8_in7=up_ele[7];
        end
        else if(DC_cnt==3)begin
            add8_in0=up_ele[8];
            add8_in1=up_ele[9];
            add8_in2=up_ele[10];
            add8_in3=up_ele[11];
            add8_in4=up_ele[12];
            add8_in5=up_ele[13];
            add8_in6=up_ele[14];
            add8_in7=up_ele[15];
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    //case 16X16 只有T(左邊)
    else if(cur_state==EVAL_intra_16X16 && lf_up_row==0 && lf_up_col>0)begin
        DC_case=3'd2;   //>>4
        if(DC_cnt==0)begin
            add8_in0=left_ele[0];
            add8_in1=left_ele[1];
            add8_in2=left_ele[2];
            add8_in3=left_ele[3];
            add8_in4=left_ele[4];
            add8_in5=left_ele[5];
            add8_in6=left_ele[6];
            add8_in7=left_ele[7];
        end
        else if(DC_cnt==1)begin
            add8_in0=left_ele[8];
            add8_in1=left_ele[9];
            add8_in2=left_ele[10];
            add8_in3=left_ele[11];
            add8_in4=left_ele[12];
            add8_in5=left_ele[13];
            add8_in6=left_ele[14];
            add8_in7=left_ele[15];
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    //case 16X16 只有L(上面)
    else if(cur_state==EVAL_intra_16X16 && lf_up_row>0 && lf_up_col==0)begin
        DC_case=3'd2;   //>>4
        if(DC_cnt==0)begin
            add8_in0=up_ele[0];
            add8_in1=up_ele[1];
            add8_in2=up_ele[2];
            add8_in3=up_ele[3];
            add8_in4=up_ele[4];
            add8_in5=up_ele[5];
            add8_in6=up_ele[6];
            add8_in7=up_ele[7];
        end
        else if(DC_cnt==1)begin
            add8_in0=up_ele[8];
            add8_in1=up_ele[9];
            add8_in2=up_ele[10];
            add8_in3=up_ele[11];
            add8_in4=up_ele[12];
            add8_in5=up_ele[13];
            add8_in6=up_ele[14];
            add8_in7=up_ele[15];
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    //case 4X4 T&L 都有
    else if(cur_state==EVAL_intra_4X4 && lf_up_row>0 && lf_up_col>0)begin
        DC_case=3'd1;   //>>3
        if(DC_cnt==0)begin
            add8_in0=up_ele[0];
            add8_in1=up_ele[1];
            add8_in2=up_ele[2];
            add8_in3=up_ele[3];
            add8_in4=left_ele[4];
            add8_in5=left_ele[5];
            add8_in6=left_ele[6];
            add8_in7=left_ele[7];
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    //case 4X4 只有T(左邊)
    else if(cur_state==EVAL_intra_4X4 && lf_up_row==0 && lf_up_col>0)begin
        DC_case=3'd0;   //>>2
        if(DC_cnt==0)begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=left_ele[4];
            add8_in5=left_ele[5];
            add8_in6=left_ele[6];
            add8_in7=left_ele[7];
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    //case 4X4 只有L(上面)
    else if(cur_state==EVAL_intra_4X4 && lf_up_row>0 && lf_up_col==0)begin
        DC_case=3'd0;   //>>2
        if(DC_cnt==0)begin
            add8_in0=up_ele[0];
            add8_in1=up_ele[1];
            add8_in2=up_ele[2];
            add8_in3=up_ele[3];
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
        else begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=8'd0;
            add8_in5=8'd0;
            add8_in6=8'd0;
            add8_in7=8'd0;
        end
    end
    else if((cur_state==EVAL_intra_4X4 || cur_state==EVAL_intra_16X16)
    && lf_up_row==0 && lf_up_col==0)begin
        DC_case=3'd7;   //128
        add8_in0=8'd0;
        add8_in1=8'd0;
        add8_in2=8'd0;
        add8_in3=8'd0;
        add8_in4=8'd0;
        add8_in5=8'd0;
        add8_in6=8'd0;
        add8_in7=8'd0;
    end
    else begin
        DC_case=3'd7;   //128
        add8_in0=8'd0;
        add8_in1=8'd0;
        add8_in2=8'd0;
        add8_in3=8'd0;
        add8_in4=8'd0;
        add8_in5=8'd0;
        add8_in6=8'd0;
        add8_in7=8'd0;
    end
end

//Part 2 Comb Logic 用offset選擇cur_H_predict和cur_V_predict
//就都算，最後選擇再看cur_H_predict, cur_V_predict是否valid
reg [7:0] cur_DC_predict, cur_H_predict, cur_V_predict;
always@(*)begin
    cur_DC_predict=DC_predict;
    //cur_H_predict，會用到left_ele (橫著填)
    if(cur_state==EVAL_intra_16X16)begin
        if(cur_SAD_row_offset==5'd0)cur_H_predict=left_ele[0];
        else if(cur_SAD_row_offset==5'd1)cur_H_predict=left_ele[1];
        else if(cur_SAD_row_offset==5'd2)cur_H_predict=left_ele[2];
        else if(cur_SAD_row_offset==5'd3)cur_H_predict=left_ele[3];
        else if(cur_SAD_row_offset==5'd4)cur_H_predict=left_ele[4];
        else if(cur_SAD_row_offset==5'd5)cur_H_predict=left_ele[5];
        else if(cur_SAD_row_offset==5'd6)cur_H_predict=left_ele[6];
        else if(cur_SAD_row_offset==5'd7)cur_H_predict=left_ele[7];
        else if(cur_SAD_row_offset==5'd8)cur_H_predict=left_ele[8];
        else if(cur_SAD_row_offset==5'd9)cur_H_predict=left_ele[9];
        else if(cur_SAD_row_offset==5'd10)cur_H_predict=left_ele[10];
        else if(cur_SAD_row_offset==5'd11)cur_H_predict=left_ele[11];
        else if(cur_SAD_row_offset==5'd12)cur_H_predict=left_ele[12];
        else if(cur_SAD_row_offset==5'd13)cur_H_predict=left_ele[13];
        else if(cur_SAD_row_offset==5'd14)cur_H_predict=left_ele[14];
        else if(cur_SAD_row_offset==5'd15)cur_H_predict=left_ele[15];
        else cur_H_predict=8'd0;    //NULL
    end
    else if(cur_state==EVAL_intra_4X4)begin
        if(cur_SAD_row_offset==5'd0)cur_H_predict=left_ele[0];
        else if(cur_SAD_row_offset==5'd1)cur_H_predict=left_ele[1];
        else if(cur_SAD_row_offset==5'd2)cur_H_predict=left_ele[2];
        else if(cur_SAD_row_offset==5'd3)cur_H_predict=left_ele[3];
        else cur_H_predict=8'd0;    //NULL
    end
    else cur_H_predict=8'd0;    //NULL

    if(cur_state==EVAL_intra_16X16)begin
        if(cur_SAD_col_offset==5'd0)cur_V_predict=up_ele[0];
        else if(cur_SAD_col_offset==5'd1)cur_V_predict=up_ele[1];
        else if(cur_SAD_col_offset==5'd2)cur_V_predict=up_ele[2];
        else if(cur_SAD_col_offset==5'd3)cur_V_predict=up_ele[3];
        else if(cur_SAD_col_offset==5'd4)cur_V_predict=up_ele[4];
        else if(cur_SAD_col_offset==5'd5)cur_V_predict=up_ele[5];
        else if(cur_SAD_col_offset==5'd6)cur_V_predict=up_ele[6];
        else if(cur_SAD_col_offset==5'd7)cur_V_predict=up_ele[7];
        else if(cur_SAD_col_offset==5'd8)cur_V_predict=up_ele[8];
        else if(cur_SAD_col_offset==5'd9)cur_V_predict=up_ele[9];
        else if(cur_SAD_col_offset==5'd10)cur_V_predict=up_ele[10];
        else if(cur_SAD_col_offset==5'd11)cur_V_predict=up_ele[11];
        else if(cur_SAD_col_offset==5'd12)cur_V_predict=up_ele[12];
        else if(cur_SAD_col_offset==5'd13)cur_V_predict=up_ele[13];
        else if(cur_SAD_col_offset==5'd14)cur_V_predict=up_ele[14];
        else if(cur_SAD_col_offset==5'd15)cur_V_predict=up_ele[15];
        else cur_V_predict=8'd0;    //NULL
    end
    else if(cur_state==EVAL_intra_4X4)begin
        if(cur_SAD_col_offset==5'd0)cur_V_predict=up_ele[0];
        else if(cur_SAD_col_offset==5'd1)cur_V_predict=up_ele[1];
        else if(cur_SAD_col_offset==5'd2)cur_V_predict=up_ele[2];
        else if(cur_SAD_col_offset==5'd3)cur_V_predict=up_ele[3];
        else cur_V_predict=8'd0;    //NULL
    end
    else cur_V_predict=8'd0;    //NULL
end

//Part 2 Comb Logic 用SAD選擇出intra_mode
//要再和gpt確認

reg [1:0] intra_mode_choice; //DC(0) or H(1) or V(2)
always@(*)begin
    if(lf_up_col==0 && lf_up_row==0) intra_mode_choice=2'd0; //DC only
    else if(lf_up_row>0 && lf_up_col==0) begin
        //上面有東西可以參考，但左邊沒有
        if(SAD_DC<=SAD_V)intra_mode_choice=2'd0; //DC優先
        else intra_mode_choice=2'd2;             //V
    end
    else if(lf_up_row==0 && lf_up_col>0) begin
        //左邊有東西可以參考，但上面沒有
        if(SAD_DC<=SAD_H)intra_mode_choice=2'd0; //DC優先
        else intra_mode_choice=2'd1;             //H
    end
    else if(lf_up_row>0 && lf_up_col>0) begin
        //左邊和上面都有東西可以參考
        if(SAD_DC<=SAD_H && SAD_DC<=SAD_V) intra_mode_choice=2'd0;  //DC優先
        else if(SAD_H<=SAD_V) intra_mode_choice=2'd1;               //H次之
        else intra_mode_choice=2'd2;                                //V最後
    end
end

//EVAL_4X4 or EVAL_16X16
reg signed [31:0] cur_4X4[0:3][0:3];
//step 1 X=I(用img_reg)-predict(來自comb logic和intra直接一樣)
//step 2 W=Cf X Cf (各用一個comb logic())
//step 3 cycle 1:記下W的16個sign，開一個16個的乘法器(unsigned)，cycle 2 加法&shift q再補上signed
//step 4 輸出

//Part 3 Seq Logic 
reg DC_predict_done, SAD_done; //EVAL_intra的內部tag
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===for DC===
        lf_up_row<=5'd0; lf_up_col<=5'd0; //最左上角的row和col，非常重要!!!
        DC_cnt<=3'd0; 
        DC_predict_done<=1'b0; DC_predict<=32'd0;
        //==for SAD===
        SAD_done<=1'b0; SAD_cnt<=8'd0; 
        SAD_DC<=18'd0; SAD_V<=18'd0; SAD_H<=18'd0; 
        cur_SAD_row_offset<=5'd0; cur_SAD_col_offset<=5'd0;
        EVAL_intra_4X4_done<=1'b0; EVAL_intra_16X16_done<=1'b0;
        //=============
        intra_mode<=2'd0;
    end
    else if(cur_state==EVAL_intra_4X4)begin
        //case 0 DC_predict尚未算完  (1 cycle)
        if(DC_predict_done==0)begin
            if(DC_case==1) DC_predict<=(DC_predict+add8_out)>>3;
            else if(DC_case==0) DC_predict<=(DC_predict+add8_out)>>2;
            else if(DC_case==7) DC_predict<=10'd128;
            else DC_predict<=10'd128;
            DC_predict_done<=1'b1;      //4*4只算一個cycle
        end
        //case 1 開始累加DC H V的SAD (4*4累加16 cycle，SAD都是正的，會先比大小再做減法)
        else if(DC_predict_done==1'b1 && SAD_done==1'b0)begin
            SAD_cnt<=SAD_cnt+1;
            //更新cur_SAD_row_offset、cur_SAD_col_offset (4X4)
            if(cur_SAD_col_offset==3)begin
                cur_SAD_col_offset<=0; cur_SAD_row_offset<=cur_SAD_row_offset+1;
            end
            else begin
                cur_SAD_col_offset<=cur_SAD_col_offset+1; cur_SAD_row_offset<=cur_SAD_row_offset;
            end

            //DC SAD (cur_DC_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_DC_predict)
                SAD_DC<=SAD_DC+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_DC_predict);
            else SAD_DC<=SAD_DC+(cur_DC_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            //H SAD (cur_H_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_H_predict)
                SAD_H<=SAD_H+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_H_predict);
            else SAD_H<=SAD_H+(cur_H_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            //V SAD (cur_V_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_V_predict)
                SAD_V<=SAD_V+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_V_predict);
            else SAD_V<=SAD_V+(cur_V_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);

            if(SAD_cnt==15)SAD_done<=1'b1;
            else SAD_done<=SAD_done;
        end
        //case 2 比大小並選擇並記錄當前的INTRA_prediction_mode不變(後續以此算predict)
        else if(DC_predict_done==1'b1 && SAD_done==1'b1)begin
            intra_mode<=intra_mode_choice; EVAL_intra_4X4_done<=1'b1;
        end
    end
    else if(cur_state==EVAL_intra_16X16)begin
        //case 0 DC_predict尚未算完  (0到4 cycle)
        if(DC_predict_done==0)begin
            DC_cnt<=DC_cnt+1; 
            if(DC_cnt>=3)begin  //算完四步了
                DC_predict_done<=1'b1;
                if(DC_case==3) DC_predict<=(DC_predict+add8_out)>>5;
                else if(DC_case==2) DC_predict<=(DC_predict+add8_out)>>4;
                else if(DC_case==7) DC_predict<=10'd128;
                else DC_predict<=10'd128;
            end
            else begin          //還沒算完
                DC_predict_done<=DC_predict_done;
                DC_predict<=DC_predict+add8_out;
            end
        end
        //case 1 開始累加DC H V的SAD (16*16累加256 cycle，SAD都是正的，會先比大小再做減法)
        else if(DC_predict_done==1'b1 && SAD_done==1'b0)begin
            SAD_cnt<=SAD_cnt+1;

            //更新cur_SAD_row_offset、cur_SAD_col_offset (16X16)
            if(cur_SAD_col_offset==15)begin
                cur_SAD_col_offset<=0; cur_SAD_row_offset<=cur_SAD_row_offset+1;
            end
            else begin
                cur_SAD_col_offset<=cur_SAD_col_offset+1; cur_SAD_row_offset<=cur_SAD_row_offset;
            end

            //DC SAD (cur_DC_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_DC_predict)
                SAD_DC<=SAD_DC+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_DC_predict);
            else SAD_DC<=SAD_DC+(cur_DC_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            
            //H SAD (cur_H_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_H_predict)
                SAD_H<=SAD_H+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_H_predict);
            else SAD_H<=SAD_H+(cur_H_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            
            //V SAD (cur_V_predict是用目前[cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_V_predict)
                SAD_V<=SAD_V+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_V_predict);
            else SAD_V<=SAD_V+(cur_V_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);

            if(SAD_cnt==255)SAD_done<=1'b1;
            else SAD_done<=SAD_done;
        end
        //case 2 比大小並選擇並記錄當前的INTRA_prediction_mode不變(後續以此算predict)
        else if(DC_predict_done==1'b1 && SAD_done==1'b1)begin
            intra_mode<=intra_mode_choice; EVAL_intra_16X16_done<=1'b1;
        end
    end

    else if(cur_state==EVAL_4X4)begin
        //做各種矩陣乘法，並且把結果暫存在reg [31:0] cur_4X4 [0:4][0:4]
        //算到Z為止
    end
    else if(cur_state==OUT_4X4)begin
        //輸出 cur_4X4
    end
    else if(cur_state==EVAL_rec_4X4)begin
        //把step 7的結果存回img_reg
        //更新 lt_up_row(+4),lt_up_col(+4) (非常重要!!)
        //go_EVAL_intra_4X4
    end
    
    else if(cur_state==EVAL_16X16)begin
        //做各種矩陣乘法，並且把結果暫存在reg [31:0] cur_4X4 [0:4][0:4]
        //算到Z為止
    end
    else if(cur_state==OUT_16X16)begin
        //輸出 cur_4X4
    end
    else if(cur_state==EVAL_rec_4X4)begin
        //把step 7的結果存回img_reg
        //case 1(如果做完16次)更新 lt_up_row(+4),lt_up_col(+4)(跳到另一個第二個16X16的大blk)且go_EVAL_intra_16X16 (非常重要!!)
        //case 2(16次還沒做完) 更新 lt_up_row(+4),lt_up_col(+4)原本的INTRA_PREDICTION_mode不變(以此算predict) (非常重要!!)
    end
end

endmodule

module MEM_wrapper(
    input clk,
    input [13:0] A,
    input [7:0] DI,
    input WEB,
    input CS,
    input OE,
    output [7:0] DO
);
    SRAM_16384_8 SRAM_16384_8_inst (
        .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]),
        .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),
        .A8(A[8]), .A9(A[9]), .A10(A[10]), .A11(A[11]),
        .A12(A[12]), .A13(A[13]),
        .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]),
        .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
        .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]),
        .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
        .CK(clk), .WEB(WEB), .OE(OE), .CS(CS)
    );
endmodule

module AdderTree8 (
    input  [7:0] in0,
    input  [7:0] in1,
    input  [7:0] in2,
    input  [7:0] in3,
    input  [7:0] in4,
    input  [7:0] in5,
    input  [7:0] in6,
    input  [7:0] in7,
    output [15:0] sum_out
);
    wire [8:0] sum_l1_0 = {1'b0, in0} + {1'b0, in1};
    wire [8:0] sum_l1_1 = {1'b0, in2} + {1'b0, in3};
    wire [8:0] sum_l1_2 = {1'b0, in4} + {1'b0, in5};
    wire [8:0] sum_l1_3 = {1'b0, in6} + {1'b0, in7};

    wire [10:0] sum_l2_0 = {2'b0, sum_l1_0} + {2'b0, sum_l1_1};
    wire [10:0] sum_l2_1 = {2'b0, sum_l1_2} + {2'b0, sum_l1_3};

    assign sum_out = {5'b0, sum_l2_0} + {5'b0, sum_l2_1};

endmodule