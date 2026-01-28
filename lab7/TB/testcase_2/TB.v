`timescale 1ns/1ps

module CLK_2_MODULE_tb;

// === Ports ===
reg         clk;
reg         rst_n;
reg         in_valid;
reg  [31:0] in_data;
reg         fifo_full;

wire        out_valid;
wire [15:0] out_data;
wire        busy;

// === Flag wires ===
reg  flag_handshake_to_clk2;
wire flag_clk2_to_handshake;
reg  flag_fifo_to_clk2;
wire flag_clk2_to_fifo;

// === Instantiate DUT ===
CLK_2_MODULE uut (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_data(in_data),
    .fifo_full(fifo_full),
    .out_valid(out_valid),
    .out_data(out_data),
    .busy(busy),
    .flag_handshake_to_clk2(flag_handshake_to_clk2),
    .flag_clk2_to_handshake(flag_clk2_to_handshake),
    .flag_fifo_to_clk2(flag_fifo_to_clk2),
    .flag_clk2_to_fifo(flag_clk2_to_fifo)
);

// === Clock Generation ===
// 10ns period → 100 MHz
initial clk = 0;
always #0.5 clk = ~clk;

// === Stimulus ===
integer i;
integer SEED = 82; 
initial begin
    // 初始值
    rst_n = 1;
    in_valid = 0;
    in_data = 32'd0;
    fifo_full = 0;
    flag_handshake_to_clk2 = 0;
    flag_fifo_to_clk2 = 0;

    // === Step 1: Negative reset ===
    @(negedge clk);
    @(negedge clk);
    $display("[%0t] Starting negative reset...", $time);
    rst_n = 0;
    @(negedge clk);
    @(negedge clk);
    rst_n = 1;
    $display("[%0t] Reset released.", $time);

    // === Step 2: 等待一段??后送?料 ===
    @(negedge clk);

    // === Step 3: ??16?cycle送入 in_data + 拉高in_valid ===
    $display("[%0t] Start feeding 16 inputs", $time);
    in_valid = 1;
    for (i = 0; i < 16; i = i + 1) begin
        in_data[3:0]   = i*8 + 0 +3;
        in_data[7:4]   = i*8 + 1 +3;
        in_data[11:8]  = i*8 + 2 +3;
        in_data[15:12] = i*8 + 3 +3;
        in_data[19:16] = i*8 + 4 +3;
        in_data[23:20] = i*8 + 5 +3;
        in_data[27:24] = i*8 + 6 +3;
        in_data[31:28] = i*8 + 7 +3;
        @(negedge clk);
    end
    in_valid = 0;
    in_data = 32'd0;

    $display("[%0t] Finish feeding input, resting...", $time);

end

endmodule