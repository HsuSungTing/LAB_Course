`timescale 1ns/1ps

module tb_DW_fp_exp;

  // === Parameters ===
  localparam SIG_WIDTH       = 23;
  localparam EXP_WIDTH       = 8;
  localparam IEEE_COMPLIANCE = 0;
  localparam ARCH            = 0;
  localparam WIDTH           = SIG_WIDTH + EXP_WIDTH + 1; // 32 for single-precision

  // === DUT signals ===
  reg  [WIDTH-1:0] a;
  wire [WIDTH-1:0] z;
  wire [7:0]       status;

  // === DUT instance ===
  DW_fp_exp #(
    .inst_sig_width(SIG_WIDTH),
    .inst_exp_width(EXP_WIDTH),
    .inst_ieee_compliance(IEEE_COMPLIANCE),
    .inst_arch(ARCH)
  ) UUT (
    .a(a),
    .z(z),
    .status(status)
  );

  // === Task: print result (hex only, no $bitstoshortreal) ===
  task print_result;
    input [WIDTH-1:0] a_val;
    input [WIDTH-1:0] z_val;
    input [7:0]       st_val;
    begin
      $display("time=%0t | a=0x%h -> z=0x%h, status=%b",
                $time, a_val, z_val, st_val);
    end
  endtask

  // === Stimulus ===
  initial begin
    $display("=== DW_fp_exp Testbench ===");

    // Test 1: exp(0.0) = 1.0
    a = 32'h00000000; #10; print_result(a, z, status);

    // Test 2: exp(1.0) ≈ 2.71828
    a = 32'h3F800000; #10; print_result(a, z, status);

    // Test 3: exp(-1.0) ≈ 0.36788
    a = 32'hBF800000; #10; print_result(a, z, status);

    // Test 4: exp(2.0) ≈ 7.38906
    a = 32'h40000000; #10; print_result(a, z, status);

    // Test 5: exp(-10.0) ≈ 4.54e-05
    a = 32'hC1200000; #10; print_result(a, z, status);

    // Test 6: +INF
    a = 32'h7F800000; #10; print_result(a, z, status);

    // Test 7: -INF
    a = 32'hFF800000; #10; print_result(a, z, status);

    // Test 8: NaN
    a = 32'h7FC00001; #10; print_result(a, z, status);

    $display("=== Simulation done ===");
    $finish;
  end

endmodule