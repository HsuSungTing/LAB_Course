// tb_update_hull.v
`timescale 1ns/1ps

module tb_update_hull;

    // arrays and regs (mirror your original widths)
    reg [9:0] hull_x [0:127];
    reg [9:0] hull_y [0:127];
    integer hull_len;

    reg [9:0] gold_drop_x [0:127];
    reg [9:0] gold_drop_y [0:127];
    reg [7:0] gold_drop_num;

    reg [1:0] cross_123; // for pt_cnt==3
    reg [9:0] temp_x, temp_y;

    reg [9:0] in_x_d, in_y_d;
    integer pt_cnt;
    integer i;

    // ---------- tasks ----------
    task update_hull_drop_outxy;
    begin
        if (pt_cnt <= 2) begin
            gold_drop_num = 8'd0;
            gold_drop_x[0] = 10'd0; gold_drop_y[0] = 10'd0;
            hull_x[hull_len] = in_x_d; hull_y[hull_len] = in_y_d;
            hull_len = hull_len + 1;
        end
        else if (pt_cnt == 3) begin
            cross_check(hull_x[0], hull_y[0], hull_x[1], hull_y[1], in_x_d, in_y_d, cross_123);
            if (cross_123 == 2'd0) begin // cross < 0 => swap A and B (你原本註解)
                temp_x = hull_x[1]; temp_y = hull_y[1];
                hull_x[2] = temp_x; hull_y[2] = temp_y; // <-- 修正: temp_y
                hull_x[1] = in_x_d;   hull_y[1] = in_y_d;
            end
            else begin
                hull_x[2] = in_x_d; hull_y[2] = in_y_d;
            end
            gold_drop_num = 8'd0; gold_drop_x[0] = 10'd0; gold_drop_y[0] = 10'd0;
            hull_len = hull_len + 1;
        end
        else begin
            // 若 pt_cnt >3，原始程式不在此處處理，視設計需求補上
        end
    end
    endtask

    // cross(O, A, B) = (Ax - Ox)*(By - Oy) - (Ay - Oy)*(Bx - Ox)
    task cross_check;
        input  [9:0] Ox, Oy;
        input  [9:0] Ax, Ay;
        input  [9:0] Bx, By;
        output reg [1:0] result;
        reg signed [10:0] dx1, dy1, dx2, dy2;
        reg signed [21:0] mul1, mul2;
        reg signed [22:0] cross_val;
    begin
        // extend to signed (prepend 0 to preserve magnitude, then cast signed)
        dx1 = $signed({1'b0, Ax}) - $signed({1'b0, Ox});
        dy1 = $signed({1'b0, Ay}) - $signed({1'b0, Oy});
        dx2 = $signed({1'b0, Bx}) - $signed({1'b0, Ox});
        dy2 = $signed({1'b0, By}) - $signed({1'b0, Oy});
        mul1 = dx1 * dy2;
        mul2 = dy1 * dx2;
        cross_val = mul1 - mul2;
        if (cross_val < 0) result = 2'b00;      // negative
        else if (cross_val == 0) result = 2'b01; // zero (collinear)
        else result = 2'b10;                    // positive
    end
    endtask

    // ---------- test sequences ----------
    initial begin
        // initialize
        hull_len = 0;
        gold_drop_num = 0;
        cross_123 = 2'b00;
        // clear arrays (for nicer waveforms)
        for (i=0; i<128; i=i+1) begin
            hull_x[i] = 0;
            hull_y[i] = 0;
            gold_drop_x[i] = 0;
            gold_drop_y[i] = 0;
        end

        // ---- Test 1: pt_cnt = 1 ----
        $display("==== Test 1: pt_cnt = 1 ====");
        pt_cnt = 1;
        in_x_d = 10'd100; in_y_d = 10'd100;
        update_hull_drop_outxy;
        $display("hull_len=%0d hull[0]=(%0d,%0d)", hull_len, hull_x[0], hull_y[0]);

        // ---- Test 2: pt_cnt = 2 ----
        $display("==== Test 2: pt_cnt = 2 ====");
        pt_cnt = 2;
        in_x_d = 10'd200; in_y_d = 10'd200;
        update_hull_drop_outxy;
        $display("hull_len=%0d hull[1]=(%0d,%0d)", hull_len, hull_x[1], hull_y[1]);

        // ---- Test 3: pt_cnt = 3, negative cross (expect swap) ----
        $display("==== Test 3: pt_cnt = 3 (negative cross => swap) ====");
        // set hull[0]=(0,0), hull[1]=(1,1) so adding in=(1,0) gives negative cross
        hull_x[0] = 10'd0; hull_y[0] = 10'd0;
        hull_x[1] = 10'd1; hull_y[1] = 10'd1;
        hull_len = 2;
        pt_cnt = 3;
        in_x_d = 10'd1; in_y_d = 10'd0; // B=(1,0)
        update_hull_drop_outxy;
        $display("cross_123=%0d (0:neg,1:zero,2:pos)", cross_123);
        $display("hull_len=%0d hull0=(%0d,%0d) hull1=(%0d,%0d) hull2=(%0d,%0d)",
                  hull_len, hull_x[0], hull_y[0], hull_x[1], hull_y[1], hull_x[2], hull_y[2]);

        // ---- Test 4: pt_cnt = 3, positive cross (no swap) ----
        $display("==== Test 4: pt_cnt = 3 (positive cross => no swap) ====");
        hull_x[0] = 10'd0; hull_y[0] = 10'd0;
        hull_x[1] = 10'd1; hull_y[1] = 10'd0;
        hull_len = 2;
        pt_cnt = 3;
        in_x_d = 10'd1; in_y_d = 10'd1; // B=(1,1)
        update_hull_drop_outxy;
        $display("cross_123=%0d (0:neg,1:zero,2:pos)", cross_123);
        $display("hull_len=%0d hull0=(%0d,%0d) hull1=(%0d,%0d) hull2=(%0d,%0d)",
                  hull_len, hull_x[0], hull_y[0], hull_x[1], hull_y[1], hull_x[2], hull_y[2]);

        // ---- Test 5: pt_cnt = 3, collinear (zero) ----
        $display("==== Test 5: pt_cnt = 3 (collinear => zero) ====");
        hull_x[0] = 10'd0; hull_y[0] = 10'd0;
        hull_x[1] = 10'd1; hull_y[1] = 10'd1;
        hull_len = 2;
        pt_cnt = 3;
        in_x_d = 10'd2; in_y_d = 10'd2; // collinear with (0,0)-(1,1)
        update_hull_drop_outxy;
        $display("cross_123=%0d (0:neg,1:zero,2:pos)", cross_123);
        $display("hull2=(%0d,%0d)", hull_x[2], hull_y[2]);

        $display("==== Tests finished ====");
        $finish;
    end

endmodule
