module Handshake_syn #(parameter WIDTH=32) (
    input  sclk,
    input  dclk,
    input  rst_n,
    input  sready,
    input  [WIDTH-1:0] din,
    input  dbusy,
    output reg sidle,
    output reg dvalid,
    output reg [WIDTH-1:0] dout,

    output flag_handshake_to_clk1,
    input  flag_clk1_to_handshake,
    output flag_handshake_to_clk2,
    input  flag_clk2_to_handshake
);

reg sreq;
wire dreq;
reg dack;
wire sack;

reg [31:0] data_to_transfer;
//Part 3 Seq Logic
// Source domain (sclk)

always @(*) begin
    if(sreq==1'b1) sidle = 1'b0;
    else if(sready==1'b1) sidle = 1'b0;
    else if(sack==1'b1) sidle = 1'b0;
    else sidle = 1'b1;
end

always @(posedge sclk or negedge rst_n) begin
    if(!rst_n) sreq <= 1'b0;
    else if(sack==1'b1) sreq <= 1'b0;   //為了下一輪準備
    else if(sready==1'b1) sreq <= 1'b1;
    else sreq <= sreq;
end

always @ (posedge sclk or negedge rst_n) begin  
	if (!rst_n) data_to_transfer <= 32'd0 ;     //sready==1就是傳入din的那個cycle
	else if (sready==1'b1) data_to_transfer <= din ;
	else data_to_transfer <= data_to_transfer ;
end


// Destination domain (dclk)
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dack <= 1'b0;
    else if(dreq==1'b1 && dbusy==1'b0)dack <= 1'b1;
    else dack <= 1'b0;
end

reg dvalid_tag; //dvalid在每一輪只能上升一個cycle (大哥說對)
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) begin 
        dvalid <= 1'b0; dvalid_tag<=0;
    end
    else if(dreq==1'b1 && dbusy==1'b0 && dvalid_tag==1'b0)begin  
        dvalid <= 1'b1; dvalid_tag<=1'b1;
    end
    else if(sready==1'b1)begin
        //sready==1'b1代表下個input傳入,開始下一輪,可清空dvalid_tag
        dvalid <= 1'b0; dvalid_tag<=0;
    end
    else begin
        dvalid <= 1'b0; dvalid_tag<=dvalid_tag;
    end
end

// latch data only when starting a new request
//因為我們的dreq不會立即變成1，所以要用一個reg把din暫存起來
always @(posedge dclk or negedge rst_n) begin
    if(!rst_n) dout <= 0;
    else if(dreq==1'b1 && dbusy==1'b0 && dvalid_tag==1'b0) dout <= data_to_transfer;
    else dout<=dout;
end

//Part 2 Comb Logic
NDFF_syn U_NDFF_req(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn U_NDFF_ack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

endmodule
