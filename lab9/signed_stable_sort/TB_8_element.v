`timescale 1ns/1ps

module tb_merge_sort;
    // Inputs to DUT
    reg signed [6:0] in0, in1, in2, in3, in4, in5, in6, in7;
    reg [4:0] in_char0, in_char1, in_char2, in_char3, in_char4, in_char5, in_char6, in_char7;

    // Outputs from DUT
    wire signed [6:0] out0, out1, out2, out3, out4, out5, out6, out7;
    wire [4:0]       out_char0, out_char1, out_char2, out_char3, out_char4, out_char5, out_char6, out_char7;

    // Instantiate the DUT (assumes merge_sort is in scope)
    merge_sort DUT (
        in0, in1, in2, in3, in4, in5, in6, in7,
        in_char0, in_char1, in_char2, in_char3, in_char4, in_char5, in_char6, in_char7,
        out0, out1, out2, out3, out4, out5, out6, out7,
        out_char0, out_char1, out_char2, out_char3, out_char4, out_char5, out_char6, out_char7
    );

    // Utility task: apply inputs, wait small delay, print
    task apply_and_print;
        input signed [6:0] a0, a1, a2, a3, a4, a5, a6, a7;
        input [4:0] t0, t1, t2, t3, t4, t5, t6, t7;
        begin
            in0 = a0; in1 = a1; in2 = a2; in3 = a3;
            in4 = a4; in5 = a5; in6 = a6; in7 = a7;
            in_char0 = t0; in_char1 = t1; in_char2 = t2; in_char3 = t3;
            in_char4 = t4; in_char5 = t5; in_char6 = t6; in_char7 = t7;
            #1; // give combinational logic a tiny moment to settle
            // Print inputs and outputs in a single line for easy diffing/logging
            $display("OUT : %4d(%2d) %4d(%2d) %4d(%2d) %4d(%2d) %4d(%2d) %4d(%2d) %4d(%2d) %4d(%2d)",
                     out0, out_char0, out1, out_char1, out2, out_char2, out3, out_char3,
                     out4, out_char4, out5, out_char5, out6, out_char6, out7, out_char7);
        end
    endtask

    // convenience: clamp a 32-bit random to signed 7-bit range -64..63
    function signed [6:0] rand_val_7bit;
        input integer seed;
        integer r;
        begin
            r = $random(seed);
            // map into -64..63
            r = r % 128;
            if (r < 0) r = r + 128;
            rand_val_7bit = r - 64;
        end
    endfunction

    // convenience: random token in 1..7
    function [4:0] rand_token_1_7;
        input integer seed;
        integer r;
        begin
            r = $random(seed);
            r = r % 7;
            if (r < 0) r = r + 7;
            rand_token_1_7 = r + 1;
        end
    endfunction

    integer i;
    integer RANDOM_TESTS;
    initial begin
        $display("=== Starting very, very, very long testbench for merge_sort ===");
        $display("Format: time | IN : val(token) ... | OUT : val(token) ...");
        $display("Note: tokens limited to 1..7; values limited to -64..63 (signed 7-bit)\n");

        RANDOM_TESTS = 10; // <-- 如果你要更多，把这个数调更大

        // ----------------------------
        // some deterministic edge-case tests
        // ----------------------------
        // 1) all zeros, different tokens
        apply_and_print(0,0,0,0,0,0,0,0, 1,2,3,4,5,6,7,1);

        // 2) all same positive value, tokens ascending
        apply_and_print(10,10,10,10,10,10,10,10, 1,2,3,4,5,6,7,1);

        // 3) all same negative value, tokens descending
        apply_and_print(-12,-12,-12,-12,-12,-12,-12,-12, 7,6,5,4,3,2,1,7);

        // 4) mixture with ties: some duplicates with different tokens
        apply_and_print(5, 5, -3, 5, -3, 5, 5, -3,  1,2,3,4,5,6,7,1);

        // 5) extremes
        apply_and_print(-64, 63, -64, 63, -64, 63, -1, 1, 1,2,3,4,5,6,7,1);

        // 6) ascending values, tokens random
        apply_and_print(-10,-5,0,3,8,12,20,63, rand_token_1_7(1),rand_token_1_7(2),rand_token_1_7(3),rand_token_1_7(4),rand_token_1_7(5),rand_token_1_7(6),rand_token_1_7(7),rand_token_1_7(8));

        // 7) descending values, tokens random
        apply_and_print(63,20,12,8,3,0,-5,-10, rand_token_1_7(9),rand_token_1_7(10),rand_token_1_7(11),rand_token_1_7(12),rand_token_1_7(13),rand_token_1_7(14),rand_token_1_7(15),rand_token_1_7(16));

        // 8) alternating sign pattern
        apply_and_print(-1, 1, -2, 2, -3, 3, -4, 4, 1,2,3,4,5,6,7,1);

        // 9) pairwise equals to exercise tie-breaking heavily
        apply_and_print(7,7,7,7,0,0,0,0, 1,2,3,4,5,6,7,1);
        apply_and_print(-5,-5,5,5,-5,-5,5,5, 7,1,6,2,5,3,4,1);

        // 10) single-element extremes, rest medium
        apply_and_print(63, 0, 0, 0, 0, 0, 0, -64, 1,2,3,4,5,6,7,1);

        // 11) wrap-around potential values using explicit numbers near boundaries
        apply_and_print(62, 63, -63, -64, 61, -61, 0, -1, 1,2,3,4,5,6,7,1);

        // ----------------------------
        // Some structured sweeps (not exhaustive but covers patterns)
        // ----------------------------
        // sweep a small set of value patterns
        for (i = 0; i < 8; i = i + 1) begin
            // pattern: shift a single -value around
            apply_and_print((i==0)?-20:5, (i==1)?-20:5, (i==2)?-20:5, (i==3)?-20:5,
                            (i==4)?-20:5, (i==5)?-20:5, (i==6)?-20:5, (i==7)?-20:5,
                            rand_token_1_7(i+1), rand_token_1_7(i+2), rand_token_1_7(i+3), rand_token_1_7(i+4),
                            rand_token_1_7(i+5), rand_token_1_7(i+6), rand_token_1_7(i+7), rand_token_1_7(i+8));
        end

        // sweep with moving positive large values
        for (i = 0; i < 8; i = i + 1) begin
            apply_and_print((i==0)?30:0, (i==1)?30:0, (i==2)?30:0, (i==3)?30:0, (i==4)?30:0, (i==5)?30:0, (i==6)?30:0, (i==7)?30:0,
                            1,2,3,4,5,6,7,1);
        end

        // ----------------------------
        // Focused tie-breaking stress tests:
        // many equal values but tokens permuted
        // ----------------------------
        // build a few cases where 4 or more values equal
        apply_and_print(9,9,9,9,1,2,3,4, 7,6,5,4,3,2,1,7);
        apply_and_print(-7,-7,-7,-7,-7,-7,-7,-7, 1,2,3,4,5,6,7,1);

        // create cases with pairs equal across array, tokens intentionally arranged to flip ordering
        apply_and_print(15,15, -15,-15, 15,15, -15,-15, 1,7,2,6,3,5,4,1);

        // ----------------------------
        // Large random batch
        // ----------------------------
        // Use $random seeded with deterministic seeds for reproducibility
        for (i = 0; i < RANDOM_TESTS; i = i + 1) begin
            // use i as seed to get deterministic different random values
            apply_and_print(
                rand_val_7bit(i*11 + 123), rand_val_7bit(i*13 + 456), rand_val_7bit(i*17 + 789), rand_val_7bit(i*19 + 1011),
                rand_val_7bit(i*23 + 1213), rand_val_7bit(i*29 + 1415), rand_val_7bit(i*31 + 1617), rand_val_7bit(i*37 + 1819),
                rand_token_1_7(i*3 + 101), rand_token_1_7(i*5 + 202), rand_token_1_7(i*7 + 303), rand_token_1_7(i*11 + 404),
                rand_token_1_7(i*13 + 505), rand_token_1_7(i*17 + 606), rand_token_1_7(i*19 + 707), rand_token_1_7(i*23 + 808)
            );
        end

        // ----------------------------
        // Some intentional pathological/randomized tie clusters
        // ----------------------------
        // Many duplicates but tokens shuffled
        for (i = 0; i < 50; i = i + 1) begin
            // pick one of a few repeated values to emphasize tie resolution
            case (i % 5)
                0: apply_and_print(3,3,3,3,3,3,3,3, rand_token_1_7(i), rand_token_1_7(i+1), rand_token_1_7(i+2), rand_token_1_7(i+3), rand_token_1_7(i+4), rand_token_1_7(i+5), rand_token_1_7(i+6), rand_token_1_7(i+7));
                1: apply_and_print(-8,-8,-8,-8,7,7,7,7, rand_token_1_7(i+2), rand_token_1_7(i+3), rand_token_1_7(i+4), rand_token_1_7(i+5), rand_token_1_7(i+6), rand_token_1_7(i+7), rand_token_1_7(i+8), rand_token_1_7(i+9));
                2: apply_and_print(12,12,12,-12,-12,12,-12,12, rand_token_1_7(i+11), rand_token_1_7(i+12), rand_token_1_7(i+13), rand_token_1_7(i+14), rand_token_1_7(i+15), rand_token_1_7(i+16), rand_token_1_7(i+17), rand_token_1_7(i+18));
                3: apply_and_print(0,0,1,1,0,0,1,1, 1,7,2,6,3,5,4,1);
                default: apply_and_print(rand_val_7bit(i+200), rand_val_7bit(i+201), rand_val_7bit(i+202), rand_val_7bit(i+203), rand_val_7bit(i+204), rand_val_7bit(i+205), rand_val_7bit(i+206), rand_val_7bit(i+207),
                                         rand_token_1_7(i+21), rand_token_1_7(i+22), rand_token_1_7(i+23), rand_token_1_7(i+24), rand_token_1_7(i+25), rand_token_1_7(i+26), rand_token_1_7(i+27), rand_token_1_7(i+28));
            endcase
        end

        $display("\n=== Testbench finished. Total random tests = %0d (plus deterministic cases) ===", RANDOM_TESTS);
        $finish;
    end

endmodule