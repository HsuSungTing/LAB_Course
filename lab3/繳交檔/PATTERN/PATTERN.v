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
reg [9:0] take_out_x[0:127];
reg [9:0] take_out_y[0:127];
reg gold_drop_used_bool [0:127];
integer match_cnt;

//Part 2-2 Signal
reg [9:0] hull_x[0:127];//(clear in next_ptn)
reg [9:0] hull_y[0:127];
integer hull_len;
reg [9:0] updated_hull_x[0:127];//(clear in next_ptn)
reg [9:0] updated_hull_y[0:127];
integer updated_hull_len;

reg [9:0] gold_drop_x[0:127];//(clear in next_round)
reg [9:0] gold_drop_y[0:127];
reg [7:0] gold_drop_num;

//for pt_cnt==3
reg [1:0] cross_123;	
reg [9:0] temp_x,temp_y;

//for pt_cnt>3
integer hull_cur_idx, hull_prev_idx, hull_next_idx;
reg [1:0] cross_check_inside;
reg on_inner_seg_bool,outside_bool,inside_bool;

reg rt_not_coline_bool, rt_coline_bool;
reg [1:0] check_cur_p_prev;
reg [1:0] check_cur_p_next;
integer rt_coline_idx, rt_not_coline_idx;
integer rt_prim,rt_prim_plus_one;

reg lt_not_coline_bool, lt_coline_bool;
reg [1:0] check_p_cur_prev;
reg [1:0] check_p_cur_next;
integer lt_coline_idx, lt_not_coline_idx;
integer lt_prim,lt_prim_minus_one;

integer drop_ptr,place_ptr;
reg pass_lt_prim_minus_one_bool,pass_rt_prim_bool;

//Part 3: CLK
always #(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

