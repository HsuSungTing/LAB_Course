`timescale 1ns/1ps
`define CYCLE_TIME 20.0

module PATTERN(
    output reg clk,
    output reg rst_n,
    output reg in_valid_data,
    output reg in_valid_param,
    output reg [7:0] data,
    output reg [3:0] index,
    output reg mode,
    output reg [4:0] QP,
    
    input out_valid,
    input signed [31:0] out_value
);

// ============================================================================
// Parameters
// ============================================================================
parameter TOTAL_SETS = 16;
parameter PIXELS_PER_FRAME = 1024;
parameter COEFFS_PER_SET = 1024;
parameter MAX_OUTPUT_CYCLES = 10000;
parameter MAX_ERROR_DISPLAY = 100;  // ← 新增：最大顯示錯誤數

// ============================================================================
// Clock Generation
// ============================================================================
initial clk = 0;
always #(`CYCLE_TIME/2) clk = ~clk;

// ============================================================================
// Variables
// ============================================================================
integer input_file, golden_file;
integer status, i, j;
integer cycle_count;
integer total_output_count;
integer error_count;
integer display_error_count;  // ← 新增：已顯示的錯誤數
integer current_set;

// 從文件讀取的數據
reg [7:0] all_pixels [0:16383];
reg [3:0] param_index [0:15];
reg [4:0] param_qp [0:15];
reg param_modes [0:15][0:3];
reg signed [31:0] golden_coeffs [0:16383];

integer pixel_count, set_count, coeff_count;
integer temp_char;

// ============================================================================
// Task: Skip Comment Lines
// ============================================================================
task skip_comments;
input integer file_handle;
begin
    temp_char = $fgetc(file_handle);
    
    while (temp_char == "/" || temp_char == " " || 
           temp_char == "\t" || temp_char == "\n" || temp_char == "\r") begin
        
        if (temp_char == "/") begin
            temp_char = $fgetc(file_handle);
            if (temp_char == "/") begin
                while (temp_char != "\n" && !$feof(file_handle)) begin
                    temp_char = $fgetc(file_handle);
                end
            end else begin
                status = $ungetc(temp_char, file_handle);
                temp_char = $fgetc(file_handle);
            end
        end
        
        if ($feof(file_handle)) begin
            return;
        end
        
        temp_char = $fgetc(file_handle);
    end
    
    if (!$feof(file_handle)) begin
        status = $ungetc(temp_char, file_handle);
    end
end
endtask

// ============================================================================
// Task: Load Input File
// ============================================================================
task load_input;
integer temp_val;
begin
    $display("="*80);
    $display("📂 Loading input.txt...");
    $display("="*80);
    
    input_file = $fopen("input.txt", "r");
    if (input_file == 0) begin
        $display("❌ Error: Cannot open input.txt");
        $display("   Please run: python3 generate_test.py");
        $finish;
    end
    
    skip_comments(input_file);
    
    pixel_count = 0;
    while (!$feof(input_file) && pixel_count < 16384) begin
        status = $fscanf(input_file, "%d", temp_val);
        
        if (status == 1) begin
            all_pixels[pixel_count] = temp_val;
            pixel_count = pixel_count + 1;
            
            if (pixel_count % 4096 == 0) begin
                $display("   Loaded %0d pixels...", pixel_count);
            end
        end else if (status == 0) begin
            skip_comments(input_file);
        end
    end
    
    if (pixel_count != 16384) begin
        $display("❌ Error: Only loaded %0d pixels (expected 16384)", pixel_count);
        $finish;
    end
    
    $display("   ✅ Loaded 16384 pixels");
    
    skip_comments(input_file);
    
    set_count = 0;
    while (!$feof(input_file) && set_count < 16) begin
        status = $fscanf(input_file, "%d %d %d %d %d %d", 
                        temp_val,
                        param_qp[set_count],
                        param_modes[set_count][0],
                        param_modes[set_count][1],
                        param_modes[set_count][2],
                        param_modes[set_count][3]);
        
        if (status == 6) begin
            param_index[set_count] = temp_val;
            set_count = set_count + 1;
        end else if (status == 0) begin
            skip_comments(input_file);
        end
    end
    
    if (set_count != 16) begin
        $display("❌ Error: Only loaded %0d parameter sets (expected 16)", set_count);
        $finish;
    end
    
    $display("   ✅ Loaded 16 parameter sets");
    $display("");
    
    $display("   Parameter sequence:");
    for (i = 0; i < 16; i = i + 1) begin
        $display("     Set %2d: index=%2d, QP=%2d, modes=[%0d,%0d,%0d,%0d]",
                 i, param_index[i], param_qp[i],
                 param_modes[i][0], param_modes[i][1],
                 param_modes[i][2], param_modes[i][3]);
    end
    $display("");
    
    $fclose(input_file);
end
endtask

