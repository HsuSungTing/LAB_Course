module GTE(
    // input signals
    clk,rst_n,in_valid_data,data,in_valid_cmd,cmd,    
    // output signals
    busy
);

input              clk;
input              rst_n;
input              in_valid_data;
input       [7:0]  data;
input              in_valid_cmd;
input      [17:0]  cmd;
output reg         busy;

// MEM_0, MEM_1, MEM_2, MEM_3: 8-bit width, 4096 depth
wire        mem0_web, mem1_web, mem2_web, mem3_web;
wire [11:0] mem0_addr, mem1_addr, mem2_addr, mem3_addr;
wire  [7:0] mem0_din, mem1_din, mem2_din, mem3_din;
wire  [7:0] mem0_dout, mem1_dout, mem2_dout, mem3_dout;

// MEM_4, MEM_5: 16-bit width, 2048 depth
wire        mem4_web, mem5_web;
wire [10:0] mem4_addr, mem5_addr;
wire [15:0] mem4_din, mem5_din;
wire [15:0] mem4_dout, mem5_dout;

// MEM_6, MEM_7: 32-bit width, 1024 depth
wire        mem6_web, mem7_web;
wire  [9:0] mem6_addr, mem7_addr;
wire [31:0] mem6_din, mem7_din;
wire [31:0] mem6_dout, mem7_dout;

//Part 1: FSM (FSM Tag)
reg [3:0] cur_state, next_state;

parameter IDLE=4'd0, INPUT_1=4'd1, WAIT_INPUT_2=4'd2; 
parameter EVAL_sram_read=4'd4, EVAL=4'd4, EVAL_sram_write=4'd5;
parameter OUTPUT=4'd6, CLEAR=4'd7;

