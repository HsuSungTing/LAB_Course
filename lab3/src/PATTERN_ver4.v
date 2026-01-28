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
reg [6:0] drop_num_q;
integer out_valid_cycle_cnt;

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
			input_task;	
			update_golden_ans;  
			wait_out_valid;
			check_spec_9_task;
			check_ans;
			next_round;
		end
    end

	// Pass all the pattern
	YOU_PASS_task;
	$finish;
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
	pt_num=9'd0;
	in_valid=0;
	in_x=3'd0; 
	in_y=3'd0;
	if(out_valid!==1'b0)begin
		$display("--------------------------------------------------");
        $display("                    SPEC-6 FAIL                   ");
		$display("		out_valid should not overlap with in_valid	");
		$display("--------------------------------------------------");
        $finish;
	end
end
endtask

task next_round; begin
	total_latency=total_latency+latency;
	latency=0;
end
endtask

task next_PTN;	begin	//should clear all variable
	//Initialize signals (Part 1 IO reset)
	total_latency=0; PTNUM=0; pt_cnt=0;
	pt_num=9'd0; in_x=10'd0; in_y=10'd0;

	//Initialize Part 2 sig (& sig to make golden ans shoukd be reset)
	pt_num_d=9'd0;
	in_x_d=10'd0; in_y_d=10'd0;	latency=0;
end
endtask

task update_hull_drop_outxy;begin
	if(pt_cnt<=2)begin
		gold_drop_num=8'd0;
		gold_drop_x[0]=10'd0; gold_drop_y[0]=10'd0;
		hull_x[hull_len]= in_x_d; hull_y[hull_len]= in_y_d;
		hull_len=hull_len+1;
	end
	else if(pt_cnt==3)begin
		//if cross的結果是負的，swap 2, 3
		gold_drop_num=8'd0;
		gold_drop_x[0]=10'd0; gold_drop_y[0]=10'd0;
		hull_len=hull_len+1;
	end
	else begin
		for(i=0;i<hull_len;i=i+1)begin
			wire [1:0] cross_check_inside;
			cross cross1
			(.Ox(hull_x[hull_cur_idx]),.Oy(hull_y[hull_cur_idx]),
			.Ax(hull_x[hull_next_idx]),.Ay(hull_y[hull_next_idx]),
			.Bx(in_x_q), .By(in_y_q), .result(cross_check_inside));

			reg on_inner_seg_bool;
			wire inside_bool;
			point_in_box PIB(
			.Ax(hull_x[hull_cur_idx]),.Ay(hull_y[hull_cur_idx]), 
			.Bx(hull_x[hull_next_idx]),.By(hull_y[hull_next_idx]), 
			.Px(in_x_q), .Py(in_y_q), .inside(inside_bool));
			always@(*)begin
				if(inside_bool==1'b1&&cross_check_inside==2'd1)on_inner_seg_bool=1'b1;
				else on_inner_seg_bool=1'b0;
			end

			//Part2 Comb Logic 找右切
			//cross(cur, p, prev)
			wire [1:0] check_cur_p_prev;
			cross cross2(.Ox(hull_x[hull_cur_idx]),.Oy(hull_y[hull_cur_idx]),
				.Ax(in_x_q),.Ay(in_y_q),
				.Bx(hull_x[hull_prev_idx]),.By(hull_y[hull_prev_idx]), 
				.result(check_cur_p_prev));

			//cross(cur, p, next)
			wire [1:0] check_cur_p_next;
			cross cross3(.Ox(hull_x[hull_cur_idx]),.Oy(hull_y[hull_cur_idx]),
				.Ax(in_x_q),.Ay(in_y_q),
				.Bx(hull_x[hull_next_idx]),.By(hull_y[hull_next_idx]), 
				.result(check_cur_p_next));

			reg rt_not_coline_bool, rt_coline_bool;
			//if cross(cur, p, prev) >0 && cross(cur, p, next) >0:右切且不共線
			always@(*)begin
				if(check_cur_p_prev==2'd2&&check_cur_p_next==2'd2)rt_not_coline_bool=1'b1;
				else rt_not_coline_bool=1'b0;
			end
			//if cross(cur, p, prev) ==0 && cross(cur, p, next) >0:右切且共線->rt也要被drop
			always@(*)begin
				if(check_cur_p_prev==2'd1&&check_cur_p_next==2'd2)rt_coline_bool=1'b1;
				else rt_coline_bool=1'b0;
			end


			//Part2 Comb Logic 找左切
			//cross(p, cur, prev)
			wire [1:0] check_p_cur_prev;
			cross cross4(.Ox(in_x_q),.Oy(in_y_q),
				.Ax(hull_x[hull_cur_idx]),.Ay(hull_y[hull_cur_idx]),
				.Bx(hull_x[hull_prev_idx]),.By(hull_y[hull_prev_idx]), 
				.result(check_p_cur_prev));

			//cross(p, cur, next)
			wire [1:0] check_p_cur_next;
			cross cross5(.Ox(in_x_q),.Oy(in_y_q),
				.Ax(hull_x[hull_cur_idx]),.Ay(hull_y[hull_cur_idx]),
				.Bx(hull_x[hull_next_idx]),.By(hull_y[hull_next_idx]), 
				.result(check_p_cur_next));

			reg lt_not_coline_bool, lt_coline_bool;
			//cross(p, cur, prev) >0 && cross(p, cur, next) >0: 左切且不共線
			always@(*)begin
				if(check_p_cur_prev==2'd2 && check_p_cur_next==2'd2)lt_not_coline_bool=1'b1;
				else lt_not_coline_bool=1'b0;
			end

			//cross(p, cur, next) ==0 && cross(p, cur, prev) >0: 左切且共線->lt也要被drop
			always@(*)begin
				if(check_p_cur_prev==2'd1 && check_p_cur_next==2'd2)lt_coline_bool=1'b1;
				else lt_coline_bool=1'b0;
			end
		end
	end
end endtask

task check_ans; begin
end endtask

task wait_out_valid; begin
	latency=0;
	while(out_valid !== 1) begin
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
endtask

task check_spec_9_task; begin
	out_valid_cycle_cnt=0;
	while(out_valid===1) begin
		drop_num_q=drop_num;
		out_valid_cycle_cnt=out_valid_cycle_cnt+1;
		//take all input here
		@(negedge clk);
	end

	if (out_valid === 1) begin
        if ((drop_num === 7'd0) && ((out_x !== 10'd0)||(out_y !== 10'd0))) begin
			$display("--------------------------------------------------");
            $display("                    SPEC-5 FAIL                   ");
			$display("		Output value set to 0 when out_valid is 0. 	");
			$display("--------------------------------------------------");
            $finish;
        end
    end
	if(drop_num_q>1 && out_valid_cycle_cnt!=drop_num_q)begin
		$display ("-------------------------------------------------");
		$display("                    SPEC-9 FAIL                   ");
		$display ("	Multiple outputs should be in continuous cycles.");
		$display ("-------------------------------------------------");
		$finish;
	end

	//===for debug===
	//$display("drop_num: %7d",drop_num_q);
	//$display("out_valid_cycle_cnt: %7d",out_valid_cycle_cnt);
	//===============

	while(out_valid_cycle_cnt<drop_num_q)begin
		if(out_valid===1)begin
			out_valid_cycle_cnt=out_valid_cycle_cnt+1;
		end
		@(negedge clk);
	end
end endtask

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

task YOU_PASS_task;begin
	$display("                  Congratulations!               ");
	$display("              execution cycles = %7d", total_latency);
	$display("              clock period = %4fns", CYCLE);
end endtask

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
	if (out_valid === 1) begin
        if ((drop_num === 7'd0) && ((out_x !== 10'd0)||(out_y !== 10'd0))) begin
			$display("--------------------------------------------------");
            $display("                    SPEC-5 FAIL                   ");
			$display("		Output value set to 0 when out_valid is 0. 	");
			$display("--------------------------------------------------");
            $finish;
        end
    end
end

// cross(O, A, B) = (Ax - Ox)*(By - Oy) - (Ay - Oy)*(Bx - Ox)
task cross_check;
    input  [9:0] Ox, Oy;
    input  [9:0] Ax, Ay;
    input  [9:0] Bx, By;
    output reg [1:0] result;  

    reg signed [10:0] dx1, dy1, dx2, dy2;   
    reg signed [21:0] mul1, mul2;           
    reg signed [22:0] cross_val;            

    begin
        dx1 = $signed({1'b0, Ax}) - $signed({1'b0, Ox});
        dy1 = $signed({1'b0, Ay}) - $signed({1'b0, Oy});
        dx2 = $signed({1'b0, Bx}) - $signed({1'b0, Ox});
        dy2 = $signed({1'b0, By}) - $signed({1'b0, Oy});

        mul1 = dx1 * dy2;
        mul2 = dy1 * dx2;
        cross_val = mul1 - mul2;

        if (cross_val < 0) result = 0;
        else if (cross_val == 0) result = 1;
        else result = 2;
    end
endtask

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