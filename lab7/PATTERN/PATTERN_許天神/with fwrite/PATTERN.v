/**************************************************************************
 * Copyright (c) 2025, OASIS Lab
 * MODULE: PATTERN
 * FILE NAME: PATTERN.v
 * VERSRION: 1.0
 * DATE: Oct 29, 2025
 * AUTHOR: Chao-En Kuo, NYCU IAIS
 * DESCRIPTION: ICLAB2025FALL / LAB7 / PATTERN
 * MODIFICATION HISTORY:
 * Date                 Description
 * 2025/10/29           Fix: GMb.txt reader (decimal with comments)
 *************************************************************************/
`timescale 1ns/1ps

`ifdef RTL
  `define CYCLE_TIME_clk1 14.1
  `define CYCLE_TIME_clk2 10.1
  `define CYCLE_TIME_clk3 20.7
  // `define CYCLE_TIME_clk3 3.1
  // `define CYCLE_TIME_clk3 4.1
  // `define CYCLE_TIME_clk3 11.1
`endif
`ifdef GATE
  `define CYCLE_TIME_clk1 14.1
  `define CYCLE_TIME_clk2 10.1
  `define CYCLE_TIME_clk3 20.7
`endif

`define GMb_FILE "../00_TESTBED/GMb.txt"

`define Q     12289
`define Q0I   12287

module PATTERN(
  clk1, clk2, clk3,
  rst_n,
  in_valid, in_data,
  out_valid, out_data
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
output reg        clk1, clk2, clk3;
output reg        rst_n;
output reg        in_valid;
output reg [31:0] in_data;

input             out_valid;
input      [15:0] out_data;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER
//---------------------------------------------------------------------
real    CYCLE_clk1 = `CYCLE_TIME_clk1;
real    CYCLE_clk2 = `CYCLE_TIME_clk2;
real    CYCLE_clk3 = `CYCLE_TIME_clk3;

integer total_latency;
integer max_latency;
integer f_log;
integer PATNUM, cur_pat;

//---------------------------------------------------------------------
//   REG & MEM
//---------------------------------------------------------------------
reg [15:0] GMb      [0:127];  // twiddle factors, 128 entries
reg [15:0] poly_in  [0:127];
reg [15:0] golden   [0:127];
reg [15:0] dut_buf  [0:127];

integer i;

// clk3 counter & helpers
integer clk3_cnt, start_cnt, end_cnt;
integer out_cnt;
reg out_valid_d1_clk3;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial clk1 = 0;  always #(CYCLE_clk1/2.0) clk1 = ~clk1;
initial clk2 = 0;  always #(CYCLE_clk2/2.0) clk2 = ~clk2;
initial clk3 = 0;  always #(CYCLE_clk3/2.0) clk3 = ~clk3;

// === FIX 1: 加上 reset，避免 X/不穩定造成邊緣偵測失效
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    clk3_cnt <= 0;
    out_valid_d1_clk3 <= 1'b0;
  end else begin
    clk3_cnt <= clk3_cnt + 1;
    out_valid_d1_clk3 <= out_valid;
  end
end

//---------------------------------------------------------------------
//  FUNCTIONS : modular add/sub & Montgomery multiply
//---------------------------------------------------------------------
function [15:0] _mod_add(input [15:0] a, input [15:0] b);
  reg [16:0] s;
begin
  s = a + b;
  _mod_add = (s >= `Q) ? s - `Q : s[15:0];
end
endfunction

function [15:0] _mod_sub(input [15:0] a, input [15:0] b);
begin
  _mod_sub = (a >= b) ? (a - b) : (a + `Q - b);
end
endfunction

function [15:0] _mont_mul(input [15:0] a, input [15:0] b);
  reg [31:0] x,y,z;
begin
  x = a * b;                        // 32-bit
  y = (x * `Q0I) & 32'h0000_FFFF;   // y = (x * q') mod R
  z = (x + y * `Q) >> 16;           // (x + y*q) / R
  _mont_mul = (z >= `Q) ? z - `Q : z[15:0];
end
endfunction

//---------------------------------------------------------------------
//  TASK: NTT golden
//---------------------------------------------------------------------
task NTT_compute_golden;
  reg [15:0] x [0:127];
  integer t, m, ht, i2, j1, j2, jj;
  reg [15:0] s, u, v;
begin
  for (i = 0; i < 128; i = i + 1) x[i] = poly_in[i];

  t = 128;
  for (m = 1; m < 128; m = m << 1) begin
    ht = t >> 1;
    j1 = 0;
    for (i2 = 0; i2 < m; i2 = i2 + 1) begin
      s = GMb[m + i2];
      j2 = j1 + ht;
      for (jj = j1; jj < j2; jj = jj + 1) begin
        u = x[jj];
        v = _mont_mul(x[jj + ht], s);
        x[jj]      = _mod_add(u, v);
        x[jj+ht]   = _mod_sub(u, v);
      end
      j1 = j1 + t;
    end
    t = ht;
  end

  for (i = 0; i < 128; i = i + 1) golden[i] = x[i];
end
endtask

//---------------------------------------------------------------------
//  TASK: robust decimal loader for GMb.txt
//---------------------------------------------------------------------
task load_GMb_decimal;
  integer fh, nread, idx, val;
  reg [1023:0] line;   // 128 bytes buffer is plenty
begin
  fh = $fopen(`GMb_FILE, "r");
  if (fh == 0) fh = $fopen("GMb.txt", "r");
  if (fh == 0) begin
    $display("[FILE] Cannot open GMb file: %s (and GMb.txt)", `GMb_FILE);
    $fwrite(f_log, "[FILE] Cannot open GMb file: %s (and GMb.txt)\n", `GMb_FILE);
    $finish;
  end

  idx = 0;
  while (!$feof(fh)) begin
    line = 0;
    nread = $fgets(line, fh);
    if (nread == 0) break;
    if ($sscanf(line, "%d", val) == 1) begin
      if (val < 0 || val >= `Q) begin
        $display("[GMb] Value out of range [0,%0d): idx=%0d val=%0d", `Q, idx, val);
        $fwrite(f_log, "[GMb] Out-of-range at idx %0d : %0d\n", idx, val);
        $finish;
      end
      if (idx >= 128) begin
        $display("[GMb] Too many numbers in GMb.txt (expect 128).");
        $fwrite(f_log, "[GMb] Too many numbers.\n");
        $finish;
      end
      GMb[idx] = val[15:0];
      idx = idx + 1;
    end
  end
  $fclose(fh);

  if (idx != 128) begin
    $display("[GMb] Numbers read = %0d (expect 128).", idx);
    $fwrite(f_log, "[GMb] Count mismatch: %0d/128\n", idx);
    $finish;
  end

  $fwrite(f_log, "[GMb] Loaded 128 decimal twiddles successfully.\n");
