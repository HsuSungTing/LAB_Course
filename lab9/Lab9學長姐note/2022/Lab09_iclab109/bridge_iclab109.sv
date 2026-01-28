module bridge(input clk, INF.bridge_inf inf);
	
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AR_ADDR	<=	0;
	end else if(inf.C_in_valid)begin
		inf.AR_ADDR	<=	{1'd1,5'd0,inf.C_addr,3'd0};
	end
end
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AW_ADDR	<=	0;
	end else if(inf.C_in_valid)begin
		inf.AW_ADDR	<=	{1'd1,5'd0,inf.C_addr,3'd0};
	end
end	

always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)begin
		inf.AW_VALID <= 0 ; 
	end else if (inf.AW_READY && inf.AW_VALID)begin
		inf.AW_VALID <= 0 ; 
	end else if (inf.C_in_valid && inf.C_r_wb == 0)begin
		inf.AW_VALID <= 1 ; 
	end
end

always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)begin
		inf.AR_VALID <= 0 ; 
	end else if (inf.AR_READY && inf.AR_VALID)begin
		inf.AR_VALID <= 0 ; 
	end else if (inf.C_in_valid && inf.C_r_wb == 1)begin
		inf.AR_VALID <= 1 ; 
	end
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.R_READY	<=	0;
	end else if(inf.AR_READY)begin
		inf.R_READY	<=	1;
	end else if(inf.R_VALID)begin
		inf.R_READY	<=	0;
	end
end


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.W_DATA	<=	0;
	end else if(inf.C_in_valid && inf.C_r_wb == 0)begin
		inf.W_DATA	<=	inf.C_data_w;
	end 
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.W_VALID	<=	0;
	end else if(inf.AW_READY)begin
		inf.W_VALID	<=	1;
	end else if(inf.W_READY)begin
		inf.W_VALID	<=	0;
	end
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.B_READY	<=	0;
	end else if(inf.AW_READY)begin
		inf.B_READY	<=	1;
	end else if(inf.B_VALID)begin
		inf.B_READY	<=	0;
	end
end

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_out_valid <=  0;
	end else if(inf.R_VALID) begin
		inf.C_out_valid	<=	1;
	end else if(inf.B_VALID) begin
		inf.C_out_valid	<=	1;
	end else begin
		inf.C_out_valid	<=	0;
	end
end


always_ff@(posedge clk , negedge inf.rst_n)begin
	if (!inf.rst_n)begin
		inf.C_data_r	<= 0 ;
	end else if (inf.R_VALID)begin
		inf.C_data_r	<= inf.R_DATA ;
	end
end
endmodule