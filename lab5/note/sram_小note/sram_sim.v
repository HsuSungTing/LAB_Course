`timescale 1ns/1ps
//just for test
module single_port_sync_ram
# (parameter ADDR_WIDTH = 4, parameter DATA_WIDTH = 32, parameter DEPTH = 16)
( 	input 				 clk,
	input [ADDR_WIDTH-1:0] A,
    input [DATA_WIDTH-1:0] DI,
	output reg [DATA_WIDTH-1:0] DO,
    input 				   CS,
	input 				   WEN,
    input 				   OE
);
reg prev_OE,prev_CS,prev_WEN;
reg [DATA_WIDTH-1:0] prev_DI;
reg [ADDR_WIDTH-1:0] prev_A;

reg [DATA_WIDTH-1:0] tmp_data;
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

always @ (posedge clk) begin
    prev_A<=A;
    prev_DI<=DI;
    prev_OE<=OE;
    prev_CS<=CS;
    prev_WEN<=WEN;
end

always @ (posedge clk) begin
    if (prev_OE==1 && prev_CS==1 & prev_WEN==1'b0) //WEN active low
        mem[prev_A] <= prev_DI;
end

always @ (posedge clk) begin
    if (prev_OE==1 && prev_CS==1 && prev_WEN==1'b1)#1 DO <= mem[prev_A];
    else if(prev_OE==1 && prev_CS==1 && prev_WEN==1'b0)#1 DO <=prev_DI;
    else DO <= 'dx;
end

endmodule