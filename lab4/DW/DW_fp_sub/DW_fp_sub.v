module DW_fp_mult #(
parameter sig_width        = 23,
parameter exp_width        = 8,
parameter ieee_compliance  = 0
)(
input  [sig_width+exp_width:0] a,
input  [sig_width+exp_width:0] b,
input  [2:0] rnd,   
output [sig_width+exp_width:0] z,
output [7:0] status
);

wire sign_A, sign_B;
reg  sign_out;
wire [exp_width-1:0] exp_A, exp_B;
reg  [exp_width-1:0] exp_out;
wire [sig_width:0] frac_A, frac_B;      
reg  [sig_width-1:0] frac_out;
wire [(sig_width+1)*2-1:0] frac_AXB;    

// 分解輸入
assign sign_A = a[sig_width+exp_width];
assign sign_B = b[sig_width+exp_width];
assign exp_A  = a[sig_width+exp_width-1 : sig_width];
assign exp_B  = b[sig_width+exp_width-1 : sig_width];
assign frac_A = {1'b1, a[sig_width-1:0]}; 
assign frac_B = {1'b1, b[sig_width-1:0]};

always @(*) begin
    sign_out = sign_A ^ sign_B;
end

assign frac_AXB = frac_A * frac_B;

always @(*) begin
    if (frac_AXB[(sig_width+1)*2-1] == 1'b1)
        frac_out = frac_AXB[(sig_width+1)*2-2 : sig_width]; 
    else
        frac_out = frac_AXB[(sig_width+1)*2-3 : sig_width-1];
end

always @(*) begin
    if (frac_AXB[(sig_width+1)*2-1] == 1'b1)
        exp_out = exp_A + exp_B - ((1<<(exp_width-1))-1) + 1; 
    else
        exp_out = exp_A + exp_B - ((1<<(exp_width-1))-1);
end

assign z = {sign_out, exp_out, frac_out};

assign status = 8'd0;

endmodule
