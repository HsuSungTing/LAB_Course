`timescale 1ns/1ps

module find_delta_tb;

// DUT IO
logic [1:0]  type_in;
logic [15:0] MP, HP, ATK, DEF;
logic [15:0] Delta_MP, Delta_HP, Delta_ATK, Delta_DEF;

// Instantiate DUT
find_delta dut(
    .type_in(type_in),
    .MP(MP), .HP(HP), .ATK(ATK), .DEF(DEF),
    .Delta_MP(Delta_MP),
    .Delta_HP(Delta_HP),
    .Delta_ATK(Delta_ATK),
    .Delta_DEF(Delta_DEF)
);

// === Task for testing one pattern ===
task run_case(
    input [1:0] t,
    input [15:0] mp, hp, atk, def
);
begin
    type_in = t;
    MP = mp;
    HP = hp;
    ATK = atk;
    DEF = def;

    #1; // let combinational logic settle

    $display("==============================");
    $display(" type=%0d | MP=%0d HP=%0d ATK=%0d DEF=%0d",
             t, mp, hp, atk, def);
    $display(" --> Delta_MP=%0d Delta_HP=%0d Delta_ATK=%0d Delta_DEF=%0d",
             Delta_MP, Delta_HP, Delta_ATK, Delta_DEF);
end
endtask

initial begin
    $display("\n===== find_delta TEST START =====\n");

    // -------- Type A: 平均值 (右 shift 3) --------
    run_case(0, 1000, 2000, 3000, 4000);
    run_case(0, 10, 10, 10, 10);

    // -------- Type B: merge_sort_4 + 差值 --------
    // 測試排序 + char mapping
    run_case(1, 1000, 3000, 2000, 4000);
    run_case(1, 1000, 3000, 2000, 2000);
    run_case(1, 4000, 3000, 2000, 1000);
    run_case(1, 4500, 1300, 4233, 2055);
    run_case(1, 2000, 2000, 2000, 2000); // all equal

    // -------- Type C: Capped at 16383 --------
    run_case(2, 10000, 15000, 16000, 16383);
    run_case(2, 20000, 20000, 20000, 20000);
    run_case(2, 0, 0, 0, 0);

    // -------- Type D: 3000 + ((65535-X)>>4), capped at 5047 --------
    run_case(3, 65535, 65535, 65535, 65535);   // min output = 3000
    run_case(3, 0, 0, 0, 0);                   // should cap at 5047
    run_case(3, 30000, 20000, 10000, 50000);   // mixed values

    $display("\n===== find_delta TEST END =====\n");
    $finish;
end

endmodule
