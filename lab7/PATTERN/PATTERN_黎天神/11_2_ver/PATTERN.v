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
 * 
 *************************************************************************/
`ifdef RTL
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 10.1
	`define CYCLE_TIME_clk3 20.7
`endif
`ifdef GATE
	`define CYCLE_TIME_clk1 14.1
	`define CYCLE_TIME_clk2 10.1
	`define CYCLE_TIME_clk3 20.7
`endif

`define RAMDOM_SEED 42
`define PAT_NUM 100

module PATTERN(
	clk1,
	clk2,
	clk3,
	rst_n,
	in_valid,
	in_data,
	out_valid,
	out_data
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
real	CYCLE_clk1 = `CYCLE_TIME_clk1;
real	CYCLE_clk2 = `CYCLE_TIME_clk2;
real	CYCLE_clk3 = `CYCLE_TIME_clk3;
real    SEED = `RAMDOM_SEED;
real    PAT_NUM = `PAT_NUM;
integer total_latency;

//---------------------------------------------------------------------
//   REG & WIRE
//---------------------------------------------------------------------
reg [3:0] x [0:127]; 

integer GMb [0:127]; 
integer golden[0:127];
integer file_GMb;

integer i, j;
integer wait_cycle;
integer pat;

integer gidx;                 // golden index
integer clk3_cycle;           // 從開始計時以來經過的 clk3 週期數
integer done;                 // flag: 是否已經收齊 128 筆
//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
initial clk1 = 0;
always #(CYCLE_clk1 / 2.0) clk1 = ~clk1;

initial clk2 = 0;
always #(CYCLE_clk2 / 2.0) clk2 = ~clk2;

initial clk3 = 0;
always #(CYCLE_clk3 / 2.0) clk3 = ~clk3;
//---------------------------------------------------------------------
//  INITIAL
//---------------------------------------------------------------------
initial begin
	file_GMb = $fopen("../00_TESTBED/GMb.txt", "r");
	if(file_GMb === 0) begin
		$display("[ERROR] Cannot open GMb files.");
		$finish;
	end
	read_GMb;

	reset_task;

	total_latency = 0;
	for(pat = 0; pat < PAT_NUM; pat = pat + 1) begin
		for (i = 0; i < 128; i = i + 1) begin
			x[i] = $random(SEED) % 16;   
		end
		input_task;
		cal_golden_ntt;
		check_ans;
		$display("\033[32mPATTERN %d PASS\033[1;0m", pat);
		total_latency = total_latency + clk3_cycle;
	end
	YOU_PASS_task;
	$finish;
end

//---------------------------------------------------------------------
//  TASK
//---------------------------------------------------------------------
task input_task;
begin
    // 1. 隨機等待 1~3 個 negedge clk1
    wait_cycle = ($urandom_range(1, 3));   // 固定 seed 時可用 $urandom(seed)
    // $display("[INFO] Wait %0d negedge clk1 before input.", wait_cycle);

    repeat(wait_cycle) @(negedge clk1);

    // 2. 開始送輸入資料
    // 假設你要送 16 拍，每拍打 8 個 4-bit（共 128 筆 x[i]）
    for (i = 0; i < 16; i = i + 1) begin
        in_valid = 1'b1;

        // 打包 8 個 4-bit → 32-bit in_data
        in_data[ 3: 0] = x[i*8 + 0];
        in_data[ 7: 4] = x[i*8 + 1];
        in_data[11: 8] = x[i*8 + 2];
        in_data[15:12] = x[i*8 + 3];
        in_data[19:16] = x[i*8 + 4];
        in_data[23:20] = x[i*8 + 5];
        in_data[27:24] = x[i*8 + 6];
        in_data[31:28] = x[i*8 + 7];
		@(negedge clk1);
    end

    in_valid = 1'b0;
    in_data  = 32'bx;
end
endtask


task read_GMb; begin
	string str;
	$fgets(str, file_GMb);
	for (i = 0; i < 128; i = i + 1) begin
		if ($fscanf(file_GMb, "%d\n", GMb[i]) != 1) begin
			$display("[WARN] GMb[%0d] read failed.", i);
			GMb[i] = 0;
		end
	end
end endtask


task reset_task;
	begin
		rst_n       = 1'b1;
		in_valid    = 1'b0;
		in_data     =32'd0;
		force clk1 = 0;
		force clk2 = 0;
		force clk3 = 0;
		#(5*CYCLE_clk1);
		rst_n = 1'b0; // async active low
		#(3*CYCLE_clk1);
		rst_n = 1'b1;
		#(3*CYCLE_clk1);
		release clk1;
		release clk2;
		release clk3;
		// after reset, outputs must be zero
		if (out_valid !== 1'b0 || out_data !== 16'd0) begin
			$display("[ERROR] Outputs not cleared after reset.");
			$finish;
		end
	end
endtask

task cal_golden_ntt;

    // ---- 內部暫存變數 ----
    integer i, j, j1, j2, m, ht, t;
    integer u, v, s;
    integer Q, Q0I, R;
    integer temp_x [0:127];

begin
    Q   = 12289;
    Q0I = 12287;
    R   = 1 << 16;

    // 初始化 temp_x
    for (i = 0; i < 128; i = i + 1)
        temp_x[i] = x[i];

    // ---------------------------
    //        NTT 主迴圈
    // ---------------------------
    t = 128;
    for (m = 1; m < 128; m = m << 1) begin
        ht = t >> 1;
        j1 = 0;
        for (i = 0; i < m; i = i + 1) begin
            s = GMb[m + i];  // twiddle factor
            j2 = j1 + ht;
            for (j = j1; j < j2; j = j + 1) begin
                u = temp_x[j];
                v = modq_mul(temp_x[j + ht], s, Q, Q0I, R);
                temp_x[j]      = modq_add(u, v, Q);
                temp_x[j + ht] = modq_sub(u, v, Q);
            end
            j1 = j1 + t;
        end
        t = ht;
    end

    // 複製結果
    for (i = 0; i < 128; i = i + 1) begin
        golden[i] = temp_x[i];
		// $display("golden[%d]:  %d", i, golden[i]);
	end
end
endtask


function integer modq_mul;
    input integer a, b, Q, Q0I, R;
    integer x, y, z;
begin
    x = a * b;
    y = (x * Q0I) & (R - 1);       // (x * Q0I) mod 2^16
    z = (x + y * Q) >> 16;         // (x + y*Q)/2^16
    if (z >= Q) z = z - Q;
    modq_mul = z;
end
endfunction

function integer modq_add;
    input integer a, b, Q;
    integer s;
begin
    s = a + b;
    if (s >= Q) s = s - Q;
    modq_add = s;
end
endfunction

function integer modq_sub;
    input integer a, b, Q;
    integer s;
begin
    if (a >= b) s = a - b;
    else        s = a - b + Q;
    modq_sub = s;
end
endfunction

task check_ans;
begin
    gidx               = 0;
    clk3_cycle         = 0;
    done               = 0;
	
    while (done == 0) begin
		clk3_cycle = clk3_cycle + 1;

        if (out_valid === 1'b1) begin
			clk3_cycle = clk3_cycle - 1;
            if (out_data !== golden[gidx][15:0]) begin
                $display("[FAIL] Mismatch at output index %0d: DUT=%0d golden=%0d (time=%0t)",
                         gidx, out_data, golden[gidx], $time);
                $finish;
            end
            gidx = gidx + 1;

            // 全部 128 筆都檢查完了
            if (gidx == 128) begin
                done = 1;
            end
        end

        if (clk3_cycle > 5000 && done == 0) begin
            $display("[FAIL] Timeout waiting for outputs, clk3_cycle=%0d", clk3_cycle);
            $finish;
        end
		@(negedge clk3);
    end 


end
endtask


task YOU_PASS_task; begin
    $display("*************************************************************************");
    $display("                         Congratulations!                              ");
    $display("                Your execution cycles = %5d cycles          ", total_latency);
    $display("                Your clock period = %.1f ns          ", CYCLE_clk3);
    $display("                Total Latency = %.1f ns          ", total_latency*CYCLE_clk3);
    $display("*************************************************************************");
    $finish;
end endtask


endmodule
