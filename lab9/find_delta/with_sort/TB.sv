`timescale 1ns/1ps

module tb_find_delta;

    logic [1:0] type_in;
    logic [15:0] MP, HP, ATK, DEF;

    logic [15:0] Delta_MP, Delta_HP, Delta_ATK, Delta_DEF;
    logic [15:0] sorted_A0, sorted_A1, sorted_A2, sorted_A3;

    // DUT
    find_delta uut(
        .type_in(type_in),
        .MP(MP), .HP(HP), .ATK(ATK), .DEF(DEF),
        .Delta_MP(Delta_MP),
        .Delta_HP(Delta_HP),
        .Delta_ATK(Delta_ATK),
        .Delta_DEF(Delta_DEF),
        .sorted_A0(sorted_A0),
        .sorted_A1(sorted_A1),
        .sorted_A2(sorted_A2),
        .sorted_A3(sorted_A3)
    );

    task apply_case(
        input [1:0] t,
        input [15:0] m, h, a, d
    );
    begin
        type_in = t;
        MP = m; HP = h; ATK = a; DEF = d;

        #1;

        $display("------------------------------------------------------------");
        $display("TYPE=%0d | MP=%0d  HP=%0d  ATK=%0d  DEF=%0d",
            t, m, h, a, d);

        $display("Delta_MP=%0d  Delta_HP=%0d  Delta_ATK=%0d  Delta_DEF=%0d",
            Delta_MP, Delta_HP, Delta_ATK, Delta_DEF);

        $display("Sorted → %0d, %0d, %0d, %0d",
            sorted_A0, sorted_A1, sorted_A2, sorted_A3);

        $display("------------------------------------------------------------\n");
    end
    endtask

    initial begin
        $display("===== Enhanced Testbench Start =====\n");

        // --------------------------------------
        // Type A 測資 (至少 3 種)
        // --------------------------------------
        $display("### TYPE A TESTS ###");
        apply_case(2'd0, 100, 200, 300, 400);       // 正常差距
        apply_case(2'd0, 0, 0, 0, 0);               // 全 0
        apply_case(2'd0, 65535, 10000, 5000, 1234); // 大數混合

        // --------------------------------------
        // Type B 測資 (至少 5 種)
        // --------------------------------------
        $display("### TYPE B TESTS ###");

        apply_case(2'd1, 50, 1000, 1000, 200);       // 常見亂序
        apply_case(2'd1, 9999, 1, 5432, 20000);     // 大亂序
        apply_case(2'd1, 9999, 1, 9999, 20000);     // 大亂序
        apply_case(2'd1, 1000, 1000, 1000, 1000);   // 全相等
        apply_case(2'd1, 20000, 15000, 10000, 5000);// 完全反序
        apply_case(2'd1, 123, 234, 345, 456);       // 已排序（微差）

        // --------------------------------------
        // Type C 測資 (至少 3 種)
        // --------------------------------------
        $display("### TYPE C TESTS ###");
        apply_case(2'd2, 10000, 20000, 500, 17000); // 混合：低於/高於 16383
        apply_case(2'd2, 0, 16000, 16383, 20000);   // Boundary 測試
        apply_case(2'd2, 20000, 30000, 40000, 50000); // 全超過 → 全 0

        // --------------------------------------
        // Type D 測資 (至少 3 種)
        // --------------------------------------
        $display("### TYPE D TESTS ###");
        apply_case(2'd3, 0, 10000, 20000, 30000);   // MP → 最高補值，容易 clamp
        apply_case(2'd3, 65535, 65535, 65535, 65535); // 全最低補值
        apply_case(2'd3, 40000, 20000, 100, 60000);   // 混合，大量跨越 5047

        $display("\n===== Enhanced Testbench Finished =====");
        $finish;
    end

endmodule
