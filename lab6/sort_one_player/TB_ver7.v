`timescale 1ns/1ps

module tb_sort_one_player;

    reg [3:0] in_num_1, in_num_2, in_num_3, in_num_4, in_num_5, in_num_6, in_num_7;
    reg [1:0] in_suit_1, in_suit_2, in_suit_3, in_suit_4, in_suit_5, in_suit_6, in_suit_7;

    wire [3:0] out_num_1, out_num_2, out_num_3, out_num_4, out_num_5;
    wire [3:0] chosen_type;

    // Instantiate DUT
    sort_one_player dut (
        .in_num_1(in_num_1), .in_num_2(in_num_2), .in_num_3(in_num_3), .in_num_4(in_num_4),
        .in_num_5(in_num_5), .in_num_6(in_num_6), .in_num_7(in_num_7),
        .in_suit_1(in_suit_1), .in_suit_2(in_suit_2), .in_suit_3(in_suit_3), .in_suit_4(in_suit_4),
        .in_suit_5(in_suit_5), .in_suit_6(in_suit_6), .in_suit_7(in_suit_7),
        .out_num_1(out_num_1), .out_num_2(out_num_2), .out_num_3(out_num_3), .out_num_4(out_num_4),
        .out_num_5(out_num_5),
        .chosen_type(chosen_type)
    );

    initial begin
        $display("Time\tin_num\t\t|\tout_num\tchosen_type");

        // -------- Test Case 1 -------- straight
        in_num_1=4'd10; in_suit_1=2'd0;
        in_num_2=4'd11; in_suit_2=2'd1;
        in_num_3=4'd12; in_suit_3=2'd2;
        in_num_4=4'd13; in_suit_4=2'd3;
        in_num_5=4'd14; in_suit_5=2'd0;
        in_num_6=4'd4;  in_suit_6=2'd1;
        in_num_7=4'd8;  in_suit_7=2'd2;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 2 -------- four of a kind
        in_num_1=4'd5; in_suit_1=2'd0;
        in_num_2=4'd2; in_suit_2=2'd1;
        in_num_3=4'd2; in_suit_3=2'd2;
        in_num_4=4'd7; in_suit_4=2'd3;
        in_num_5=4'd2; in_suit_5=2'd0;
        in_num_6=4'd2; in_suit_6=2'd3;
        in_num_7=4'd14; in_suit_7=2'd2;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 3 -------- three of a kind
        in_num_1=4'd10; in_suit_1=2'd0;
        in_num_2=4'd7; in_suit_2=2'd1;
        in_num_3=4'd7; in_suit_3=2'd2;
        in_num_4=4'd13; in_suit_4=2'd0;
        in_num_5=4'd10; in_suit_5=2'd1;
        in_num_6=4'd5;  in_suit_6=2'd2;
        in_num_7=4'd7;  in_suit_7=2'd3;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 4 -------- two pair
        in_num_1=4'd13; in_suit_1=2'd0;
        in_num_2=4'd13; in_suit_2=2'd1;
        in_num_3=4'd1;  in_suit_3=2'd2;
        in_num_4=4'd9;  in_suit_4=2'd3;
        in_num_5=4'd3;  in_suit_5=2'd0;
        in_num_6=4'd1;  in_suit_6=2'd1;
        in_num_7=4'd3;  in_suit_7=2'd2;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 5 -------- random
        in_num_1=4'd8;  in_suit_1=2'd3;
        in_num_2=4'd12; in_suit_2=2'd1;
        in_num_3=4'd9;  in_suit_3=2'd0;
        in_num_4=4'd8;  in_suit_4=2'd2;
        in_num_5=4'd14; in_suit_5=2'd3;
        in_num_6=4'd6;  in_suit_6=2'd1;
        in_num_7=4'd4;  in_suit_7=2'd0;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 6 -------- straight
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd3;  in_suit_2=2'd0;
        in_num_3=4'd2;  in_suit_3=2'd2;
        in_num_4=4'd5;  in_suit_4=2'd3;
        in_num_5=4'd4;  in_suit_5=2'd1;
        in_num_6=4'd12; in_suit_6=2'd2;
        in_num_7=4'd14; in_suit_7=2'd0;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 7 -------- royal flush
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd12; in_suit_2=2'd1;
        in_num_3=4'd10; in_suit_3=2'd1;
        in_num_4=4'd5;  in_suit_4=2'd3;
        in_num_5=4'd11; in_suit_5=2'd1;
        in_num_6=4'd13; in_suit_6=2'd1;
        in_num_7=4'd14; in_suit_7=2'd0;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 8 -------- straight flush
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd5;  in_suit_2=2'd1;
        in_num_3=4'd6;  in_suit_3=2'd1;
        in_num_4=4'd5;  in_suit_4=2'd3;
        in_num_5=4'd9;  in_suit_5=2'd1;
        in_num_6=4'd7;  in_suit_6=2'd1;
        in_num_7=4'd8;  in_suit_7=2'd1;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 9 -------- full house
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd5;  in_suit_2=2'd2;
        in_num_3=4'd5;  in_suit_3=2'd1;
        in_num_4=4'd5;  in_suit_4=2'd3;
        in_num_5=4'd9;  in_suit_5=2'd3;
        in_num_6=4'd9;  in_suit_6=2'd0;
        in_num_7=4'd2;  in_suit_7=2'd1;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 10 -------- flush
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd5;  in_suit_2=2'd2;
        in_num_3=4'd5;  in_suit_3=2'd1;
        in_num_4=4'd6;  in_suit_4=2'd1;
        in_num_5=4'd9;  in_suit_5=2'd1;
        in_num_6=4'd9;  in_suit_6=2'd0;
        in_num_7=4'd2;  in_suit_7=2'd1;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        // -------- Test Case 11 -------- high card
        in_num_1=4'd14; in_suit_1=2'd1;
        in_num_2=4'd5;  in_suit_2=2'd2;
        in_num_3=4'd5;  in_suit_3=2'd1;
        in_num_4=4'd6;  in_suit_4=2'd3;
        in_num_5=4'd9;  in_suit_5=2'd1;
        in_num_6=4'd9;  in_suit_6=2'd0;
        in_num_7=4'd2;  in_suit_7=2'd1;
        #10; $display("%t\t%0d %0d %0d %0d %0d %0d %0d\t|\t%0d %0d %0d %0d %0d\t%0d",
            $time,in_num_1,in_num_2,in_num_3,in_num_4,in_num_5,in_num_6,in_num_7,
            out_num_1,out_num_2,out_num_3,out_num_4,out_num_5,chosen_type);

        $finish;
    end

endmodule