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
reg [4:0] cur_state, next_state;
parameter IDLE=5'd0, INPUT_1=5'd1, WAIT=5'd2, INPUT_2=5'd3, READ_sram_and_diverse=5'd4;
parameter EVAL_intra_4X4=5'd5,EVAL_4X4=5'd6,EVAL_intra_16X16=5'd7,EVAL_16X16=5'd8; 
parameter OUT_4X4=5'd9, OUT_16X16=5'd10, EVAL_rec_4X4=5'd11,EVAL_rec_16X16=5'd12; 
parameter EVAL_4X4_next=5'd13;      
parameter EVAL_16X16_next=5'd14;    

parameter CLEAR_small=5'd15, CLEAR_big=5'd16;

//FSM Tag
reg [2:0] in_valid_param_cnt;
reg [4:0] cur_set_cnt;      //how many 32X32 in
reg [2:0] big_block_cnt;    //how many block done(for EVAL4X4_next, EVAL_16X16_next)
reg READ_sram_done;
reg EVAL_intra_4X4_done, EVAL_intra_16X16_done;
reg EVAL_4X4_done, EVAL_16X16_done;
reg [4:0] out_cnt;
reg EVAL_rec_4X4_done, EVAL_rec_16X16_done;
reg EVAL_all_done;

//input buf for input_data
reg [7:0] data_q;

//input buf for in_valid_param
reg mode_q_arr[0:3];
reg [4:0] QP_q;
reg [3:0] set_idx_q;

//for sram in
reg [3:0] in_sram_idx; 
reg [4:0] in_sram_row, in_sram_col;

reg [13:0] sram_addr;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

