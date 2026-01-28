module MVDM(
    // input signals
    clk,rst_n,in_valid,in_valid2,in_data,
    // output signals
    out_valid,out_sad
);

input clk, rst_n;
input in_valid, in_valid2;
input [8:0] in_data;

output reg out_valid;
output reg out_sad;

//Part 1: FSM (FSM Tag)
reg [3:0] cur_state, next_state;

parameter IDLE=4'd0, INPUT_1=4'd1, WAIT=4'd2, INPUT_2=4'd3; 
parameter EVAL_sram_read=4'd4, EVAL_inter=4'd5, EVAL_SATD=4'd6;
parameter EVAL_max_SATD=4'd7, OUTPUT=4'd8, CLEAR_small=4'd9, CLEAR_big=4'd10;

reg [16:0] Input_1_cnt;     //FSM tag
reg [3:0] Input_2_cnt;
reg [7:0] EVAL_sram_read_cnt;//最多數到227
reg [9:0] global_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid==1'b1)next_state=INPUT_1;
            else next_state=IDLE;
        end
        INPUT_1: begin  
            if(Input_1_cnt=={1'b1, 7'd127, 7'd127}) next_state=WAIT;
            else next_state=INPUT_1;
        end
        WAIT: begin
            if(in_valid2==1'b1)next_state=INPUT_2;
            else next_state=WAIT;
        end
        INPUT_2: begin
            if(Input_2_cnt>=4'd7)next_state=EVAL_sram_read;
            else next_state=INPUT_2;
        end
        EVAL_sram_read:begin 
            if(EVAL_sram_read_cnt>=226) next_state=EVAL_inter;
            else next_state=EVAL_sram_read;
        end
        EVAL_inter: begin
            next_state=EVAL_inter;
        end
        CLEAR_small: next_state=WAIT;       
        CLEAR_big: next_state=IDLE;         
        default: next_state=IDLE;
    endcase
end

//Part 3 Seq Logic for INPUT_2
reg [7:0] MVx_L0_p1, MVy_L0_p1;
reg [7:0] MVx_L1_p1, MVy_L1_p1;
reg [7:0] MVx_L0_p2, MVy_L0_p2;
reg [7:0] MVx_L1_p2, MVy_L1_p2;
reg frac_x_L0_p1, frac_y_L0_p1;
reg frac_x_L1_p1, frac_y_L1_p1;
reg frac_x_L0_p2, frac_y_L0_p2;
reg frac_x_L1_p2, frac_y_L1_p2;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        Input_2_cnt<=0;
        MVx_L0_p1<=0; frac_x_L0_p1<=0;
        MVy_L0_p1<=0; frac_y_L0_p1<=0;
        MVx_L1_p1<=0; frac_x_L1_p1<=0;
        MVy_L1_p1<=0; frac_y_L1_p1<=0;
        MVx_L0_p2<=0; frac_x_L0_p2<=0;
        MVy_L0_p2<=0; frac_y_L0_p2<=0;
        MVx_L1_p2<=0; frac_x_L1_p2<=0;
        MVy_L1_p2<=0; frac_y_L1_p2<=0;
    end
    else if(in_valid2==1'b1)begin
        Input_2_cnt<=Input_2_cnt+1;
        case(Input_2_cnt)
            0: begin
                MVx_L0_p1<=in_data[8:1]; frac_x_L0_p1<=in_data[0];
            end
            1: begin
                MVy_L0_p1<=in_data[8:1]; frac_y_L0_p1<=in_data[0];
            end
            2: begin
                MVx_L1_p1<=in_data[8:1]; frac_x_L1_p1<=in_data[0];
            end
            3: begin
                MVy_L1_p1<=in_data[8:1]; frac_y_L1_p1<=in_data[0];
            end
            4: begin
                MVx_L0_p2<=in_data[8:1]; frac_x_L0_p2<=in_data[0];
            end
            5: begin
                MVy_L0_p2<=in_data[8:1]; frac_y_L0_p2<=in_data[0];
            end
            6: begin
                MVx_L1_p2<=in_data[8:1]; frac_x_L1_p2<=in_data[0];
            end
            7: begin
                MVy_L1_p2<=in_data[8:1]; frac_y_L1_p2<=in_data[0];
            end
            default: begin
                MVy_L1_p2<=MVy_L1_p2; frac_y_L1_p2<=frac_y_L1_p2;
            end
        endcase
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        Input_2_cnt<=0;
        MVx_L0_p1<=0; frac_x_L0_p1<=0;
        MVy_L0_p1<=0; frac_y_L0_p1<=0;
        MVx_L1_p1<=0; frac_x_L1_p1<=0;
        MVy_L1_p1<=0; frac_y_L1_p1<=0;
        MVx_L0_p2<=0; frac_x_L0_p2<=0;
        MVy_L0_p2<=0; frac_y_L0_p2<=0;
        MVx_L1_p2<=0; frac_x_L1_p2<=0;
        MVy_L1_p2<=0; frac_y_L1_p2<=0;
    end
end
 
//Part 2 Comb Logic sram_L0
reg WEB_L0, WEB_L1;
reg [7:0] sram_L0_din, sram_L1_din;
reg [13:0] sram_L0_addr, sram_L1_addr;
wire [7:0] sram_L0_dout, sram_L1_dout;
MEM_wrapper sram_L0(.clk(clk),.A(sram_L0_addr),.DI(sram_L0_din),.WEB(WEB_L0),.CS(1'b1),.OE(1'b1),.DO(sram_L0_dout));
MEM_wrapper sram_L1(.clk(clk),.A(sram_L1_addr),.DI(sram_L1_din),.WEB(WEB_L1),.CS(1'b1),.OE(1'b1),.DO(sram_L1_dout));

//Part 3 Seq Logic for EVAL_inter
reg [7:0] L0_15X15_img [0:14][0:14];
reg [7:0] L1_15X15_img [0:14][0:14];

//Part 3 Seq Logic sram
reg write_sram_idx;
reg [6:0] write_sram_row, write_sram_col;   //INPUT_1 L0 L1共用
reg [6:0] read_sram_row, read_sram_col;     //EVAL_sram_read L0 L1共用

integer i,j;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //INPUT_1
        Input_1_cnt<=0;
        write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
        //EVAL_sram_read
        EVAL_sram_read_cnt<=0;
        read_sram_row<=0; read_sram_col<=0;
        //sram sig
        sram_L0_din<=0; sram_L1_din<=0;
        sram_L0_addr<=0; sram_L1_addr<=0;
        WEB_L0<=1; WEB_L1<=1;
    end
    //INPUT_1 接收128X128X2個in_data
    else if(in_valid==1'b1)begin
        //step 0 update cnt
        Input_1_cnt<=Input_1_cnt+1;
        if(write_sram_idx==0 && write_sram_row==127 && write_sram_col==127)begin
            write_sram_idx<=1;    write_sram_row<=0;    write_sram_col<=0;
        end
        else if(write_sram_col==127)begin
            write_sram_row<=write_sram_row+1;   write_sram_col<=0;
        end
        else begin
           write_sram_row<=write_sram_row; write_sram_col<=write_sram_col+1;
        end

        //step 1 sram_write
        if(Input_1_cnt>=0 && Input_1_cnt<={1'd1,7'd127,7'd127})begin
            //case 0 write to sram_L0
            if(write_sram_idx==0)begin
                sram_L0_addr<={write_sram_row, write_sram_col};
                sram_L0_din<=in_data[8:1];
                WEB_L0<=0;  
            end
            //case 1 write_to_sram_L1
            else begin
                sram_L1_addr<={write_sram_row, write_sram_col};
                sram_L1_din<=in_data[8:1];
                WEB_L1<=0;  
            end 
        end
    end
    else if(cur_state==EVAL_sram_read)begin
        //step 0 update cnt
        EVAL_sram_read_cnt<=EVAL_sram_read_cnt+1;
        if(read_sram_col==15)begin
            read_sram_row<=read_sram_row+1; read_sram_col<=0; 
        end
        else begin 
            read_sram_row<=read_sram_row;   read_sram_col<=read_sram_col+1; 
        end
        //step 1 sram addr
        if(EVAL_sram_read_cnt>=0 && EVAL_sram_read_cnt<=(225-1))begin
            //step 0 read sram_L0
            sram_L0_addr[13:7]<=(MVy_L0_p1+read_sram_row);
            sram_L0_addr[6:0] <=(MVx_L0_p1+read_sram_col);
            WEB_L0<=1;  
            //step 1 read sram_L1
            sram_L1_addr[13:7]<=(MVy_L1_p1+read_sram_row);
            sram_L1_addr[6:0] <=(MVx_L1_p1+read_sram_col);
            WEB_L1<=1;  
        end
        //step 2 store to img_reg[]
        if(EVAL_sram_read_cnt>=2 && EVAL_sram_read_cnt<=(225+1))begin
            //step 0 read sram_L0
            for(i=0;i<15;i=i+1)begin
                for(j=0;j<15;j=j+1)begin
                    if(i==14 && j==14) L0_15X15_img[14][14]<=sram_L0_dout;
                    else if(i!=14 && j==14) L0_15X15_img[i][14]<=L0_15X15_img[i+1][0];
                    else L0_15X15_img[i][j]<=L0_15X15_img[i][j+1];
                end
            end
            //step 1 read sram_L1
            for(i=0;i<15;i=i+1)begin
                for(j=0;j<15;j=j+1)begin
                    if(i==14 && j==14) L1_15X15_img[14][14]<=sram_L1_dout;
                    else if(i!=14 && j==14) L1_15X15_img[i][14]<=L1_15X15_img[i+1][0];
                    else L1_15X15_img[i][j]<=L1_15X15_img[i][j+1];
                end
            end
        end
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        //INPUT_1
        Input_1_cnt<=0;
        write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
        //EVAL_sram_read
        EVAL_sram_read_cnt<=0;
        read_sram_row<=0; read_sram_col<=0;
        //sram sig
        sram_L0_din<=0; sram_L1_din<=0;
        sram_L0_addr<=0; sram_L1_addr<=0;
        WEB_L0<=1; WEB_L1<=1;
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