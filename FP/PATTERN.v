`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif
`ifdef POST
    `define CYCLE_TIME 20.0
`endif

`define CYCLE_TIME 20.0

module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    out_valid,
    out_sad
);
output reg clk, rst_n, in_valid, in_valid2;
output reg [8:0] in_data;
input out_valid;
input out_sad;

parameter  PATNUM=10;

real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk; //clock

//Part 2 var
integer pat_count, exe_lat;
integer i,j;

//Part 4
task reset_task; begin
	// Initialize signals (Part 1)
    in_valid=0;
    in_valid2=0;
    in_data=0;
	rst_n = 1'b1;
	// Start reset
	force clk = 1'b0;
	#(CYCLE); rst_n = 1'b0;
	// Pass the reset check
	#(CYCLE); rst_n = 1'b1;
	#(CYCLE); release clk;
end
endtask

task input_task_1; begin
    for(i=0;i<32768;i=i+1)begin
        in_data=$urandom_range(0, 127);
        in_valid= 1'b1;
        @(negedge clk);
    end
    in_valid= 1'b0; in_data= 4'dx;
    @(negedge clk);
end
endtask

task input_task_2; begin
    @(negedge clk);
    for(i=0;i<8;i=i+1)begin
        in_data=$urandom_range(0, 127);
        in_valid2= 1'b1;
        @(negedge clk);
    end
    in_valid2= 1'b0; in_data= 4'dx;
    @(negedge clk);
end
endtask

//Part 5: main()
initial begin
    reset_task;
    input_task_1;
    for(pat_count=0; pat_count<PATNUM; pat_count=pat_count+1'd1)begin
		input_task_2;			    //讀這筆PTN的這個測資，讓in_valid=1並輸入測資
		wait_task;
    end
	$finish;
end

task wait_task ; begin 
	exe_lat = -1 ;
	while (out_valid !== 1) begin 
        exe_lat = exe_lat + 1;
        if(exe_lat>1000)begin
            $display("===================================");
            $display("FAIL, latency mote than 1000 cycles");
            $display("===================================");
            $finish;
        end
        @(negedge clk);
	end
end endtask 
endmodule