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

//input buf for input_data
reg [7:0] data_q;

//input buf for in_valid_param
reg mode_q_arr[0:3];
reg [4:0] QP_q;
reg [3:0] set_idx_q;

//只是放到這裡
reg [3:0] in_sram_idx; 
reg [4:0] in_sram_row; 
reg [2:0] in_sram_col;

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
            if(in_sram_idx==15&&in_sram_row==31&&in_sram_col==7)next_state=WAIT;
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
        end
        EVAL_4X4: begin
        end
        OUT_4X4: begin
        end
        EVAL_rec_4X4: begin
            next_state=EVAL_intra_4X4;
        end

        EVAL_intra_16X16: begin
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
reg [31:0] sram_din;    //32 bit，4個拼接
reg [11:0] sram_addr;   //12 bit
wire [31:0] sram_dout;  //32 bit，4個拼接

//Part 2 Comb Logic
reg [4:0] read_sram_row; 
reg [2:0] read_sram_col;    //(只是放到這裡來)
reg [1:0] in_buf_cnt;       //(只是放到這裡來)
reg [7:0] data_q1,data_q2,data_q3,data_q4;  //(只是放到這裡來)
reg [31:0] sram_in_buf;
reg [11:0] sram_write_addr;
reg can_write_bool;

always @(*)begin
    if(cur_state==INPUT_1&&can_write_bool==1'b1)begin      //sram write
        sram_WEB=1'b0;
        sram_addr=sram_write_addr;
        sram_din=sram_in_buf;
    end
    else if(cur_state==READ_sram_and_diverse)begin  //sram read(不影響sram)
        sram_WEB=1'b1;
        sram_addr={set_idx_q, read_sram_row, read_sram_col};
        sram_din=32'd0;
    end
    else begin                                       //sram read(不影響sram)
        sram_WEB=1'b1;
        sram_addr={set_idx_q, read_sram_row, read_sram_col};
        sram_din=32'd0;
    end
end

//Part 3 Seq Logic: sram input
//reg [3:0] in_sram_idx; 
//reg [4:0] in_sram_row;
//reg [2:0] in_sram_col;

MEM_wrapper sram(.clk(clk),.A(sram_addr),.DI(sram_din),.WEB(sram_WEB),.CS(1'b1),.OE(1'b1),.DO(sram_dout));

//Part 3 Seq Logic INPUT_1 (data存入也會慢一拍)
//reg [1:0] in_buf_cnt;
//reg [7:0] data_q1,data_q2,data_q3,data_q4;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        data_q1<=8'd0;data_q2<=8'd0;
        data_q3<=8'd0;data_q4<=8'd0; 
        in_buf_cnt<=0;
    end
    else if(in_valid_data==1'b1)begin 
        in_buf_cnt<=in_buf_cnt+1;
        if(in_buf_cnt==0)data_q1<=data;
        else if(in_buf_cnt==1)data_q2<=data;
        else if(in_buf_cnt==2)data_q3<=data;
        else if(in_buf_cnt==3)data_q4<=data;
    end
    else begin 
        data_q1<=8'd0;data_q2<=8'd0;
        data_q3<=8'd0;data_q4<=8'd0; 
        in_buf_cnt<=0;
    end
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
        in_sram_idx<=4'd0; in_sram_row<=5'd0; in_sram_col<=3'd0;
    end
    else if(cur_state==INPUT_1&&in_buf_cnt==3)begin
        can_write_bool<=1'b1;
        sram_in_buf<={data_q1,data_q2,data_q3,data};
        sram_write_addr<={in_sram_idx, in_sram_row, in_sram_col};
    end
    else if(cur_state==INPUT_1&&in_buf_cnt==0)begin
        if(in_sram_col==7&&in_sram_row==31)begin       //存完一張img了
            in_sram_col<=4'd0; in_sram_row<=4'd0; 
            in_sram_idx<=in_sram_idx+1;
        end
        else if(in_sram_col==7&&in_sram_row<31)begin   //下個row
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
reg [7:0] img_reg [0:31][0:31]; 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        read_sram_cnt<=11'd0; READ_sram_done<=1'b0;
        save_reg_row<=5'd0; save_reg_col<=3'd0;
        read_sram_row<=5'd0; read_sram_col<=3'd0;
        for(i=0;i<32;i=i+1)begin
            for(j=0;j<32;j=j+1)begin
                img_reg[i][j]<=8'd0;
            end
        end
    end
    else if(cur_state==READ_sram_and_diverse&&read_sram_cnt<=256)begin  //會用一個cnt
        read_sram_cnt<=read_sram_cnt+1'd1;
        save_reg_row<=read_sram_row;    //會慢一拍
        save_reg_col<=read_sram_col;    //會慢一拍
        //目前說可以
        if(read_sram_cnt>=1&&read_sram_cnt<=256)begin
            img_reg[save_reg_row][{save_reg_col,2'd0}]<=sram_dout[31:24];
            img_reg[save_reg_row][{save_reg_col,2'd1}]<=sram_dout[23:16];
            img_reg[save_reg_row][{save_reg_col,2'd2}]<=sram_dout[15:8];
            img_reg[save_reg_row][{save_reg_col,2'd3}]<=sram_dout[7:0];
        end

        if(read_sram_cnt>=0&&read_sram_cnt<=255)begin
            if(read_sram_col==7)begin
                read_sram_col<=5'd0; read_sram_row<=read_sram_row+1'd1;
            end
            else begin
                read_sram_col<=read_sram_col+1'd1; read_sram_row<=read_sram_row;
            end 
        end

        if(read_sram_cnt==256)READ_sram_done<=1'b1;
        else READ_sram_done<=READ_sram_done;
    end
end


endmodule

module MEM_wrapper(
    input clk, 
    input [11:0] A, 
    input [31:0] DI, 
    input WEB, 
    input CS, 
    input OE, 
    output [31:0] DO
);
    MEM_4096_32 MEM_4096_32_inst(
        .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]),
        .A8(A[8]), .A9(A[9]), .A10(A[10]), .A11(A[11]),
        .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
        .DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]), .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),
        .DO16(DO[16]), .DO17(DO[17]), .DO18(DO[18]), .DO19(DO[19]), .DO20(DO[20]), .DO21(DO[21]), .DO22(DO[22]), .DO23(DO[23]),
        .DO24(DO[24]), .DO25(DO[25]), .DO26(DO[26]), .DO27(DO[27]), .DO28(DO[28]), .DO29(DO[29]), .DO30(DO[30]), .DO31(DO[31]),
        .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
        .DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]), .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
        .DI16(DI[16]), .DI17(DI[17]), .DI18(DI[18]), .DI19(DI[19]), .DI20(DI[20]), .DI21(DI[21]), .DI22(DI[22]), .DI23(DI[23]),
        .DI24(DI[24]), .DI25(DI[25]), .DI26(DI[26]), .DI27(DI[27]), .DI28(DI[28]), .DI29(DI[29]), .DI30(DI[30]), .DI31(DI[31]),
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