// ============================================================================
// Task: Load Golden Output
// ============================================================================
task load_golden;
integer temp_coeff;
begin
    $display("="*80);
    $display("📂 Loading golden.txt...");
    $display("="*80);
    
    golden_file = $fopen("golden.txt", "r");
    if (golden_file == 0) begin
        $display("❌ Error: Cannot open golden.txt");
        $display("   Please run: python3 generate_test.py");
        $finish;
    end
    
    skip_comments(golden_file);
    
    coeff_count = 0;
    while (!$feof(golden_file) && coeff_count < 16384) begin
        status = $fscanf(golden_file, "%d", temp_coeff);
        
        if (status == 1) begin
            golden_coeffs[coeff_count] = temp_coeff;
            coeff_count = coeff_count + 1;
            
            if (coeff_count % 4096 == 0) begin
                $display("   Loaded %0d coefficients...", coeff_count);
            end
        end else if (status == 0) begin
            skip_comments(golden_file);
        end
    end
    
    if (coeff_count != 16384) begin
        $display("❌ Error: Only loaded %0d coefficients (expected 16384)", coeff_count);
        $finish;
    end
    
    $display("   ✅ Loaded 16384 golden coefficients");
    $display("");
    
    $display("   First 16 golden coefficients:");
    $write("     ");
    for (i = 0; i < 16; i = i + 1) begin
        $write("%6d ", golden_coeffs[i]);
    end
    $display("");
    $display("");
    
    $fclose(golden_file);
end
endtask

// ============================================================================
// Task: Reset
// ============================================================================
task reset_task;
begin
    $display("="*80);
    $display("🔄 Applying Reset...");
    $display("="*80);
    
    rst_n = 0;
    in_valid_data = 0;
    in_valid_param = 0;
    data = 8'h0;
    index = 4'h0;
    mode = 1'b0;
    QP = 5'h0;
    
    #(`CYCLE_TIME * 3);
    
    @(negedge clk);
    rst_n = 1;
    
    #(`CYCLE_TIME * 1);
    
    $display("✅ Reset completed\n");
end
endtask

// ============================================================================
// Task: Send Input Data (16384 pixels)
// ============================================================================
task send_input_data;
integer pix_idx;
begin
    $display("="*80);
    $display("📥 Sending Input Data (16384 pixels)");
    $display("="*80);
    
    @(negedge clk);
    
    for (pix_idx = 0; pix_idx < 16384; pix_idx = pix_idx + 1) begin
        in_valid_data = 1;
        data = all_pixels[pix_idx];
        
        if (pix_idx % 4096 == 0) begin
            $display("   Sending pixels %0d-%0d...", pix_idx, pix_idx+4095);
        end
        
        @(negedge clk);
    end
    
    in_valid_data = 0;
    data = 8'hxx;
    
    $display("✅ All 16384 pixels sent\n");
end
endtask

