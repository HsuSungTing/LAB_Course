`timescale 1ns/1ps

module tb_check_date;

    // === DUT (Device Under Test) 介面 ===
    logic [3:0] prev_mon;
    logic [4:0] prev_day;
    logic [3:0] cur_mon;
    logic [4:0] cur_day;
    logic cts_bool;
    logic more_than_90days;

    // === DUT 實例化 ===
    check_date dut (
        .prev_mon(prev_mon),
        .prev_day(prev_day),
        .cur_mon(cur_mon),
        .cur_day(cur_day),
        .cts_bool(cts_bool),
        .more_than_90days(more_than_90days)
    );

    // === 測試程序 ===
    initial begin
        $display("==== check_date TestBench ====");
        $display(" prev_mon prev_day | cur_mon cur_day || cts_bool more_than_90days ");
        $display("--------------------------------------------------------------");

        // === Case 1: 同月連續日期 (1月1日 -> 1月2日) ===
        prev_mon = 1; prev_day = 1;
        cur_mon  = 1; cur_day  = 2; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 2: 跨月連續日期 (1月31日 -> 2月1日) ===
        prev_mon = 1; prev_day = 31;
        cur_mon  = 2; cur_day  = 1; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 3: 同月非連續 (1月1日 -> 1月5日) ===
        prev_mon = 1; prev_day = 1;
        cur_mon  = 1; cur_day  = 5; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 4: 超過 90 天 (1月1日 -> 4月10日) ===
        prev_mon = 1; prev_day = 1;
        cur_mon  = 4; cur_day  = 10; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 5: 年度跨越連續日期 (12月31日 -> 1月1日) ===
        prev_mon = 12; prev_day = 31;
        cur_mon  = 1; cur_day  = 1; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 6: 跨年非連續 (12月31日 -> 1月10日) ===
        prev_mon = 12; prev_day = 31;
        cur_mon  = 1; cur_day  = 10; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 7: 同月最後一天 -> 下一月第一天 (2月28日 -> 3月1日) ===
        prev_mon = 2; prev_day = 28;
        cur_mon  = 3; cur_day  = 1; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 8: 小間隔 (3月14日 -> 3月15日) ===
        prev_mon = 3; prev_day = 14;
        cur_mon  = 3; cur_day  = 15; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 9: 跨月但差兩天 (5月30日 -> 6月1日) ===
        prev_mon = 5; prev_day = 30;
        cur_mon  = 6; cur_day  = 1; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 10: 同月大距離 (3月1日 -> 3月31日) ===
        prev_mon = 3; prev_day = 1;
        cur_mon  = 3; cur_day  = 31; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 11: 跨兩個月 (4月15日 -> 6月15日) ===
        prev_mon = 4; prev_day = 15;
        cur_mon  = 6; cur_day  = 15; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 12: 相差約 90 天 (1月1日 -> 4月1日) ===
        prev_mon = 1; prev_day = 1;
        cur_mon  = 4; cur_day  = 1; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 13: 跨年約 100 天 (11月1日 -> 2月10日) ===
        prev_mon = 11; prev_day = 1;
        cur_mon  = 2; cur_day  = 10; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 14: 同一月邊界 (6月29日 -> 6月30日) ===
        prev_mon = 6; prev_day = 29;
        cur_mon  = 6; cur_day  = 30; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 15: 非連續 (10月10日 -> 10月12日) ===
        prev_mon = 10; prev_day = 10;
        cur_mon  = 10; cur_day  = 12; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        // === Case 16: 跨年遠距 (11月15日 -> 3月20日) ===
        prev_mon = 11; prev_day = 15;
        cur_mon  = 3; cur_day  = 20; #1;
        $display(" %2d        %2d    |   %2d      %2d   ||    %b           %b",
                  prev_mon, prev_day, cur_mon, cur_day, cts_bool, more_than_90days);

        $display("--------------------------------------------------------------");
        $finish;
    end

endmodule
