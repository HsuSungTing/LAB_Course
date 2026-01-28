`timescale 1ns/1ps

module tb_DW_fp_mult;
    localparam sig_width       = 23;
    localparam exp_width       = 8;
    localparam ieee_compliance = 0;
    localparam en_ubr_flag     = 0;

    reg  [sig_width+exp_width:0] a, b;
    reg  [2:0] rnd;
    wire [sig_width+exp_width:0] z;
    wire [7:0] status;

    // Instantiate DUT
    DW_fp_mult #(
        .sig_width(sig_width),
        .exp_width(exp_width),
        .ieee_compliance(ieee_compliance),
        .en_ubr_flag(en_ubr_flag)
    ) UUT (
        .a(a),
        .b(b),
        .rnd(rnd),
        .z(z),
        .status(status)
    );

    // IEEE754 32-bit to real (for display)
    function real fp32_to_real(input [31:0] fp);
        reg [22:0] frac;
        reg [7:0]  exp;
        reg sign;
        real frac_real;
        integer i;
    begin
        sign = fp[31];
        exp  = fp[30:23];
        frac = fp[22:0];
        frac_real = 1.0;
        for (i=0; i<23; i=i+1)
            if (frac[i]) frac_real = frac_real + (1.0 / (2.0**(23-i)));
        fp32_to_real = ((sign)? -1.0:1.0) * frac_real * (2.0**(exp-127));
    end
    endfunction

    initial begin
        $display("=== DW_fp_mult Testbench ===");
        rnd = 3'b000;

        // Case 1: 2.0 * 3.0 = 6.0
        a = 32'h40000000; // 2.0
        b = 32'h40400000; // 3.0
        #10;
        $display("2*3 = %f (0x%h)", fp32_to_real(z), z);

        // Case 2: -2.0 * 3.0 = -6.0
        a = 32'hC0000000; // -2.0
        b = 32'h40400000; // 3.0
        #10;
        $display("-2*3 = %f (0x%h)", fp32_to_real(z), z);

        // Case 3: -1.5 * -2.0 = 3.0
        a = 32'hBFC00000; // -1.5
        b = 32'hC0000000; // -2.0
        #10;
        $display("-1.5*-2 = %f (0x%h)", fp32_to_real(z), z);

        // Case 4: 0 * 5.0 = 0
        a = 32'h00000000; // 0.0
        b = 32'h40A00000; // 5.0
        #10;
        $display("0*5 = %f (0x%h)", fp32_to_real(z), z);

        // Case 5: 大指數差: 1e10 * 1.0 ≈ 1e10
        a = 32'h501502F9; // ~1e10
        b = 32'h3F800000; // 1.0
        #10;
        $display("1e10*1 = %f (0x%h)", fp32_to_real(z), z);

        $display("=== End of Testbench ===");
        $finish;
    end

endmodule
