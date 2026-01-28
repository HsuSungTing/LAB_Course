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
            if(input_cnt>=16) next_state=OUTPUT;  
            else next_state=INPUT;
        end
        OUTPUT: begin
            //傳完16筆就休息
            if(output_cnt >= 18) next_state=CLEAR;
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

//Part 3 Seq Logic: 
reg [31:0] out_data_d;
reg [31:0] prev_out_data_d;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        output_cnt<=0; out_data_d<=32'd0; prev_out_data_d<=32'd0;
    end
    else if(cur_state==OUTPUT && output_cnt<=17)begin
        if(output_cnt==0)begin
            output_cnt<=1; out_data_d<=input_data[0]; prev_out_data_d<=input_data[0];
        end
        else if(out_idle==1'b1)begin
            output_cnt<=output_cnt+1; out_data_d<=input_data[output_cnt];
            prev_out_data_d<=out_data_d;
        end
        else begin
           output_cnt<=output_cnt; out_data_d<=out_data_d;
           prev_out_data_d<=prev_out_data_d;
        end
    end
    else begin
        output_cnt<=0; out_data_d<=32'd0; prev_out_data_d<=32'd0;
    end
end

//Part 3 Seq Logic 刻意讓輸出維持3個cycle

reg [1:0] out_hold_cnt;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) out_hold_cnt<=0;
    else if(cur_state==OUTPUT && out_hold_cnt==3)begin
        out_hold_cnt<=0;
    end
    else if(cur_state==OUTPUT && out_hold_cnt>=1 && out_hold_cnt<=2)begin
        out_hold_cnt<=out_hold_cnt+1;
    end
    else if(cur_state==OUTPUT && output_cnt>=1 && output_cnt<=16 && out_idle==1'b1)begin
        out_hold_cnt<=1;
    end
    else begin
        out_hold_cnt<=0;
    end
end

always@(*)begin
    if(cur_state==OUTPUT&& output_cnt>=1 && output_cnt<=16 && out_idle==1'b1)begin
        out_valid=1'b1; out_data=out_data_d;
    end
    else if(cur_state==OUTPUT&& output_cnt>=1 && output_cnt<=16 && (out_hold_cnt>=1 && out_hold_cnt<=3))begin
        out_valid=1'b1; out_data=prev_out_data_d;
    end
    else begin
        out_valid=1'b0; out_data=32'd0;
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
output reg        busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

//Part 1 FSM (FSM tag)
reg [2:0]cur_state,next_state;
parameter IDLE=3'd0, INPUT=3'd1, EVAL=3'd2, OUTPUT=3'd3, CLEAR=3'd4;

//FSM tag
reg [4:0] input_cnt;    //有16組input
reg [7:0] output_cnt;   //有128個output
reg EVAL_done;
reg [8:0] EVAL_cnt;

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
            if(input_cnt>=16) next_state=EVAL;
            else next_state=INPUT;
        end
        EVAL: begin
            if(EVAL_cnt>=448)next_state=OUTPUT;
            else next_state=EVAL;
        end
        OUTPUT: begin
            if(output_cnt >= 129) next_state=CLEAR;
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 3 Seq Logic (for EVAL)
reg [7:0] cur_t;
reg [6:0] cur_ht;   //64, 32, 16, 8
reg [15:0] cur_s;
reg [7:0] cur_j1, cur_j2;
reg [7:0] cur_m, cur_i, cur_j;    //big cnt, mid_cnt, small_cntl

//Part 2 Comb Logic
reg [15:0] GMb_val;
reg [6:0] Gmb_idx;

always@(*)begin
    if(cur_i==cur_m-1 && cur_j==cur_j2-1)Gmb_idx=(cur_m<<1)+ 0;
    else Gmb_idx= cur_m+ (cur_i+1);
end

always@(*)begin
    case (Gmb_idx)
        0:  GMb_val = 4091;
        1:  GMb_val = 7888;
        2:  GMb_val = 11060;
        3:  GMb_val = 11208;
        4:  GMb_val = 6960;
        5:  GMb_val = 4342;
        6:  GMb_val = 6275;
        7:  GMb_val = 9759;
        8:  GMb_val = 1591;
        9:  GMb_val = 6399;
        10: GMb_val = 9477;
        11: GMb_val = 5266;
        12: GMb_val = 586;
        13: GMb_val = 5825;
        14: GMb_val = 7538;
        15: GMb_val = 9710;
        16: GMb_val = 1134;
        17: GMb_val = 6407;
        18: GMb_val = 1711;
        19: GMb_val = 965;
        20: GMb_val = 7099;
        21: GMb_val = 7674;
        22: GMb_val = 3743;
        23: GMb_val = 6442;
        24: GMb_val = 10414;
        25: GMb_val = 8100;
        26: GMb_val = 1885;
        27: GMb_val = 1688;
        28: GMb_val = 1364;
        29: GMb_val = 10329;
        30: GMb_val = 10164;
        31: GMb_val = 9180;
        32: GMb_val = 12210;
        33: GMb_val = 6240;
        34: GMb_val = 997;
        35: GMb_val = 117;
        36: GMb_val = 4783;
        37: GMb_val = 4407;
        38: GMb_val = 1549;
        39: GMb_val = 7072;
        40: GMb_val = 2829;
        41: GMb_val = 6458;
        42: GMb_val = 4431;
        43: GMb_val = 8877;
        44: GMb_val = 7144;
        45: GMb_val = 2564;
        46: GMb_val = 5664;
        47: GMb_val = 4042;
        48: GMb_val = 12189;
        49: GMb_val = 432;
        50: GMb_val = 10751;
        51: GMb_val = 1237;
        52: GMb_val = 7610;
        53: GMb_val = 1534;
        54: GMb_val = 3983;
        55: GMb_val = 7863;
        56: GMb_val = 2181;
        57: GMb_val = 6308;
        58: GMb_val = 8720;
        59: GMb_val = 6570;
        60: GMb_val = 4843;
        61: GMb_val = 1690;
        62: GMb_val = 14;
        63: GMb_val = 3872;
        64: GMb_val = 5569;
        65: GMb_val = 9368;
        66: GMb_val = 12163;
        67: GMb_val = 2019;
        68: GMb_val = 7543;
        69: GMb_val = 2315;
        70: GMb_val = 4673;
        71: GMb_val = 7340;
        72: GMb_val = 1553;
        73: GMb_val = 1156;
        74: GMb_val = 8401;
        75: GMb_val = 11389;
        76: GMb_val = 1020;
        77: GMb_val = 2967;
        78: GMb_val = 10772;
        79: GMb_val = 7045;
        80: GMb_val = 3316;
        81: GMb_val = 11236;
        82: GMb_val = 5285;
        83: GMb_val = 11578;
        84: GMb_val = 10637;
        85: GMb_val = 10086;
        86: GMb_val = 9493;
        87: GMb_val = 6180;
        88: GMb_val = 9277;
        89: GMb_val = 6130;
        90: GMb_val = 3323;
        91: GMb_val = 883;
        92: GMb_val = 10469;
        93: GMb_val = 489;
        94: GMb_val = 1502;
        95: GMb_val = 2851;
        96: GMb_val = 11061;
        97: GMb_val = 9729;
        98: GMb_val = 2742;
        99: GMb_val = 12241;
        100: GMb_val = 4970;
        101: GMb_val = 10481;
        102: GMb_val = 10078;
        103: GMb_val = 1195;
        104: GMb_val = 730;
        105: GMb_val = 1762;
        106: GMb_val = 3854;
        107: GMb_val = 2030;
        108: GMb_val = 5892;
        109: GMb_val = 10922;
        110: GMb_val = 9020;
        111: GMb_val = 5274;
        112: GMb_val = 9179;
        113: GMb_val = 3604;
        114: GMb_val = 3782;
        115: GMb_val = 10206;
        116: GMb_val = 3180;
        117: GMb_val = 3467;
        118: GMb_val = 4668;
        119: GMb_val = 2446;
        120: GMb_val = 7613;
        121: GMb_val = 9386;
        122: GMb_val = 834;
        123: GMb_val = 7703;
        124: GMb_val = 6836;
        125: GMb_val = 3403;
        126: GMb_val = 5351;
        127: GMb_val = 12276;
        default: GMb_val = 0;
    endcase
end

//Part 3 Seq Logic (為了pipeline 暫存前個cycle的value給下個ycycle算)
reg [31:0] last_cycle_x;
reg [15:0] last_cycle_y;
reg [7:0] last_cycle_cur_j, last_cycle_cur_j_plus_cur_ht;   //for pipeline

//Part 2 Comb Logic
reg [15:0] x_arr [0:127];
wire [15:0] mg_mul_out, u_plus_v_mod_Q_out, u_minus_v_mod_Q_out;
//裡面應該要切，但先看面積沒關係 

wire [31:0] x_out;
wire [15:0] y_out;

montgomery_mult_part1 montgomery_mult_part1_inst(
    .A(x_arr[cur_j+cur_ht]),
    .B(cur_s),
    .x(x_out),
    .y(y_out)
);

montgomery_mult_part2 montgomery_mult_part2_inst(
    .x(last_cycle_x),
    .y(last_cycle_y),
    .R_out(mg_mul_out)
);

// montgomery_mult_16 montgomery_mult_16_inst(
//     .A(x_arr[cur_j+cur_ht]),
//     .B(cur_s),
//     .R_out(mg_mul_out)
// );

u_plus_v_mod_Q u_plus_v_mod_Q_inst(
    .A(x_arr[last_cycle_cur_j]),    //要放入前一個cycle的
    .B(mg_mul_out),
    .out(u_plus_v_mod_Q_out)
);

u_minus_v_mod_Q u_minus_v_mod_Q_inst(
    .A(x_arr[last_cycle_cur_j]),    //要放入前一個cycle的
    .B(mg_mul_out),
    .out(u_minus_v_mod_Q_out)
);

//Part 3 Seq Logic: take x_arr[] and EVAL x_arr[] (FSM)
integer i,j;
//reg [15:0] x_arr [0:127];
wire [7:0] input_cnt_mul_8;

assign input_cnt_mul_8=input_cnt<<3;
reg can_take_next_input;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        //===for input===
        can_take_next_input<=1;
        input_cnt<=5'd0; 
        for(i=0;i<128;i=i+1)begin
            x_arr[i]<=16'd0;
        end
        //===for EVAL===
        last_cycle_cur_j<=8'd0;
        last_cycle_cur_j_plus_cur_ht<=8'd0;
        last_cycle_x<=31'd0;
        last_cycle_y<=16'd0;

        cur_m<=8'd1; 
        cur_i<=8'd0;        //i初始值為j1
        cur_j<=8'd0;        //j初始值為j1
        cur_t<=8'd128;      //t=128 
        cur_ht<=7'd64;      //ht=t/2
        cur_s<=16'd7888;    //GMb[1]
        cur_j1<=8'd0; 
        cur_j2<=(8'd0)+64;  //j1+ht
        EVAL_done<=0;   EVAL_cnt<=9'd0;
    end
    else if (input_cnt<=15) begin
        //代表拿完一次Input,這輪拿完了,直到dvalid放下以前都不能再更新
        if(in_valid==1'b1&&can_take_next_input==1)can_take_next_input<=0;
        else if(can_take_next_input==1 && in_valid==1'b0)can_take_next_input<=1;
        else if(can_take_next_input==0 && in_valid==1'b0)can_take_next_input<=1;
        else can_take_next_input<=can_take_next_input;

        if(in_valid==1'b1&&can_take_next_input==1)begin 
            input_cnt<= input_cnt+1'd1;
            x_arr[input_cnt_mul_8]  <={12'd0,in_data[3:0]};
            x_arr[input_cnt_mul_8+1]<={12'd0,in_data[7:4]};
            x_arr[input_cnt_mul_8+2]<={12'd0,in_data[11:8]};
            x_arr[input_cnt_mul_8+3]<={12'd0,in_data[15:12]};
            x_arr[input_cnt_mul_8+4]<={12'd0,in_data[19:16]};
            x_arr[input_cnt_mul_8+5]<={12'd0,in_data[23:20]};
            x_arr[input_cnt_mul_8+6]<={12'd0,in_data[27:24]};
            x_arr[input_cnt_mul_8+7]<={12'd0,in_data[31:28]};
        end
        else input_cnt<= input_cnt;
    end
    else if (cur_state==EVAL) begin
        EVAL_cnt<=EVAL_cnt+1;
        if(EVAL_cnt>=0&&EVAL_cnt<=447)begin
            last_cycle_cur_j<=cur_j;
            last_cycle_cur_j_plus_cur_ht<=cur_j+cur_ht;
            last_cycle_x<=x_out;
            last_cycle_y<=y_out;
        end

        if(EVAL_cnt>=1&&EVAL_cnt<=448)begin
            x_arr[last_cycle_cur_j]<=u_plus_v_mod_Q_out;
            x_arr[last_cycle_cur_j_plus_cur_ht]<=u_minus_v_mod_Q_out;
        end

        if(cur_m==64 && cur_i==cur_m-1'b1 && cur_j==cur_j2-1'b1)begin
            EVAL_done<=1;
        end                                                           
        else if(cur_i==cur_m-1 && cur_j==cur_j2-1) begin //outer loop it update
            //outer loop it update
            cur_m<=cur_m<<1;    //m=m*2
            //mid var update
            cur_t <=cur_ht;
            cur_ht<=cur_ht>>1;  //ht=t/2

            //mid loop it update
            cur_i<=0;
            cur_j1<=0;
            //innner loop var update
            cur_s<=GMb_val;         //GMB[m+i], next i=0  
            cur_j2<= 0 + (cur_ht>>1);    //j1+ht, next j1=0  
            //inner loop it update
            cur_j<=0;               //j<=j1, next j1=0  
        end                                                
        else if(cur_j==cur_j2-1)begin   //mid loop it update
            //mid loop it update
            cur_i<=(cur_i+1);
            cur_j1<=(cur_j1 +cur_t);
            //innner loop var update
            cur_s <= GMb_val;           //GMB[cur_m+ (cur_i+1)];
            cur_j2<= (cur_j1 +cur_t) + cur_ht;
            //inner loop it update
            cur_j<=(cur_j1 +cur_t);
        end           
        else begin 
            cur_j<=cur_j+1;            //inner loop it update
        end
    end
    else if(cur_state==CLEAR) begin
        //===for input===
        can_take_next_input<=1;
        input_cnt<=5'd0; 
        for(i=0;i<128;i=i+1)begin
            x_arr[i]<=16'd0;
        end
        //===for EVAL===
        last_cycle_cur_j<=8'd0;
        last_cycle_cur_j_plus_cur_ht<=8'd0;
        last_cycle_x<=31'd0;
        last_cycle_y<=16'd0;

        cur_m<=8'd1; 
        cur_i<=8'd0;        //i初始值為j1
        cur_j<=8'd0;        //j初始值為j1
        cur_t<=8'd128;      //t=128 
        cur_ht<=7'd64;      //ht=t/2
        cur_s<=16'd7888;    //GMb[1]
        cur_j1<=8'd0; 
        cur_j2<=(8'd0)+64;  //j1+ht
        EVAL_done<=0;   EVAL_cnt<=9'd0;
    end
end

//Part 3 Seq Logic: busy
//busy會在接收完所有輸入資料之後開始被拉成 1, 並在整個計算與寫出
//結果的過程中維持為 1, 直到輸出結果結束後才會恢復為 0
//reg busy_d
//再用comb
always@(posedge clk or negedge rst_n)begin
    if(!rst_n) busy<=0;
    //else if((cur_state==EVAL&&EVAL_cnt>=8) || cur_state==OUTPUT || cur_state==CLEAR) busy<=1;
    else if(cur_state==OUTPUT || cur_state==CLEAR) busy<=1;
    else busy<=0;
end

//Part 3 Seq Logic: for OUTPUT (fifo_empty==0才能輸出)
//OUTPUT 一定要COMB
reg [15:0] out_data_d;
reg met_full_tag;
reg [2:0] full_cnt;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        output_cnt<=8'd0; out_data_d<=16'd0; met_full_tag<=0; full_cnt<=0;               
    end
    else if(cur_state==OUTPUT && output_cnt<=128)begin
        //not full時才能傳下一筆
        if(fifo_full==1)begin      //發生full的cycle進行標記
            output_cnt<=output_cnt; out_data_d<=out_data_d; 
            met_full_tag<=1;    full_cnt<=full_cnt+1;
        end
        else begin                    //0 1 2 都保持不變
            output_cnt<=output_cnt+1; out_data_d<=x_arr[output_cnt]; 
            met_full_tag<=0;    full_cnt<=0;
        end
    end
    else begin
        output_cnt<=8'd0; out_data_d<=16'd0; met_full_tag<=0; full_cnt<=0;          
    end
end

always@(*)begin
    if(cur_state==OUTPUT && output_cnt>=1 && output_cnt<=128 && fifo_full==0)begin
        //not full時才能傳下一筆
        out_valid=1'b1; out_data=out_data_d;    
    end
    else begin
        out_valid=1'b0; out_data=16'd0;                  
    end
end

endmodule

// module montgomery_mult_16 (
//     input  [15:0] A,
//     input  [15:0] B,
//     output [15:0] R_out
// );
//     // Step 1: x = A * B
//     wire [31:0] x; 
//     assign x= A * B;

//     // Step 2: y = (x * Q0I) mod R
//     wire [31:0] xQ0I;
//     assign xQ0I = x[15:0] * 12287;  //Q0I
//     wire [15:0] y;
//     assign y = xQ0I[15:0];

//     // Step 3: z = (x + y * Q) / R
//     wire [31:0] yQ;
//     assign yQ= y * 12289;
//     wire [31:0] z_temp; 
//     assign z_temp= x + yQ;
//     wire [15:0] z; 
//     assign z= z_temp[31:16];    // / R

//     // Step 4: if (z >= Q) return z - Q else return z   (Q=12289)
//     assign R_out = (z >= 12289) ? (z - 12289) : z;
// endmodule

module montgomery_mult_part1 (
    input  [15:0] A,
    input  [15:0] B,
    output [31:0] x,
    output [15:0] y
);
    // Step 1: x = A * B
    assign x = A * B;

    // Step 2: y = (x * Q0I) mod R
    wire [31:0] xQ0I;
    assign xQ0I = x[15:0] * 12287;  // Q0I
    assign y = xQ0I[15:0];
endmodule

module montgomery_mult_part2 (
    input  [31:0] x,
    input  [15:0] y,
    output [15:0] R_out
);
    // Step 3: z = (x + y * Q) / R
    wire [31:0] yQ;
    assign yQ = y * 12289;  // Q
    wire [31:0] z_temp;
    assign z_temp = x + yQ;
    wire [15:0] z;
    assign z = z_temp[31:16];  // / R

    // Step 4: if (z >= Q) return z - Q else return z (Q = 12289)
    assign R_out = (z >= 12289) ? (z - 12289) : z;
endmodule

module u_plus_v_mod_Q (
    input  wire [15:0] A,
    input  wire [15:0] B,
    output reg  [15:0] out
);
    // Q = 12289; sum 最大 131070 -> 17 bits 足夠
    reg [16:0] sum;
    always@(*)begin
        sum = A + B;
    end

    always @(*) begin
        if (sum < 17'd12289)      out= sum;
        else if(sum < 17'd24578)  out= sum-17'd12289;
        else if(sum < 17'd36867)  out= sum-17'd24578;
        else if(sum < 17'd49156)  out= sum-17'd36867;
        else if(sum < 17'd61445)  out= sum-17'd49156;
        else if(sum < 17'd73734)  out= sum-17'd61445;
        else if(sum < 17'd86023)  out= sum-17'd73734; 
        else if(sum < 17'd98312)  out= sum-17'd86023;
        else if(sum < 17'd110601) out= sum-17'd98312;
        else if(sum < 17'd122890) out= sum-17'd110601;
        else                      out= sum-17'd122890;
    end
endmodule

module u_minus_v_mod_Q (
    input  wire [15:0] A,
    input  wire [15:0] B,
    output reg  [15:0] out
);
    always@(*)begin
        if(A>=B) out=A-B;
        else out=12289+A-B;
    end
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
        output_cnt<=8'd0;
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
    else begin
        out_valid<=1'b0; out_data<=16'd0;
        output_cnt<=8'd0;
    end
end

endmodule