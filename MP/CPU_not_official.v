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
reg [3:0]cur_state,next_state;

parameter INST_read=4'd0, INST_sram_read=4'd1, INST_dram_read=4'd2;
parameter INST_decode=4'd3, EXE=4'd4, LOAD_DRAM=4'd5, STORE_DRAM=4'd6;
parameter WRITE_BACK=4'd7, IDLE=4'd8;

reg [15:0] pc;                                //global program counter      

//FSM_Tag
reg INST_sram_read_done, INST_dram_read_done, INST_decode_done;
reg EXE_done, LOAD_DRAM_done, STORE_DRAM_done, WRITE_BACK_done;

always @(posedge clk or negedge rst_n) begin
  if(!rst_n)cur_state<=INST_read;
  else cur_state<=next_state;
end

//Part 2 Comb Logic 判定目前pc是否介在sram_start_addr和sram_start_addr+63中
reg in_sram_bool;  
always@(*) begin
    if(pc>=sram_start_addr || pc<=(sram_start_addr + 63)) in_sram_bool=1'b1;
    else in_sram_bool=1'b0;
end

always@(*)begin
    case(cur_state)
        INST_read: begin
            if(in_sram_bool==1'b1) next_state=INST_sram_read;
            else next_state=INST_dram_read;
        end
        INST_sram_read: begin
            if(INST_sram_read_done==1'b1) next_state =INST_decode;
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
        STORE_DRAM: begin
            if(STORE_DRAM_done==1'b1) next_state=WRITE_BACK;
            else next_state=STORE_DRAM;
        end
        WRITE_BACK: next_state= INST_read;
        default: next_state=IDLE;
    endcase
end

//===AXI4 WRITRE (只有STORE會用到)===
//1. write address channel (1-1 to 1-7)
//1-1 AWID (目前看學長是寫0)
assign awid_m_inf=4'd0;
//1-3 AWLEN (STORE不用burst mode)
assign awlen_m_inf= 7'd0;
//1-4 AWSIZE (題目要求)
assign awsize_m_inf= 3'b001;
//1-5 AWBURST
assign awburst_m_inf=2'b01;
//我們需要Read awready_m_inf, 發送 awvalid_m_inf和awaddr_m_inf(STORE的address)

//2. write data channel (2-1 to 2-4)
//2-1 WDATA, 2-2 WLAST, 2-3 WVALID, 2-4 WREADY
//我們用handshke讀wready_m_inf,把wvalid_m_inf拉高並輸出wdata_m_inf
//當wready_m_inf和wvalid_m_inf同時為1時令wlast_m_inf=1 (Part 2 Comb Logic)

//3. write respondse
//3-1 BID (form DRAM), 3-2 BRESP(form DRAM), 3-3 BVALID(form DRAM), 3-4 BREADY
//當wready_m_inf和wvalid_m_inf同時為1，bready_m_inf就可以拉成1
//當bready_m_inf && bvalid_m_inf同時為1時代表 STOREJ)ˊ代表STORE完成


//Part 3 Seq Logic for AXI4 Write
always @(posedge clk or negedge rst_n) begin
    
end

//===AXI4 READ (INST_dram_read和LOAD會用到)===
//4. read address channel
//4-1 ARID
assign arid_m_inf[7:4] =4'd0;	//inst的ARID, 
assign arid_m_inf[3:0] =4'd0;	//data的ARID

//4-3 ARLEN
assign arlen_m_inf[13:7] = 7'd128;	//inst的burst len
assign arlen_m_inf[6:0] = 7'd0;		//data的burst len

//4-4 ARSIZE
assign arsize_m_inf[5:3] = 3'd1;	//inst的arsize
assign arsize_m_inf[2:0] = 3'd1;	//data的arsize

//4-5 ARBURST
assign arburst_m_inf[3:2] = 2'd1;	//inst的arburst
assign arburst_m_inf[1:0] = 2'd1;	//data的arburst

//學長是直接用comb寫araddr_m_inf
//arvalid_inst和arvalid_data要分開控制
//
assign arvalid_m_inf[1] = arvalid_inst;
assign arvalid_m_inf[0] = arvalid_data;
endmodule 

module MEM_wrapper(
    input clk,
    input [5:0] A,
    input [15:0] DI,
    input WEB,
    input CS,
    input OE,
    output [15:0] DO
);
  SRAM_64_16 SRAM_64_16_inst(
    .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]),

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