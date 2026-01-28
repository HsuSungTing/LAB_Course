//==for debug===
module DW_fp_cmp #(parameter inst_sig_width = 23,
parameter inst_exp_width = 8,
parameter inst_ieee_compliance = 0)
(
input  [inst_sig_width+inst_exp_width:0] a,   
input  [inst_sig_width+inst_exp_width:0] b,   
input        zctr,                            
output reg   aeqb,                            
output reg   altb,                            
output reg   agtb,                            
output       unordered,                       
output reg   z0,                              
output reg   z1,                              
output [7:0] status0,                         
output [7:0] status1                          
);

wire sign_A, sign_B;
wire [inst_exp_width-1:0] exp_A, exp_B;
wire [inst_sig_width-1:0] frac_A, frac_B;

assign sign_A = a[inst_sig_width+inst_exp_width];
assign exp_A  = a[inst_sig_width+inst_exp_width-1 : inst_sig_width];
assign frac_A = a[inst_sig_width-1:0];

assign sign_B = b[inst_sig_width+inst_exp_width];
assign exp_B  = b[inst_sig_width+inst_exp_width-1 : inst_sig_width];
assign frac_B = b[inst_sig_width-1:0];

assign unordered = 1'b0;  // 這裡不實作 NaN 判斷
assign status0   = 8'd0;
assign status1   = 8'd0;

