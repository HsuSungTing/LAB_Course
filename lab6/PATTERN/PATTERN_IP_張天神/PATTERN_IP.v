module PATTERN #(parameter IP_WIDTH = 9)(
    // Output signals (to DUT)
    IN_HOLE_CARD_NUM, 
    IN_HOLE_CARD_SUIT, 
    IN_PUB_CARD_NUM, 
    IN_PUB_CARD_SUIT,
    // Input signals (from DUT)
    OUT_WINNER
);

// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*8-1:0]  IN_HOLE_CARD_NUM;
output reg [IP_WIDTH*4-1:0]  IN_HOLE_CARD_SUIT;
output reg [19:0]  IN_PUB_CARD_NUM;
output reg [9:0]   IN_PUB_CARD_SUIT;

input [IP_WIDTH-1:0]  OUT_WINNER;

// ========================================
// Parameter & Integer
// ========================================
integer input_file, output_file;
integer pattern_num;
integer pat;
integer i;
integer error_count;

reg [IP_WIDTH*8-1:0]  golden_hole_num;
reg [IP_WIDTH*4-1:0]  golden_hole_suit;
reg [19:0]  golden_pub_num;
reg [9:0]   golden_pub_suit;
reg [IP_WIDTH-1:0]  golden_winner;

integer scan_result;
reg [200*8:1] input_filename;   // 字串緩衝區
reg [200*8:1] output_filename;  // 字串緩衝區

// ========================================
// Clock (for timing reference)
// ========================================
integer CYCLE_TIME = 20;
reg clk;
initial clk = 0;
always #(CYCLE_TIME/2.0) clk = ~clk;

// ========================================
// Initial
// ========================================
initial begin
    // Format filenames with IP_WIDTH
    $sformat(input_filename, "../00_TESTBED/input_%0d.txt", IP_WIDTH);
    $sformat(output_filename, "../00_TESTBED/output_%0d.txt", IP_WIDTH);
    
    // Open files
    input_file = $fopen(input_filename, "r");
    output_file = $fopen(output_filename, "r");
    
    if (input_file == 0) begin
        $display("========================================");
        $display("  Error: Cannot open %s", input_filename);
        $display("========================================");
        $finish;
    end
    
    if (output_file == 0) begin
        $display("========================================");
        $display("  Error: Cannot open %s", output_filename);
        $display("========================================");
        $finish;
    end
    
    // Initialize
    IN_HOLE_CARD_NUM = 0;
    IN_HOLE_CARD_SUIT = 0;
    IN_PUB_CARD_NUM = 0;
    IN_PUB_CARD_SUIT = 0;
    error_count = 0;
    pattern_num = 0;
    
    // Read pattern count from first line
    scan_result = $fscanf(input_file, "%d\n", pattern_num);
    $fclose(input_file);
    
    // Reopen files
    input_file = $fopen(input_filename, "r");
    output_file = $fopen(output_filename, "r");
    
    // Skip first line (pattern count) in both files
    scan_result = $fscanf(input_file, "%d\n", i);
    scan_result = $fscanf(output_file, "%d\n", i);
    
    $display("========================================");
    $display("  Simulation Start");
    $display("  Total Patterns: %0d", pattern_num);
    $display("========================================");
    
    // Run all patterns
    for (pat = 0; pat < pattern_num; pat = pat + 1) begin
        read_pattern(pat);
        send_input;
        @(negedge clk);
        check_output(pat);
    end
    
    // Close files
    $fclose(input_file);
    $fclose(output_file);
    
    // Display result
    $display("========================================");
    if (error_count == 0) begin
        $display("  Congratulations!");
        $display("  All patterns passed!");
    end else begin
        $display("  FAIL!");
        $display("  Total errors: %0d", error_count);
    end
    $display("========================================");
    $finish;
end

// ========================================
// Task: Read Pattern
// ========================================
task read_pattern;
    input integer pat_id;
    reg [IP_WIDTH*8-1:0] hole_num_temp;
    reg [IP_WIDTH*4-1:0] hole_suit_temp;
    reg [19:0] pub_num_temp;
    reg [9:0] pub_suit_temp;
    reg [IP_WIDTH-1:0] winner_temp;
    integer pattern_id;
    
    begin
        // Read from input.txt
        // Pattern ID
        scan_result = $fscanf(input_file, "%d\n", pattern_id);
        
        // IN_HOLE_CARD_NUM
        scan_result = $fscanf(input_file, "%h\n", hole_num_temp);
        golden_hole_num = hole_num_temp;
        
        // IN_HOLE_CARD_SUIT
        scan_result = $fscanf(input_file, "%h\n", hole_suit_temp);
        golden_hole_suit = hole_suit_temp;
        
        // IN_PUB_CARD_NUM
        scan_result = $fscanf(input_file, "%h\n", pub_num_temp);
        golden_pub_num = pub_num_temp;
        
        // IN_PUB_CARD_SUIT
        scan_result = $fscanf(input_file, "%h\n", pub_suit_temp);
        golden_pub_suit = pub_suit_temp;
        
        // Read from output.txt
        // Pattern ID
        scan_result = $fscanf(output_file, "%d\n", pattern_id);
        
        // OUT_WINNER
        scan_result = $fscanf(output_file, "%b\n", winner_temp);
        golden_winner = winner_temp;
    end
endtask

// ========================================
// Task: Send Input
// ========================================
task send_input;
    begin
        @(negedge clk);
        IN_HOLE_CARD_NUM = golden_hole_num;
        IN_HOLE_CARD_SUIT = golden_hole_suit;
        IN_PUB_CARD_NUM = golden_pub_num;
        IN_PUB_CARD_SUIT = golden_pub_suit;
        @(negedge clk);
    end
endtask

// ========================================
// Task: Check Output
// ========================================
task check_output;
    input integer pat_id;
    begin
        if (OUT_WINNER !== golden_winner) begin
            $display("========================================");
            $display("  Pattern %0d FAILED!", pat_id);
            $display("  Golden: %b", golden_winner);
            $display("  Your  : %b", OUT_WINNER);
            $display("========================================");
            error_count = error_count + 1;
        end else begin
            $display("Pattern %0d PASS  | Golden: %b  | Your  : %b", pat_id, golden_winner, OUT_WINNER);
        end
    end
endtask

endmodule