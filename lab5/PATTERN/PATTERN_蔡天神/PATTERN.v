`define CYCLE_TIME 20.0

module PATTERN(
    // output to DUT
    clk,
    rst_n,
    in_valid_data,
    in_valid_param,
    data,
    index,
    mode,
    QP,
    // input from DUT
    out_valid,
    out_value
);

// ======================== I/O ========================
output reg          clk;
output reg          rst_n;
output reg          in_valid_data;
output reg          in_valid_param;

output reg   [7:0]  data;
output reg   [3:0]  index;
output reg          mode;
output reg   [4:0]  QP;

input               out_valid;
input  signed [31:0] out_value;

// ======================== clock ======================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

// ======================== TB storage =================
integer fin;
integer i, j, k, f;
integer fgolden;
integer r1, val, v_golden;

reg [7:0] frame_mem [0:15][0:1023];
reg [3:0]  p_index   [0:15];
reg [4:0]  p_qp      [0:15];
reg        p_mode    [0:15][0:3];

integer out_cnt;
integer lat_cnt;
reg waiting_first_out;
reg [31:0] cycle_cnt;
integer safety_guard;
integer err_cnt;
integer total_err;

// ======================== TASKS ==================
task load_input_file;
    integer r;
begin
    fin = $fopen("../00_TESTBED/input.txt", "r");
    if (fin == 0) begin
        $display("\033[1;31m[FAIL]\033[0m cannot open input.txt");
        $finish;
    end

    // --- read frame data ---
    for (f = 0; f < 16; f = f + 1)
        for (i = 0; i < 1024; i = i + 1) begin
            r = $fscanf(fin, "%d", val);
            if (r != 1) begin
                $display("\033[1;31m[FAIL]\033[0m input.txt frame data insufficient at frame %0d pix %0d", f, i);
                $finish;
            end
            frame_mem[f][i] = (val < 0) ? 0 : (val > 255 ? 255 : val[7:0]);
        end

    // --- read param sets ---
    for (k = 0; k < 16; k = k + 1) begin
        integer idx, qp, m0, m1, m2, m3;
        r = $fscanf(fin, "%d %d %d %d %d %d", idx, qp, m0, m1, m2, m3);
        if (r != 6) begin
            $display("\033[1;31m[FAIL]\033[0m input.txt param insufficient at set %0d", k);
            $finish;
        end
        p_index[k] = idx[3:0];
        p_qp[k]    = qp[4:0];
        p_mode[k][0] = (m0 != 0);
        p_mode[k][1] = (m1 != 0);
        p_mode[k][2] = (m2 != 0);
        p_mode[k][3] = (m3 != 0);
    end
    $fclose(fin);
end
endtask


task send_frames;
begin
    for (f = 0; f < 16; f = f + 1) begin
        in_valid_data = 1'b1;
        for (i = 0; i < 1024; i = i + 1) begin
            data = frame_mem[f][i];
            @(negedge clk);
        end
        in_valid_data = 0;
        data = 'bx;
    end
end
endtask


task send_one_param(input integer kk);
    integer m;
begin
    in_valid_param = 1'b1;
    index = p_index[kk];
    QP    = p_qp[kk];
    mode  = p_mode[kk][0];
    @(negedge clk);

    index = 'bx;
    QP    = 'bx;
    for (m = 1; m < 4; m = m + 1) begin
        mode = p_mode[kk][m];
        @(negedge clk);
    end
    in_valid_param = 0;
    mode = 'bx;
end
endtask

task wait_2_to_4_negedges;
    integer w;
begin
    w = {$random} % 3 + 2;
    repeat (w) @(negedge clk);
end
endtask

// ======================== SPEC CHECKS =================
always @(posedge clk) begin
    if (rst_n) begin
        if (out_valid && (in_valid_data || in_valid_param)) begin
            $display("\033[1;31m[FAIL]\033[0m overlap: out_valid overlaps with in_valid_param at cycle %0d", cycle_cnt);
            $finish; 
        end
        if (!out_valid && (out_value !== 32'sd0)) begin
            $display("\033[1;31m[FAIL]\033[0m out_value != 0 when out_valid=0 at cycle %0d (value=%0d)", cycle_cnt, out_value);
            $finish; 
        end
    end
end

always @(posedge clk or negedge rst_n)
    if (!rst_n) cycle_cnt <= 0;
    else        cycle_cnt <= cycle_cnt + 1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_cnt <= 0;
        waiting_first_out <= 0;
        lat_cnt <= 0;
    end else begin
        if (out_valid) out_cnt <= out_cnt + 1;
        if (waiting_first_out && !out_valid) lat_cnt <= lat_cnt + 1;
        if (waiting_first_out && out_valid)  waiting_first_out <= 0;
    end
end

// ======================== MAIN =======================
initial begin
    fgolden = $fopen("../00_TESTBED/output.txt", "r");
    if (fgolden == 0) begin
        $display("\033[1;31m[FAIL]\033[0m cannot open golden output.txt");
        $finish;
    end

    clk = 0;
    rst_n = 1;
    in_valid_data = 0;
    in_valid_param = 0;
    data = 'bx; index='bx; mode='bx; QP='bx;

    #(CYCLE*0.5);
    rst_n = 0;
    #(CYCLE*3.0);
    rst_n = 1;
    #(CYCLE*1.0);

    load_input_file();
    send_frames();

    total_err = 0;

    for (k = 0; k < 16; k = k + 1) begin
        wait_2_to_4_negedges();
        out_cnt = 0;
        err_cnt = 0;
        waiting_first_out = 1;
        send_one_param(k);

        // skip "PATTERN x"
        r1 = $fscanf(fgolden, "PATTERN %d\n", i);

        safety_guard = 0;
        while (out_cnt < 1024) begin
            @(posedge clk);
            safety_guard = safety_guard + 1;

            if (out_valid) begin
                r1 = $fscanf(fgolden, "%d\n", v_golden);
                if (r1 != 1) begin
                    $display("\033[1;31m[FAIL]\033[0m golden file insufficient data at pattern %0d, line %0d", k, out_cnt);
                    $finish;
                end
                if (out_value !== v_golden) begin
                    err_cnt = err_cnt + 1;
                    if (err_cnt <= 5)
                        $display("\033[1;31m[MISMATCH]\033[0m PATTERN %0d, idx %0d: DUT=%0d, GOLDEN=%0d", k, out_cnt, out_value, v_golden);
                        $finish;
                end
            end

            if (out_cnt == 0 && safety_guard > 10000) begin
                $display("\033[1;31m[FAIL]\033[0m set %0d: no output for 10000 cycles after in_valid_param.", k);
                $finish;
            end
        end

        // skip "END"
        r1 = $fscanf(fgolden, "END\n");

        if (err_cnt == 0)
            $display("\033[1;32m[PASS]\033[0m Pattern %0d matched!", k);
        else begin
            $display("\033[1;31m[FAIL]\033[0m Pattern %0d: %0d mismatches.", k, err_cnt);
            total_err = total_err + 1;
        end
    end

    if (total_err == 0)
        $display("\033[1;32m[PASS]\033[0m All patterns matched golden output!");
    else
        $display("\033[1;31m[FAIL]\033[0m %0d patterns mismatched.", total_err);

    $fclose(fgolden);
    #(CYCLE*10);
    $finish;
end

endmodule
