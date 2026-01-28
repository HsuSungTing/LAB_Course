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
parameter IEEE_one = 32'h3F800000;
parameter IEEE_zero = 32'h00000000;
parameter FLOAT_0_01 = 32'h3C23D70A;

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

reg [31:0] acted_img [0:7];
reg [31:0] img_after_FC1 [0:4];
reg [31:0] img_after_relu [0:4];
reg [31:0] img_after_FC2 [0:2];

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

//===step 1 conv===
//(step 4也會共用)
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
//step 1的加法器，和step 3共用 (div_den要存add_conv_result(分母))
reg [31:0] add_conv_a_in, add_conv_b_in;
wire [31:0] add_conv_result;
reg [31:0] prev_positive_exp,prev_negative_exp;

always@(*)begin
    if(conv_cnt<=35||conv_cnt<=71)begin
        //step 1 conv
        add_conv_a_in=sum3_out[3]; 
        add_conv_b_in=sum3_out[7];
    end
    else if(conv_cnt>=81&&conv_cnt<=98)begin
        //step 2 act的e^x + e^-x
        if(mode==2'b01||2'b11)begin //tahn
            add_conv_a_in=prev_positive_exp; add_conv_b_in=prev_negative_exp;
        end
        else begin
            add_conv_a_in=IEEE_one; add_conv_b_in=prev_negative_exp;
        end
    end
    else if(conv_cnt>=99&&conv_cnt<=101)begin
        //step 4 FC 1
        add_conv_a_in=sum3_out[3]; 
        add_conv_b_in=sum3_out[7];
    end
    else if(conv_cnt>=103&&conv_cnt<=104)begin
        //step 4 FC 1
        add_conv_a_in=sum3_out[3]; 
        add_conv_b_in=sum3_out[7];
    end
end

