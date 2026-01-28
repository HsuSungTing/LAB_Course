module DW_fp_sum3 #(parameter inst_sig_width = 23,
parameter inst_exp_width = 8,
parameter inst_ieee_compliance = 0,
parameter inst_arch_type = 0)
(
input  [inst_sig_width+inst_exp_width:0] a,   // operand A
input  [inst_sig_width+inst_exp_width:0] b,   // operand B
input  [inst_sig_width+inst_exp_width:0] c,   // operand C
input  [2:0] rnd,                             // rounding mode 
output [inst_sig_width+inst_exp_width:0] z,   // sum result
output [7:0] status                          // status flag 
);

wire [inst_sig_width+inst_exp_width:0] sum_ab;
wire [inst_sig_width+inst_exp_width:0] sum_abc;

// === A + B ===
ADD add1 (
    .FP_A(a),
    .FP_B(b),
    .FP_out(sum_ab)
);

// === (A+B) + C ===
ADD add2 (
    .FP_A(sum_ab),
    .FP_B(c),
    .FP_out(sum_abc)
);

assign z      = sum_abc;
assign status = 8'd0; 


endmodule


module ADD(FP_A, FP_B, FP_out);
input  [31:0] FP_A, FP_B;
output [31:0] FP_out;

wire sign_A, sign_B;
reg sign_out;
wire [7:0] exp_A, exp_B;
reg  [7:0] exp_out;
wire [24:0] frac_A, frac_B;
reg  [24:0] frac_out;

assign exp_A  = FP_A[30:23];
assign exp_B  = FP_B[30:23];
assign sign_A = FP_A[31];
assign sign_B = FP_B[31];
assign frac_A = {1'b0, 1'b1, FP_A[22:0]};
assign frac_B = {1'b0, 1'b1, FP_B[22:0]};

reg [7:0] shift_bit;

always @(*) begin
    if (exp_A >= exp_B) shift_bit = exp_A - exp_B;
    else shift_bit = exp_B - exp_A;
end

reg [24:0] frac_A_after_shifting, frac_B_after_shifting;
always @(*) begin
    if (exp_A < exp_B) frac_A_after_shifting = frac_A >> shift_bit;
    else frac_A_after_shifting = frac_A;
end

always @(*) begin
    if (exp_A >= exp_B) frac_B_after_shifting = frac_B >> shift_bit;
    else frac_B_after_shifting = frac_B;
end

always @(*) begin
    if (sign_A == sign_B) frac_out = frac_A_after_shifting + frac_B_after_shifting;
    else if (sign_A == 1'b0 && sign_B == 1'b1) frac_out = frac_A_after_shifting - frac_B_after_shifting;
    else frac_out = frac_B_after_shifting - frac_A_after_shifting;
end

always @(*) begin
    if (sign_A == sign_B) sign_out = sign_A;
    else sign_out = frac_out[24];
end

always @(*) begin
    if (frac_out[24] == 1'b1 && exp_A >= exp_B) exp_out = exp_A + 1;
    else if (frac_out[24] == 1'b1 && exp_A < exp_B) exp_out = exp_B + 1;
    else if (frac_out[24] == 1'b0 && exp_A >= exp_B) exp_out = exp_A;
    else if (frac_out[24] == 1'b0 && exp_A < exp_B) exp_out = exp_B;
    else exp_out = exp_A;
end

assign FP_out = (frac_out[24]) ? {sign_out, exp_out, frac_out[23:1]} :
                                 {sign_out, exp_out, frac_out[22:0]};

endmodule
