`timescale 1ns / 1ps
module mpca_tb;

    // Testbench inputs
    reg [127:0] packets;
    reg [11:0] channel_load;
    reg [8:0] channel_capacity;
    reg [63:0] KEY;

    // Testbench outputs
    wire [15:0] grant_channel;

    // Instantiate the Unit Under Test (DUT)
    MPCA uut (
        .packets(packets),
        .channel_load(channel_load),
        .channel_capacity(channel_capacity),
        .KEY(KEY),
        .grant_channel(grant_channel)
    );

    // Initial block to apply stimulus and check results
    initial begin
        // --- 1. SET INPUT VALUES ---
        //IDEAL
        packets = 128'he040_5cd2_4527_5495_524a_3c2a_791a_9a33;
        KEY     = 64'he750_3a4f_51c0_bb1a;
        channel_load = {4'hd,4'd7,4'd2};
        channel_capacity = {3'd6,3'd4,3'd4};
        
        //UGLY
        #20
        packets = 128'h5649_5a15_8f3b_eee6_06fb_164a_56ac_c1e5;
        KEY     = 64'haeee_bd3c_30ab_f5ae;
        channel_load = {4'd8,4'd1,4'hd};
        channel_capacity = {3'd3,3'd0,3'd4};
        
        //PTN6
        #20
        packets =128'hf3ca_8775_7fa3_9297_fa0a_d73f_0304_beac;
        KEY=64'hf5ceda403a758c89;
        channel_load = {4'd4,4'd3,4'h1};
        channel_capacity = {3'd7,3'd4,3'd4};
        
        //6030
        #20
        packets = 128'h03F1_813A_A797_F9C8_EB83_C648_B32F_047C;
        KEY     = 64'hD032_4927_B44F_C6A3;
        channel_load = {4'hE,4'd0,4'hE};
        channel_capacity = {3'd6,3'd3,3'd4};
        
        //6031
        #20
        packets =128'h2BA8_8D7A_785A_C2D5_ABAF_B081_22C1_5FF3;
        KEY=64'h6E4F_0630_9AEB_DE62;
        channel_load = {4'hE,4'hF,4'hF};
        channel_capacity = {3'd5,3'd1,3'd6};
        
        //2
        #20
        packets =128'hdc92_87ce_15fa_f01a_3351_26c1_a77f_f300;
        KEY=64'hc6310617b4354bde;
        channel_load = {4'h5,4'h2,4'hb};
        channel_capacity = {3'd4,3'd4,3'd2};
        
        //Xiu
        #20
        packets =128'h61f8_f0bd_9ac8_b23a_6a7b_fbff_54ed_2dd6;
        KEY=64'h2780534630249883;
        channel_load = {4'hd,4'he,4'hd};
        channel_capacity = {3'd3,3'd2,3'd2};
        
        // Monitor key signals for debugging
        $monitor("Time=%0t: packets=%h, KEY=%h, K0=%h, K1=%h, K2=%h, K3=%h",
                 $time, packets, KEY, uut.K0, uut.K1, uut.K2, uut.K3);
        $monitor("Time=%0t: ori_pkts: [%h %h] [%h %h] [%h %h] [%h %h]",
                 $time, uut.ori_pkt[1], uut.ori_pkt[0], uut.ori_pkt[3], uut.ori_pkt[2],
                 uut.ori_pkt[5], uut.ori_pkt[4], uut.ori_pkt[7], uut.ori_pkt[6]);
        $monitor("Time=%0t: p_scores: [%d %d %d %d %d %d %d %d]",
                 $time, $signed(uut.p_score[0]), $signed(uut.p_score[1]), $signed(uut.p_score[2]), $signed(uut.p_score[3]),
                 $signed(uut.p_score[4]), $signed(uut.p_score[5]), $signed(uut.p_score[6]), $signed(uut.p_score[7]));
        $monitor("Time=%0t: Sorted p_scores: [%d %d %d %d %d %d %d %d]",
                 $time, $signed(uut.sorted_pkt[0]), $signed(uut.sorted_pkt[1]), $signed(uut.sorted_pkt[2]), $signed(uut.sorted_pkt[3]),
                 $signed(uut.sorted_pkt[4]), $signed(uut.sorted_pkt[5]), $signed(uut.sorted_pkt[6]), $signed(uut.sorted_pkt[7]));
        $monitor("Time=%0t: Sorted IDs: [%d %d %d %d %d %d %d %d]",
                 $time, uut.sorted_pkt_id[0], uut.sorted_pkt_id[1], uut.sorted_pkt_id[2], uut.sorted_pkt_id[3],
                 uut.sorted_pkt_id[4], uut.sorted_pkt_id[5], uut.sorted_pkt_id[6], uut.sorted_pkt_id[7]);

        // --- 2. VERIFYING THE LOGIC ---
        #10; // Wait for combinational logic to propagate

        $display("--- Verification Start ---");

        // Verify KEY values
        if (uut.K0 !== 16'hbb1a) $error("K0 mismatch! Expected bb1a, got %h", uut.K0);
        if (uut.K1 !== 16'h7f0d) $error("K1 mismatch! Expected 7f0d, got %h", uut.K1);
        if (uut.K2 !== 16'h12d9) $error("K2 mismatch! Expected 12d9, got %h", uut.K2);
        if (uut.K3 !== 16'h331b) $error("K3 mismatch! Expected 331b, got %h", uut.K3);

        // Verify decrypted packets (ori_pkt)
        if (uut.ori_pkt[0] !== 16'h0000) $error("ori_pkt[0] mismatch! Expected 0000, got %h", uut.ori_pkt[0]);
        if (uut.ori_pkt[1] !== 16'h0123) $error("ori_pkt[1] mismatch! Expected 0123, got %h", uut.ori_pkt[1]);
        if (uut.ori_pkt[2] !== 16'h0456) $error("ori_pkt[2] mismatch! Expected 0456, got %h", uut.ori_pkt[2]);
        if (uut.ori_pkt[3] !== 16'h0789) $error("ori_pkt[3] mismatch! Expected 0789, got %h", uut.ori_pkt[3]);
        if (uut.ori_pkt[4] !== 16'h0abc) $error("ori_pkt[4] mismatch! Expected 0abc, got %h", uut.ori_pkt[4]);
        if (uut.ori_pkt[5] !== 16'h0def) $error("ori_pkt[5] mismatch! Expected 0def, got %h", uut.ori_pkt[5]);
        if (uut.ori_pkt[6] !== 16'h1011) $error("ori_pkt[6] mismatch! Expected 1011, got %h", uut.ori_pkt[6]);
        if (uut.ori_pkt[7] !== 16'h1213) $error("ori_pkt[7] mismatch! Expected 1213, got %h", uut.ori_pkt[7]);

        // Verify Priority Scores
        // Manual calculation based on the formula: (qos-2)*4 + (pkt_len-8)*(-2) + (1-congestion)*3 + (src_hint-4)
        // ori_pkt[0] = 0000h (qos=0, len=0, cong=0, src=0) -> (0-2)*4 + (0-8)*-2 + (1-0)*3 + (0-4) = -8 + 16 + 3 - 4 = 7
        if ($signed(uut.p_score[0]) !== 7) $error("p_score[0] mismatch! Expected 7, got %d", $signed(uut.p_score[0]));
        // ori_pkt[1] = 0123h (qos=0, len=4, cong=2, src=0) -> (0-2)*4 + (4-8)*-2 + (1-2)*3 + (0-4) = -8 + 8 - 3 - 4 = -7
        if ($signed(uut.p_score[1]) !== -7) $error("p_score[1] mismatch! Expected -7, got %d", $signed(uut.p_score[1]));
        // ori_pkt[2] = 0456h (qos=1, len=0, cong=1, src=5) -> (1-2)*4 + (0-8)*-2 + (1-1)*3 + (5-4) = -4 + 16 + 0 + 1 = 13
        if ($signed(uut.p_score[2]) !== 13) $error("p_score[2] mismatch! Expected 13, got %d", $signed(uut.p_score[2]));
        // ori_pkt[3] = 0789h (qos=1, len=7, cong=2, src=4) -> (1-2)*4 + (7-8)*-2 + (1-2)*3 + (4-4) = -4 + 2 - 3 + 0 = -5
        if ($signed(uut.p_score[3]) !== -5) $error("p_score[3] mismatch! Expected -5, got %d", $signed(uut.p_score[3]));
        // ori_pkt[4] = 0abch (qos=2, len=1, cong=2, src=7) -> (2-2)*4 + (1-8)*-2 + (1-2)*3 + (7-4) = 0 + 14 - 3 + 3 = 14
        if ($signed(uut.p_score[4]) !== 14) $error("p_score[4] mismatch! Expected 14, got %d", $signed(uut.p_score[4]));
        // ori_pkt[5] = 0defh (qos=3, len=15, cong=3, src=7) -> (3-2)*4 + (15-8)*-2 + (1-3)*3 + (7-4) = 4 - 14 - 6 + 3 = -13
        if ($signed(uut.p_score[5]) !== -13) $error("p_score[5] mismatch! Expected -13, got %d", $signed(uut.p_score[5]));
        // ori_pkt[6] = 1011h (qos=0, len=0, cong=0, src=4) -> (0-2)*4 + (0-8)*-2 + (1-0)*3 + (4-4) = -8 + 16 + 3 + 0 = 11
        if ($signed(uut.p_score[6]) !== 11) $error("p_score[6] mismatch! Expected 11, got %d", $signed(uut.p_score[6]));
        // ori_pkt[7] = 1213h (qos=0, len=4, cong=0, src=4) -> (0-2)*4 + (4-8)*-2 + (1-0)*3 + (4-4) = -8 + 8 + 3 + 0 = 3
        if ($signed(uut.p_score[7]) !== 3) $error("p_score[7] mismatch! Expected 3, got %d", $signed(uut.p_score[7]));

        // Check sorted output (values & IDs)
        // Original scores: {7, -7, 13, -5, 14, -13, 11, 3}
        // Original IDs: {0, 1, 2, 3, 4, 5, 6, 7}
        // Sorted scores should be: {-13, -7, -5, 3, 7, 11, 13, 14}
        // Sorted IDs should be: {5, 1, 3, 7, 0, 6, 2, 4}
        if ($signed(uut.sorted_pkt[7]) !== -13) $error("Sorted score[7] mismatch! Expected -13, got %d", $signed(uut.sorted_pkt[7]));
        if ($signed(uut.sorted_pkt[6]) !== -7)  $error("Sorted score[6] mismatch! Expected -7, got %d", $signed(uut.sorted_pkt[6]));
        if ($signed(uut.sorted_pkt[5]) !== -5)  $error("Sorted score[5] mismatch! Expected -5, got %d", $signed(uut.sorted_pkt[5]));
        if ($signed(uut.sorted_pkt[4]) !== 3)   $error("Sorted score[4] mismatch! Expected 3, got %d", $signed(uut.sorted_pkt[4]));
        if ($signed(uut.sorted_pkt[3]) !== 7)   $error("Sorted score[3] mismatch! Expected 7, got %d", $signed(uut.sorted_pkt[3]));
        if ($signed(uut.sorted_pkt[2]) !== 11)  $error("Sorted score[2] mismatch! Expected 11, got %d", $signed(uut.sorted_pkt[2]));
        if ($signed(uut.sorted_pkt[1]) !== 13)  $error("Sorted score[1] mismatch! Expected 13, got %d", $signed(uut.sorted_pkt[1]));
        if ($signed(uut.sorted_pkt[0]) !== 14)  $error("Sorted score[0] mismatch! Expected 14, got %d", $signed(uut.sorted_pkt[0]));
        
        if (uut.sorted_pkt_id[7] !== 3'd5) $error("Sorted ID[7] mismatch! Expected 5, got %d", uut.sorted_pkt_id[7]);
        if (uut.sorted_pkt_id[6] !== 3'd1) $error("Sorted ID[6] mismatch! Expected 1, got %d", uut.sorted_pkt_id[6]);
        if (uut.sorted_pkt_id[5] !== 3'd3) $error("Sorted ID[5] mismatch! Expected 3, got %d", uut.sorted_pkt_id[5]);
        if (uut.sorted_pkt_id[4] !== 3'd7) $error("Sorted ID[4] mismatch! Expected 7, got %d", uut.sorted_pkt_id[4]);
        if (uut.sorted_pkt_id[3] !== 3'd0) $error("Sorted ID[3] mismatch! Expected 0, got %d", uut.sorted_pkt_id[3]);
        if (uut.sorted_pkt_id[2] !== 3'd6) $error("Sorted ID[2] mismatch! Expected 6, got %d", uut.sorted_pkt_id[2]);
        if (uut.sorted_pkt_id[1] !== 3'd2) $error("Sorted ID[1] mismatch! Expected 2, got %d", uut.sorted_pkt_id[1]);
        if (uut.sorted_pkt_id[0] !== 3'd4) $error("Sorted ID[0] mismatch! Expected 4, got %d", uut.sorted_pkt_id[0]);

        $display("--- Verification Finished. All checks passed if no errors reported. ---");

        #10;
        $finish;
    end

endmodule