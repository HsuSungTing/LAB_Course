module CPU(
		  clk,
    	rst_n,
    	IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//Part 1: FSM (& FSM)
reg [3:0] cur_state,next_state;

parameter INST_read=4'd0, INST_sram_read=4'd1, INST_dram_read=4'd2;
parameter INST_decode=4'd3, EXE=4'd4, LOAD_DRAM=4'd5, STORE_DRAM=4'd6;
parameter WRITE_BACK=4'd7, IDLE=4'd8;

reg [15:0] program_cnt;                                //global program counter      
reg [2:0] cur_opcode;
reg [15:0] sram_start_addr;

//FSM_Tag
reg [1:0] INST_sram_read_cnt;
reg INST_dram_read_done, INST_decode_done;
reg EXE_done, LOAD_DRAM_done, STORE_DRAM_done, WRITE_BACK_done;

always @(posedge clk or negedge rst_n) begin
  	if(!rst_n)cur_state<=INST_read;
  	else cur_state<=next_state;
end

//Part 2 Comb Logic 判定目前pc是否介在sram_start_addr和sram_start_addr+63中
reg in_sram_bool;  
always@(*) begin
    if(program_cnt>=sram_start_addr && program_cnt<=(sram_start_addr + 127)) in_sram_bool=1'b1;
    else in_sram_bool=1'b0;
end

always@(*)begin
    case(cur_state)
        INST_read: begin
            if(in_sram_bool==1'b1) next_state=INST_sram_read;
            else next_state=INST_dram_read;
        end
        INST_sram_read: begin
            if(INST_sram_read_cnt>=2'b1) next_state =INST_decode;
            else next_state=INST_sram_read;
        end
        INST_dram_read: begin
            if(INST_dram_read_done==1'b1) next_state =INST_decode;
            else next_state=INST_dram_read;
        end
        INST_decode: next_state=EXE;
        EXE: begin
            //LOAD
            if(cur_opcode==3'b011) next_state=LOAD_DRAM;
            //STORE
            else if(cur_opcode==3'b010) next_state=STORE_DRAM;
            else next_state=EXE;
        end
        LOAD_DRAM: begin
            if(LOAD_DRAM_done==1'b1) next_state=WRITE_BACK;
            else next_state=LOAD_DRAM;
        end
        STORE_DRAM: begin				//STORE不用WRITE BACK
            if(STORE_DRAM_done==1'b1) next_state=INST_read;
            else next_state=STORE_DRAM;
        end
        WRITE_BACK: next_state= INST_read;
        default: next_state=IDLE;
    endcase
end

//===AXI4 WRITRE (只有STORE會用到)===

//1. write address channel (1-1 to 1-7)
//1-1 AWID (OUTPUT)
assign awid_m_inf=4'd0;
//1-2 AWADDR (OUTPUT)
reg [31:0] awaddr_data_m;
assign awaddr_m_inf=awaddr_data_m;
//1-3 AWLEN (OUTPUT) 
assign awlen_m_inf= 7'd0; //(STORE不用burst mode)
//1-4 AWSIZE (OUTPUT)
assign awsize_m_inf= 3'b001;
//1-5 AWBURST (OUTPUT)
assign awburst_m_inf=2'b01;
//1-6 AWVALID (OUTPUT)
reg awvalid_data_m;
assign awvalid_m_inf=awvalid_data_m;
//1-7 AWREADY (INPUT)
wire awready_data_s;
assign awready_data_s=awready_m_inf;
//我們需要Read awready_m_inf, 發送 awvalid_m_inf和awaddr_m_inf(STORE的address)

//2. write data channel (2-1 to 2-4)
//2-1 WDATA (OUTPUT)
reg [15:0] wdata_data_m;
assign wdata_m_inf=wdata_data_m;
//2-2 WLAST (OUTPUT) 
reg wlast_data_m;
assign wlast_m_inf=wlast_data_m;
//2-3 WVALID (OUTPUT) 
reg wvalid_data_m;
assign wvalid_m_inf=wvalid_data_m;
//2-4 WREADY (INPUT)
wire wready_data_s;
assign wready_data_s=wready_m_inf;
//我們用handshke讀wready_m_inf,把wvalid_m_inf拉高並輸出wdata_m_inf
//當wready_m_inf和wvalid_m_inf同時為1時令wlast_m_inf=1 (Part 2 Comb Logic)

//3. write respondse
//3-1 BID (INPUT), 3-2 BRESP (INPUT)
//3-3 BVALID (OUTPUT)
reg bvalid_data_m;
assign bvalid_m_inf=bvalid_data_m;
//3-4 BREADY (INPUT)
wire bready_data_s;
assign bready_data_s=bready_m_inf;
//當wready_m_inf和wvalid_m_inf同時為1，bready_m_inf就可以拉成1
//當bready_m_inf && bvalid_m_inf同時為1時代表 STOREJ)ˊ代表STORE完成


//===AXI4 READ (INST_dram_read和LOAD會用到)===

//4. read address channel
//4-1 ARID (OUTPUT)
assign arid_m_inf[7:4] =4'd0;	      //inst的ARID, 
assign arid_m_inf[3:0] =4'd0;	      //data的ARID
//4-2 ARADDR (OUTPUT)
reg [31:0] araddr_inst_m, araddr_data_m;
assign araddr_m_inf={araddr_inst_m, araddr_data_m};
//4-3 ARLEN (OUTPUT)
assign arlen_m_inf[13:7] = 7'd127;	  //inst的burst len
assign arlen_m_inf[6:0] = 7'd0;		  //data的burst len
//4-4 ARSIZE (OUTPUT)
assign arsize_m_inf[5:3] = 3'd1;	  //inst的arsize
assign arsize_m_inf[2:0] = 3'd1;	  //data的arsize
//4-5 ARBURST (OUTPUT)
assign arburst_m_inf[3:2] = 2'd1;	  //inst的arburst
assign arburst_m_inf[1:0] = 2'd1;	  //data的arburst
//4-6 ARVALID (OUTPUT)   (arvalid_inst和arvalid_data要分開控制)
reg arvalid_inst_m, arvalid_data_m;
assign arvalid_m_inf[1]= arvalid_inst_m;
assign arvalid_m_inf[0]= arvalid_data_m;
//4-7 ARREADY (INPUT)
wire arready_inst_s, arready_data_s;   //arredy from slave
assign arready_inst_s=arready_m_inf[1];
assign arready_data_s=arready_m_inf[0];

//5. read channel
//5-1 RID (INPUT)
//5-2 RDATA (INPUT)
wire [15:0] rdata_inst_s, rdata_data_s;
assign rdata_inst_s=rdata_m_inf[31:16];
assign rdata_data_s=rdata_m_inf[15: 0];
//5-3 RRESP (INPUT)
//5-4 RLAST (INPUT) (理論上不會用到，因為我們會用cnt去計算直到128)
wire rlast_inst_s, rlast_data_s;
assign rlast_inst_s=rlast_m_inf[1];
assign rlast_data_s=rlast_m_inf[0];
//5-5 RVALID (INPUT)
wire rvalid_inst_s, rvalid_data_s;
assign rvalid_inst_s=rvalid_m_inf[1];
assign rvalid_data_s=rvalid_m_inf[0];
//5-6 RREADY (OUTPUT)
reg rready_inst_m, rready_data_m;
assign rready_m_inf= {rready_inst_m, rready_data_m};

//===for sram===
reg [6:0] sram_addr;
reg WEB;
reg [15:0] sram_din; 
wire [15:0] sram_dout;
reg [15:0] sram_dout_q;

MEM_wrapper sram_inst(
	.clk(clk), .A(sram_addr), .DI(sram_din),
	.WEB(WEB),.CS(1'b1),.OE(1'b1),.DO(sram_dout)
);

//===stage 1 INST_sram_read or INST+dram_read===
//寫入SRAM且讀取DRAM(or SRAM),得到cur_inst_q

//Part 3 Seq Logic
reg [15:0] cur_inst_q;
reg writing_sram_bool;	//判定目前是否有在寫SRAM
reg ar_handshake_done;	//判定目前是否已經完成address的handshake(準備開始data的handshke)
reg [7:0] r_handshake_cnt;
reg [15:0] LOAD_data_from_dram; //for step 4 LOAD and STORE Data
reg [15:0] lw_sw_address;		//for step 4 LOAD and STORE Data

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		//INST_sram_read
		cur_inst_q<=16'd0; 			INST_sram_read_cnt<=2'd0;
		//INST_dram_read: control signal for AXI read
		sram_start_addr<=16'd0; 	writing_sram_bool<=1'b0; 
		ar_handshake_done<=1'b0;	araddr_inst_m<=16'd0;	arvalid_inst_m<=1'b0;	
		rready_inst_m<=1'b0;		r_handshake_cnt<=8'd0; 
		INST_dram_read_done<=1'b0;
		//INST_dram_read: control signal for sram signal
		sram_addr<=7'd0; WEB<=1'b1;	sram_din<=16'd0; 
		//LOAD_DRAM
		LOAD_data_from_dram<=16'd0; LOAD_DRAM_done<=0;
	end
	//case 0: 指令在inst_sram中, 直接讀取一次即可
	else if(cur_state==INST_sram_read)begin
		INST_sram_read_cnt<=INST_sram_read_cnt+1;
		if(INST_sram_read_cnt==0) begin
    		sram_addr<= (program_cnt - sram_start_addr);
			WEB<=1'b1;
			cur_inst_q<=cur_inst_q;
		end
		else if(INST_sram_read_cnt==1)begin
			sram_addr<= (program_cnt - sram_start_addr);
			WEB<=1'b1;
			cur_inst_q<=sram_dout;
		end
  	end
  	//case 1:指令不在inst_sram中, 一次讀取128個element
  	else if(cur_state==INST_dram_read)begin
    	//case 1-0 :read inst address handshake到了
    	if((arvalid_inst_m==1'b1 && arready_inst_s==1'b1) && ar_handshake_done==0 && r_handshake_cnt==0) begin
      		//step 1 AXI4 (ARVALID送完就休息,換RREADY)
			araddr_inst_m<=16'd0;	
			arvalid_inst_m<=1'b0;	
			ar_handshake_done<=1'b1;
			rready_inst_m<=1'b1;	

			//step 2 sram control
			sram_din<=16'd0; sram_addr<=7'd0; WEB<=1; //準備開始WRITE,仍維持read
    	end
    	//case 1-1: inst等address handshake
    	else if((arvalid_inst_m!=1'b1 || arready_inst_s!=1'b1) && ar_handshake_done==0 && r_handshake_cnt==0)begin
    		//step 1 AXI4 (持續送)
			araddr_inst_m<=program_cnt;	
			arvalid_inst_m<=1'b1;		
			ar_handshake_done<=1'b0;
    	end
		//case 1-4:完成寫入 (data handshake 127次了)
		else if(r_handshake_cnt>127)begin
			//step 1: AXI4
			rready_inst_m<=1'b0;		
			writing_sram_bool<=1'b0;	
			//step 2: sram control
			sram_addr<=7'd0;
			sram_din<=16'd0; WEB<=1;	//停止寫入，就read
			//step 3: INST_dram_read完成
			INST_dram_read_done<=1'b1;
		end
    	//case 1-2: address完成handshake且read inst data handshake到了
    	else if((rvalid_inst_s==1'b1 && rready_inst_m==1'b1)&& ar_handshake_done==1 && r_handshake_cnt<=127) begin
			//step 1 AXI4 (接收到data了)
			rready_inst_m<=1'b1;
			sram_start_addr <= program_cnt;
			if(r_handshake_cnt==0) cur_inst_q<=rdata_inst_s; 
			writing_sram_bool<=1'b1;			//第一次handshake之後的就會開始連續寫入
			r_handshake_cnt<=r_handshake_cnt+1;	//代表完成一次r data的handshake
			
			//step 2: sram control (開始連續寫), 寫入重複沒關係, 只要din和addr同步即可
			sram_din<=rdata_inst_s; 			//接收到AXI4傳入的data
			WEB<=0;								
			if(r_handshake_cnt==0) sram_addr<=sram_addr;
			else sram_addr<=sram_addr+1'd1;
    	end
		//case 1-3: address完成handshake但read inst data 目前沒有handshake到
  	end
	//case 2 for STEP 4 LOAD DRAM (讀1筆就好)
	else if(cur_state==LOAD_DRAM)begin
		//case 1-0: data的address handshake完成
		if((arready_data_s==1'b1 && arvalid_data_m==1'b1) && ar_handshake_done==0 && r_handshake_cnt==0)begin
			//step 1 AXI4 (ARVALID送完就休息,換RREADY)
			araddr_data_m<=16'd0;	
			arvalid_data_m<=1'b0;	
			ar_handshake_done<=1'b1;	
		end
		//case 1-1: data等address handshake
		else if((arready_data_s!=1'b1 || arvalid_data_m!=1'b1) && ar_handshake_done==0 && r_handshake_cnt==0)begin
			araddr_data_m<=lw_sw_address;
			arvalid_data_m<=1'b1;		
			ar_handshake_done<=1'b0;
		end
		//case 1-2: data的data handshake完成
		else if((rready_data_m==1'b1 && rvalid_data_s==1'b1) && ar_handshake_done==1 && r_handshake_cnt==0) begin
			LOAD_data_from_dram<=LOAD_data_from_dram;
			rready_data_m<=1'b0; 
			r_handshake_cnt<=1;
			LOAD_DRAM_done<=1;
		end
		//case 1-3: data在等data handshake
		else if((rready_data_m==1'b0 || rvalid_data_s==1'b0) && ar_handshake_done==1 && r_handshake_cnt==0) begin
			LOAD_data_from_dram<=rdata_data_s;
			rready_data_m<=1'b1;
			r_handshake_cnt<=0;
		end
	end
	else begin
		//INST_sram_read
		cur_inst_q<=16'd0; 			INST_sram_read_cnt<=2'd0;
		//INST_dram_read: control signal for AXI read
		sram_start_addr<=16'd0; 	writing_sram_bool<=1'b0; 
		ar_handshake_done<=1'b0;	araddr_inst_m<=16'd0;	arvalid_inst_m<=1'b0;	
		rready_inst_m<=1'b0;		r_handshake_cnt<=8'd0; 
		INST_dram_read_done<=1'b0;
		//INST_dram_read: control signal for sram signal
		sram_addr<=7'd0; WEB<=1'b1;	sram_din<=16'd0; 
		//LOAD_DRAM
		LOAD_data_from_dram<=16'd0; LOAD_DRAM_done<=0;
	end
end
//===================

//===stage 2 INSAT_decode===
//對cur_inst_q做decode並暫存rs, rt, rd, op, addr, imm, func

//Part 2 Comb Logic
reg [15:0] rs_value, rt_value, rd_value;
always@(*)begin
	case(cur_inst_q[12:9])
		4'd0:  rs_value = core_r0;
		4'd1:  rs_value = core_r1;
		4'd2:  rs_value = core_r2;
		4'd3:  rs_value = core_r3;
		4'd4:  rs_value = core_r4;
		4'd5:  rs_value = core_r5;
		4'd6:  rs_value = core_r6;
		4'd7:  rs_value = core_r7;
		4'd8:  rs_value = core_r8;
		4'd9:  rs_value = core_r9;
		4'd10: rs_value = core_r10;
		4'd11: rs_value = core_r11;
		4'd12: rs_value = core_r12;
		4'd13: rs_value = core_r13;
		4'd14: rs_value = core_r14;
		4'd15: rs_value = core_r15;
	endcase
end

always@(*)begin
	case(cur_inst_q[8:5])
		4'd0:  rt_value = core_r0;
		4'd1:  rt_value = core_r1;
		4'd2:  rt_value = core_r2;
		4'd3:  rt_value = core_r3;
		4'd4:  rt_value = core_r4;
		4'd5:  rt_value = core_r5;
		4'd6:  rt_value = core_r6;
		4'd7:  rt_value = core_r7;
		4'd8:  rt_value = core_r8;
		4'd9:  rt_value = core_r9;
		4'd10: rt_value = core_r10;
		4'd11: rt_value = core_r11;
		4'd12: rt_value = core_r12;
		4'd13: rt_value = core_r13;
		4'd14: rt_value = core_r14;
		4'd15: rt_value = core_r15;
	endcase
end

//Part 3 Seq Logic
reg signed [15:0] cur_rs, cur_rt;
reg cur_func;
reg signed [4:0] cur_immediate;
reg [12:0] cur_address;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cur_opcode<=3'd0;
		cur_rs<=16'd0; cur_rt<=16'd0; 
		cur_immediate<=5'd0; cur_address<=13'd0;
	end
	else if(cur_state==INST_decode)begin
		cur_opcode<=cur_inst_q[15:13];
		cur_rs<=rs_value; cur_rt<=rt_value; 
		cur_immediate<=cur_inst_q[4:0];		//不確定是否這樣就會直接被解讀成signed，但學長這樣寫
		cur_address<=cur_inst_q;
	end
end

//==========================

//===stage 3 EXE===
//step 3-1 更新PC (包含LW SW的address計算)
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		program_cnt<=16'h1000;
	end
	else if(cur_state==EXE) begin
		//beq	
		if(cur_inst_q==3'b101) program_cnt<=program_cnt+2+cur_immediate;	//cur_immediate為signd，但我看學長直接加
		//jump
		else if(cur_inst_q==3'b100) program_cnt<={3'd0,cur_address};
		else program_cnt<=program_cnt+2;
	end
end

//step 3-2 做ALU的 + - * slt並存入cur_rd(大佬說不用共用加法器, 才一千多)
reg signed [15:0] cur_rd;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cur_rd<=16'd0;
	end
	else if(cur_state==EXE)begin
		if(cur_opcode==3'b000 && cur_func==1'b1) cur_rd<= cur_rs+cur_rt;
		else if(cur_opcode==3'b000 && cur_func==1'b0) cur_rd<= cur_rs-cur_rt;
		else if(cur_opcode==3'b001 && cur_func==1'b1) begin
			if(cur_rs<cur_rt) cur_rd<= 16'd1;
			else cur_rd<= 16'd0;
		end
		else if(cur_opcode==3'b001 && cur_func==1'b0) cur_rd<= cur_rs*cur_rt;
		else cur_rd<=16'd0;
	end
end

//STEP 3-3 (LW SW的address計算)
//reg [15:0] lw_sw_address;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		lw_sw_address<=16'd0;
	end
	else if(cur_state==EXE) begin
		lw_sw_address<= (cur_rs+cur_immediate)<<<1 + 16'h1000;
	end
end
//==========================

//step 4 LOAD & STORE DRAM
reg aw_handshake_done;
reg w_handshake_done;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		//STORE_DRAM: AW
		awaddr_data_m<=16'd0; awvalid_data_m<=0;	aw_handshake_done<=0;
		//STORE_DRAM: W
		wdata_data_m<=16'd0;
		wvalid_data_m<=0;	w_handshake_done<=0;
		//STORE_DRAM: B
		bvalid_data_m<=0;	STORE_DRAM_done<=0;
	end
	//case 0 STORE_DRAM
	else if(cur_state==STORE_DRAM)begin
		//case 0-0 aw data的address handshake完成
		if((awvalid_data_m==1'b1 && awready_data_s==1'b1) && aw_handshake_done==0 && w_handshake_done==0 && STORE_DRAM_done==0)begin
			awaddr_data_m<=awaddr_data_m;
			awvalid_data_m<=0;
			aw_handshake_done<=1;
		end
		//case 0-1 aw data等address handshake
		else if((awvalid_data_m!=1'b1 || awready_data_s!=1'b1) && aw_handshake_done==0 && w_handshake_done==0 && STORE_DRAM_done==0)begin
			awaddr_data_m<=lw_sw_address;
			awvalid_data_m<=1'b1;
			aw_handshake_done<=0;
		end
		//case 0-2 w data等address handshake
		else if((wvalid_data_m==1'b1 && wready_data_s==1'b1) && aw_handshake_done==1 && w_handshake_done==0 && STORE_DRAM_done==0)begin
			wdata_data_m<=wdata_data_m;
			wvalid_data_m<=0;
			w_handshake_done<=1;
		end
		//case 0-3 w data等address handshake
		else if((wvalid_data_m!=1'b1 || wready_data_s!=1'b1) && aw_handshake_done==1 && w_handshake_done==0 && STORE_DRAM_done==0)begin
			wdata_data_m<=cur_rt;
			wvalid_data_m<=1;
			w_handshake_done<=0;
		end
		//case 0-4 b data等address handshake
		else if((bready_data_s==1'b1 && bvalid_data_m==1'b1) && aw_handshake_done==1 && w_handshake_done==1 && STORE_DRAM_done==0)begin
			bvalid_data_m<=0;
			STORE_DRAM_done<=1;
		end
		//case 0-5 b data等address handshake
		else if((bvalid_data_m!=1'b1 || bready_data_s!=1'b1) && aw_handshake_done==1 && w_handshake_done==1 && STORE_DRAM_done==0)begin
			bvalid_data_m<=1;
			STORE_DRAM_done<=0;
		end
	end
	else begin
		//STORE_DRAM: AW
		awaddr_data_m<=16'd0; awvalid_data_m<=0;	aw_handshake_done<=0;
		//STORE_DRAM: W
		wdata_data_m<=16'd0;
		wvalid_data_m<=0;	w_handshake_done<=0;
		//STORE_DRAM: B
		bvalid_data_m<=0;	STORE_DRAM_done<=0;
	end
end
//========================

//step 5 write back
//除了STORE之外其他都要write back
//for LOAD, rt<=LOAD_data_from_dram
//for ALU, rd<=cur_rd
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		core_r0  <= 16'd0;
		core_r1  <= 16'd0;
		core_r2  <= 16'd0;
		core_r3  <= 16'd0;
		core_r4  <= 16'd0;
		core_r5  <= 16'd0;
		core_r6  <= 16'd0;
		core_r7  <= 16'd0;
		core_r8  <= 16'd0;
		core_r9  <= 16'd0;
		core_r10 <= 16'd0;
		core_r11 <= 16'd0;
		core_r12 <= 16'd0;
		core_r13 <= 16'd0;
		core_r14 <= 16'd0;
		core_r15 <= 16'd0;
	end
	else if(cur_state==WRITE_BACK)begin
		if(cur_opcode==3'b000|| cur_opcode==3'b001)begin
			case(cur_inst_q[4:1])	//rd
				0: core_r0  <= cur_rd;
				1: core_r1  <= cur_rd;
				2: core_r2  <= cur_rd;
				3: core_r3  <= cur_rd;
				4: core_r4  <= cur_rd;
				5: core_r5  <= cur_rd;
				6: core_r6  <= cur_rd;
				7: core_r7  <= cur_rd;
				8: core_r8  <= cur_rd;
				9: core_r9  <= cur_rd;
				10: core_r10 <= cur_rd;
				11: core_r11 <= cur_rd;
				12: core_r12 <= cur_rd;
				13: core_r13 <= cur_rd;
				14: core_r14 <= cur_rd;
				15: core_r15 <= cur_rd;
			endcase
		end
		else if(cur_opcode==3'b011)begin
			case(cur_inst_q[8:5])	//rt
				0: core_r0  <=LOAD_data_from_dram;
				1: core_r1  <=LOAD_data_from_dram;
				2: core_r2  <=LOAD_data_from_dram;
				3: core_r3  <=LOAD_data_from_dram;
				4: core_r4  <=LOAD_data_from_dram;
				5: core_r5  <=LOAD_data_from_dram;
				6: core_r6  <=LOAD_data_from_dram;
				7: core_r7  <=LOAD_data_from_dram;
				8: core_r8  <=LOAD_data_from_dram;
				9: core_r9  <=LOAD_data_from_dram;
				10: core_r10<=LOAD_data_from_dram;
				11: core_r11<=LOAD_data_from_dram;
				12: core_r12<=LOAD_data_from_dram;
				13: core_r13<=LOAD_data_from_dram;
				14: core_r14<=LOAD_data_from_dram;
				15: core_r15<=LOAD_data_from_dram;
			endcase
		end
	end
end
//=============================

//Part 3 Seq Logic: IO_stall
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)IO_stall<=1'b1;
	else IO_stall<=1'b1;
end

endmodule 

module MEM_wrapper(
    input clk,
    input [6:0] A,
    input [15:0] DI,
    input WEB,
    input CS,
    input OE,
    output [15:0] DO
);
  SRAM_128_16 SRAM_128_16_inst(
    .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]),

    .DO0(DO[0]), .DO1(DO[1]), .DO2(DO[2]), .DO3(DO[3]), 
    .DO4(DO[4]), .DO5(DO[5]), .DO6(DO[6]), .DO7(DO[7]),
    .DO8(DO[8]), .DO9(DO[9]), .DO10(DO[10]), .DO11(DO[11]), 
    .DO12(DO[12]), .DO13(DO[13]), .DO14(DO[14]), .DO15(DO[15]),

    .DI0(DI[0]), .DI1(DI[1]), .DI2(DI[2]), .DI3(DI[3]), 
    .DI4(DI[4]), .DI5(DI[5]), .DI6(DI[6]), .DI7(DI[7]),
    .DI8(DI[8]), .DI9(DI[9]), .DI10(DI[10]), .DI11(DI[11]), 
    .DI12(DI[12]), .DI13(DI[13]), .DI14(DI[14]), .DI15(DI[15]),
    
    .CK(clk), .WEB(WEB), .OE(OE), .CS(CS)
  );
endmodule