`timescale 1ns / 1ps

module Poker_tb;

    // Parameter
    parameter IP_WIDTH = 9;

    // Inputs
    reg [IP_WIDTH*8-1:0] IN_HOLE_CARD_NUM;
    reg [IP_WIDTH*4-1:0] IN_HOLE_CARD_SUIT;
    reg [19:0] IN_PUB_CARD_NUM;
    reg [9:0] IN_PUB_CARD_SUIT;

    // Outputs
    wire [IP_WIDTH-1:0] OUT_WINNER;

    // Instantiate the Unit Under Test (UUT)
    Poker #(.IP_WIDTH(IP_WIDTH)) uut (
        .IN_HOLE_CARD_NUM(IN_HOLE_CARD_NUM),
        .IN_HOLE_CARD_SUIT(IN_HOLE_CARD_SUIT),
        .IN_PUB_CARD_NUM(IN_PUB_CARD_NUM),
        .IN_PUB_CARD_SUIT(IN_PUB_CARD_SUIT),
        .OUT_WINNER(OUT_WINNER)
    );

    // Test procedure
    initial begin
        // Initialize inputs
        IN_HOLE_CARD_NUM = 0;
        IN_HOLE_CARD_SUIT = 0;
        IN_PUB_CARD_NUM = 0;
        IN_PUB_CARD_SUIT = 0;

        // Wait some time
        #10;

        // --------- Test Case 1 ---------
        // 玩家1: 2♠ 3♣, 玩家2: K♦ A♥
        IN_HOLE_CARD_NUM = 72'h8c_b986_26be_e879_4962; 
        IN_HOLE_CARD_SUIT = 36'h8_fc2a_d067;   
        IN_PUB_CARD_NUM  = {4'ha, 4'h5, 4'hD, 4'h3, 4'h2}; 
        IN_PUB_CARD_SUIT = {2'd0, 2'd1, 2'd0, 2'd1, 2'd1};  
        #10;
        $display("Test 1 Winner: %d", OUT_WINNER);
        #10;
        $finish;
    end

endmodule