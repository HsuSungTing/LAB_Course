// ##############################################################
//   You can modify by your own
//   You can modify by your own
//   You can modify by your own
// ##############################################################

module CHIP(
    // input signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    
	
    // output signals
    busy
);

input            clk;
input            rst_n;
		  
input            in_valid_data;
input     [7:0]  data;
		  
input            in_valid_cmd;
input    [17:0]  cmd;
		  
output           busy;

//==================================================================
// reg & wire
//==================================================================
wire             C_clk;
wire             C_rst_n;

wire             C_in_valid_data;
wire      [7:0]  C_data;

wire             C_in_valid_cmd;
wire     [17:0]  C_cmd;

wire             C_busy;

//==================================================================
// CORE
//==================================================================
GTE CORE(
	// input signals
	.clk(C_clk),
	.rst_n(C_rst_n),

	.in_valid_data(C_in_valid_data),
	.data(C_data),

	.in_valid_cmd(C_in_valid_cmd),
	.cmd(C_cmd),

	// output signals
	.busy(C_busy)
);

//==================================================================
// INPUT PAD: XMD
// Syntax: XMD PAD_NAME ( .O(CORE_PORT_NAME), .I(CHIP_PORT_NAME), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
// Ex: XMD    I_CLK ( .O(C_clk),          .I(clk),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_CLK 			(.O(C_clk),          .I(clk),            .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_RST 			(.O(C_rst_n),        .I(rst_n),          .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_in_valid_data 	(.O(C_in_valid_data),       .I(in_valid_data),         .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_in_valid_cmd 	(.O(C_in_valid_cmd),        .I(in_valid_cmd),          .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_data0 			(.O(C_data[0]), .I(data[0]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data1 			(.O(C_data[1]), .I(data[1]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data2 			(.O(C_data[2]), .I(data[2]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data3 			(.O(C_data[3]), .I(data[3]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data4 			(.O(C_data[4]), .I(data[4]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data5 			(.O(C_data[5]), .I(data[5]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data6 			(.O(C_data[6]), .I(data[6]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_data7 			(.O(C_data[7]), .I(data[7]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));

XMD    I_cmd0  			(.O(C_cmd[0]),  .I(cmd[0]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd1  			(.O(C_cmd[1]),  .I(cmd[1]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd2  			(.O(C_cmd[2]),  .I(cmd[2]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd3  			(.O(C_cmd[3]),  .I(cmd[3]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd4  			(.O(C_cmd[4]),  .I(cmd[4]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd5  			(.O(C_cmd[5]),  .I(cmd[5]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd6  			(.O(C_cmd[6]),  .I(cmd[6]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd7  			(.O(C_cmd[7]),  .I(cmd[7]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd8  			(.O(C_cmd[8]),  .I(cmd[8]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd9  			(.O(C_cmd[9]),  .I(cmd[9]),  .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd10 			(.O(C_cmd[10]), .I(cmd[10]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd11 			(.O(C_cmd[11]), .I(cmd[11]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd12 			(.O(C_cmd[12]), .I(cmd[12]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd13 			(.O(C_cmd[13]), .I(cmd[13]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd14 			(.O(C_cmd[14]), .I(cmd[14]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd15 			(.O(C_cmd[15]), .I(cmd[15]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd16 			(.O(C_cmd[16]), .I(cmd[16]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
XMD    I_cmd17 			(.O(C_cmd[17]), .I(cmd[17]), .PU(1'b0), .PD(1'b0), .SMT(1'b0));
//==================================================================
// You need to finish this part



//==================================================================
// OUTPUT PAD: YA2GSD
// Syntax: YA2GSD PAD_NAME (.I(CORE_PIN_NAME), .O(PAD_PIN_NAME), .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
// Ex: YA2GSD  O_VALID (.I(C_out_valid),   .O(out_valid),    .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
YA2GSD O_busy 			(.I(C_busy),        .O(busy),        .E(1'b1), .E2(1'b1), .E4(1'b1), .E8(1'b0), .SR(1'b0));
//==================================================================
// You need to finish this part


//==================================================================
// I/O power 3.3V pads: VCC3IOD/GNDIOD 
// Syntax: VCC3IOD/GNDIOD PAD_NAME ();
//    Ex1: VCC3IOD        VDDP0 ();
//    Ex2: GNDIOD         GNDP0 ();
VCC3IOD VDDP0 ();
GNDIOD  GNDP0 ();

VCC3IOD VDDP1 ();
GNDIOD  GNDP1 ();

VCC3IOD VDDP2 ();
GNDIOD  GNDP2 ();

VCC3IOD VDDP3 ();
GNDIOD  GNDP3 ();

VCC3IOD VDDP4 ();
GNDIOD  GNDP4 ();

VCC3IOD VDDP5 ();
GNDIOD  GNDP5 ();
//==================================================================


//==================================================================
// Core power 1.8V pads: VCCKD/GNDKD
// Syntax: VCCKD/GNDKD PAD_NAME ();
//    Ex1: VCCKD       VDDC0 ();
//    Ex2: GNDKD       GNDC0 ();
VCCKD VDDC0 ();
GNDKD GNDC0 ();

VCCKD VDDC1 ();
GNDKD GNDC1 ();

VCCKD VDDC2 ();
GNDKD GNDC2 ();

VCCKD VDDC3 ();
GNDKD GNDC3 ();

VCCKD VDDC4 ();
GNDKD GNDC4 ();

VCCKD VDDC5 ();
GNDKD GNDC5 ();
//==================================================================
// You need to finish this part


endmodule