`timescale 1ns / 1ps

module allocate_pkt_tb;

    // Testbench signals
    reg [1:0] prefer_chl;
    reg req_valid;
    reg [1:0] cur_pivot;
    reg [2:0] chl_0_cap;
    reg [2:0] chl_1_cap;
    reg [2:0] chl_2_cap; 

    wire [2:0] chl_0_cap_out;
    wire [2:0] chl_1_cap_out;
    wire [2:0] chl_2_cap_out;
    wire [1:0] next_pivot;
    wire [1:0] target_chl;

    // Instantiate the Unit Under Test (DUT)
    allocate_pkt uut (
        .prefer_chl(prefer_chl),
        .req_valid(req_valid),
        .cur_pivot(cur_pivot),
        .chl_0_cap(chl_0_cap),
        .chl_1_cap(chl_1_cap),
        .chl_2_cap(chl_2_cap),
        .chl_0_cap_out(chl_0_cap_out),
        .chl_1_cap_out(chl_1_cap_out),
        .chl_2_cap_out(chl_2_cap_out),
        .next_pivot(next_pivot),
        .target_chl(target_chl)
    );

    // Initial block for stimulus generation
    initial begin
        $dumpfile("allocate_pkt.vcd");
        $dumpvars(0, allocate_pkt_tb);

        $display("------------------------------------------------------------------------------------------------------------------------------------");
        $display("Time | Valid | Prefer Chl | Cur Pivot | Chl 0 Cap | Chl 1 Cap | Chl 2 Cap | Target Chl | Next Pivot | Chl 0 Out | Chl 1 Out | Chl 2 Out");
        $display("------------------------------------------------------------------------------------------------------------------------------------");
        $monitor("%4t  | %b     | %2d         | %2d        | %2d        | %2d        | %2d        | %2d         | %2d         | %2d        | %2d        | %2d", 
                 $time, req_valid, prefer_chl, cur_pivot, chl_0_cap, chl_1_cap, chl_2_cap, target_chl, next_pivot, chl_0_cap_out, chl_1_cap_out, chl_2_cap_out);

        // --- Test Case 0: No allocation (req_valid = 0)
        // Expected: target_chl=3, next_pivot=cur_pivot, no change in capacity.
        #10;
        req_valid = 1'b0;
        prefer_chl = 2'd0;
        cur_pivot = 2'd0;
        chl_0_cap = 3'd7;
        chl_1_cap = 3'd5;
        chl_2_cap = 3'd3;
        
        // --- Test Case 1: Direct allocation (case 1)
        // Expected: target_chl=prefer_chl, next_pivot=cur_pivot, preferred channel capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd1;
        cur_pivot = 2'd0;
        chl_0_cap = 3'd7;
        chl_1_cap = 3'd5;
        chl_2_cap = 3'd3;
        
        // --- Test Case 2-0: Fallback to pivot_0 (cur_pivot != 3'd3)
        // Expected: target_chl=pivot_0, next_pivot=pivot_0+1, pivot_0 channel capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; // Preferred channel is empty
        cur_pivot = 2'd2; // Fallback from pivot 2 -> pivot 0
        chl_0_cap = 3'd7;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd0;

        // --- Test Case 2-1: Fallback to pivot_1 (cur_pivot != 3'd3)
        // Expected: target_chl=pivot_1, next_pivot=pivot_1, pivot_1 channel capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; // Preferred channel is empty
        cur_pivot = 2'd2; // Fallback from pivot 2 -> pivot 0 (empty) -> pivot 1
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd5;
        chl_2_cap = 3'd0;

        // --- Test Case 2-2: Fallback to pivot_2 (cur_pivot != 3'd3)
        // Expected: target_chl=pivot_2, next_pivot=(pivot_0+2)%3, pivot_2 channel capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; // Preferred channel is empty
        cur_pivot = 2'd2; // Fallback from pivot 2 (empty) -> pivot 0 (empty) -> pivot 1
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd3;
        
        // --- Test Case 2-3: Fallback unsuccessful (cur_pivot != 3'd3)
        // Expected: target_chl=3, next_pivot=(pivot_0+2)%3, no change in capacity.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0;
        cur_pivot = 2'd2;
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd0;

        // --- Test Case 2-0: First fallback (cur_pivot = 3'd3)
        // Expected: target_chl=prefer_chl, next_pivot=(prefer_chl+1)%3, prefer_chl channel capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; 
        cur_pivot = 2'd3; 
        chl_0_cap = 3'd7;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd0;

        // --- Test Case 2-1: First fallback (cur_pivot = 3'd3), prefer_chl is empty
        // Expected: target_chl=(prefer_chl+1)%3, next_pivot=(prefer_chl+1)%3, target_chl capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; 
        cur_pivot = 2'd3; 
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd5;
        chl_2_cap = 3'd0;

        // --- Test Case 2-2: First fallback (cur_pivot = 3'd3), prefer_chl & prefer+1 empty
        // Expected: target_chl=(prefer_chl+2)%3, next_pivot=(prefer_chl+2)%3, target_chl capacity -1.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0; 
        cur_pivot = 2'd3; 
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd3;

        // --- Test Case 2-3: First fallback unsuccessful (cur_pivot = 3'd3)
        // Expected: target_chl=3, next_pivot=(prefer_chl+2)%3, no change in capacity.
        #10;
        req_valid = 1'b1;
        prefer_chl = 2'd0;
        cur_pivot = 2'd3;
        chl_0_cap = 3'd0;
        chl_1_cap = 3'd0;
        chl_2_cap = 3'd0;

        #10;
        $finish;
    end
endmodule