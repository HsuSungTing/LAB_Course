`ifdef RTL
    `define CYCLE_TIME 45.0
`endif
`ifdef GATE
    `define CYCLE_TIME 45.0
`endif

module PATTERN(
    // Output Port
    clk,
    rst_n,
    in_valid,
    Image,
    Kernel_ch1,
    Kernel_ch2,
    Weight_Bias,
    task_number,
    mode,
    capacity_cost,
    // Input Port
    out_valid,
    out
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg         clk, rst_n, in_valid;
output reg [31:0]  Image;
output reg [31:0]  Kernel_ch1;
output reg [31:0]  Kernel_ch2;
output reg [31:0]  Weight_Bias;
output reg         task_number;
output reg [1:0]   mode;
output reg [3:0]   capacity_cost;

input              out_valid;
input      [31:0]  out;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
real CYCLE = `CYCLE_TIME;
integer PATNUM;
integer patcount;
integer i, j, k;
integer latency;
integer total_latency;
integer file_in, file_out;
integer cycles;
integer gap;

// DW floating point parameters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;

// Task 0 storage
reg [31:0] image_task0 [0:71];      // 6x6x2 = 72
reg [31:0] kernel_ch1_task0 [0:17]; // 2x3x3 = 18
reg [31:0] kernel_ch2_task0 [0:17]; // 2x3x3 = 18
reg [31:0] weight_bias_task0 [0:56]; // 5x8 + 5 + 3x5 + 3 = 57
reg [31:0] golden_out_task0 [0:2];  // 3 outputs

// Task 1 storage
reg [31:0] image_task1 [0:35];      // 6x6 = 36
reg [31:0] kernel_ch1_task1 [0:17]; // 4x3x3 / 2 = 18
reg [31:0] kernel_ch2_task1 [0:17]; // 4x3x3 / 2 = 18
reg [3:0]  capacity_cost_task1 [0:4]; // capacity + 4 costs
reg [31:0] golden_out_task1;        // 1 output (32-bit with 4-bit selection)

reg        current_task;
reg [1:0]  current_mode;

//---------------------------------------------------------------------
//   CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;

initial clk = 0;

//---------------------------------------------------------------------
//   INITIAL
//---------------------------------------------------------------------
initial begin
    file_in = $fopen("../00_TESTBED/input.txt", "r");
    file_out = $fopen("../00_TESTBED/output.txt", "r");

    $fscanf(file_in, "%d\n", PATNUM);

    if (file_in == 0 || file_out == 0) begin
        $display("========================================================");
        $display("   Error: Cannot open input.txt or output.txt          ");
        $display("========================================================");
        $finish;
    end
    
    reset_signal_task;
    total_latency = 0;
    
    for (patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        
        // Random gap between patterns (2~4 cycles)
        gap = 2 + ({$random} % 50);
        repeat(gap) @(negedge clk);
    end
    
    $fclose(file_in);
    $fclose(file_out);
    YOU_PASS_task;
end

//---------------------------------------------------------------------
//   TASK: Reset
//---------------------------------------------------------------------
task reset_signal_task; begin
    rst_n = 1'b1;
    in_valid = 1'b0;
    Image = 32'bx;
    Kernel_ch1 = 32'bx;
    Kernel_ch2 = 32'bx;
    Weight_Bias = 32'bx;
    task_number = 1'bx;
    mode = 2'bx;
    capacity_cost = 4'bx;
    
    force clk = 0;
    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;
    
    // if (out_valid !== 0 || out !== 0) begin
    //     $display("========================================================");
    //     $display("   Output signals should be 0 after reset               ");
    //     $display("========================================================");
    //     repeat(2) #CYCLE;
    //     $finish;
    // end
    
    #CYCLE; release clk;
end endtask

//---------------------------------------------------------------------
//   TASK: Input
//---------------------------------------------------------------------
task input_task; begin
    // Read task and mode
    if ($fscanf(file_in, "%d %d\n", current_task, current_mode) != 2) begin
        $display("Error reading task and mode for pattern %0d", patcount);
        $finish;
    end
    
    $display("Reading Pattern %0d: Task=%0d, Mode=%0d", patcount, current_task, current_mode);
    
    if (current_task == 0) begin
        // Task 0: Read all data
        // Read Image (72 cycles)
        for (i = 0; i < 72; i = i + 1) begin
            if ($fscanf(file_in, "%b\n", image_task0[i]) != 1) begin
                $display("Error reading image data at cycle %0d", i);
                $finish;
            end
        end
        
        // Read Kernels (18 cycles, ch1 and ch2 together)
        for (i = 0; i < 18; i = i + 1) begin
            if ($fscanf(file_in, "%b %b\n", kernel_ch1_task0[i], kernel_ch2_task0[i]) != 2) begin
                $display("Error reading kernel data at cycle %0d", i);
                $finish;
            end
        end
        
        // Read Weight_Bias (57 cycles)
        for (i = 0; i < 57; i = i + 1) begin
            if ($fscanf(file_in, "%b\n", weight_bias_task0[i]) != 1) begin
                $display("Error reading weight_bias data at cycle %0d", i);
                $finish;
            end
        end
        
        // Read golden output (3 values)
        for (i = 0; i < 3; i = i + 1) begin
            if ($fscanf(file_out, "%b\n", golden_out_task0[i]) != 1) begin
                $display("Error reading golden output at index %0d", i);
                $finish;
            end
        end
        
        // Send input to DUT
        @(negedge clk);
        in_valid = 1'b1;
        task_number = current_task;
        mode = current_mode;
        
        for (i = 0; i < 72; i = i + 1) begin
            Image = image_task0[i];
            if (i < 18) begin
                Kernel_ch1 = kernel_ch1_task0[i];
                Kernel_ch2 = kernel_ch2_task0[i];
            end else begin
                Kernel_ch1 = 32'bx;
                Kernel_ch2 = 32'bx;
            end
            
            if (i < 57) begin
                Weight_Bias = weight_bias_task0[i];
            end else begin
                Weight_Bias = 32'bx;
            end
            
            if (i > 0) begin
                task_number = 1'bx;
                mode = 2'bx;
            end
            
            capacity_cost = 4'bx;
            
            @(negedge clk);
        end
        
    end else begin
        // Task 1: Read all data
        // Read Image (36 cycles)
        for (i = 0; i < 36; i = i + 1) begin
            if ($fscanf(file_in, "%b\n", image_task1[i]) != 1) begin
                $display("Error reading image data at cycle %0d", i);
                $finish;
            end
        end
        
        // Read Kernels (18 cycles)
        for (i = 0; i < 18; i = i + 1) begin
            if ($fscanf(file_in, "%b %b\n", kernel_ch1_task1[i], kernel_ch2_task1[i]) != 2) begin
                $display("Error reading kernel data at cycle %0d", i);
                $finish;
            end
        end
        
        // Read capacity_cost (5 values)
        for (i = 0; i < 5; i = i + 1) begin
            if ($fscanf(file_in, "%d\n", capacity_cost_task1[i]) != 1) begin
                $display("Error reading capacity_cost at index %0d", i);
                $finish;
            end
        end
        
        // Read golden output
        if ($fscanf(file_out, "%b\n", golden_out_task1) != 1) begin
            $display("Error reading golden output for task 1");
            $finish;
        end
        
        // Send input to DUT
        @(negedge clk);
        in_valid = 1'b1;
        task_number = current_task;
        mode = current_mode;
        
        for (i = 0; i < 36; i = i + 1) begin
            Image = image_task1[i];
            
            if (i < 18) begin
                Kernel_ch1 = kernel_ch1_task1[i];
                Kernel_ch2 = kernel_ch2_task1[i];
            end else begin
                Kernel_ch1 = 32'bx;
                Kernel_ch2 = 32'bx;
            end
            
            if (i < 5) begin
                capacity_cost = capacity_cost_task1[i];
            end else begin
                capacity_cost = 4'bx;
            end
            
            if (i > 0) begin
                task_number = 1'bx;
                mode = 2'bx;
            end
            
            Weight_Bias = 32'bx;
            
            @(negedge clk);
        end
    end
    
    // Pull down in_valid
    in_valid = 1'b0;
    Image = 32'bx;
    Kernel_ch1 = 32'bx;
    Kernel_ch2 = 32'bx;
    Weight_Bias = 32'bx;
    task_number = 1'bx;
    mode = 2'bx;
    capacity_cost = 4'bx;
    
end endtask

//---------------------------------------------------------------------
//   TASK: Wait out_valid (簡化版，不等待 out_valid)
//---------------------------------------------------------------------
task wait_out_valid_task; begin
    // 因為 design 沒接線，跳過等待 out_valid
    // 只等待幾個 cycle 讓波形好看
    repeat(150) @(negedge clk);
    $display("Skipping out_valid wait (design not connected)");
end endtask

//---------------------------------------------------------------------
//   TASK: Check Answer (只顯示讀取的 golden 答案)
//---------------------------------------------------------------------
task check_ans_task; begin
    if (current_task == 0) begin
        $display("  Golden Output (Task 0):");
        for (i = 0; i < 3; i = i + 1) begin
            $display("    [%0d] = %b", i, golden_out_task0[i]);
        end
    end else begin
        $display("  Golden Output (Task 1): %b (selection=%b)", golden_out_task1, golden_out_task1[3:0]);
    end
    
    $display("Pattern %0d completed - 請檢查波形確認資料正確\n", patcount);
    
    // 等待一些 cycle
    repeat(3) @(negedge clk);
end endtask

//---------------------------------------------------------------------
//   FUNCTION: Compare floating point with tolerance
//---------------------------------------------------------------------
function compare_float;
    input [31:0] a, b;
    real fa, fb, diff;
    begin
        fa = $bitstoreal(a);
        fb = $bitstoreal(b);
        diff = (fa > fb) ? (fa - fb) : (fb - fa);
        compare_float = (diff < 0.000001);
    end
endfunction

//---------------------------------------------------------------------
//   TASK: Pass
//---------------------------------------------------------------------
task YOU_PASS_task; begin
    $display("========================================================");
    $display("   資料讀取測試完成                                      ");
    $display("   Total Patterns: %0d                                  ", PATNUM);
    $display("   請檢查波形確認以下項目：                              ");
    $display("   1. in_valid 持續正確的 cycles (Task0=72, Task1=36)   ");
    $display("   2. Image, Kernel, Weight_Bias 資料流正確              ");
    $display("   3. task_number 和 mode 只在第一個 cycle 有效          ");
    $display("   4. 其他 cycle 的控制訊號為 x                          ");
    $display("========================================================");
    repeat(2) @(negedge clk);
    $finish;
end endtask

endmodule