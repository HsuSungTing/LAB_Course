`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

module PATTERN(
    // Output signals
    clk,
	rst_n,
	in_valid,
    in_hole_num,
    in_hole_suit,
    in_pub_num,
    in_pub_suit,
    out_valid,
    out_win_rate
);

// ========================================
// Input & Output
// ========================================
output reg clk;
output reg rst_n;
output reg in_valid;
output reg [71:0] in_hole_num;
output reg [35:0] in_hole_suit;
output reg [11:0] in_pub_num;
output reg [6:0] in_pub_suit;

input out_valid;
input [62:0] out_win_rate;

// ========================================
// Parameter
// ========================================
parameter Path_in  = "../00_TESTBED/result_winrate.txt";

integer file_in;
integer pat;
integer patnum = 10;
integer len;
integer counter;
integer out_latency, total_latency;

reg [3:0] hcn [8:0][1:0];
reg [1:0] hcs [8:0][1:0];
reg [3:0] pcn [2:0];
reg [1:0] pcs [2:0];
reg [6:0] golden_win_rate[8:0];
reg [62:0] golden_out;

integer i, j;
//================================================================
// clock
//================================================================
//reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

assign golden_out = {golden_win_rate[8], golden_win_rate[7], golden_win_rate[6], golden_win_rate[5], golden_win_rate[4], golden_win_rate[3], golden_win_rate[2], golden_win_rate[1], golden_win_rate[0]};

initial begin
	file_in = $fopen(Path_in, "r");
    $fscanf(file_in, "%d", patnum);
	reset_task;
	total_latency = 0;
	repeat(4) @(negedge clk);
	for (pat = 0; pat < patnum; pat = pat + 1)begin
		input_task;
		wait_out_task;
		total_latency = total_latency + out_latency;
		check_ans_task;
		$display("PASS PATTERN NO.%4d", pat);
		repeat($urandom_range(2, 4)) @(negedge clk);
	end
	YOU_PASS_task;
end

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    in_hole_num = 'bx;
    in_hole_suit = 'bx;
    in_pub_num = 'bx;
    in_pub_suit = 'bx;
	
    force clk = 0;
    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    if(out_valid !== 'b0 || out_win_rate !== 'b0) begin //out!==0
        $display("************************************************************");  
        $display("                          FAIL!                              ");    
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE;
        $finish;
    end
	#CYCLE; release clk;
end endtask


task input_task; begin
	for(j=0; j<9; j=j+1)begin
		$fscanf(file_in, "%d %d %d %d", hcn[j][1], hcs[j][1], hcn[j][0], hcs[j][0]);	
	end	
    $fscanf(file_in, "%d %d %d %d %d %d", pcn[2], pcs[2], pcn[1], pcs[1], pcn[0], pcs[0]);	
    $fscanf(file_in, "%d %d %d %d %d %d %d %d %d", golden_win_rate[0], golden_win_rate[1], golden_win_rate[2], golden_win_rate[3], golden_win_rate[4], golden_win_rate[5], golden_win_rate[6], golden_win_rate[7], golden_win_rate[8]);	
	@(negedge clk);
	in_valid = 'b1;
	in_hole_num  = {hcn[8][1], hcn[8][0], hcn[7][1], hcn[7][0], hcn[6][1], hcn[6][0], hcn[5][1], hcn[5][0], hcn[4][1], hcn[4][0], hcn[3][1], hcn[3][0], hcn[2][1], hcn[2][0], hcn[1][1], hcn[1][0], hcn[0][1], hcn[0][0]};
	in_hole_suit = {hcs[8][1], hcs[8][0], hcs[7][1], hcs[7][0], hcs[6][1], hcs[6][0], hcs[5][1], hcs[5][0], hcs[4][1], hcs[4][0], hcs[3][1], hcs[3][0], hcs[2][1], hcs[2][0], hcs[1][1], hcs[1][0], hcs[0][1], hcs[0][0]};
	in_pub_num = {pcn[2], pcn[1], pcn[0]};
	in_pub_suit = {pcs[2], pcs[1], pcs[0]};
    check_out_valid_task;
	@(negedge clk);

    in_valid = 'b0;
    in_hole_num = 'bx;
    in_hole_suit = 'bx;
    in_pub_num = 'bx;
    in_pub_suit = 'bx;
	@(negedge clk);
end endtask

task wait_out_task; begin
	out_latency = 1;
	while(out_valid !== 1)begin
		if(out_latency === 2001) begin
			$display("********************************************************");     
			$display("*                     FAIL!                            *");
			$display("*  The execution latency are over 2000 cycles          *");//over max
			$display("********************************************************");
			repeat(2) @(negedge clk);
			$finish;
		end
		out_latency = out_latency + 1;
		@(negedge clk);
	end
end endtask

task check_out_valid_task; begin
	if(out_valid !== 0 )begin
		$display("********************************************************");     
		$display("                     FAIL!                              ");
		$display("*  out_valid should not be raised when in_valid is high.  *");
		$display("********************************************************");
		repeat(2) @(negedge clk);
		$finish;
	end
    else if(out_win_rate !== 'b0)begin
		$display("********************************************************");     
		$display("                     FAIL!                              ");
		$display("*  out_win_rate should not be raised when in_valid is high.  *");
		$display("********************************************************");
		repeat(2) @(negedge clk);
		$finish;
	end
end endtask

task check_ans_task; begin
    if(out_win_rate !== golden_out)begin
        $display("********************************************************");     
        $display("                     FAIL!                              ");
        $display("*                 Wrong answer                         *");
        $display("********************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    @(negedge clk);
end endtask

task YOU_PASS_task; begin
    $display ("--------------------------------------------------------------------");
    $display ("                         Congratulations!                           ");
    $display ("                  You have passed all patterns!                     ");
    $display ("                  Your execution cycles = %5d cycles                ", total_latency);
	$display ("                  Your clock period = %.1f ns                       ", CYCLE);
    $display ("                  Total Latency = %.1f ns                           ", total_latency*CYCLE);
    $display ("--------------------------------------------------------------------");     
    repeat(2)@(negedge clk);
    $finish;
end endtask

endmodule