`timescale 1ns/1ps

module tb_diff_compare;

    logic [15:0] X;
    logic [15:0] Y_sub;
    logic [15:0] Y_not;

    // Instantiate DUT
    diff_compare dut(
        .X(X),
        .Y_sub(Y_sub),
        .Y_not(Y_not)
    );

    integer i;

    initial begin
        $display("Start testing...");

        // 跑 10000 筆隨機向量
        for (i = 0; i < 10000; i++) begin
            X = $random;

            #1; // 等 combinational settle

            if (Y_sub !== Y_not) begin
                $display("Mismatch at i=%0d: X=%h  Y_sub=%h  Y_not=%h",
                          i, X, Y_sub, Y_not);
                $fatal("FAIL");
            end
        end

        $display("All tests passed! Y_sub == Y_not for all cases.");
        $finish;
    end

endmodule