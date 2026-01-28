`timescale 1ns/1ps

module abs_signed_tb;
    // DUT signals
    reg  signed [31:0] w;
    wire signed [31:0] abs_w;

    // 被测试逻辑 (DUT)
    assign abs_w = (w < 0) ? -w : w;

    // 输出任务：显示有号的十进制结果
    task print_case;
        input signed [31:0] val;
        begin
            w = val;
            #1; // 等待组合逻辑稳定
            $display("Time=%0t | w=%0d | abs_w=%0d",
                      $time, w, abs_w);
        end
    endtask

    initial begin
        $display("=== ABS (signed) TestBench (Decimal Output) ===");

        // 测试正数
        print_case(32'sd0);
        print_case(32'sd5);
        print_case(32'sd12345);

        // 测试负数
        print_case(-32'sd5);
        print_case(-32'sd12345);

        // 测试边界值
        print_case(32'sh7FFFFFFF);   // +2147483647
        print_case(-32'sh7FFFFFFF);  // -2147483647

        $display("=== Test Completed ===");
        $finish;
    end
endmodule