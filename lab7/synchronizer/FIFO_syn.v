module FIFO_syn #(parameter WIDTH=16, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk3,
    flag_clk3_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output flag_fifo_to_clk2;
input  flag_clk2_to_fifo;
output flag_fifo_to_clk3;
input  flag_clk3_to_fifo;

wire [WIDTH-1:0] rdata_q;   //就是rdata_q

// wptr and rptr should be gray coded
// Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

//Part 3 Seq Logic
wire [6:0] rptr_synced, wptr_synced;    //address為6 bit，故開到7 bit


//===READ===
// rdata, Add one more register stage to rdata
reg rinc_q;
always @ (posedge rclk or negedge rst_n) begin 
    if(!rst_n) rinc_q<=1'b0;
	else rinc_q<=rinc;
end
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) rdata<=0;
    else if(rinc==1'b1 || rinc_q==1'b1) rdata<=rdata_q;
end
//======

reg [5:0] read_addr;    //for sram input
reg [6:0] r_binary_q;   //當前sram read address (binary),對於read port來說是主角
reg [6:0] r_binary_d;   //下個sram read address (binary)
reg [6:0] rptr_gray_coded;

//r_binary_d
always@(*) begin
    if(rinc==1'b1 && rempty==1'b0)r_binary_d = r_binary_q+1'b1;
    else r_binary_d = r_binary_q;
end

//rptr_gray_coded
always@(*) begin 
    rptr_gray_coded = (r_binary_d >> 1) ^ r_binary_d;
end

//r_binary_q
always @(posedge rclk or negedge rst_n) begin
    if(!rst_n) r_binary_q <= 0;
    else r_binary_q <= r_binary_d;
end

//rptr
always @(posedge rclk or negedge rst_n)begin 
    if(!rst_n) rptr<= 0;
    else rptr<= rptr_gray_coded;
end

//read_addr
always@(*) begin 
    read_addr= r_binary_q[5:0];
end

//rempty
always @(posedge rclk or negedge rst_n)begin
    if(!rst_n) rempty <= 1'b1;
    else if(rptr_gray_coded == wptr_synced) rempty <= 1'b1;
    else rempty <= 1'b0;
end
//===========


//===WRITE===
reg [5:0] write_addr;   //for sram input
reg [6:0] w_binary_q;   //當前sram write address (binary),對於write port來說是主角
reg [6:0] w_binary_d;   //下個sram write address (binary)
reg [6:0] wptr_gray_coded;
reg write_en;

//w_binary_d
always@(*)begin 
    if(winc==1'b1 && wfull==1'b0) w_binary_d = w_binary_q +1'b1;
    else w_binary_d = w_binary_q;
end

//wptr_gray_coded
always@(*)begin 
    wptr_gray_coded = (w_binary_d >> 1) ^ w_binary_d;
end

//w_binary_q
always @(posedge wclk or negedge rst_n)begin 
    if(!rst_n)w_binary_q <= 0;
    else w_binary_q <= w_binary_d;
end

//wptr
always @(posedge wclk or negedge rst_n) begin
    if(!rst_n) wptr<=0;
    else wptr<=wptr_gray_coded;
end

//write_addr
always@(*)begin 
    write_addr= w_binary_q[5:0];
end

//wfull
//不能直接拿w_binary_q和r_binary_q比較，因為對於寫入端來說r_binary_q是另一個clk domain的，讀取時會有violation
always @(posedge wclk or negedge rst_n) begin
    if  (!rst_n) wfull <= 1'b0;
    else wfull <= ({~wptr_gray_coded[6:5],wptr_gray_coded[4:0]} == rptr_synced)? 1'b1:1'b0;
end

//write_en (如果寫入端沒有要寫入或是wfull==1'b1，就不寫)
always@(*)begin
    if(winc==1'b0 || wfull==1'b1 )write_en=1'b1;
    else write_en=1'b0;
end
//==========


//Part 3 Seq Logic sram signal
wire [15:0] sram_din;
reg [15:0] sram_dout;   

DUAL_64X16X1BM1 u_dual_sram (
    .CKA(wclk),
    .CKB(rclk),
    .WEAN(1'b0),
    .WEBN(1'b1),
    .CSA(write_en),
    .CSB(1'b1),
    .OEA(1'b1),
    .OEB(1'b1),
    .A0(write_addr[0]),
    .A1(write_addr[1]),
    .A2(write_addr[2]),
    .A3(write_addr[3]),
    .A4(write_addr[4]),
    .A5(write_addr[5]),
    .B0(read_addr[0]),
    .B1(read_addr[1]),
    .B2(read_addr[2]),
    .B3(read_addr[3]),
    .B4(read_addr[4]),
    .B5(read_addr[5]),
    .DIA0(wdata[0]),
    .DIA1(wdata[1]),
    .DIA2(wdata[2]),
    .DIA3(wdata[3]),
    .DIA4(wdata[4]),
    .DIA5(wdata[5]),
    .DIA6(wdata[6]),
    .DIA7(wdata[7]),
    .DIA8(wdata[8]),
    .DIA9(wdata[9]),
    .DIA10(wdata[10]),
    .DIA11(wdata[11]),
    .DIA12(wdata[12]),
    .DIA13(wdata[13]),
    .DIA14(wdata[14]),
    .DIA15(wdata[15]),
    .DIB0(1'b0),
    .DIB1(1'b0),
    .DIB2(1'b0),
    .DIB3(1'b0),
    .DIB4(1'b0),
    .DIB5(1'b0),
    .DIB6(1'b0),
    .DIB7(1'b0),
    .DIB8(1'b0),
    .DIB9(1'b0),
    .DIB10(1'b0),
    .DIB11(1'b0),
    .DIB12(1'b0),
    .DIB13(1'b0),
    .DIB14(1'b0),
    .DIB15(1'b0),
    .DOB0(rdata_q[0]),
    .DOB1(rdata_q[1]),
    .DOB2(rdata_q[2]),
    .DOB3(rdata_q[3]),
    .DOB4(rdata_q[4]),
    .DOB5(rdata_q[5]),
    .DOB6(rdata_q[6]),
    .DOB7(rdata_q[7]),
    .DOB8(rdata_q[8]),
    .DOB9(rdata_q[9]),
    .DOB10(rdata_q[10]),
    .DOB11(rdata_q[11]),
    .DOB12(rdata_q[12]),
    .DOB13(rdata_q[13]),
    .DOB14(rdata_q[14]),
    .DOB15(rdata_q[15])
);

//rptr已經是gray code形式，因為同步過去給對面看到的要是gray code形式
//rptr=(r_binary_d >> 1) ^ r_binary_d;
//然後r_binary_d = r_binary_q + (rinc & ~rempty); 就是我們的read address
NDFF_BUS_syn #(.WIDTH(7)) rtow_ptr(.D(rptr), .Q(rptr_synced), .clk(wclk), .rst_n(rst_n));

//wptr已經是gray code形式，因為同步過去給對面看到的要是gray code形式
//wptr_gray_coded = (w_binary_d >> 1) ^ w_binary_d;
//然後w_binary_d = w_binary_q + (winc & ~wfull); 就是我們的address
NDFF_BUS_syn #(.WIDTH(7)) wtor_ptr(.D(wptr), .Q(wptr_synced), .clk(rclk), .rst_n(rst_n));

endmodule