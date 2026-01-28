module CNN(
    // Input Port
    clk,rst_n,in_valid,Image,Kernel_ch1,Kernel_ch2,
    Weight_Bias,task_number,mode,capacity_cost,
    // Output Port
    out_valid,out
);

// IEEE floating point parameter (You can't modify these parameters)
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

input           clk, rst_n, in_valid;
input   [31:0]  Image;
input   [31:0]  Kernel_ch1;
input   [31:0]  Kernel_ch2;
input   [31:0]  Weight_Bias;
input           task_number;
input   [1:0]   mode;
input   [3:0]   capacity_cost;
output  reg         out_valid;
output  reg [31:0]  out;

//Part 1 FSM (& tag)
reg [3:0] cur_state,next_state;
parameter IDLE=4'd0, INPUT=4'd1,EVAL_task_0=4'd2;
parameter EVAL_task_1=4'd3, OUTPUT=4'd4, CLEAR=4'd5;
reg [7:0] input_cnt, conv_cnt;
reg [1:0] out_cnt;

reg task_number_q; 
reg [1:0] mode_q;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case (cur_state)
        IDLE: begin
            if(in_valid==1'b1)next_state=INPUT;
            else next_state=IDLE;
        end
        INPUT: begin
            if(input_cnt==8'd71&&task_number_q==0)next_state=EVAL_task_0;
            else if(input_cnt==8'd71&&task_number_q==1)next_state=EVAL_task_1;
            else next_state=INPUT;
        end
        EVAL_task_0: begin   
            if(conv_cnt==8'd135)next_state=OUTPUT;
            else next_state=EVAL_task_0;
        end
        EVAL_task_1: begin   
            if(conv_cnt==8'd135)next_state=OUTPUT;
            else next_state=EVAL_task_1;
        end
        OUTPUT: begin
            if(out_cnt>=2'd2)next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default next_state=IDLE;
    endcase
end

//Part 3 Seq Logic
reg [31:0] img_0 [0:63];
reg [31:0] img_1 [0:63];
reg [6:0] map_idx;  //for img input

reg [31:0] ker_ch1[0:8][0:1];
reg [31:0] ker_ch2[0:8][0:1];

reg [31:0] big_wgt[0:7][0:4];   //fc lay 1
reg [31:0] bias_1, bias_2;
reg [31:0] small_wgt[0:4][0:2]; //fc lay 2

//Part 3 Seq Logic conv_cnt
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        conv_cnt<=8'd0;
    end
    else if(cur_state==EVAL_task_0||cur_state==EVAL_task_1)begin
        conv_cnt<=conv_cnt+8'd1;
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(in_valid==1'b1&&input_cnt<=8)begin
        ker_ch1[input_cnt][0]<=Kernel_ch1; //ker_ch1_1
        ker_ch2[input_cnt][0]<=Kernel_ch2; //ker_ch2_1
    end
    else if(in_valid==1'b1&&input_cnt<=17)begin
        ker_ch1[input_cnt-9][1]<=Kernel_ch1;   //ker_ch1_2
        ker_ch2[input_cnt-9][1]<=Kernel_ch2;   //ker_ch2_2
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(in_valid==1'b1&&input_cnt<=7)begin
        big_wgt[input_cnt][0]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=15)begin
        big_wgt[input_cnt-8][1]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=23)begin
        big_wgt[input_cnt-16][2]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=31)begin
        big_wgt[input_cnt-24][3]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=39)begin
        big_wgt[input_cnt-32][4]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt==40)bias_1<=Weight_Bias;
    else if(in_valid==1'b1&&input_cnt<=45)begin
        small_wgt[input_cnt-41][0]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=50)begin
        small_wgt[input_cnt-46][1]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt<=55)begin
        small_wgt[input_cnt-51][2]<=Weight_Bias;
    end
    else if(in_valid==1'b1&&input_cnt==56)bias_2<=Weight_Bias;
end

//===input===
//Part 3 Seq Logic img
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        input_cnt<=8'd0; task_number_q<=2'd0; mode_q<=2'b00;
    end
    else if(in_valid==1'b1&&input_cnt<=8'd35)begin
        //case 0 img_0
        input_cnt<=input_cnt+1'd1;
        if(input_cnt==0)begin
            task_number_q<=task_number; mode_q<=mode;
        end
        else begin
            task_number_q<=task_number; mode_q<=mode;
        end

        img_0[map_idx]<=Image;
        if(mode_q==2'b00||mode_q==2'b01)begin   //Rep Pad 
            img_0[0]<=img_0[9];     img_0[1]<=img_0[9];
            img_0[2]<=img_0[10];    img_0[3]<=img_0[11];
            img_0[4]<=img_0[12];    img_0[5]<=img_0[13];
            img_0[6]<=img_0[14];    img_0[7]<=img_0[14];

            img_0[8]<=img_0[9];     img_0[15]<=img_0[14];
            img_0[16]<=img_0[17];   img_0[23]<=img_0[22];
            img_0[24]<=img_0[25];   img_0[31]<=img_0[30];
            img_0[32]<=img_0[33];   img_0[39]<=img_0[38];
            img_0[40]<=img_0[41];   img_0[47]<=img_0[46];
            img_0[48]<=img_0[49];   img_0[55]<=img_0[54];

            img_0[56]<=img_0[49];   img_0[57]<=img_0[49];
            img_0[58]<=img_0[50];   img_0[59]<=img_0[51];
            img_0[60]<=img_0[52];   img_0[61]<=img_0[53];
            img_0[62]<=img_0[54];   img_0[63]<=img_0[54];
        end
        else begin                              //Reflect Pad 
            img_0[0]<=img_0[18];    img_0[1]<=img_0[17];
            img_0[2]<=img_0[18];    img_0[3]<=img_0[19];
            img_0[4]<=img_0[20];    img_0[5]<=img_0[21];
            img_0[6]<=img_0[22];    img_0[7]<=img_0[21];

            img_0[8]<=img_0[10];    img_0[15]<=img_0[13];
            img_0[16]<=img_0[18];   img_0[23]<=img_0[21];
            img_0[24]<=img_0[26];   img_0[31]<=img_0[29];
            img_0[32]<=img_0[34];   img_0[39]<=img_0[37];
            img_0[40]<=img_0[42];   img_0[47]<=img_0[45];
            img_0[48]<=img_0[50];   img_0[55]<=img_0[53];

            img_0[56]<=img_0[42];   img_0[57]<=img_0[41];
            img_0[58]<=img_0[42];   img_0[59]<=img_0[43];
            img_0[60]<=img_0[44];   img_0[61]<=img_0[45];
            img_0[62]<=img_0[46];   img_0[63]<=img_0[44];
        end
    end
    else if(in_valid==1'b1&&input_cnt<=8'd71)begin
        //case 1 img_1 
        input_cnt<=input_cnt+1'd1;
        img_1[map_idx]<=Image;
        if(mode_q==2'b00||mode_q==2'b01)begin   //Rep Pad 
            //for Rep Pad (因為54會最後才進入，所以要後續補上)
            img_0[55]<=img_0[54]; img_0[62]<=img_0[54]; img_0[63]<=img_0[54];

            img_1[0]<=img_1[9];   img_1[1]<=img_1[9];
            img_1[2]<=img_1[10];  img_1[3]<=img_1[11];
            img_1[4]<=img_1[12];  img_1[5]<=img_1[13];
            img_1[6]<=img_1[14];  img_1[7]<=img_1[14];

            img_1[8]<=img_1[9];   img_1[15]<=img_1[14];
            img_1[16]<=img_1[17]; img_1[23]<=img_1[22];
            img_1[24]<=img_1[25]; img_1[31]<=img_1[30];
            img_1[32]<=img_1[33]; img_1[39]<=img_1[38];
            img_1[40]<=img_1[41]; img_1[47]<=img_1[46];
            img_1[48]<=img_1[49]; img_1[55]<=img_1[54];

            img_1[56]<=img_1[49]; img_1[57]<=img_1[49];
            img_1[58]<=img_1[50]; img_1[59]<=img_1[51];
            img_1[60]<=img_1[52]; img_1[61]<=img_1[53];
            img_1[62]<=img_1[54]; img_1[63]<=img_1[54];
        end
        else begin                              //Reflect Pad 
            img_1[0]<=img_1[18];  img_1[1]<=img_1[17];
            img_1[2]<=img_1[18];  img_1[3]<=img_1[19];
            img_1[4]<=img_1[20];  img_1[5]<=img_1[21];
            img_1[6]<=img_1[22];  img_1[7]<=img_1[21];

            img_1[8]<=img_1[10];  img_1[15]<=img_1[13];
            img_1[16]<=img_1[18]; img_1[23]<=img_1[21];
            img_1[24]<=img_1[26]; img_1[31]<=img_1[29];
            img_1[32]<=img_1[34]; img_1[39]<=img_1[37];
            img_1[40]<=img_1[42]; img_1[47]<=img_1[45];
            img_1[48]<=img_1[50]; img_1[55]<=img_1[53];

            img_1[56]<=img_1[42]; img_1[57]<=img_1[41];
            img_1[58]<=img_1[42]; img_1[59]<=img_1[43];
            img_1[60]<=img_1[44]; img_1[61]<=img_1[45];
            img_1[62]<=img_1[46]; img_1[63]<=img_1[45];
        end
    end
    else begin
        //for Rep Pad (因為54會最後才進入，所以要後續補上)
        if(mode_q==2'b00||mode_q==2'b01)begin
            img_1[55]<=img_1[54]; img_1[62]<=img_1[54]; img_1[63]<=img_1[54];
        end
    end
end

//Part 2 Comb Logic (for Input)
//輸入2個img
always @(*) begin
    case (input_cnt)
        0,  36: map_idx = 7'd9;
        1,  37: map_idx = 7'd10;
        2,  38: map_idx = 7'd11;
        3,  39: map_idx = 7'd12;
        4,  40: map_idx = 7'd13;
        5,  41: map_idx = 7'd14;

        6,  42: map_idx = 7'd17;
        7,  43: map_idx = 7'd18;
        8,  44: map_idx = 7'd19;
        9,  45: map_idx = 7'd20;
        10, 46: map_idx = 7'd21;
        11, 47: map_idx = 7'd22;

        12, 48: map_idx = 7'd25;
        13, 49: map_idx = 7'd26;
        14, 50: map_idx = 7'd27;
        15, 51: map_idx = 7'd28;
        16, 52: map_idx = 7'd29;
        17, 53: map_idx = 7'd30;

        18, 54: map_idx = 7'd33;
        19, 55: map_idx = 7'd34;
        20, 56: map_idx = 7'd35;
        21, 57: map_idx = 7'd36;
        22, 58: map_idx = 7'd37;
        23, 59: map_idx = 7'd38;

        24, 60: map_idx = 7'd41;
        25, 61: map_idx = 7'd42;
        26, 62: map_idx = 7'd43;
        27, 63: map_idx = 7'd44;
        28, 64: map_idx = 7'd45;
        29, 65: map_idx = 7'd46;

        30, 66: map_idx = 7'd49;
        31, 67: map_idx = 7'd50;
        32, 68: map_idx = 7'd51;
        33, 69: map_idx = 7'd52;
        34, 70: map_idx = 7'd53;
        35, 71: map_idx = 7'd54;
        default: map_idx = 7'd8;
    endcase
end
//==========

//Part 2 Comb Logic
reg [31:0] ch1_mult_in_a [0:8];
reg [31:0] ch1_mult_in_b [0:8];
wire [31:0] ch1_mult_out [0:8];

//===18 mult===
DW_fp_mult_inst conv_ch1_0(.inst_a(ch1_mult_in_a[0]),.inst_b(ch1_mult_in_b[0]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[0]),.status_inst());
DW_fp_mult_inst conv_ch1_1(.inst_a(ch1_mult_in_a[1]),.inst_b(ch1_mult_in_b[1]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[1]),.status_inst());
DW_fp_mult_inst conv_ch1_2(.inst_a(ch1_mult_in_a[2]),.inst_b(ch1_mult_in_b[2]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[2]),.status_inst());
DW_fp_mult_inst conv_ch1_3(.inst_a(ch1_mult_in_a[3]),.inst_b(ch1_mult_in_b[3]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[3]),.status_inst());
DW_fp_mult_inst conv_ch1_4(.inst_a(ch1_mult_in_a[4]),.inst_b(ch1_mult_in_b[4]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[4]),.status_inst());
DW_fp_mult_inst conv_ch1_5(.inst_a(ch1_mult_in_a[5]),.inst_b(ch1_mult_in_b[5]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[5]),.status_inst());
DW_fp_mult_inst conv_ch1_6(.inst_a(ch1_mult_in_a[6]),.inst_b(ch1_mult_in_b[6]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[6]),.status_inst());
DW_fp_mult_inst conv_ch1_7(.inst_a(ch1_mult_in_a[7]),.inst_b(ch1_mult_in_b[7]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[7]),.status_inst());
DW_fp_mult_inst conv_ch1_8(.inst_a(ch1_mult_in_a[8]),.inst_b(ch1_mult_in_b[8]),.inst_rnd(3'b0),.z_inst(ch1_mult_out[8]),.status_inst());

//Part 2 Comb Logic
reg [31:0] ch2_mult_in_a [0:8];
reg [31:0] ch2_mult_in_b [0:8];
wire [31:0] ch2_mult_out [0:8];

//===18 mult===
DW_fp_mult_inst conv_ch2_0(.inst_a(ch2_mult_in_a[0]),.inst_b(ch2_mult_in_b[0]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[0]),.status_inst());
DW_fp_mult_inst conv_ch2_1(.inst_a(ch2_mult_in_a[1]),.inst_b(ch2_mult_in_b[1]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[1]),.status_inst());
DW_fp_mult_inst conv_ch2_2(.inst_a(ch2_mult_in_a[2]),.inst_b(ch2_mult_in_b[2]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[2]),.status_inst());

DW_fp_mult_inst conv_ch2_3(.inst_a(ch2_mult_in_a[3]),.inst_b(ch2_mult_in_b[3]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[3]),.status_inst());
DW_fp_mult_inst conv_ch2_4(.inst_a(ch2_mult_in_a[4]),.inst_b(ch2_mult_in_b[4]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[4]),.status_inst());
DW_fp_mult_inst conv_ch2_5(.inst_a(ch2_mult_in_a[5]),.inst_b(ch2_mult_in_b[5]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[5]),.status_inst());

DW_fp_mult_inst conv_ch2_6(.inst_a(ch2_mult_in_a[6]),.inst_b(ch2_mult_in_b[6]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[6]),.status_inst());
DW_fp_mult_inst conv_ch2_7(.inst_a(ch2_mult_in_a[7]),.inst_b(ch2_mult_in_b[7]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[7]),.status_inst());
DW_fp_mult_inst conv_ch2_8(.inst_a(ch2_mult_in_a[8]),.inst_b(ch2_mult_in_b[8]),.inst_rnd(3'b0),.z_inst(ch2_mult_out[8]),.status_inst());
//==========

//===sum3===
reg [31:0] sum3_a_in [0:7];
reg [31:0] sum3_b_in [0:7];
reg [31:0] sum3_c_in [0:7];
wire [31:0] sum3_out [0:7];

//===sum for ch1===
DW_fp_sum3_inst step1_sum3_0(.inst_a(sum3_a_in[0]),.inst_b(sum3_b_in[0]),.inst_c(sum3_c_in[0]),.inst_rnd(3'b0),.z_inst(sum3_out[0]),.status_inst());
DW_fp_sum3_inst step1_sum3_1(.inst_a(sum3_a_in[1]),.inst_b(sum3_b_in[1]),.inst_c(sum3_c_in[1]),.inst_rnd(3'b0),.z_inst(sum3_out[1]),.status_inst());
DW_fp_sum3_inst step1_sum3_2(.inst_a(sum3_a_in[2]),.inst_b(sum3_b_in[2]),.inst_c(sum3_c_in[2]),.inst_rnd(3'b0),.z_inst(sum3_out[2]),.status_inst());

DW_fp_sum3_inst step1_sum3_3(.inst_a(sum3_a_in[3]),.inst_b(sum3_b_in[3]),.inst_c(sum3_c_in[3]),.inst_rnd(3'b0),.z_inst(sum3_out[3]),.status_inst());

//===sum for ch2===
DW_fp_sum3_inst step1_sum3_4(.inst_a(sum3_a_in[4]),.inst_b(sum3_b_in[4]),.inst_c(sum3_c_in[4]),.inst_rnd(3'b0),.z_inst(sum3_out[4]),.status_inst());
DW_fp_sum3_inst step1_sum3_5(.inst_a(sum3_a_in[5]),.inst_b(sum3_b_in[5]),.inst_c(sum3_c_in[5]),.inst_rnd(3'b0),.z_inst(sum3_out[5]),.status_inst());
DW_fp_sum3_inst step1_sum3_6(.inst_a(sum3_a_in[6]),.inst_b(sum3_b_in[6]),.inst_c(sum3_c_in[6]),.inst_rnd(3'b0),.z_inst(sum3_out[6]),.status_inst());

DW_fp_sum3_inst step1_sum3_7(.inst_a(sum3_a_in[7]),.inst_b(sum3_b_in[7]),.inst_c(sum3_c_in[7]),.inst_rnd(3'b0),.z_inst(sum3_out[7]),.status_inst());
//===========

//===sum fo ch1 & ch2===
reg [31:0] add_conv_a_in, add_conv_b_in;
wire [31:0] add_conv_result;

always@(*)begin
    if(conv_cnt<=35||conv_cnt<=71)begin
        add_conv_a_in=sum3_out[3]; 
        add_conv_b_in=sum3_out[7];
    end
end

DW_fp_add_inst add_conv(.inst_a(add_conv_a_in),.inst_b(add_conv_b_in),.inst_rnd(3'b0),.z_inst(add_conv_result),.status_inst());
//======================

always@(*)begin
    if(conv_cnt<=35||conv_cnt<=71)begin
        sum3_a_in[0]=ch1_mult_out[0]; 
        sum3_b_in[0]=ch1_mult_out[1];
        sum3_c_in[0]=ch1_mult_out[2]; 
        sum3_a_in[1]=ch1_mult_out[3]; 
        sum3_b_in[1]=ch1_mult_out[4];
        sum3_c_in[1]=ch1_mult_out[5]; 
        sum3_a_in[2]=ch1_mult_out[6]; 
        sum3_b_in[2]=ch1_mult_out[7];
        sum3_c_in[2]=ch1_mult_out[8]; 

        sum3_a_in[3]=sum3_out[0];
        sum3_b_in[3]=sum3_out[1];
        sum3_c_in[3]=sum3_out[2];
    end
end

always@(*)begin
    if(conv_cnt<=35||conv_cnt<=71)begin
        sum3_a_in[4]=ch2_mult_out[0]; 
        sum3_b_in[4]=ch2_mult_out[1];
        sum3_c_in[4]=ch2_mult_out[2]; 
        sum3_a_in[5]=ch2_mult_out[3]; 
        sum3_b_in[5]=ch2_mult_out[4];
        sum3_c_in[5]=ch2_mult_out[5]; 
        sum3_a_in[6]=ch2_mult_out[6]; 
        sum3_b_in[6]=ch2_mult_out[7];
        sum3_c_in[6]=ch2_mult_out[8]; 

        sum3_a_in[7]=sum3_out[4];
        sum3_b_in[7]=sum3_out[5];
        sum3_c_in[7]=sum3_out[6];
    end
end

//===Part 3 Seq Logic===
reg [31:0] conved_img [0:35][0:1];

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt<=35)begin
        conved_img[conv_cnt][0]<=add_conv_result;
    end
    else if(conv_cnt<=71)begin
        conved_img[conv_cnt-36][1]<=add_conv_result;
    end
end
//======================

//===task 0 step 1 conv===
//Part 2 Comb Logic (決定要放入乘法器的是哪些訊號)
reg [7:0] conv_img_idx;
always @(*) begin
    case(conv_cnt)
        0,36 : conv_img_idx = 8'd0;
        1,37 : conv_img_idx = 8'd1;
        2,38 : conv_img_idx = 8'd2;
        3,39 : conv_img_idx = 8'd3;
        4,40 : conv_img_idx = 8'd4;
        5,41 : conv_img_idx = 8'd5;

        6,42 : conv_img_idx = 8'd8;
        7,43 : conv_img_idx = 8'd9;
        8,44 : conv_img_idx = 8'd10;
        9,45 : conv_img_idx = 8'd11;
        10,46: conv_img_idx = 8'd12;
        11,47: conv_img_idx = 8'd13;

        12,48: conv_img_idx = 8'd16;
        13,49: conv_img_idx = 8'd17;
        14,50: conv_img_idx = 8'd18;
        15,51: conv_img_idx = 8'd19;
        16,52: conv_img_idx = 8'd20;
        17,53: conv_img_idx = 8'd21;

        18,54: conv_img_idx = 8'd24;
        19,55: conv_img_idx = 8'd25;
        20,56: conv_img_idx = 8'd26;
        21,57: conv_img_idx = 8'd27;
        22,58: conv_img_idx = 8'd28;
        23,59: conv_img_idx = 8'd29;

        24,60: conv_img_idx = 8'd32;
        25,61: conv_img_idx = 8'd33;
        26,62: conv_img_idx = 8'd34;
        27,63: conv_img_idx = 8'd35;
        28,64: conv_img_idx = 8'd36;
        29,65: conv_img_idx = 8'd37;

        30,66: conv_img_idx = 8'd40;
        31,67: conv_img_idx = 8'd41;
        32,68: conv_img_idx = 8'd42;
        33,69: conv_img_idx = 8'd43;
        34,70: conv_img_idx = 8'd44;
        35,71: conv_img_idx = 8'd45;
        default: conv_img_idx = 8'd0;
    endcase
end

//Part 2 Comb Logic mult_in_a 固定放img
always@(*)begin
    if(conv_cnt<=35)begin
        //img_0 conv ker_ch1_1
        ch1_mult_in_a[0]=img_0[conv_img_idx]; 
        ch1_mult_in_a[1]=img_0[conv_img_idx+1];
        ch1_mult_in_a[2]=img_0[conv_img_idx+2]; 
        ch1_mult_in_a[3]=img_0[conv_img_idx+8];
        ch1_mult_in_a[4]=img_0[conv_img_idx+9]; 
        ch1_mult_in_a[5]=img_0[conv_img_idx+10];
        ch1_mult_in_a[6]=img_0[conv_img_idx+16];
        ch1_mult_in_a[7]=img_0[conv_img_idx+17]; 
        ch1_mult_in_a[8]=img_0[conv_img_idx+18];
        //img_1 conv ker_ch1_2
        ch2_mult_in_a[0] =img_1[conv_img_idx]; 
        ch2_mult_in_a[1]=img_1[conv_img_idx+1];
        ch2_mult_in_a[2]=img_1[conv_img_idx+2]; 
        ch2_mult_in_a[3]=img_1[conv_img_idx+8];
        ch2_mult_in_a[4]=img_1[conv_img_idx+9]; 
        ch2_mult_in_a[5]=img_1[conv_img_idx+10];
        ch2_mult_in_a[6]=img_1[conv_img_idx+16];
        ch2_mult_in_a[7]=img_1[conv_img_idx+17]; 
        ch2_mult_in_a[8]=img_1[conv_img_idx+18];
    end
    else if(conv_cnt<=71)begin  
        //img_0 conv ker_ch2_1
        ch1_mult_in_a[0]=img_0[conv_img_idx]; 
        ch1_mult_in_a[1]=img_0[conv_img_idx+1];
        ch1_mult_in_a[2]=img_0[conv_img_idx+2]; 
        ch1_mult_in_a[3]=img_0[conv_img_idx+8];
        ch1_mult_in_a[4]=img_0[conv_img_idx+9]; 
        ch1_mult_in_a[5]=img_0[conv_img_idx+10];
        ch1_mult_in_a[6]=img_0[conv_img_idx+16];
        ch1_mult_in_a[7]=img_0[conv_img_idx+17]; 
        ch1_mult_in_a[8]=img_0[conv_img_idx+18];
        //img_1 conv ker_ch2_2
        ch2_mult_in_a[0]=img_1[conv_img_idx]; 
        ch2_mult_in_a[1]=img_1[conv_img_idx+1];
        ch2_mult_in_a[2]=img_1[conv_img_idx+2]; 
        ch2_mult_in_a[3]=img_1[conv_img_idx+8];
        ch2_mult_in_a[4]=img_1[conv_img_idx+9]; 
        ch2_mult_in_a[5]=img_1[conv_img_idx+10];
        ch2_mult_in_a[6]=img_1[conv_img_idx+16];
        ch2_mult_in_a[7]=img_1[conv_img_idx+17]; 
        ch2_mult_in_a[8]=img_1[conv_img_idx+18];
    end
end

//Part 2 Comb Logic
always@(*)begin
    if(conv_cnt<=35)begin
        //img_0 conv ker_ch1_1
        ch1_mult_in_b[0]=ker_ch1[0][0]; 
        ch1_mult_in_b[1]=ker_ch1[1][0]; 
        ch1_mult_in_b[2]=ker_ch1[2][0]; 
        ch1_mult_in_b[3]=ker_ch1[3][0]; 
        ch1_mult_in_b[4]=ker_ch1[4][0]; 
        ch1_mult_in_b[5]=ker_ch1[5][0]; 
        ch1_mult_in_b[6]=ker_ch1[6][0]; 
        ch1_mult_in_b[7]=ker_ch1[7][0]; 
        ch1_mult_in_b[8]=ker_ch1[8][0]; 
        //img_1 conv ker_ch1_2
        ch2_mult_in_b[0]=ker_ch1[0][1]; 
        ch2_mult_in_b[1]=ker_ch1[1][1]; 
        ch2_mult_in_b[2]=ker_ch1[2][1]; 
        ch2_mult_in_b[3]=ker_ch1[3][1]; 
        ch2_mult_in_b[4]=ker_ch1[4][1]; 
        ch2_mult_in_b[5]=ker_ch1[5][1]; 
        ch2_mult_in_b[6]=ker_ch1[6][1]; 
        ch2_mult_in_b[7]=ker_ch1[7][1]; 
        ch2_mult_in_b[8]=ker_ch1[8][1]; 
    end
    else if(conv_cnt<=71)begin
        //img_0 conv ker_ch2_1
        ch1_mult_in_b[0]=ker_ch2[0][0]; 
        ch1_mult_in_b[1]=ker_ch2[1][0]; 
        ch1_mult_in_b[2]=ker_ch2[2][0]; 
        ch1_mult_in_b[3]=ker_ch2[3][0]; 
        ch1_mult_in_b[4]=ker_ch2[4][0]; 
        ch1_mult_in_b[5]=ker_ch2[5][0]; 
        ch1_mult_in_b[6]=ker_ch2[6][0]; 
        ch1_mult_in_b[7]=ker_ch2[7][0]; 
        ch1_mult_in_b[8]=ker_ch2[8][0]; 
        //img_1 conv ker_ch2_2
        ch2_mult_in_b[0]=ker_ch2[0][1]; 
        ch2_mult_in_b[1]=ker_ch2[1][1]; 
        ch2_mult_in_b[2]=ker_ch2[2][1]; 
        ch2_mult_in_b[3]=ker_ch2[3][1]; 
        ch2_mult_in_b[4]=ker_ch2[4][1]; 
        ch2_mult_in_b[5]=ker_ch2[5][1]; 
        ch2_mult_in_b[6]=ker_ch2[6][1]; 
        ch2_mult_in_b[7]=ker_ch2[7][1]; 
        ch2_mult_in_b[8]=ker_ch2[8][1]; 
    end
end
//=======================

endmodule

module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 1;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_mult
	DW_fp_mult #(sig_width, exp_width, ieee_compliance)
	U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule

module DW_fp_sum3_inst(inst_a, inst_b, inst_c, inst_rnd, z_inst,status_inst);
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [inst_sig_width+inst_exp_width : 0] inst_c;
    input [2:0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    output [7:0] status_inst;
    // Instance of DW_fp_sum3
    DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
    U1 (.a(inst_a),.b(inst_b),.c(inst_c),.rnd(inst_rnd),.z(z_inst),.status(status_inst));
endmodule

module DW_fp_add_inst(inst_a, inst_b, inst_rnd, z_inst, status_inst);
	parameter sig_width = 23;
	parameter exp_width = 8;
	parameter ieee_compliance = 0;
	input [sig_width+exp_width : 0] inst_a;
	input [sig_width+exp_width : 0] inst_b;
	input [2 : 0] inst_rnd;
	output [sig_width+exp_width : 0] z_inst;
	output [7 : 0] status_inst;
	// Instance of DW_fp_add
	DW_fp_add #(sig_width, exp_width, ieee_compliance)
	U1 (.a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


//===for debug===
module DW_fp_mult #(
parameter sig_width        = 23,
parameter exp_width        = 8,
parameter ieee_compliance  = 0
)(
input  [sig_width+exp_width:0] a,
input  [sig_width+exp_width:0] b,
input  [2:0] rnd,   
output [sig_width+exp_width:0] z,
output [7:0] status
);

wire sign_A, sign_B;
reg  sign_out;
wire [exp_width-1:0] exp_A, exp_B;
reg  [exp_width-1:0] exp_out;
wire [sig_width:0] frac_A, frac_B;      
reg  [sig_width-1:0] frac_out;
wire [(sig_width+1)*2-1:0] frac_AXB;    

// 分解輸入
assign sign_A = a[sig_width+exp_width];
assign sign_B = b[sig_width+exp_width];
assign exp_A  = a[sig_width+exp_width-1 : sig_width];
assign exp_B  = b[sig_width+exp_width-1 : sig_width];
assign frac_A = {1'b1, a[sig_width-1:0]}; 
assign frac_B = {1'b1, b[sig_width-1:0]};

always @(*) begin
    sign_out = sign_A ^ sign_B;
end

assign frac_AXB = frac_A * frac_B;

always @(*) begin
    if (frac_AXB[(sig_width+1)*2-1] == 1'b1)
        frac_out = frac_AXB[(sig_width+1)*2-2 : sig_width]; 
    else
        frac_out = frac_AXB[(sig_width+1)*2-3 : sig_width-1];
end

always @(*) begin
    if (frac_AXB[(sig_width+1)*2-1] == 1'b1)
        exp_out = exp_A + exp_B - ((1<<(exp_width-1))-1) + 1; 
    else
        exp_out = exp_A + exp_B - ((1<<(exp_width-1))-1);
end

assign z = {sign_out, exp_out, frac_out};

assign status = 8'd0;

endmodule

module DW_fp_sum3 #(parameter inst_sig_width = 23,
parameter inst_exp_width = 8,
parameter inst_ieee_compliance = 0,
parameter inst_arch_type = 0)
(
input  [inst_sig_width+inst_exp_width:0] a,   // operand A
input  [inst_sig_width+inst_exp_width:0] b,   // operand B
input  [inst_sig_width+inst_exp_width:0] c,   // operand C
input  [2:0] rnd,                             // rounding mode 
output [inst_sig_width+inst_exp_width:0] z,   // sum result
output [7:0] status                          // status flag 
);

wire [inst_sig_width+inst_exp_width:0] sum_ab;
wire [inst_sig_width+inst_exp_width:0] sum_abc;

// === A + B ===
ADD add1 (.FP_A(a),.FP_B(b),.FP_out(sum_ab));

// === (A+B) + C ===
ADD add2 (.FP_A(sum_ab),.FP_B(c),.FP_out(sum_abc));

assign z      = sum_abc;
assign status = 8'd0; 

endmodule

module ADD(FP_A, FP_B, FP_out);
input  [31:0] FP_A, FP_B;
output [31:0] FP_out;

wire sign_A, sign_B;
reg sign_out;
wire [7:0] exp_A, exp_B;
reg  [7:0] exp_out;
wire [24:0] frac_A, frac_B;
reg  [24:0] frac_out;

assign exp_A  = FP_A[30:23];
assign exp_B  = FP_B[30:23];
assign sign_A = FP_A[31];
assign sign_B = FP_B[31];
assign frac_A = {1'b0, 1'b1, FP_A[22:0]};
assign frac_B = {1'b0, 1'b1, FP_B[22:0]};

reg [7:0] shift_bit;

always @(*) begin
    if (exp_A >= exp_B) shift_bit = exp_A - exp_B;
    else shift_bit = exp_B - exp_A;
end

reg [24:0] frac_A_after_shifting, frac_B_after_shifting;
always @(*) begin
    if (exp_A < exp_B) frac_A_after_shifting = frac_A >> shift_bit;
    else frac_A_after_shifting = frac_A;
end

always @(*) begin
    if (exp_A >= exp_B) frac_B_after_shifting = frac_B >> shift_bit;
    else frac_B_after_shifting = frac_B;
end

always @(*) begin
    if (sign_A == sign_B) frac_out = frac_A_after_shifting + frac_B_after_shifting;
    else if (sign_A == 1'b0 && sign_B == 1'b1) frac_out = frac_A_after_shifting - frac_B_after_shifting;
    else frac_out = frac_B_after_shifting - frac_A_after_shifting;
end

always @(*) begin
    if (sign_A == sign_B) sign_out = sign_A;
    else sign_out = frac_out[24];
end

always @(*) begin
    if (frac_out[24] == 1'b1 && exp_A >= exp_B) exp_out = exp_A + 1;
    else if (frac_out[24] == 1'b1 && exp_A < exp_B) exp_out = exp_B + 1;
    else if (frac_out[24] == 1'b0 && exp_A >= exp_B) exp_out = exp_A;
    else if (frac_out[24] == 1'b0 && exp_A < exp_B) exp_out = exp_B;
    else exp_out = exp_A;
end

assign FP_out = (frac_out[24]) ? {sign_out, exp_out, frac_out[23:1]} :
                                 {sign_out, exp_out, frac_out[22:0]};
endmodule

module DW_fp_add #(
    parameter sig_width = 23, 
    parameter exp_width = 8, 
    parameter ieee_compliance = 0
) (
    input  [sig_width+exp_width:0] a,   // 輸入 A (等效 FP_A)
    input  [sig_width+exp_width:0] b,   // 輸入 B (等效 FP_B)
    input  [2:0] rnd,                   // 四捨五入模式 (先不用在內部)
    output [sig_width+exp_width:0] z,   // 輸出 (等效 FP_out)
    output [7:0] status                 // 狀態碼 (這裡我們先固定 0)
);

    wire [31:0] FP_A = a;
    wire [31:0] FP_B = b;
    reg  [31:0] FP_out;

    wire sign_A, sign_B;
    reg sign_out;
    wire [7:0] exp_A, exp_B;
    reg  [7:0] exp_out;
    wire [24:0] frac_A, frac_B;
    reg  [24:0] frac_out;

    assign exp_A  = FP_A[30:23];
    assign exp_B  = FP_B[30:23];
    assign sign_A = FP_A[31];
    assign sign_B = FP_B[31];
    assign frac_A = {1'b0, 1'b1, FP_A[22:0]};
    assign frac_B = {1'b0, 1'b1, FP_B[22:0]};

    reg [7:0] shift_bit;

    always @(*) begin
        if (exp_A >= exp_B) shift_bit = exp_A - exp_B;
        else shift_bit = exp_B - exp_A;
    end

    reg [24:0] frac_A_after_shifting, frac_B_after_shifting;
    always @(*) begin
        if (exp_A < exp_B) frac_A_after_shifting = frac_A >> shift_bit;
        else frac_A_after_shifting = frac_A;
    end

    always @(*) begin
        if (exp_A >= exp_B) frac_B_after_shifting = frac_B >> shift_bit;
        else frac_B_after_shifting = frac_B;
    end

    always @(*) begin
        if (sign_A == sign_B) frac_out = frac_A_after_shifting + frac_B_after_shifting;
        else if (sign_A == 1'b0 && sign_B == 1'b1) frac_out = frac_A_after_shifting - frac_B_after_shifting;
        else frac_out = frac_B_after_shifting - frac_A_after_shifting;
    end

    always @(*) begin
        if (sign_A == sign_B) sign_out = sign_A;
        else sign_out = frac_out[24];
    end

    always @(*) begin
        if (frac_out[24] == 1'b1 && exp_A >= exp_B) exp_out = exp_A + 1;
        else if (frac_out[24] == 1'b1 && exp_A < exp_B) exp_out = exp_B + 1;
        else if (frac_out[24] == 1'b0 && exp_A >= exp_B) exp_out = exp_A;
        else if (frac_out[24] == 1'b0 && exp_A < exp_B) exp_out = exp_B;
        else exp_out = exp_A;
    end

    always @(*) begin
        FP_out = (frac_out[24]) ? {sign_out, exp_out, frac_out[23:1]} :
                                  {sign_out, exp_out, frac_out[22:0]};
    end

    assign z = FP_out;
    assign status = 8'b0;  // 沒有例外檢查，先固定為 0

endmodule
//===============