reg [15:0] INPUT_1_cnt;	//FSM tag

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
        IDLE: begin
            if(in_valid_data==1'b1) next_state=INPUT_1;
            else next_state=IDLE;
        end
        INPUT_1: begin  
            if(INPUT_1_cnt>=32768)next_state=WAIT_INPUT_2;
            else next_state=INPUT_1;
        end
        WAIT_INPUT_2: begin
            if(in_valid_cmd==1'b1) next_state=EVAL_sram_read;
            else next_state=WAIT_INPUT_2;
        end
        EVAL_sram_read: begin
            
        end
		EVAL: begin
            
        end
        EVAL_sram_write: begin
            
        end
        
        OUTPUT: next_state=CLEAR;
        CLEAR: next_state=WAIT_INPUT_2;               
        default: next_state=WAIT_INPUT_2;
    endcase
end

//Part 3 Seq Logic INPUT_1: write_sram
integer i,j,k;
reg WEB_arr [0:7];	//一次只會對一個sram寫入(其他都是1)
reg [3:0] read_sram_idx, read_sram_row, read_sram_col;
reg [1:0] write_sram_2048_cnt, write_sram_1024_cnt;
reg [11:0] sram_4096_write_addr;
reg [7:0] sram_4096_write_din;

reg [10:0] sram_2048_write_addr;
reg [15:0] sram_2048_write_din;

reg [9:0] sram_1024_write_addr;
reg [31:0] sram_1024_write_din;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		//sram control cnt
		INPUT_1_cnt<=0;
		read_sram_idx<=0; read_sram_row<=0; read_sram_col<=0;
		//sram addr, din, WEB
		for(i=0;i<8;i=i+1)WEB_arr[i]<=1;	//read
		sram_4096_write_addr<=0; sram_4096_write_din<=0;
		sram_2048_write_addr<=0; sram_2048_write_din<=0;
		write_sram_2048_cnt<=0;
		sram_1024_write_addr<=0; sram_1024_write_din<=0;
		write_sram_1024_cnt<=0;
	end
	else if(in_valid_data==1'b1 || cur_state==INPUT_1)begin
		//update idx, row, col
		INPUT_1_cnt<=INPUT_1_cnt+1;
		if(read_sram_row==15&&read_sram_col==15)begin
			read_sram_idx<=read_sram_idx+1;
			read_sram_row<=0;	read_sram_col<=0;
		end
		else if(read_sram_col==15)begin
			read_sram_idx<=read_sram_idx;
			read_sram_row<=read_sram_row+1; read_sram_col<=0;
		end
		else begin
			read_sram_idx<=read_sram_idx;
			read_sram_row<=read_sram_row; read_sram_col<=read_sram_col+1;
		end

		//case 0 write to sram 0~3
		if(read_sram_idx>=0&&read_sram_idx<=3)begin	//每次存
			//step 1 WEB
			for(i=0;i<7;i=i+1)begin
				if(i==read_sram_idx) WEB_arr[i]<=0;
				else WEB_arr[i]<=1;
			end
			//step 2 din & cnt & addr
			sram_4096_write_addr<= {read_sram_idx, read_sram_row, read_sram_col};
			sram_4096_write_din<=data;
		end
		//case 1 write to sram 4~5
		else if(read_sram_idx==4 || read_sram_idx==5)begin//累計2個才能存一次
			//case 1-0: 在儲存的過程不能寫入
			if(write_sram_2048_cnt==0)begin
				//step 1 WEB
				for(i=0;i<7;i=i+1)WEB_arr[i]<=1;
				//step 2 din & cnt & addr
				write_sram_2048_cnt<=1;
				sram_2048_write_addr<=sram_2048_write_addr;
				sram_2048_write_din<={data,8'd0};
			end
			//case 1-1: 可以寫入
			else begin
				//step 1 WEB
				for(i=0;i<7;i=i+1)begin
					if(i==read_sram_idx) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				//step 2 din & cnt & addr
				write_sram_2048_cnt<=0;
				//要和大佬核對
				sram_2048_write_addr<={read_sram_idx-64, read_sram_row, read_sram_col[3:1]};
				sram_2048_write_din<={sram_2048_write_din[15:8],data};
			end
		end
		//case 2 write to sram 6~7
		else if(read_sram_idx==6 || read_sram_idx==7)begin	//累計4個才能存一次
			//case 1-0: 在儲存的過程不能寫入
			if(write_sram_1024_cnt==0 || write_sram_1024_cnt==1 ||write_sram_1024_cnt==2)begin
				//step 1 WEB
				for(i=0;i<7;i=i+1) WEB_arr[i]<=1;
				//step 2 din & cnt & addr
				write_sram_1024_cnt<=write_sram_1024_cnt+1;
				sram_1024_write_addr<=sram_1024_write_addr;
				if(write_sram_1024_cnt==0)sram_1024_write_din<={data,24'd0};
				else if(write_sram_1024_cnt==1)sram_1024_write_din<={sram_1024_write_din[31:24],data,16'd0};
				else if(write_sram_1024_cnt==2)sram_1024_write_din<={sram_1024_write_din[31:16],data,8'd0};
			end
			//case 1-1: 可以寫入
			else begin
				//step 1 WEB
				for(i=0;i<7;i=i+1)begin
					if(i==read_sram_idx) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				//step 2 din & cnt
				write_sram_1024_cnt<=0;
				//要和大佬核對
				sram_1024_write_addr<= {read_sram_idx-96, read_sram_row, read_sram_col[3:2]};
				sram_1024_write_din<={sram_1024_write_din[31:8],data};
			end
		end
	end
	else if(cur_state==CLEAR)begin
		//sram control cnt
		INPUT_1_cnt<=0;
		read_sram_idx<=0; read_sram_row<=0; read_sram_col<=0;
		//sram addr, din, WEB
		for(i=0;i<8;i=i+1)WEB_arr[i]<=1;	//read
		sram_4096_write_addr<=0; sram_4096_write_din<=0;
		sram_2048_write_addr<=0; sram_2048_write_din<=0;
		write_sram_2048_cnt<=0;
		sram_1024_write_addr<=0; sram_1024_write_din<=0;
		write_sram_1024_cnt<=0;
	end
end

assign mem0_addr = sram_4096_write_addr;	//之後有Read要再接read的
assign mem0_web  = WEB_arr[0];
assign mem0_din  = sram_4096_write_din;

assign mem1_addr = sram_4096_write_addr;
assign mem1_web  = WEB_arr[1];
assign mem1_din  = sram_4096_write_din;

assign mem2_addr = sram_4096_write_addr;
assign mem2_web  = WEB_arr[2];
assign mem2_din  = sram_4096_write_din;

assign mem3_addr = sram_4096_write_addr;
assign mem3_web  = WEB_arr[3];
assign mem3_din  = sram_4096_write_din;

assign mem4_addr = sram_2048_write_addr;
assign mem4_web  = WEB_arr[4];
assign mem4_din  = sram_2048_write_din;

assign mem5_addr = sram_2048_write_addr;
assign mem5_web  = WEB_arr[5];
assign mem5_din  = sram_2048_write_din;

assign mem6_addr = sram_1024_write_addr;
assign mem6_web  = WEB_arr[6];
assign mem6_din  = sram_1024_write_din;

assign mem7_addr = sram_1024_write_addr;
assign mem7_web  = WEB_arr[7];
assign mem7_din  = sram_1024_write_din;


// MEM_0, MEM_1, MEM_2, MEM_3, MEM_4, MEM_5, MEM_6, MEM_7 instantiation
SUMA180_4096X8X1BM4 MEM0(
    .A0(mem0_addr[0]), .A1(mem0_addr[1]), .A2(mem0_addr[2]), .A3(mem0_addr[3]), .A4(mem0_addr[4]), .A5(mem0_addr[5]), .A6(mem0_addr[6]), .A7(mem0_addr[7]), 
    .A8(mem0_addr[8]), .A9(mem0_addr[9]), .A10(mem0_addr[10]), .A11(mem0_addr[11]),
    .DO0(mem0_dout[0]), .DO1(mem0_dout[1]), .DO2(mem0_dout[2]), .DO3(mem0_dout[3]), .DO4(mem0_dout[4]), .DO5(mem0_dout[5]), .DO6(mem0_dout[6]), .DO7(mem0_dout[7]),
    .DI0(mem0_din[0]), .DI1(mem0_din[1]), .DI2(mem0_din[2]), .DI3(mem0_din[3]), .DI4(mem0_din[4]), .DI5(mem0_din[5]), .DI6(mem0_din[6]), .DI7(mem0_din[7]),
    .CK(clk), .WEB(mem0_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM1(
    .A0(mem1_addr[0]), .A1(mem1_addr[1]), .A2(mem1_addr[2]), .A3(mem1_addr[3]), .A4(mem1_addr[4]), .A5(mem1_addr[5]), .A6(mem1_addr[6]), .A7(mem1_addr[7]), 
    .A8(mem1_addr[8]), .A9(mem1_addr[9]), .A10(mem1_addr[10]), .A11(mem1_addr[11]),
    .DO0(mem1_dout[0]), .DO1(mem1_dout[1]), .DO2(mem1_dout[2]), .DO3(mem1_dout[3]), .DO4(mem1_dout[4]), .DO5(mem1_dout[5]), .DO6(mem1_dout[6]), .DO7(mem1_dout[7]),
    .DI0(mem1_din[0]), .DI1(mem1_din[1]), .DI2(mem1_din[2]), .DI3(mem1_din[3]), .DI4(mem1_din[4]), .DI5(mem1_din[5]), .DI6(mem1_din[6]), .DI7(mem1_din[7]),
    .CK(clk), .WEB(mem1_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM2 (
    .A0(mem2_addr[0]), .A1(mem2_addr[1]), .A2(mem2_addr[2]), .A3(mem2_addr[3]), .A4(mem2_addr[4]), .A5(mem2_addr[5]), .A6(mem2_addr[6]), .A7(mem2_addr[7]),
    .A8(mem2_addr[8]), .A9(mem2_addr[9]), .A10(mem2_addr[10]), .A11(mem2_addr[11]),
    .DO0(mem2_dout[0]), .DO1(mem2_dout[1]), .DO2(mem2_dout[2]), .DO3(mem2_dout[3]), .DO4(mem2_dout[4]), .DO5(mem2_dout[5]), .DO6(mem2_dout[6]), .DO7(mem2_dout[7]),
    .DI0(mem2_din[0]), .DI1(mem2_din[1]), .DI2(mem2_din[2]), .DI3(mem2_din[3]), .DI4(mem2_din[4]), .DI5(mem2_din[5]), .DI6(mem2_din[6]), .DI7(mem2_din[7]),
    .CK(clk), .WEB(mem2_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_4096X8X1BM4 MEM3(
    .A0(mem3_addr[0]), .A1(mem3_addr[1]), .A2(mem3_addr[2]), .A3(mem3_addr[3]), .A4(mem3_addr[4]), .A5(mem3_addr[5]), .A6(mem3_addr[6]), .A7(mem3_addr[7]), 
    .A8(mem3_addr[8]), .A9(mem3_addr[9]), .A10(mem3_addr[10]), .A11(mem3_addr[11]),
    .DO0(mem3_dout[0]), .DO1(mem3_dout[1]), .DO2(mem3_dout[2]), .DO3(mem3_dout[3]), .DO4(mem3_dout[4]), .DO5(mem3_dout[5]), .DO6(mem3_dout[6]), .DO7(mem3_dout[7]),
    .DI0(mem3_din[0]), .DI1(mem3_din[1]), .DI2(mem3_din[2]), .DI3(mem3_din[3]), .DI4(mem3_din[4]), .DI5(mem3_din[5]), .DI6(mem3_din[6]), .DI7(mem3_din[7]),
    .CK(clk), .WEB(mem3_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_2048X16X1BM1 MEM4(
	.A0(mem4_addr[0]), .A1(mem4_addr[1]), .A2(mem4_addr[2]), .A3(mem4_addr[3]), .A4(mem4_addr[4]), .A5(mem4_addr[5]), .A6(mem4_addr[6]), .A7(mem4_addr[7]), 
	.A8(mem4_addr[8]), .A9(mem4_addr[9]), .A10(mem4_addr[10]),
	.DO0(mem4_dout[0]), .DO1(mem4_dout[1]), .DO2(mem4_dout[2]), .DO3(mem4_dout[3]), .DO4(mem4_dout[4]), .DO5(mem4_dout[5]), .DO6(mem4_dout[6]), .DO7(mem4_dout[7]), 
	.DO8(mem4_dout[8]), .DO9(mem4_dout[9]), .DO10(mem4_dout[10]), .DO11(mem4_dout[11]), .DO12(mem4_dout[12]), .DO13(mem4_dout[13]), .DO14(mem4_dout[14]), .DO15(mem4_dout[15]),
	.DI0(mem4_din[0]), .DI1(mem4_din[1]), .DI2(mem4_din[2]), .DI3(mem4_din[3]), .DI4(mem4_din[4]), .DI5(mem4_din[5]), .DI6(mem4_din[6]), .DI7(mem4_din[7]), 
	.DI8(mem4_din[8]), .DI9(mem4_din[9]), .DI10(mem4_din[10]), .DI11(mem4_din[11]), .DI12(mem4_din[12]), .DI13(mem4_din[13]), .DI14(mem4_din[14]), .DI15(mem4_din[15]),
	.CK(clk), .WEB(mem4_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_2048X16X1BM1 MEM5(
	.A0(mem5_addr[0]), .A1(mem5_addr[1]), .A2(mem5_addr[2]), .A3(mem5_addr[3]), .A4(mem5_addr[4]), .A5(mem5_addr[5]), .A6(mem5_addr[6]), .A7(mem5_addr[7]), 
	.A8(mem5_addr[8]), .A9(mem5_addr[9]), .A10(mem5_addr[10]),
	.DO0(mem5_dout[0]), .DO1(mem5_dout[1]), .DO2(mem5_dout[2]), .DO3(mem5_dout[3]), .DO4(mem5_dout[4]), .DO5(mem5_dout[5]), .DO6(mem5_dout[6]), .DO7(mem5_dout[7]), 
	.DO8(mem5_dout[8]), .DO9(mem5_dout[9]), .DO10(mem5_dout[10]), .DO11(mem5_dout[11]), .DO12(mem5_dout[12]), .DO13(mem5_dout[13]), .DO14(mem5_dout[14]), .DO15(mem5_dout[15]),
	.DI0(mem5_din[0]), .DI1(mem5_din[1]), .DI2(mem5_din[2]), .DI3(mem5_din[3]), .DI4(mem5_din[4]), .DI5(mem5_din[5]), .DI6(mem5_din[6]), .DI7(mem5_din[7]), 
	.DI8(mem5_din[8]), .DI9(mem5_din[9]), .DI10(mem5_din[10]), .DI11(mem5_din[11]), .DI12(mem5_din[12]), .DI13(mem5_din[13]), .DI14(mem5_din[14]), .DI15(mem5_din[15]),
	.CK(clk), .WEB(mem5_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_1024X32X1BM2 MEM6(
	.A0(mem6_addr[0]), .A1(mem6_addr[1]), .A2(mem6_addr[2]), .A3(mem6_addr[3]), .A4(mem6_addr[4]), .A5(mem6_addr[5]), .A6(mem6_addr[6]), .A7(mem6_addr[7]), 
	.A8(mem6_addr[8]), .A9(mem6_addr[9]),
	.DO0(mem6_dout[0]), .DO1(mem6_dout[1]), .DO2(mem6_dout[2]), .DO3(mem6_dout[3]), .DO4(mem6_dout[4]), .DO5(mem6_dout[5]), .DO6(mem6_dout[6]), .DO7(mem6_dout[7]), 
	.DO8(mem6_dout[8]), .DO9(mem6_dout[9]), .DO10(mem6_dout[10]), .DO11(mem6_dout[11]), .DO12(mem6_dout[12]), .DO13(mem6_dout[13]), .DO14(mem6_dout[14]), .DO15(mem6_dout[15]), 
	.DO16(mem6_dout[16]), .DO17(mem6_dout[17]), .DO18(mem6_dout[18]), .DO19(mem6_dout[19]), .DO20(mem6_dout[20]), .DO21(mem6_dout[21]), .DO22(mem6_dout[22]), .DO23(mem6_dout[23]), 
	.DO24(mem6_dout[24]), .DO25(mem6_dout[25]), .DO26(mem6_dout[26]), .DO27(mem6_dout[27]), .DO28(mem6_dout[28]), .DO29(mem6_dout[29]), .DO30(mem6_dout[30]), .DO31(mem6_dout[31]),
	.DI0(mem6_din[0]), .DI1(mem6_din[1]), .DI2(mem6_din[2]), .DI3(mem6_din[3]), .DI4(mem6_din[4]), .DI5(mem6_din[5]), .DI6(mem6_din[6]), .DI7(mem6_din[7]), 
	.DI8(mem6_din[8]), .DI9(mem6_din[9]), .DI10(mem6_din[10]), .DI11(mem6_din[11]), .DI12(mem6_din[12]), .DI13(mem6_din[13]), .DI14(mem6_din[14]), .DI15(mem6_din[15]), 
	.DI16(mem6_din[16]), .DI17(mem6_din[17]), .DI18(mem6_din[18]), .DI19(mem6_din[19]), .DI20(mem6_din[20]), .DI21(mem6_din[21]), .DI22(mem6_din[22]), .DI23(mem6_din[23]), 
	.DI24(mem6_din[24]), .DI25(mem6_din[25]), .DI26(mem6_din[26]), .DI27(mem6_din[27]), .DI28(mem6_din[28]), .DI29(mem6_din[29]), .DI30(mem6_din[30]), .DI31(mem6_din[31]),
	.CK(clk), .WEB(mem6_web), .OE(1'b1), .CS(1'b1)
);

SUMA180_1024X32X1BM2 MEM7(
	.A0(mem7_addr[0]), .A1(mem7_addr[1]), .A2(mem7_addr[2]), .A3(mem7_addr[3]), .A4(mem7_addr[4]), .A5(mem7_addr[5]), .A6(mem7_addr[6]), .A7(mem7_addr[7]), 
	.A8(mem7_addr[8]), .A9(mem7_addr[9]),
	.DO0(mem7_dout[0]), .DO1(mem7_dout[1]), .DO2(mem7_dout[2]), .DO3(mem7_dout[3]), .DO4(mem7_dout[4]), .DO5(mem7_dout[5]), .DO6(mem7_dout[6]), .DO7(mem7_dout[7]), 
	.DO8(mem7_dout[8]), .DO9(mem7_dout[9]), .DO10(mem7_dout[10]), .DO11(mem7_dout[11]), .DO12(mem7_dout[12]), .DO13(mem7_dout[13]), .DO14(mem7_dout[14]), .DO15(mem7_dout[15]), 
	.DO16(mem7_dout[16]), .DO17(mem7_dout[17]), .DO18(mem7_dout[18]), .DO19(mem7_dout[19]), .DO20(mem7_dout[20]), .DO21(mem7_dout[21]), .DO22(mem7_dout[22]), .DO23(mem7_dout[23]), 
	.DO24(mem7_dout[24]), .DO25(mem7_dout[25]), .DO26(mem7_dout[26]), .DO27(mem7_dout[27]), .DO28(mem7_dout[28]), .DO29(mem7_dout[29]), .DO30(mem7_dout[30]), .DO31(mem7_dout[31]),
	.DI0(mem7_din[0]), .DI1(mem7_din[1]), .DI2(mem7_din[2]), .DI3(mem7_din[3]), .DI4(mem7_din[4]), .DI5(mem7_din[5]), .DI6(mem7_din[6]), .DI7(mem7_din[7]), 
	.DI8(mem7_din[8]), .DI9(mem7_din[9]), .DI10(mem7_din[10]), .DI11(mem7_din[11]), .DI12(mem7_din[12]), .DI13(mem7_din[13]), .DI14(mem7_din[14]), .DI15(mem7_din[15]), 
	.DI16(mem7_din[16]), .DI17(mem7_din[17]), .DI18(mem7_din[18]), .DI19(mem7_din[19]), .DI20(mem7_din[20]), .DI21(mem7_din[21]), .DI22(mem7_din[22]), .DI23(mem7_din[23]), 
	.DI24(mem7_din[24]), .DI25(mem7_din[25]), .DI26(mem7_din[26]), .DI27(mem7_din[27]), .DI28(mem7_din[28]), .DI29(mem7_din[29]), .DI30(mem7_din[30]), .DI31(mem7_din[31]),
	.CK(clk), .WEB(mem7_web), .OE(1'b1), .CS(1'b1)
);

endmodule