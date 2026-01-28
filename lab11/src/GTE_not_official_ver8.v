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
parameter EVAL_sram_read=4'd3, EVAL=4'd4, EVAL_sram_write=4'd5;
parameter OUTPUT=4'd6, CLEAR=4'd7;

reg [16:0] INPUT_1_cnt;	//FSM tag
reg [8:0] EVAL_sram_read_cnt,EVAL_sram_write_cnt;
reg [8:0] ms_sram_len;
reg [8:0] md_sram_len;

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
            if(INPUT_1_cnt>=32768) next_state=WAIT_INPUT_2;
            else next_state=INPUT_1;
        end
        WAIT_INPUT_2: begin
            if(in_valid_cmd==1'b1) next_state=EVAL_sram_read;
            else next_state=WAIT_INPUT_2;
        end
        EVAL_sram_read: begin
            if(EVAL_sram_read_cnt>=ms_sram_len+1) next_state=EVAL;
			else next_state=EVAL_sram_read;
        end
		EVAL: begin
            next_state=EVAL_sram_write;
        end
        EVAL_sram_write: begin
            if(EVAL_sram_write_cnt>=md_sram_len-1) next_state=OUTPUT;
			else next_state=EVAL_sram_write;
        end
        OUTPUT: next_state=CLEAR;
        CLEAR: next_state=WAIT_INPUT_2;               
        default: next_state=WAIT_INPUT_2;
    endcase
end

//Part 3 Seq Logic (take input)
reg [1:0] opcode_q, funct_q;
reg [6:0] ms_q, md_q;
reg [7:0] img_reg [0:15][0:15];
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		opcode_q<=0; funct_q<=0; ms_q<=0; md_q<=0;
	end
	else if(in_valid_cmd==1)begin
		opcode_q<=cmd[17:16]; funct_q<=cmd[15:14]; 
		ms_q<=cmd[13:7]; md_q<=cmd[6:0];
	end
	else if(cur_state==CLEAR)begin
		opcode_q<=0; funct_q<=0; ms_q<=0; md_q<=0;
	end
end

//Part 3 Seq Logic: read and write sram
integer i,j,m,n;
reg WEB_arr [0:7];	//一次只會對一個sram寫入(其他都是1)
//INPUT_1
reg [7:0] write_sram_idx; //0-127
reg [3:0] write_sram_row, write_sram_col;
reg [1:0] write_sram_2048_cnt, write_sram_1024_cnt;
//EVAL_sram_read
reg [3:0] read_sram_row, read_sram_col;
reg [3:0] read_sram_row_q, read_sram_col_q;
reg [3:0] read_sram_row_qq, read_sram_col_qq;
wire [6:0] mem_read_idx;			//Part 2 Comb Logic: EVAL_sram_read
reg [6:0] ms_mem_idx;				//Part 2 Comb Logic: EVAL_sram_read
//reg [8:0] ms_sram_len;			//Part 2 Comb Logic: EVAL_sram_read

//EVAL_sram_write
wire [6:0] mem_write_idx;			//Part 2 Comb Logic: EVAL_sram_write
reg [6:0] md_mem_idx;				//Part 2 Comb Logic: EVAL_sram_write
//reg [8:0] md_sram_len;

//Part 3 Seq: addr & din		
reg [11:0] sram_4096_addr;
reg [7:0] sram_4096_din;

reg [10:0] sram_2048_addr;
reg [15:0] sram_2048_din;

reg [9:0] sram_1024_addr;
reg [31:0] sram_1024_din;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		//INPUT_1 sram write
		INPUT_1_cnt<=0; 
		write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
		//EVAL_sram_read sram read
		EVAL_sram_read_cnt<=0; 
		read_sram_row<=0; read_sram_col<=0; 
		read_sram_row_q<=0; read_sram_col_q<=0;
		read_sram_row_qq<=0; read_sram_col_qq<=0;
		//EVAL_sram_write
		EVAL_sram_write_cnt<=0;
		//重複使用write_sram_row<=0; write_sram_col<=0;
		//sram addr, din, WEB
		for(i=0;i<8;i=i+1) WEB_arr[i]<=1;	//read
		sram_4096_addr<=0; sram_4096_din<=0;
		sram_2048_addr<=0; sram_2048_din<=0; write_sram_2048_cnt<=0;
		sram_1024_addr<=0; sram_1024_din<=0; write_sram_1024_cnt<=0;
	end
	//case 0: INPUT_1 sram write 
	else if(in_valid_data==1'b1 || cur_state==INPUT_1)begin
		//step 0 update idx, row, col
		INPUT_1_cnt<=INPUT_1_cnt+1;
		if(write_sram_row==15&&write_sram_col==15)begin
			write_sram_idx<=write_sram_idx+1;
			write_sram_row<=0;	write_sram_col<=0;
		end
		else if(write_sram_col==15)begin
			write_sram_idx<=write_sram_idx;
			write_sram_row<=write_sram_row+1; write_sram_col<=0;
		end
		else begin
			write_sram_idx<=write_sram_idx;
			write_sram_row<=write_sram_row; write_sram_col<=write_sram_col+1;
		end
		//step 1 din & cnt & addr
		if(write_sram_idx>=0&&write_sram_idx<=63)begin	//每次存
			if(write_sram_idx>=0 && write_sram_idx<=15)begin
				for(i=0;i<8;i=i+1)begin
					if(i==0) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				sram_4096_addr<= {write_sram_idx, write_sram_row, write_sram_col};
			end
			else if(write_sram_idx>=16 && write_sram_idx<=31)begin
				for(i=0;i<8;i=i+1)begin
					if(i==1) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				sram_4096_addr<= {write_sram_idx-16, write_sram_row, write_sram_col};
			end
			else if(write_sram_idx>=32 && write_sram_idx<=47)begin
				for(i=0;i<8;i=i+1)begin
					if(i==2) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				sram_4096_addr<= {write_sram_idx-32, write_sram_row, write_sram_col};
			end
			else if(write_sram_idx>=48 && write_sram_idx<=63)begin
				for(i=0;i<8;i=i+1)begin
					if(i==3) WEB_arr[i]<=0;
					else WEB_arr[i]<=1;
				end
				sram_4096_addr<= {write_sram_idx-48, write_sram_row, write_sram_col};
			end
			//step 2 din
			sram_4096_din<=data;
		end
		//case 1 write to sram 4~5
		else if(write_sram_idx>=64 && write_sram_idx<=95)begin//累計2個才能存一次
			//case 1-0: 在儲存的過程不能寫入
			if(write_sram_2048_cnt==0)begin
				//step 1 WEB
				for(i=0;i<8;i=i+1)WEB_arr[i]<=1;
				//step 2 din & cnt & addr
				write_sram_2048_cnt<=1;
				sram_2048_addr<=sram_2048_addr;
				sram_2048_din<={data,8'd0};
			end
			//case 1-1: 可以寫入
			else begin
				//step 1 WEB & addr
				if(write_sram_idx>=64 && write_sram_idx<=79)begin
					for(i=0;i<8;i=i+1)begin
						if(i==4) WEB_arr[i]<=0;
						else WEB_arr[i]<=1;
					end
					sram_2048_addr<={write_sram_idx-64, write_sram_row, write_sram_col[3:1]};
				end
				else if(write_sram_idx>=80 && write_sram_idx<=95)begin
					for(i=0;i<8;i=i+1)begin
						if(i==5) WEB_arr[i]<=0;
						else WEB_arr[i]<=1;
					end
					sram_2048_addr<={write_sram_idx-80, write_sram_row, write_sram_col[3:1]};
				end
				//step 2 din & cnt & addr
				write_sram_2048_cnt<=0;
				sram_2048_din<={sram_2048_din[15:8],data};	//要和大佬核對
			end
		end
		//case 2 write to sram 6~7
		else if(write_sram_idx>=96 && write_sram_idx<=127)begin	//累計4個才能存一次
			//case 1-0: 在儲存的過程不能寫入
			if(write_sram_1024_cnt==0 || write_sram_1024_cnt==1 ||write_sram_1024_cnt==2)begin
				//step 1 WEB
				for(i=0;i<8;i=i+1) WEB_arr[i]<=1;
				//step 2 din & cnt & addr
				write_sram_1024_cnt<=write_sram_1024_cnt+1;
				sram_1024_addr<=sram_1024_addr;
				if(write_sram_1024_cnt==0)sram_1024_din<={data,24'd0};
				else if(write_sram_1024_cnt==1)sram_1024_din<={sram_1024_din[31:24],data,16'd0};
				else if(write_sram_1024_cnt==2)sram_1024_din<={sram_1024_din[31:16],data,8'd0};
			end
			//case 1-1: 可以寫入
			else begin
				//step 1 WEB
				if(write_sram_idx>=96 && write_sram_idx<=111)begin
					for(i=0;i<8;i=i+1)begin
						if(i==6) WEB_arr[i]<=0;
						else WEB_arr[i]<=1;
					end
					sram_1024_addr<= {write_sram_idx-96, write_sram_row, write_sram_col[3:2]};
				end
				else if(write_sram_idx>=112 && write_sram_idx<=127)begin
					for(i=0;i<8;i=i+1)begin
						if(i==7) WEB_arr[i]<=0;
						else WEB_arr[i]<=1;
					end
					sram_1024_addr<= {write_sram_idx-112, write_sram_row, write_sram_col[3:2]};
				end
				//step 2 din & cnt
				write_sram_1024_cnt<=0;
				sram_1024_din<={sram_1024_din[31:8],data};	//要和大佬核對
			end
		end
	end
	//case 1: EVAL_sram_read sram raed
	else if(cur_state==EVAL_sram_read)begin
		//要確定 read_sram_idx<=mem_read_idx;	//ex: 113-7*16=1	
		//ms_sram_len 256 or 128 or 64
		EVAL_sram_read_cnt<=EVAL_sram_read_cnt+1;
		//step 0: address cnt (因為會晚兩拍)
		read_sram_row_q<=read_sram_row; 	read_sram_col_q<=read_sram_col;
		read_sram_row_qq<=read_sram_row_q; 	read_sram_col_qq<=read_sram_col_q;
		if(EVAL_sram_read_cnt>=0 && EVAL_sram_read_cnt<=ms_sram_len-1)begin
			//case 0: 一次讀一個
			if(ms_mem_idx>=0 && ms_mem_idx<=3)begin
				if(read_sram_col==15)begin
					read_sram_row<=read_sram_row+1; read_sram_col<=0;
				end
				else begin
					read_sram_row<=read_sram_row; 	read_sram_col<=read_sram_col+1;
				end
			end
			else if(ms_mem_idx==4 || ms_mem_idx==5)begin
				if(read_sram_col==14)begin
					read_sram_row<=read_sram_row+1; read_sram_col<=0;
				end
				else begin
					read_sram_row<=read_sram_row; 	read_sram_col<=read_sram_col+2;
				end
			end
			else if(ms_mem_idx==6 || ms_mem_idx==7)begin
				if(read_sram_col==12)begin
					read_sram_row<=read_sram_row+1; read_sram_col<=0;
				end
				else begin
					read_sram_row<=read_sram_row; 	read_sram_col<=read_sram_col+4;
				end
			end
		end
		//step 1 送入WEB & addr
		if(EVAL_sram_read_cnt>=0 && EVAL_sram_read_cnt<=ms_sram_len-1)begin
			for(i=0;i<8;i=i+1) WEB_arr[i]<=1;	//就是read而已
			//mem_read_idx=ms_q-(ms_mem_idx<<4);
			//case 0 一次寫一個data
			if(ms_mem_idx>=0 && ms_mem_idx<=3)begin
				sram_4096_addr<={mem_read_idx,read_sram_row,read_sram_col};
			end
			//case 1 一次寫兩個data
			else if(ms_mem_idx==4 || ms_mem_idx==5)begin
				sram_2048_addr<={mem_read_idx,read_sram_row,read_sram_col[3:1]};
			end
			//case 2 一次寫四個data
			else if(ms_mem_idx==6 || ms_mem_idx==7)begin
				sram_1024_addr<={mem_read_idx,read_sram_row,read_sram_col[3:2]};
			end
		end
		//step 2 接收sram data 
	end
	//case 2: EVAL
	else if(cur_state==EVAL)begin
		write_sram_row<=0; write_sram_col<=0;	//for EVAL_sram_write
	end
	//case 3: EVAL_sram_write
	else if(cur_state==EVAL_sram_write)begin
		EVAL_sram_write_cnt<=EVAL_sram_write_cnt+1;
		//step 0 update cnt
		if(md_mem_idx>=0 && md_mem_idx<=3)begin
			//case 0 每次累加1
			if(write_sram_col==15)begin
				write_sram_row<=write_sram_row+1; write_sram_col<=0;
			end
			else begin
				write_sram_row<=write_sram_row;   write_sram_col<=write_sram_col+1;
			end
		end
		else if(md_mem_idx==4 || md_mem_idx==5)begin
			//case 1 每次累加2
			if(write_sram_col==14)begin
				write_sram_row<=write_sram_row+1; write_sram_col<=0;
			end
			else begin
				write_sram_row<=write_sram_row;   write_sram_col<=write_sram_col+2;
			end
		end
		else if(md_mem_idx==6 || md_mem_idx==7)begin
			//case 2 每次累加4
			if(write_sram_col==12)begin
				write_sram_row<=write_sram_row+1; write_sram_col<=0;
			end
			else begin
				write_sram_row<=write_sram_row;   write_sram_col<=write_sram_col+4;
			end
		end

		//step 1 送入WEB & addr
		if(md_mem_idx>=0 && md_mem_idx<=3)begin
			//case 0 一次寫一個data
			for(i=0;i<8;i=i+1)begin
				//只對需要寫入的mem寫入,只會有一個
				if(i==md_mem_idx) WEB_arr[i]<=0;
				else WEB_arr[i]<=1;
			end
			sram_4096_din<= img_reg[write_sram_row][write_sram_col];
			sram_4096_addr<={mem_write_idx, write_sram_row, write_sram_col};
		end
		else if(md_mem_idx==4 || md_mem_idx==5)begin
			//case 1 一次寫兩個data
			for(i=0;i<8;i=i+1)begin
				//只對需要寫入的mem寫入,只會有一個
				if(i==md_mem_idx) WEB_arr[i]<=0;
				else WEB_arr[i]<=1;
			end
			sram_2048_din<= {img_reg[write_sram_row][write_sram_col],img_reg[write_sram_row][write_sram_col+1]};
			sram_2048_addr<={mem_write_idx, write_sram_row, write_sram_col[3:1]};
		end
		else if(md_mem_idx==6 || md_mem_idx==7)begin
			//case 2 一次寫四個data
			for(i=0;i<8;i=i+1)begin
				//只對需要寫入的mem寫入,只會有一個
				if(i==md_mem_idx) WEB_arr[i]<=0;
				else WEB_arr[i]<=1;
			end
			sram_1024_din<= {img_reg[write_sram_row][write_sram_col],img_reg[write_sram_row][write_sram_col+1]
							,img_reg[write_sram_row][write_sram_col+2],img_reg[write_sram_row][write_sram_col+3]};
			sram_1024_addr<={mem_write_idx, write_sram_row, write_sram_col[3:2]};
		end
	end
	else if(cur_state==CLEAR)begin
		//INPUT_1 sram write
		INPUT_1_cnt<=0; 
		write_sram_idx<=0; write_sram_row<=0; write_sram_col<=0;
		//EVAL_sram_read sram read
		EVAL_sram_read_cnt<=0; 
		read_sram_row<=0; read_sram_col<=0; 
		read_sram_row_q<=0; read_sram_col_q<=0;
		read_sram_row_qq<=0; read_sram_col_qq<=0;
		//EVAL_sram_write
		EVAL_sram_write_cnt<=0;
		//重複使用write_sram_row<=0; write_sram_col<=0;
		//sram addr, din, WEB
		for(i=0;i<8;i=i+1) WEB_arr[i]<=1;	//read
		sram_4096_addr<=0; sram_4096_din<=0;
		sram_2048_addr<=0; sram_2048_din<=0; write_sram_2048_cnt<=0;
		sram_1024_addr<=0; sram_1024_din<=0; write_sram_1024_cnt<=0;
	end
end
//part 3 Seq Logic: OUTPUT
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		busy<=1;	//要被reset成1
	end
	else if(cur_state==OUTPUT)begin
		busy<=0;	
	end
	else begin
		busy<=1;
	end
end

//Part 3 Seq Logic: img_reg
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<16;i=i+1)begin
			for(j=0;j<16;j=j+1)begin
				img_reg[i][j]<=0;
			end
		end
	end
	//case 1: EVAL_sram_read sram raed
	else if(cur_state==EVAL_sram_read)begin
		//step 0: address cnt (因為會晚兩拍)
		//step 1 送入WEB & addr
		//step 2 接收sram data 
		if(EVAL_sram_read_cnt>=2&& EVAL_sram_read_cnt<=ms_sram_len+1)begin
			//case 0 一次read一個data
			if(ms_mem_idx>=0 && ms_mem_idx<=3)begin
				if(ms_mem_idx==0)img_reg[read_sram_row_qq][read_sram_col_qq]<=mem0_dout;
				else if(ms_mem_idx==1) img_reg[read_sram_row_qq][read_sram_col_qq]<=mem1_dout;
				else if(ms_mem_idx==2) img_reg[read_sram_row_qq][read_sram_col_qq]<=mem2_dout;
				else if(ms_mem_idx==3) img_reg[read_sram_row_qq][read_sram_col_qq]<=mem3_dout;
			end
			//case 1 一次read兩個data
			else if(ms_mem_idx==4 || ms_mem_idx==5)begin
				if(ms_mem_idx==4)begin
					img_reg[read_sram_row_qq][read_sram_col_qq]<=mem4_dout[15:8];
					img_reg[read_sram_row_qq][read_sram_col_qq+1]<=mem4_dout[7:0];
				end
				else if(ms_mem_idx==5)begin
					img_reg[read_sram_row_qq][read_sram_col_qq]<=mem5_dout[15:8];
					img_reg[read_sram_row_qq][read_sram_col_qq+1]<=mem5_dout[7:0];
				end
			end
			//case 2 一次read四個data
			else if(ms_mem_idx==6 || ms_mem_idx==7)begin
				if(ms_mem_idx==6)begin
					img_reg[read_sram_row_qq][read_sram_col_qq]  <=mem6_dout[31:24];
					img_reg[read_sram_row_qq][read_sram_col_qq+1]<=mem6_dout[23:16];
					img_reg[read_sram_row_qq][read_sram_col_qq+2]<=mem6_dout[15:8];
					img_reg[read_sram_row_qq][read_sram_col_qq+3]<=mem6_dout[7:0];
				end
				else begin
					img_reg[read_sram_row_qq][read_sram_col_qq]  <=mem7_dout[31:24];
					img_reg[read_sram_row_qq][read_sram_col_qq+1]<=mem7_dout[23:16];
					img_reg[read_sram_row_qq][read_sram_col_qq+2]<=mem7_dout[15:8];
					img_reg[read_sram_row_qq][read_sram_col_qq+3]<=mem7_dout[7:0];
				end
			end
		end
	end
	else if(cur_state==EVAL)begin
		case({opcode_q,funct_q})
			4'b0000:begin	//Mirror X (對x方向鏡射)
				for(i=0;i<8;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[i][j]<=img_reg[15-i][j];
						img_reg[15-i][j]<=img_reg[i][j];
					end
				end
			end
			4'b0001:begin	//Mirror Y (對y方向鏡射)
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<8;j=j+1)begin
						img_reg[i][j]<=img_reg[i][15-j];
						img_reg[i][15-j]<=img_reg[i][j];
					end
				end
			end
			4'b0010:begin	//transpose
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[i][j]<=img_reg[j][i];
					end
				end
			end
			4'b0011:begin	//secondary transpose
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[i][j]<=img_reg[15-j][15-i];
					end
				end
			end
			4'b0100:begin	//順時針轉90度
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[j][15-i]<=img_reg[i][j];
					end
				end
			end
			4'b0101:begin	//順時針轉180度
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[15-i][15-j]<=img_reg[i][j];
					end
				end
			end
			4'b0110:begin	//順時針轉270度
				for(i=0;i<16;i=i+1)begin
					for(j=0;j<16;j=j+1)begin
						img_reg[15-j][i]<=img_reg[i][j];
					end
				end
			end
			4'b1000:begin	//right shift
				for(i=0;i<16;i=i+1)begin
					img_reg[i][0]<=img_reg[i][4];
					img_reg[i][1]<=img_reg[i][3];
					img_reg[i][2]<=img_reg[i][2];
					img_reg[i][3]<=img_reg[i][1];
					img_reg[i][4]<=img_reg[i][0];
					img_reg[i][5]<=img_reg[i][0];
					img_reg[i][6]<=img_reg[i][1];
					img_reg[i][7]<=img_reg[i][2];
					img_reg[i][8]<=img_reg[i][3];
					img_reg[i][9]<=img_reg[i][4];
					img_reg[i][10]<=img_reg[i][5];
					img_reg[i][11]<=img_reg[i][6];
					img_reg[i][12]<=img_reg[i][7];
					img_reg[i][13]<=img_reg[i][8];
					img_reg[i][14]<=img_reg[i][9];
					img_reg[i][15]<=img_reg[i][10];
				end
			end
			4'b1001:begin	//left shift
				for(i=0;i<16;i=i+1)begin
					img_reg[i][0]<=img_reg[i][5];
					img_reg[i][1]<=img_reg[i][6];
					img_reg[i][2]<=img_reg[i][7];
					img_reg[i][3]<=img_reg[i][8];
					img_reg[i][4]<=img_reg[i][9];
					img_reg[i][5]<=img_reg[i][10];
					img_reg[i][6]<=img_reg[i][11];
					img_reg[i][7]<=img_reg[i][12];
					img_reg[i][8]<=img_reg[i][13];
					img_reg[i][9]<=img_reg[i][14];
					img_reg[i][10]<=img_reg[i][15];
					img_reg[i][11]<=img_reg[i][15];
					img_reg[i][12]<=img_reg[i][14];
					img_reg[i][13]<=img_reg[i][13];
					img_reg[i][14]<=img_reg[i][12];
					img_reg[i][15]<=img_reg[i][11];
				end
			end
			4'b1010:begin	//up shift
				for(j=0;j<16;j=j+1)begin
					img_reg[0][j] <=img_reg[5][j];
					img_reg[1][j] <=img_reg[6][j];
					img_reg[2][j] <=img_reg[7][j];
					img_reg[3][j] <=img_reg[8][j];
					img_reg[4][j] <=img_reg[9][j];
					img_reg[5][j] <=img_reg[10][j];
					img_reg[6][j] <=img_reg[11][j];
					img_reg[7][j] <=img_reg[12][j];
					img_reg[8][j] <=img_reg[13][j];
					img_reg[9][j] <=img_reg[14][j];
					img_reg[10][j]<=img_reg[15][j];
					img_reg[11][j]<=img_reg[15][j];
					img_reg[12][j]<=img_reg[14][j];
					img_reg[13][j]<=img_reg[13][j];
					img_reg[14][j]<=img_reg[12][j];
					img_reg[15][j]<=img_reg[11][j];
				end
			end
			4'b1011:begin	//down shift
				for(j=0;j<16;j=j+1)begin
					img_reg[0][j] <=img_reg[4][j];
					img_reg[1][j] <=img_reg[3][j];
					img_reg[2][j] <=img_reg[2][j];
					img_reg[3][j] <=img_reg[1][j];
					img_reg[4][j] <=img_reg[0][j];
					img_reg[5][j] <=img_reg[0][j];
					img_reg[6][j] <=img_reg[1][j];
					img_reg[7][j] <=img_reg[2][j];
					img_reg[8][j] <=img_reg[3][j];
					img_reg[9][j] <=img_reg[4][j];
					img_reg[10][j]<=img_reg[5][j];
					img_reg[11][j]<=img_reg[6][j];
					img_reg[12][j]<=img_reg[7][j];
					img_reg[13][j]<=img_reg[8][j];
					img_reg[14][j]<=img_reg[9][j];
					img_reg[15][j]<=img_reg[10][j];
				end
			end
			4'b1100:begin	//ZZ4
				for(i=0;i<4;i=i+1)begin
					for(j=0;j<4;j=j+1)begin
						img_reg[4*i+0][4*j+0]<=img_reg[4*i+0][4*j+0];

						img_reg[4*i+0][4*j+1]<=img_reg[4*i+0][4*j+1];
						img_reg[4*i+0][4*j+2]<=img_reg[4*i+1][4*j+0];

						img_reg[4*i+0][4*j+3]<=img_reg[4*i+2][4*j+0];
						img_reg[4*i+1][4*j+0]<=img_reg[4*i+1][4*j+1];
						img_reg[4*i+1][4*j+1]<=img_reg[4*i+0][4*j+2];

						img_reg[4*i+1][4*j+2]<=img_reg[4*i+0][4*j+3];
						img_reg[4*i+1][4*j+3]<=img_reg[4*i+1][4*j+2];
    					img_reg[4*i+2][4*j+0]<=img_reg[4*i+2][4*j+1];
						img_reg[4*i+2][4*j+1]<=img_reg[4*i+3][4*j+0];

						img_reg[4*i+2][4*j+2]<=img_reg[4*i+3][4*j+1];
						img_reg[4*i+2][4*j+3]<=img_reg[4*i+2][4*j+2];
						img_reg[4*i+3][4*j+0]<=img_reg[4*i+1][4*j+3];

						img_reg[4*i+3][4*j+1]<=img_reg[4*i+2][4*j+3];
						img_reg[4*i+3][4*j+2]<=img_reg[4*i+3][4*j+2];

						img_reg[4*i+3][4*j+3]<=img_reg[4*i+3][4*j+3];
					end
				end
			end
			4'b1101:begin	//ZZ8
				for(i=0;i<2;i=i+1) begin
					for(j=0;j<2;j=j+1) begin
						// Row 0
						img_reg[8*i+0][8*j+0] <= img_reg[8*i+0][8*j+0];
						img_reg[8*i+0][8*j+1] <= img_reg[8*i+0][8*j+1];
						img_reg[8*i+0][8*j+2] <= img_reg[8*i+1][8*j+0];
						img_reg[8*i+0][8*j+3] <= img_reg[8*i+2][8*j+0];
						img_reg[8*i+0][8*j+4] <= img_reg[8*i+1][8*j+1];
						img_reg[8*i+0][8*j+5] <= img_reg[8*i+0][8*j+2];
						img_reg[8*i+0][8*j+6] <= img_reg[8*i+0][8*j+3];
						img_reg[8*i+0][8*j+7] <= img_reg[8*i+1][8*j+2];
						// Row 1
						img_reg[8*i+1][8*j+0] <= img_reg[8*i+2][8*j+1];
						img_reg[8*i+1][8*j+1] <= img_reg[8*i+3][8*j+0];
						img_reg[8*i+1][8*j+2] <= img_reg[8*i+4][8*j+0];
						img_reg[8*i+1][8*j+3] <= img_reg[8*i+3][8*j+1];
						img_reg[8*i+1][8*j+4] <= img_reg[8*i+2][8*j+2];
						img_reg[8*i+1][8*j+5] <= img_reg[8*i+1][8*j+3];
						img_reg[8*i+1][8*j+6] <= img_reg[8*i+0][8*j+4];
						img_reg[8*i+1][8*j+7] <= img_reg[8*i+0][8*j+5];
						// Row 2
						img_reg[8*i+2][8*j+0] <= img_reg[8*i+1][8*j+4];
						img_reg[8*i+2][8*j+1] <= img_reg[8*i+2][8*j+3];
						img_reg[8*i+2][8*j+2] <= img_reg[8*i+3][8*j+2];
						img_reg[8*i+2][8*j+3] <= img_reg[8*i+4][8*j+1];
						img_reg[8*i+2][8*j+4] <= img_reg[8*i+5][8*j+0];
						img_reg[8*i+2][8*j+5] <= img_reg[8*i+6][8*j+0];
						img_reg[8*i+2][8*j+6] <= img_reg[8*i+5][8*j+1];
						img_reg[8*i+2][8*j+7] <= img_reg[8*i+4][8*j+2];
						// Row 3
						img_reg[8*i+3][8*j+0] <= img_reg[8*i+3][8*j+3];
						img_reg[8*i+3][8*j+1] <= img_reg[8*i+2][8*j+4];
						img_reg[8*i+3][8*j+2] <= img_reg[8*i+1][8*j+5];
						img_reg[8*i+3][8*j+3] <= img_reg[8*i+0][8*j+6];
						img_reg[8*i+3][8*j+4] <= img_reg[8*i+0][8*j+7];
						img_reg[8*i+3][8*j+5] <= img_reg[8*i+1][8*j+6];
						img_reg[8*i+3][8*j+6] <= img_reg[8*i+2][8*j+5];
						img_reg[8*i+3][8*j+7] <= img_reg[8*i+3][8*j+4];
						// Row 4
						img_reg[8*i+4][8*j+0] <= img_reg[8*i+4][8*j+3];
						img_reg[8*i+4][8*j+1] <= img_reg[8*i+5][8*j+2];
						img_reg[8*i+4][8*j+2] <= img_reg[8*i+6][8*j+1];
						img_reg[8*i+4][8*j+3] <= img_reg[8*i+7][8*j+0];
						img_reg[8*i+4][8*j+4] <= img_reg[8*i+7][8*j+1];
						img_reg[8*i+4][8*j+5] <= img_reg[8*i+6][8*j+2];
						img_reg[8*i+4][8*j+6] <= img_reg[8*i+5][8*j+3];
						img_reg[8*i+4][8*j+7] <= img_reg[8*i+4][8*j+4];
						// Row 5
						img_reg[8*i+5][8*j+0] <= img_reg[8*i+3][8*j+5];
						img_reg[8*i+5][8*j+1] <= img_reg[8*i+2][8*j+6];
						img_reg[8*i+5][8*j+2] <= img_reg[8*i+1][8*j+7];
						img_reg[8*i+5][8*j+3] <= img_reg[8*i+2][8*j+7];
						img_reg[8*i+5][8*j+4] <= img_reg[8*i+3][8*j+6];
						img_reg[8*i+5][8*j+5] <= img_reg[8*i+4][8*j+5];
						img_reg[8*i+5][8*j+6] <= img_reg[8*i+5][8*j+4];
						img_reg[8*i+5][8*j+7] <= img_reg[8*i+6][8*j+3];
						// Row 6
						img_reg[8*i+6][8*j+0] <= img_reg[8*i+7][8*j+2];
						img_reg[8*i+6][8*j+1] <= img_reg[8*i+7][8*j+3];
						img_reg[8*i+6][8*j+2] <= img_reg[8*i+6][8*j+4];
						img_reg[8*i+6][8*j+3] <= img_reg[8*i+5][8*j+5];
						img_reg[8*i+6][8*j+4] <= img_reg[8*i+4][8*j+6];
						img_reg[8*i+6][8*j+5] <= img_reg[8*i+3][8*j+7];
						img_reg[8*i+6][8*j+6] <= img_reg[8*i+4][8*j+7];
						img_reg[8*i+6][8*j+7] <= img_reg[8*i+5][8*j+6];
						// Row 7
						img_reg[8*i+7][8*j+0] <= img_reg[8*i+6][8*j+5];
						img_reg[8*i+7][8*j+1] <= img_reg[8*i+7][8*j+4];
						img_reg[8*i+7][8*j+2] <= img_reg[8*i+7][8*j+5];
						img_reg[8*i+7][8*j+3] <= img_reg[8*i+6][8*j+6];
						img_reg[8*i+7][8*j+4] <= img_reg[8*i+5][8*j+7];
						img_reg[8*i+7][8*j+5] <= img_reg[8*i+6][8*j+7];
						img_reg[8*i+7][8*j+6] <= img_reg[8*i+7][8*j+6];
						img_reg[8*i+7][8*j+7] <= img_reg[8*i+7][8*j+7];
					end
				end
			end
			4'b1110:begin	//MO4
				for(i=0;i<4;i=i+1)begin
					for(j=0;j<4;j=j+1)begin
						img_reg[4*i+0][4*j+0]<=img_reg[4*i+0][4*j+0];
						img_reg[4*i+0][4*j+1]<=img_reg[4*i+0][4*j+1];
						img_reg[4*i+0][4*j+2]<=img_reg[4*i+1][4*j+0];
						img_reg[4*i+0][4*j+3]<=img_reg[4*i+1][4*j+1];

						img_reg[4*i+1][4*j+0]<=img_reg[4*i+0][4*j+2];
						img_reg[4*i+1][4*j+1]<=img_reg[4*i+0][4*j+3];
						img_reg[4*i+1][4*j+2]<=img_reg[4*i+1][4*j+2];
						img_reg[4*i+1][4*j+3]<=img_reg[4*i+1][4*j+3];

						img_reg[4*i+2][4*j+0]<=img_reg[4*i+2][4*j+0];
						img_reg[4*i+2][4*j+1]<=img_reg[4*i+2][4*j+1];
						img_reg[4*i+2][4*j+2]<=img_reg[4*i+3][4*j+0];
						img_reg[4*i+2][4*j+3]<=img_reg[4*i+3][4*j+1];
						
						img_reg[4*i+3][4*j+0]<=img_reg[4*i+2][4*j+2];
						img_reg[4*i+3][4*j+1]<=img_reg[4*i+2][4*j+3];
						img_reg[4*i+3][4*j+2]<=img_reg[4*i+3][4*j+2];
						img_reg[4*i+3][4*j+3]<=img_reg[4*i+3][4*j+3];
					end
				end
			end
			4'b1111:begin	//MO8
				for(m=0;m<2;m=m+1)begin
					for(n=0;n<2;n=n+1)begin
						for(i=0;i<2;i=i+1)begin
							for(j=0;j<2;j=j+1)begin
								img_reg[8*m+(4*i+2*j)+0][8*n+0+0] <= img_reg[8*m+4*i+0][8*n+4*j+0];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+1] <= img_reg[8*m+4*i+0][8*n+4*j+1];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+2] <= img_reg[8*m+4*i+1][8*n+4*j+0];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+3] <= img_reg[8*m+4*i+1][8*n+4*j+1];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+4] <= img_reg[8*m+4*i+0][8*n+4*j+2];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+5] <= img_reg[8*m+4*i+0][8*n+4*j+3];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+6] <= img_reg[8*m+4*i+1][8*n+4*j+2];
								img_reg[8*m+(4*i+2*j)+0][8*n+0+7] <= img_reg[8*m+4*i+1][8*n+4*j+3];
								
								img_reg[8*m+(4*i+2*j)+1][8*n+0+0] <= img_reg[8*m+4*i+2][8*n+4*j+0];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+1] <= img_reg[8*m+4*i+2][8*n+4*j+1];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+2] <= img_reg[8*m+4*i+3][8*n+4*j+0];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+3] <= img_reg[8*m+4*i+3][8*n+4*j+1];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+4] <= img_reg[8*m+4*i+2][8*n+4*j+2];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+5] <= img_reg[8*m+4*i+2][8*n+4*j+3];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+6] <= img_reg[8*m+4*i+3][8*n+4*j+2];
								img_reg[8*m+(4*i+2*j)+1][8*n+0+7] <= img_reg[8*m+4*i+3][8*n+4*j+3];
							end
						end
					end
				end
			end
		endcase
	end
	else if(cur_state==CLEAR)begin
		for(i=0;i<16;i=i+1)begin
			for(j=0;j<16;j=j+1)begin
				img_reg[i][j]<=0;
			end
		end
	end
