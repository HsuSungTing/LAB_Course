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
parameter EVAL_sram_read=4'd4, EVAL_inter=4'd5, EVAL_prepare_p2=4'd11, EVAL_SATD_p2=4'd6;
parameter EVAL_min_SATD_p2=4'd7, OUTPUT=4'd8, CLEAR_small=4'd9, CLEAR_big=4'd10;

reg [16:0]Input_1_cnt;          //INPUT_1 FSM tag
reg [3:0] Input_2_cnt;          //INPUT_2 FSM tag
reg [1:0] cur_p1_or_p2;    
reg [7:0] EVAL_sram_read_cnt;   //EVAL_sram_read FSM tag 0~226
reg [7:0] EVAL_inter_cnt;       //EVAL_inter FSM tag 0~106
reg [9:0] global_cnt;
reg [3:0] EVAL_SATD_small_cnt, EVAL_SATD_next_idx;
reg EVAL_min_SATD_p1_done, EVAL_min_SATD_p2_done;      //EVAL_min_SATD_p2 FSM tag
reg [3:0] EVAL_min_SATD_p1_cnt,EVAL_min_SATD_p2_cnt;
reg [5:0] output_cnt;           //OUTPUT tag
reg [6:0] ptn_cnt;

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
        EVAL_sram_read:begin    //0-226
            if(EVAL_sram_read_cnt>=226) next_state=EVAL_inter;
            else next_state=EVAL_sram_read;
        end
        EVAL_inter: begin       //227-334
            if(EVAL_inter_cnt>=161&& cur_p1_or_p2==1) next_state=EVAL_prepare_p2;
            else if(EVAL_inter_cnt>=161&& cur_p1_or_p2==2) next_state=EVAL_SATD_p2;
            else next_state=EVAL_inter;
        end
        EVAL_prepare_p2: begin  //1 cycle 清空EVAL_sram_read, EVAL_inter的所有cnt(reg array不用)
            next_state=EVAL_sram_read;
        end
        EVAL_SATD_p2: begin        //335-416
            if(EVAL_SATD_small_cnt==7 && EVAL_SATD_next_idx==15) next_state=EVAL_min_SATD_p2;
            else next_state=EVAL_SATD_p2;
        end
        EVAL_min_SATD_p2: begin    //416-425
            if(EVAL_min_SATD_p2_done==1)next_state=OUTPUT;
            else next_state=EVAL_min_SATD_p2;
        end
        OUTPUT: begin
            if(output_cnt>=55 && ptn_cnt>=64) next_state=CLEAR_big;
            else if(output_cnt>=55 && ptn_cnt<63) next_state=CLEAR_small;
            else next_state=OUTPUT;
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