// ============================================================================
// Task: Send Parameters and Check Output
// ============================================================================
task send_param_and_check;
input integer set_idx;
integer delay_cycles;
integer mode_idx;
integer out_cnt;
integer wait_cycles;
reg signed [31:0] expected_val;
integer set_error_count;  // ← 新增：當前 set 的錯誤數
begin
    $display("="*80);
    $display("📦 Set %0d: index=%0d, QP=%0d, modes=[%0d,%0d,%0d,%0d]", 
             set_idx, 
             param_index[set_idx], 
             param_qp[set_idx],
             param_modes[set_idx][0], 
             param_modes[set_idx][1],
             param_modes[set_idx][2], 
             param_modes[set_idx][3]);
    $display("="*80);
    
    // 初始化當前 set 的錯誤計數
    set_error_count = 0;
    
    // 延遲 2~4 週期
    delay_cycles = 2 + ($random % 3);
    repeat(delay_cycles) @(negedge clk);
    
    // 發送參數（4 週期）
    @(negedge clk);
    
    // 第 1 週期
    in_valid_param = 1;
    index = param_index[set_idx];
    QP = param_qp[set_idx];
    mode = param_modes[set_idx][0];
    @(negedge clk);
    
    // 第 2~4 週期
    index = 4'hx;
    QP = 5'hx;
    
    for (mode_idx = 1; mode_idx < 4; mode_idx = mode_idx + 1) begin
        mode = param_modes[set_idx][mode_idx];
        @(negedge clk);
    end
    
    // 下降
    in_valid_param = 0;
    index = 4'hx;
    QP = 5'hx;
    mode = 1'bx;
    
    // 等待並檢查輸出
    $display("⏳ Waiting for 1024 outputs...");
    
    out_cnt = 0;
    wait_cycles = 0;
    
    while (out_cnt < COEFFS_PER_SET && wait_cycles < MAX_OUTPUT_CYCLES) begin
        @(posedge clk);
        
        // 檢查重疊
        if (out_valid && (in_valid_data || in_valid_param)) begin
            if (display_error_count < MAX_ERROR_DISPLAY) begin
                $display("❌ [Cycle %0d] out_valid overlaps with input!", cycle_count);
                display_error_count = display_error_count + 1;
            end
            error_count = error_count + 1;
        end
        
        if (out_valid) begin
            expected_val = golden_coeffs[set_idx * COEFFS_PER_SET + out_cnt];
            
            // 比對
            if (out_value !== expected_val) begin
                if (display_error_count < MAX_ERROR_DISPLAY) begin
                    $display("❌ [Set %2d, Coeff %4d] Got %8d, Expected %8d, Diff = %0d",
                             set_idx, out_cnt, out_value, expected_val, 
                             out_value - expected_val);
                    display_error_count = display_error_count + 1;
                end
                error_count = error_count + 1;
                set_error_count = set_error_count + 1;
            end
            
            out_cnt = out_cnt + 1;
            total_output_count = total_output_count + 1;
            
            // 進度顯示
            if (out_cnt % 256 == 0) begin
                $display("   Progress: %0d/1024 (errors in this set: %0d)", 
                         out_cnt, set_error_count);
            end
        end else begin
            // 檢查 out_value 是否為 0
            if (out_value !== 32'sd0) begin
                if (display_error_count < MAX_ERROR_DISPLAY) begin
                    $display("❌ [Cycle %0d] out_value=%0d (should be 0 when out_valid=0)", 
                             cycle_count, out_value);
                    display_error_count = display_error_count + 1;
                end
                error_count = error_count + 1;
            end
        end
        
        wait_cycles = wait_cycles + 1;
        cycle_count = cycle_count + 1;
    end
    
    // 檢查結果
    if (out_cnt < COEFFS_PER_SET) begin
        $display("❌ Set %0d: Only %0d/%0d outputs in %0d cycles!", 
                 set_idx, out_cnt, COEFFS_PER_SET, wait_cycles);
        error_count = error_count + 1;
    end else begin
        if (set_error_count == 0) begin
            $display("✅ Set %0d: All 1024 outputs correct in %0d cycles", 
                     set_idx, wait_cycles);
        end else begin
            $display("⚠️  Set %0d: Completed in %0d cycles with %0d errors", 
                     set_idx, wait_cycles, set_error_count);
        end
    end
    
    @(negedge clk);
    $display("");
end
endtask

// ============================================================================
// Main Test Flow
// ============================================================================
initial begin
    cycle_count = 0;
    total_output_count = 0;
    error_count = 0;
    display_error_count = 0;  // ← 初始化
    
    $display("\n");
    $display("="*80);
    $display("     H.264 Lite Pre-Entropy Encoder Pattern");
    $display("     Clock Period: %.1f ns", `CYCLE_TIME);
    $display("="*80);
    $display("\n");
    
    // 載入測試數據
    load_input();
    load_golden();
    
    // 執行測試
    reset_task();
    send_input_data();
    
    // 處理 16 組
    for (current_set = 0; current_set < TOTAL_SETS; current_set = current_set + 1) begin
        send_param_and_check(current_set);
    end
    
    // 最終報告
    $display("\n");
    $display("="*80);
    $display("📊 Simulation Summary");
    $display("="*80);
    $display("Clock period:          %.1f ns", `CYCLE_TIME);
    $display("Total cycles:          %0d", cycle_count);
    $display("Total outputs:         %0d / 16384", total_output_count);
    $display("Total errors:          %0d", error_count);
    $display("Errors displayed:      %0d / %0d", display_error_count, error_count);
    
    if (error_count > MAX_ERROR_DISPLAY) begin
        $display("⚠️  Note: Only first %0d errors were displayed", MAX_ERROR_DISPLAY);
        $display("         Total errors: %0d", error_count);
    end
    
    $display("="*80);
    
    if (error_count == 0 && total_output_count == 16384) begin
        $display("\n");
        $display("  ██████╗  █████╗ ███████╗███████╗");
        $display("  ██╔══██╗██╔══██╗██╔════╝██╔════╝");
        $display("  ██████╔╝███████║███████╗███████╗");
        $display("  ██╔═══╝ ██╔══██║╚════██║╚════██║");
        $display("  ██║     ██║  ██║███████║███████║");
        $display("  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝");
        $display("\n");
        $display("         🎉 ALL TESTS PASSED! 🎉");
        $display("\n");
    end else begin
        $display("\n");
        $display("  ███████╗ █████╗ ██╗██╗     ");
        $display("  ██╔════╝██╔══██╗██║██║     ");
        $display("  █████╗  ███████║██║██║     ");
        $display("  ██╔══╝  ██╔══██║██║██║     ");
        $display("  ██║     ██║  ██║██║███████╗");
        $display("  ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝");
        $display("\n");
        $display("         ❌ TESTS FAILED!");
        $display("\n");
    end
    
    $display("="*80);
    $display("Simulation time: %.2f us", $realtime / 1000.0);
    $display("="*80);
    
    #(`CYCLE_TIME * 10);
    $finish;
end

// ============================================================================
// Timeout Watchdog
// ============================================================================
initial begin
    #(`CYCLE_TIME * 5000000);
    $display("\n");
    $display("="*80);
    $display("❌ TIMEOUT: Simulation exceeded 5M cycles");
    $display("="*80);
    $finish;
end

endmodule