end

//Part 2 Comb Logic: EVAL_sram_read (控制目前要read或是寫的是哪一個sram)
assign mem_read_idx=ms_q-(ms_mem_idx<<4);	//ex: 113-7*16=1
assign mem_write_idx=md_q-(md_mem_idx<<4);

always @(*) begin	//標記目前的ms屬於哪一個sram
    case (ms_q)
        0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15:ms_mem_idx=0;
        16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31:ms_mem_idx=1;
        32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47:ms_mem_idx=2;
        48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63:ms_mem_idx=3;
        64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79:ms_mem_idx=4;
        80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95:ms_mem_idx=5;
        96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111:ms_mem_idx=6;
        112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127:ms_mem_idx=7;
        default: ms_mem_idx=0;
    endcase
end

always @(*) begin	//標記目前的md屬於哪一個sram
    case (md_q)
        0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15:md_mem_idx=0;
        16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31:md_mem_idx=1;
        32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47:md_mem_idx=2;
        48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63:md_mem_idx=3;
        64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79:md_mem_idx=4;
        80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95:md_mem_idx=5;
        96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111:md_mem_idx=6;
        112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127:md_mem_idx=7;
        default: md_mem_idx=0;
    endcase
end

//Part 2 Comb Logic: EVAL_sram_read
//read sram的bound
always@(*)begin
	case (ms_q)
        0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15: ms_sram_len=256;
        16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31:ms_sram_len=256;
        32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47:ms_sram_len=256;
        48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63:ms_sram_len=256;
        64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79:ms_sram_len=128;
        80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95:ms_sram_len=128;
        96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111:ms_sram_len=64;
        112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127:ms_sram_len=64;
        default: ms_sram_len=0;
    endcase
