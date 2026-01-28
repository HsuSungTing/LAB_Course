module tb_compare_sort;

    logic [15:0] in[3:0];
    logic [1:0]  inc[3:0];

    logic [15:0] out_ref[3:0], out_new[3:0];
    logic [1:0]  outc_ref[3:0], outc_new[3:0];

    // DUTs
    merge_sort_4 inst(
        in[0], in[1], in[2], in[3],
        inc[0], inc[1], inc[2], inc[3],
        out_ref[0], out_ref[1], out_ref[2], out_ref[3],
        outc_ref[0], outc_ref[1], outc_ref[2], outc_ref[3]
    );

    merge_sort_4_three_stage dut(
        in[0], in[1], in[2], in[3],
        inc[0], inc[1], inc[2], inc[3],
        out_new[0], out_new[1], out_new[2], out_new[3],
        outc_new[0], outc_new[1], outc_new[2], outc_new[3]
    );

    integer i;

    initial begin
        $display("Start testing...");
        for (i=0; i<100000; i=i+1) begin
            // random inputs
            in[0] = $urandom();
            in[1] = $urandom();
            in[2] = $urandom();
            in[3] = $urandom();

            inc[0] = $urandom_range(0,3);
            inc[1] = $urandom_range(0,3);
            inc[2] = $urandom_range(0,3);
            inc[3] = $urandom_range(0,3);

            #1;
            $display("REF out = %p, char = %p", out_ref, outc_ref);
            $display("NEW out = %p, char = %p", out_new, outc_new);
            
            if (out_ref[0] !== out_new[0] ||
                out_ref[1] !== out_new[1] ||
                out_ref[2] !== out_new[2] ||
                out_ref[3] !== out_new[3] ||
                outc_ref[0] !== outc_new[0] ||
                outc_ref[1] !== outc_new[1] ||
                outc_ref[2] !== outc_new[2] ||
                outc_ref[3] !== outc_new[3]) begin

                $display("Mismatch at iter %d!", i);
                $display("REF out = %p, char = %p", out_ref, outc_ref);
                $display("NEW out = %p, char = %p", out_new, outc_new);
                $finish;
            end
        end

        $display("PASS! All outputs match.");
        $finish;
    end
endmodule