always @(*) begin
    aeqb = 0;
    altb = 0;
    agtb = 0;
    z0   = 0;
    z1   = 0;

    if (a == b) begin
        aeqb = 1'b1;
    end
    else begin
        if (sign_A != sign_B) begin
            if (sign_A == 1'b0) agtb = 1'b1; // A 正, B 負
            else altb = 1'b1;                // A 負, B 正
        end
        else begin
            if (exp_A > exp_B) begin
                if (sign_A == 1'b0) agtb = 1'b1;
                else altb = 1'b1;
            end
            else if (exp_A < exp_B) begin
                if (sign_A == 1'b0) altb = 1'b1;
                else agtb = 1'b1;
            end
            else begin
                if (frac_A > frac_B) begin
                    if (sign_A == 1'b0) agtb = 1'b1;
                    else altb = 1'b1;
                end
                else if (frac_A < frac_B) begin
                    if (sign_A == 1'b0) altb = 1'b1;
                    else agtb = 1'b1;
                end
            end
        end
    end

    // 根據 zctr 決定輸出 z0/z1 (這裡比照 DW_fp_cmp 的行為)
    if (zctr) begin
        z0 = altb;  // min
        z1 = agtb;  // max
    end
    else begin
        z0 = agtb;  // max
        z1 = altb;  // min
    end
end

endmodule

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

module DW_fp_exp #(
    parameter inst_sig_width       = 23,
    parameter inst_exp_width       = 8,
    parameter inst_ieee_compliance = 0,
    parameter inst_arch            = 0
)(
    input  wire [inst_sig_width+inst_exp_width:0] a,   // IEEE754 input
    output wire [inst_sig_width+inst_exp_width:0] z,   // IEEE754 exp(x)
    output wire [7:0] status                         // status flags (simplified)
);

    // === Local parameters ===
    localparam WIDTH = inst_sig_width + inst_exp_width + 1; // e.g., 32

    // === Decode input ===
    wire sign_in            = a[WIDTH-1];
    wire [inst_exp_width-1:0] exp_in  = a[WIDTH-2:inst_sig_width];
    wire [inst_sig_width-1:0] frac_in = a[inst_sig_width-1:0];

    // Special cases: NaN, Inf
    wire is_nan  = (exp_in == {inst_exp_width{1'b1}}) && (frac_in != 0);
    wire is_inf  = (exp_in == {inst_exp_width{1'b1}}) && (frac_in == 0) && !sign_in;
    wire is_ninf = (exp_in == {inst_exp_width{1'b1}}) && (frac_in == 0) &&  sign_in;

    // Convert to signed fixed-point Q8.24 (rough)
    integer E;
    reg [inst_sig_width:0] M; // mantissa with hidden bit
    reg signed [31:0] xin_q;
    always @(*) begin
        if (exp_in == 0) begin
            M = {1'b0, frac_in}; // subnormal
            E = 1 - ((1 << (inst_exp_width-1)) - 1);
        end else begin
            M = {1'b1, frac_in};
            E = exp_in - ((1 << (inst_exp_width-1)) - 1);
        end
        xin_q = (M <<< 7) >>> inst_sig_width; // rough mantissa to Q8
        xin_q = xin_q + (E <<< 24);           // shift exponent into Q8.24
        if (sign_in) xin_q = -xin_q;
    end

    // Multiply by log2(e) ≈ 1.4426950408889634 (Q2.30)
    localparam signed [31:0] LOG2E = 32'sd1549082000; // ≈1.442695 in Q2.30
    wire signed [63:0] mul_q    = xin_q * LOG2E;
    wire signed [31:0] exp2_arg = mul_q >>> 30; // Q8.24 again

    // Split integer/fraction
    wire signed [7:0] int_part = exp2_arg[31:24];
    wire [23:0] frac_part      = exp2_arg[23:0];

    // Polynomial coefficients for 2^x approximation
    localparam signed [31:0] C0 = 32'sd1073741824; // 1.0
    localparam signed [31:0] C1 = 32'sd744261117;  // 0.693
    localparam signed [31:0] C2 = 32'sd258867450;  // 0.241
    localparam signed [31:0] C3 = 32'sd55790968;   // 0.052
    localparam signed [31:0] C4 = 32'sd13925132;   // 0.013

    wire signed [31:0] f_q = {8'b0, frac_part};

    wire signed [63:0] f2 = (f_q * f_q) >>> 30;
    wire signed [63:0] f3 = (f2  * f_q) >>> 30;
    wire signed [63:0] f4 = (f3  * f_q) >>> 30;

    wire signed [63:0] poly_q = C0 
                              + ((C1 * f_q) >>> 30) 
                              + ((C2 * f2) >>> 30)
                              + ((C3 * f3) >>> 30)
                              + ((C4 * f4) >>> 30);

    // Shift by integer part (2^int_part)
    wire [63:0] shifted = (int_part >= 0) ? (poly_q <<< int_part) 
                                          : (poly_q >>> -int_part);
    integer lz;
    reg [31:0] mant;
    reg [inst_exp_width-1:0] exp_out;

    // Pack back into IEEE754 (simplified, no rounding)
    reg [WIDTH-1:0] result;
    always @(*) begin
        if (is_nan) begin
            result = {1'b0, {inst_exp_width{1'b1}}, {1'b1, {inst_sig_width-1{1'b0}}}}; // canonical NaN
        end else if (is_inf) begin
            result = {1'b0, {inst_exp_width{1'b1}}, {inst_sig_width{1'b0}}}; // +INF
        end else if (is_ninf) begin
            result = {WIDTH{1'b0}}; // exp(-inf)=0
        end else if (shifted[63:32] != 0) begin
            result = {1'b0, {inst_exp_width{1'b1}}, {inst_sig_width{1'b0}}}; // overflow -> +Inf
        end else begin
            mant = shifted[31:0];
            lz = 0;
            while (mant[31] == 0 && mant != 0 && lz < 31) begin
                mant = mant << 1;
                lz   = lz + 1;
            end
            exp_out = ((1 << (inst_exp_width-1)) - 1) + (31 - lz);
            result  = {1'b0, exp_out, mant[30:8]};
        end
    end

    assign z      = result;
    assign status = 8'd0; // simplified, no exception flags
endmodule

module DW_fp_mult #(
parameter sig_width        = 23,
parameter exp_width        = 8,
parameter ieee_compliance  = 0,
parameter en_ubr_flag      = 0
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

module DW_fp_sum4 #(
parameter inst_sig_width       = 23,
parameter inst_exp_width       = 8,
parameter inst_ieee_compliance = 0,
parameter inst_arch_type       = 0
)(
input  [inst_sig_width+inst_exp_width:0] a,
input  [inst_sig_width+inst_exp_width:0] b,
input  [inst_sig_width+inst_exp_width:0] c,
input  [inst_sig_width+inst_exp_width:0] d,
input  [2:0] rnd,
output [inst_sig_width+inst_exp_width:0] z,
output [7:0] status
);

wire [31:0] sum_ab, sum_cd;

ADD add1(.FP_A(a), .FP_B(b), .FP_out(sum_ab));
ADD add2(.FP_A(c), .FP_B(d), .FP_out(sum_cd));

ADD add3(.FP_A(sum_ab), .FP_B(sum_cd), .FP_out(z));

assign status = 8'd0;  // 不實作 overflow/NaN flag

endmodule
//=============