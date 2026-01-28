`define CYCLE_TIME      17.0

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


    output reg         clk, rst_n, in_valid;
    output reg [31:0]  Image;
    output reg [31:0]  Kernel_ch1;
    output reg [31:0]  Kernel_ch2;
    output reg [31:0]  Weight_Bias;
    output reg         task_number;
    output reg [1:0]   mode;
    output reg [3:0]   capacity_cost;

    input           out_valid;
    input   [31:0]  out;

    real CYCLE = `CYCLE_TIME;
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;

    // Clock generation
    initial begin
        clk = 0;
        forever #0.5 clk = ~clk; // 100MHz clock
    end

    integer i;

    initial begin
        // Initialize
        rst_n = 1;
        in_valid = 0;
        Image = 0;
        Kernel_ch1 = 0;
        Kernel_ch2 = 0;
        Weight_Bias = 0;
        task_number = 0;
        mode = 2'b00;
        capacity_cost = 4'd0;

        // Reset
        @(negedge clk);
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        // Start feeding
        @(negedge clk);
        in_valid = 1;

        // Image: 72 cycles
        for (i = 0; i < 72; i = i+1) begin
            Image = 32'h3f800000 + i; // 假設 float 1.0 + i
            if (i < 18) begin
                Kernel_ch1 = 32'h40000000 + i; // float 2.0 + i
                Kernel_ch2 = 32'h40400000 + i; // float 3.0 + i
            end else begin
                Kernel_ch1 = 0;
                Kernel_ch2 = 0;
            end
            if (i < 57) begin
                Weight_Bias = 32'h40800000 + i; // float 4.0 + i
            end else begin
                Weight_Bias = 0;
            end
            @(negedge clk);
        end

        // Stop input
        in_valid = 0;
        Image = 0;
        Kernel_ch1 = 0;
        Kernel_ch2 = 0;
        Weight_Bias = 0;
        
        #200
        $finish;
    end

endmodule