end
//Part 2 Comb Logic: EVAL_sram_write
always@(*) begin
    case (md_q)
        0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15: md_sram_len = 256;
        16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31: md_sram_len = 256;
        32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47: md_sram_len = 256;
        48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63: md_sram_len = 256;
        64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79: md_sram_len = 128;
        80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95: md_sram_len = 128;
        96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111: md_sram_len = 64;
        112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127: md_sram_len = 64;
        default: md_sram_len = 0;
    endcase
end

assign mem0_addr = sram_4096_addr;	//之後有Read要再接read的
assign mem0_web  = WEB_arr[0];
assign mem0_din  = sram_4096_din;

assign mem1_addr = sram_4096_addr;
assign mem1_web  = WEB_arr[1];
assign mem1_din  = sram_4096_din;

assign mem2_addr = sram_4096_addr;
assign mem2_web  = WEB_arr[2];
assign mem2_din  = sram_4096_din;

assign mem3_addr = sram_4096_addr;
assign mem3_web  = WEB_arr[3];
assign mem3_din  = sram_4096_din;

assign mem4_addr = sram_2048_addr;
assign mem4_web  = WEB_arr[4];
assign mem4_din  = sram_2048_din;

assign mem5_addr = sram_2048_addr;
assign mem5_web  = WEB_arr[5];
assign mem5_din  = sram_2048_din;

assign mem6_addr = sram_1024_addr;
assign mem6_web  = WEB_arr[6];
assign mem6_din  = sram_1024_din;

assign mem7_addr = sram_1024_addr;
assign mem7_web  = WEB_arr[7];
assign mem7_din  = sram_1024_din;

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