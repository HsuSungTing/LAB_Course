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
parameter IDLE=3'd0, EVAL=3'd2, OUTPUT=3'd3, CLEAR=4'd4;
reg EVAL_done, OUTPUT_done;
reg [8:0] pt_num_q, pt_cnt;
reg [9:0] in_x_q, in_y_q;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

always@(*)begin
    case(cur_state)
    IDLE: begin
        if(in_valid==1'b1)next_state=EVAL;
        else next_state=IDLE;
    end
    EVAL: begin
        if(EVAL_done==1'b1) next_state=OUTPUT;
        else next_state=EVAL;
    end
    OUTPUT: begin
        if(pt_cnt<=pt_num_q-1'd1) next_state=CLEAR;
        else next_state=OUTPUT;
    end
    CLEAR: next_state=IDLE;		//再CLEAR的時候才要把pt_cnt歸0
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
	else begin
		pt_num_q<=pt_num_q; pt_cnt<=pt_cnt;
		in_x_q<=in_x_q; in_y_q<=in_y_q;
	end
end

//Part 3 Seq Logic
reg [9:0] hull_x [0:127];
reg [9:0] hull_y [0:127];
reg [7:0] hull_len;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
    end
    else if(cur_state==EVAL)begin
        //case 0 pt_cnt<2，直接放入hull(一定不drop)
    end
    else if()begin
        //case 1 pt_cnt==2，直接放入reorder比較，比較完後更新Hull(一定不drop)
    end
    else if()begin
        //case 2 pt_cnt>2，開始判定四個tag
        EVAL_start<=1;
        //comb logic 1:找內部共線 (確定有共線就能進入EVAL_place)
        //comb logic 2:找內部 (要做128次)
        //comb logic 3:找左切點 (找到之後就標記起來)
        //comb logic 4:找右切點 (找到之後就標記起來)
        //EVAL_find_done<=1
    end
    else if()begin
        //case 3 Place 1
        //直接drop pt
        //hull保留
        //EVAL_done<=1
    end
    else if()begin
        //case 4 Place 2
        //放入updated_hull(從lt`放到rt`)直到
        //並且把要drop的點放入drop
        //if都放完 EVAL_place_done<=1;
    end
    else if(cur_state==OUTPUT)begin
        //輸出drop[]
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

    cross_product u_cross (
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

module cross_product (
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
		if (term < 0) result = 2'd0;   // negative
		else if (term == 0) result = 2'd1;   // zero
		else result = 2'd2;   // positive
	end
endmodule