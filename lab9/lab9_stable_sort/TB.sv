`timescale 1ns/1ps

module tb_merge_sort_4;

    // DUT signals
    reg  [15:0] in0, in1, in2, in3;
    reg  [1:0]  in_char0, in_char1, in_char2, in_char3;
    wire [15:0] out0, out1, out2, out3;
    wire [1:0]  out_char0, out_char1, out_char2, out_char3;

    // instantiate DUT
    merge_sort_4 dut (
        .in0(in0), .in1(in1), .in2(in2), .in3(in3),
        .in_char0(in_char0), .in_char1(in_char1),
        .in_char2(in_char2), .in_char3(in_char3),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3),
        .out_char0(out_char0), .out_char1(out_char1),
        .out_char2(out_char2), .out_char3(out_char3)
    );

    // golden model storage (simple arrays)
    integer i, j, tc;
    reg [15:0] val_in [0:3];
    reg [1:0]  tok_in [0:3];
    reg [15:0] val_expected [0:3];
    reg [1:0]  tok_expected [0:3];

    // produce vcd for waveform inspection
    initial begin
        $dumpfile("tb_merge_sort_4.vcd");
        $dumpvars(0, tb_merge_sort_4);
    end

    // test sequence
    initial begin
        $display("==============================================");
        $display("   Testbench for merge_sort_4 (16-bit + 2-bit)");
        $display("==============================================");

        // test 0: increasing values
        in0 = 16'd1;  in_char0 = 2'd0;
        in1 = 16'd2;  in_char1 = 2'd1;
        in2 = 16'd3;  in_char2 = 2'd2;
        in3 = 16'd4;  in_char3 = 2'd3;
        #1;
        check_and_display(0);

        // test 1: decreasing values
        in0 = 16'd1000; in_char0 = 2'd0;
        in1 = 16'd900;  in_char1 = 2'd1;
        in2 = 16'd800;  in_char2 = 2'd2;
        in3 = 16'd700;  in_char3 = 2'd3;
        #1;
        check_and_display(1);

        // test 2: equal values with different tokens (tie-break)
        in0 = 16'd500; in_char0 = 2'd3;
        in1 = 16'd500; in_char1 = 2'd1; // smaller token -> larger (tie-break)
        in2 = 16'd500; in_char2 = 2'd2;
        in3 = 16'd500; in_char3 = 2'd0; // smallest token -> largest overall
        #1;
        check_and_display(2);

        // random tests
        for (tc = 0; tc < 50; tc = tc + 1) begin
            in0 = $urandom_range(0,65535);
            in1 = $urandom_range(0,65535);
            in2 = $urandom_range(0,65535);
            in3 = $urandom_range(0,65535);
            in_char0 = $urandom_range(0,3);
            in_char1 = $urandom_range(0,3);
            in_char2 = $urandom_range(0,3);
            in_char3 = $urandom_range(0,3);

            #1;
            check_and_display(100 + tc);
        end

        $display("All tests done.");
        $finish;
    end

    // task: compute expected output according to comparator’s ordering,
    // and compare DUT outputs to expected; print result
    task check_and_display(input integer id);
        begin
            // pack inputs into arrays
            val_in[0] = in0; tok_in[0] = in_char0;
            val_in[1] = in1; tok_in[1] = in_char1;
            val_in[2] = in2; tok_in[2] = in_char2;
            val_in[3] = in3; tok_in[3] = in_char3;

            // make expected copy
            for (i = 0; i < 4; i = i + 1) begin
                val_expected[i] = val_in[i];
                tok_expected[i] = tok_in[i];
            end

            // bubble sort for expected results
            // ascending by value; for ties, smaller token = larger (later)
            for (i = 0; i < 4; i = i + 1) begin
                for (j = i + 1; j < 4; j = j + 1) begin
                    if ( (val_expected[i] > val_expected[j]) ||
                         ( (val_expected[i] == val_expected[j]) && (tok_expected[i] > tok_expected[j]) )
                       ) begin
                        {val_expected[i], val_expected[j]} = {val_expected[j], val_expected[i]};
                        {tok_expected[i], tok_expected[j]} = {tok_expected[j], tok_expected[i]};
                    end
                end
            end

            // display
            $display("--------------------------------------------------");
            $display("TC %0d : In  : (%5d,%1d) (%5d,%1d) (%5d,%1d) (%5d,%1d)",
                     id,
                     in0, in_char0, in1, in_char1, in2, in_char2, in3, in_char3);
            $display("       DUT : (%5d,%1d) (%5d,%1d) (%5d,%1d) (%5d,%1d)",
                     out0, out_char0, out1, out_char1, out2, out_char2, out3, out_char3);
            $display("    Expect : (%5d,%1d) (%5d,%1d) (%5d,%1d) (%5d,%1d)",
                     val_expected[0], tok_expected[0],
                     val_expected[1], tok_expected[1],
                     val_expected[2], tok_expected[2],
                     val_expected[3], tok_expected[3]);

            // verify
            if ( (out0 !== val_expected[0]) || (out_char0 !== tok_expected[0]) ||
                 (out1 !== val_expected[1]) || (out_char1 !== tok_expected[1]) ||
                 (out2 !== val_expected[2]) || (out_char2 !== tok_expected[2]) ||
                 (out3 !== val_expected[3]) || (out_char3 !== tok_expected[3]) ) begin
                $display(">>> MISMATCH at TC %0d <<<", id);
                $fatal(1, "Test failed");
            end
            else begin
                $display("OK");
            end
        end
    endtask

endmodule