task update_hull_drop_outxy;begin
	if(pt_cnt<=2)begin
		gold_drop_num=8'd0;
		gold_drop_x[0]=10'd0; gold_drop_y[0]=10'd0;
		hull_x[hull_len]= in_x_d; hull_y[hull_len]= in_y_d;
		hull_len=hull_len+1;
	end
	else if(pt_cnt==3)begin
		cross_check(hull_x[0],hull_y[0],hull_x[1],hull_y[1],in_x_d,in_y_d,cross_123);
		if(cross_123==2'd0)begin	//if cross<0, swap 2, 3
			temp_x=hull_x[1]; temp_y=hull_y[1];
			hull_x[2]=temp_x; hull_y[2]=temp_y;
			hull_x[1]=in_x_d; hull_y[1]=in_y_d;
		end
		else begin
			hull_x[2]=in_x_d; hull_y[2]=in_y_d;
		end
		gold_drop_num=8'd0; gold_drop_x[0]=10'd0; gold_drop_y[0]=10'd0;
		hull_len=hull_len+1;
	end
	else begin
		//reset
		outside_bool=0; on_inner_seg_bool=0;
		rt_not_coline_bool=0; rt_coline_bool=0; 
		rt_coline_idx=255; rt_not_coline_idx=255;	//NULL
		lt_not_coline_bool=0; lt_coline_bool=0; 
		lt_coline_idx=255; lt_not_coline_idx=255;	//NULL
		//=====

		for(i=0;i<hull_len;i=i+1)begin
			//Part 1: update idx
			hull_cur_idx=i;
			if(hull_cur_idx==0)hull_prev_idx=hull_len-1;
			else hull_prev_idx=hull_cur_idx-1;
			if(hull_cur_idx==hull_len-1)hull_next_idx=0;
			else hull_next_idx=hull_cur_idx+1;

			//Part 2-1 check inside
			//cross(cur, next, p)
			cross_check(hull_x[hull_cur_idx],hull_y[hull_cur_idx],
			hull_x[hull_next_idx],hull_y[hull_next_idx],in_x_d,in_y_d,cross_check_inside);
			if(cross_check_inside==2'd0)outside_bool=1;

			point_in_box_task (hull_x[hull_cur_idx],hull_y[hull_cur_idx], 
			hull_x[hull_next_idx],hull_y[hull_next_idx],in_x_d,in_y_d,inside_bool);
			if(inside_bool==1'b1&&cross_check_inside==2'd1)on_inner_seg_bool=1;
			
			//Part2 Comb Logic 
			//cross(cur, p, prev)
			cross_check(hull_x[hull_cur_idx],hull_y[hull_cur_idx],in_x_d,in_y_d,
			hull_x[hull_prev_idx],hull_y[hull_prev_idx],check_cur_p_prev);
			//cross(cur, p, next)
			cross_check(hull_x[hull_cur_idx],hull_y[hull_cur_idx],in_x_d,in_y_d,
			hull_x[hull_next_idx],hull_y[hull_next_idx],check_cur_p_next);

			//if cross(cur, p, prev) >0 && cross(cur, p, next) >0
			if(check_cur_p_prev==2'd2&&check_cur_p_next==2'd2)begin
				rt_not_coline_bool=1'b1; rt_not_coline_idx=hull_cur_idx;
			end
			//if cross(cur, p, prev) ==0 && cross(cur, p, next) >0
			if(check_cur_p_prev==2'd1&&check_cur_p_next==2'd2)begin
				rt_coline_bool=1'b1; rt_coline_idx=hull_cur_idx;
			end
			
			//Part2 Comb Logic
			//cross(p, cur, prev)
			cross_check(in_x_d,in_y_d,hull_x[hull_cur_idx],hull_y[hull_cur_idx],
			hull_x[hull_prev_idx],hull_y[hull_prev_idx],check_p_cur_prev);
			//cross(p, cur, next)
			cross_check(in_x_d,in_y_d,hull_x[hull_cur_idx],hull_y[hull_cur_idx],
			hull_x[hull_next_idx],hull_y[hull_next_idx],check_p_cur_next);

			//cross(p, cur, prev) >0 && cross(p, cur, next) >0
			if(check_p_cur_prev==2'd2 && check_p_cur_next==2'd2)begin 
				lt_not_coline_bool=1'b1; lt_not_coline_idx=hull_cur_idx;
			end
			//cross(p, cur, next) ==0 && cross(p, cur, prev) >0
			if(check_p_cur_next==2'd1 && check_p_cur_prev==2'd2)begin 
				lt_coline_bool=1'b1; lt_coline_idx=hull_cur_idx;
			end
		end

		//update lt_prim
		if(lt_not_coline_idx!=255)lt_prim=lt_not_coline_idx;
		else if(lt_coline_idx!=255)begin	//lt`=(lt+1)%hull_len
			if(lt_coline_idx==hull_len-1) lt_prim=0;
			else lt_prim=lt_coline_idx+1;
		end
		else lt_prim=255;
		if(lt_prim==0)lt_prim_minus_one=hull_len-1;
		else lt_prim_minus_one=lt_prim-1;
		//===============

		//update rt_prim
		if(rt_not_coline_idx!=255)rt_prim=rt_not_coline_idx;
		else if(rt_coline_idx!=255)begin	//rt`=(rt-1)%hull_len
			if(rt_coline_idx==0) rt_prim=hull_len-1;
			else rt_prim=rt_coline_idx-1;
		end
		else rt_prim=255;
		if(rt_prim==hull_len-1)rt_prim_plus_one=0;
		else rt_prim_plus_one=rt_prim+1;
		//===============

		//update drop[]&hull[]
		if(outside_bool==0||on_inner_seg_bool==1)begin
			gold_drop_num=1; 
			gold_drop_x[0]=in_x_d; gold_drop_y[0]=in_y_d;
		end
		else begin
			//reset
			drop_ptr=rt_prim_plus_one; place_ptr=lt_prim; 
			pass_rt_prim_bool=0;  pass_lt_prim_minus_one_bool=0;
			updated_hull_len=0; gold_drop_num=0; 
			for(i=0;i<128;i=i+1)begin
				updated_hull_x[i]=0; updated_hull_y[i]=0;
				gold_drop_x[i]=0; gold_drop_y[i]=0;
			end
			//======

			//update drop[ ]
			while((drop_ptr!=lt_prim||pass_lt_prim_minus_one_bool==0)&&rt_prim_plus_one!=lt_prim)begin
				gold_drop_x[gold_drop_num]=hull_x[drop_ptr];
            	gold_drop_y[gold_drop_num]=hull_y[drop_ptr];
            	if(drop_ptr==lt_prim_minus_one)pass_lt_prim_minus_one_bool=1'b1;
				gold_drop_num=gold_drop_num+1'd1;
            	drop_ptr=(drop_ptr+1'd1)%hull_len;
			end
			//==============

			//update hull[ ]
			while(place_ptr!=rt_prim_plus_one||pass_rt_prim_bool==0)begin
				updated_hull_x[updated_hull_len]=hull_x[place_ptr];
                updated_hull_y[updated_hull_len]=hull_y[place_ptr];
				updated_hull_len=updated_hull_len+1'd1;
				if(place_ptr==rt_prim) pass_rt_prim_bool=1;
				place_ptr=(place_ptr+1) % hull_len;
			end
			for(i=0;i<128;i=i+1)begin
                if(i!=updated_hull_len)begin
                    hull_x[i]=updated_hull_x[i];hull_y[i]=updated_hull_y[i];
                end
                else begin
                    hull_x[updated_hull_len]=in_x_d; 
					hull_y[updated_hull_len]=in_y_d;
                end
            end
            hull_len=updated_hull_len+1; 
			//===================
		end
	end
end endtask

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

task point_in_box_task;
    input  [9:0] Ax, Ay;  
    input  [9:0] Bx, By;  
    input  [9:0] Px, Py;  
    output       inside_bool; 
    reg x_between, y_between;
    begin
        // Check if P.x is in [min(Ax,Bx), max(Ax,Bx)]
        x_between = (Px >= (Ax < Bx ? Ax : Bx)) &&
                    (Px <= (Ax > Bx ? Ax : Bx));
        // Check if P.y is in [min(Ay,By), max(Ay,By)]
        y_between = (Py >= (Ay < By ? Ay : By)) &&
                    (Py <= (Ay > By ? Ay : By));
        // If both X and Y conditions are satisfied, inside_bool = 1
        inside_bool = x_between & y_between;
    end
endtask

//Part 4: main()
initial begin
    f_in  =$fopen("../00_TESTBED/input.txt","r");
    if (f_in == 0) begin
        $display("Failed to open input.txt");
        $finish;
    end

    k= $fscanf(f_in,"%d", PATNUM);		
    for(pat_count=0; pat_count<PATNUM; pat_count=pat_count+1'd1)begin
		reset_task;
		read_PTNUM;
		while(pt_cnt<PTNUM) begin	
			pt_cnt=pt_cnt+1;
			input_task;	
			update_hull_drop_outxy;  
			wait_out_valid;
			check_spec_9_task;
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
	//Part 2-2 Sig reset
	drop_ptr=rt_prim_plus_one; place_ptr=lt_prim; 
	pass_rt_prim_bool=0;  pass_lt_prim_minus_one_bool=0;
	updated_hull_len=0; gold_drop_num=0; 
	for(i=0;i<128;i=i+1)begin
		updated_hull_x[i]=0; updated_hull_y[i]=0;
		gold_drop_x[i]=0; gold_drop_y[i]=0;
	end
end
endtask

task next_PTN;	begin	//should clear all variable
	//Initialize signals (Part 1 IO reset)
	total_latency=0; PTNUM=0; pt_cnt=0;
	pt_num=9'd0; in_x=10'd0; in_y=10'd0;

	//Initialize Part 2-1 sig
	pt_num_d=9'd0;
	in_x_d=10'd0; in_y_d=10'd0;	latency=0;

	//Initialize Part 2-2(& sig to make golden ans shoukd be reset)
	hull_len=0;
	for(i=0;i<128;i=i+1)begin
		hull_x[i]=0; hull_y[i]=0;
	end
end
endtask

task check_spec_8; begin
	//reset
	for(i=0;i<128;i=i+1)begin
		gold_drop_used_bool[i]=0;
	end
	match_cnt=0;
	//=====
	if(gold_drop_num!=drop_num_q)begin
		$display("--------------------------------------------------");
		$display("                    SPEC-8 FAIL                   ");
		$display("--------------------------------------------------");
		$finish;
	end
	else begin
		for(i=0;i<out_valid_cycle_cnt;i=i+1)begin
			for(j=0;j<gold_drop_num;j=j+1)begin
				if(take_out_x[i]==gold_drop_x[j]&&take_out_y[i]==gold_drop_y[j]
					&&gold_drop_used_bool[j]==0)begin
					gold_drop_used_bool[j]=1;
					match_cnt=match_cnt+1;
				end
			end
		end

		if(match_cnt!=gold_drop_num)begin
			$display("--------------------------------------------------");
			$display("                    SPEC-8 FAIL                   ");
			$display("--------------------------------------------------");
			$finish;
		end
	end

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
	//reset
	for(i=0;i<128;i=i+1)begin
		take_out_x[i]=0; take_out_y[i]=0;
	end
	out_valid_cycle_cnt=0;
	//=====

	while(out_valid===1) begin
		//take all input here
		drop_num_q=drop_num;
		take_out_x[out_valid_cycle_cnt]=out_x;
		take_out_y[out_valid_cycle_cnt]=out_y;
		out_valid_cycle_cnt=out_valid_cycle_cnt+1;
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
	check_spec_8;

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
	total_latency=0; latency=0;
	rst_n= 1'b1; in_valid= 1'b0;
	pt_num=9'd0; in_x=10'd0; in_y=10'd0;

	// Initialize circuit Part 2-1 reset
	pt_num_d=9'd0;
	in_x_d=10'd0; in_y_d=10'd0;	latency=0;

	//nitialize circuit Part 2-2
	hull_len=0; gold_drop_num=0;
	for(i=0;i<128;i=i+1)begin
		hull_x[i]=0; hull_y[i]=0;
		gold_drop_x[i]=0; gold_drop_y[i]=0;
	end
	
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

//spec 6 check with always
// always @(posedge clk) begin
//     if (in_valid === 1) begin
//         if (out_valid !== 0) begin
// 			$display("--------------------------------------------------");
//             $display("                    SPEC-6 FAIL                   ");
// 			$display("		out_valid should not overlap with in_valid	");
// 			$display("--------------------------------------------------");
//             $finish;
//         end
//     end
// end

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