reg [7:0] cur_MVx_L0, cur_MVy_L0;   //如果是p1就存p1的, p2就存p2的
reg [7:0] cur_MVx_L1, cur_MVy_L1;   //如果是p1就存p1的, p2就存p2的

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //INPUT_2
        Input_2_cnt<=0;
        MVx_L0_p1<=0; frac_x_L0_p1<=0;
        MVy_L0_p1<=0; frac_y_L0_p1<=0;
        MVx_L1_p1<=0; frac_x_L1_p1<=0;
        MVy_L1_p1<=0; frac_y_L1_p1<=0;
        MVx_L0_p2<=0; frac_x_L0_p2<=0;
        MVy_L0_p2<=0; frac_y_L0_p2<=0;
        MVx_L1_p2<=0; frac_x_L1_p2<=0;
        MVy_L1_p2<=0; frac_y_L1_p2<=0;
        //for EVAL_sram_read
        cur_MVx_L0<=0; cur_MVy_L0<=0;
        cur_MVx_L1<=0; cur_MVy_L1<=0;
    end
    else if(in_valid2==1'b1)begin
        Input_2_cnt<=Input_2_cnt+1;
        case(Input_2_cnt)
            0: begin
                MVx_L0_p1<=in_data[8:1]; frac_x_L0_p1<=in_data[0];
                cur_MVx_L0<=in_data[8:1]; 
            end
            1: begin
                MVy_L0_p1<=in_data[8:1]; frac_y_L0_p1<=in_data[0];
                cur_MVy_L0<=in_data[8:1];
            end
            2: begin
                MVx_L1_p1<=in_data[8:1]; frac_x_L1_p1<=in_data[0];
                cur_MVx_L1<=in_data[8:1];
            end
            3: begin
                MVy_L1_p1<=in_data[8:1]; frac_y_L1_p1<=in_data[0];
                cur_MVy_L1<=in_data[8:1];
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
    else if(cur_state==EVAL_prepare_p2)begin
        //for EVAL_sram_read
        cur_MVx_L0<=MVx_L0_p2; cur_MVy_L0<=MVy_L0_p2;
        cur_MVx_L1<=MVx_L1_p2; cur_MVy_L1<=MVy_L1_p2;
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
        //for EVAL_sram_read
        cur_MVx_L0<=0; cur_MVy_L0<=0;
        cur_MVx_L1<=0; cur_MVy_L1<=0;
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

reg [7:0] L0_reg_row, L0_reg_col;           //to check EVAL_sram_read 
reg [7:0] L1_reg_row, L1_reg_col;           //to check EVAL_sram_read 

integer i,j;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //INPUT_1
        Input_1_cnt<=0;
        write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
        //EVAL_sram_read
        EVAL_sram_read_cnt<=0;
        read_sram_row<=0; read_sram_col<=0;
        L0_reg_row<=0; L0_reg_col<=0; L1_reg_row<=0; L1_reg_col<=0;
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
        if(read_sram_col==14)begin
            read_sram_row<=read_sram_row+1; read_sram_col<=0; 
        end
        else begin 
            read_sram_row<=read_sram_row;   read_sram_col<=read_sram_col+1; 
        end
        //step 1 sram addr
        if(EVAL_sram_read_cnt>=0 && EVAL_sram_read_cnt<=(225-1))begin
            //step 0 read sram_L0 (我們的cnt會多2,所以最後要扣2, 因為要其實要從Mvy-2和MVx-2開始到Mvy+13和MVx+13)
            if((cur_MVy_L0+read_sram_row)<8'd2)begin 
                sram_L0_addr[13:7]<=7'd0; L0_reg_row<=0;
            end
            else if((cur_MVy_L0+read_sram_row)>8'd129)begin 
                sram_L0_addr[13:7]<=7'd127; L0_reg_row<=127;
            end
            else begin 
                sram_L0_addr[13:7]<=(cur_MVy_L0+read_sram_row-2); 
                L0_reg_row<=(cur_MVy_L0+read_sram_row-2);
            end

            if((cur_MVx_L0+read_sram_col)<8'd2)begin 
                sram_L0_addr[6:0]<=7'd0;    L0_reg_col<=0;
            end
            else if((cur_MVx_L0+read_sram_col)>8'd129)begin  
                sram_L0_addr[6:0]<=7'd127;  L0_reg_col<=127;
            end
            else begin 
                sram_L0_addr[6:0]<=(cur_MVx_L0+read_sram_col-2);
                L0_reg_col<=(cur_MVx_L0+read_sram_col-2);
            end
            WEB_L0<=1;  

            //step 1 read sram_L1 (我們的cnt會多2,所以最後要扣2, 因為要其實要從Mvy-2和MVx-2開始到Mvy+13和MVx+13)
            if((cur_MVy_L1+read_sram_row)<8'd2)begin 
                sram_L1_addr[13:7]<=7'd0;   L1_reg_row<=0;
            end
            else if((cur_MVy_L1+read_sram_row)>8'd129)begin 
                sram_L1_addr[13:7]<=7'd127; L1_reg_row<=127;
            end
            else begin 
                sram_L1_addr[13:7]<=(cur_MVy_L1+read_sram_row-2);
                L1_reg_row<=(cur_MVy_L1+read_sram_row-2);
            end

            if((cur_MVx_L1+read_sram_col)<8'd2)begin 
                sram_L1_addr[6:0]<=7'd0;   L1_reg_col<=0;
            end
            else if((cur_MVx_L1+read_sram_col)>8'd129)begin 
                sram_L1_addr[6:0]<=7'd127; L1_reg_col<=127;
            end
            else begin 
                sram_L1_addr[6:0]<=(cur_MVx_L1+read_sram_col-2);
                L1_reg_col<=(cur_MVx_L1+read_sram_col-2);
            end
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
    else if(cur_state==EVAL_prepare_p2)begin
        //把EVAL_sram_read和EVAL_inter的歸0
        //EVAL_sram_read
        EVAL_sram_read_cnt<=0;
        read_sram_row<=0; read_sram_col<=0;
        L0_reg_row<=0; L0_reg_col<=0; L1_reg_row<=0; L1_reg_col<=0;
        //sram sig
        sram_L0_din<=0; sram_L1_din<=0;
        sram_L0_addr<=0; sram_L1_addr<=0;
        WEB_L0<=1; WEB_L1<=1;
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        //INPUT_1
        Input_1_cnt<=0;
        write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
        //EVAL_sram_read
        EVAL_sram_read_cnt<=0;
        read_sram_row<=0; read_sram_col<=0;
        L0_reg_row<=0; L0_reg_col<=0; L1_reg_row<=0; L1_reg_col<=0;
        //sram sig
        sram_L0_din<=0; sram_L1_din<=0;
        sram_L0_addr<=0; sram_L1_addr<=0;
        WEB_L0<=1; WEB_L1<=1;
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        global_cnt<=0;
    end
    else if(cur_state==EVAL_inter || cur_state==EVAL_sram_read 
    || cur_state==EVAL_prepare_p2 || cur_state==EVAL_SATD_p2 
    || cur_state==EVAL_min_SATD_p2) begin
        global_cnt<=global_cnt+1;
    end
    else if(cur_state==CLEAR_big || cur_state==CLEAR_small)begin
        global_cnt<=0;
    end
end

//Part 3 Seq Logic EVAL_inter for L0 (include EVAL_inter_cnt)
//內插第一次會須42*255 (15 bit), 內插第二次會須42*2^15 (23 bit)
reg signed [8:0] L0_10X10_img [0:9][0:9];
reg signed [8:0] L1_10X10_img [0:9][0:9];
reg signed [15:0] L0_inter_2D_reg [0:5];     //for 2D水平內插的六個push reg
reg signed [23:0] keep_vertical_inter_L0;
reg signed [15:0] vr_hz_inter_result_L0;
reg [3:0] inter_L0_row, inter_L0_col;  //0-15
reg [3:0] store_L0_10X10_row, store_L0_10X10_col;

//EVAL_SATD 
//reg [3:0] EVAL_SATD_small_cnt, EVAL_SATD_next_idx;
reg [3:0] EVAL_SATD_cur_idx;
reg [15:0] SATD_8X8_img[0:7][0:7];

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //for 4 inter mode
        cur_p1_or_p2<=1; EVAL_inter_cnt<=0;
        inter_L0_row<=0; inter_L0_col<=0; 
        for(i=0;i<10;i=i+1)begin
            for(j=0;j<10;j=j+1)begin
                L0_10X10_img [i][j]<=0;
            end
        end 
        //for HZ & VR inter
        vr_hz_inter_result_L0<=0;
        //for 2D inter
        store_L0_10X10_row<=0; store_L0_10X10_col<=0;
        keep_vertical_inter_L0<=0;
        for(i=0;i<6;i=i+1) L0_inter_2D_reg[i]<=0;
    end
    else if(cur_state==EVAL_inter)begin
        //step 1 EVAL_inter_cnt
        EVAL_inter_cnt<=EVAL_inter_cnt+1;
        //step 2
        //case 0: 2D inter
        if((cur_p1_or_p2==2'd1&&frac_x_L0_p1==1&&frac_y_L0_p1==1)||(cur_p1_or_p2==2'd2&&frac_x_L0_p2==1&&frac_y_L0_p2==1))begin
            //step 1 update cnt (inter_L0_row會從0-15,inter_L0_col會從0-9)
            if(inter_L0_row==15) begin
                inter_L0_row<=0; inter_L0_col<=inter_L0_col+1;
            end
            else begin
                inter_L0_row<=inter_L0_row+1; inter_L0_col<=inter_L0_col;
            end
            //note: 2D inter分三段pipeline

            //step 2 push 6 reg
            if(EVAL_inter_cnt>=0 && EVAL_inter_cnt<=160-1) begin
                //case 0 inter_L0_row==15的時候,[0:5]分別會有9,10,11,12,13,14,故不用更新(但垂直內插還是要算)
                if(inter_L0_row==15)begin
                    for(i=0;i<6;i=i+1) L0_inter_2D_reg[i]<=L0_inter_2D_reg[i];
                end
                //case 1 [0]接收[1] [1]接收[2] [2]接收[3] [3]接收[4] [4]接收[5] [5]做內插
                else begin 
                    for(i=0;i<5;i=i+1) L0_inter_2D_reg[i]<=L0_inter_2D_reg[i+1]; 
                    L0_inter_2D_reg[5]<=(L0_15X15_img[inter_L0_row][inter_L0_col]
                        -5* L0_15X15_img[inter_L0_row][inter_L0_col+1]
                        +20*L0_15X15_img[inter_L0_row][inter_L0_col+2]
                        +20*L0_15X15_img[inter_L0_row][inter_L0_col+3]
                        -5* L0_15X15_img[inter_L0_row][inter_L0_col+4]
                        +   L0_15X15_img[inter_L0_row][inter_L0_col+5]);
                end
            end
            //step 3 find 垂直內插
            if ((EVAL_inter_cnt >= 6   && EVAL_inter_cnt <= 15)  ||
                (EVAL_inter_cnt >= 22  && EVAL_inter_cnt <= 31)  ||
                (EVAL_inter_cnt >= 38  && EVAL_inter_cnt <= 47)  ||
                (EVAL_inter_cnt >= 54  && EVAL_inter_cnt <= 63)  ||
                (EVAL_inter_cnt >= 70  && EVAL_inter_cnt <= 79)  ||
                (EVAL_inter_cnt >= 86  && EVAL_inter_cnt <= 95)  ||
                (EVAL_inter_cnt >= 102 && EVAL_inter_cnt <= 111) ||
                (EVAL_inter_cnt >= 118 && EVAL_inter_cnt <= 127) ||
                (EVAL_inter_cnt >= 134 && EVAL_inter_cnt <= 143) ||
                (EVAL_inter_cnt >= 150 && EVAL_inter_cnt <= 159))begin
                keep_vertical_inter_L0<=L0_inter_2D_reg[0]-5*L0_inter_2D_reg[1]+20*L0_inter_2D_reg[2]
                                    +20*L0_inter_2D_reg[3]-5*L0_inter_2D_reg[4]+L0_inter_2D_reg[5];
            end
            //step 4 find clip and store
            if ((EVAL_inter_cnt >= 7   && EVAL_inter_cnt <= 16)  ||
                (EVAL_inter_cnt >= 23  && EVAL_inter_cnt <= 32)  ||
                (EVAL_inter_cnt >= 39  && EVAL_inter_cnt <= 48)  ||
                (EVAL_inter_cnt >= 55  && EVAL_inter_cnt <= 64)  ||
                (EVAL_inter_cnt >= 71  && EVAL_inter_cnt <= 80)  ||
                (EVAL_inter_cnt >= 87  && EVAL_inter_cnt <= 96)  ||
                (EVAL_inter_cnt >= 103 && EVAL_inter_cnt <= 112) ||
                (EVAL_inter_cnt >= 119 && EVAL_inter_cnt <= 128) ||
                (EVAL_inter_cnt >= 135 && EVAL_inter_cnt <= 144) ||
                (EVAL_inter_cnt >= 151 && EVAL_inter_cnt <= 160))begin
                //step 4-0 update_cnt (由上往下, 做完一個col再往右)
                if(store_L0_10X10_row==9)begin
                    store_L0_10X10_row<=0; store_L0_10X10_col<=store_L0_10X10_col+1;
                end
                else begin
                    store_L0_10X10_row<=store_L0_10X10_row+1; 
                    store_L0_10X10_col<=store_L0_10X10_col;
                end
                //step 4-1 store L0_10X10_img[9][9]
                if(((keep_vertical_inter_L0+512)>>>10)>255) L0_10X10_img[store_L0_10X10_row][store_L0_10X10_col]<=255;
                else if(((keep_vertical_inter_L0+512)>>>10)<-256) L0_10X10_img[store_L0_10X10_row][store_L0_10X10_col]<=(-256);
                else L0_10X10_img[store_L0_10X10_row][store_L0_10X10_col]<=((keep_vertical_inter_L0+512)>>>10);
            end
        end
        //case 1: no inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L0_p1==0&&frac_y_L0_p1==0)||(cur_p1_or_p2==2'd2&&frac_x_L0_p2==0&&frac_y_L0_p2==0))begin
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L0_row會從0-9,inter_L0_col會從0-9)
                if(inter_L0_col==9) begin
                    inter_L0_row<=inter_L0_row+1; inter_L0_col<=inter_L0_col<=0;
                end
                else begin
                    inter_L0_row<=inter_L0_row; inter_L0_col<=inter_L0_col+1;
                end
                //note: no inter不用切

                //step 2 store L0_10X10_img (由左往右，再去下一個row)
                //step 2-1 store L0_10X10_img[9][9]
                if(((keep_vertical_inter_L0+16)>>>5)>255) L0_10X10_img[9][9]<=255;
                else if(((keep_vertical_inter_L0+16)>>>5)<-256) L0_10X10_img[9][9]<=(-256);
                else L0_10X10_img[9][9]<=L0_15X15_img[inter_L0_row+2][inter_L0_col+2];
                //step 2-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L0_10X10_img[i][9]<=L0_10X10_img[i+1][0];
                            else L0_10X10_img[i][j]<=L0_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
        //case 2: HZ inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L0_p1==1&&frac_y_L0_p1==0)||(cur_p1_or_p2==2'd2&&frac_x_L0_p2==1&&frac_y_L0_p2==0))begin
            //note: HZ inter分2段pipeline
            //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L0_row會從0-9,inter_L0_col會從0-9)
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                if(inter_L0_col==9) begin
                    inter_L0_row<=inter_L0_row+1; inter_L0_col<=inter_L0_col<=0;
                end
                else begin
                    inter_L0_row<=inter_L0_row; inter_L0_col<=inter_L0_col+1;
                end
            end

            //step 2 find inter
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                vr_hz_inter_result_L0<=L0_15X15_img [inter_L0_row+2][inter_L0_col]
                                    -5* L0_15X15_img[inter_L0_row+2][inter_L0_col+1]
                                    +20*L0_15X15_img[inter_L0_row+2][inter_L0_col+2]
                                    +20*L0_15X15_img[inter_L0_row+2][inter_L0_col+3]
                                    -5* L0_15X15_img[inter_L0_row+2][inter_L0_col+4]
                                    +   L0_15X15_img[inter_L0_row+2][inter_L0_col+5];
            end

            //step 3 stote
            if(EVAL_inter_cnt>=1&&EVAL_inter_cnt<=100)begin
                //step 3-1 store L0_10X10_img[9][9]
                if(((vr_hz_inter_result_L0+16)>>>5)>255) L0_10X10_img[9][9]<=255;
                else if(((vr_hz_inter_result_L0+16)>>>5)<-256) L0_10X10_img[9][9]<=(-256);
                else L0_10X10_img[9][9]<=((vr_hz_inter_result_L0+16)>>>5);
                //step 3-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L0_10X10_img[i][9]<=L0_10X10_img[i+1][0];
                            else L0_10X10_img[i][j]<=L0_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
        //case 3: VR inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L0_p1==0&&frac_y_L0_p1==1)||(cur_p1_or_p2==2'd2&&frac_x_L0_p2==0&&frac_y_L0_p2==1))begin
            //note: VR inter分2段pipeline
            //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L0_row會從0-9,inter_L0_col會從0-9)
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                if(inter_L0_col==9) begin
                    inter_L0_row<=inter_L0_row+1; inter_L0_col<=inter_L0_col<=0;
                end
                else begin
                    inter_L0_row<=inter_L0_row; inter_L0_col<=inter_L0_col+1;
                end
            end

            //step 2 find inter
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                vr_hz_inter_result_L0<=L0_15X15_img [inter_L0_row]  [inter_L0_col+2]
                                    -5* L0_15X15_img[inter_L0_row+1][inter_L0_col+2]
                                    +20*L0_15X15_img[inter_L0_row+2][inter_L0_col+2]
                                    +20*L0_15X15_img[inter_L0_row+3][inter_L0_col+2]
                                    -5* L0_15X15_img[inter_L0_row+4][inter_L0_col+2]
                                    +   L0_15X15_img[inter_L0_row+5][inter_L0_col+2];
            end

            //step 3 stote
            if(EVAL_inter_cnt>=1&&EVAL_inter_cnt<=100)begin
                //step 3-1 store L0_10X10_img[9][9]
                if(((vr_hz_inter_result_L0+16)>>>5)>255) L0_10X10_img[9][9]<=255;
                else if(((vr_hz_inter_result_L0+16)>>>5)<-256) L0_10X10_img[9][9]<=(-256);
                else L0_10X10_img[9][9]<=((vr_hz_inter_result_L0+16)>>>5);
                //step 3-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L0_10X10_img[i][9]<=L0_10X10_img[i+1][0];
                            else L0_10X10_img[i][j]<=L0_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
    end
    else if(cur_state==EVAL_prepare_p2)begin
        //for 4 inter mode
        cur_p1_or_p2<=2;            //update cur_p1_or_p2
        EVAL_inter_cnt<=0; inter_L0_row<=0; inter_L0_col<=0; 
        //for HZ & VR inter
        vr_hz_inter_result_L0<=0;
        //for 2D inter
        store_L0_10X10_row<=0; store_L0_10X10_col<=0;
        keep_vertical_inter_L0<=0;
        for(i=0;i<6;i=i+1) L0_inter_2D_reg[i]<=0;
    end
    //EVAL_SADT_p2
    else if(cur_state==EVAL_SATD_p2 || (global_cnt>=390 && global_cnt<=(390+90-1)))begin
        //step 0 update cnt
        //step 1 update L0_10X10_img (push)
        if(EVAL_SATD_small_cnt==0)begin
            //上上 左左 下下 右 上
            case(EVAL_SATD_next_idx)
                0,1: begin
                    //往上推一個row, row[0]給row[9]
                    for(i=0;i<10;i=i+1)L0_10X10_img[9][i]<=L0_10X10_img[0][i];
                    for(i=0;i<9;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i+1][j];
                        end
                    end
                end
                2,5: begin
                    //往左推一個col, col[0]給col[9]
                    for(i=0;i<10;i=i+1) L0_10X10_img[i][9]<=L0_10X10_img[i][0];
                    for(i=0;i<10;i=i+1)begin
                        for(j=0;j<9;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i][j+1];
                        end
                    end
                end
                8,7: begin
                    //往下推一個row, row[9]給row[0]
                    for(j=0;j<10;j=j+1) L0_10X10_img[0][j] <= L0_10X10_img[9][j];
                    for(i=1;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i-1][j];
                        end
                    end
                end
                6: begin
                    //往右推一個col, col[9]給col[0]
                    for(i=0;i<10;i=i+1) L0_10X10_img[i][0]<=L0_10X10_img[i][9];
                    for(i=0;i<10;i=i+1)begin
                        for(j=1;j<10;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i][j-1];
                        end
                    end
                end
                3: begin
                    //往上推一個row, row[0]給row[9]
                    for(i=0;i<10;i=i+1)L0_10X10_img[9][i]<=L0_10X10_img[0][i];
                    for(i=0;i<9;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i+1][j];
                        end
                    end
                end  
                default: begin
                    for(i=0;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L0_10X10_img[i][j]<=L0_10X10_img[i][j];
                        end
                    end
                end
            endcase
        end
        //step 2 update SATD_8X8_img
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        //for 4 inter mode
        cur_p1_or_p2<=1; EVAL_inter_cnt<=0;
        inter_L0_row<=0; inter_L0_col<=0; 
        for(i=0;i<10;i=i+1)begin
            for(j=0;j<10;j=j+1)begin
                L0_10X10_img [i][j]<=0;
            end
        end 
        //for HZ & VR inter
        vr_hz_inter_result_L0<=0;
        //for 2D inter
        store_L0_10X10_row<=0; store_L0_10X10_col<=0;
        keep_vertical_inter_L0<=0;
        for(i=0;i<6;i=i+1) L0_inter_2D_reg[i]<=0;
    end
end

//Part 3 Seq Logic EVAL_inter for L1
//內插第一次會須42*255 (15 bit), 內插第二次會須42*2^15 (23 bit)
reg signed [15:0] L1_inter_2D_reg [0:5];     //for 2D水平內插的六個push reg
reg signed [23:0] keep_vertical_inter_L1;
reg signed [15:0] vr_hz_inter_result_L1;
reg [3:0] inter_L1_row, inter_L1_col;  //0-15
reg [3:0] store_L1_10X10_row, store_L1_10X10_col;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //for 4 inter mode
        inter_L1_row<=0; inter_L1_col<=0; 
        for(i=0;i<10;i=i+1)begin
            for(j=0;j<10;j=j+1)begin
                L1_10X10_img [i][j]<=0;
            end
        end 
        //for HZ & VR inter
        vr_hz_inter_result_L1<=0;
        //for 2D inter
        store_L1_10X10_row<=0; store_L1_10X10_col<=0;
        keep_vertical_inter_L1<=0;
        for(i=0;i<6;i=i+1) L1_inter_2D_reg[i]<=0;
    end
    else if(cur_state==EVAL_inter)begin
        //case 0: 2D inter
        if((cur_p1_or_p2==2'd1&&frac_x_L1_p1==1&&frac_y_L1_p1==1)||(cur_p1_or_p2==2'd2&&frac_x_L1_p2==1&&frac_y_L1_p2==1))begin
            //step 1 update cnt (inter_L1_row會從0-15,inter_L1_col會從0-9)
            if(inter_L1_row==15) begin
                inter_L1_row<=0; inter_L1_col<=inter_L1_col+1;
            end
            else begin
                inter_L1_row<=inter_L1_row+1; inter_L1_col<=inter_L1_col;
            end
            //note: 2D inter分三段pipeline

            //step 2 push 6 reg
            if(EVAL_inter_cnt>=0 && EVAL_inter_cnt<=160-1) begin
                //case 0 inter_L1_row==15的時候,[0:5]分別會有9,10,11,12,13,14,故不用更新(但垂直內插還是要算)
                if(inter_L1_row==15)begin
                    for(i=0;i<6;i=i+1) L1_inter_2D_reg[i]<=L1_inter_2D_reg[i];
                end
                //case 1 [0]接收[1] [1]接收[2] [2]接收[3] [3]接收[4] [4]接收[5] [5]做內插
                else begin 
                    for(i=0;i<5;i=i+1) L1_inter_2D_reg[i]<=L1_inter_2D_reg[i+1]; 
                    L1_inter_2D_reg[5]<=(L1_15X15_img[inter_L1_row][inter_L1_col]
                        -5* L1_15X15_img[inter_L1_row][inter_L1_col+1]
                        +20*L1_15X15_img[inter_L1_row][inter_L1_col+2]
                        +20*L1_15X15_img[inter_L1_row][inter_L1_col+3]
                        -5* L1_15X15_img[inter_L1_row][inter_L1_col+4]
                        +   L1_15X15_img[inter_L1_row][inter_L1_col+5]);
                end
            end
            //step 3 find 垂直內插
            if ((EVAL_inter_cnt >= 6   && EVAL_inter_cnt <= 15)  ||
                (EVAL_inter_cnt >= 22  && EVAL_inter_cnt <= 31)  ||
                (EVAL_inter_cnt >= 38  && EVAL_inter_cnt <= 47)  ||
                (EVAL_inter_cnt >= 54  && EVAL_inter_cnt <= 63)  ||
                (EVAL_inter_cnt >= 70  && EVAL_inter_cnt <= 79)  ||
                (EVAL_inter_cnt >= 86  && EVAL_inter_cnt <= 95)  ||
                (EVAL_inter_cnt >= 102 && EVAL_inter_cnt <= 111) ||
                (EVAL_inter_cnt >= 118 && EVAL_inter_cnt <= 127) ||
                (EVAL_inter_cnt >= 134 && EVAL_inter_cnt <= 143) ||
                (EVAL_inter_cnt >= 150 && EVAL_inter_cnt <= 159))begin
                keep_vertical_inter_L1<=L1_inter_2D_reg[0]-5*L1_inter_2D_reg[1]+20*L1_inter_2D_reg[2]
                                    +20*L1_inter_2D_reg[3]-5*L1_inter_2D_reg[4]+L1_inter_2D_reg[5];
            end
            //step 4 find clip and store
            if ((EVAL_inter_cnt >= 7   && EVAL_inter_cnt <= 16)  ||
                (EVAL_inter_cnt >= 23  && EVAL_inter_cnt <= 32)  ||
                (EVAL_inter_cnt >= 39  && EVAL_inter_cnt <= 48)  ||
                (EVAL_inter_cnt >= 55  && EVAL_inter_cnt <= 64)  ||
                (EVAL_inter_cnt >= 71  && EVAL_inter_cnt <= 80)  ||
                (EVAL_inter_cnt >= 87  && EVAL_inter_cnt <= 96)  ||
                (EVAL_inter_cnt >= 103 && EVAL_inter_cnt <= 112) ||
                (EVAL_inter_cnt >= 119 && EVAL_inter_cnt <= 128) ||
                (EVAL_inter_cnt >= 135 && EVAL_inter_cnt <= 144) ||
                (EVAL_inter_cnt >= 151 && EVAL_inter_cnt <= 160))begin
                //step 4-0 update_cnt (由上往下, 做完一個col再往右)
                if(store_L1_10X10_row==9)begin
                    store_L1_10X10_row<=0; store_L1_10X10_col<=store_L1_10X10_col+1;
                end
                else begin
                    store_L1_10X10_row<=store_L1_10X10_row+1; 
                    store_L1_10X10_col<=store_L1_10X10_col;
                end
                //step 4-1 store L1_10X10_img[9][9]
                if(((keep_vertical_inter_L1+512)>>>10)>255) L1_10X10_img[store_L1_10X10_row][store_L1_10X10_col]<=255;
                else if(((keep_vertical_inter_L1+512)>>>10)<-256) L1_10X10_img[store_L1_10X10_row][store_L1_10X10_col]<=(-256);
                else L1_10X10_img[store_L1_10X10_row][store_L1_10X10_col]<=((keep_vertical_inter_L1+512)>>>10);
            end
        end
        //case 1: no inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L1_p1==0&&frac_y_L1_p1==0)||(cur_p1_or_p2==2'd2&&frac_x_L1_p2==0&&frac_y_L1_p2==0))begin
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L1_row會從0-9,inter_L1_col會從0-9)
                if(inter_L1_col==9) begin
                    inter_L1_row<=inter_L1_row+1; inter_L1_col<=inter_L1_col<=0;
                end
                else begin
                    inter_L1_row<=inter_L1_row; inter_L1_col<=inter_L1_col+1;
                end
                //note: no inter不用切

                //step 2 store L1_10X10_img (由左往右，再去下一個row)
                //step 2-1 store L1_10X10_img[9][9]
                if(((keep_vertical_inter_L1+16)>>>5)>255) L1_10X10_img[9][9]<=255;
                else if(((keep_vertical_inter_L1+16)>>>5)<-256) L1_10X10_img[9][9]<=(-256);
                else L1_10X10_img[9][9]<=L1_15X15_img[inter_L1_row+2][inter_L1_col+2];
                //step 2-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L1_10X10_img[i][9]<=L1_10X10_img[i+1][0];
                            else L1_10X10_img[i][j]<=L1_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
        //case 2: HZ inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L1_p1==1&&frac_y_L1_p1==0)||(cur_p1_or_p2==2'd2&&frac_x_L1_p2==1&&frac_y_L1_p2==0))begin
            //note: HZ inter分2段pipeline
            //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L1_row會從0-9,inter_L1_col會從0-9)
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                if(inter_L1_col==9) begin
                    inter_L1_row<=inter_L1_row+1; inter_L1_col<=inter_L1_col<=0;
                end
                else begin
                    inter_L1_row<=inter_L1_row; inter_L1_col<=inter_L1_col+1;
                end
            end
            //step 2 find inter
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                vr_hz_inter_result_L1<=L1_15X15_img [inter_L1_row+2][inter_L1_col]
                                    -5* L1_15X15_img[inter_L1_row+2][inter_L1_col+1]
                                    +20*L1_15X15_img[inter_L1_row+2][inter_L1_col+2]
                                    +20*L1_15X15_img[inter_L1_row+2][inter_L1_col+3]
                                    -5* L1_15X15_img[inter_L1_row+2][inter_L1_col+4]
                                    +   L1_15X15_img[inter_L1_row+2][inter_L1_col+5];
            end
            //step 3 stote
            if(EVAL_inter_cnt>=1&&EVAL_inter_cnt<=100)begin
                //step 3-1 store L1_10X10_img[9][9]
                if(((vr_hz_inter_result_L1+16)>>>5)>255) L1_10X10_img[9][9]<=255;
                else if(((vr_hz_inter_result_L1+16)>>>5)<-256) L1_10X10_img[9][9]<=(-256);
                else L1_10X10_img[9][9]<=((vr_hz_inter_result_L1+16)>>>5);
                //step 3-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L1_10X10_img[i][9]<=L1_10X10_img[i+1][0];
                            else L1_10X10_img[i][j]<=L1_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
        //case 3: VR inter
        else if((cur_p1_or_p2==2'd1&&frac_x_L1_p1==0&&frac_y_L1_p1==1)||(cur_p1_or_p2==2'd2&&frac_x_L1_p2==0&&frac_y_L1_p2==1))begin
            //note: VR inter分2段pipeline
            //step 1 update cnt 0-9即可 (由左往右，再去下一個row, inter_L1_row會從0-9,inter_L1_col會從0-9)
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                if(inter_L1_col==9) begin
                    inter_L1_row<=inter_L1_row+1; inter_L1_col<=inter_L1_col<=0;
                end
                else begin
                    inter_L1_row<=inter_L1_row; inter_L1_col<=inter_L1_col+1;
                end
            end
            //step 2 find inter
            if(EVAL_inter_cnt>=0&&EVAL_inter_cnt<=100-1)begin
                vr_hz_inter_result_L1<=L1_15X15_img [inter_L1_row]  [inter_L1_col+2]
                                    -5* L1_15X15_img[inter_L1_row+1][inter_L1_col+2]
                                    +20*L1_15X15_img[inter_L1_row+2][inter_L1_col+2]
                                    +20*L1_15X15_img[inter_L1_row+3][inter_L1_col+2]
                                    -5* L1_15X15_img[inter_L1_row+4][inter_L1_col+2]
                                    +   L1_15X15_img[inter_L1_row+5][inter_L1_col+2];
            end
            //step 3 stote
            if(EVAL_inter_cnt>=1&&EVAL_inter_cnt<=100)begin
                //step 3-1 store L1_10X10_img[9][9]
                if(((vr_hz_inter_result_L1+16)>>>5)>255) L1_10X10_img[9][9]<=255;
                else if(((vr_hz_inter_result_L1+16)>>>5)<-256) L1_10X10_img[9][9]<=(-256);
                else L1_10X10_img[9][9]<=((vr_hz_inter_result_L1+16)>>>5);
                //step 3-2 push
                for(i=0;i<10;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        if(!(i==9 && j==9)) begin 
                            if(i!=9 && j==9) L1_10X10_img[i][9]<=L1_10X10_img[i+1][0];
                            else L1_10X10_img[i][j]<=L1_10X10_img[i][j+1];
                        end
                    end
                end
            end
        end
    end
    else if(cur_state==EVAL_prepare_p2)begin
        //for 4 inter mode
        inter_L1_row<=0; inter_L1_col<=0; 
        //for HZ & VR inter
        vr_hz_inter_result_L1<=0;
        //for 2D inter
        store_L1_10X10_row<=0; store_L1_10X10_col<=0;
        keep_vertical_inter_L1<=0;
        for(i=0;i<6;i=i+1) L1_inter_2D_reg[i]<=0;
    end
    else if(cur_state==EVAL_SATD_p2 || (global_cnt>=389 && global_cnt<=(389+90-1)))begin
        //step 1 update L1_10X10_img (push)
        if(EVAL_SATD_small_cnt==0)begin
        //下下 右右 上上 左 下
            case(EVAL_SATD_next_idx)
                0,1: begin
                    //往下推一個row, row[9]給row[0]
                    for(j=0;j<10;j=j+1) L1_10X10_img[0][j] <= L1_10X10_img[9][j];
                    for(i=1;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i-1][j];
                        end
                    end
                end
                2,5: begin
                    //往右推一個col, col[9]給col[0]
                    for(i=0;i<10;i=i+1) L1_10X10_img[i][0]<=L1_10X10_img[i][9];
                    for(i=0;i<10;i=i+1)begin
                        for(j=1;j<10;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i][j-1];
                        end
                    end
                end
                8,7: begin
                    //往上推一個row, row[0]給row[9]
                    for(i=0;i<10;i=i+1)L1_10X10_img[9][i]<=L1_10X10_img[0][i];
                    for(i=0;i<9;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i+1][j];
                        end
                    end
                end
                6: begin
                    //往左推一個col, col[0]給col[9]
                    for(i=0;i<10;i=i+1) L1_10X10_img[i][9]<=L1_10X10_img[i][0];
                    for(i=0;i<10;i=i+1)begin
                        for(j=0;j<9;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i][j+1];
                        end
                    end
                end
                3: begin
                    //往下推一個row, row[9]給row[0]
                    for(j=0;j<10;j=j+1) L1_10X10_img[0][j] <= L1_10X10_img[9][j];
                    for(i=1;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i-1][j];
                        end
                    end
                end
                default: begin
                    for(i=0;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            L1_10X10_img[i][j]<=L1_10X10_img[i][j];
                        end
                    end
                end
            endcase
        end
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        //for 4 inter mode
        inter_L1_row<=0; inter_L1_col<=0; 
        for(i=0;i<10;i=i+1)begin
            for(j=0;j<10;j=j+1)begin
                L1_10X10_img [i][j]<=0;
            end
        end 
        //for HZ & VR inter
        vr_hz_inter_result_L1<=0;
        //for 2D inter
        store_L1_10X10_row<=0; store_L1_10X10_col<=0;
        keep_vertical_inter_L1<=0;
        for(i=0;i<6;i=i+1) L1_inter_2D_reg[i]<=0;
    end
end

//EVAL_SATD
//Part 2 Comb Logic
reg signed [15:0] H_mul_result [0:7][0:7];
H_mul H_mul_inst1(
    .a00(SATD_8X8_img[0][0]),.a01(SATD_8X8_img[0][1]),.a02(SATD_8X8_img[0][2]),.a03(SATD_8X8_img[0][3]),
    .a10(SATD_8X8_img[1][0]),.a11(SATD_8X8_img[1][1]),.a12(SATD_8X8_img[1][2]),.a13(SATD_8X8_img[1][3]),
    .a20(SATD_8X8_img[2][0]),.a21(SATD_8X8_img[2][1]),.a22(SATD_8X8_img[2][2]),.a23(SATD_8X8_img[2][3]),
    .a30(SATD_8X8_img[3][0]),.a31(SATD_8X8_img[3][1]),.a32(SATD_8X8_img[3][2]),.a33(SATD_8X8_img[3][3]),
    .b00(H_mul_result[0][0]),.b01(H_mul_result[0][1]),.b02(H_mul_result[0][2]),.b03(H_mul_result[0][3]),
    .b10(H_mul_result[1][0]),.b11(H_mul_result[1][1]),.b12(H_mul_result[1][2]),.b13(H_mul_result[1][3]),
    .b20(H_mul_result[2][0]),.b21(H_mul_result[2][1]),.b22(H_mul_result[2][2]),.b23(H_mul_result[2][3]),
    .b30(H_mul_result[3][0]),.b31(H_mul_result[3][1]),.b32(H_mul_result[3][2]),.b33(H_mul_result[3][3])
);
H_mul H_mul_inst2(
    .a00(SATD_8X8_img[0][4]),.a01(SATD_8X8_img[0][5]),.a02(SATD_8X8_img[0][6]),.a03(SATD_8X8_img[0][7]),
    .a10(SATD_8X8_img[1][4]),.a11(SATD_8X8_img[1][5]),.a12(SATD_8X8_img[1][6]),.a13(SATD_8X8_img[1][7]),
    .a20(SATD_8X8_img[2][4]),.a21(SATD_8X8_img[2][5]),.a22(SATD_8X8_img[2][6]),.a23(SATD_8X8_img[2][7]),
    .a30(SATD_8X8_img[3][4]),.a31(SATD_8X8_img[3][5]),.a32(SATD_8X8_img[3][6]),.a33(SATD_8X8_img[3][7]),
    .b00(H_mul_result[0][4]),.b01(H_mul_result[0][5]),.b02(H_mul_result[0][6]),.b03(H_mul_result[0][7]),
    .b10(H_mul_result[1][4]),.b11(H_mul_result[1][5]),.b12(H_mul_result[1][6]),.b13(H_mul_result[1][7]),
    .b20(H_mul_result[2][4]),.b21(H_mul_result[2][5]),.b22(H_mul_result[2][6]),.b23(H_mul_result[2][7]),
    .b30(H_mul_result[3][4]),.b31(H_mul_result[3][5]),.b32(H_mul_result[3][6]),.b33(H_mul_result[3][7])
);
H_mul H_mul_inst3(
    .a00(SATD_8X8_img[4][0]), .a01(SATD_8X8_img[4][1]), .a02(SATD_8X8_img[4][2]), .a03(SATD_8X8_img[4][3]),
    .a10(SATD_8X8_img[5][0]), .a11(SATD_8X8_img[5][1]), .a12(SATD_8X8_img[5][2]), .a13(SATD_8X8_img[5][3]),
    .a20(SATD_8X8_img[6][0]), .a21(SATD_8X8_img[6][1]), .a22(SATD_8X8_img[6][2]), .a23(SATD_8X8_img[6][3]),
    .a30(SATD_8X8_img[7][0]), .a31(SATD_8X8_img[7][1]), .a32(SATD_8X8_img[7][2]), .a33(SATD_8X8_img[7][3]),
    .b00(H_mul_result[4][0]), .b01(H_mul_result[4][1]), .b02(H_mul_result[4][2]), .b03(H_mul_result[4][3]),
    .b10(H_mul_result[5][0]), .b11(H_mul_result[5][1]), .b12(H_mul_result[5][2]), .b13(H_mul_result[5][3]),
    .b20(H_mul_result[6][0]), .b21(H_mul_result[6][1]), .b22(H_mul_result[6][2]), .b23(H_mul_result[6][3]),
    .b30(H_mul_result[7][0]), .b31(H_mul_result[7][1]), .b32(H_mul_result[7][2]), .b33(H_mul_result[7][3])
);
H_mul H_mul_inst4(
    .a00(SATD_8X8_img[4][4]), .a01(SATD_8X8_img[4][5]), .a02(SATD_8X8_img[4][6]), .a03(SATD_8X8_img[4][7]),
    .a10(SATD_8X8_img[5][4]), .a11(SATD_8X8_img[5][5]), .a12(SATD_8X8_img[5][6]), .a13(SATD_8X8_img[5][7]),
    .a20(SATD_8X8_img[6][4]), .a21(SATD_8X8_img[6][5]), .a22(SATD_8X8_img[6][6]), .a23(SATD_8X8_img[6][7]),
    .a30(SATD_8X8_img[7][4]), .a31(SATD_8X8_img[7][5]), .a32(SATD_8X8_img[7][6]), .a33(SATD_8X8_img[7][7]),
    .b00(H_mul_result[4][4]), .b01(H_mul_result[4][5]), .b02(H_mul_result[4][6]), .b03(H_mul_result[4][7]),
    .b10(H_mul_result[5][4]), .b11(H_mul_result[5][5]), .b12(H_mul_result[5][6]), .b13(H_mul_result[5][7]),
    .b20(H_mul_result[6][4]), .b21(H_mul_result[6][5]), .b22(H_mul_result[6][6]), .b23(H_mul_result[6][7]),
    .b30(H_mul_result[7][4]), .b31(H_mul_result[7][5]), .b32(H_mul_result[7][6]), .b33(H_mul_result[7][7])
);

reg signed [15:0] mul_H_result [0:7][0:7];
mul_H mul_H_inst1(
    .a00(SATD_8X8_img[0][0]),.a01(SATD_8X8_img[0][1]),.a02(SATD_8X8_img[0][2]),.a03(SATD_8X8_img[0][3]),
    .a10(SATD_8X8_img[1][0]),.a11(SATD_8X8_img[1][1]),.a12(SATD_8X8_img[1][2]),.a13(SATD_8X8_img[1][3]),
    .a20(SATD_8X8_img[2][0]),.a21(SATD_8X8_img[2][1]),.a22(SATD_8X8_img[2][2]),.a23(SATD_8X8_img[2][3]),
    .a30(SATD_8X8_img[3][0]),.a31(SATD_8X8_img[3][1]),.a32(SATD_8X8_img[3][2]),.a33(SATD_8X8_img[3][3]),
    .b00(mul_H_result[0][0]),.b01(mul_H_result[0][1]),.b02(mul_H_result[0][2]),.b03(mul_H_result[0][3]),
    .b10(mul_H_result[1][0]),.b11(mul_H_result[1][1]),.b12(mul_H_result[1][2]),.b13(mul_H_result[1][3]),
    .b20(mul_H_result[2][0]),.b21(mul_H_result[2][1]),.b22(mul_H_result[2][2]),.b23(mul_H_result[2][3]),
    .b30(mul_H_result[3][0]),.b31(mul_H_result[3][1]),.b32(mul_H_result[3][2]),.b33(mul_H_result[3][3])
);
mul_H mul_H_inst2(
    .a00(SATD_8X8_img[0][4]),.a01(SATD_8X8_img[0][5]),.a02(SATD_8X8_img[0][6]),.a03(SATD_8X8_img[0][7]),
    .a10(SATD_8X8_img[1][4]),.a11(SATD_8X8_img[1][5]),.a12(SATD_8X8_img[1][6]),.a13(SATD_8X8_img[1][7]),
    .a20(SATD_8X8_img[2][4]),.a21(SATD_8X8_img[2][5]),.a22(SATD_8X8_img[2][6]),.a23(SATD_8X8_img[2][7]),
    .a30(SATD_8X8_img[3][4]),.a31(SATD_8X8_img[3][5]),.a32(SATD_8X8_img[3][6]),.a33(SATD_8X8_img[3][7]),
    .b00(mul_H_result[0][4]),.b01(mul_H_result[0][5]),.b02(mul_H_result[0][6]),.b03(mul_H_result[0][7]),
    .b10(mul_H_result[1][4]),.b11(mul_H_result[1][5]),.b12(mul_H_result[1][6]),.b13(mul_H_result[1][7]),
    .b20(mul_H_result[2][4]),.b21(mul_H_result[2][5]),.b22(mul_H_result[2][6]),.b23(mul_H_result[2][7]),
    .b30(mul_H_result[3][4]),.b31(mul_H_result[3][5]),.b32(mul_H_result[3][6]),.b33(mul_H_result[3][7])
);
mul_H mul_H_inst3(
    .a00(SATD_8X8_img[4][0]), .a01(SATD_8X8_img[4][1]), .a02(SATD_8X8_img[4][2]), .a03(SATD_8X8_img[4][3]),
    .a10(SATD_8X8_img[5][0]), .a11(SATD_8X8_img[5][1]), .a12(SATD_8X8_img[5][2]), .a13(SATD_8X8_img[5][3]),
    .a20(SATD_8X8_img[6][0]), .a21(SATD_8X8_img[6][1]), .a22(SATD_8X8_img[6][2]), .a23(SATD_8X8_img[6][3]),
    .a30(SATD_8X8_img[7][0]), .a31(SATD_8X8_img[7][1]), .a32(SATD_8X8_img[7][2]), .a33(SATD_8X8_img[7][3]),
    .b00(mul_H_result[4][0]), .b01(mul_H_result[4][1]), .b02(mul_H_result[4][2]), .b03(mul_H_result[4][3]),
    .b10(mul_H_result[5][0]), .b11(mul_H_result[5][1]), .b12(mul_H_result[5][2]), .b13(mul_H_result[5][3]),
    .b20(mul_H_result[6][0]), .b21(mul_H_result[6][1]), .b22(mul_H_result[6][2]), .b23(mul_H_result[6][3]),
    .b30(mul_H_result[7][0]), .b31(mul_H_result[7][1]), .b32(mul_H_result[7][2]), .b33(mul_H_result[7][3])
);
mul_H mul_H_inst4(
    .a00(SATD_8X8_img[4][4]), .a01(SATD_8X8_img[4][5]), .a02(SATD_8X8_img[4][6]), .a03(SATD_8X8_img[4][7]),
    .a10(SATD_8X8_img[5][4]), .a11(SATD_8X8_img[5][5]), .a12(SATD_8X8_img[5][6]), .a13(SATD_8X8_img[5][7]),
    .a20(SATD_8X8_img[6][4]), .a21(SATD_8X8_img[6][5]), .a22(SATD_8X8_img[6][6]), .a23(SATD_8X8_img[6][7]),
    .a30(SATD_8X8_img[7][4]), .a31(SATD_8X8_img[7][5]), .a32(SATD_8X8_img[7][6]), .a33(SATD_8X8_img[7][7]),
    .b00(mul_H_result[4][4]), .b01(mul_H_result[4][5]), .b02(mul_H_result[4][6]), .b03(mul_H_result[4][7]),
    .b10(mul_H_result[5][4]), .b11(mul_H_result[5][5]), .b12(mul_H_result[5][6]), .b13(mul_H_result[5][7]),
    .b20(mul_H_result[6][4]), .b21(mul_H_result[6][5]), .b22(mul_H_result[6][6]), .b23(mul_H_result[6][7]),
    .b30(mul_H_result[7][4]), .b31(mul_H_result[7][5]), .b32(mul_H_result[7][6]), .b33(mul_H_result[7][7])
);

//Part 3 Seq Logic EVAL_SATD
reg [23:0] SATD_result [0:8];
reg [20:0] sub_blk_1_sum, sub_blk_2_sum, sub_blk_3_sum, sub_blk_4_sum;//16bit*16

reg [23:0] P1_min_SATD, P2_min_SATD; 
reg [3:0] P1_min_SATD_idx, P2_min_SATD_idx;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //EVAL_SATD
        EVAL_SATD_small_cnt<=0; 
        EVAL_SATD_next_idx<=0; EVAL_SATD_cur_idx<=0;    //存入SATD結果
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                SATD_8X8_img[i][j]<=0;
            end
        end
        for(i=0;i<9;i=i+1) SATD_result[i]<=0;
        sub_blk_1_sum<=0; sub_blk_2_sum<=0; 
        sub_blk_3_sum<=0; sub_blk_4_sum<=0;
        //EVAL_min_SATD
        P1_min_SATD<=0; P1_min_SATD_idx<=0;
        P2_min_SATD<=0; P2_min_SATD_idx<=0;
        EVAL_min_SATD_p1_done<=0;EVAL_min_SATD_p2_done<=0; 
        EVAL_min_SATD_p1_cnt<=0; EVAL_min_SATD_p2_cnt<=0;
    end
    //EVAL_SADT_p2
    else if(cur_state==EVAL_SATD_p2 || (global_cnt>=390 && global_cnt<=(462-1)))begin
        //step 0 update cnt
        if(EVAL_SATD_small_cnt==7)EVAL_SATD_small_cnt<=0;
        else EVAL_SATD_small_cnt<=EVAL_SATD_small_cnt+1;
        //step 1 update L0_10X10_img (push)
        if(EVAL_SATD_small_cnt==0)begin
            EVAL_SATD_cur_idx<=EVAL_SATD_next_idx;
            case(EVAL_SATD_next_idx)
                0: EVAL_SATD_next_idx<=1;
                1: EVAL_SATD_next_idx<=2;
                2: EVAL_SATD_next_idx<=5;
                5: EVAL_SATD_next_idx<=8;
                8: EVAL_SATD_next_idx<=7;
                7: EVAL_SATD_next_idx<=6;
                6: EVAL_SATD_next_idx<=3;
                3: EVAL_SATD_next_idx<=4;
                4: EVAL_SATD_next_idx<=15;       //done
                default: EVAL_SATD_next_idx<=15; //done
            endcase
        end
        //step 2 update SATD_8X8_img
        //step 2-1 minus
        if(EVAL_SATD_small_cnt==0)begin
            for(i=0;i<8;i=i+1)begin
                for(j=0;j<8;j=j+1)begin
                    SATD_8X8_img[i][j]<=L0_10X10_img[i][j]-L1_10X10_img[i+2][j+2];
                end
            end
        end
        //step 2-2 H_mul
        else if(EVAL_SATD_small_cnt==1)begin
            for(i=0;i<8;i=i+1)begin
                for(j=0;j<8;j=j+1)begin
                    SATD_8X8_img[i][j]<=H_mul_result[i][j];
                end
            end
        end
        //step 2-3 mul_H
        else if(EVAL_SATD_small_cnt==2)begin
            for(i=0;i<8;i=i+1)begin
                for(j=0;j<8;j=j+1)begin
                    SATD_8X8_img[i][j]<=mul_H_result[i][j];
                end
            end
        end
        //step 2-4 4X4內橫的累加 4 cycles
        else if(EVAL_SATD_small_cnt>=3&&EVAL_SATD_small_cnt<=6)begin
            //sub_blk 1
            sub_blk_1_sum<=sub_blk_1_sum+SATD_8X8_img[EVAL_SATD_small_cnt-3][0]+SATD_8X8_img[EVAL_SATD_small_cnt-3][1]
                            +SATD_8X8_img[EVAL_SATD_small_cnt-3][2]+SATD_8X8_img[EVAL_SATD_small_cnt-3][3];
            //sub_blk 2
            sub_blk_2_sum<=sub_blk_2_sum+SATD_8X8_img[EVAL_SATD_small_cnt-3][4]+SATD_8X8_img[EVAL_SATD_small_cnt-3][5]
                            +SATD_8X8_img[EVAL_SATD_small_cnt-3][6]+SATD_8X8_img[EVAL_SATD_small_cnt-3][7];
            //sub_blk 3
            sub_blk_3_sum<=sub_blk_3_sum+SATD_8X8_img[EVAL_SATD_small_cnt+1][0]+SATD_8X8_img[EVAL_SATD_small_cnt+1][1]
                            +SATD_8X8_img[EVAL_SATD_small_cnt+1][2]+SATD_8X8_img[EVAL_SATD_small_cnt+1][3];
            //sub_blk 4
            sub_blk_4_sum<=sub_blk_4_sum+SATD_8X8_img[EVAL_SATD_small_cnt+1][4]+SATD_8X8_img[EVAL_SATD_small_cnt+1][5]
                            +SATD_8X8_img[EVAL_SATD_small_cnt+1][6]+SATD_8X8_img[EVAL_SATD_small_cnt+1][7];
        end
        else if(EVAL_SATD_small_cnt==7)begin
            //step 0
            SATD_result[EVAL_SATD_cur_idx]<=sub_blk_1_sum+sub_blk_2_sum+sub_blk_3_sum+sub_blk_4_sum;
            //step 1: 為了後續計算而歸0
            sub_blk_1_sum<=0; sub_blk_2_sum<=0; sub_blk_3_sum<=0; sub_blk_4_sum<=0;
        end
    end
    else if((cur_state==EVAL_min_SATD_p2) || (global_cnt>=462 && global_cnt<=(462+9)))begin
        //step 0 還沒找到min, update_cnt
        if(cur_state==EVAL_min_SATD_p2 && EVAL_min_SATD_p2_done==0)begin
            EVAL_min_SATD_p2_cnt<=EVAL_min_SATD_p2_cnt+1;
        end
        else if(global_cnt>=462 && global_cnt<=(462+9) && EVAL_min_SATD_p1_done==0)begin
            EVAL_min_SATD_p1_cnt<=EVAL_min_SATD_p1_cnt+1;
        end
        
        //step 1 check min_SATD
        if(SATD_result[0]<=SATD_result[1]&&SATD_result[0]<=SATD_result[2]&&
           SATD_result[0]<=SATD_result[3]&&SATD_result[0]<=SATD_result[4]&&
           SATD_result[0]<=SATD_result[5]&&SATD_result[0]<=SATD_result[6]&&
           SATD_result[0]<=SATD_result[7])begin
            //case 0: find p2_now
            if(cur_state==EVAL_min_SATD_p2 && EVAL_min_SATD_p2_done==0)begin
                P2_min_SATD<=SATD_result[0];
                P2_min_SATD_idx<=EVAL_min_SATD_p2_cnt;
                EVAL_min_SATD_p2_done<=1;   //為了在同樣小的情況下選idx最小的,不能覆蓋
            end
            //case 1: find p1_now
            else if(global_cnt>=462 && global_cnt<=(462+9) && EVAL_min_SATD_p1_done==0)begin
                P1_min_SATD<=SATD_result[0];
                P1_min_SATD_idx<=EVAL_min_SATD_p1_cnt;
                EVAL_min_SATD_p1_done<=1;
            end
        end
        //step 2 push reg to find next SATD
        for(i=1;i<9;i=i+1) SATD_result[i-1]<=SATD_result[i];
        SATD_result[8]<=SATD_result[0];

        //step 3: 為了p2後續計算而歸0 (目前比完了才能歸0)
        if(global_cnt>=462 && global_cnt<=(462+9) && EVAL_min_SATD_p1_done==1)begin
            //EVAL_SATD
            EVAL_SATD_small_cnt<=0; 
            EVAL_SATD_next_idx<=0; EVAL_SATD_cur_idx<=0;    //存入SATD結果
            for(i=0;i<8;i=i+1)begin
                for(j=0;j<8;j=j+1)begin
                    SATD_8X8_img[i][j]<=0;
                end
            end
            for(i=0;i<9;i=i+1) SATD_result[i]<=0;
            sub_blk_1_sum<=0; sub_blk_2_sum<=0; 
            sub_blk_3_sum<=0; sub_blk_4_sum<=0;
        end
    end
    else if(cur_state==CLEAR_small || cur_state==CLEAR_big)begin
        //EVAL_SATD
        EVAL_SATD_small_cnt<=0; 
        EVAL_SATD_next_idx<=0; EVAL_SATD_cur_idx<=0;    //存入SATD結果
        for(i=0;i<8;i=i+1)begin
            for(j=0;j<8;j=j+1)begin
                SATD_8X8_img[i][j]<=0;
            end
        end
        for(i=0;i<9;i=i+1) SATD_result[i]<=0;
        sub_blk_1_sum<=0; sub_blk_2_sum<=0; 
        sub_blk_3_sum<=0; sub_blk_4_sum<=0;
        //EVAL_min_SATD
        P1_min_SATD<=0; P1_min_SATD_idx<=0;
        P2_min_SATD<=0; P2_min_SATD_idx<=0;
        EVAL_min_SATD_p1_done<=0;EVAL_min_SATD_p2_done<=0; 
        EVAL_min_SATD_p1_cnt<=0; EVAL_min_SATD_p2_cnt<=0;
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

module H_mul (
    input  signed [15:0] a00, a01, a02, a03,
    input  signed [15:0] a10, a11, a12, a13,
    input  signed [15:0] a20, a21, a22, a23,
    input  signed [15:0] a30, a31, a32, a33,
    output signed [15:0] b00, b01, b02, b03,
    output signed [15:0] b10, b11, b12, b13,
    output signed [15:0] b20, b21, b22, b23,
    output signed [15:0] b30, b31, b32, b33
);
assign b00 = a00 + a10 + a20 + a30; // + + + +
assign b10 = a00 - a10 + a20 - a30; // + - + -
assign b20 = a00 + a10 - a20 - a30; // + + - -
assign b30 = a00 - a10 - a20 + a30; // + - - +

assign b01 = a01 + a11 + a21 + a31;
assign b11 = a01 - a11 + a21 - a31;
assign b21 = a01 + a11 - a21 - a31;
assign b31 = a01 - a11 - a21 + a31;

assign b02 = a02 + a12 + a22 + a32;
assign b12 = a02 - a12 + a22 - a32;
assign b22 = a02 + a12 - a22 - a32;
assign b32 = a02 - a12 - a22 + a32;

assign b03 = a03 + a13 + a23 + a33;
assign b13 = a03 - a13 + a23 - a33;
assign b23 = a03 + a13 - a23 - a33;
assign b33 = a03 - a13 - a23 + a33;
endmodule

module mul_H (
    input  signed [15:0] a00, a01, a02, a03,
    input  signed [15:0] a10, a11, a12, a13,
    input  signed [15:0] a20, a21, a22, a23,
    input  signed [15:0] a30, a31, a32, a33,
    output signed [15:0] b00, b01, b02, b03,
    output signed [15:0] b10, b11, b12, b13,
    output signed [15:0] b20, b21, b22, b23,
    output signed [15:0] b30, b31, b32, b33
);
    // 原始计算结果 (16-bit signed)
    wire signed [15:0] r00 = a00 + a01 + a02 + a03;
    wire signed [15:0] r01 = a00 - a01 + a02 - a03;
    wire signed [15:0] r02 = a00 + a01 - a02 - a03;
    wire signed [15:0] r03 = a00 - a01 - a02 + a03;

    wire signed [15:0] r10 = a10 + a11 + a12 + a13;
    wire signed [15:0] r11 = a10 - a11 + a12 - a13;
    wire signed [15:0] r12 = a10 + a11 - a12 - a13;
    wire signed [15:0] r13 = a10 - a11 - a12 + a13;

    wire signed [15:0] r20 = a20 + a21 + a22 + a23;
    wire signed [15:0] r21 = a20 - a21 + a22 - a23;
    wire signed [15:0] r22 = a20 + a21 - a22 - a23;
    wire signed [15:0] r23 = a20 - a21 - a22 + a23;

    wire signed [15:0] r30 = a30 + a31 + a32 + a33;
    wire signed [15:0] r31 = a30 - a31 + a32 - a33;
    wire signed [15:0] r32 = a30 + a31 - a32 - a33;
    wire signed [15:0] r33 = a30 - a31 - a32 + a33;

    // 绝对值输出（使用直接负号 -rXX）
    assign b00 = (r00 < 0) ? -r00 : r00;
    assign b01 = (r01 < 0) ? -r01 : r01;
    assign b02 = (r02 < 0) ? -r02 : r02;
    assign b03 = (r03 < 0) ? -r03 : r03;

    assign b10 = (r10 < 0) ? -r10 : r10;
    assign b11 = (r11 < 0) ? -r11 : r11;
    assign b12 = (r12 < 0) ? -r12 : r12;
    assign b13 = (r13 < 0) ? -r13 : r13;

    assign b20 = (r20 < 0) ? -r20 : r20;
    assign b21 = (r21 < 0) ? -r21 : r21;
    assign b22 = (r22 < 0) ? -r22 : r22;
    assign b23 = (r23 < 0) ? -r23 : r23;

    assign b30 = (r30 < 0) ? -r30 : r30;
    assign b31 = (r31 < 0) ? -r31 : r31;
    assign b32 = (r32 < 0) ? -r32 : r32;
    assign b33 = (r33 < 0) ? -r33 : r33;
endmodule