`timescale 1ns/1ps

module tb_max3;
    parameter WIDTH = 5;

    reg  [WIDTH-1:0] input0, input1, input2;
    wire [WIDTH-1:0] max_val;
    wire [1:0]       max_idx;

    // DUT
    max3 #(.WIDTH(WIDTH)) dut (
        .input0(input0),
        .input1(input1),
        .input2(input2),
        .max_val(max_val),
        .max_idx(max_idx)
    );

    initial begin
        $dumpfile("tb_max3.vcd"); // for GTKWave
        $dumpvars(0, tb_max3);

        // case 1: input0 最大
        input0 = 5'd20; input1 = 5'd10; input2 = 5'd5;
        #5;

        // case 2: input1 最大
        input0 = 5'd5; input1 = 5'd15; input2 = 5'd7;
        #5;

        // case 3: input2 最大
        input0 = 5'd3; input1 = 5'd8; input2 = 5'd12;
        #5;

        // case 4: input0 == input1 > input2 → 選 input0 (idx=0)
        input0 = 5'd10; input1 = 5'd10; input2 = 5'd3;
        #5;

        // case 5: input1 == input2 > input0 → 選 input1 (idx=1)
        input0 = 5'd6; input1 = 5'd14; input2 = 5'd14;
        #5;

        // case 6: input0 == input2 > input1 → 選 input0 (idx=0)
        input0 = 5'd9; input1 = 5'd7; input2 = 5'd9;
        #5;

        // case 7: 三個相等 → 選 input0 (idx=0)
        input0 = 5'd11; input1 = 5'd11; input2 = 5'd11;
        #5;

        $finish;
    end

    // 顯示結果
    initial begin
        $monitor("t=%0t | in0=%0d in1=%0d in2=%0d -> max_val=%0d, max_idx=%0d",
                 $time, input0, input1, input2, max_val, max_idx);
    end

endmodule
