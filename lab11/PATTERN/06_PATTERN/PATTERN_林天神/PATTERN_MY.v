//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : PATTERN.v
//    Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`ifdef RTL
	`define CYCLE_TIME  20.0
`elsif GATE
    `define CYCLE_TIME  20.0
`elsif POST
    `define CYCLE_TIME  20.0
`endif

module PATTERN(
    // Output signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    

    // Input signals
	busy
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg        clk, rst_n;
output reg        in_valid_data;
output reg  [7:0] data;
output reg        in_valid_cmd;
output reg [17:0] cmd;

// Input
input busy;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// parameter
// ========================================
parameter PATNUM = 10000;
parameter TOTAL_IMAGE = 128;
parameter IMG_SIZE = 16;
parameter MAX_LATENCY = 5000;

// ========================================
// integer & parameter
// ========================================
integer i, j, k, pat;
integer latency, total_latency;
integer err_count;

// ========================================
// wire & reg
// ========================================
// Golden images
reg [7:0] golden_img [0:TOTAL_IMAGE-1][0:IMG_SIZE-1][0:IMG_SIZE-1];
reg [7:0] temp_img [0:IMG_SIZE-1][0:IMG_SIZE-1];
reg [7:0] result_img [0:IMG_SIZE-1][0:IMG_SIZE-1];

// Command
reg [1:0] opcode, funct;
reg [6:0] ms, md;

//================================================================
// initial
//================================================================
initial begin
    clk = 0;
    rst_n = 1;
    in_valid_data = 0;
    data = 'bx;
    in_valid_cmd = 0;
    cmd = 'bx;
    total_latency = 0;
    err_count = 0;
    
    force clk = 0;
    reset_task;
    @(negedge clk);
    
    // Generate and input images
    generate_images;
    input_images;
    
    // Test patterns
    for(pat=0; pat<PATNUM; pat=pat+1) begin
        input_command;
        wait_busy_low;
        check_answer;
        @(negedge clk);
    end
    
    YOU_PASS_task;
end

//================================================================
// task
//================================================================

task reset_task; begin
    #(0.5); rst_n = 0;
    #(CYCLE*3);
    if(busy !== 1) begin
        $display("************************************************************");  
        $display("*   FAIL! busy should be 1 after reset                    *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    #(CYCLE*0.5); rst_n = 1;
    #(CYCLE*3); release clk;
end endtask

task generate_images; begin
    for(i=0; i<TOTAL_IMAGE; i=i+1) begin
        for(j=0; j<IMG_SIZE; j=j+1) begin
            for(k=0; k<IMG_SIZE; k=k+1) begin
                golden_img[i][j][k] = $random % 256;
            end
        end
    end
end endtask

task input_images; begin
    // Check busy overlap with in_valid_data
    if(busy === 0) begin
        $display("************************************************************");  
        $display("*   FAIL! busy should not be 0 when in_valid_data is high *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    
    repeat($random % 3 + 2) @(negedge clk);
    
    in_valid_data = 1;
    for(i=0; i<TOTAL_IMAGE; i=i+1) begin
        for(j=0; j<IMG_SIZE; j=j+1) begin
            for(k=0; k<IMG_SIZE; k=k+1) begin
                if(busy === 0) begin
                    $display("************************************************************");  
                    $display("*   FAIL! busy overlaps with in_valid_data                *");
                    $display("************************************************************");
                    repeat(2) @(negedge clk);
                    $finish;
                end
                data = golden_img[i][j][k];
                @(negedge clk);
            end
        end
    end
    in_valid_data = 0;
    data = 'bx;
end endtask

task input_command; begin
    // Check busy overlap with in_valid_cmd
    if(busy === 0) begin
        $display("************************************************************");  
        $display("*   FAIL! busy should not be 0 before command input       *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    
    // Generate random command
    opcode = $random % 4;
    
    // Handle funct based on opcode
    if(opcode == 1) begin
        // For rotation (opcode=01), only 00, 01, 10 are valid
        funct = $urandom_range(0,2);  // 0, 1, or 2
    end else begin
        funct = $random % 4;  // 0, 1, 2, or 3
    end
    
    ms = $random % TOTAL_IMAGE;
    md = $random % TOTAL_IMAGE;
    
    // Wait 2-4 cycles
    repeat($random % 3 + 2) @(negedge clk);
    
    in_valid_cmd = 1;
    cmd = {opcode, funct, ms, md};
    
    if(busy === 0) begin
        $display("************************************************************");  
        $display("*   FAIL! busy overlaps with in_valid_cmd                 *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    
    // Calculate golden answer
    calculate_golden;
    
    @(negedge clk);
    in_valid_cmd = 0;
    cmd = 'bx;
end endtask

task wait_busy_low; begin
    latency = 0;
    while(busy === 1) begin
        latency = latency + 1;
        if(latency > MAX_LATENCY) begin
            $display("************************************************************");  
            $display("*   FAIL! Latency exceeded %d cycles                      *", MAX_LATENCY);
            $display("************************************************************");
            repeat(2) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;

end endtask

task check_answer; begin
    // Fetch from SRAM based on md
    fetch_result_from_sram;
    
    // Compare
    for(j=0; j<IMG_SIZE; j=j+1) begin
        for(k=0; k<IMG_SIZE; k=k+1) begin
            if(result_img[j][k] !== golden_img[md][j][k]) begin
                $display("************************************************************");  
                $display("*   FAIL! Pattern: %d                                      *", pat);
                $display("*   Operation: opcode=%b, funct=%b                        *", opcode, funct);
                $display("*   ms=%d, md=%d                                           *", ms, md);
                $display("*   Image: %d, Position: [%2d][%2d]                       *", md, j, k);
                $display("*   Golden: %3d (0x%h), Your: %3d (0x%h)                  *", 
                         golden_img[md][j][k], golden_img[md][j][k],
                         result_img[j][k], result_img[j][k]);
                $display("************************************************************");
                repeat(2) @(negedge clk);
                $finish;
            end
        end
    end
$display("\033[1;32mPASS PATTERN NO.%4d\033[0m latency: %5d cycles", pat, latency);

end endtask

task calculate_golden; begin
    integer block_row, block_col;
    integer bi, bj, idx;
    
    // Apply operation directly on golden_img[md]
    case({opcode, funct})
        4'b0000: begin // MX - Mirror X
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][IMG_SIZE-1-j][k];
                end
            end
        end
        
        4'b0001: begin // MY - Mirror Y
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][j][IMG_SIZE-1-k];
                end
            end
        end
        
        4'b0010: begin // TRP - Transpose
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][k][j];
                end
            end
        end
        
        4'b0011: begin // STRP - Secondary Transpose
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][IMG_SIZE-1-k][IMG_SIZE-1-j];
                end
            end
        end
        
        4'b0100: begin // R90 - Rotate 90
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][IMG_SIZE-1-k][j];
                end
            end
        end
        
        4'b0101: begin // R180 - Rotate 180
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][IMG_SIZE-1-j][IMG_SIZE-1-k];
                end
            end
        end
        
        4'b0110: begin // R270 - Rotate 270
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][k][IMG_SIZE-1-j];
                end
            end
        end
        
        4'b1000: begin // RS - Right shift
            for(j=0; j<IMG_SIZE; j=j+1) begin
                temp_img[j][0] = golden_img[ms][j][4];
                temp_img[j][1] = golden_img[ms][j][3];
                temp_img[j][2] = golden_img[ms][j][2];
                temp_img[j][3] = golden_img[ms][j][1];
                temp_img[j][4] = golden_img[ms][j][0];
                for(k=5; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][j][k-5];
                end
            end
        end
        
        4'b1001: begin // LS - Left shift
            for(j=0; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<11; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][j][k+5];
                end
                temp_img[j][11] = golden_img[ms][j][15];
                temp_img[j][12] = golden_img[ms][j][14];
                temp_img[j][13] = golden_img[ms][j][13];
                temp_img[j][14] = golden_img[ms][j][12];
                temp_img[j][15] = golden_img[ms][j][11];
            end
        end
        
        4'b1010: begin // US - Up shift
            for(j=0; j<11; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][j+5][k];
                end
            end
            for(k=0; k<IMG_SIZE; k=k+1) begin
                temp_img[11][k] = golden_img[ms][15][k];
                temp_img[12][k] = golden_img[ms][14][k];
                temp_img[13][k] = golden_img[ms][13][k];
                temp_img[14][k] = golden_img[ms][12][k];
                temp_img[15][k] = golden_img[ms][11][k];
            end
        end
        
        4'b1011: begin // DS - Down shift
            for(k=0; k<IMG_SIZE; k=k+1) begin
                temp_img[0][k] = golden_img[ms][4][k];
                temp_img[1][k] = golden_img[ms][3][k];
                temp_img[2][k] = golden_img[ms][2][k];
                temp_img[3][k] = golden_img[ms][1][k];
                temp_img[4][k] = golden_img[ms][0][k];
            end
            for(j=5; j<IMG_SIZE; j=j+1) begin
                for(k=0; k<IMG_SIZE; k=k+1) begin
                    temp_img[j][k] = golden_img[ms][j-5][k];
                end
            end
        end
        
        4'b1100: begin // ZZ4 - 4x4 Zig-zag
            for(block_row=0; block_row<4; block_row=block_row+1) begin
                for(block_col=0; block_col<4; block_col=block_col+1) begin
                    temp_img[block_row*4 + 0][block_col*4 + 0] = golden_img[ms][block_row*4 + 0][block_col*4 + 0];
                    temp_img[block_row*4 + 0][block_col*4 + 1] = golden_img[ms][block_row*4 + 0][block_col*4 + 1];
                    temp_img[block_row*4 + 0][block_col*4 + 2] = golden_img[ms][block_row*4 + 1][block_col*4 + 0];
                    temp_img[block_row*4 + 0][block_col*4 + 3] = golden_img[ms][block_row*4 + 2][block_col*4 + 0];
                    temp_img[block_row*4 + 1][block_col*4 + 0] = golden_img[ms][block_row*4 + 1][block_col*4 + 1];
                    temp_img[block_row*4 + 1][block_col*4 + 1] = golden_img[ms][block_row*4 + 0][block_col*4 + 2];
                    temp_img[block_row*4 + 1][block_col*4 + 2] = golden_img[ms][block_row*4 + 0][block_col*4 + 3];
                    temp_img[block_row*4 + 1][block_col*4 + 3] = golden_img[ms][block_row*4 + 1][block_col*4 + 2];
                    temp_img[block_row*4 + 2][block_col*4 + 0] = golden_img[ms][block_row*4 + 2][block_col*4 + 1];
                    temp_img[block_row*4 + 2][block_col*4 + 1] = golden_img[ms][block_row*4 + 3][block_col*4 + 0];
                    temp_img[block_row*4 + 2][block_col*4 + 2] = golden_img[ms][block_row*4 + 3][block_col*4 + 1];
                    temp_img[block_row*4 + 2][block_col*4 + 3] = golden_img[ms][block_row*4 + 2][block_col*4 + 2];
                    temp_img[block_row*4 + 3][block_col*4 + 0] = golden_img[ms][block_row*4 + 1][block_col*4 + 3];
                    temp_img[block_row*4 + 3][block_col*4 + 1] = golden_img[ms][block_row*4 + 2][block_col*4 + 3];
                    temp_img[block_row*4 + 3][block_col*4 + 2] = golden_img[ms][block_row*4 + 3][block_col*4 + 2];
                    temp_img[block_row*4 + 3][block_col*4 + 3] = golden_img[ms][block_row*4 + 3][block_col*4 + 3];
                end
            end
        end
        
        4'b1101: begin // ZZ8 - 8x8 Zig-zag
            for(block_row=0; block_row<2; block_row=block_row+1) begin
                for(block_col=0; block_col<2; block_col=block_col+1) begin
                    temp_img[block_row*8 + 0][block_col*8 + 0] = golden_img[ms][block_row*8 + 0][block_col*8 + 0];
                    temp_img[block_row*8 + 0][block_col*8 + 1] = golden_img[ms][block_row*8 + 0][block_col*8 + 1];
                    temp_img[block_row*8 + 0][block_col*8 + 2] = golden_img[ms][block_row*8 + 1][block_col*8 + 0];
                    temp_img[block_row*8 + 0][block_col*8 + 3] = golden_img[ms][block_row*8 + 2][block_col*8 + 0];
                    temp_img[block_row*8 + 0][block_col*8 + 4] = golden_img[ms][block_row*8 + 1][block_col*8 + 1];
                    temp_img[block_row*8 + 0][block_col*8 + 5] = golden_img[ms][block_row*8 + 0][block_col*8 + 2];
                    temp_img[block_row*8 + 0][block_col*8 + 6] = golden_img[ms][block_row*8 + 0][block_col*8 + 3];
                    temp_img[block_row*8 + 0][block_col*8 + 7] = golden_img[ms][block_row*8 + 1][block_col*8 + 2];
                    temp_img[block_row*8 + 1][block_col*8 + 0] = golden_img[ms][block_row*8 + 2][block_col*8 + 1];
                    temp_img[block_row*8 + 1][block_col*8 + 1] = golden_img[ms][block_row*8 + 3][block_col*8 + 0];
                    temp_img[block_row*8 + 1][block_col*8 + 2] = golden_img[ms][block_row*8 + 4][block_col*8 + 0];
                    temp_img[block_row*8 + 1][block_col*8 + 3] = golden_img[ms][block_row*8 + 3][block_col*8 + 1];
                    temp_img[block_row*8 + 1][block_col*8 + 4] = golden_img[ms][block_row*8 + 2][block_col*8 + 2];
                    temp_img[block_row*8 + 1][block_col*8 + 5] = golden_img[ms][block_row*8 + 1][block_col*8 + 3];
                    temp_img[block_row*8 + 1][block_col*8 + 6] = golden_img[ms][block_row*8 + 0][block_col*8 + 4];
                    temp_img[block_row*8 + 1][block_col*8 + 7] = golden_img[ms][block_row*8 + 0][block_col*8 + 5];
                    temp_img[block_row*8 + 2][block_col*8 + 0] = golden_img[ms][block_row*8 + 1][block_col*8 + 4];
                    temp_img[block_row*8 + 2][block_col*8 + 1] = golden_img[ms][block_row*8 + 2][block_col*8 + 3];
                    temp_img[block_row*8 + 2][block_col*8 + 2] = golden_img[ms][block_row*8 + 3][block_col*8 + 2];
                    temp_img[block_row*8 + 2][block_col*8 + 3] = golden_img[ms][block_row*8 + 4][block_col*8 + 1];
                    temp_img[block_row*8 + 2][block_col*8 + 4] = golden_img[ms][block_row*8 + 5][block_col*8 + 0];
                    temp_img[block_row*8 + 2][block_col*8 + 5] = golden_img[ms][block_row*8 + 6][block_col*8 + 0];
                    temp_img[block_row*8 + 2][block_col*8 + 6] = golden_img[ms][block_row*8 + 5][block_col*8 + 1];
                    temp_img[block_row*8 + 2][block_col*8 + 7] = golden_img[ms][block_row*8 + 4][block_col*8 + 2];
                    temp_img[block_row*8 + 3][block_col*8 + 0] = golden_img[ms][block_row*8 + 3][block_col*8 + 3];
                    temp_img[block_row*8 + 3][block_col*8 + 1] = golden_img[ms][block_row*8 + 2][block_col*8 + 4];
                    temp_img[block_row*8 + 3][block_col*8 + 2] = golden_img[ms][block_row*8 + 1][block_col*8 + 5];
                    temp_img[block_row*8 + 3][block_col*8 + 3] = golden_img[ms][block_row*8 + 0][block_col*8 + 6];
                    temp_img[block_row*8 + 3][block_col*8 + 4] = golden_img[ms][block_row*8 + 0][block_col*8 + 7];
                    temp_img[block_row*8 + 3][block_col*8 + 5] = golden_img[ms][block_row*8 + 1][block_col*8 + 6];
                    temp_img[block_row*8 + 3][block_col*8 + 6] = golden_img[ms][block_row*8 + 2][block_col*8 + 5];
                    temp_img[block_row*8 + 3][block_col*8 + 7] = golden_img[ms][block_row*8 + 3][block_col*8 + 4];
                    temp_img[block_row*8 + 4][block_col*8 + 0] = golden_img[ms][block_row*8 + 4][block_col*8 + 3];
                    temp_img[block_row*8 + 4][block_col*8 + 1] = golden_img[ms][block_row*8 + 5][block_col*8 + 2];
                    temp_img[block_row*8 + 4][block_col*8 + 2] = golden_img[ms][block_row*8 + 6][block_col*8 + 1];
                    temp_img[block_row*8 + 4][block_col*8 + 3] = golden_img[ms][block_row*8 + 7][block_col*8 + 0];
                    temp_img[block_row*8 + 4][block_col*8 + 4] = golden_img[ms][block_row*8 + 7][block_col*8 + 1];
                    temp_img[block_row*8 + 4][block_col*8 + 5] = golden_img[ms][block_row*8 + 6][block_col*8 + 2];
                    temp_img[block_row*8 + 4][block_col*8 + 6] = golden_img[ms][block_row*8 + 5][block_col*8 + 3];
                    temp_img[block_row*8 + 4][block_col*8 + 7] = golden_img[ms][block_row*8 + 4][block_col*8 + 4];
                    temp_img[block_row*8 + 5][block_col*8 + 0] = golden_img[ms][block_row*8 + 3][block_col*8 + 5];
                    temp_img[block_row*8 + 5][block_col*8 + 1] = golden_img[ms][block_row*8 + 2][block_col*8 + 6];
                    temp_img[block_row*8 + 5][block_col*8 + 2] = golden_img[ms][block_row*8 + 1][block_col*8 + 7];
                    temp_img[block_row*8 + 5][block_col*8 + 3] = golden_img[ms][block_row*8 + 2][block_col*8 + 7];
                    temp_img[block_row*8 + 5][block_col*8 + 4] = golden_img[ms][block_row*8 + 3][block_col*8 + 6];
                    temp_img[block_row*8 + 5][block_col*8 + 5] = golden_img[ms][block_row*8 + 4][block_col*8 + 5];
                    temp_img[block_row*8 + 5][block_col*8 + 6] = golden_img[ms][block_row*8 + 5][block_col*8 + 4];
                    temp_img[block_row*8 + 5][block_col*8 + 7] = golden_img[ms][block_row*8 + 6][block_col*8 + 3];
                    temp_img[block_row*8 + 6][block_col*8 + 0] = golden_img[ms][block_row*8 + 7][block_col*8 + 2];
                    temp_img[block_row*8 + 6][block_col*8 + 1] = golden_img[ms][block_row*8 + 7][block_col*8 + 3];
                    temp_img[block_row*8 + 6][block_col*8 + 2] = golden_img[ms][block_row*8 + 6][block_col*8 + 4];
                    temp_img[block_row*8 + 6][block_col*8 + 3] = golden_img[ms][block_row*8 + 5][block_col*8 + 5];
                    temp_img[block_row*8 + 6][block_col*8 + 4] = golden_img[ms][block_row*8 + 4][block_col*8 + 6];
                    temp_img[block_row*8 + 6][block_col*8 + 5] = golden_img[ms][block_row*8 + 3][block_col*8 + 7];
                    temp_img[block_row*8 + 6][block_col*8 + 6] = golden_img[ms][block_row*8 + 4][block_col*8 + 7];
                    temp_img[block_row*8 + 6][block_col*8 + 7] = golden_img[ms][block_row*8 + 5][block_col*8 + 6];
                    temp_img[block_row*8 + 7][block_col*8 + 0] = golden_img[ms][block_row*8 + 6][block_col*8 + 5];
                    temp_img[block_row*8 + 7][block_col*8 + 1] = golden_img[ms][block_row*8 + 7][block_col*8 + 4];
                    temp_img[block_row*8 + 7][block_col*8 + 2] = golden_img[ms][block_row*8 + 7][block_col*8 + 5];
                    temp_img[block_row*8 + 7][block_col*8 + 3] = golden_img[ms][block_row*8 + 6][block_col*8 + 6];
                    temp_img[block_row*8 + 7][block_col*8 + 4] = golden_img[ms][block_row*8 + 5][block_col*8 + 7];
                    temp_img[block_row*8 + 7][block_col*8 + 5] = golden_img[ms][block_row*8 + 6][block_col*8 + 7];
                    temp_img[block_row*8 + 7][block_col*8 + 6] = golden_img[ms][block_row*8 + 7][block_col*8 + 6];
                    temp_img[block_row*8 + 7][block_col*8 + 7] = golden_img[ms][block_row*8 + 7][block_col*8 + 7];
                end
            end
        end
        
        4'b1110: begin // MO4 - 4x4 Morton Order
            for(block_row=0; block_row<4; block_row=block_row+1) begin
                for(block_col=0; block_col<4; block_col=block_col+1) begin
                    temp_img[block_row*4 + 0][block_col*4 + 0] = golden_img[ms][block_row*4 + 0][block_col*4 + 0];
                    temp_img[block_row*4 + 0][block_col*4 + 1] = golden_img[ms][block_row*4 + 0][block_col*4 + 1];
                    temp_img[block_row*4 + 0][block_col*4 + 2] = golden_img[ms][block_row*4 + 1][block_col*4 + 0];
                    temp_img[block_row*4 + 0][block_col*4 + 3] = golden_img[ms][block_row*4 + 1][block_col*4 + 1];
                    temp_img[block_row*4 + 1][block_col*4 + 0] = golden_img[ms][block_row*4 + 0][block_col*4 + 2];
                    temp_img[block_row*4 + 1][block_col*4 + 1] = golden_img[ms][block_row*4 + 0][block_col*4 + 3];
                    temp_img[block_row*4 + 1][block_col*4 + 2] = golden_img[ms][block_row*4 + 1][block_col*4 + 2];
                    temp_img[block_row*4 + 1][block_col*4 + 3] = golden_img[ms][block_row*4 + 1][block_col*4 + 3];
                    temp_img[block_row*4 + 2][block_col*4 + 0] = golden_img[ms][block_row*4 + 2][block_col*4 + 0];
                    temp_img[block_row*4 + 2][block_col*4 + 1] = golden_img[ms][block_row*4 + 2][block_col*4 + 1];
                    temp_img[block_row*4 + 2][block_col*4 + 2] = golden_img[ms][block_row*4 + 3][block_col*4 + 0];
                    temp_img[block_row*4 + 2][block_col*4 + 3] = golden_img[ms][block_row*4 + 3][block_col*4 + 1];
                    temp_img[block_row*4 + 3][block_col*4 + 0] = golden_img[ms][block_row*4 + 2][block_col*4 + 2];
                    temp_img[block_row*4 + 3][block_col*4 + 1] = golden_img[ms][block_row*4 + 2][block_col*4 + 3];
                    temp_img[block_row*4 + 3][block_col*4 + 2] = golden_img[ms][block_row*4 + 3][block_col*4 + 2];
                    temp_img[block_row*4 + 3][block_col*4 + 3] = golden_img[ms][block_row*4 + 3][block_col*4 + 3];
                end
            end
        end
        
        4'b1111: begin // MO8 - 8x8 Morton Order
            for(block_row=0; block_row<2; block_row=block_row+1) begin
                for(block_col=0; block_col<2; block_col=block_col+1) begin
                    temp_img[block_row*8 + 0][block_col*8 + 0] = golden_img[ms][block_row*8 + 0][block_col*8 + 0];
                    temp_img[block_row*8 + 0][block_col*8 + 1] = golden_img[ms][block_row*8 + 0][block_col*8 + 1];
                    temp_img[block_row*8 + 0][block_col*8 + 2] = golden_img[ms][block_row*8 + 1][block_col*8 + 0];
                    temp_img[block_row*8 + 0][block_col*8 + 3] = golden_img[ms][block_row*8 + 1][block_col*8 + 1];
                    temp_img[block_row*8 + 0][block_col*8 + 4] = golden_img[ms][block_row*8 + 0][block_col*8 + 2];
                    temp_img[block_row*8 + 0][block_col*8 + 5] = golden_img[ms][block_row*8 + 0][block_col*8 + 3];
                    temp_img[block_row*8 + 0][block_col*8 + 6] = golden_img[ms][block_row*8 + 1][block_col*8 + 2];
                    temp_img[block_row*8 + 0][block_col*8 + 7] = golden_img[ms][block_row*8 + 1][block_col*8 + 3];
                    temp_img[block_row*8 + 1][block_col*8 + 0] = golden_img[ms][block_row*8 + 2][block_col*8 + 0];
                    temp_img[block_row*8 + 1][block_col*8 + 1] = golden_img[ms][block_row*8 + 2][block_col*8 + 1];
                    temp_img[block_row*8 + 1][block_col*8 + 2] = golden_img[ms][block_row*8 + 3][block_col*8 + 0];
                    temp_img[block_row*8 + 1][block_col*8 + 3] = golden_img[ms][block_row*8 + 3][block_col*8 + 1];
                    temp_img[block_row*8 + 1][block_col*8 + 4] = golden_img[ms][block_row*8 + 2][block_col*8 + 2];
                    temp_img[block_row*8 + 1][block_col*8 + 5] = golden_img[ms][block_row*8 + 2][block_col*8 + 3];
                    temp_img[block_row*8 + 1][block_col*8 + 6] = golden_img[ms][block_row*8 + 3][block_col*8 + 2];
                    temp_img[block_row*8 + 1][block_col*8 + 7] = golden_img[ms][block_row*8 + 3][block_col*8 + 3];
                    temp_img[block_row*8 + 2][block_col*8 + 0] = golden_img[ms][block_row*8 + 0][block_col*8 + 4];
                    temp_img[block_row*8 + 2][block_col*8 + 1] = golden_img[ms][block_row*8 + 0][block_col*8 + 5];
                    temp_img[block_row*8 + 2][block_col*8 + 2] = golden_img[ms][block_row*8 + 1][block_col*8 + 4];
                    temp_img[block_row*8 + 2][block_col*8 + 3] = golden_img[ms][block_row*8 + 1][block_col*8 + 5];
                    temp_img[block_row*8 + 2][block_col*8 + 4] = golden_img[ms][block_row*8 + 0][block_col*8 + 6];
                    temp_img[block_row*8 + 2][block_col*8 + 5] = golden_img[ms][block_row*8 + 0][block_col*8 + 7];
                    temp_img[block_row*8 + 2][block_col*8 + 6] = golden_img[ms][block_row*8 + 1][block_col*8 + 6];
                    temp_img[block_row*8 + 2][block_col*8 + 7] = golden_img[ms][block_row*8 + 1][block_col*8 + 7];
                    temp_img[block_row*8 + 3][block_col*8 + 0] = golden_img[ms][block_row*8 + 2][block_col*8 + 4];
                    temp_img[block_row*8 + 3][block_col*8 + 1] = golden_img[ms][block_row*8 + 2][block_col*8 + 5];
                    temp_img[block_row*8 + 3][block_col*8 + 2] = golden_img[ms][block_row*8 + 3][block_col*8 + 4];
                    temp_img[block_row*8 + 3][block_col*8 + 3] = golden_img[ms][block_row*8 + 3][block_col*8 + 5];
                    temp_img[block_row*8 + 3][block_col*8 + 4] = golden_img[ms][block_row*8 + 2][block_col*8 + 6];
                    temp_img[block_row*8 + 3][block_col*8 + 5] = golden_img[ms][block_row*8 + 2][block_col*8 + 7];
                    temp_img[block_row*8 + 3][block_col*8 + 6] = golden_img[ms][block_row*8 + 3][block_col*8 + 6];
                    temp_img[block_row*8 + 3][block_col*8 + 7] = golden_img[ms][block_row*8 + 3][block_col*8 + 7];
                    temp_img[block_row*8 + 4][block_col*8 + 0] = golden_img[ms][block_row*8 + 4][block_col*8 + 0];
                    temp_img[block_row*8 + 4][block_col*8 + 1] = golden_img[ms][block_row*8 + 4][block_col*8 + 1];
                    temp_img[block_row*8 + 4][block_col*8 + 2] = golden_img[ms][block_row*8 + 5][block_col*8 + 0];
                    temp_img[block_row*8 + 4][block_col*8 + 3] = golden_img[ms][block_row*8 + 5][block_col*8 + 1];
                    temp_img[block_row*8 + 4][block_col*8 + 4] = golden_img[ms][block_row*8 + 4][block_col*8 + 2];
                    temp_img[block_row*8 + 4][block_col*8 + 5] = golden_img[ms][block_row*8 + 4][block_col*8 + 3];
                    temp_img[block_row*8 + 4][block_col*8 + 6] = golden_img[ms][block_row*8 + 5][block_col*8 + 2];
                    temp_img[block_row*8 + 4][block_col*8 + 7] = golden_img[ms][block_row*8 + 5][block_col*8 + 3];
                    temp_img[block_row*8 + 5][block_col*8 + 0] = golden_img[ms][block_row*8 + 6][block_col*8 + 0];
                    temp_img[block_row*8 + 5][block_col*8 + 1] = golden_img[ms][block_row*8 + 6][block_col*8 + 1];
                    temp_img[block_row*8 + 5][block_col*8 + 2] = golden_img[ms][block_row*8 + 7][block_col*8 + 0];
                    temp_img[block_row*8 + 5][block_col*8 + 3] = golden_img[ms][block_row*8 + 7][block_col*8 + 1];
                    temp_img[block_row*8 + 5][block_col*8 + 4] = golden_img[ms][block_row*8 + 6][block_col*8 + 2];
                    temp_img[block_row*8 + 5][block_col*8 + 5] = golden_img[ms][block_row*8 + 6][block_col*8 + 3];
                    temp_img[block_row*8 + 5][block_col*8 + 6] = golden_img[ms][block_row*8 + 7][block_col*8 + 2];
                    temp_img[block_row*8 + 5][block_col*8 + 7] = golden_img[ms][block_row*8 + 7][block_col*8 + 3];
                    temp_img[block_row*8 + 6][block_col*8 + 0] = golden_img[ms][block_row*8 + 4][block_col*8 + 4];
                    temp_img[block_row*8 + 6][block_col*8 + 1] = golden_img[ms][block_row*8 + 4][block_col*8 + 5];
                    temp_img[block_row*8 + 6][block_col*8 + 2] = golden_img[ms][block_row*8 + 5][block_col*8 + 4];
                    temp_img[block_row*8 + 6][block_col*8 + 3] = golden_img[ms][block_row*8 + 5][block_col*8 + 5];
                    temp_img[block_row*8 + 6][block_col*8 + 4] = golden_img[ms][block_row*8 + 4][block_col*8 + 6];
                    temp_img[block_row*8 + 6][block_col*8 + 5] = golden_img[ms][block_row*8 + 4][block_col*8 + 7];
                    temp_img[block_row*8 + 6][block_col*8 + 6] = golden_img[ms][block_row*8 + 5][block_col*8 + 6];
                    temp_img[block_row*8 + 6][block_col*8 + 7] = golden_img[ms][block_row*8 + 5][block_col*8 + 7];
                    temp_img[block_row*8 + 7][block_col*8 + 0] = golden_img[ms][block_row*8 + 6][block_col*8 + 4];
                    temp_img[block_row*8 + 7][block_col*8 + 1] = golden_img[ms][block_row*8 + 6][block_col*8 + 5];
                    temp_img[block_row*8 + 7][block_col*8 + 2] = golden_img[ms][block_row*8 + 7][block_col*8 + 4];
                    temp_img[block_row*8 + 7][block_col*8 + 3] = golden_img[ms][block_row*8 + 7][block_col*8 + 5];
                    temp_img[block_row*8 + 7][block_col*8 + 4] = golden_img[ms][block_row*8 + 6][block_col*8 + 6];
                    temp_img[block_row*8 + 7][block_col*8 + 5] = golden_img[ms][block_row*8 + 6][block_col*8 + 7];
                    temp_img[block_row*8 + 7][block_col*8 + 6] = golden_img[ms][block_row*8 + 7][block_col*8 + 6];
                    temp_img[block_row*8 + 7][block_col*8 + 7] = golden_img[ms][block_row*8 + 7][block_col*8 + 7];
                end
            end
        end
    endcase
    
    // Store to golden destination
    for(j=0; j<IMG_SIZE; j=j+1) begin
        for(k=0; k<IMG_SIZE; k=k+1) begin
            golden_img[md][j][k] = temp_img[j][k];
        end
    end
