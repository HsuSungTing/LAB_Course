module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
    in_data,
    out_idle,
    out_valid,
    out_data,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake
);

input             clk;
input             rst_n;
input             in_valid;
input      [31:0] in_data;
input             out_idle;
output reg        out_valid;
output reg [31:0] out_data;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

//Part 1 FSM (& tag)
reg [1:0] cur_state,next_state;
parameter IDLE=2'd0, INPUT=2'd1, OUTPUT=2'd2, CLEAR=2'd3;

//Part 1 FSM tag
reg [4:0] input_cnt;
reg [4:0] output_cnt;

reg [31:0] input_data [0:15];

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
            //有接到input就可以開始傳了
            if(input_cnt>=1) next_state=OUTPUT;  
            else next_state=INPUT;
        end
        OUTPUT: begin
            //傳完16筆就休息
            if(output_cnt >= 16) next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end
//out_idle==1時才能輸出, 送完之後就clear就好, 等下一組inupt進來

//Part 3 Seq Logic: take input
integer i;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        input_cnt<=5'd0;
        for(i=0;i<16;i=i+1)begin
            input_data [i]<=32'd0;
        end
    end
    else if(in_valid==1'b1)begin
        input_cnt<=input_cnt+1;
        input_data [input_cnt]<=in_data;
    end
    else if(cur_state==CLEAR)begin
        input_cnt<=5'd0;
        for(i=0;i<16;i=i+1)begin
            input_data [i]<=32'd0;
        end
    end
end

//Part 3 Seq Logic: OUTPUT
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        output_cnt<=0; out_valid<=1'b0; out_data<=32'd0;
    end
    else if(cur_state==OUTPUT && output_cnt<=15)begin
        if(out_idle==1'b0)begin
            output_cnt<=output_cnt+1; out_valid<=1'b1; out_data<=input_data[output_cnt];
        end
        else begin
            output_cnt<=output_cnt; out_valid<=1'b0; out_data<=32'd0;
        end
    end
    else begin
        output_cnt<=0; out_valid<=1'b0; out_data<=32'd0;
    end
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    in_data,
    fifo_full,
    out_valid,
    out_data,
    busy,
    
    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input             clk;
input             rst_n;
input             in_valid;
input             fifo_full;
input      [31:0] in_data;
output reg        out_valid;
output reg [15:0] out_data;
output            busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

endmodule

module CLK_3_MODULE (
    clk,
    rst_n,
    fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_fifo_to_clk3,
    flag_clk3_to_fifo
);

input             clk;
input             rst_n;
input             fifo_empty;
input      [15:0] fifo_rdata;
output reg        fifo_rinc;
output reg        out_valid;
output reg [15:0] out_data;

// You can change the input / output of the custom flag ports
input  flag_fifo_to_clk3;
output flag_clk3_to_fifo;

//每接到一筆就輸出一筆,當fifo_empty不為1就可以要求接收下一筆, output_cnt

//Part 1 FSM (& tag)
reg [1:0] cur_state,next_state;
parameter OUTPUT=2'd1, CLEAR=2'd2;
reg [7:0] output_cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cur_state<=OUTPUT;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        OUTPUT: begin
            //傳完16筆就休息
            if(output_cnt >= 128) next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=OUTPUT;
        default: next_state=OUTPUT;
    endcase
end

//part 3 Seq Logic 
reg fifo_empty_q ;
reg fifo_empty_qq;

//fifo_rinc
always @(*)begin 
    if(fifo_empty==1'b1) fifo_rinc=1'b0;
    else fifo_rinc=1'b1;
end

//fifo_empty
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) fifo_empty_q <= 1'b1;
    else fifo_empty_q <= fifo_empty;
end

//fifo_empty_qq
always @(posedge clk or negedge rst_n)begin 
    if(!rst_n) fifo_empty_qq <= 1'b1;
    else fifo_empty_qq <= fifo_empty_q;
end

//Part 3 Seq Logic for OUTPUT
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_valid<=1'b0; out_data<=16'd0;
        output_cnt<=output_cnt;
    end
    else if(cur_state==OUTPUT)begin
        if(fifo_empty_qq==1'b0)begin
            out_valid<=1'b1; out_data<=fifo_rdata;
            output_cnt<=output_cnt+1;
        end
        else begin
            out_valid<=1'b0; out_data<=16'd0;
            output_cnt<=output_cnt;
        end
    end
end

endmodule