module Handshake_syn 
#(parameter WIDTH=32) (
input wire              sclk,
input wire              dclk,
input wire              rst_n,
input wire              sready,
input wire [WIDTH-1:0]  din,
input wire              dbusy,
output reg              sidle,
output reg              dvalid,
output reg [WIDTH-1:0]  dout,
//! These flags are no use .
output reg              flag_handshake_to_clk1,
input wire              flag_clk1_to_handshake,
output reg              flag_handshake_to_clk2,
input wire              flag_clk2_to_handshake  );

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [31:0]data_to_transfer;


always @(posedge sclk or negedge rst_n)begin
    if(!rst_n) sidle<= 1;
    else if (sready==1'b1) sidle<= 0;
    else if (sreq==1'b1) sidle<= 0;
    else if (sack==1'b1) sidle<= 0;
    else sidle <= 1;
end

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n)  sreq <= 0;
    else if(sack) sreq <= 1'b0;
    else if(sready==1'b1 && sidle==1'b1) sreq <= 1'b1;
    else sreq <= sreq;
end

//data_to_transfer
always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) data_to_transfer <= 0;
    else if(sready==1'b1 && sidle==1'b1) data_to_transfer <= din;
    else  data_to_transfer <= data_to_transfer;
end

//destination domain
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n)  dack <= 1'b0;
    else if(dreq==1'b1) dack <=1'b1;
    else dack <=1'b0;
end


always @(posedge dclk or negedge rst_n)begin
    if(!rst_n) dvalid <= 1'b0;
    else if(dreq==1'b1 && dack==1'b1)dvalid <= 1'b1;
    else dvalid <= 1'b0 ;
end

always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dout <= 0;
    else if(dreq==1'b1) dout <= data_to_transfer;
    else  dout <= dout;
end


NDFF_syn U_NDFF_req_inst(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn U_NDFF_ack_inst(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));
endmodule