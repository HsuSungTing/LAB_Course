`timescale 1ns/1ps
`define CYCLE_TIME 20.0

module PATTERN(
    // output to DUT
    output reg          clk,
    output reg          rst_n,
    output reg          in_valid_data,
    output reg          in_valid_param,
    output reg  [7:0]   data,
    output reg  [3:0]   index,
    output reg          mode,
    output reg  [4:0]   QP,
    // input from DUT
    input               out_valid,
    input signed [31:0] out_value
);

// ===== Clock / Reset =====
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

// ===== Config =====
localparam FRAMES         = 16;
localparam PIX_PER_FRM    = 1024;  // 32*32
localparam SETS           = 16;
localparam TIMEOUT_CYCLES = 20000; // 等待 DUT 輸出的 Timeout 上限

// ===== Storage =====
reg [7:0] frames [0:FRAMES*PIX_PER_FRM-1];
reg [3:0] modes  [0:SETS-1];
reg [4:0] qps    [0:SETS-1];
reg [3:0] indices[0:SETS-1]; // 用來儲存從 params.txt 讀取的 index

// ===== Helpers =====
integer i, p, rc, fp;
reg [8*256-1:0] fname;
integer mix;

// ===== Reset Task =====
task automatic do_reset;
begin
    clk = 1'b0;
    rst_n = 1'b0;
    in_valid_data  = 1'b0;
    in_valid_param = 1'b0;
    data  = 8'dx;
    index = 4'dx;
    mode  = 1'bx;
    QP    = 5'dx;
    #(CYCLE * 3.5); // 根據規格書，Reset 持續 3T
    rst_n = 1'b1;
    #(CYCLE); // 等待 1T 後再開始送資料
end
endtask

// ===== Load frames (hex files) Task =====
// 讀取 dat/frame_0.hex ~ dat/frame_15.hex
task automatic load_frames;
    integer addr, fill;
    reg [7:0] tmp;
begin
    $display("[INFO] Loading frame data...");
    for (i=0; i<FRAMES; i=i+1) begin
        $sformat(fname, "../00_TESTBED/dat/frame_%0d.hex", i);
        fp = $fopen(fname, "r");
        if (fp==0) begin
            $display("[WARN] %0s not found; synthesizing dummy frame %0d", fname, i);
            for (p=0; p<PIX_PER_FRM; p=p+1) begin
                mix = (i*17 + p*7) ^ (i<<3);
                frames[i*PIX_PER_FRM + p] = (mix & 8'hFF);
            end
        end else begin
            begin : READ_LOOP
                for (addr=0; addr<PIX_PER_FRM; addr=addr+1) begin
                    rc = $fscanf(fp, "%h\n", tmp);
                    if (rc!=1) begin
                        $display("[WARN] %0s has less data; fill rest with dummy", fname);
                        for (fill=addr; fill<PIX_PER_FRM; fill=fill+1) begin
                            mix = (i*17 + fill*7) ^ (i<<3);
                            frames[i*PIX_PER_FRM + fill] = (mix & 8'hFF);
                        end
                        disable READ_LOOP;
                    end
                    frames[i*PIX_PER_FRM + addr] = tmp;
                end
            end
            $fclose(fp);
        end
    end
end
endtask

// ===== Load params.txt Task =====
// 檔案每行：index QP m0 m1 m2 m3
task automatic load_params;
    integer idx, qp_i, m0, m1, m2, m3;
begin
    $display("[INFO] Loading parameters...");
    fp = $fopen("../00_TESTBED/params.txt", "r");
    if (fp==0) begin
        $display("[WARN] params.txt not found; synthesize default params");
        for (i=0;i<SETS;i=i+1) begin
            indices[i] = i;
            qps[i]     = i % 30;
            modes[i]   = 4'b1010;
        end
    end else begin
        for (i=0;i<SETS;i=i+1) begin
            rc = $fscanf(fp, "%d %d %d %d %d %d\n", idx, qp_i, m0, m1, m2, m3);
            if (rc!=6) begin
                $display("[WARN] params.txt line %0d parse fail; fill with default", i+1);
                indices[i] = i;
                qps[i]     = i % 30;
                modes[i]   = 4'b1010;
            end else begin
                indices[i] = idx[3:0];
                qps[i]     = qp_i[4:0];
                modes[i]   = {m3[0], m2[0], m1[0], m0[0]};
            end
        end
        $fclose(fp);
    end
end
endtask

// ===== Main Task: Drive inputs and wait for outputs =====
task automatic feed_frames_then_params;
    integer wait_cnt;
    integer out_valid_count;

begin
    // 1) Phase 1: 送出 16 張影像資料
    $display("[INFO] Start sending frame data to DUT...");
    for (i = 0; i < FRAMES * PIX_PER_FRM; i = i + 1) begin
        @(negedge clk);
        in_valid_data <= 1'b1;
        data <= frames[i];
    end
    @(negedge clk);
    in_valid_data <= 1'b0;
    data <= 8'dx;
    $display("[INFO] Frame data sending completed.");

    // 等待 2~4 週期再送第一組 param
    repeat (3) @(negedge clk);

    // 2) Phase 2: 依序送出 16 組參數，並等待 DUT 完成
    for (i = 0; i < SETS; i = i + 1) begin
        $display("[INFO] Sending parameter set %0d (index=%0d, QP=%0d, mode=%b)...", i, indices[i], qps[i], modes[i]);
        // --- 發送第 i 組 param (共 4 個 cycle) ---
        @(negedge clk);
        in_valid_param <= 1'b1;
        index          <= indices[i];
        QP             <= qps[i];
        mode           <= modes[i][0];

        @(negedge clk); mode <= modes[i][1];
        @(negedge clk); mode <= modes[i][2];
        @(negedge clk); mode <= modes[i][3];

        @(negedge clk);
        in_valid_param <= 1'b0;
        index <= 4'dx; QP <= 5'dx; mode <= 1'bx;
        
        // --- 等待這一組的 1024 筆 out_valid 完成 ---
        out_valid_count = 0;
        wait_cnt = 0;

        while (out_valid_count < PIX_PER_FRM) begin
            if (wait_cnt >= TIMEOUT_CYCLES) begin
                $display("[TIMEOUT] Did not receive 1024 out_valid cycles for set %0d within %0d cycles. Last count: %d", i, TIMEOUT_CYCLES, out_valid_count);
                $finish;
            end
            
            if (out_valid) begin
                out_valid_count = out_valid_count + 1;
            end
            
            wait_cnt = wait_cnt + 1;
            @(negedge clk);
        end

        $display("[INFO] Set %0d finished, received %0d out_valid cycles.", i, out_valid_count);

        // 等待 2~4 週期再送下一組 param
        repeat (3) @(negedge clk);
    end

    // 全部 16 組完成
    repeat (10) @(negedge clk);
    $display("[SUCCESS] All %0d sets completed. Ending simulation.", SETS);
    $finish;
end
endtask


initial begin
    do_reset();
    load_frames();
    load_params();
    feed_frames_then_params();
end

endmodule