/**************************************************************************/
// Copyright (c) 2025, SI2 Lab
// MODULE: PATTERN_IP
// FILE NAME: PATTERN_IP.v
// VERSRION: 1.0
// DATE: OCT 15, 2025
// AUTHOR: Auto-generated Pattern
// CODE TYPE: RTL or Behavioral Level (Verilog)
/**************************************************************************/

`timescale 1ns/1ps

module PATTERN #(
    parameter IP_WIDTH = 9
)(
    output reg [IP_WIDTH*8-1:0]  IN_HOLE_CARD_NUM,
    output reg [IP_WIDTH*4-1:0]  IN_HOLE_CARD_SUIT,
    output reg [19:0]  IN_PUB_CARD_NUM,
    output reg [9:0]  IN_PUB_CARD_SUIT,
    input wire [IP_WIDTH-1:0]  OUT_WINNER
);

//================================================================
// Integer & Parameter
//================================================================
integer PATTERN_NUM;
integer pat_count;
integer total_cycles;
integer error_count;
integer i, j;
integer input_file, golden_file;
integer scan_result;

// Test data storage
reg [IP_WIDTH*8-1:0]  test_hole_num [0:9999];
reg [IP_WIDTH*4-1:0]  test_hole_suit [0:9999];
reg [19:0]  test_pub_num [0:9999];
reg [9:0]  test_pub_suit [0:9999];
reg [IP_WIDTH-1:0]  test_winner [0:9999];

// Golden answer
reg [IP_WIDTH-1:0] golden_winner;

//================================================================
// Initial
//================================================================
initial begin
    // Initialize signals
    IN_HOLE_CARD_NUM = 0;
    IN_HOLE_CARD_SUIT = 0;
    IN_PUB_CARD_NUM = 0;
    IN_PUB_CARD_SUIT = 0;
    
    error_count = 0;
    total_cycles = 0;
    
    // Load test data
    load_test_data;
    
    // Start testing
    display_header;
    
    // Test loop
    for (pat_count = 0; pat_count < PATTERN_NUM; pat_count = pat_count + 1) begin
        input_data;
        wait_for_stable;
        check_answer;
        total_cycles = total_cycles + 1;
    end
    
    // Display results
    display_results;
    $finish;
end

//================================================================
// Task: Load Test Data
//================================================================
task load_test_data;
    integer idx;
    reg [IP_WIDTH*8-1:0] temp_hole_num;
    reg [IP_WIDTH*4-1:0] temp_hole_suit;
    reg [19:0] temp_pub_num;
    reg [9:0] temp_pub_suit;
    reg [IP_WIDTH-1:0] temp_winner;
begin
    // Open input file
    input_file = $fopen("../00_TESTBED/input.txt", "r");
    if (input_file == 0) begin
        $display("============================================================");
        $display("  ERROR: Cannot open ./00_TESTBED/input.txt file!");
        $display("  Please run: python poker_testgen.py");
        $display("  And place files in ./00_TESTBED/ folder");
        $display("============================================================");
        $finish;
    end
    
    // Open golden file
    golden_file = $fopen("../00_TESTBED/golden.txt", "r");
    if (golden_file == 0) begin
        $display("============================================================");
        $display("  ERROR: Cannot open ./00_TESTBED/golden.txt file!");
        $display("  Please run: python poker_testgen.py");
        $display("  And place files in ./00_TESTBED/ folder");
        $display("============================================================");
        $fclose(input_file);
        $finish;
    end
    
    // Read all test patterns
    idx = 0;
    while (!$feof(input_file) && !$feof(golden_file) && idx < 10000) begin
        scan_result = $fscanf(input_file, "%b %b %b %b\n", 
            temp_hole_num, temp_hole_suit, temp_pub_num, temp_pub_suit);
        
        scan_result = $fscanf(golden_file, "%b\n", temp_winner);
        
        if (scan_result > 0) begin
            test_hole_num[idx] = temp_hole_num;
            test_hole_suit[idx] = temp_hole_suit;
            test_pub_num[idx] = temp_pub_num;
            test_pub_suit[idx] = temp_pub_suit;
            test_winner[idx] = temp_winner;
            idx = idx + 1;
        end
    end
    
    PATTERN_NUM = idx;
    
    if (PATTERN_NUM == 0) begin
        $display("============================================================");
        $display("  ERROR: No test patterns loaded!");
        $display("  Please check ./00_TESTBED/input.txt and golden.txt format.");
        $display("============================================================");
        $finish;
    end
    
    $fclose(input_file);
    $fclose(golden_file);
end
endtask

//================================================================
// Task: Display Header
//================================================================
task display_header; begin
    $display("============================================================");
    $display("  Poker IP Verification");
    $display("  Total Patterns: %0d", PATTERN_NUM);
    $display("  Number of Players: %0d", IP_WIDTH);
    $display("============================================================");
end
endtask

//================================================================
// Task: Input Data
//================================================================
task input_data; begin
    IN_HOLE_CARD_NUM = test_hole_num[pat_count];
    IN_HOLE_CARD_SUIT = test_hole_suit[pat_count];
    IN_PUB_CARD_NUM = test_pub_num[pat_count];
    IN_PUB_CARD_SUIT = test_pub_suit[pat_count];
    golden_winner = test_winner[pat_count];
end
endtask

//================================================================
// Task: Wait for Stable
//================================================================
task wait_for_stable; begin
    #10; // Wait for combinational logic to settle
end
endtask

//================================================================
// Task: Check Answer
//================================================================
task check_answer; begin
    if (OUT_WINNER !== golden_winner) begin
        display_fail;
        error_count = error_count + 1;
    end else begin
        $display("PATTERN No.%4d PASS", pat_count);
    end
end
endtask

//================================================================
// Task: Display Fail
//================================================================
task display_fail; begin
    $display("============================================================");
    $display("  PATTERN No.%4d FAIL", pat_count);
    $display("============================================================");
    $display("  Expected OUT_WINNER: %b", golden_winner);
    $display("  Your     OUT_WINNER: %b", OUT_WINNER);
    $display("------------------------------------------------------------");
    display_cards;
    $display("============================================================");
end
endtask

//================================================================
// Task: Display Cards
//================================================================
task display_cards;
    integer p;
    reg [3:0] card_num;
    reg [1:0] card_suit;
begin
    $display("  Public Cards:");
    for (i = 0; i < 5; i = i + 1) begin
        card_num = test_pub_num[pat_count][i*4 +: 4];
        card_suit = test_pub_suit[pat_count][i*2 +: 2];
        $display("    Card %0d: %s of %s", 
            i+1, 
            get_card_name(card_num),
            get_suit_name(card_suit));
    end
    
    $display("  Players' Hole Cards:");
    for (p = 0; p < IP_WIDTH; p = p + 1) begin
        $write("    Player %0d: ", p);
        // Card 1
        card_num = test_hole_num[pat_count][p*8 +: 4];
        card_suit = test_hole_suit[pat_count][p*4 +: 2];
        $write("%s of %s, ", get_card_name(card_num), get_suit_name(card_suit));
        // Card 2
        card_num = test_hole_num[pat_count][p*8+4 +: 4];
        card_suit = test_hole_suit[pat_count][p*4+2 +: 2];
        $write("%s of %s", get_card_name(card_num), get_suit_name(card_suit));
        
        // Mark winner
        if (golden_winner[p])
            $display(" <- WINNER");
        else
            $display("");
    end
end
endtask

//================================================================
// Task: Display Results
//================================================================
task display_results; begin
    $display("============================================================");
    $display("  Test Completed!");
    $display("============================================================");
    $display("  Total Patterns:  %4d", PATTERN_NUM);
    $display("  Passed Patterns: %4d", PATTERN_NUM - error_count);
    $display("  Failed Patterns: %4d", error_count);
    $display("------------------------------------------------------------");
    if (error_count == 0) begin
        $display("  Congratulations! All patterns PASS!");
        $display("  Total execution cycles: %0d", total_cycles);
    end else begin
        $display("  Test FAILED! Please check your design.");
    end
    $display("============================================================");
end
endtask

//================================================================
// Function: Get Card Name
//================================================================
function [63:0] get_card_name;
    input [3:0] num;
begin
    case(num)
        4'd2:  get_card_name = "2";
        4'd3:  get_card_name = "3";
        4'd4:  get_card_name = "4";
        4'd5:  get_card_name = "5";
        4'd6:  get_card_name = "6";
        4'd7:  get_card_name = "7";
        4'd8:  get_card_name = "8";
        4'd9:  get_card_name = "9";
        4'd10: get_card_name = "10";
        4'd11: get_card_name = "J";
        4'd12: get_card_name = "Q";
        4'd13: get_card_name = "K";
        4'd14: get_card_name = "A";
        default: get_card_name = "?";
    endcase
end
endfunction

//================================================================
// Function: Get Suit Name
//================================================================
function [63:0] get_suit_name;
    input [1:0] suit;
begin
    case(suit)
        2'b00: get_suit_name = "Clubs";
        2'b01: get_suit_name = "Diamonds";
        2'b10: get_suit_name = "Hearts";
        2'b11: get_suit_name = "Spades";
        default: get_suit_name = "Unknown";
    endcase
end
endfunction

endmodule