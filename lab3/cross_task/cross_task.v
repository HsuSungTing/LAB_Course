module tb_cross_check;
    reg [9:0] Ox, Oy, Ax, Ay, Bx, By; 
    reg [1:0] result;

    task cross_check;
        input  [9:0] Ox, Oy;
        input  [9:0] Ax, Ay;
        input  [9:0] Bx, By;
        output reg [1:0] result;  

        reg signed [10:0] dx1, dy1, dx2, dy2;   
        reg signed [21:0] mul1, mul2;           
        reg signed [22:0] cross_val;            

        begin
            dx1 = $signed({1'b0, Ax}) - $signed({1'b0, Ox});
            dy1 = $signed({1'b0, Ay}) - $signed({1'b0, Oy});
            dx2 = $signed({1'b0, Bx}) - $signed({1'b0, Ox});
            dy2 = $signed({1'b0, By}) - $signed({1'b0, Oy});

            mul1 = dx1 * dy2;
            mul2 = dy1 * dx2;
            cross_val = mul1 - mul2;

            if (cross_val < 0) result = 0;
            else if (cross_val == 0) result = 1;
            else result = 2;
        end
    endtask

    initial begin
        // 測試 1: 正
        Ox = 0; Oy = 0; Ax = 1; Ay = 0; Bx = 0; By = 1;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test1: result = %0d (expect 2)", result);

        // 測試 2: 負
        Ox = 0; Oy = 0; Ax = 0; Ay = 1; Bx = 1; By = 0;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test2: result = %0d (expect 0)", result);

        // 測試 3: 共線
        Ox = 0; Oy = 0; Ax = 1; Ay = 1; Bx = 2; By = 2;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test3: result = %0d (expect 1)", result);

        // 測試 4: 大數 (10-bit 最大值 1023)
        Ox = 10'd1000; Oy = 10'd1000;
        Ax = 10'd1005; Ay = 10'd1002;
        Bx = 10'd1002; By = 10'd1007;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test4: result = %0d", result);

        // 基本測試
        Ox = 0; Oy = 0; Ax = 1; Ay = 0; Bx = 0; By = 1;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test1: result = %0d (expect 2)", result);

        Ox = 0; Oy = 0; Ax = 0; Ay = 1; Bx = 1; By = 0;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test2: result = %0d (expect 0)", result);

        Ox = 0; Oy = 0; Ax = 1; Ay = 1; Bx = 2; By = 2;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test3: result = %0d (expect 1)", result);

        // 大數測試
        Ox = 10'd1000; Oy = 10'd1000; Ax = 10'd1005; Ay = 10'd1002; Bx = 10'd1002; By = 10'd1007;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test4: result = %0d", result);

        // 邊界測試 1: Ox = Oy = 0，Ax = Bx = 1023，Ay = By = 1023 (共線)
        Ox = 0; Oy = 0; Ax = 1023; Ay = 1023; Bx = 1023; By = 1023;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test5: result = %0d (expect 1)", result);

        // 邊界測試 2: 正向斜率
        Ox = 10'd512; Oy = 10'd512; Ax = 10'd600; Ay = 10'd520; Bx = 10'd520; By = 10'd600;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test6: result = %0d (expect 2)", result);

        // 邊界測試 3: 負向斜率
        Ox = 10'd512; Oy = 10'd512; Ax = 10'd520; Ay = 10'd600; Bx = 10'd600; By = 10'd520;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test7: result = %0d (expect 0)", result);

        // 邊界測試 4: Ox, Oy = 最大值
        Ox = 10'd1023; Oy = 10'd1023; Ax = 10'd1020; Ay = 10'd1020; Bx = 10'd1015; By = 10'd1018;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test8: result = %0d", result);

        // 邊界測試 5: 隨機小數據
        Ox = 10'd10; Oy = 10'd15; Ax = 10'd12; Ay = 10'd18; Bx = 10'd11; By = 10'd17;
        cross_check(Ox, Oy, Ax, Ay, Bx, By, result);
        $display("Test9: result = %0d", result);

        $finish;
    end
endmodule
