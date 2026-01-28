// tb_cross_product.v
`timescale 1ns/1ps

module tb_cross_product;
    reg  [9:0] Ox, Oy, Ax, Ay, Bx, By;
    wire [1:0] result;

    // DUT
    cross_product dut (
        .Ox(Ox), .Oy(Oy), .Ax(Ax), .Ay(Ay), .Bx(Bx), .By(By),
        .result(result)
    );

    integer i;
    integer ref;           // reference cross product (signed)
    integer expected_calc;
    integer seed;
    integer errors;

    task do_test;
        input [9:0] tOx, tOy, tAx, tAy, tBx, tBy;
        begin
            Ox = tOx; Oy = tOy; Ax = tAx; Ay = tAy; Bx = tBx; By = tBy;
            #1; // combinational settle

            // 参考计算（保持与 DUT 相同的算式 & 有号扩展）
            ref = ($signed({1'b0, tAx}) - $signed({1'b0, tOx})) * ($signed({1'b0, tBy}) - $signed({1'b0, tOy}))
                - ($signed({1'b0, tAy}) - $signed({1'b0, tOy})) * ($signed({1'b0, tBx}) - $signed({1'b0, tOx}));

            if (ref > 0) expected_calc = 2;
            else if (ref == 0) expected_calc = 1;
            else expected_calc = 0;

            $display("O=(%4d,%4d) A=(%4d,%4d) B=(%4d,%4d)  cross=%8d  dut=%0d  exp=%0d  %s",
                tOx,tOy,tAx,tAy,tBx,tBy, ref, result, expected_calc,
                (result==expected_calc) ? "PASS" : "FAIL");

            if (result != expected_calc) errors = errors + 1;
        end
    endtask

    initial begin
        errors = 0;
        seed = 32'hCAFEBABE;

        $display("=== Basic tests ===");
        do_test(0, 0,   1, 0,   0, 1);     // +1 -> positive
        do_test(0, 0,   0, 1,   1, 0);     // -1 -> negative
        do_test(0, 0,   1, 1,   2, 2);     // collinear -> zero
        do_test(100,200, 300,200, 100,400); // 40000 positive
        do_test(1023,1023, 0,0,  1023,0);  // large positive check

        $display("=== Random tests (2000 vectors) ===");
        for (i = 0; i < 2000; i = i + 1) begin
            Ox = $random(seed) & 10'h3FF;
            Oy = $random(seed) & 10'h3FF;
            Ax = $random(seed) & 10'h3FF;
            Ay = $random(seed) & 10'h3FF;
            Bx = $random(seed) & 10'h3FF;
            By = $random(seed) & 10'h3FF;
            #1;

            // compute reference
            ref = ($signed({1'b0, Ax}) - $signed({1'b0, Ox})) * ($signed({1'b0, By}) - $signed({1'b0, Oy}))
                - ($signed({1'b0, Ay}) - $signed({1'b0, Oy})) * ($signed({1'b0, Bx}) - $signed({1'b0, Ox}));

            if (ref > 0) expected_calc = 2;
            else if (ref == 0) expected_calc = 1;
            else expected_calc = 0;

            if (result != expected_calc) begin
                $display("RANDOM FAIL O=(%4d,%4d) A=(%4d,%4d) B=(%4d,%4d) cross=%8d dut=%0d expected=%0d",
                    Ox,Oy,Ax,Ay,Bx,By,ref,result,expected_calc);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