end
endtask

//---------------------------------------------------------------------
//  TASK: drive 16 cycles on clk1 (8 coefficients per 32-bit word)
//---------------------------------------------------------------------
task drive_inputs_16_cycles;
  integer blk, t, base_idx;
  reg [31:0] w;
begin
  @(negedge clk1);
  in_valid = 1;
  for (blk = 0; blk < 16; blk = blk + 1) begin
    base_idx = blk * 8;
    w = 32'd0;
    for (t = 0; t < 8; t = t + 1) begin
      w[(t*4)+3 -: 4] = poly_in[base_idx + t][3:0];
    end
    in_data = w;

    if (out_valid !== 1'b0 || out_data !== 16'd0) begin
      $display("[SPEC] out_valid/out_data must be zero while in_valid=1.");
      $fwrite(f_log, "[SPEC] out_valid/out_data must be zero while in_valid=1.\n");
      $finish;
    end

    @(negedge clk1);
  end
  in_valid = 0;
  in_data  = 0;
end
endtask

//---------------------------------------------------------------------
//  TASK: wait for outputs & check
//---------------------------------------------------------------------
task wait_outputs_and_check;
  integer mism, k, this_latency;
  reg fall_detected;
begin
  mism = 0; out_cnt = 0; fall_detected = 0;

  // === FIX 2: 起點用「等級 + 對齊 clk3」，避免卡死與早起算
  wait (in_valid === 1'b0);     // 若已經是 0 會立刻通過，不會卡
  @(posedge clk3);              // 對齊 clk3 作為 latency 的起點
  start_cnt = clk3_cnt;

  while (out_cnt < 128) begin
    @(posedge clk3);

    // 規格檢查（容忍跨時脈監看）
    if (in_valid === 1'b1 && (out_valid === 1'b1 || out_data !== 16'd0)) begin
      $display("[SPEC] out_valid/out_data must be zero while in_valid=1 (clk3-phase).");
      $fwrite(f_log, "[SPEC] out_valid/out_data must be zero while in_valid=1 (clk3-phase).\n");
      $finish;
    end

    if (out_valid === 1'b1) begin
      dut_buf[out_cnt] = out_data;
      if (out_data !== golden[out_cnt]) begin
        mism = mism + 1;
        $display("[MISMATCH] idx=%0d golden=%0d got=%0d", out_cnt, golden[out_cnt], out_data);
      end
      out_cnt = out_cnt + 1;
    end

    // 進度 watchdog（以修正後的起點為準）
    if ((clk3_cnt - start_cnt) > 5000) begin
      $display("[clk3_cnt]=%d, [start_cnt]=%d", clk3_cnt, start_cnt);
      $display("[TIMEOUT] Exceed 5000 clk3 cycles without 128 outputs.");
      $fwrite(f_log, "[TIMEOUT] Exceed 5000 clk3 cycles.\n");
      $finish;
    end
  end

  // 收齊 128 筆後，等最後一次 out_valid 的下降；若已經是 0 就直接收尾
  if (out_valid === 1'b0) begin
    end_cnt = clk3_cnt;
  end else begin
    while (!fall_detected) begin
      @(posedge clk3);
      if (out_valid_d1_clk3 === 1'b1 && out_valid === 1'b0) begin
        fall_detected = 1'b1;
        end_cnt = clk3_cnt;
      end
      // 小保險：避免永遠等不到下降緣
      if ((clk3_cnt - start_cnt) > 5000 + 64) begin
        $display("[TIMEOUT] Waited too long for final out_valid fall.");
        $finish;
      end
    end
  end

  this_latency   = end_cnt - start_cnt;
  total_latency  = this_latency;
  $display("[PATTERN %0d] Latency = %0d clk3 cycles.", cur_pat, this_latency);
  if (this_latency > max_latency) max_latency = this_latency;

  $fwrite(f_log, "==== Pattern %0d ====\n", cur_pat);
  $fwrite(f_log, "Latency(clk3 cycles) = %0d\n", this_latency);
  for (k = 0; k < 128; k = k + 1) begin
    $fwrite(f_log, "[%03d] in=%0d golden=%0d got=%0d %s\n",
      k, poly_in[k], golden[k], dut_buf[k],
      (golden[k]===dut_buf[k]) ? "OK" : "X");
  end
  if (mism == 0) $fwrite(f_log, "Pattern %0d : ALL PASS (128/128)\n\n", cur_pat);
  else begin
    $fwrite(f_log, "Pattern %0d : %0d mismatches\n\n", cur_pat, mism);
    $display("[PATTERN %0d] %0d mismatches, see output.txt", cur_pat, mism);
    $finish;
  end
end
endtask

//---------------------------------------------------------------------
//  RAND helper
//---------------------------------------------------------------------
function integer rand_between_1_3;
  integer r; begin
    r = $random; r = r % 3; if (r < 0) r = r + 3;
    rand_between_1_3 = r + 1;
  end
endfunction

task gap_wait_clk1(input integer n);
  integer k; begin
    for (k = 0; k < n; k = k + 1) @(negedge clk1);
  end
endtask

//---------------------------------------------------------------------
//  產生測資（含幾個可除錯的固定案例 + 隨機）
//---------------------------------------------------------------------
task gen_one_pattern(input integer idx);
  integer k, r; begin
    // if (idx == 1) begin
    //   for (k = 0; k < 128; k = k + 1) poly_in[k] = 16'd0;
    // end
    if (idx == 2) begin
      for (k = 0; k < 128; k = k + 1) poly_in[k] = (k % 16);
    end else if (idx == 3) begin
      for (k = 0; k < 128; k = k + 1) poly_in[k] = (k[0] ? 16'd15 : 16'd0);
    end else if (idx == 4) begin
      for (k = 0; k < 128; k = k + 1) poly_in[k] = 16'd0;
      poly_in[17] = 16'd1;
    end else begin
      for (k = 0; k < 128; k = k + 1) begin
        r = $random;
        poly_in[k] = r & 16'h000F; // 4-bit 係數
      end
    end
    for (k = 0; k < 128; k = k + 1) begin
      golden[k]  = 16'd0;
      dut_buf[k] = 16'd0;
    end
  end
endtask

//---------------------------------------------------------------------
//  INITIAL
//---------------------------------------------------------------------
initial begin
    f_log = $fopen("output.txt", "w");
    if (!f_log) begin
        $display("[PATTERN] Cannot open output.txt");
        $finish;
    end
    $fwrite(f_log, "ICLAB 2025F Lab07 NTT PATTERN Log\n");

    in_valid = 0; in_data = 0;

    force clk1 = 0;
    force clk2 = 0;
    force clk3 = 0;
    // Reset 序列
    #20;
    rst_n = 1; #20;//repeat(3) @(negedge clk1);
    rst_n = 0; #100;//repeat(5) @(negedge clk1);
    rst_n = 1;
    #100;
    release clk1;
    release clk2;
    release clk3;

    // Reset 後輸出應為 0
    if (out_valid !== 1'b0 || out_data !== 16'd0) begin
        $display("[SPEC] Outputs must be zero after reset.");
        $fwrite(f_log, "[SPEC] Outputs must be zero after reset.\n");
        $finish;
    end

    clk3_cnt    = 0;
    max_latency = 0;

    // 改用十進位讀檔
    load_GMb_decimal();

    PATNUM = 100000;

    for (cur_pat = 1; cur_pat <= PATNUM; cur_pat = cur_pat + 1) begin
        gen_one_pattern(cur_pat);
        drive_inputs_16_cycles();
        NTT_compute_golden();
        wait_outputs_and_check();
        gap_wait_clk1(rand_between_1_3());
    end

    YOU_PASS_task();
end

//---------------------------------------------------------------------
//  PASS banner
//---------------------------------------------------------------------
task YOU_PASS_task; begin
  $display("*************************************************************************");
  $display("*                         Congratulations!                              *");
  $display("*                Max execution cycles = %5d cycles (clk3)               *", max_latency);
  $display("*                Your clock period = %.1f ns                            *", CYCLE_clk3);
  $display("*                Max Total Latency = %.1f ns                            *", max_latency*CYCLE_clk3);
  $display("*                詳細比對請見 output.txt                                *");
  $display("*************************************************************************");
  $fwrite(f_log, "== ALL PATTERNS PASS ==\n");
  $fclose(f_log);
  $finish;
end endtask

endmodule
