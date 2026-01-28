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
parameter IDLE=4'd0, INPUT_1=4'd1, WAIT=4'd2, INPUT_2=4'd3,READ_sram_and_diverse=4'd14;
parameter EVAL_intra_4X4=4'd4,EVAL_4X4=4'd5,EVAL_intra_16X16=4'd6,EVAL_16X16=4'd7; 
parameter OUT_4X4=4'd8, OUT_16X16=4'd9, EVAL_rec_4X4=4'd10,EVAL_rec_16X16=4'd11; 
parameter CLEAR_small=4'd12, CLEAR_big=4'd13;

//input buf for input_data
reg [7:0] data_q;

//input buf for in_valid_param
reg [2:0] in_valid_param_cnt;
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
            //包含分流(用mode_q_arr判斷)
        end

        EVAL_intra_4X4: begin
        end
        EVAL_4X4: begin
        end
        OUT_4X4: begin
        end
        EVAL_rec_4X4: begin
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
        read_sram_cnt<=11'd0; 
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