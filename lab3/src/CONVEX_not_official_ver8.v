module CONVEX (
	// Input
	rst_n,clk,in_valid,pt_num,in_x,in_y,
	// Output
	out_valid,out_x,out_y,drop_num
);

input				rst_n, clk, in_valid;
input		[8:0]	pt_num;
input		[9:0]	in_x, in_y;
output reg			out_valid;
output reg	[9:0]	out_x, out_y;
output reg	[6:0]	drop_num;

//Part 1 FSM (&tag)
reg [2:0] cur_state, next_state;
parameter IDLE=3'd0,EVAL_check=3'd1, EVAL_place=3'd2, OUTPUT=3'd3;
parameter CLEAR_small=4'd4, CLEAR_big=4'd5;
reg EVAL_check_done, EVAL_place_done, go_output_tag;
reg [8:0] pt_num_q, pt_cnt;
reg [7:0] out_cnt, out_cnt_bound;
reg [9:0] in_x_q, in_y_q;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
    IDLE: begin
        if(in_valid==1'b1)next_state=EVAL_check;
        else next_state=IDLE;
    end
    EVAL_check: begin
        if(go_output_tag==1'b1) next_state=OUTPUT;
        else if(EVAL_check_done==1'b1) next_state=EVAL_place;
        else next_state=EVAL_check;
    end
    EVAL_place: begin
        if(go_output_tag==1'b1) next_state=OUTPUT;
        else if(EVAL_place_done==1'b1) next_state=OUTPUT;
        else next_state=EVAL_place;
    end
    OUTPUT: begin
        if(pt_cnt<pt_num_q&&out_cnt>=out_cnt_bound-1) next_state=CLEAR_small;
        else if(pt_cnt==pt_num_q&&out_cnt>=out_cnt_bound-1)next_state=CLEAR_big;
        else next_state=OUTPUT;
    end
    CLEAR_small: next_state=IDLE;		//再CLEAR的時候才要把pt_cnt歸0
    CLEAR_big: next_state=IDLE;
    default: next_state=IDLE;
    endcase
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		pt_num_q<=9'd0; pt_cnt<=9'd0; 
		in_x_q<=10'd0; in_y_q<=10'd0;
	end
	else if(in_valid==1'b1&&pt_cnt==9'd0)begin
		pt_num_q<=pt_num; pt_cnt<=pt_cnt+1'd1; 
		in_x_q<=in_x; in_y_q<=in_y;
	end
	else if(in_valid==1'b1&&pt_cnt>9'd0)begin
		pt_num_q<=pt_num_q; pt_cnt<=pt_cnt+1'd1;
		in_x_q<=in_x; in_y_q<=in_y;
	end
    else if(cur_state==CLEAR_small)begin
        pt_num_q<=pt_num_q; pt_cnt<=pt_cnt;
        in_x_q<=10'd0; in_y_q<=10'd0;
    end
    else if(cur_state==CLEAR_big)begin
        pt_num_q<=9'd0; pt_cnt<=9'd0; 
		in_x_q<=10'd0; in_y_q<=10'd0;
    end
	else begin
		pt_num_q<=pt_num_q; pt_cnt<=pt_cnt;
		in_x_q<=in_x_q; in_y_q<=in_y_q;
	end
end

//Part 2 Comb Logic (reorder when pt_cnt==2)
wire [9:0] out_x1, out_y1, out_x2, out_y2, out_x3, out_y3;//h[0] to h[3] after reorder

reorder_points RP(
    .x1(hull_x[0]), .y1(hull_y[0]), .x2(hull_x[1]), .y2(hull_y[1]),
    .x3(in_x_q), .y3(in_y_q), .out_x1(out_x1), .out_y1(out_y1),
    .out_x2(out_x2), .out_y2(out_y2), .out_x3(out_x3), .out_y3(out_y3)
);

//Part 3 Seq Logic
reg [7:0] hull_len;
reg [7:0] hull_cur_idx; 
reg [7:0] hull_prev_idx, hull_next_idx;

always@(*)begin
    if(hull_cur_idx==8'd0) hull_prev_idx=hull_len-1'd1;
    else hull_prev_idx=hull_cur_idx-1'd1;

    if(hull_cur_idx==hull_len-1'd1) hull_next_idx=8'd0;
    else hull_next_idx=hull_cur_idx+1'd1;
end

//Part 2-1 Comb Logic: check inside
//cross(cur, next, p)，如果有任何一次小於0代表pt在hull外面
//如果全部都大於0就代表pt在hull的內部，只要有一個小於0就代表在外部!
wire [1:0] cross_check_inside;
cross cross1(.Ox(hull_x[hull_cur_idx]),.Oy(hull_y[hull_cur_idx]),
    .Ax(hull_x[hull_next_idx]),.Ay(hull_y[hull_next_idx]),
    .Bx(in_x_q), .By(in_y_q), .result(cross_check_inside));

//Part 2-2 Comb Logic: check on inner segemnt
//如果cross_result==0的時候 p.x在cur.x和prev.x中間且p.y在cur.y和prev.y中間
//代表p在hull的線段上的內部(如果有需要的話再比較128個點是否重合)
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

//Part 3 Seq Logic
reg [9:0] hull_x [0:127];
reg [9:0] hull_y [0:127];
reg [7:0] place_ptr;    //指向hull[](要放入updated_hull[]的位置)

reg [9:0] updated_hull_x [0:127];
reg [9:0] updated_hull_y [0:127];
reg [7:0] updated_hull_len;

reg [9:0] drop_x [0:127];
reg [9:0] drop_y [0:127];
reg [7:0] drop_len;
reg [7:0] drop_ptr;    //指向hull[](要放入drop[]的位置)

//在hull[]中的idx 
reg on_inner_seg_tag;
reg outside_tag;            //只要有一個cross小於0就是outside
reg [7:0] rt_coline_idx, rt_not_coline_idx;
reg [7:0] lt_coline_idx, lt_not_coline_idx;
reg [7:0] rt_prim, lt_prim; //rt`、lt`
reg [7:0] rt_prim_plus_one, lt_prim_minus_one;
reg pass_rt_prim_bool, pass_lt_prim_minus_one_bool;

always@(*)begin
    if(rt_not_coline_idx!=8'd255)rt_prim=rt_not_coline_idx;
    else if(rt_coline_idx!=8'd255)begin
        //rt`=(rt-1)%hull_len
        if(rt_coline_idx==8'd0) rt_prim=hull_len-1'd1;
        else rt_prim=rt_coline_idx-1'd1;
    end
    else rt_prim=8'd255;

    if(rt_prim==hull_len-1'd1)rt_prim_plus_one=8'd0;
    else rt_prim_plus_one=rt_prim+1'd1;
end

always@(*)begin
    if(lt_not_coline_idx!=8'd255)lt_prim=lt_not_coline_idx;
    else if(lt_coline_idx!=8'd255)begin
        //lt`=(lt+1)%hull_len
        if(lt_coline_idx==hull_len-1'd1) lt_prim=8'd0;
        else lt_prim=lt_coline_idx+1'd1;
    end
    else lt_prim=8'd255;

    if(lt_prim==8'd0)lt_prim_minus_one=hull_len-1'd1;
    else lt_prim_minus_one=lt_prim-1'd1;
end

//Part 3 Srq Logic
reg hull_placed_done,drop_placed_done;  //Tag for case 4
integer i;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0;i<128;i=i+1)begin
            hull_x[i]<=10'd0; hull_y[i]<=10'd0;
            drop_x[i]<=10'd0; drop_y[i]<=10'd0;
            updated_hull_x[i]<=10'd0; updated_hull_y[i]<=10'd0;
        end
        hull_cur_idx<=8'd0;
        hull_len<=8'd0; drop_len<=8'd0; updated_hull_len<=8'd0;
        on_inner_seg_tag<=1'd0; outside_tag<=1'd0;
        rt_coline_idx<=8'd255; rt_not_coline_idx<=8'd255;
        lt_coline_idx<=8'd255; lt_not_coline_idx<=8'd255;
        hull_placed_done<=1'b0; drop_placed_done<=1'b0;
        place_ptr<=8'd0; drop_ptr<=8'd0;
        pass_rt_prim_bool<=1'd0; pass_lt_prim_minus_one_bool<=1'd0;
        EVAL_check_done<=1'b0; EVAL_place_done<=1'b0; go_output_tag<=1'b0;
        out_cnt_bound<=8'd0;
    end
    else if(cur_state==EVAL_check&&pt_cnt<=2&&go_output_tag==1'b0)begin
        //case 0 pt_cnt<=2，直接放入hull (一定不drop)
        hull_x[hull_len]<=in_x_q; hull_y[hull_len]<=in_y_q;
        hull_len<=hull_len+1'd1; go_output_tag<=1'b1; drop_len<=9'd0;
        out_cnt_bound<=8'd1;    //即便drop_len==0，OUTPUT還是需要輸出一個cycle
    end
    else if(cur_state==EVAL_check&&pt_cnt==3&&go_output_tag==1'b0)begin
        //case 1 pt_cnt==3，直接放入reorder比較，比較完後更新Hull(一定不drop)
        hull_x[0]<=out_x1; hull_y[0]<=out_y1; 
        hull_x[1]<=out_x2; hull_y[1]<=out_y2; 
        hull_x[2]<=out_x3; hull_y[2]<=out_y3;
        hull_len<=hull_len+1'd1; go_output_tag<=1'b1; drop_len<=9'd0;
        out_cnt_bound<=8'd1;    //即便drop_len==0，OUTPUT還是需要輸出一個cycle
    end
    else if(cur_state==EVAL_check && pt_cnt>3 && hull_cur_idx<=hull_len-1'd1&&go_output_tag==1'b0)begin
        //case 2 pt_cnt>3，開始判定四個tag，且正在判斷
        hull_cur_idx<=hull_cur_idx+1'd1;
        //comb logic 1:找內部共線 (確定有共線就能進入EVAL_place)
        if(on_inner_seg_bool==1'b1) on_inner_seg_tag<=1'b1;
        else on_inner_seg_tag<=on_inner_seg_tag;

        //comb logic 2:找內部 (要做128次)
        if(cross_check_inside==2'd0) outside_tag<=1'b1; //只要有一次小於0就是在外部
        else outside_tag<=outside_tag;

        //comb logic 3:找左切點 (找到之後就標記起來)
        if(lt_coline_bool)lt_coline_idx<=hull_cur_idx;
        else lt_coline_idx<=lt_coline_idx;
        if(lt_not_coline_bool)lt_not_coline_idx<=hull_cur_idx;
        else lt_not_coline_idx<=lt_not_coline_idx;

        //comb logic 4:找右切點 (找到之後就標記起來)
        if(rt_coline_bool)rt_coline_idx<=hull_cur_idx;
        else rt_coline_idx<=rt_coline_idx;
        if(rt_not_coline_bool)rt_not_coline_idx<=hull_cur_idx;
        else rt_not_coline_idx<=rt_not_coline_idx;
    end
    else if(cur_state==EVAL_check&&pt_cnt>3&&hull_cur_idx>hull_len-1'd1&&go_output_tag==1'b0)begin
        //case 3 
        EVAL_check_done<=1'b1;
        if(on_inner_seg_tag==1'b1||outside_tag==1'b0)begin
            //直接drop輸入的pt
            go_output_tag<=1'b1; drop_len<=9'd1;
            drop_x[0]<=in_x_q; drop_y[0]<=in_y_q;
            out_cnt_bound<=8'd1;
        end
        place_ptr<=lt_prim;             //為了EVAL_place(從lt`到rt`)
        //為了EVAL_place(從(rt`+1)%hull_size到(lt`-1)%hull_size)
        drop_ptr<=rt_prim_plus_one;     
    end
    else if(cur_state==EVAL_place&&(hull_placed_done==1'b0||drop_placed_done==1'b0)&&go_output_tag==1'b0)begin
        //case 4 Place
        //step 1 放入updated_hull(從lt`放到rt`),且hull_len要更新
        if(place_ptr!=rt_prim_plus_one||pass_rt_prim_bool==1'b0)begin
            updated_hull_x[updated_hull_len]<=hull_x[place_ptr];
            updated_hull_y[updated_hull_len]<=hull_y[place_ptr];
            place_ptr<=(place_ptr+1) % hull_len;
            updated_hull_len<=updated_hull_len+1'd1;
            if(place_ptr==rt_prim) pass_rt_prim_bool<=1'b1;
            else pass_rt_prim_bool<=pass_rt_prim_bool;
        end
        else begin      //代表放完了
            for(i=0;i<128;i=i+1)begin
                if(i!=updated_hull_len)begin
                    hull_x[i]<=updated_hull_x[i];
                    hull_y[i]<=updated_hull_y[i];
                end
                else begin
                    hull_x[updated_hull_len]<=in_x_q; hull_y[updated_hull_len]<=in_y_q;
                end
            end
            //只要需要找左切或是右切，就一定要放
            hull_len<=updated_hull_len+1'd1;
            hull_placed_done<=1'b1;
        end

        //step 2 把要drop的點放入drop
        //drop_ptr從(rt'+1)%hull_len放到(lt'-1)%hull_len
        if((drop_ptr!=lt_prim||pass_lt_prim_minus_one_bool==1'b0)&&rt_prim_plus_one!=lt_prim)begin
            drop_x[drop_len]<=hull_x[drop_ptr];
            drop_y[drop_len]<=hull_y[drop_ptr];
            drop_len<=drop_len+1'd1;
            drop_ptr<=(drop_ptr+1'd1)%hull_len;
            if(drop_ptr==lt_prim_minus_one)pass_lt_prim_minus_one_bool<=1'b1;
            else pass_lt_prim_minus_one_bool<=1'b0;
        end
        else begin 
            if(rt_prim_plus_one==lt_prim)out_cnt_bound<=8'd1;   //不用drop的情況
            else out_cnt_bound<=drop_len;
            drop_placed_done<=1'b1;
        end
    end
    else if(cur_state==EVAL_place&&(hull_placed_done==1&&drop_placed_done==1))begin
        //case 5 完成EVAL_place
        go_output_tag<=1'b1; EVAL_place_done<=1'b1; 
    end
    else if(cur_state==CLEAR_small)begin
        for(i=0;i<128;i=i+1)begin
            drop_x[i]<=10'd0; drop_y[i]<=10'd0;
            updated_hull_x[i]<=10'd0; updated_hull_y[i]<=10'd0;
        end
        hull_cur_idx<=8'd0;
        drop_len<=8'd0; updated_hull_len<=8'd0;
        on_inner_seg_tag<=1'd0; outside_tag<=1'd0;
        rt_coline_idx<=8'd255; rt_not_coline_idx<=8'd255;
        lt_coline_idx<=8'd255; lt_not_coline_idx<=8'd255;
        hull_placed_done<=1'b0; drop_placed_done<=1'b0;
        place_ptr<=8'd0; drop_ptr<=8'd0;
        pass_rt_prim_bool<=1'b0; pass_lt_prim_minus_one_bool<=1'b0;
        EVAL_check_done<=1'b0; EVAL_place_done<=1'b0; go_output_tag<=1'b0;
    end
    else if(cur_state==CLEAR_big)begin
        for(i=0;i<128;i=i+1)begin
            hull_x[i]<=10'd0; hull_y[i]<=10'd0;
            drop_x[i]<=10'd0; drop_y[i]<=10'd0;
            updated_hull_x[i]<=10'd0; updated_hull_y[i]<=10'd0;
        end
        hull_cur_idx<=8'd0;
        hull_len<=8'd0; drop_len<=8'd0; updated_hull_len<=8'd0;
        on_inner_seg_tag<=1'd0; outside_tag<=1'd0;
        rt_coline_idx<=8'd255; rt_not_coline_idx<=8'd255;
        lt_coline_idx<=8'd255; lt_not_coline_idx<=8'd255;
        hull_placed_done<=1'b0; drop_placed_done<=1'b0;
        place_ptr<=8'd0; drop_ptr<=8'd0;
        pass_rt_prim_bool<=1'b0; pass_lt_prim_minus_one_bool<=1'b0;
        EVAL_check_done<=1'b0; EVAL_place_done<=1'b0; go_output_tag<=1'b0;
    end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        out_cnt<=8'd0; out_valid<=1'b0; drop_num<=8'd0;
        out_x<=10'd0; out_y<=10'd0;
    end
    else if(cur_state==OUTPUT&&out_cnt<=out_cnt_bound-1'd1)begin
        out_valid<=1'd1; out_cnt<=out_cnt+1'd1;
        if(drop_len==8'd0)begin 
            out_x<=10'd0; out_y<=10'd0;
        end
        else begin
            out_x<=drop_x[out_cnt]; out_y<=drop_y[out_cnt];
        end
        drop_num<=drop_len;
    end
    else begin
        out_cnt<=8'd0; out_valid<=1'b0; drop_num<=8'd0;
        out_x<=10'd0; out_y<=10'd0;
    end
end

endmodule

module reorder_points (
    input  [9:0] x1, y1,
    input  [9:0] x2, y2,
    input  [9:0] x3, y3,
    output [9:0] out_x1, out_y1,
    output [9:0] out_x2, out_y2,
    output [9:0] out_x3, out_y3
);
    wire [1:0] cross_result;

    cross u_cross (
        .Ox(x1), .Oy(y1), .Ax(x2), .Ay(y2),
        .Bx(x3), .By(y3), .result(cross_result)
    );

    assign out_x1 = x1;
    assign out_y1 = y1;

    assign out_x2 = (cross_result == 2'd0) ? x3 : x2;
    assign out_y2 = (cross_result == 2'd0) ? y3 : y2;
    assign out_x3 = (cross_result == 2'd0) ? x2 : x3;
    assign out_y3 = (cross_result == 2'd0) ? y2 : y3;
endmodule

module cross (
    input [9:0] Ox, Oy, input [9:0] Ax, Ay,
    input  [9:0] Bx, By, output reg [1:0] result 
);
	wire [19:0] Ox_exd, Oy_exd, Ax_exd, Ay_exd, Bx_exd, By_exd;
	assign Ox_exd={10'd0,Ox}; assign Oy_exd={10'd0,Oy};
	assign Ax_exd={10'd0,Ax}; assign Ay_exd={10'd0,Ay};
	assign Bx_exd={10'd0,Bx}; assign By_exd={10'd0,By};

	wire signed [19:0] Ox_signed, Oy_signed, Ax_signed, Ay_signed;
	wire signed [19:0] Bx_signed, By_signed;
	assign Ox_signed= $signed(Ox_exd); assign Oy_signed= $signed(Oy_exd);
	assign Ax_signed= $signed(Ax_exd); assign Ay_signed= $signed(Ay_exd);
	assign Bx_signed= $signed(Bx_exd); assign By_signed= $signed(By_exd);

    wire signed [19:0] dxA = Ax_signed - Ox_signed;  
    wire signed [19:0] dyA = Ay_signed - Oy_signed;  
    wire signed [19:0] dxB = Bx_signed - Ox_signed;  
    wire signed [19:0] dyB = By_signed - Oy_signed;  

    wire signed [22:0] term= (dxA * dyB)-(dyA * dxB);

	always @(*) begin
		if (term < 0) result = 2'd0;        // negative
		else if (term == 0) result = 2'd1;  // zero
		else result = 2'd2;                 // positive
	end
endmodule

module point_in_box (
    input  [9:0] Ax, Ay,  // Coordinates of point A
    input  [9:0] Bx, By,  // Coordinates of point B
    input  [9:0] Px, Py,  // Coordinates of point P
    output        inside   // Output: whether P is inside the rectangle defined by A and B
);
    wire x_between, y_between;
    // Check if P.x is in [min(Ax,Bx), max(Ax,Bx)]
    assign x_between = (Px >= (Ax < Bx ? Ax : Bx)) &&
                       (Px <= (Ax > Bx ? Ax : Bx));
    // Check if P.y is in [min(Ay,By), max(Ay,By)]
    assign y_between = (Py >= (Ay < By ? Ay : By)) &&
                       (Py <= (Ay > By ? Ay : By));
    // If both X and Y conditions are satisfied, inside = 1
    assign inside = x_between & y_between;
endmodule