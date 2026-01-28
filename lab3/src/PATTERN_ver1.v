/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2025
// AUTHOR: Chao-En Kuo, NYCU IAIS
// DESCRIPTION: ICLAB2025FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 40.0
`endif

module PATTERN (
	// Output
	rst_n,clk,in_valid,pt_num,in_x,in_y,
	// Input
	out_valid,out_x,out_y,drop_num
);

//Part 1: IO Port
output reg			rst_n;
output reg			clk;
output reg			in_valid;
output reg	[8:0]	pt_num;
output reg	[9:0]	in_x;
output reg	[9:0]	in_y;
input				out_valid;
input		[9:0]	out_x;
input		[9:0]	out_y;
input		[6:0]	drop_num;

//Part 2-1: signals
integer total_latency, latency;
real CYCLE = `CYCLE_TIME;
integer i,j;
integer k, f_in;
integer PATNUM, pat_count; 	//outer loop
integer PTNUM, pt_cnt;		//inner loop
reg	[8:0] pt_num_d;
reg	[9:0] in_x_d, in_y_d;

//Part 3: CLK
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//Part 4: main()
initial begin
    f_in  =$fopen("../00_TESTBED/input.txt","r");
    if (f_in == 0) begin
        $display("Failed to open input.txt");
        $finish;
    end

    reset_task;

    k= $fscanf(f_in,"%d", PATNUM);		
    for(pat_count=0; pat_count<PATNUM; pat_count=pat_count+1'd1)begin
		read_PTNUM;
		while(pt_cnt<PTNUM) begin	
			pt_cnt=pt_cnt+1;

			input_task;	//讀這筆PTN的這個測資，讓in_valid=1並輸入測資
			update_golden_ans;  
			wait_out_valid;
			check_ans;
			next_round;
		end
    end
end

task read_PTNUM; begin
	pt_cnt=0;
	k = $fscanf(f_in, "%d", PTNUM);
	pt_num_d= PTNUM;
end 
endtask

task input_task; begin
	k= $fscanf(f_in,"%d %d", in_x_d,in_y_d);
	while(out_valid==1'b1)begin
		@(negedge clk);
	end
	//in_valid=1 for 1 cycle
	if(pt_cnt==0)pt_num=pt_num_d;
	else pt_num=9'd0;
	in_valid=1'b1;
	in_x=in_x_d; 
	in_y=in_y_d;

	@(negedge clk);
	in_valid=0;
	in_x=3'd0; 
	in_y=3'd0;
end
endtask

task next_round; begin
	total_latency=total_latency+latency;
	latency=0;
end
endtask

task next_PTN;	begin	//要清空所有變數
	//Initialize signals (Part 1 IO reset)
	total_latency=0; PTNUM=0; pt_cnt=0;
	pt_num=9'd0; in_x=10'd0; in_y=10'd0;

	//Initialize Part 2 sig (加上之後會有的計算golden ans的所有訊號)
	pt_num_d=9'd0;
	in_x_d=10'd0; in_y_d=10'd0;	latency=0;
end
endtask

task update_golden_ans;begin
end endtask

task check_ans; begin
end endtask

task wait_out_valid; begin
	latency=0;
	while(score_valid !== 1) begin
		latency = latency + 1;
		if(latency > 1000) begin
			$display ("-------------------------------------------------");
			$display("                    SPEC-7 FAIL                   ");
			$display ("	latency of each inputs is limited in 1000 cycles");
			$display ("-------------------------------------------------");
      		$finish;
		end

		@(negedge clk);
	end
	latency = latency + 1;
end
end
endtask

//Part 5: Reset Task
task reset_task; begin
	//Initialize signals (Part 1 IO reset)
	rst_n= 1'b1; in_valid= 1'b0;
	pt_num=9'd0; in_x=10'd0; in_y=10'd0;

	// Initialize circuit Part 2 reset)
	pt_num_d=9'd0;
	in_x_d=10'd0; in_y_d=10'd0;	latency=0;
	
	@(negedge clk);

	//Start reset
	force clk = 1'b0;
	#(CYCLE); rst_n = 1'b0;

	// spec 4 check
	#(100);
	if((out_valid !== 1'd0)||(out_x !== 10'd0)||(out_y !== 10'd0)||(drop_num !== 7'd0)) begin
		$display("--------------------------------------------------");
		$display("                    SPEC-4 FAIL                   ");
		$display("       	All outputs set to 0 when reset    		");
		$display("--------------------------------------------------");
		$finish;
	end

	// Pass the reset check
	#(CYCLE); rst_n = 1'b1;
	#(CYCLE); release clk;
end
endtask

//spec 5 check with always
always @(posedge clk) begin
    if (out_valid === 0) begin
        if ((out_x !== 0)||(out_y !== 0)||(drop_num !== 0)) begin
			$display("--------------------------------------------------");
            $display("                    SPEC-5 FAIL                   ");
			$display("		Output value set to 0 when out_valid is 0. 	");
			$display("--------------------------------------------------");
            $finish;
        end
    end
end

//spec 6 check with always
always @(posedge clk) begin
    if (in_valid === 1) begin
        if (out_valid !== 0) begin
			$display("--------------------------------------------------");
            $display("                    SPEC-6 FAIL                   ");
			$display("		out_valid should not overlap with in_valid	");
			$display("--------------------------------------------------");
            $finish;
        end
    end
end
endmodule

// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// $display("                    SPEC-9 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);