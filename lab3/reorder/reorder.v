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
        .Ox(x1), .Oy(y1),
        .Ax(x2), .Ay(y2),
        .Bx(x3), .By(y3),
        .result(cross_result)
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