end endtask

task fetch_result_from_sram; begin
    reg [11:0] addr;
    reg [6:0] img_idx;
    integer local_i, local_j;
    
    // Determine which SRAM and calculate address
    if(md < 16) begin // MEM0: image 0-15
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+1) begin
                addr = md * 256 + local_i * 16 + local_j;
                `ifdef RTL
                    result_img[local_i][local_j] = u_GTE.CORE.MEM0.Memory[addr];
                `elsif GATE
                    result_img[local_i][local_j] = u_GTE.CORE.MEM0.Memory[addr];
                `elsif POST
                    result_img[local_i][local_j] = u_CHIP.CORE.MEM0.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 32) begin // MEM1: image 16-31
        img_idx = md - 16;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+1) begin
                addr = img_idx * 256 + local_i * 16 + local_j;
                `ifdef RTL
                    result_img[local_i][local_j] = u_GTE.CORE.MEM1.Memory[addr];
                `elsif GATE
                    result_img[local_i][local_j] = u_GTE.CORE.MEM1.Memory[addr];
                `elsif POST
                    result_img[local_i][local_j] = u_CHIP.CORE.MEM1.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 48) begin // MEM2: image 32-47
        img_idx = md - 32;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+1) begin
                addr = img_idx * 256 + local_i * 16 + local_j;
                `ifdef RTL
                    result_img[local_i][local_j] = u_GTE.CORE.MEM2.Memory[addr];
                `elsif GATE
                    result_img[local_i][local_j] = u_GTE.CORE.MEM2.Memory[addr];
                `elsif POST
                    result_img[local_i][local_j] = u_CHIP.CORE.MEM2.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 64) begin // MEM3: image 48-63
        img_idx = md - 48;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+1) begin
                addr = img_idx * 256 + local_i * 16 + local_j;
                `ifdef RTL
                    result_img[local_i][local_j] = u_GTE.CORE.MEM3.Memory[addr];
                `elsif GATE
                    result_img[local_i][local_j] = u_GTE.CORE.MEM3.Memory[addr];
                `elsif POST
                    result_img[local_i][local_j] = u_CHIP.CORE.MEM3.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 80) begin // MEM4: image 64-79, 16-bit (2 pixels per address)
        img_idx = md - 64;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+2) begin
                addr = img_idx * 128 + local_i * 8 + local_j/2;
                `ifdef RTL
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_GTE.CORE.MEM4.Memory[addr];
                `elsif GATE
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_GTE.CORE.MEM4.Memory[addr];
                `elsif POST
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_CHIP.CORE.MEM4.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 96) begin // MEM5: image 80-95, 16-bit (2 pixels per address)
        img_idx = md - 80;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+2) begin
                addr = img_idx * 128 + local_i * 8 + local_j/2;
                `ifdef RTL
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_GTE.CORE.MEM5.Memory[addr];
                `elsif GATE
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_GTE.CORE.MEM5.Memory[addr];
                `elsif POST
                    {result_img[local_i][local_j], result_img[local_i][local_j+1]} = u_CHIP.CORE.MEM5.Memory[addr];
                `endif
            end
        end
    end
    else if(md < 112) begin // MEM6: image 96-111, 32-bit (4 pixels per address)
        img_idx = md - 96;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+4) begin
                addr = img_idx * 64 + local_i * 4 + local_j/4;
                `ifdef RTL
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_GTE.CORE.MEM6.Memory[addr];
                `elsif GATE
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_GTE.CORE.MEM6.Memory[addr];
                `elsif POST
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_CHIP.CORE.MEM6.Memory[addr];
                `endif
            end
        end
    end
    else begin // MEM7: image 112-127, 32-bit (4 pixels per address)
        img_idx = md - 112;
        for(local_i=0; local_i<IMG_SIZE; local_i=local_i+1) begin
            for(local_j=0; local_j<IMG_SIZE; local_j=local_j+4) begin
                addr = img_idx * 64 + local_i * 4 + local_j/4;
                `ifdef RTL
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_GTE.CORE.MEM7.Memory[addr];
                `elsif GATE
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_GTE.CORE.MEM7.Memory[addr];
                `elsif POST
                    {result_img[local_i][local_j], result_img[local_i][local_j+1], result_img[local_i][local_j+2], result_img[local_i][local_j+3]} = u_CHIP.CORE.MEM7.Memory[addr];
                `endif
            end
        end
    end
end endtask

task YOU_PASS_task; begin
    $display("************************************************************");  
    $display("*                  Congratulations!                        *");
    $display("*            All patterns have been passed!                *");
    $display("*         Total Patterns: %4d                              *", PATNUM);
    $display("*         Total Latency:  %8d cycles                       *", total_latency);
    $display("*         Average Latency: %6d cycles                      *", total_latency/PATNUM);
    $display("************************************************************");
    repeat(2) @(negedge clk);
    $finish;
end endtask

endmodule