DW_fp_add_inst add_conv(.inst_a(add_conv_a_in),.inst_b(add_conv_b_in),.inst_rnd(3'b0),.z_inst(add_conv_result),.status_inst());
//======================

always@(*)begin
    if(conv_cnt<=35||conv_cnt<=71)begin
        //step 1 conv
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
    else if(conv_cnt>=99&&conv_cnt<=101)begin
        //step 4 FC 1
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
    else if(conv_cnt>=103&&conv_cnt<=104)begin
        //step 6 FC 2
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
        //step 1 conv
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
    else if(conv_cnt>=99&&conv_cnt<=101)begin
        //step 4 FC 1
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
    else if(conv_cnt>=103&&conv_cnt<=104)begin
        //step 6 FC 2
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
    else if(conv_cnt==99)begin
        //step 4 FC 1 wght 0
        ch1_mult_in_a[0]=big_wgt[0][0];
        ch1_mult_in_a[1]=big_wgt[1][0];
        ch1_mult_in_a[2]=big_wgt[2][0];
        ch1_mult_in_a[3]=big_wgt[3][0];
        ch1_mult_in_a[4]=big_wgt[4][0];
        ch1_mult_in_a[5]=big_wgt[5][0];
        ch1_mult_in_a[6]=big_wgt[6][0];
        ch1_mult_in_a[7]=big_wgt[7][0];
        ch1_mult_in_a[8]=bias_1;
        //step 4 FC 1 wght 1
        ch2_mult_in_a[0]=big_wgt[0][1];
        ch2_mult_in_a[1]=big_wgt[1][1];
        ch2_mult_in_a[2]=big_wgt[2][1];
        ch2_mult_in_a[3]=big_wgt[3][1];
        ch2_mult_in_a[4]=big_wgt[4][1];
        ch2_mult_in_a[5]=big_wgt[5][1];
        ch2_mult_in_a[6]=big_wgt[6][1];
        ch2_mult_in_a[7]=big_wgt[7][1];
        ch2_mult_in_a[8]=bias_1;
    end
    else if(conv_cnt==100)begin
        //step 4 FC 1 wght 2
        ch1_mult_in_a[0]=big_wgt[0][2];
        ch1_mult_in_a[1]=big_wgt[1][2];
        ch1_mult_in_a[2]=big_wgt[2][2];
        ch1_mult_in_a[3]=big_wgt[3][2];
        ch1_mult_in_a[4]=big_wgt[4][2];
        ch1_mult_in_a[5]=big_wgt[5][2];
        ch1_mult_in_a[6]=big_wgt[6][2];
        ch1_mult_in_a[7]=big_wgt[7][2];
        ch1_mult_in_a[8]=bias_1;
        //step 4 FC 1 wght 3
        ch2_mult_in_a[0]=big_wgt[0][3];
        ch2_mult_in_a[1]=big_wgt[1][3];
        ch2_mult_in_a[2]=big_wgt[2][3];
        ch2_mult_in_a[3]=big_wgt[3][3];
        ch2_mult_in_a[4]=big_wgt[4][3];
        ch2_mult_in_a[5]=big_wgt[5][3];
        ch2_mult_in_a[6]=big_wgt[6][3];
        ch2_mult_in_a[7]=big_wgt[7][3];
        ch2_mult_in_a[8]=bias_1;
    end
    else if(conv_cnt==101)begin
        //step 4 FC 1 wght 4
        ch1_mult_in_a[0]=big_wgt[0][4];
        ch1_mult_in_a[1]=big_wgt[1][4];
        ch1_mult_in_a[2]=big_wgt[2][4];
        ch1_mult_in_a[3]=big_wgt[3][4];
        ch1_mult_in_a[4]=big_wgt[4][4];
        ch1_mult_in_a[5]=big_wgt[5][4];
        ch1_mult_in_a[6]=big_wgt[6][4];
        ch1_mult_in_a[7]=big_wgt[7][4];
        ch1_mult_in_a[8]=bias_1;
        
        ch2_mult_in_a[0]=IEEE_zero;
        ch2_mult_in_a[1]=IEEE_zero;
        ch2_mult_in_a[2]=IEEE_zero;
        ch2_mult_in_a[3]=IEEE_zero;
        ch2_mult_in_a[4]=IEEE_zero;
        ch2_mult_in_a[5]=IEEE_zero;
        ch2_mult_in_a[6]=IEEE_zero;
        ch2_mult_in_a[7]=IEEE_zero;
        ch2_mult_in_a[8]=IEEE_zero;
    end
    else if(conv_cnt==102)begin
        //step 5 relu
        ch1_mult_in_a[0]=img_after_FC1[0];
        ch1_mult_in_a[1]=img_after_FC1[1];
        ch1_mult_in_a[2]=img_after_FC1[2];
        ch1_mult_in_a[3]=img_after_FC1[3];
        ch1_mult_in_a[4]=img_after_FC1[4];
        ch1_mult_in_a[5]=IEEE_zero;
        ch1_mult_in_a[6]=IEEE_zero;
        ch1_mult_in_a[7]=IEEE_zero;
        ch1_mult_in_a[8]=IEEE_zero;
        
        ch2_mult_in_a[0]=IEEE_zero;
        ch2_mult_in_a[1]=IEEE_zero;
        ch2_mult_in_a[2]=IEEE_zero;
        ch2_mult_in_a[3]=IEEE_zero;
        ch2_mult_in_a[4]=IEEE_zero;
        ch2_mult_in_a[5]=IEEE_zero;
        ch2_mult_in_a[6]=IEEE_zero;
        ch2_mult_in_a[7]=IEEE_zero;
        ch2_mult_in_a[8]=IEEE_zero;
    end
    else if(conv_cnt==103)begin
        //step 6 FC wght 0
        ch1_mult_in_a[0]=small_wgt[0][0];
        ch1_mult_in_a[1]=small_wgt[1][0];
        ch1_mult_in_a[2]=small_wgt[2][0];
        ch1_mult_in_a[3]=small_wgt[3][0];
        ch1_mult_in_a[4]=small_wgt[4][0];
        ch1_mult_in_a[5]=bias_2;        //記得
        ch1_mult_in_a[6]=IEEE_zero;
        ch1_mult_in_a[7]=IEEE_zero;
        ch1_mult_in_a[8]=IEEE_zero;
        //step 6 FC wght 1
        ch2_mult_in_a[0]=small_wgt[0][1];
        ch2_mult_in_a[1]=small_wgt[1][1];
        ch2_mult_in_a[2]=small_wgt[2][1];
        ch2_mult_in_a[3]=small_wgt[3][1];
        ch2_mult_in_a[4]=small_wgt[4][1];
        ch2_mult_in_a[5]=bias_2;        //記得
        ch2_mult_in_a[6]=IEEE_zero;
        ch2_mult_in_a[7]=IEEE_zero;
        ch2_mult_in_a[8]=IEEE_zero;
    end
    else if(conv_cnt==104)begin
        //step 6 FC wght 2
        ch1_mult_in_a[0]=small_wgt[0][2];
        ch1_mult_in_a[1]=small_wgt[1][2];
        ch1_mult_in_a[2]=small_wgt[2][2];
        ch1_mult_in_a[3]=small_wgt[3][2];
        ch1_mult_in_a[4]=small_wgt[4][2];
        ch1_mult_in_a[5]=bias_2;        //記得
        ch1_mult_in_a[6]=IEEE_zero;
        ch1_mult_in_a[7]=IEEE_zero;
        ch1_mult_in_a[8]=IEEE_zero;
        //step 6 NULL
        ch2_mult_in_a[0]=IEEE_zero;
        ch2_mult_in_a[1]=IEEE_zero;
        ch2_mult_in_a[2]=IEEE_zero;
        ch2_mult_in_a[3]=IEEE_zero;
        ch2_mult_in_a[4]=IEEE_zero;
        ch2_mult_in_a[5]=IEEE_zero;
        ch2_mult_in_a[6]=IEEE_zero;
        ch2_mult_in_a[7]=IEEE_zero;
        ch2_mult_in_a[8]=IEEE_zero;
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
    else if(conv_cnt==99)begin
        //step 4 - FC wght 0
        ch1_mult_in_b[0]=acted_img[0]; 
        ch1_mult_in_b[1]=acted_img[1]; 
        ch1_mult_in_b[2]=acted_img[2]; 
        ch1_mult_in_b[3]=acted_img[3]; 
        ch1_mult_in_b[4]=acted_img[4]; 
        ch1_mult_in_b[5]=acted_img[5]; 
        ch1_mult_in_b[6]=acted_img[6]; 
        ch1_mult_in_b[7]=acted_img[7]; 
        ch1_mult_in_b[8]=IEEE_one;
        //step 4 - FC wght 1
        ch2_mult_in_b[0]=acted_img[0]; 
        ch2_mult_in_b[1]=acted_img[1]; 
        ch2_mult_in_b[2]=acted_img[2]; 
        ch2_mult_in_b[3]=acted_img[3]; 
        ch2_mult_in_b[4]=acted_img[4]; 
        ch2_mult_in_b[5]=acted_img[5]; 
        ch2_mult_in_b[6]=acted_img[6]; 
        ch2_mult_in_b[7]=acted_img[7]; 
        ch2_mult_in_b[8]=IEEE_one; 
    end
    else if(conv_cnt==100)begin
        //step 4  - FC wght 2
        ch1_mult_in_b[0]=acted_img[0]; 
        ch1_mult_in_b[1]=acted_img[1]; 
        ch1_mult_in_b[2]=acted_img[2]; 
        ch1_mult_in_b[3]=acted_img[3]; 
        ch1_mult_in_b[4]=acted_img[4]; 
        ch1_mult_in_b[5]=acted_img[5]; 
        ch1_mult_in_b[6]=acted_img[6]; 
        ch1_mult_in_b[7]=acted_img[7]; 
        ch1_mult_in_b[8]=IEEE_one;      //for bias 1
        //step 4 - FC wght 3
        ch2_mult_in_b[0]=acted_img[0]; 
        ch2_mult_in_b[1]=acted_img[1]; 
        ch2_mult_in_b[2]=acted_img[2]; 
        ch2_mult_in_b[3]=acted_img[3]; 
        ch2_mult_in_b[4]=acted_img[4]; 
        ch2_mult_in_b[5]=acted_img[5]; 
        ch2_mult_in_b[6]=acted_img[6]; 
        ch2_mult_in_b[7]=acted_img[7]; 
        ch2_mult_in_b[8]=IEEE_one;      //for bias 1
    end
    else if(conv_cnt==101)begin
        //step 4  - FC wght 4
        ch1_mult_in_b[0]=acted_img[0]; 
        ch1_mult_in_b[1]=acted_img[1]; 
        ch1_mult_in_b[2]=acted_img[2]; 
        ch1_mult_in_b[3]=acted_img[3]; 
        ch1_mult_in_b[4]=acted_img[4]; 
        ch1_mult_in_b[5]=acted_img[5]; 
        ch1_mult_in_b[6]=acted_img[6]; 
        ch1_mult_in_b[7]=acted_img[7]; 
        ch1_mult_in_b[8]=IEEE_one;      //for bias 1
        //step 4 - NULL
        ch2_mult_in_b[0]=IEEE_zero; 
        ch2_mult_in_b[1]=IEEE_zero; 
        ch2_mult_in_b[2]=IEEE_zero; 
        ch2_mult_in_b[3]=IEEE_zero; 
        ch2_mult_in_b[4]=IEEE_zero; 
        ch2_mult_in_b[5]=IEEE_zero; 
        ch2_mult_in_b[6]=IEEE_zero; 
        ch2_mult_in_b[7]=IEEE_zero; 
        ch2_mult_in_b[8]=IEEE_zero;
    end
    else if(conv_cnt==102)begin
        //step 5 relu
        ch1_mult_in_b[0]=FLOAT_0_01; 
        ch1_mult_in_b[1]=FLOAT_0_01; 
        ch1_mult_in_b[2]=FLOAT_0_01; 
        ch1_mult_in_b[3]=FLOAT_0_01; 
        ch1_mult_in_b[4]=FLOAT_0_01; 
        ch1_mult_in_b[5]=IEEE_zero; 
        ch1_mult_in_b[6]=IEEE_zero; 
        ch1_mult_in_b[7]=IEEE_zero; 
        ch1_mult_in_b[8]=IEEE_zero; 
        //step 4 - NULL
        ch2_mult_in_b[0]=IEEE_zero; 
        ch2_mult_in_b[1]=IEEE_zero; 
        ch2_mult_in_b[2]=IEEE_zero; 
        ch2_mult_in_b[3]=IEEE_zero; 
        ch2_mult_in_b[4]=IEEE_zero; 
        ch2_mult_in_b[5]=IEEE_zero; 
        ch2_mult_in_b[6]=IEEE_zero; 
        ch2_mult_in_b[7]=IEEE_zero; 
        ch2_mult_in_b[8]=IEEE_zero;
    end
    else if(conv_cnt==103)begin
        //step 4  - FC wght 4
        ch1_mult_in_b[0]=img_after_relu[0]; 
        ch1_mult_in_b[1]=img_after_relu[1]; 
        ch1_mult_in_b[2]=img_after_relu[2]; 
        ch1_mult_in_b[3]=img_after_relu[3]; 
        ch1_mult_in_b[4]=img_after_relu[4]; 
        ch1_mult_in_b[5]=IEEE_one;  //for bias 2
        ch1_mult_in_b[6]=IEEE_zero; 
        ch1_mult_in_b[7]=IEEE_zero; 
        ch1_mult_in_b[8]=IEEE_zero; 
        //step 4 - NULL
        ch2_mult_in_b[0]=img_after_relu[0]; 
        ch2_mult_in_b[1]=img_after_relu[1]; 
        ch2_mult_in_b[2]=img_after_relu[2]; 
        ch2_mult_in_b[3]=img_after_relu[3]; 
        ch2_mult_in_b[4]=img_after_relu[4]; 
        ch2_mult_in_b[5]=IEEE_one;  //for bias 2
        ch2_mult_in_b[6]=IEEE_zero; 
        ch2_mult_in_b[7]=IEEE_zero; 
        ch2_mult_in_b[8]=IEEE_zero; 
    end
end
//=======================

//===max pooling===
reg [31:0] cmp_1_1_a,cmp_1_1_b; wire cmp_1_1_altb;
DW_fp_cmp_inst cmp_ch1_1(.inst_a(cmp_1_1_a), .inst_b(cmp_1_1_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_1_1_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_1_2_a,cmp_1_2_b; wire cmp_1_2_altb;
DW_fp_cmp_inst cmp_ch1_2(.inst_a(cmp_1_2_a), .inst_b(cmp_1_2_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_1_2_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_1_3_a,cmp_1_3_b; wire cmp_1_3_altb;
DW_fp_cmp_inst cmp_ch1_3(.inst_a(cmp_1_3_a), .inst_b(cmp_1_3_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_1_3_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_1_4_a,cmp_1_4_b; wire cmp_1_4_altb;
DW_fp_cmp_inst cmp_ch1_4(.inst_a(cmp_1_4_a), .inst_b(cmp_1_4_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_1_4_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());
//=================

//===max pooling===
reg [31:0] cmp_2_1_a,cmp_2_1_b; wire cmp_2_1_altb;
DW_fp_cmp_inst cmp_ch2_1(.inst_a(cmp_2_1_a), .inst_b(cmp_2_1_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_2_1_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_2_2_a,cmp_2_2_b; wire cmp_2_2_altb;
DW_fp_cmp_inst cmp_ch2_2(.inst_a(cmp_2_2_a), .inst_b(cmp_2_2_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_2_2_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_2_3_a,cmp_2_3_b; wire cmp_2_3_altb;
DW_fp_cmp_inst cmp_ch2_3(.inst_a(cmp_2_3_a), .inst_b(cmp_2_3_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_2_3_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());

reg [31:0] cmp_2_4_a,cmp_2_4_b; wire cmp_2_4_altb;
DW_fp_cmp_inst cmp_ch2_4(.inst_a(cmp_2_4_a), .inst_b(cmp_2_4_b),
.inst_zctr(1'b0),.aeqb_inst(),.altb_inst(cmp_2_4_altb),.agtb_inst(),
.unordered_inst(),.z0_inst(),.z1_inst(),.status0_inst(),.status1_inst());
//=================

//比八次，每次紀錄目前最大的val
reg [31:0]temp_cmp_result1, temp_cmp_result2, temp_cmp_result3,temp_cmp_result4;
reg [31:0]temp_cmp_result5, temp_cmp_result6, temp_cmp_result7,temp_cmp_result8;

//Part 3 Seq Logic- 更新temp_cmp_result
reg [31:0] pooled_img[0:7];
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==8'd72)begin
        temp_cmp_result1<=conved_img[0][0];  temp_cmp_result5<=conved_img[0][0];
        temp_cmp_result2<=conved_img[3][0];  temp_cmp_result6<=conved_img[3][0];
        temp_cmp_result3<=conved_img[18][0]; temp_cmp_result7<=conved_img[18][0];
        temp_cmp_result4<=conved_img[21][0]; temp_cmp_result8<=conved_img[21][0];
    end
    else if(conv_cnt>=8'd73&&conv_cnt<=8'd79)begin
        if(cmp_1_1_altb==1'b1)temp_cmp_result1<=temp_cmp_result1;
        else temp_cmp_result1<=cmp_1_1_a;
        if(cmp_1_2_altb==1'b1)temp_cmp_result2<=temp_cmp_result2;
        else temp_cmp_result2<=cmp_1_2_a;
        if(cmp_1_3_altb==1'b1)temp_cmp_result3<=temp_cmp_result3;
        else temp_cmp_result3<=cmp_1_3_a;
        if(cmp_1_4_altb==1'b1)temp_cmp_result4<=temp_cmp_result4;
        else temp_cmp_result4<=cmp_1_4_a;

        if(cmp_2_1_altb==1'b1)temp_cmp_result5<=temp_cmp_result5;
        else temp_cmp_result5<=cmp_2_1_a;
        if(cmp_2_2_altb==1'b1)temp_cmp_result6<=temp_cmp_result6;
        else temp_cmp_result6<=cmp_2_2_a;
        if(cmp_2_3_altb==1'b1)temp_cmp_result7<=temp_cmp_result7;
        else temp_cmp_result7<=cmp_2_3_a;
        if(cmp_2_4_altb==1'b1)temp_cmp_result8<=temp_cmp_result8;
        else temp_cmp_result8<=cmp_2_4_a;
    end
    else if(conv_cnt==8'd80)begin
        if(cmp_1_1_altb==1'b1)pooled_img[0]<=temp_cmp_result1;
        else pooled_img[0]<=cmp_1_1_a;
        if(cmp_1_2_altb==1'b1)pooled_img[1]<=temp_cmp_result2;
        else pooled_img[1]<=cmp_1_2_a;
        if(cmp_1_3_altb==1'b1)pooled_img[2]<=temp_cmp_result3;
        else pooled_img[2]<=cmp_1_3_a;
        if(cmp_1_4_altb==1'b1)pooled_img[3]<=temp_cmp_result4;
        else pooled_img[3]<=cmp_1_4_a;

        if(cmp_2_1_altb==1'b1)pooled_img[4]<=temp_cmp_result5;
        else pooled_img[4]<=cmp_2_1_a;
        if(cmp_2_2_altb==1'b1)pooled_img[5]<=temp_cmp_result6;
        else pooled_img[5]<=cmp_2_2_a;
        if(cmp_2_3_altb==1'b1)pooled_img[6]<=temp_cmp_result7;
        else pooled_img[6]<=cmp_2_3_a;
        if(cmp_2_4_altb==1'b1)pooled_img[7]<=temp_cmp_result8;
        else pooled_img[7]<=cmp_2_4_a;
    end
end

//Part 2 Comb Logic
always@(*)begin
    if(conv_cnt==8'd73)begin
        cmp_1_1_a=conved_img[1][0];  cmp_1_2_a=conved_img[4][0];  
        cmp_1_3_a=conved_img[19][0]; cmp_1_4_a=conved_img[22][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[1][1];  cmp_2_2_a=conved_img[4][1];  
        cmp_2_3_a=conved_img[19][1]; cmp_2_4_a=conved_img[22][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd74)begin
        cmp_1_1_a=conved_img[2][0];  cmp_1_2_a=conved_img[5][0];  
        cmp_1_3_a=conved_img[20][0]; cmp_1_4_a=conved_img[23][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[2][1];  cmp_2_2_a=conved_img[5][1];  
        cmp_2_3_a=conved_img[20][1]; cmp_2_4_a=conved_img[23][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd75)begin
        cmp_1_1_a=conved_img[6][0];  cmp_1_2_a=conved_img[9][0];  
        cmp_1_3_a=conved_img[24][0]; cmp_1_4_a=conved_img[27][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[6][1];  cmp_2_2_a=conved_img[9][1];  
        cmp_2_3_a=conved_img[24][1]; cmp_2_4_a=conved_img[27][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd76)begin
        cmp_1_1_a=conved_img[7][0];  cmp_1_2_a=conved_img[10][0];  
        cmp_1_3_a=conved_img[25][0]; cmp_1_4_a=conved_img[28][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[7][1];  cmp_2_2_a=conved_img[10][1];  
        cmp_2_3_a=conved_img[25][1]; cmp_2_4_a=conved_img[28][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd77)begin
        cmp_1_1_a=conved_img[8][0];  cmp_1_2_a=conved_img[11][0];  
        cmp_1_3_a=conved_img[26][0]; cmp_1_4_a=conved_img[29][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[8][1];  cmp_2_2_a=conved_img[11][1];  
        cmp_2_3_a=conved_img[26][1]; cmp_2_4_a=conved_img[29][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd78)begin
        cmp_1_1_a=conved_img[12][0]; cmp_1_2_a=conved_img[15][0];  
        cmp_1_3_a=conved_img[30][0]; cmp_1_4_a=conved_img[33][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[12][1]; cmp_2_2_a=conved_img[15][1];  
        cmp_2_3_a=conved_img[30][1]; cmp_2_4_a=conved_img[33][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd79)begin
        cmp_1_1_a=conved_img[13][0]; cmp_1_2_a=conved_img[16][0];  
        cmp_1_3_a=conved_img[31][0]; cmp_1_4_a=conved_img[34][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[13][1]; cmp_2_2_a=conved_img[16][1];  
        cmp_2_3_a=conved_img[31][1]; cmp_2_4_a=conved_img[34][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
    else if(conv_cnt==8'd80)begin
        cmp_1_1_a=conved_img[14][0]; cmp_1_2_a=conved_img[17][0];  
        cmp_1_3_a=conved_img[32][0]; cmp_1_4_a=conved_img[35][0];
        cmp_1_1_b=temp_cmp_result1;  cmp_1_2_b=temp_cmp_result2;  
        cmp_1_3_b=temp_cmp_result3;  cmp_1_4_b=temp_cmp_result4; 

        cmp_2_1_a=conved_img[14][1]; cmp_2_2_a=conved_img[17][1];  
        cmp_2_3_a=conved_img[32][1]; cmp_2_4_a=conved_img[35][1]; 
        cmp_2_1_b=temp_cmp_result5;  cmp_2_2_b=temp_cmp_result6;  
        cmp_2_3_b=temp_cmp_result7;  cmp_2_4_b=temp_cmp_result8; 
    end
end
//=================

//===step 3 ACT 1===
//加法器和step 1共用
//減法器 prev_positive_exp - prev_negative_exp
wire [31:0] sub_out;
DW_fp_sub_inst sub1(.inst_a(prev_positive_exp),.inst_b(prev_negative_exp),.inst_rnd(3'b0),.z_inst(sub_out),.status_inst());

reg [31:0] exp_in;
wire [31:0] exp_out;
DW_fp_exp_inst exp1(.inst_a(exp_in),.z_inst(exp_out),.status_inst());

reg [31:0] div_in_a, div_in_b;
wire [31:0] div_out;
DW_fp_div_inst div1(.inst_a(div_in_a),.inst_b(div_in_b),.inst_rnd(3'b0),.z_inst(div_out),.status_inst());

//Part 3 Seq Logic (分子和分母)
reg [31:0] div_num, div_den;    //分子和分母
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==83)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[0];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==85)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[1];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==87)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[2];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==89)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[3];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==91)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[4];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==93)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[5];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==95)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[6];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
    else if(conv_cnt==97)begin
        if(mode_q==2'b01||mode_q==2'b11)div_num<=pooled_img[7];
        else div_num<=sub_out;
        div_den<=add_conv_result;
    end
end

//Part 2 Comb Logic
always@(*)begin
    if(conv_cnt>=81&&conv_cnt<=98)begin
        div_in_a=div_num; div_in_b=div_den;
    end
end

//Part 2 Comb Logic (exp的Input)
always @(*) begin
    if(conv_cnt==81) exp_in=pooled_img[0];   //e^x1
    else if(conv_cnt==82) exp_in={~pooled_img[0][31],pooled_img[0][30:0]};   //e^-x1
    else if(conv_cnt==83) exp_in=pooled_img[1];   //e^x2
    else if(conv_cnt==84) exp_in={~pooled_img[1][31],pooled_img[1][30:0]};   //e^-x2
    else if(conv_cnt==85) exp_in=pooled_img[2];   //e^x3
    else if(conv_cnt==86) exp_in={~pooled_img[2][31],pooled_img[2][30:0]};   //e^-x3
    else if(conv_cnt==87) exp_in=pooled_img[3];   //e^x4
    else if(conv_cnt==88) exp_in={~pooled_img[3][31],pooled_img[3][30:0]};   //e^-x4
    else if(conv_cnt==89) exp_in=pooled_img[4];   //e^x5
    else if(conv_cnt==90) exp_in={~pooled_img[4][31],pooled_img[4][30:0]};   //e^-x5
    else if(conv_cnt==91) exp_in=pooled_img[5];   //e^x6
    else if(conv_cnt==92) exp_in={~pooled_img[5][31],pooled_img[5][30:0]};   //e^-x6
    else if(conv_cnt==93) exp_in=pooled_img[6];   //e^x7
    else if(conv_cnt==94) exp_in={~pooled_img[6][31],pooled_img[6][30:0]};   //e^-x7
    else if(conv_cnt==95) exp_in=pooled_img[7];   //e^x8
    else if(conv_cnt==96) exp_in={~pooled_img[7][31],pooled_img[7][30:0]};   //e^-x8
end

reg [31:0] cur_positive_exp,cur_negative_exp;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==81)cur_positive_exp<=exp_out;  //e^x1
    else if(conv_cnt==82)begin
        cur_negative_exp<=exp_out;  //e^-x1
        prev_positive_exp<=cur_positive_exp;//e^x1
        prev_negative_exp<=exp_out;         //e^-x1
    end
    else if(conv_cnt==83)cur_positive_exp<=exp_out;  //e^x2
    else if(conv_cnt==84)begin
        cur_negative_exp<=exp_out;  //e^-x2
        prev_positive_exp<=cur_positive_exp;//e^x2
        prev_negative_exp<=exp_out;         //e^-x2
    end
    else if(conv_cnt==85)cur_positive_exp<=exp_out;  //e^x3
    else if(conv_cnt==86)begin
        cur_negative_exp<=exp_out;  //e^-x3
        prev_positive_exp<=cur_positive_exp;//e^x3
        prev_negative_exp<=exp_out;         //e^-x3
    end
    else if(conv_cnt==87)cur_positive_exp<=exp_out;  //e^x4
    else if(conv_cnt==88)begin
        cur_negative_exp<=exp_out;  //e^-x4
        prev_positive_exp<=cur_positive_exp;//e^x4
        prev_negative_exp<=exp_out;         //e^-x4
    end
    else if(conv_cnt==89)cur_positive_exp<=exp_out;  //e^x5
    else if(conv_cnt==90)begin
        cur_negative_exp<=exp_out;  //e^-x5
        prev_positive_exp<=cur_positive_exp;//e^x5
        prev_negative_exp<=exp_out;         //e^-x5
    end
    else if(conv_cnt==91)cur_positive_exp<=exp_out;  //e^x6
    else if(conv_cnt==92)begin
        cur_negative_exp<=exp_out;  //e^-x6
        prev_positive_exp<=cur_positive_exp;//e^x6
        prev_negative_exp<=exp_out;         //e^-x6
    end
    else if(conv_cnt==93)cur_positive_exp<=exp_out;  //e^x7
    else if(conv_cnt==94)begin
        cur_negative_exp<=exp_out;  //e^-x7
        prev_positive_exp<=cur_positive_exp;//e^x7
        prev_negative_exp<=exp_out;         //e^-x7
    end
    else if(conv_cnt==95)cur_positive_exp<=exp_out;  //e^x7
    else if(conv_cnt==96)begin
        cur_negative_exp<=exp_out;  //e^-x8
        prev_positive_exp<=cur_positive_exp;//e^x8
        prev_negative_exp<=exp_out;         //e^-x8
    end
end

//Part 3 Seq Logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
    end
    else if(conv_cnt==84) acted_img[0]<=div_out;
    else if(conv_cnt==86) acted_img[1]<=div_out;
    else if(conv_cnt==88) acted_img[2]<=div_out;
    else if(conv_cnt==90) acted_img[3]<=div_out;
    else if(conv_cnt==92) acted_img[4]<=div_out;
    else if(conv_cnt==94) acted_img[5]<=div_out;
    else if(conv_cnt==96) acted_img[6]<=div_out;
    else if(conv_cnt==98) acted_img[7]<=div_out;
end
//===========

//===step 4 FC 1===
//和step 1共用乘法和加法
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==99)begin
        img_after_FC1[0]<=add_conv_a_in;
        img_after_FC1[1]<=add_conv_b_in;
    end
    else if(conv_cnt==100)begin
        img_after_FC1[2]<=add_conv_a_in;
        img_after_FC1[3]<=add_conv_b_in;
    end
    else if(conv_cnt==101)begin
        img_after_FC1[4]<=add_conv_a_in;
    end
end
//=================

//===step 5 leaky relu===
//和step 1共用乘法
//reg [31:0] ch1_mult_in_a [0-4];
//reg [31:0] ch1_mult_in_b [0-4];
//wire [31:0] ch1_mult_out [0-4];

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==102)begin
        //直接用sign bit看
        if(img_after_FC1[0][31]==1'b1) img_after_relu[0]<=ch1_mult_out[0];
        else img_after_relu[0]<=img_after_FC1[0];
        if(img_after_FC1[1][31]==1'b1) img_after_relu[1]<=ch1_mult_out[1];
        else img_after_relu[1]<=img_after_FC1[1];
        if(img_after_FC1[2][31]==1'b1) img_after_relu[2]<=ch1_mult_out[2];
        else img_after_relu[2]<=img_after_FC1[2];
        if(img_after_FC1[3][31]==1'b1) img_after_relu[3]<=ch1_mult_out[3];
        else img_after_relu[3]<=img_after_FC1[3];
        if(img_after_FC1[4][31]==1'b1) img_after_relu[4]<=ch1_mult_out[4];
        else img_after_relu[4]<=img_after_FC1[4];
    end
end
//=======================

//===step 6 FC 2===
//和step 1共用乘法和加法
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(conv_cnt==103)begin
        img_after_FC2[0]<=add_conv_a_in;
        img_after_FC2[1]<=add_conv_b_in;
    end
    else if(conv_cnt==104)begin
        img_after_FC2[2]<=add_conv_a_in;
    end
end
//=================

endmodule

module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst, status_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
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

module DW_fp_cmp_inst(inst_a,inst_b,inst_zctr, aeqb_inst,altb_inst,agtb_inst,
    unordered_inst, z0_inst, z1_inst, status0_inst,status1_inst);
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input inst_zctr;
    output aeqb_inst;
    output altb_inst;
    output agtb_inst;
    output unordered_inst;
    output [sig_width+exp_width : 0] z0_inst;
    output [sig_width+exp_width : 0] z1_inst;
    output [7 : 0] status0_inst;
    output [7 : 0] status1_inst;
    // Instance of DW_fp_cmp
    DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
    U1(.a(inst_a),.b(inst_b),.zctr(inst_zctr),.aeqb(aeqb_inst),.altb(altb_inst),.agtb(agtb_inst),
    .unordered(unordered_inst),.z0(z0_inst), .z1(z1_inst),.status0(status0_inst),.status1(status1_inst));

endmodule

module DW_fp_exp_inst( inst_a, z_inst, status_inst );
    parameter inst_sig_width=23;
    parameter inst_exp_width=8;
    parameter inst_ieee_compliance= 0;
    parameter inst_arch=0;
    input [inst_sig_width+inst_exp_width:0]inst_a;
    output [inst_sig_width+inst_exp_width:0]z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_exp
    DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) 
    U1 (.a(inst_a),.z(z_inst),.status(status_inst));
endmodule

module DW_fp_div_inst(inst_a, inst_b, inst_rnd, z_inst, status_inst);
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    parameter faithful_round = 0;

    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    //Instance of DW_fp_div
    DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round) 
    U1 (.a(inst_a),.b(inst_b),.rnd(inst_rnd),.z(z_inst),.status(status_inst));
endmodule

module DW_fp_sub_inst(inst_a, inst_b, inst_rnd, z_inst, status_inst);
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [sig_width+exp_width : 0] z_inst;
    output [7 : 0] status_inst;
    // Instance of DW_fp_sub
    DW_fp_sub #(sig_width, exp_width, ieee_compliance)
    U1(.a(inst_a),.b(inst_b),.rnd(inst_rnd),.z(z_inst),.status(status_inst));
endmodule