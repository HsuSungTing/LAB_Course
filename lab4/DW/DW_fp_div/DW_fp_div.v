module DW_fp_div #(
parameter sig_width        = 23,
parameter exp_width        = 8,
parameter ieee_compliance  = 0,
parameter faithful_round   = 0,
parameter en_ubr_flag      = 0
)(
input  [sig_width+exp_width:0] a,   // dividend
input  [sig_width+exp_width:0] b,   // divisor
input  [2:0] rnd,                   // rounding mode
output [sig_width+exp_width:0] z,   // quotient
output [7:0] status
);

wire sign_a, sign_b, sign_q;
wire [exp_width-1:0] exp_a, exp_b;
reg  [exp_width-1:0] exp_q;
wire [sig_width:0] mant_a, mant_b;      
reg  [sig_width-1:0] mant_res;
wire [(sig_width*2+1):0] mant_div;      
reg  [exp_width-1:0] exp_diff;

assign sign_a = a[sig_width+exp_width];
assign sign_b = b[sig_width+exp_width];
assign exp_a  = a[sig_width+exp_width-1 : sig_width];
assign exp_b  = b[sig_width+exp_width-1 : sig_width];
assign mant_a = (exp_a == 0) ? {1'b0, a[sig_width-1:0]} : {1'b1, a[sig_width-1:0]};
assign mant_b = (exp_b == 0) ? {1'b0, b[sig_width-1:0]} : {1'b1, b[sig_width-1:0]};

assign sign_q = sign_a ^ sign_b;

always @(*) begin
    exp_diff = exp_a - exp_b + ((1 << (exp_width-1)) - 1);
end

assign mant_div = (mant_a << sig_width) / mant_b;

always @(*) begin
    if (mant_div[sig_width+1]) begin
        mant_res = mant_div[sig_width+1 : 1]; 
        exp_q    = exp_diff + 1;
    end else begin
        mant_res = mant_div[sig_width : 1];
        exp_q    = exp_diff;
    end
end

assign z = {sign_q, exp_q, mant_res};
assign status = 8'd0;

endmodule