//most important signal!!!!
reg signed [31:0] cur_4X4 [0:3][0:3];
reg [4:0] lf_up_row, lf_up_col; 
reg [4:0] small_lf_up_row, small_lf_up_col; 

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid_data==1'b1)next_state=INPUT_1;
            else next_state=IDLE;
        end
        INPUT_1: begin  
            if(sram_addr=={4'd15, 5'd31, 5'd31})next_state=WAIT;
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
            if(EVAL_4X4_done==1) next_state=OUT_4X4;
            else next_state=EVAL_4X4;
        end
        OUT_4X4: begin
            if(out_cnt==16&&EVAL_all_done==1'b1&&cur_set_cnt<16)next_state=CLEAR_small;
            else if(out_cnt==16&&EVAL_all_done==1'b1&&cur_set_cnt==16)next_state=CLEAR_big;
            else if(out_cnt==16) next_state=EVAL_rec_4X4;   
            else next_state=OUT_4X4;
        end
        EVAL_rec_4X4: begin
            if(EVAL_rec_4X4_done==1'b1) next_state=EVAL_4X4_next;
            else next_state=EVAL_rec_4X4;
        end
        EVAL_4X4_next: begin
            if((small_lf_up_row==12&&small_lf_up_col==12)||(small_lf_up_row==12&&small_lf_up_col==28)
            ||(small_lf_up_row==28&&small_lf_up_col==12)) begin
                if(mode_q_arr[big_block_cnt+1]==1'b1)next_state=EVAL_intra_4X4;
                else next_state=EVAL_intra_16X16;
            end
            else next_state=EVAL_intra_4X4;     
        end

        EVAL_intra_16X16: begin
            if(EVAL_intra_16X16_done==1'b1) next_state=EVAL_16X16;
            else next_state=EVAL_intra_16X16;
        end
        EVAL_16X16: begin
            if(EVAL_16X16_done==1) next_state=OUT_16X16;
            else next_state=EVAL_16X16;
        end
        OUT_16X16: begin
            if(out_cnt==16&&EVAL_all_done==1'b1&&cur_set_cnt<16)next_state=CLEAR_small;
            else if(out_cnt==16 && EVAL_all_done==1'b1&&cur_set_cnt==16)next_state=CLEAR_big;
            else if(out_cnt==16) next_state=EVAL_rec_16X16;   //not done 32X32
            else next_state=OUT_16X16;
        end
        EVAL_rec_16X16: begin
            if(EVAL_rec_16X16_done==1'b1) next_state=EVAL_16X16_next;
            else next_state=EVAL_rec_16X16;
        end
        EVAL_16X16_next: begin
            if((small_lf_up_row==12&&small_lf_up_col==12)||(small_lf_up_row==12&&small_lf_up_col==28)
            ||(small_lf_up_row==28&&small_lf_up_col==12)) begin
                if(mode_q_arr[big_block_cnt+1]==1'b1)next_state=EVAL_intra_4X4;
                else next_state=EVAL_intra_16X16;
            end
            else next_state=EVAL_16X16;     
        end
        
        CLEAR_small: next_state=WAIT;       
        CLEAR_big: next_state=IDLE;         
        default: next_state=IDLE;
    endcase
end

//Part 3 Seq Logic (all sram signal should be reset)
reg sram_WEB;
reg [7:0] sram_din;
//reg [13:0] sram_addr;
wire [7:0] sram_dout;

// //Part 2 Comb Logic
reg [4:0] read_sram_row, read_sram_col; 
// always @(*)begin
//     if(cur_state==INPUT_1)begin //sram write
//         sram_WEB=1'b0;
//         sram_addr={in_sram_idx, in_sram_row, in_sram_col};
//         sram_din=data_q;
//     end
//     else begin
//         sram_WEB=1'b1;
//         sram_addr={set_idx_q, read_sram_row, read_sram_col};
//         sram_din=data_q;
//     end
// end


//Part 3 Seq Logic: sram input
//reg [3:0] in_sram_idx; 
//reg [4:0] in_sram_row, in_sram_col;
MEM_wrapper sram(.clk(clk),.A(sram_addr),.DI(sram_din),.WEB(sram_WEB),.CS(1'b1),.OE(1'b1),.DO(sram_dout));

// //Part 3 Seq Logic INPUT_1 
// always@(posedge clk or negedge rst_n)begin
//     if(!rst_n) data_q<=8'd0;
//     else if(in_valid_data==1'b1) data_q<=data;
//     else data_q<=8'd0;
// end

//Part 3 Seq Logic INPUT_2 
integer i,j;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin 
        in_valid_param_cnt<=3'd0;
        QP_q<=5'd0; set_idx_q<=4'd0;
        for(i=0;i<4;i=i+1)mode_q_arr[i]<=1'b0;
        cur_set_cnt<=5'd0;  //only reset when CLEAR_big
    end
    else if(in_valid_param==1'b1)begin
        in_valid_param_cnt<=in_valid_param_cnt+1'd1;
        if(in_valid_param_cnt<=3)mode_q_arr[in_valid_param_cnt]<=mode;
        if(in_valid_param_cnt==0)begin
            QP_q<=QP; set_idx_q<=index; cur_set_cnt<=cur_set_cnt+1;
        end
    end
    else if(cur_state==CLEAR_small)begin
        in_valid_param_cnt<=3'd0;
        QP_q<=5'd0; set_idx_q<=4'd0;
        for(i=0;i<4;i=i+1)mode_q_arr[i]<=1'b0;
    end
    else if(cur_state==CLEAR_big)begin
        in_valid_param_cnt<=3'd0;
        QP_q<=5'd0; set_idx_q<=4'd0;
        for(i=0;i<4;i=i+1) mode_q_arr[i]<=1'b0;
        cur_set_cnt<=5'd0;
    end
end

//Part 3 Seq Logic sram write
reg [10:0] read_sram_cnt;
reg [4:0] save_reg_row, save_reg_col;
reg [4:0] save_reg_row_q, save_reg_col_q;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sram_addr<=14'd0; sram_WEB<=1'b1; sram_din<=14'd0;
        in_sram_idx<=4'd0; in_sram_row<=5'd0; in_sram_col<=5'd0;
    end
    else if(in_valid_data==1'b1||cur_state==INPUT_1)begin
        if(sram_addr=={4'd15, 5'd31, 5'd31})begin
            sram_addr<=14'd0; sram_WEB<=1'b1; sram_din<=14'd0;
        end
        else begin
            sram_addr<={in_sram_idx, in_sram_row, in_sram_col};
            sram_din<=data; sram_WEB<=1'b0; //write addr
        end

        if(in_sram_col==31&&in_sram_row==31)begin       //1 img done
            in_sram_col<=4'd0; in_sram_row<=4'd0; 
            in_sram_idx<=in_sram_idx+1;
        end
        else if(in_sram_col==31&&in_sram_row<31)begin   //next row
            in_sram_col<=4'd0; in_sram_row<=in_sram_row+1; 
            in_sram_idx<=in_sram_idx;
        end
        else begin                                      //next element
            in_sram_col<=in_sram_col+1'd1; in_sram_row<=in_sram_row; 
            in_sram_idx<=in_sram_idx;
        end

    end
    //for READ_sram_and_diverse
    else if(cur_state==READ_sram_and_diverse&&read_sram_cnt<=1025)begin
        if(read_sram_cnt>=0&&read_sram_cnt<=1023)begin
            //belongs to line 265
            sram_addr<={set_idx_q, read_sram_row, read_sram_col};
            sram_din<=8'd0; sram_WEB<=1'b1;     //read only
        end
    end
    else if(cur_state==CLEAR_big)begin
        sram_addr<=14'd0; sram_WEB<=1'b1; sram_din<=14'd0;
        in_sram_idx<=4'd0; in_sram_row<=5'd0; in_sram_col<=5'd0;    
    end
    else begin
        sram_addr<=14'd0; sram_WEB<=1'b1; sram_din<=14'd0;
        in_sram_idx<=in_sram_idx; in_sram_row<=in_sram_row; in_sram_col<=in_sram_col; 
    end
end

//Part 3 Seq Logic Read SRAM 
//reg [4:0] read_sram_row, read_sram_col;
reg [7:0] img_reg [0:31][0:31]; 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        read_sram_cnt<=11'd0; READ_sram_done<=1'b0;
        save_reg_row<=5'd0; save_reg_col<=5'd0;
        save_reg_row_q<=5'd0; save_reg_col_q<=5'd0;
        read_sram_row<=5'd0; read_sram_col<=5'd0;
        for(i=0;i<32;i=i+1)begin
            for(j=0;j<32;j=j+1)begin
                img_reg[i][j]<=8'd0;
            end
        end
    end
    else if(cur_state==READ_sram_and_diverse&&read_sram_cnt<=1025)begin  
        read_sram_cnt<=read_sram_cnt+1'd1;
        save_reg_row<=read_sram_row; save_reg_col<=read_sram_col; 
        save_reg_row_q<=save_reg_row; save_reg_col_q<=save_reg_col;   
        if(read_sram_cnt>=2&&read_sram_cnt<=1025)img_reg[save_reg_row_q][save_reg_col_q]<=sram_dout;

        if(read_sram_cnt>=0&&read_sram_cnt<=1023)begin
            if(read_sram_col==31)begin
                read_sram_col<=5'd0; read_sram_row<=read_sram_row+1'd1;
            end
            else begin
                read_sram_col<=read_sram_col+1'd1; read_sram_row<=read_sram_row;
            end 
        end
        //要多等一個cycle，因為我們晚一個cycle才開始read
        if(read_sram_cnt==1025)READ_sram_done<=1'b1;
        else READ_sram_done<=READ_sram_done;
    end
    else if(cur_state==EVAL_4X4_next||cur_state==EVAL_16X16_next)begin
        //stoe back to img reg
        for(i=0;i<4;i=i+1)begin
            for(j=0;j<4;j=j+1)begin
                if(cur_4X4[i][j]<0) img_reg[small_lf_up_row+i][small_lf_up_col+j]<=8'd0;
                else if(cur_4X4[i][j]>255) img_reg[small_lf_up_row+i][small_lf_up_col+j]<=8'd255;
                else img_reg[small_lf_up_row+i][small_lf_up_col+j]<=cur_4X4[i][j][7:0];
            end
        end
    end
    else if(cur_state==CLEAR_small)begin
        read_sram_cnt<=11'd0; READ_sram_done<=1'b0;
        save_reg_row<=5'd0; save_reg_col<=5'd0;
        read_sram_row<=5'd0; read_sram_col<=5'd0;
        for(i=0;i<32;i=i+1)begin
            for(j=0;j<32;j=j+1)begin
                img_reg[i][j]<=8'd0;
            end
        end
    end
    else if(cur_state==CLEAR_big)begin
        read_sram_cnt<=11'd0; READ_sram_done<=1'b0;
        save_reg_row<=5'd0; save_reg_col<=5'd0;
        read_sram_row<=5'd0; read_sram_col<=5'd0;
        for(i=0;i<32;i=i+1)begin
            for(j=0;j<32;j=j+1)begin
                img_reg[i][j]<=8'd0;
            end
        end
    end
end

//===INTRA_Prediction_DC and SAD===

//Part 2 Comb Logic
reg [7:0] add8_in0, add8_in1, add8_in2, add8_in3, add8_in4, add8_in5, add8_in6, add8_in7;
wire [15:0]add8_out;

AdderTree8 ADD8(
    .in0(add8_in0),.in1(add8_in1),.in2(add8_in2),.in3(add8_in3),
    .in4(add8_in4),.in5(add8_in5),.in6(add8_in6),.in7(add8_in7),
    .sum_out(add8_out)
);

//Part 3 Seq Logic
//reg [4:0] lf_up_row, lf_up_col; 

//Part 2 Cpmb Logic
//EVAL_intra_4X4, EVAL_intra_16X16, EVAL_4X4, EVAL_16X16, EVAL_rec_4X4, EVAL_rec_16X16
reg [7:0] left_ele [0:15]; 
reg [7:0] up_ele[0:15];
always@(*)begin
    if(lf_up_col!=5'd0&&(cur_state==EVAL_intra_4X4
    ||cur_state==EVAL_4X4||cur_state==EVAL_rec_4X4))begin
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
    else if(lf_up_col!=5'd0&&(cur_state==EVAL_intra_16X16
    ||cur_state==EVAL_16X16||cur_state==EVAL_rec_16X16))begin
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
        left_ele[0]  = 8'd0;
        left_ele[1]  = 8'd0;
        left_ele[2]  = 8'd0;
        left_ele[3]  = 8'd0;
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
end

always@(*)begin
    if(lf_up_row!=5'd0&&(cur_state==EVAL_intra_4X4
    ||cur_state==EVAL_4X4||cur_state==EVAL_rec_4X4))begin
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
    else if(lf_up_row!=5'd0&&(cur_state==EVAL_intra_16X16
    ||cur_state==EVAL_16X16||cur_state==EVAL_rec_16X16))begin
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
        up_ele[0]  = 8'd0;
        up_ele[1]  = 8'd0;
        up_ele[2]  = 8'd0;
        up_ele[3]  = 8'd0;
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
end

//Part 3 Seq Logic
reg [14:0] DC_predict;                  

reg [17:0] SAD_DC, SAD_H, SAD_V;        
reg [8:0] SAD_cnt;
reg [4:0] cur_SAD_row_offset, cur_SAD_col_offset;
reg [1:0] intra_mode;               //DC(0) or H(1) or V(2)

//Part 2 Comb Logic
reg [2:0] DC_cnt;
reg [2:0] DC_case;  //>>2(0) or >>3(1) or >>4(2) or>>5(3) or 128 (7)
always@(*)begin
    //case 16X16 T&L 
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
    //case 16X16 only T
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
    //case 16X16 only L
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
    //case 4X4 T&L 
    else if(cur_state==EVAL_intra_4X4 && lf_up_row>0 && lf_up_col>0)begin
        DC_case=3'd1;   //>>3
        if(DC_cnt==0)begin
            add8_in0=up_ele[0];
            add8_in1=up_ele[1];
            add8_in2=up_ele[2];
            add8_in3=up_ele[3];
            add8_in4=left_ele[0];
            add8_in5=left_ele[1];
            add8_in6=left_ele[2];
            add8_in7=left_ele[3];
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
    //case 4X4 only T
    else if(cur_state==EVAL_intra_4X4 && lf_up_row==0 && lf_up_col>0)begin
        DC_case=3'd0;   //>>2
        if(DC_cnt==0)begin
            add8_in0=8'd0;
            add8_in1=8'd0;
            add8_in2=8'd0;
            add8_in3=8'd0;
            add8_in4=left_ele[0];
            add8_in5=left_ele[1];
            add8_in6=left_ele[2];
            add8_in7=left_ele[3];
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
    //case 4X4 only L
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

//Part 2 Comb Logic 
reg [7:0] cur_DC_predict, cur_H_predict, cur_V_predict;
always@(*)begin
    cur_DC_predict=DC_predict;
    //cur_H_predict, use left_ele
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

//Part 2 Comb Logic choose intra_mode with SAD
reg [1:0] intra_mode_choice; //DC(0) or H(1) or V(2)
always@(*)begin
    if(lf_up_col==0 && lf_up_row==0) intra_mode_choice=2'd0; //DC only
    else if(lf_up_row>0 && lf_up_col==0) begin
        if(SAD_DC<=SAD_V)intra_mode_choice=2'd0; //DC first
        else intra_mode_choice=2'd2;             //V
    end
    else if(lf_up_row==0 && lf_up_col>0) begin
        if(SAD_DC<=SAD_H)intra_mode_choice=2'd0; //DC first
        else intra_mode_choice=2'd1;             //H
    end
    else if(lf_up_row>0 && lf_up_col>0) begin
        if(SAD_DC<=SAD_H && SAD_DC<=SAD_V) intra_mode_choice=2'd0;  //DC first
        else if(SAD_H<=SAD_V) intra_mode_choice=2'd1;               //H second
        else intra_mode_choice=2'd2;                                //V final
    end
    else intra_mode_choice=2'd3;    //NULL
end
//=========================

//===EVAL_4X4 & EVAL_16X16===
reg [3:0] EVAL_4X4_cnt,EVAL_16X16_cnt;


//step 1 X=I(img_reg 8 bit)-predict
//when (EVAL_4X4_cnt, EVAL_16X16_cnt==0)
reg [7:0] cur_4X4_predict [0:3][0:3]; 
always@(*)begin
    //case 0:if intra use DC
    if(intra_mode==2'd0)begin
        cur_4X4_predict[0][0] = DC_predict;
        cur_4X4_predict[0][1] = DC_predict;
        cur_4X4_predict[0][2] = DC_predict;
        cur_4X4_predict[0][3] = DC_predict;
        cur_4X4_predict[1][0] = DC_predict;
        cur_4X4_predict[1][1] = DC_predict;
        cur_4X4_predict[1][2] = DC_predict;
        cur_4X4_predict[1][3] = DC_predict;
        cur_4X4_predict[2][0] = DC_predict;
        cur_4X4_predict[2][1] = DC_predict;
        cur_4X4_predict[2][2] = DC_predict;
        cur_4X4_predict[2][3] = DC_predict;
        cur_4X4_predict[3][0] = DC_predict;
        cur_4X4_predict[3][1] = DC_predict;
        cur_4X4_predict[3][2] = DC_predict;
        cur_4X4_predict[3][3] = DC_predict;
    end
    //case 1:if intra use H
    else if(intra_mode==2'd1)begin
        if(cur_state==EVAL_16X16||cur_state==EVAL_rec_16X16)begin
            if(small_lf_up_row==lf_up_row)begin
                cur_4X4_predict[0][0]=left_ele[0];
                cur_4X4_predict[0][1]=left_ele[0];
                cur_4X4_predict[0][2]=left_ele[0];
                cur_4X4_predict[0][3]=left_ele[0];
                cur_4X4_predict[1][0]=left_ele[1];
                cur_4X4_predict[1][1]=left_ele[1];
                cur_4X4_predict[1][2]=left_ele[1];
                cur_4X4_predict[1][3]=left_ele[1];
                cur_4X4_predict[2][0]=left_ele[2];
                cur_4X4_predict[2][1]=left_ele[2];
                cur_4X4_predict[2][2]=left_ele[2];
                cur_4X4_predict[2][3]=left_ele[2];
                cur_4X4_predict[3][0]=left_ele[3];
                cur_4X4_predict[3][1]=left_ele[3];
                cur_4X4_predict[3][2]=left_ele[3];
                cur_4X4_predict[3][3]=left_ele[3];
            end
            else if(small_lf_up_row==lf_up_row+4)begin
                cur_4X4_predict[0][0]=left_ele[4];
                cur_4X4_predict[0][1]=left_ele[4];
                cur_4X4_predict[0][2]=left_ele[4];
                cur_4X4_predict[0][3]=left_ele[4];
                cur_4X4_predict[1][0]=left_ele[5];
                cur_4X4_predict[1][1]=left_ele[5];
                cur_4X4_predict[1][2]=left_ele[5];
                cur_4X4_predict[1][3]=left_ele[5];
                cur_4X4_predict[2][0]=left_ele[6];
                cur_4X4_predict[2][1]=left_ele[6];
                cur_4X4_predict[2][2]=left_ele[6];
                cur_4X4_predict[2][3]=left_ele[6];
                cur_4X4_predict[3][0]=left_ele[7];
                cur_4X4_predict[3][1]=left_ele[7];
                cur_4X4_predict[3][2]=left_ele[7];
                cur_4X4_predict[3][3]=left_ele[7];
            end
            else if(small_lf_up_row==lf_up_row+8)begin
                cur_4X4_predict[0][0]=left_ele[8];
                cur_4X4_predict[0][1]=left_ele[8];
                cur_4X4_predict[0][2]=left_ele[8];
                cur_4X4_predict[0][3]=left_ele[8];
                cur_4X4_predict[1][0]=left_ele[9];
                cur_4X4_predict[1][1]=left_ele[9];
                cur_4X4_predict[1][2]=left_ele[9];
                cur_4X4_predict[1][3]=left_ele[9];
                cur_4X4_predict[2][0]=left_ele[10];
                cur_4X4_predict[2][1]=left_ele[10];
                cur_4X4_predict[2][2]=left_ele[10];
                cur_4X4_predict[2][3]=left_ele[10];
                cur_4X4_predict[3][0]=left_ele[11];
                cur_4X4_predict[3][1]=left_ele[11];
                cur_4X4_predict[3][2]=left_ele[11];
                cur_4X4_predict[3][3]=left_ele[11];
            end
            else if(small_lf_up_row==lf_up_row+12)begin
                cur_4X4_predict[0][0]=left_ele[12];
                cur_4X4_predict[0][1]=left_ele[12];
                cur_4X4_predict[0][2]=left_ele[12];
                cur_4X4_predict[0][3]=left_ele[12];
                cur_4X4_predict[1][0]=left_ele[13];
                cur_4X4_predict[1][1]=left_ele[13];
                cur_4X4_predict[1][2]=left_ele[13];
                cur_4X4_predict[1][3]=left_ele[13];
                cur_4X4_predict[2][0]=left_ele[14];
                cur_4X4_predict[2][1]=left_ele[14];
                cur_4X4_predict[2][2]=left_ele[14];
                cur_4X4_predict[2][3]=left_ele[14];
                cur_4X4_predict[3][0]=left_ele[15];
                cur_4X4_predict[3][1]=left_ele[15];
                cur_4X4_predict[3][2]=left_ele[15];
                cur_4X4_predict[3][3]=left_ele[15];
            end
            else begin
                cur_4X4_predict[0][0] = 8'd0;
                cur_4X4_predict[0][1] = 8'd0;
                cur_4X4_predict[0][2] = 8'd0;
                cur_4X4_predict[0][3] = 8'd0;
                cur_4X4_predict[1][0] = 8'd0;
                cur_4X4_predict[1][1] = 8'd0;
                cur_4X4_predict[1][2] = 8'd0;
                cur_4X4_predict[1][3] = 8'd0;
                cur_4X4_predict[2][0] = 8'd0;
                cur_4X4_predict[2][1] = 8'd0;
                cur_4X4_predict[2][2] = 8'd0;
                cur_4X4_predict[2][3] = 8'd0;
                cur_4X4_predict[3][0] = 8'd0;
                cur_4X4_predict[3][1] = 8'd0;
                cur_4X4_predict[3][2] = 8'd0;
                cur_4X4_predict[3][3] = 8'd0;
            end
        end
        else if(cur_state==EVAL_4X4||cur_state==EVAL_rec_4X4)begin
            cur_4X4_predict[0][0]=left_ele[0];
            cur_4X4_predict[0][1]=left_ele[0];
            cur_4X4_predict[0][2]=left_ele[0];
            cur_4X4_predict[0][3]=left_ele[0];
            cur_4X4_predict[1][0]=left_ele[1];
            cur_4X4_predict[1][1]=left_ele[1];
            cur_4X4_predict[1][2]=left_ele[1];
            cur_4X4_predict[1][3]=left_ele[1];
            cur_4X4_predict[2][0]=left_ele[2];
            cur_4X4_predict[2][1]=left_ele[2];
            cur_4X4_predict[2][2]=left_ele[2];
            cur_4X4_predict[2][3]=left_ele[2];
            cur_4X4_predict[3][0]=left_ele[3];
            cur_4X4_predict[3][1]=left_ele[3];
            cur_4X4_predict[3][2]=left_ele[3];
            cur_4X4_predict[3][3]=left_ele[3];
        end
        else begin
            cur_4X4_predict[0][0] = 8'd0;
            cur_4X4_predict[0][1] = 8'd0;
            cur_4X4_predict[0][2] = 8'd0;
            cur_4X4_predict[0][3] = 8'd0;
            cur_4X4_predict[1][0] = 8'd0;
            cur_4X4_predict[1][1] = 8'd0;
            cur_4X4_predict[1][2] = 8'd0;
            cur_4X4_predict[1][3] = 8'd0;
            cur_4X4_predict[2][0] = 8'd0;
            cur_4X4_predict[2][1] = 8'd0;
            cur_4X4_predict[2][2] = 8'd0;
            cur_4X4_predict[2][3] = 8'd0;
            cur_4X4_predict[3][0] = 8'd0;
            cur_4X4_predict[3][1] = 8'd0;
            cur_4X4_predict[3][2] = 8'd0;
            cur_4X4_predict[3][3] = 8'd0;
        end
    end
    //case 2 if intra use V
    else if(intra_mode==2'd2)begin
        if(cur_state==EVAL_16X16||cur_state==EVAL_rec_16X16)begin
            if(small_lf_up_col==lf_up_col)begin
                cur_4X4_predict[0][0]=up_ele[0];
                cur_4X4_predict[0][1]=up_ele[1];
                cur_4X4_predict[0][2]=up_ele[2];
                cur_4X4_predict[0][3]=up_ele[3];
                cur_4X4_predict[1][0]=up_ele[0];
                cur_4X4_predict[1][1]=up_ele[1];
                cur_4X4_predict[1][2]=up_ele[2];
                cur_4X4_predict[1][3]=up_ele[3];
                cur_4X4_predict[2][0]=up_ele[0];
                cur_4X4_predict[2][1]=up_ele[1];
                cur_4X4_predict[2][2]=up_ele[2];
                cur_4X4_predict[2][3]=up_ele[3];
                cur_4X4_predict[3][0]=up_ele[0];
                cur_4X4_predict[3][1]=up_ele[1];
                cur_4X4_predict[3][2]=up_ele[2];
                cur_4X4_predict[3][3]=up_ele[3];
            end
            else if(small_lf_up_col==lf_up_col+4)begin
                cur_4X4_predict[0][0]=up_ele[4];
                cur_4X4_predict[0][1]=up_ele[5];
                cur_4X4_predict[0][2]=up_ele[6];
                cur_4X4_predict[0][3]=up_ele[7];
                cur_4X4_predict[1][0]=up_ele[4];
                cur_4X4_predict[1][1]=up_ele[5];
                cur_4X4_predict[1][2]=up_ele[6];
                cur_4X4_predict[1][3]=up_ele[7];
                cur_4X4_predict[2][0]=up_ele[4];
                cur_4X4_predict[2][1]=up_ele[5];
                cur_4X4_predict[2][2]=up_ele[6];
                cur_4X4_predict[2][3]=up_ele[7];
                cur_4X4_predict[3][0]=up_ele[4];
                cur_4X4_predict[3][1]=up_ele[5];
                cur_4X4_predict[3][2]=up_ele[6];
                cur_4X4_predict[3][3]=up_ele[7];
            end
            else if(small_lf_up_col==lf_up_col+8)begin
                cur_4X4_predict[0][0]=up_ele[8];
                cur_4X4_predict[0][1]=up_ele[9];
                cur_4X4_predict[0][2]=up_ele[10];
                cur_4X4_predict[0][3]=up_ele[11];
                cur_4X4_predict[1][0]=up_ele[8];
                cur_4X4_predict[1][1]=up_ele[9];
                cur_4X4_predict[1][2]=up_ele[10];
                cur_4X4_predict[1][3]=up_ele[11];
                cur_4X4_predict[2][0]=up_ele[8];
                cur_4X4_predict[2][1]=up_ele[9];
                cur_4X4_predict[2][2]=up_ele[10];
                cur_4X4_predict[2][3]=up_ele[11];
                cur_4X4_predict[3][0]=up_ele[8];
                cur_4X4_predict[3][1]=up_ele[9];
                cur_4X4_predict[3][2]=up_ele[10];
                cur_4X4_predict[3][3]=up_ele[11];
            end
            else if(small_lf_up_col==lf_up_col+12)begin
                cur_4X4_predict[0][0]=up_ele[12];
                cur_4X4_predict[0][1]=up_ele[13];
                cur_4X4_predict[0][2]=up_ele[14];
                cur_4X4_predict[0][3]=up_ele[15];
                cur_4X4_predict[1][0]=up_ele[12];
                cur_4X4_predict[1][1]=up_ele[13];
                cur_4X4_predict[1][2]=up_ele[14];
                cur_4X4_predict[1][3]=up_ele[15];
                cur_4X4_predict[2][0]=up_ele[12];
                cur_4X4_predict[2][1]=up_ele[13];
                cur_4X4_predict[2][2]=up_ele[14];
                cur_4X4_predict[2][3]=up_ele[15];
                cur_4X4_predict[3][0]=up_ele[12];
                cur_4X4_predict[3][1]=up_ele[13];
                cur_4X4_predict[3][2]=up_ele[14];
                cur_4X4_predict[3][3]=up_ele[15];
            end
            else begin
                cur_4X4_predict[0][0] = 8'd0;
                cur_4X4_predict[0][1] = 8'd0;
                cur_4X4_predict[0][2] = 8'd0;
                cur_4X4_predict[0][3] = 8'd0;
                cur_4X4_predict[1][0] = 8'd0;
                cur_4X4_predict[1][1] = 8'd0;
                cur_4X4_predict[1][2] = 8'd0;
                cur_4X4_predict[1][3] = 8'd0;
                cur_4X4_predict[2][0] = 8'd0;
                cur_4X4_predict[2][1] = 8'd0;
                cur_4X4_predict[2][2] = 8'd0;
                cur_4X4_predict[2][3] = 8'd0;
                cur_4X4_predict[3][0] = 8'd0;
                cur_4X4_predict[3][1] = 8'd0;
                cur_4X4_predict[3][2] = 8'd0;
                cur_4X4_predict[3][3] = 8'd0;
            end
        end
        else if(cur_state==EVAL_4X4||cur_state==EVAL_rec_4X4)begin
            cur_4X4_predict[0][0]=up_ele[0];
            cur_4X4_predict[0][1]=up_ele[1];
            cur_4X4_predict[0][2]=up_ele[2];
            cur_4X4_predict[0][3]=up_ele[3];
            cur_4X4_predict[1][0]=up_ele[0];
            cur_4X4_predict[1][1]=up_ele[1];
            cur_4X4_predict[1][2]=up_ele[2];
            cur_4X4_predict[1][3]=up_ele[3];
            cur_4X4_predict[2][0]=up_ele[0];
            cur_4X4_predict[2][1]=up_ele[1];
            cur_4X4_predict[2][2]=up_ele[2];
            cur_4X4_predict[2][3]=up_ele[3];
            cur_4X4_predict[3][0]=up_ele[0];
            cur_4X4_predict[3][1]=up_ele[1];
            cur_4X4_predict[3][2]=up_ele[2];
            cur_4X4_predict[3][3]=up_ele[3];
        end
        else begin
            cur_4X4_predict[0][0] = 8'd0;
            cur_4X4_predict[0][1] = 8'd0;
            cur_4X4_predict[0][2] = 8'd0;
            cur_4X4_predict[0][3] = 8'd0;
            cur_4X4_predict[1][0] = 8'd0;
            cur_4X4_predict[1][1] = 8'd0;
            cur_4X4_predict[1][2] = 8'd0;
            cur_4X4_predict[1][3] = 8'd0;
            cur_4X4_predict[2][0] = 8'd0;
            cur_4X4_predict[2][1] = 8'd0;
            cur_4X4_predict[2][2] = 8'd0;
            cur_4X4_predict[2][3] = 8'd0;
            cur_4X4_predict[3][0] = 8'd0;
            cur_4X4_predict[3][1] = 8'd0;
            cur_4X4_predict[3][2] = 8'd0;
            cur_4X4_predict[3][3] = 8'd0;
        end
    end
    else begin
        cur_4X4_predict[0][0] = 8'd0;
        cur_4X4_predict[0][1] = 8'd0;
        cur_4X4_predict[0][2] = 8'd0;
        cur_4X4_predict[0][3] = 8'd0;
        cur_4X4_predict[1][0] = 8'd0;
        cur_4X4_predict[1][1] = 8'd0;
        cur_4X4_predict[1][2] = 8'd0;
        cur_4X4_predict[1][3] = 8'd0;
        cur_4X4_predict[2][0] = 8'd0;
        cur_4X4_predict[2][1] = 8'd0;
        cur_4X4_predict[2][2] = 8'd0;
        cur_4X4_predict[2][3] = 8'd0;
        cur_4X4_predict[3][0] = 8'd0;
        cur_4X4_predict[3][1] = 8'd0;
        cur_4X4_predict[3][2] = 8'd0;
        cur_4X4_predict[3][3] = 8'd0;
    end
end

//step 2 W=Cf X Cf 
//when (EVAL_4X4_cnt, EVAL_16X16_cnt==1)
reg signed [31:0] C_mul_mat_out[0:3][0:3];
C_mul_mat C_mul_mat_inst(
    .cur_4X4_0_0(cur_4X4[0][0]),.cur_4X4_0_1(cur_4X4[0][1]),.cur_4X4_0_2(cur_4X4[0][2]),.cur_4X4_0_3(cur_4X4[0][3]),
    .cur_4X4_1_0(cur_4X4[1][0]),.cur_4X4_1_1(cur_4X4[1][1]),.cur_4X4_1_2(cur_4X4[1][2]),.cur_4X4_1_3(cur_4X4[1][3]),
    .cur_4X4_2_0(cur_4X4[2][0]),.cur_4X4_2_1(cur_4X4[2][1]),.cur_4X4_2_2(cur_4X4[2][2]),.cur_4X4_2_3(cur_4X4[2][3]),
    .cur_4X4_3_0(cur_4X4[3][0]),.cur_4X4_3_1(cur_4X4[3][1]),.cur_4X4_3_2(cur_4X4[3][2]),.cur_4X4_3_3(cur_4X4[3][3]),
    .result_0_0(C_mul_mat_out[0][0]),.result_0_1(C_mul_mat_out[0][1]),.result_0_2(C_mul_mat_out[0][2]),.result_0_3(C_mul_mat_out[0][3]),
    .result_1_0(C_mul_mat_out[1][0]),.result_1_1(C_mul_mat_out[1][1]),.result_1_2(C_mul_mat_out[1][2]),.result_1_3(C_mul_mat_out[1][3]),
    .result_2_0(C_mul_mat_out[2][0]),.result_2_1(C_mul_mat_out[2][1]),.result_2_2(C_mul_mat_out[2][2]),.result_2_3(C_mul_mat_out[2][3]),
    .result_3_0(C_mul_mat_out[3][0]),.result_3_1(C_mul_mat_out[3][1]),.result_3_2(C_mul_mat_out[3][2]),.result_3_3(C_mul_mat_out[3][3])
);

//when (EVAL_4X4_cnt, EVAL_16X16_cnt==2)
reg signed [31:0] mat_mul_C_out[0:3][0:3];
mat_mul_C mat_mul_C_inst(
    .cur_4X4_0_0(cur_4X4[0][0]),.cur_4X4_0_1(cur_4X4[0][1]),.cur_4X4_0_2(cur_4X4[0][2]),.cur_4X4_0_3(cur_4X4[0][3]),
    .cur_4X4_1_0(cur_4X4[1][0]),.cur_4X4_1_1(cur_4X4[1][1]),.cur_4X4_1_2(cur_4X4[1][2]),.cur_4X4_1_3(cur_4X4[1][3]),
    .cur_4X4_2_0(cur_4X4[2][0]),.cur_4X4_2_1(cur_4X4[2][1]),.cur_4X4_2_2(cur_4X4[2][2]),.cur_4X4_2_3(cur_4X4[2][3]),
    .cur_4X4_3_0(cur_4X4[3][0]),.cur_4X4_3_1(cur_4X4[3][1]),.cur_4X4_3_2(cur_4X4[3][2]),.cur_4X4_3_3(cur_4X4[3][3]),
    .result_0_0(mat_mul_C_out[0][0]),.result_0_1(mat_mul_C_out[0][1]),.result_0_2(mat_mul_C_out[0][2]),.result_0_3(mat_mul_C_out[0][3]),
    .result_1_0(mat_mul_C_out[1][0]),.result_1_1(mat_mul_C_out[1][1]),.result_1_2(mat_mul_C_out[1][2]),.result_1_3(mat_mul_C_out[1][3]),
    .result_2_0(mat_mul_C_out[2][0]),.result_2_1(mat_mul_C_out[2][1]),.result_2_2(mat_mul_C_out[2][2]),.result_2_3(mat_mul_C_out[2][3]),
    .result_3_0(mat_mul_C_out[3][0]),.result_3_1(mat_mul_C_out[3][1]),.result_3_2(mat_mul_C_out[3][2]),.result_3_3(mat_mul_C_out[3][3])
);

//step 3
//step 3-1 
//when (EVAL_4X4_cnt, EVAL_16X16_cnt==3)
reg W_sign_bit[0:3][0:3];

//step 3-2 elementwise
reg signed [31:0] MF_a, MF_b, MF_c; 

always @(*) begin
    if(cur_state==EVAL_16X16||cur_state==EVAL_4X4)begin
        case(QP_q)
            0,6,12,18,24,30: begin  //QP mod 6 = 0
                MF_a = 32'd13107; MF_b = 32'd5243; MF_c =32'd8066;
            end
            1,7,13,19,25,31: begin  //QP mod 6 = 1
                MF_a = 32'd11916; MF_b = 32'd4660; MF_c =32'd7490;
            end
            2,8,14,20,26: begin     //QP mod 6 = 2
                MF_a = 32'd10082; MF_b = 32'd4194; MF_c = 32'd6554;
            end
            3,9,15,21,27: begin     //QP mod 6 = 3
                MF_a = 32'd9362; MF_b = 32'd3647;  MF_c = 32'd5825;
            end
            4,10,16,22,28: begin    //QP mod 6 = 4
                MF_a = 32'd8192; MF_b = 32'd3355;  MF_c = 32'd5243;
            end
            5,11,17,23,29: begin    //QP mod 6 = 5
                MF_a = 32'd7282; MF_b = 32'd2893;  MF_c = 32'd4559;
            end
            default: begin
                MF_a = 32'd0;    MF_b = 32'd0;     MF_c = 32'd0;
            end
        endcase
    end
    else begin
        case(QP_q)
            0,6,12,18,24,30: begin  // QP mod 6 = 0
                MF_a = 32'd10; MF_b = 32'd16; MF_c = 32'd13;
            end
            1,7,13,19,25,31: begin  // QP mod 6 = 1
                MF_a = 32'd11; MF_b = 32'd18; MF_c = 32'd14;
            end
            2,8,14,20,26: begin     // QP mod 6 = 2
                MF_a = 32'd13; MF_b = 32'd20; MF_c = 32'd16;
            end
            3,9,15,21,27: begin     // QP mod 6 = 3
                MF_a = 32'd14; MF_b = 32'd23; MF_c = 32'd18;
            end
            4,10,16,22,28: begin    // QP mod 6 = 4
                MF_a = 32'd16; MF_b = 32'd25; MF_c = 32'd20;
            end
            5,11,17,23,29: begin    // QP mod 6 = 5
                MF_a = 32'd18; MF_b = 32'd29; MF_c = 32'd23;
            end
            default: begin
                MF_a = 32'd0; MF_b = 32'd0; MF_c = 32'd0;
            end
        endcase
    end
end

reg signed [31:0] MF_f;
always @(*) begin
    case (QP_q)
        // 0..5 -> 10922
        0, 1, 2, 3, 4, 5: MF_f = 32'd10922;
        // 6..11 -> 21845
        6, 7, 8, 9, 10, 11: MF_f = 32'd21845;
        // 12..17 -> 43690
        12, 13, 14, 15, 16, 17: MF_f = 32'd43690;
        // 18..23 -> 87381
        18, 19, 20, 21, 22, 23: MF_f = 32'd87381;
        // 24..29 -> 174762
        24, 25, 26, 27, 28, 29: MF_f = 32'd174762;
        default: MF_f = 32'd0;
    endcase
end

//when (EVAL_4X4_cnt, EVAL_16X16_cnt==4)
reg [3:0] EVAL_rec_4X4_cnt, EVAL_rec_16X16_cnt; 
reg signed [31:0]  mul_A_in[0:3][0:3];
reg signed [31:0]  mul_B_in[0:3][0:3];
wire signed [31:0] mul_16_out[0:3][0:3];

elementwise_mul16 mul16(
    //A inputs
    .A0 (mul_A_in[0][0]), .A1 (mul_A_in[0][1]), .A2 (mul_A_in[0][2]), .A3 (mul_A_in[0][3]),
    .A4 (mul_A_in[1][0]), .A5 (mul_A_in[1][1]), .A6 (mul_A_in[1][2]), .A7 (mul_A_in[1][3]),
    .A8 (mul_A_in[2][0]), .A9 (mul_A_in[2][1]), .A10(mul_A_in[2][2]), .A11(mul_A_in[2][3]),
    .A12(mul_A_in[3][0]), .A13(mul_A_in[3][1]), .A14(mul_A_in[3][2]), .A15(mul_A_in[3][3]),
    //B inputs
    .B0 (mul_B_in[0][0]), .B1 (mul_B_in[0][1]), .B2 (mul_B_in[0][2]), .B3 (mul_B_in[0][3]),
    .B4 (mul_B_in[1][0]), .B5 (mul_B_in[1][1]), .B6 (mul_B_in[1][2]), .B7 (mul_B_in[1][3]),
    .B8 (mul_B_in[2][0]), .B9 (mul_B_in[2][1]), .B10(mul_B_in[2][2]), .B11(mul_B_in[2][3]),
    .B12(mul_B_in[3][0]), .B13(mul_B_in[3][1]), .B14(mul_B_in[3][2]), .B15(mul_B_in[3][3]),
    //P outputs
    .P0 (mul_16_out[0][0]), .P1 (mul_16_out[0][1]), .P2 (mul_16_out[0][2]), .P3 (mul_16_out[0][3]),
    .P4 (mul_16_out[1][0]), .P5 (mul_16_out[1][1]), .P6 (mul_16_out[1][2]), .P7 (mul_16_out[1][3]),
    .P8 (mul_16_out[2][0]), .P9 (mul_16_out[2][1]), .P10(mul_16_out[2][2]), .P11(mul_16_out[2][3]),
    .P12(mul_16_out[3][0]), .P13(mul_16_out[3][1]), .P14(mul_16_out[3][2]), .P15(mul_16_out[3][3])
);

reg signed [31:0] two_pow_floor_QP_div6;
always @(*) begin
    if(cur_state==EVAL_4X4||cur_state==EVAL_16X16)begin
        mul_A_in[0][0]=cur_4X4[0][0]; mul_A_in[0][1]=cur_4X4[0][1];
        mul_A_in[0][2]=cur_4X4[0][2]; mul_A_in[0][3]=cur_4X4[0][3];
        mul_A_in[1][0]=cur_4X4[1][0]; mul_A_in[1][1]=cur_4X4[1][1];
        mul_A_in[1][2]=cur_4X4[1][2]; mul_A_in[1][3]=cur_4X4[1][3];
        mul_A_in[2][0]=cur_4X4[2][0]; mul_A_in[2][1]=cur_4X4[2][1];
        mul_A_in[2][2]=cur_4X4[2][2]; mul_A_in[2][3]=cur_4X4[2][3];
        mul_A_in[3][0]=cur_4X4[3][0]; mul_A_in[3][1]=cur_4X4[3][1];
        mul_A_in[3][2]=cur_4X4[3][2]; mul_A_in[3][3]=cur_4X4[3][3];

        mul_B_in[0][0]=MF_a; mul_B_in[0][1]=MF_c; mul_B_in[0][2]=MF_a; mul_B_in[0][3]=MF_c;
        mul_B_in[1][0]=MF_c; mul_B_in[1][1]=MF_b; mul_B_in[1][2]=MF_c; mul_B_in[1][3]=MF_b;
        mul_B_in[2][0]=MF_a; mul_B_in[2][1]=MF_c; mul_B_in[2][2]=MF_a; mul_B_in[2][3]=MF_c;
        mul_B_in[3][0]=MF_c; mul_B_in[3][1]=MF_b; mul_B_in[3][2]=MF_c; mul_B_in[3][3]=MF_b;
    end
    else if((cur_state==EVAL_rec_4X4 && EVAL_rec_4X4_cnt==0)
    ||(cur_state==EVAL_rec_16X16 && EVAL_rec_16X16_cnt==0))begin
        //EVAL_4X4, EVAL_16X16 step 1-1 cur_4X4*Vij
        mul_A_in[0][0]=cur_4X4[0][0]; mul_A_in[0][1]=cur_4X4[0][1];
        mul_A_in[0][2]=cur_4X4[0][2]; mul_A_in[0][3]=cur_4X4[0][3];
        mul_A_in[1][0]=cur_4X4[1][0]; mul_A_in[1][1]=cur_4X4[1][1];
        mul_A_in[1][2]=cur_4X4[1][2]; mul_A_in[1][3]=cur_4X4[1][3];
        mul_A_in[2][0]=cur_4X4[2][0]; mul_A_in[2][1]=cur_4X4[2][1];
        mul_A_in[2][2]=cur_4X4[2][2]; mul_A_in[2][3]=cur_4X4[2][3];
        mul_A_in[3][0]=cur_4X4[3][0]; mul_A_in[3][1]=cur_4X4[3][1];
        mul_A_in[3][2]=cur_4X4[3][2]; mul_A_in[3][3]=cur_4X4[3][3];

        mul_B_in[0][0]=MF_a; mul_B_in[0][1]=MF_c; mul_B_in[0][2]=MF_a; mul_B_in[0][3]=MF_c;
        mul_B_in[1][0]=MF_c; mul_B_in[1][1]=MF_b; mul_B_in[1][2]=MF_c; mul_B_in[1][3]=MF_b;
        mul_B_in[2][0]=MF_a; mul_B_in[2][1]=MF_c; mul_B_in[2][2]=MF_a; mul_B_in[2][3]=MF_c;
        mul_B_in[3][0]=MF_c; mul_B_in[3][1]=MF_b; mul_B_in[3][2]=MF_c; mul_B_in[3][3]=MF_b;
    end
    else if((cur_state==EVAL_rec_4X4 && EVAL_rec_4X4_cnt==1)
    ||(cur_state==EVAL_rec_16X16 && EVAL_rec_16X16_cnt==1))begin
        //EVAL_4X4, EVAL_16X16 step 1-1 cur_4X4*2^(QP/6)
        mul_A_in[0][0]=cur_4X4[0][0]; mul_A_in[0][1]=cur_4X4[0][1];
        mul_A_in[0][2]=cur_4X4[0][2]; mul_A_in[0][3]=cur_4X4[0][3];
        mul_A_in[1][0]=cur_4X4[1][0]; mul_A_in[1][1]=cur_4X4[1][1];
        mul_A_in[1][2]=cur_4X4[1][2]; mul_A_in[1][3]=cur_4X4[1][3];
        mul_A_in[2][0]=cur_4X4[2][0]; mul_A_in[2][1]=cur_4X4[2][1];
        mul_A_in[2][2]=cur_4X4[2][2]; mul_A_in[2][3]=cur_4X4[2][3];
        mul_A_in[3][0]=cur_4X4[3][0]; mul_A_in[3][1]=cur_4X4[3][1];
        mul_A_in[3][2]=cur_4X4[3][2]; mul_A_in[3][3]=cur_4X4[3][3];

        mul_B_in[0][0] = two_pow_floor_QP_div6;
        mul_B_in[0][1] = two_pow_floor_QP_div6;
        mul_B_in[0][2] = two_pow_floor_QP_div6;
        mul_B_in[0][3] = two_pow_floor_QP_div6;
        mul_B_in[1][0] = two_pow_floor_QP_div6;
        mul_B_in[1][1] = two_pow_floor_QP_div6;
        mul_B_in[1][2] = two_pow_floor_QP_div6;
        mul_B_in[1][3] = two_pow_floor_QP_div6;
        mul_B_in[2][0] = two_pow_floor_QP_div6;
        mul_B_in[2][1] = two_pow_floor_QP_div6;
        mul_B_in[2][2] = two_pow_floor_QP_div6;
        mul_B_in[2][3] = two_pow_floor_QP_div6;
        mul_B_in[3][0] = two_pow_floor_QP_div6;
        mul_B_in[3][1] = two_pow_floor_QP_div6;
        mul_B_in[3][2] = two_pow_floor_QP_div6;
        mul_B_in[3][3] = two_pow_floor_QP_div6;
    end
    else begin
        mul_A_in[0][0]=32'd0; mul_A_in[0][1]=32'd0;
        mul_A_in[0][2]=32'd0; mul_A_in[0][3]=32'd0;
        mul_A_in[1][0]=32'd0; mul_A_in[1][1]=32'd0;
        mul_A_in[1][2]=32'd0; mul_A_in[1][3]=32'd0;
        mul_A_in[2][0]=32'd0; mul_A_in[2][1]=32'd0;
        mul_A_in[2][2]=32'd0; mul_A_in[2][3]=32'd0;
        mul_A_in[3][0]=32'd0; mul_A_in[3][1]=32'd0;
        mul_A_in[3][2]=32'd0; mul_A_in[3][3]=32'd0;

        mul_B_in[0][0]=32'd0; mul_B_in[0][1]=32'd0;
        mul_B_in[0][2]=32'd0; mul_B_in[0][3]=32'd0;
        mul_B_in[1][0]=32'd0; mul_B_in[1][1]=32'd0;
        mul_B_in[1][2]=32'd0; mul_B_in[1][3]=32'd0;
        mul_B_in[2][0]=32'd0; mul_B_in[2][1]=32'd0;
        mul_B_in[2][2]=32'd0; mul_B_in[2][3]=32'd0;
        mul_B_in[3][0]=32'd0; mul_B_in[3][1]=32'd0;
        mul_B_in[3][2]=32'd0; mul_B_in[3][3]=32'd0;
    end
end
//===================================

//step 3-3 
//when (EVAL_4X4_cnt, EVAL_16X16_cnt==5)
reg [2:0] floor_QP_div6;
always @(*) begin
    case (QP_q)
        0, 1, 2, 3, 4, 5:       floor_QP_div6 = 3'd0;
        6, 7, 8, 9, 10, 11:     floor_QP_div6 = 3'd1;
        12, 13, 14, 15, 16, 17: floor_QP_div6 = 3'd2;
        18, 19, 20, 21, 22, 23: floor_QP_div6 = 3'd3;
        24, 25, 26, 27, 28, 29: floor_QP_div6 = 3'd4;
        30, 31:                 floor_QP_div6 = 3'd0;
        default:                floor_QP_div6 = 3'd0; 
    endcase
end

//reg signed [31:0] two_pow_floor_QP_div6;
always@(*)begin
    case (floor_QP_div6)
        0: two_pow_floor_QP_div6=32'd1;
        1: two_pow_floor_QP_div6=32'd2;
        2: two_pow_floor_QP_div6=32'd4;
        3: two_pow_floor_QP_div6=32'd8;
        4: two_pow_floor_QP_div6=32'd16;
        default: two_pow_floor_QP_div6=32'd0;
    endcase
end
//==============================


//Part 3 Seq Logic 
reg DC_predict_done, SAD_done; 
reg [2:0] out_row,out_col;

//out_row、out_col、out_cnt、out_valid、out_value、EVAL_all_done
//EVAL_rec_4X4_cnt、EVAL_rec_16X16_cnt、EVAL_rec_4X4_done、EVAL_rec_16X16_done
//big_block_cnt
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===OUT===
        out_row<=3'd0; out_col<=3'd0; out_cnt<=5'd0; 
        out_valid<=1'b0; out_value<=32'd0; EVAL_all_done<=1'b0;
        //===EVAL_rec_4X4, EVAL_16X16===
        EVAL_rec_4X4_cnt<=4'd0; EVAL_rec_16X16_cnt<=4'd0;
        EVAL_rec_4X4_done<=1'b0;EVAL_rec_16X16_done<=1'b0;
        //===EVAL_4X4_next, EVAL_16X16_next===
        big_block_cnt<=3'd0;    //reset when CLEAR_big or CLEAR_small
    end
    else if(cur_state==OUT_4X4)begin
        out_cnt<=out_cnt+1;
        //32X32 all done, EVAL_all_done
        if(out_cnt==15&&small_lf_up_row==28&&small_lf_up_col==28) EVAL_all_done<=1'b1;
        //OUTPUT cur_4X4
        if(out_cnt<=15)begin
            out_valid<=1'b1; out_value<=cur_4X4[out_row][out_col];
            if(out_col==3)begin 
                out_row<=out_row+1; out_col<=3'd0;
            end
            else begin 
                out_row<=out_row;   out_col<=out_col+3'd1;
            end
        end
        else begin
            out_valid<=1'b0; out_value<=32'd0;
        end
    end
    else if(cur_state==EVAL_rec_4X4)begin
        EVAL_rec_4X4_cnt<=EVAL_rec_4X4_cnt+1;
        //step 3 REC
        if(EVAL_rec_4X4_cnt==5)begin
            EVAL_rec_4X4_done<=1'b1;
        end
    end
    else if(cur_state==EVAL_4X4_next)begin
        //step 1
        //===OUT===
        out_row<=3'd0; out_col<=3'd0; out_cnt<=5'd0; 
        out_valid<=1'b0; out_value<=32'd0;
        //===EVAL_rec_4X4, EVAL_16X16===
        EVAL_rec_4X4_cnt<=4'd0; EVAL_rec_16X16_cnt<=4'd0;
        EVAL_rec_4X4_done<=1'b0;EVAL_rec_16X16_done<=1'b0;

        //step 2
        //case 0
        if(small_lf_up_row==12&&small_lf_up_col==12)begin
            big_block_cnt<=big_block_cnt+1;                //case circle
        end
        else if(small_lf_up_row==12&&small_lf_up_col==28)begin
            big_block_cnt<=big_block_cnt+1;                //case circle 
        end
        else if(small_lf_up_row==28&&small_lf_up_col==12)begin
            big_block_cnt<=big_block_cnt+1;                //case circle
        end
        //case 1 go EVAL_intra_4X4
    end
    else if(cur_state==EVAL_16X16)begin
        EVAL_16X16_cnt<=EVAL_16X16_cnt+1;
    end
    else if(cur_state==OUT_16X16)begin
        out_cnt<=out_cnt+1;
        if(out_cnt==15&&small_lf_up_row==28&&small_lf_up_col==28) EVAL_all_done<=1'b1; 

        if(out_cnt<=15)begin
            out_valid<=1'b1; out_value<=cur_4X4[out_row][out_col];
            if(out_col==3)begin 
                out_row<=out_row+1; out_col<=3'd0;
            end
            else begin 
                out_row<=out_row;   out_col<=out_col+3'd1;
            end
        end
        else begin
            out_valid<=1'b0; out_value<=32'd0;
        end
    end
    else if(cur_state==EVAL_rec_16X16)begin
        EVAL_rec_16X16_cnt<=EVAL_rec_16X16_cnt+1;
        //step 3 REC
        if(EVAL_rec_16X16_cnt==5)begin
            EVAL_rec_16X16_done<=1'b1;
        end
    end
    else if(cur_state==EVAL_16X16_next)begin
        //step 1
        //===OUT===
        out_row<=3'd0; out_col<=3'd0; out_cnt<=5'd0; 
        out_valid<=1'b0; out_value<=32'd0;
        //===EVAL_rec_4X4, EVAL_16X16===
        EVAL_rec_4X4_cnt<=4'd0; EVAL_rec_16X16_cnt<=4'd0;
        EVAL_rec_4X4_done<=1'b0;EVAL_rec_16X16_done<=1'b0;
        //step 2
        //case 0
        if(small_lf_up_row==12&&small_lf_up_col==12)begin 
            big_block_cnt<=big_block_cnt+1;             //case circle
        end
        else if(small_lf_up_row==12&&small_lf_up_col==28)begin
            big_block_cnt<=big_block_cnt+1;             //case circle
        end
        else if(small_lf_up_row==28&&small_lf_up_col==12)begin
            big_block_cnt<=big_block_cnt+1;             //case circle
        end
        //case 1
    end
    else if(cur_state==CLEAR_small||cur_state==CLEAR_big)begin
        //===OUT===
        out_row<=3'd0; out_col<=3'd0; out_cnt<=5'd0; 
        out_valid<=1'b0; out_value<=32'd0; EVAL_all_done<=1'b0;
        //===EVAL_rec_4X4, EVAL_16X16===
        EVAL_rec_4X4_cnt<=4'd0; EVAL_rec_16X16_cnt<=4'd0;
        EVAL_rec_4X4_done<=1'b0;EVAL_rec_16X16_done<=1'b0;
        //===EVAL_4X4_next, EVAL_16X16_next===
        big_block_cnt<=3'd0;    
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===EVAL_4X4 & EVAL_16X16===
        W_sign_bit[0][0]<=1'b0; W_sign_bit[0][1]<=1'b0; W_sign_bit[0][2]<=1'b0; W_sign_bit[0][3]<=1'b0;
        W_sign_bit[1][0]<=1'b0; W_sign_bit[1][1]<=1'b0; W_sign_bit[1][2]<=1'b0; W_sign_bit[1][3]<=1'b0;
        W_sign_bit[2][0]<=1'b0; W_sign_bit[2][1]<=1'b0; W_sign_bit[2][2]<=1'b0; W_sign_bit[2][3]<=1'b0;
        W_sign_bit[3][0]<=1'b0; W_sign_bit[3][1]<=1'b0; W_sign_bit[3][2]<=1'b0; W_sign_bit[3][3]<=1'b0;
        //reset cur_4X4
        cur_4X4[0][0]<=32'd0; cur_4X4[0][1]<=32'd0; cur_4X4[0][2]<=32'd0; cur_4X4[0][3]<=32'd0;
        cur_4X4[1][0]<=32'd0; cur_4X4[1][1]<=32'd0; cur_4X4[1][2]<=32'd0; cur_4X4[1][3]<=32'd0;
        cur_4X4[2][0]<=32'd0; cur_4X4[2][1]<=32'd0; cur_4X4[2][2]<=32'd0; cur_4X4[2][3]<=32'd0;
        cur_4X4[3][0]<=32'd0; cur_4X4[3][1]<=32'd0; cur_4X4[3][2]<=32'd0; cur_4X4[3][3]<=32'd0;
    end
    else if(cur_state==EVAL_4X4)begin
        //reg [31:0] cur_4X4 [0:4][0:4]
        //step 1 residual
        if(EVAL_4X4_cnt==0)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=$signed({16'b0,img_reg[small_lf_up_row+i][small_lf_up_col+j]})-$signed({16'b0,cur_4X4_predict[i][j]});
                end
            end
        end
        //step 2-1 int transform
        else if(EVAL_4X4_cnt==1)begin
            cur_4X4[0][0]<=C_mul_mat_out[0][0];
            cur_4X4[0][1]<=C_mul_mat_out[0][1];
            cur_4X4[0][2]<=C_mul_mat_out[0][2];
            cur_4X4[0][3]<=C_mul_mat_out[0][3];
            cur_4X4[1][0]<=C_mul_mat_out[1][0];
            cur_4X4[1][1]<=C_mul_mat_out[1][1];
            cur_4X4[1][2]<=C_mul_mat_out[1][2];
            cur_4X4[1][3]<=C_mul_mat_out[1][3];
            cur_4X4[2][0]<=C_mul_mat_out[2][0];
            cur_4X4[2][1]<=C_mul_mat_out[2][1];
            cur_4X4[2][2]<=C_mul_mat_out[2][2];
            cur_4X4[2][3]<=C_mul_mat_out[2][3];
            cur_4X4[3][0]<=C_mul_mat_out[3][0];
            cur_4X4[3][1]<=C_mul_mat_out[3][1];
            cur_4X4[3][2]<=C_mul_mat_out[3][2];
            cur_4X4[3][3]<=C_mul_mat_out[3][3];
        end
        //step 2-2 int transform
        else if(EVAL_4X4_cnt==2)begin
            cur_4X4[0][0]<=mat_mul_C_out[0][0];
            cur_4X4[0][1]<=mat_mul_C_out[0][1];
            cur_4X4[0][2]<=mat_mul_C_out[0][2];
            cur_4X4[0][3]<=mat_mul_C_out[0][3];
            cur_4X4[1][0]<=mat_mul_C_out[1][0];
            cur_4X4[1][1]<=mat_mul_C_out[1][1];
            cur_4X4[1][2]<=mat_mul_C_out[1][2];
            cur_4X4[1][3]<=mat_mul_C_out[1][3];
            cur_4X4[2][0]<=mat_mul_C_out[2][0];
            cur_4X4[2][1]<=mat_mul_C_out[2][1];
            cur_4X4[2][2]<=mat_mul_C_out[2][2];
            cur_4X4[2][3]<=mat_mul_C_out[2][3];
            cur_4X4[3][0]<=mat_mul_C_out[3][0];
            cur_4X4[3][1]<=mat_mul_C_out[3][1];
            cur_4X4[3][2]<=mat_mul_C_out[3][2];
            cur_4X4[3][3]<=mat_mul_C_out[3][3];
        end
        //step 3-1 
        else if(EVAL_4X4_cnt==3)begin
            for(i=0;i<4;i=i+1)begin                             //keep signed_bit
                for(j=0;j<4;j=j+1) begin
                    if(cur_4X4[i][j]<0)W_sign_bit[i][j]<=1'b1;  //negative
                    else W_sign_bit[i][j]<=1'b0;                //positive
                end
            end
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1) begin                        //make to positive
                    if(cur_4X4[i][j]<0) cur_4X4[i][j]<=(-cur_4X4[i][j]);
                    else cur_4X4[i][j]<=cur_4X4[i][j];
                end
            end
        end
        //step 3-2 elementwise
        else if(EVAL_4X4_cnt==4)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 3-3 elementwise
        else if(EVAL_4X4_cnt==5)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1) begin 
                    if(W_sign_bit[i][j]==1) cur_4X4[i][j]<=-((cur_4X4[i][j]+MF_f)>>(15+floor_QP_div6));
                    else cur_4X4[i][j]<=(cur_4X4[i][j]+MF_f)>>(15+floor_QP_div6);
                end
            end
        end
    end
    else if(cur_state==EVAL_rec_4X4)begin
        //step 1-1 Dequantize cur_4X4*V
        if(EVAL_rec_4X4_cnt==0)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 1-2 Dequantize cur_4X4*2_pow_floor_QP_div_6;
        else if(EVAL_rec_4X4_cnt==1)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 2-1 inverse int transform
        else if(EVAL_rec_4X4_cnt==2)begin
            cur_4X4[0][0]<=C_mul_mat_out[0][0];
            cur_4X4[0][1]<=C_mul_mat_out[0][1];
            cur_4X4[0][2]<=C_mul_mat_out[0][2];
            cur_4X4[0][3]<=C_mul_mat_out[0][3];
            cur_4X4[1][0]<=C_mul_mat_out[1][0];
            cur_4X4[1][1]<=C_mul_mat_out[1][1];
            cur_4X4[1][2]<=C_mul_mat_out[1][2];
            cur_4X4[1][3]<=C_mul_mat_out[1][3];
            cur_4X4[2][0]<=C_mul_mat_out[2][0];
            cur_4X4[2][1]<=C_mul_mat_out[2][1];
            cur_4X4[2][2]<=C_mul_mat_out[2][2];
            cur_4X4[2][3]<=C_mul_mat_out[2][3];
            cur_4X4[3][0]<=C_mul_mat_out[3][0];
            cur_4X4[3][1]<=C_mul_mat_out[3][1];
            cur_4X4[3][2]<=C_mul_mat_out[3][2];
            cur_4X4[3][3]<=C_mul_mat_out[3][3];
        end
        //step 2-2 inverse int transform
        else if(EVAL_rec_4X4_cnt==3)begin
            cur_4X4[0][0]<=mat_mul_C_out[0][0];
            cur_4X4[0][1]<=mat_mul_C_out[0][1];
            cur_4X4[0][2]<=mat_mul_C_out[0][2];
            cur_4X4[0][3]<=mat_mul_C_out[0][3];
            cur_4X4[1][0]<=mat_mul_C_out[1][0];
            cur_4X4[1][1]<=mat_mul_C_out[1][1];
            cur_4X4[1][2]<=mat_mul_C_out[1][2];
            cur_4X4[1][3]<=mat_mul_C_out[1][3];
            cur_4X4[2][0]<=mat_mul_C_out[2][0];
            cur_4X4[2][1]<=mat_mul_C_out[2][1];
            cur_4X4[2][2]<=mat_mul_C_out[2][2];
            cur_4X4[2][3]<=mat_mul_C_out[2][3];
            cur_4X4[3][0]<=mat_mul_C_out[3][0];
            cur_4X4[3][1]<=mat_mul_C_out[3][1];
            cur_4X4[3][2]<=mat_mul_C_out[3][2];
            cur_4X4[3][3]<=mat_mul_C_out[3][3];
        end
        //step 2-3 X`=Y>>>6
        else if(EVAL_rec_4X4_cnt==4)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=cur_4X4[i][j]>>>6;   //signed shift
                end
            end
        end
        //step 3 REC
        else if(EVAL_rec_4X4_cnt==5)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=cur_4X4[i][j]+cur_4X4_predict[i][j];   
                end
            end
        end
    end
    else if(cur_state==EVAL_4X4_next)begin
        //step 1
        W_sign_bit[0][0]<=1'b0; W_sign_bit[0][1]<=1'b0; W_sign_bit[0][2]<=1'b0; W_sign_bit[0][3]<=1'b0;
        W_sign_bit[1][0]<=1'b0; W_sign_bit[1][1]<=1'b0; W_sign_bit[1][2]<=1'b0; W_sign_bit[1][3]<=1'b0;
        W_sign_bit[2][0]<=1'b0; W_sign_bit[2][1]<=1'b0; W_sign_bit[2][2]<=1'b0; W_sign_bit[2][3]<=1'b0;
        W_sign_bit[3][0]<=1'b0; W_sign_bit[3][1]<=1'b0; W_sign_bit[3][2]<=1'b0; W_sign_bit[3][3]<=1'b0;
        //reset cur_4X4
        cur_4X4[0][0]<=32'd0; cur_4X4[0][1]<=32'd0; cur_4X4[0][2]<=32'd0; cur_4X4[0][3]<=32'd0;
        cur_4X4[1][0]<=32'd0; cur_4X4[1][1]<=32'd0; cur_4X4[1][2]<=32'd0; cur_4X4[1][3]<=32'd0;
        cur_4X4[2][0]<=32'd0; cur_4X4[2][1]<=32'd0; cur_4X4[2][2]<=32'd0; cur_4X4[2][3]<=32'd0;
        cur_4X4[3][0]<=32'd0; cur_4X4[3][1]<=32'd0; cur_4X4[3][2]<=32'd0; cur_4X4[3][3]<=32'd0; 
    end
    else if(cur_state==EVAL_16X16)begin
        //reg [31:0] cur_4X4 [0:4][0:4]
        //step 1 residual
        if(EVAL_16X16_cnt==0)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=$signed({16'b0,img_reg[small_lf_up_row+i][small_lf_up_col+j]})-$signed({16'b0,cur_4X4_predict[i][j]});
                end
            end
        end
        //step 2-1 int transform
        else if(EVAL_16X16_cnt==1)begin
            cur_4X4[0][0]<=C_mul_mat_out[0][0];
            cur_4X4[0][1]<=C_mul_mat_out[0][1];
            cur_4X4[0][2]<=C_mul_mat_out[0][2];
            cur_4X4[0][3]<=C_mul_mat_out[0][3];
            cur_4X4[1][0]<=C_mul_mat_out[1][0];
            cur_4X4[1][1]<=C_mul_mat_out[1][1];
            cur_4X4[1][2]<=C_mul_mat_out[1][2];
            cur_4X4[1][3]<=C_mul_mat_out[1][3];
            cur_4X4[2][0]<=C_mul_mat_out[2][0];
            cur_4X4[2][1]<=C_mul_mat_out[2][1];
            cur_4X4[2][2]<=C_mul_mat_out[2][2];
            cur_4X4[2][3]<=C_mul_mat_out[2][3];
            cur_4X4[3][0]<=C_mul_mat_out[3][0];
            cur_4X4[3][1]<=C_mul_mat_out[3][1];
            cur_4X4[3][2]<=C_mul_mat_out[3][2];
            cur_4X4[3][3]<=C_mul_mat_out[3][3];
        end
        //step 2-2 int transform
        else if(EVAL_16X16_cnt==2)begin
            cur_4X4[0][0]<=mat_mul_C_out[0][0];
            cur_4X4[0][1]<=mat_mul_C_out[0][1];
            cur_4X4[0][2]<=mat_mul_C_out[0][2];
            cur_4X4[0][3]<=mat_mul_C_out[0][3];
            cur_4X4[1][0]<=mat_mul_C_out[1][0];
            cur_4X4[1][1]<=mat_mul_C_out[1][1];
            cur_4X4[1][2]<=mat_mul_C_out[1][2];
            cur_4X4[1][3]<=mat_mul_C_out[1][3];
            cur_4X4[2][0]<=mat_mul_C_out[2][0];
            cur_4X4[2][1]<=mat_mul_C_out[2][1];
            cur_4X4[2][2]<=mat_mul_C_out[2][2];
            cur_4X4[2][3]<=mat_mul_C_out[2][3];
            cur_4X4[3][0]<=mat_mul_C_out[3][0];
            cur_4X4[3][1]<=mat_mul_C_out[3][1];
            cur_4X4[3][2]<=mat_mul_C_out[3][2];
            cur_4X4[3][3]<=mat_mul_C_out[3][3];
        end
        //step 3-1
        else if(EVAL_16X16_cnt==3)begin
            for(i=0;i<4;i=i+1)begin                             //keep signed_bit
                for(j=0;j<4;j=j+1) begin
                    if(cur_4X4[i][j]<0)W_sign_bit[i][j]<=1'b1;  //negtive
                    else W_sign_bit[i][j]<=1'b0;                //positive
                end
            end
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1) begin                        //make to positive
                    if(cur_4X4[i][j]<0) cur_4X4[i][j]<=(-cur_4X4[i][j]);
                    else cur_4X4[i][j]<=cur_4X4[i][j];
                end
            end
        end
        //step 3-2 
        else if(EVAL_16X16_cnt==4)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 3-3
        else if(EVAL_16X16_cnt==5)begin   
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1) begin 
                    if(W_sign_bit[i][j]==1) cur_4X4[i][j]<=-((cur_4X4[i][j]+MF_f)>>(15+floor_QP_div6));
                    else cur_4X4[i][j]<=(cur_4X4[i][j]+MF_f)>>(15+floor_QP_div6);
                end
            end
        end
    end
    else if(cur_state==EVAL_rec_16X16)begin
        //step 1-1 Dequantize cur_4X4*V
        if(EVAL_rec_16X16_cnt==0)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 1-2 Dequantize cur_4X4*2_pow_floor_QP_div_6;
        else if(EVAL_rec_16X16_cnt==1)begin
            cur_4X4[0][0]<=mul_16_out[0][0];
            cur_4X4[0][1]<=mul_16_out[0][1];
            cur_4X4[0][2]<=mul_16_out[0][2];
            cur_4X4[0][3]<=mul_16_out[0][3];
            cur_4X4[1][0]<=mul_16_out[1][0];
            cur_4X4[1][1]<=mul_16_out[1][1];
            cur_4X4[1][2]<=mul_16_out[1][2];
            cur_4X4[1][3]<=mul_16_out[1][3];
            cur_4X4[2][0]<=mul_16_out[2][0];
            cur_4X4[2][1]<=mul_16_out[2][1];
            cur_4X4[2][2]<=mul_16_out[2][2];
            cur_4X4[2][3]<=mul_16_out[2][3];
            cur_4X4[3][0]<=mul_16_out[3][0];
            cur_4X4[3][1]<=mul_16_out[3][1];
            cur_4X4[3][2]<=mul_16_out[3][2];
            cur_4X4[3][3]<=mul_16_out[3][3];
        end
        //step 2-1 inverse int transform
        else if(EVAL_rec_16X16_cnt==2)begin
            cur_4X4[0][0]<=C_mul_mat_out[0][0];
            cur_4X4[0][1]<=C_mul_mat_out[0][1];
            cur_4X4[0][2]<=C_mul_mat_out[0][2];
            cur_4X4[0][3]<=C_mul_mat_out[0][3];
            cur_4X4[1][0]<=C_mul_mat_out[1][0];
            cur_4X4[1][1]<=C_mul_mat_out[1][1];
            cur_4X4[1][2]<=C_mul_mat_out[1][2];
            cur_4X4[1][3]<=C_mul_mat_out[1][3];
            cur_4X4[2][0]<=C_mul_mat_out[2][0];
            cur_4X4[2][1]<=C_mul_mat_out[2][1];
            cur_4X4[2][2]<=C_mul_mat_out[2][2];
            cur_4X4[2][3]<=C_mul_mat_out[2][3];
            cur_4X4[3][0]<=C_mul_mat_out[3][0];
            cur_4X4[3][1]<=C_mul_mat_out[3][1];
            cur_4X4[3][2]<=C_mul_mat_out[3][2];
            cur_4X4[3][3]<=C_mul_mat_out[3][3];

        end
        //step 2-2 inverse int transform
        else if(EVAL_rec_16X16_cnt==3)begin
            cur_4X4[0][0]<=mat_mul_C_out[0][0];
            cur_4X4[0][1]<=mat_mul_C_out[0][1];
            cur_4X4[0][2]<=mat_mul_C_out[0][2];
            cur_4X4[0][3]<=mat_mul_C_out[0][3];
            cur_4X4[1][0]<=mat_mul_C_out[1][0];
            cur_4X4[1][1]<=mat_mul_C_out[1][1];
            cur_4X4[1][2]<=mat_mul_C_out[1][2];
            cur_4X4[1][3]<=mat_mul_C_out[1][3];
            cur_4X4[2][0]<=mat_mul_C_out[2][0];
            cur_4X4[2][1]<=mat_mul_C_out[2][1];
            cur_4X4[2][2]<=mat_mul_C_out[2][2];
            cur_4X4[2][3]<=mat_mul_C_out[2][3];
            cur_4X4[3][0]<=mat_mul_C_out[3][0];
            cur_4X4[3][1]<=mat_mul_C_out[3][1];
            cur_4X4[3][2]<=mat_mul_C_out[3][2];
            cur_4X4[3][3]<=mat_mul_C_out[3][3];
        end
        //step 2-3 X`=Y>>>6
        else if(EVAL_rec_16X16_cnt==4)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=cur_4X4[i][j]>>>6;   //signed shift
                end
            end
        end
        //step 3 REC
        else if(EVAL_rec_16X16_cnt==5)begin
            for(i=0;i<4;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    cur_4X4[i][j]<=cur_4X4[i][j]+cur_4X4_predict[i][j];   
                end
            end
        end
    end
    else if(cur_state==EVAL_16X16_next)begin
        //step 1
        W_sign_bit[0][0]<=1'b0; W_sign_bit[0][1]<=1'b0; W_sign_bit[0][2]<=1'b0; W_sign_bit[0][3]<=1'b0;
        W_sign_bit[1][0]<=1'b0; W_sign_bit[1][1]<=1'b0; W_sign_bit[1][2]<=1'b0; W_sign_bit[1][3]<=1'b0;
        W_sign_bit[2][0]<=1'b0; W_sign_bit[2][1]<=1'b0; W_sign_bit[2][2]<=1'b0; W_sign_bit[2][3]<=1'b0;
        W_sign_bit[3][0]<=1'b0; W_sign_bit[3][1]<=1'b0; W_sign_bit[3][2]<=1'b0; W_sign_bit[3][3]<=1'b0;
        //reset cur_4X4
        cur_4X4[0][0]<=32'd0; cur_4X4[0][1]<=32'd0; cur_4X4[0][2]<=32'd0; cur_4X4[0][3]<=32'd0;
        cur_4X4[1][0]<=32'd0; cur_4X4[1][1]<=32'd0; cur_4X4[1][2]<=32'd0; cur_4X4[1][3]<=32'd0;
        cur_4X4[2][0]<=32'd0; cur_4X4[2][1]<=32'd0; cur_4X4[2][2]<=32'd0; cur_4X4[2][3]<=32'd0;
        cur_4X4[3][0]<=32'd0; cur_4X4[3][1]<=32'd0; cur_4X4[3][2]<=32'd0; cur_4X4[3][3]<=32'd0;
    end
    else if(cur_state==CLEAR_small||cur_state==CLEAR_big)begin
        W_sign_bit[0][0]<=1'b0; W_sign_bit[0][1]<=1'b0; W_sign_bit[0][2]<=1'b0; W_sign_bit[0][3]<=1'b0;
        W_sign_bit[1][0]<=1'b0; W_sign_bit[1][1]<=1'b0; W_sign_bit[1][2]<=1'b0; W_sign_bit[1][3]<=1'b0;
        W_sign_bit[2][0]<=1'b0; W_sign_bit[2][1]<=1'b0; W_sign_bit[2][2]<=1'b0; W_sign_bit[2][3]<=1'b0;
        W_sign_bit[3][0]<=1'b0; W_sign_bit[3][1]<=1'b0; W_sign_bit[3][2]<=1'b0; W_sign_bit[3][3]<=1'b0;
        //reset cur_4X4
        cur_4X4[0][0]<=32'd0; cur_4X4[0][1]<=32'd0; cur_4X4[0][2]<=32'd0; cur_4X4[0][3]<=32'd0;
        cur_4X4[1][0]<=32'd0; cur_4X4[1][1]<=32'd0; cur_4X4[1][2]<=32'd0; cur_4X4[1][3]<=32'd0;
        cur_4X4[2][0]<=32'd0; cur_4X4[2][1]<=32'd0; cur_4X4[2][2]<=32'd0; cur_4X4[2][3]<=32'd0;
        cur_4X4[3][0]<=32'd0; cur_4X4[3][1]<=32'd0; cur_4X4[3][2]<=32'd0; cur_4X4[3][3]<=32'd0;  
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===for DC===
        lf_up_row<=5'd0; lf_up_col<=5'd0; 
        DC_cnt<=3'd0; 
        DC_predict_done<=1'b0; DC_predict<=15'd0;
        //==for SAD===
        SAD_done<=1'b0; SAD_cnt<=8'd0; 
        SAD_DC<=18'd0; SAD_V<=18'd0; SAD_H<=18'd0; 
        cur_SAD_row_offset<=5'd0; cur_SAD_col_offset<=5'd0;
        EVAL_intra_4X4_done<=1'b0; EVAL_intra_16X16_done<=1'b0;
        intra_mode<=2'd0;
        //===EVAL_4X4 & EVAL_16X16===
        small_lf_up_row<=5'd0; small_lf_up_col<=5'd0;
        EVAL_4X4_cnt<=4'd0; EVAL_16X16_cnt<=4'd0;
        EVAL_4X4_done<=1'b0; EVAL_16X16_done<=1'b0;
    end
    else if(cur_state==EVAL_intra_4X4)begin
        //case 0 DC_predict not done  (1 cycle)
        if(DC_predict_done==0)begin
            if(DC_case==1) DC_predict<=(DC_predict+add8_out)>>3;
            else if(DC_case==0) DC_predict<=(DC_predict+add8_out)>>2;
            else if(DC_case==7) DC_predict<=10'd128;
            else DC_predict<=10'd128;
            DC_predict_done<=1'b1;      //4*4 only 1 cycle
        end
        //case 1
        else if(DC_predict_done==1'b1 && SAD_done==1'b0)begin
            SAD_cnt<=SAD_cnt+1;
            //update cur_SAD_row_offset, cur_SAD_col_offset (4X4)
            if(cur_SAD_col_offset==3)begin
                cur_SAD_col_offset<=0; cur_SAD_row_offset<=cur_SAD_row_offset+1;
            end
            else begin
                cur_SAD_col_offset<=cur_SAD_col_offset+1; cur_SAD_row_offset<=cur_SAD_row_offset;
            end

            //DC SAD 
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_DC_predict)
                SAD_DC<=SAD_DC+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_DC_predict);
            else SAD_DC<=SAD_DC+(cur_DC_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            //H SAD 
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_H_predict)
                SAD_H<=SAD_H+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_H_predict);
            else SAD_H<=SAD_H+(cur_H_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            //V SAD 
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_V_predict)
                SAD_V<=SAD_V+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_V_predict);
            else SAD_V<=SAD_V+(cur_V_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);

            if(SAD_cnt==15)SAD_done<=1'b1;
            else SAD_done<=SAD_done;
        end
        //case 2 
        else if(DC_predict_done==1'b1 && SAD_done==1'b1)begin
            intra_mode<=intra_mode_choice; EVAL_intra_4X4_done<=1'b1;
            small_lf_up_row<=lf_up_row; small_lf_up_col<=lf_up_col;
        end
    end
    else if(cur_state==EVAL_intra_16X16)begin
        //case 0 DC_predict not done
        if(DC_predict_done==0)begin
            DC_cnt<=DC_cnt+1; 
            if(DC_cnt>=3)begin  //4 step done
                DC_predict_done<=1'b1;
                if(DC_case==3) DC_predict<=(DC_predict+add8_out)>>5;
                else if(DC_case==2) DC_predict<=(DC_predict+add8_out)>>4;
                else if(DC_case==7) DC_predict<=10'd128;
                else DC_predict<=10'd128;
            end
            else begin          //not done
                DC_predict_done<=DC_predict_done;
                DC_predict<=DC_predict+add8_out;
            end
        end
        //case 1 accumulate DC H V SAD
        else if(DC_predict_done==1'b1 && SAD_done==1'b0)begin
            SAD_cnt<=SAD_cnt+1;

            //update cur_SAD_row_offset, cur_SAD_col_offset (16X16)
            if(cur_SAD_col_offset==15)begin
                cur_SAD_col_offset<=0; cur_SAD_row_offset<=cur_SAD_row_offset+1;
            end
            else begin
                cur_SAD_col_offset<=cur_SAD_col_offset+1; cur_SAD_row_offset<=cur_SAD_row_offset;
            end

            //DC SAD (cur_DC_predict use [cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_DC_predict)
                SAD_DC<=SAD_DC+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_DC_predict);
            else SAD_DC<=SAD_DC+(cur_DC_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            
            //H SAD (cur_H_predict use [cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_H_predict)
                SAD_H<=SAD_H+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_H_predict);
            else SAD_H<=SAD_H+(cur_H_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);
            
            //V SAD (cur_V_predict use [cur_SAD_row][cur_SAD_col])
            if(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]>cur_V_predict)
                SAD_V<=SAD_V+(img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]-cur_V_predict);
            else SAD_V<=SAD_V+(cur_V_predict-img_reg[lf_up_row+cur_SAD_row_offset][lf_up_col+cur_SAD_col_offset]);

            if(SAD_cnt==255)SAD_done<=1'b1;
            else SAD_done<=SAD_done;
        end
        //case 2 
        else if(DC_predict_done==1'b1 && SAD_done==1'b1)begin
            intra_mode<=intra_mode_choice; EVAL_intra_16X16_done<=1'b1;
            small_lf_up_row<=lf_up_row; small_lf_up_col<=lf_up_col;
        end
    end
    else if(cur_state==EVAL_4X4)begin
        EVAL_4X4_cnt<=EVAL_4X4_cnt+1;
        //step 3-3 elementwise
        if(EVAL_4X4_cnt==5)begin
            EVAL_4X4_done<=1'b1;    //done
        end
    end
    else if(cur_state==EVAL_4X4_next)begin
        //step 1
        //===for intra===
        DC_cnt<=3'd0; DC_predict_done<=1'b0; DC_predict<=15'd0;
        SAD_done<=1'b0; SAD_cnt<=8'd0; 
        SAD_DC<=18'd0; SAD_V<=18'd0; SAD_H<=18'd0; 
        cur_SAD_row_offset<=5'd0; cur_SAD_col_offset<=5'd0;
        EVAL_intra_4X4_done<=1'b0; EVAL_intra_16X16_done<=1'b0;
        intra_mode<=2'd0;
        //===EVAL_4X4, EVAL_16X16===
        EVAL_4X4_cnt<=4'd0; EVAL_16X16_cnt<=4'd0;
        EVAL_4X4_done<=1'b0; EVAL_16X16_done<=1'b0;

        //step 2
        //case 0
        if(small_lf_up_row==12&&small_lf_up_col==12)begin
            lf_up_row<=0;       lf_up_col<=16; 
            small_lf_up_row<=0; small_lf_up_col<=16;
        end
        else if(small_lf_up_row==12&&small_lf_up_col==28)begin
            lf_up_row<=16;      lf_up_col<=0;
            small_lf_up_row<=16;small_lf_up_col<=0;
        end
        else if(small_lf_up_row==28&&small_lf_up_col==12)begin
            lf_up_row<=16;      lf_up_col<=16;
            small_lf_up_row<=16;small_lf_up_col<=16;
        end
        //case 1 go EVAL_intra_4X4
        else begin
            if(lf_up_col==12)begin          //triangle (go_EVAL_intra_4X4)
                lf_up_row<=lf_up_row+4;         lf_up_col<=0; 
                small_lf_up_row<=lf_up_row+4;   small_lf_up_col<=0;
            end
            else if(lf_up_col==28)begin     //triangle (go_EVAL_intra_4X4)
                lf_up_row<=lf_up_row+4;         lf_up_col<=16; 
                small_lf_up_row<=lf_up_row+4;   small_lf_up_col<=16;
            end
            else begin                      //check    (go_EVAL_intra_4X4)
                lf_up_row<=lf_up_row;           lf_up_col<=lf_up_col+4; 
                small_lf_up_row<=lf_up_row;     small_lf_up_col<=lf_up_col+4; 
            end
        end
    end
    else if(cur_state==EVAL_16X16)begin
        EVAL_16X16_cnt<=EVAL_16X16_cnt+1;
        if(EVAL_16X16_cnt==5)begin
            EVAL_16X16_done<=1'b1;    
        end
    end
    else if(cur_state==EVAL_16X16_next)begin
        //step 1
        //===for intra===
        DC_cnt<=3'd0; DC_predict_done<=1'b0; 
        SAD_done<=1'b0; SAD_cnt<=8'd0; 
        SAD_DC<=18'd0; SAD_V<=18'd0; SAD_H<=18'd0; 
        cur_SAD_row_offset<=5'd0; cur_SAD_col_offset<=5'd0;
        EVAL_intra_4X4_done<=1'b0; EVAL_intra_16X16_done<=1'b0;
        //===EVAL_4X4, EVAL_16X16===
        EVAL_4X4_cnt<=4'd0; EVAL_16X16_cnt<=4'd0;
        EVAL_4X4_done<=1'b0; EVAL_16X16_done<=1'b0;

        //step 2
        //case 0
        if(small_lf_up_row==12&&small_lf_up_col==12)begin
            lf_up_row<=0;       lf_up_col<=16; 
            small_lf_up_row<=0; small_lf_up_col<=16; 
            DC_predict<=15'd0;  intra_mode<=2'd0;
        end
        else if(small_lf_up_row==12&&small_lf_up_col==28)begin
            lf_up_row<=16;      lf_up_col<=0;
            small_lf_up_row<=16;small_lf_up_col<=0; 
            DC_predict<=15'd0;  intra_mode<=2'd0;
        end
        else if(small_lf_up_row==28&&small_lf_up_col==12)begin
            lf_up_row<=16;      lf_up_col<=16;
            small_lf_up_row<=16;small_lf_up_col<=16; 
            DC_predict<=15'd0;  intra_mode<=2'd0;
        end
        //case 1
        else begin
            if(small_lf_up_col==12)begin            //triangle (go_EVAL_16X16)
                small_lf_up_row<=small_lf_up_row+4; small_lf_up_col<=0; 
            end
            else if(small_lf_up_col==28)begin       //triangle (go_EVAL_16X16)
                small_lf_up_row<=small_lf_up_row+4; small_lf_up_col<=16; 
            end
            else begin                              //check    (go_EVAL_16X16)
                small_lf_up_row<=small_lf_up_row; small_lf_up_col<=small_lf_up_col+4; 
            end
        end
    end
    else if(cur_state==CLEAR_small||cur_state==CLEAR_big)begin
        //===for DC===
        lf_up_row<=5'd0; lf_up_col<=5'd0; 
        DC_cnt<=3'd0; 
        DC_predict_done<=1'b0; DC_predict<=15'd0;
        //==for SAD===
        SAD_done<=1'b0; SAD_cnt<=8'd0; 
        SAD_DC<=18'd0; SAD_V<=18'd0; SAD_H<=18'd0; 
        cur_SAD_row_offset<=5'd0; cur_SAD_col_offset<=5'd0;
        EVAL_intra_4X4_done<=1'b0; EVAL_intra_16X16_done<=1'b0;
        intra_mode<=2'd0;
        //===EVAL_4X4 & EVAL_16X16===
        small_lf_up_row<=5'd0; small_lf_up_col<=5'd0;
        EVAL_4X4_cnt<=4'd0; EVAL_16X16_cnt<=4'd0;
        EVAL_4X4_done<=1'b0; EVAL_16X16_done<=1'b0;
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
    input  [7:0] in0,input  [7:0] in1,input  [7:0] in2,
    input  [7:0] in3,input  [7:0] in4,input  [7:0] in5,
    input  [7:0] in6,input  [7:0] in7,output [15:0] sum_out
);
    wire [8:0] sum_l1_0 = {1'b0, in0} + {1'b0, in1};
    wire [8:0] sum_l1_1 = {1'b0, in2} + {1'b0, in3};
    wire [8:0] sum_l1_2 = {1'b0, in4} + {1'b0, in5};
    wire [8:0] sum_l1_3 = {1'b0, in6} + {1'b0, in7};

    wire [10:0] sum_l2_0 = {2'b0, sum_l1_0} + {2'b0, sum_l1_1};
    wire [10:0] sum_l2_1 = {2'b0, sum_l1_2} + {2'b0, sum_l1_3};

    assign sum_out = {5'b0, sum_l2_0} + {5'b0, sum_l2_1};
endmodule

module C_mul_mat (
    input  signed [31:0] cur_4X4_0_0, input signed [31:0] cur_4X4_0_1, input signed [31:0] cur_4X4_0_2, input signed [31:0] cur_4X4_0_3,
    input  signed [31:0] cur_4X4_1_0, input signed [31:0] cur_4X4_1_1, input signed [31:0] cur_4X4_1_2, input signed [31:0] cur_4X4_1_3,
    input  signed [31:0] cur_4X4_2_0, input signed [31:0] cur_4X4_2_1, input signed [31:0] cur_4X4_2_2, input signed [31:0] cur_4X4_2_3,
    input  signed [31:0] cur_4X4_3_0, input signed [31:0] cur_4X4_3_1, input signed [31:0] cur_4X4_3_2, input signed [31:0] cur_4X4_3_3,
    output signed [31:0] result_0_0, output signed [31:0] result_0_1, output signed [31:0] result_0_2, output signed [31:0] result_0_3,
    output signed [31:0] result_1_0, output signed [31:0] result_1_1, output signed [31:0] result_1_2, output signed [31:0] result_1_3,
    output signed [31:0] result_2_0, output signed [31:0] result_2_1, output signed [31:0] result_2_2, output signed [31:0] result_2_3,
    output signed [31:0] result_3_0, output signed [31:0] result_3_1, output signed [31:0] result_3_2, output signed [31:0] result_3_3
);

    // Row 0 : [1 1 1 1]
    assign result_0_0 = cur_4X4_0_0 + cur_4X4_1_0 + cur_4X4_2_0 + cur_4X4_3_0;
    assign result_0_1 = cur_4X4_0_1 + cur_4X4_1_1 + cur_4X4_2_1 + cur_4X4_3_1;
    assign result_0_2 = cur_4X4_0_2 + cur_4X4_1_2 + cur_4X4_2_2 + cur_4X4_3_2;
    assign result_0_3 = cur_4X4_0_3 + cur_4X4_1_3 + cur_4X4_2_3 + cur_4X4_3_3;

    // Row 1 : [1 1 -1 -1]
    assign result_1_0 = cur_4X4_0_0 + cur_4X4_1_0 - cur_4X4_2_0 - cur_4X4_3_0;
    assign result_1_1 = cur_4X4_0_1 + cur_4X4_1_1 - cur_4X4_2_1 - cur_4X4_3_1;
    assign result_1_2 = cur_4X4_0_2 + cur_4X4_1_2 - cur_4X4_2_2 - cur_4X4_3_2;
    assign result_1_3 = cur_4X4_0_3 + cur_4X4_1_3 - cur_4X4_2_3 - cur_4X4_3_3;

    // Row 2 : [1 -1 -1 1]
    assign result_2_0 = cur_4X4_0_0 - cur_4X4_1_0 - cur_4X4_2_0 + cur_4X4_3_0;
    assign result_2_1 = cur_4X4_0_1 - cur_4X4_1_1 - cur_4X4_2_1 + cur_4X4_3_1;
    assign result_2_2 = cur_4X4_0_2 - cur_4X4_1_2 - cur_4X4_2_2 + cur_4X4_3_2;
    assign result_2_3 = cur_4X4_0_3 - cur_4X4_1_3 - cur_4X4_2_3 + cur_4X4_3_3;

    // Row 3 : [1 -1 1 -1]
    assign result_3_0 = cur_4X4_0_0 - cur_4X4_1_0 + cur_4X4_2_0 - cur_4X4_3_0;
    assign result_3_1 = cur_4X4_0_1 - cur_4X4_1_1 + cur_4X4_2_1 - cur_4X4_3_1;
    assign result_3_2 = cur_4X4_0_2 - cur_4X4_1_2 + cur_4X4_2_2 - cur_4X4_3_2;
    assign result_3_3 = cur_4X4_0_3 - cur_4X4_1_3 + cur_4X4_2_3 - cur_4X4_3_3;
endmodule

module mat_mul_C (
    // inputs: cur[row][col]
    input  signed [31:0] cur_4X4_0_0, input signed [31:0] cur_4X4_0_1, input signed [31:0] cur_4X4_0_2, input signed [31:0] cur_4X4_0_3,
    input  signed [31:0] cur_4X4_1_0, input signed [31:0] cur_4X4_1_1, input signed [31:0] cur_4X4_1_2, input signed [31:0] cur_4X4_1_3,
    input  signed [31:0] cur_4X4_2_0, input signed [31:0] cur_4X4_2_1, input signed [31:0] cur_4X4_2_2, input signed [31:0] cur_4X4_2_3,
    input  signed [31:0] cur_4X4_3_0, input signed [31:0] cur_4X4_3_1, input signed [31:0] cur_4X4_3_2, input signed [31:0] cur_4X4_3_3,
    // outputs: result[row][col]  = cur[row,:] * C[:,col]
    output signed [31:0] result_0_0, output signed [31:0] result_0_1, output signed [31:0] result_0_2, output signed [31:0] result_0_3,
    output signed [31:0] result_1_0, output signed [31:0] result_1_1, output signed [31:0] result_1_2, output signed [31:0] result_1_3,
    output signed [31:0] result_2_0, output signed [31:0] result_2_1, output signed [31:0] result_2_2, output signed [31:0] result_2_3,
    output signed [31:0] result_3_0, output signed [31:0] result_3_1, output signed [31:0] result_3_2, output signed [31:0] result_3_3
);
    // C matrix (columns):
    // col0 = [1,  1,  1,  1]
    // col1 = [1,  1, -1, -1]
    // col2 = [1, -1, -1,  1]
    // col3 = [1, -1,  1, -1]

    // result[row][0] = cur[row][0] + cur[row][1] + cur[row][2] + cur[row][3]
    assign result_0_0 = cur_4X4_0_0 + cur_4X4_0_1 + cur_4X4_0_2 + cur_4X4_0_3;
    assign result_1_0 = cur_4X4_1_0 + cur_4X4_1_1 + cur_4X4_1_2 + cur_4X4_1_3;
    assign result_2_0 = cur_4X4_2_0 + cur_4X4_2_1 + cur_4X4_2_2 + cur_4X4_2_3;
    assign result_3_0 = cur_4X4_3_0 + cur_4X4_3_1 + cur_4X4_3_2 + cur_4X4_3_3;

    // result[row][1] = cur[row][0] + cur[row][1] - cur[row][2] - cur[row][3]
    assign result_0_1 = cur_4X4_0_0 + cur_4X4_0_1 - cur_4X4_0_2 - cur_4X4_0_3;
    assign result_1_1 = cur_4X4_1_0 + cur_4X4_1_1 - cur_4X4_1_2 - cur_4X4_1_3;
    assign result_2_1 = cur_4X4_2_0 + cur_4X4_2_1 - cur_4X4_2_2 - cur_4X4_2_3;
    assign result_3_1 = cur_4X4_3_0 + cur_4X4_3_1 - cur_4X4_3_2 - cur_4X4_3_3;

    // result[row][2] = cur[row][0] - cur[row][1] - cur[row][2] + cur[row][3]
    assign result_0_2 = cur_4X4_0_0 - cur_4X4_0_1 - cur_4X4_0_2 + cur_4X4_0_3;
    assign result_1_2 = cur_4X4_1_0 - cur_4X4_1_1 - cur_4X4_1_2 + cur_4X4_1_3;
    assign result_2_2 = cur_4X4_2_0 - cur_4X4_2_1 - cur_4X4_2_2 + cur_4X4_2_3;
    assign result_3_2 = cur_4X4_3_0 - cur_4X4_3_1 - cur_4X4_3_2 + cur_4X4_3_3;

    // result[row][3] = cur[row][0] - cur[row][1] + cur[row][2] - cur[row][3]
    assign result_0_3 = cur_4X4_0_0 - cur_4X4_0_1 + cur_4X4_0_2 - cur_4X4_0_3;
    assign result_1_3 = cur_4X4_1_0 - cur_4X4_1_1 + cur_4X4_1_2 - cur_4X4_1_3;
    assign result_2_3 = cur_4X4_2_0 - cur_4X4_2_1 + cur_4X4_2_2 - cur_4X4_2_3;
    assign result_3_3 = cur_4X4_3_0 - cur_4X4_3_1 + cur_4X4_3_2 - cur_4X4_3_3;
endmodule

module elementwise_mul16(
    input  signed [31:0] A0,  input  signed [31:0] A1,
    input  signed [31:0] A2,  input  signed [31:0] A3,
    input  signed [31:0] A4,  input  signed [31:0] A5,
    input  signed [31:0] A6,  input  signed [31:0] A7,
    input  signed [31:0] A8,  input  signed [31:0] A9,
    input  signed [31:0] A10, input  signed [31:0] A11,
    input  signed [31:0] A12, input  signed [31:0] A13,
    input  signed [31:0] A14, input  signed [31:0] A15,
    input  signed [31:0] B0,  input  signed [31:0] B1,
    input  signed [31:0] B2,  input  signed [31:0] B3,
    input  signed [31:0] B4,  input  signed [31:0] B5,
    input  signed [31:0] B6,  input  signed [31:0] B7,
    input  signed [31:0] B8,  input  signed [31:0] B9,
    input  signed [31:0] B10, input  signed [31:0] B11,
    input  signed [31:0] B12, input  signed [31:0] B13,
    input  signed [31:0] B14, input  signed [31:0] B15,
    output signed [31:0] P0,  output signed [31:0] P1,
    output signed [31:0] P2,  output signed [31:0] P3,
    output signed [31:0] P4,  output signed [31:0] P5,
    output signed [31:0] P6,  output signed [31:0] P7,
    output signed [31:0] P8,  output signed [31:0] P9,
    output signed [31:0] P10, output signed [31:0] P11,
    output signed [31:0] P12, output signed [31:0] P13,
    output signed [31:0] P14, output signed [31:0] P15
);
    assign P0  = A0  * B0;
    assign P1  = A1  * B1;
    assign P2  = A2  * B2;
    assign P3  = A3  * B3;
    assign P4  = A4  * B4;
    assign P5  = A5  * B5;
    assign P6  = A6  * B6;
    assign P7  = A7  * B7;
    assign P8  = A8  * B8;
    assign P9  = A9  * B9;
    assign P10 = A10 * B10;
    assign P11 = A11 * B11;
    assign P12 = A12 * B12;
    assign P13 = A13 * B13;
    assign P14 = A14 * B14;
    assign P15 = A15 * B15;
endmodule