`timescale 1ns/1ps 
 
module tb_DW_fp_div;

  // 參數化 (單精度: 23-bit mantissa + 8-bit exponent)
  localparam SIG_WIDTH = 23;
  localparam EXP_WIDTH = 8;
  localparam WIDTH     = SIG_WIDTH + EXP_WIDTH + 1; // 32

  reg  [WIDTH-1:0] a, b;
  reg  [2:0] rnd;
  wire [WIDTH-1:0] z;
  wire [7:0]       status;

  // 測試模組
  DW_fp_div #(
    .sig_width(SIG_WIDTH),
    .exp_width(EXP_WIDTH)
  ) UUT (
    .a(a),
    .b(b),
    .rnd(rnd),
    .z(z),
    .status(status)
  );

  // 輔助任務: 印出結果 (十六進位)
  task show_result;
    input [WIDTH-1:0] op_a;
    input [WIDTH-1:0] op_b;
    input [WIDTH-1:0] res;
    begin
      $display("time=%0t | a=0x%h, b=0x%h => z=0x%h, status=%0d",
                $time, op_a, op_b, res, status);
    end
  endtask

  initial begin
    $display("==== DW_fp_div Testbench Start ====");
    rnd = 3'b000; // round to nearest (未真正實作, 但保留介面)

    // 測試 1: 6 / 3 = 2
    a = 32'h40C00000; // 6.0
    b = 32'h40400000; // 3.0
    #10; show_result(a, b, z);

    // 測試 2: -10 / 2 = -5
    a = 32'hC1200000; // -10.0
    b = 32'h40000000; // 2.0
    #10; show_result(a, b, z);

    // 測試 3: 0 / 5 = 0
    a = 32'h00000000; // 0.0
    b = 32'h40A00000; // 5.0
    #10; show_result(a, b, z);

    // 測試 4: 大數 / 小數
    a = 32'h7F7FFFFF; // 最大有限浮點數
    b = 32'h3F800000; // 1.0
    #10; show_result(a, b, z);

    // 測試 5: 小數 / 大數
    a = 32'h3F800000; // 1.0
    b = 32'h7F7FFFFF; // 最大有限浮點數
    #10; show_result(a, b, z);

    $display("==== DW_fp_div Testbench End ====");
    $finish;
  end

endmodule