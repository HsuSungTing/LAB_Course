`timescale 1ns/1ps

module tb_point_in_box;

    // 測試輸入
    reg  [31:0] Ax, Ay, Bx, By, Px, Py;
    wire inside;

    // DUT
    point_in_box dut (
        .Ax(Ax), .Ay(Ay),
        .Bx(Bx), .By(By),
        .Px(Px), .Py(Py),
        .inside(inside)
    );

    // 測試流程
    initial begin
        $display("=== Test Start ===");

        // case 1: 點在框內
        Ax=0; Ay=0; Bx=10; By=10; Px=5; Py=5;
        #1 $display("Case1 Inside: %b (expect 1)", inside);

        // case 2: 點在框外 (X 太小)
        Px=-1; Py=5;
        #1 $display("Case2 Outside (X too small): %b (expect 0)", inside);

        // case 3: 點在框外 (X 太大)
        Px=11; Py=5;
        #1 $display("Case3 Outside (X too big): %b (expect 0)", inside);

        // case 4: 點在框外 (Y 太小)
        Px=5; Py=-2;
        #1 $display("Case4 Outside (Y too small): %b (expect 0)", inside);

        // case 5: 點在框外 (Y 太大)
        Px=5; Py=20;
        #1 $display("Case5 Outside (Y too big): %b (expect 0)", inside);

        // case 6: 點在邊界 (左邊界)
        Px=0; Py=5;
        #1 $display("Case6 On boundary (left edge): %b (expect 1)", inside);

        // case 7: 點在邊界 (右上角)
        Px=10; Py=10;
        #1 $display("Case7 On corner (Bx,By): %b (expect 1)", inside);

        // case 8: 點和 A 重合
        Px=0; Py=0;
        #1 $display("Case8 On point A: %b (expect 1)", inside);

        // case 9: 測試 Bx < Ax, By < Ay (反過來的矩形)
        Ax=10; Ay=10; Bx=0; By=0; Px=5; Py=5;
        #1 $display("Case9 Reversed corners: %b (expect 1)", inside);

        // case 10: 點在框外 (反過來情況, 在外面)
        Px=15; Py=15;
        #1 $display("Case10 Reversed outside: %b (expect 0)", inside);

        $display("=== Test End ===");
        $finish;
    end

endmodule
