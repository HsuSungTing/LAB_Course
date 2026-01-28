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