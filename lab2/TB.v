`timescale 1ns/1ps

module tb_SUDOKU;

    // DUT ports
    reg clk;
    reg rst_n;
    reg in_valid;
    reg [3:0] in;
    wire out_valid;
    wire [3:0] out;
    integer k;
    // instantiate DUT
    SUDOKU dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in(in),
        .out_valid(out_valid),
        .out(out)
    );

    // clock: 10ns period
    initial begin
        clk = 0;
    end
    always #2 clk = ~clk;

    // sequence memory (81 values)
    reg [3:0] seq [0:80];

    initial begin
        // initialize sequence (the 81 values you gave)
        seq[0] = 4'd0;
        seq[1] = 4'd0;
        seq[2] = 4'd0;
        seq[3] = 4'd0;
        seq[4] = 4'd0;
        seq[5] = 4'd0;
        seq[6] = 4'd0;
        seq[7] = 4'd0;
        seq[8] = 4'd4;
        seq[9] = 4'd0;
        seq[10] = 4'd0;
        seq[11] = 4'd0;
        seq[12] = 4'd0;
        seq[13] = 4'd4;
        seq[14] = 4'd0;
        seq[15] = 4'd6;
        seq[16] = 4'd8;
        seq[17] = 4'd0;
        seq[18] = 4'd0;
        seq[19] = 4'd0;
        seq[20] = 4'd0;
        seq[21] = 4'd1;
        seq[22] = 4'd0;
        seq[23] = 4'd3;
        seq[24] = 4'd0;
        seq[25] = 4'd0;
        seq[26] = 4'd0;
        seq[27] = 4'd0;
        seq[28] = 4'd0;
        seq[29] = 4'd0;
        seq[30] = 4'd7;
        seq[31] = 4'd0;
        seq[32] = 4'd0;
        seq[33] = 4'd3;
        seq[34] = 4'd0;
        seq[35] = 4'd0;
        seq[36] = 4'd6;
        seq[37] = 4'd3;
        seq[38] = 4'd0;
        seq[39] = 4'd5;
        seq[40] = 4'd0;
        seq[41] = 4'd2;
        seq[42] = 4'd0;
        seq[43] = 4'd4;
        seq[44] = 4'd8;
        seq[45] = 4'd5;
        seq[46] = 4'd0;
        seq[47] = 4'd1;
        seq[48] = 4'd0;
        seq[49] = 4'd0;
        seq[50] = 4'd0;
        seq[51] = 4'd0;
        seq[52] = 4'd0;
        seq[53] = 4'd0;
        seq[54] = 4'd0;
        seq[55] = 4'd0;
        seq[56] = 4'd0;
        seq[57] = 4'd0;
        seq[58] = 4'd0;
        seq[59] = 4'd0;
        seq[60] = 4'd0;
        seq[61] = 4'd2;
        seq[62] = 4'd1;
        seq[63] = 4'd7;
        seq[64] = 4'd0;
        seq[65] = 4'd0;
        seq[66] = 4'd0;
        seq[67] = 4'd0;
        seq[68] = 4'd0;
        seq[69] = 4'd0;
        seq[70] = 4'd0;
        seq[71] = 4'd0;
        seq[72] = 4'd4;
        seq[73] = 4'd0;
        seq[74] = 4'd0;
        seq[75] = 4'd2;
        seq[76] = 4'd3;
        seq[77] = 4'd1;
        seq[78] = 4'd8;
        seq[79] = 4'd0;
        seq[80] = 4'd5;
    end

    //main stimulus
    initial begin
       clk = 0; rst_n = 1; in_valid = 0; in = 0;

        // Reset
        @(negedge clk);
        @(negedge clk);
        rst_n = 0;

        // Wait for negedge of clk after reset
        @(negedge clk);
        rst_n = 1;

        // wait for next negative edge of clk after reset release
        @(negedge clk);

        // now send 81 inputs consecutively with in_valid = 1
        for (k = 0; k < 81; k = k + 1) begin
            // drive inputs stable before posedge
            in_valid = 1'b1;
            in = seq[k];

            // wait one clock where the DUT samples on posedge
            @(negedge clk);
        end

        // finish input burst
        in_valid = 1'b0;
        in = 4'd0;
              
    end

    // optional: monitor outputs (printed when out_valid asserted)
    initial begin
        forever begin
            @(posedge clk);
            if (out_valid) begin
                $display("[%0t] DUT out_valid=1 out=%0d", $time, out);
            end
        end
    end

endmodule
