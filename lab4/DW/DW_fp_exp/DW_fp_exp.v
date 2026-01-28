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