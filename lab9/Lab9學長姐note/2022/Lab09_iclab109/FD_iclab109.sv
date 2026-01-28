module FD(input clk, INF.FD_inf inf);
import usertype::*;
//   modport FD_inf(
//	    input  rst_n,
//			   D, id_valid, act_valid, res_valid, cus_valid, food_valid,
//			   C_out_valid, C_data_r,
//       output out_valid, err_msg,  complete, out_info, 
//			   C_addr, C_data_w, C_in_valid, C_r_wb
//	);

State 		c_state, n_state;
DATA 			data;
Action 			act;
Error_Msg 		err_msg, err_msg_comb;



D_man_Info 	deliver_man, deliver_man_comb;
D_man_Info 	gold_deliver_man, gold_deliver_man_comb;
res_info 	restaurant,restaurant_comb;
res_info 	gold_restaurant,gold_restaurant_comb;

logic [7:0] id,res_id;
logic [63:0] out,out_comb;
Ctm_Info    customer;
food_ID_servings food_id;
logic [8:0] total_food_num;
//bridge logic
logic [7:0]  D_addr,D_addr_comb;
logic [63:0] D_data,reverse_D_data,reverse_write_data;
logic D_in_valid;
logic D_r_wb, D_r_wb_comb;
//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
integer i,j;
//===========================================================================
// logic 
//===========================================================================
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		c_state	<=	IDLE;
		id<=0;
		res_id<=0;
		customer<=0;
		food_id<=0;	
	end
	else begin
		c_state <= n_state;
		if(inf.act_valid)begin act <= inf.D.d_act[0];end
		else 			 begin act <= act; end	
		if(inf.id_valid) begin id <= inf.D.d_id[0];end
		else			 begin id<= id; end
		if(inf.cus_valid)begin customer <= inf.D.d_ctm_info[0];end
		else 			 begin customer <= customer; end
		if(inf.res_valid)begin res_id <= inf.D.d_res_id[0]; end
		else 			 begin res_id <=res_id; end
		if(inf.food_valid)begin food_id <= inf.D.d_food_ID_ser[0]; end 
		else 			 begin food_id <= food_id;end
	end
end

always_comb begin
	//-----------------------initial-------------------------------------
	n_state	= 	c_state;
	case(c_state)
		IDLE:begin
			if(inf.act_valid)	begin n_state = ACT;	end
			else begin n_state = IDLE; end
		end
		ACT:begin
			if(act == Take)begin 		   n_state = TAKE;		end
			else if(act == Deliver)begin n_state = DELIVER;	end
			else if(act == Order  )begin n_state = ORDER;		end
			else if(act == Cancel )begin n_state = CANCEL;	end
			else begin n_state = ACT; end
		end
		TAKE:begin
			if(inf.cus_valid)		begin n_state = READ_ID_INV; end
			else begin 					  n_state = TAKE;	  end
		end
		DELIVER:begin
			if(inf.id_valid)		begin n_state = READ_ID_INV; end
			else begin 					  n_state = DELIVER;  end
		end					
		ORDER:begin
			if(inf.food_valid)		begin n_state = READ_RES_INV; end
			else begin 					  n_state = ORDER;	  end
		end						
		CANCEL:begin 
			if(inf.id_valid)		begin n_state = READ_ID_INV; end
			else begin 					  n_state = CANCEL;	  end
		end
		READ_ID_INV:begin n_state = READ_ID;end
		READ_ID:begin
			if(inf.C_out_valid==1) begin
				case(act)
					Take: begin	n_state = READ_RES_INV;end
					Deliver:begin n_state = CHECK;end
					Order:begin	n_state = READ_RES_INV;end
					Cancel:begin n_state = CHECK;end
					default:begin n_state = IDLE; end
				endcase
			end
			else begin
				n_state = READ_ID;
			end
		end
		READ_RES_INV:begin n_state = READ_RES; end
		READ_RES:begin
			if(inf.C_out_valid==1) begin
				n_state = CHECK;
			end
			else begin
				n_state = READ_RES;
			end
		end
		CHECK:begin n_state=HOLD; end
		HOLD:begin
			if(err_msg==0)begin
				case(act)
					Take: 	n_state = WRITE_ID_INV;
					Deliver:n_state = WRITE_ID_INV;
					Order:	n_state = WRITE_RES_INV;
					Cancel: n_state = WRITE_ID_INV;
					default:begin n_state = IDLE; end
				endcase
			end
			else n_state=OUT;
		end
		WRITE_ID_INV:begin n_state = WRITE_ID; end
		WRITE_ID:begin
			if(inf.C_out_valid==1) begin
				case(act)
					Take: 	n_state = WRITE_RES_INV;
					Deliver:n_state = OUT;
					Order:	n_state = WRITE_RES_INV;
					Cancel: n_state = OUT;
					default:begin n_state = IDLE; end
				endcase
			end
			else begin
				n_state = WRITE_ID;
			end
		end
		WRITE_RES_INV:begin n_state = WRITE_RES;end
		WRITE_RES:begin
			if(inf.C_out_valid==1) begin
				n_state = OUT;
			end
			else begin
				n_state = WRITE_RES;
			end
		end
		OUT:begin
			n_state = IDLE;
		end
	endcase	
end

//total_food_num
always_comb begin
	total_food_num = restaurant.ser_FOOD1+restaurant.ser_FOOD2+restaurant.ser_FOOD3+food_id.d_ser_food;
end
//check 
always_ff@(posedge clk or negedge inf.rst_n)begin
 	if(!inf.rst_n) begin
		err_msg	<=	No_Err;
		out<=0;
 	end
 	else begin 
		err_msg <=	err_msg_comb;
		out <= out_comb;
 	end 

end
always_comb begin
	//initial-------------------------------------
	err_msg_comb = err_msg;
	out_comb = out;
		
	deliver_man_comb.ctm_info1 = deliver_man.ctm_info1;
	deliver_man_comb.ctm_info2 = deliver_man.ctm_info2;
	restaurant_comb = restaurant;
		
	gold_deliver_man_comb = gold_deliver_man;
	gold_restaurant_comb  =	gold_restaurant;
	//check
	if(c_state==CHECK)begin
		case(act)
			Take:begin
				if(deliver_man.ctm_info1.ctm_status !=None && deliver_man.ctm_info2.ctm_status!=None)begin
					err_msg_comb = D_man_busy;
					out_comb = 0;
				end
				else begin
					case(customer.food_ID)
						FOOD1:begin
							if(restaurant.ser_FOOD1 < customer.ser_food)begin
								err_msg_comb = No_Food;
								out_comb = 0;
							end
							else begin
								if(deliver_man.ctm_info1.ctm_status ==None)
									deliver_man_comb.ctm_info1 = customer;
								else begin
									if(customer.ctm_status > deliver_man.ctm_info1.ctm_status)begin
										deliver_man_comb.ctm_info1 = customer;
										deliver_man_comb.ctm_info2 = deliver_man.ctm_info1;
									end
									else begin
										deliver_man_comb.ctm_info1 = deliver_man.ctm_info1;
										deliver_man_comb.ctm_info2 = customer;
									end
								end
								restaurant_comb.ser_FOOD1 = restaurant.ser_FOOD1 - customer.ser_food;
								out_comb = {deliver_man_comb,restaurant_comb};
							end
						end
						FOOD2:begin
						if(restaurant.ser_FOOD2 < customer.ser_food)begin
								err_msg_comb = No_Food;
								out_comb = 0;
							end
							else begin
								if(deliver_man.ctm_info1.ctm_status ==None)
									deliver_man_comb.ctm_info1 = customer;
								else begin
									if(customer.ctm_status > deliver_man.ctm_info1.ctm_status)begin
										deliver_man_comb.ctm_info1 = customer;
										deliver_man_comb.ctm_info2 = deliver_man.ctm_info1;
									end
									else begin
										deliver_man_comb.ctm_info1 = deliver_man.ctm_info1;
										deliver_man_comb.ctm_info2 = customer;
									end
								end
								restaurant_comb.ser_FOOD2 = restaurant.ser_FOOD2 - customer.ser_food;
								out_comb = {deliver_man_comb,restaurant_comb};
							end
						end
						FOOD3:begin
							if(restaurant.ser_FOOD3 < customer.ser_food)begin
								err_msg_comb = No_Food;
								out_comb = 0;
							end
							else begin
								if(deliver_man.ctm_info1.ctm_status ==None)
									deliver_man_comb.ctm_info1 = customer;
								else begin
									if(customer.ctm_status > deliver_man.ctm_info1.ctm_status)begin
										deliver_man_comb.ctm_info1 = customer;
										deliver_man_comb.ctm_info2 = deliver_man.ctm_info1;
									end
									else begin
										deliver_man_comb.ctm_info1 = deliver_man.ctm_info1;
										deliver_man_comb.ctm_info2 = customer;
									end
								end
								restaurant_comb.ser_FOOD3 = restaurant.ser_FOOD3 - customer.ser_food;
								out_comb = {deliver_man_comb,restaurant_comb};
							end
						end
					endcase
				end
			end
			Deliver:begin
				if(deliver_man.ctm_info1.ctm_status ==None && deliver_man.ctm_info2.ctm_status==None)begin
					err_msg_comb = No_customers; //0100
					out_comb = 0;
				end
				else begin
					deliver_man_comb.ctm_info1 = deliver_man.ctm_info2;
					deliver_man_comb.ctm_info2 = 0;
					err_msg_comb = No_Err;
					out_comb = {deliver_man.ctm_info2,48'd0};
				end
			end
			Order:begin
				if(total_food_num > restaurant.limit_num_orders)begin
					err_msg_comb = Res_busy; //1000
					out_comb = 0;
				end
				else begin
					if(food_id.d_food_ID == FOOD1) restaurant_comb.ser_FOOD1 = restaurant.ser_FOOD1 + food_id.d_ser_food;
					else if(food_id.d_food_ID == FOOD2) restaurant_comb.ser_FOOD2 = restaurant.ser_FOOD2 + food_id.d_ser_food;
					else if(food_id.d_food_ID == FOOD3) restaurant_comb.ser_FOOD3 = restaurant.ser_FOOD3 + food_id.d_ser_food;
					else restaurant_comb = restaurant;
					
					err_msg_comb = No_Err;
					out_comb = {32'd0,restaurant_comb};
				end
			end
			Cancel:begin
				if(deliver_man.ctm_info1.ctm_status ==None && deliver_man.ctm_info2.ctm_status==None)begin
					err_msg_comb = Wrong_cancel; 
					out_comb = 0;
				end
				else if (deliver_man.ctm_info1.res_ID != res_id && deliver_man.ctm_info2.res_ID != res_id  )begin
					err_msg_comb = Wrong_res_ID; 
					out_comb = 0;
				end
				else if (deliver_man.ctm_info1.res_ID == res_id && deliver_man.ctm_info1.food_ID != food_id.d_food_ID)begin
					err_msg_comb = Wrong_food_ID; 
					out_comb = 0;
				end
				else if (deliver_man.ctm_info2.res_ID == res_id && deliver_man.ctm_info2.food_ID != food_id.d_food_ID)begin
					err_msg_comb = Wrong_food_ID; 
					out_comb = 0;
				end
				else begin
					if ( deliver_man.ctm_info1.res_ID == res_id && deliver_man.ctm_info1.food_ID == food_id.d_food_ID 
					&&   deliver_man.ctm_info2.res_ID == res_id && deliver_man.ctm_info2.food_ID == food_id.d_food_ID)begin
						deliver_man_comb.ctm_info1 = 0;
						deliver_man_comb.ctm_info2 = 0;
						err_msg_comb = No_Err;
						out_comb = {64'd0};
					end
					else if(deliver_man.ctm_info1.res_ID == res_id && deliver_man.ctm_info1.food_ID == food_id.d_food_ID)begin
						deliver_man_comb.ctm_info1 = deliver_man_comb.ctm_info2;
						deliver_man_comb.ctm_info2 = 0;
						err_msg_comb = No_Err;
						out_comb = {deliver_man_comb,32'b0};
					end
					else begin
						deliver_man_comb.ctm_info2 = 0;
						err_msg_comb = No_Err;
						out_comb = {deliver_man_comb,32'b0};
					end
				end
			end
		endcase
	end
	else if(c_state==READ_ID)begin
		if(inf.C_out_valid) begin 
			deliver_man_comb.ctm_info1 = reverse_D_data[31:16];
			deliver_man_comb.ctm_info2 = reverse_D_data[15:0];
			
			gold_restaurant_comb = reverse_D_data[63:32];
		end
		err_msg_comb = No_Err;
		out_comb = 0;
	end
	else if(c_state==READ_RES)begin
		if(inf.C_out_valid) begin 
			restaurant_comb = reverse_D_data[63:32];
			
			gold_deliver_man_comb.ctm_info1 = reverse_D_data[31:16];
			gold_deliver_man_comb.ctm_info2 = reverse_D_data[15:0];
		end
		err_msg_comb = No_Err;
		out_comb = 0;
	end
	else begin
		err_msg_comb = err_msg;
		out_comb = out;
		
		deliver_man_comb.ctm_info1 = deliver_man.ctm_info1;
		deliver_man_comb.ctm_info2 = deliver_man.ctm_info2;
		restaurant_comb = restaurant;
		
		gold_deliver_man_comb = gold_deliver_man;
		gold_restaurant_comb  =	gold_restaurant;
	end
end
//bridge_in
always_ff@(posedge clk or negedge inf.rst_n)begin
 	if(!inf.rst_n) begin
		deliver_man <= 0;
		restaurant<=0;
		gold_deliver_man<=0;
		gold_restaurant<=0;
 	end
 	else if(inf.C_out_valid) begin 
		gold_deliver_man <=gold_deliver_man_comb;
		deliver_man<= deliver_man_comb;
		gold_restaurant<=gold_restaurant_comb;
		restaurant<= restaurant_comb;
 	end 
end
always_comb begin
	if(inf.C_out_valid) begin 
		reverse_D_data = { inf.C_data_r[7:0],
							inf.C_data_r[15:8],
							inf.C_data_r[23:16],
							inf.C_data_r[31:24],
							inf.C_data_r[39:32],
							inf.C_data_r[47:40],
							inf.C_data_r[55:48],
							inf.C_data_r[63:56]};
 	end 
	else begin
		reverse_D_data =0;
	end
end

//bridge_out
always_ff@(posedge clk or negedge inf.rst_n)begin
 	if(!inf.rst_n) begin
 		inf.C_in_valid  <=	0;
 		inf.C_addr		<=	0;
		inf.C_data_w	<=	0;
		inf.C_r_wb		<=	0;
		D_r_wb			<=  0;
		D_addr			<=  0;			
 	end
 	else  begin 
 		inf.C_in_valid	<=	D_in_valid ;
		inf.C_data_w	<=	D_data ;
		inf.C_addr		<=	D_addr_comb ;
		inf.C_r_wb		<=	D_r_wb_comb ;
		D_r_wb 			<=  D_r_wb_comb ;
		D_addr			<=  D_addr_comb ;
 	end 
end

always_comb begin
	D_in_valid	=	(c_state==READ_ID_INV || c_state==READ_RES_INV || c_state==WRITE_ID_INV || c_state==WRITE_RES_INV) ? 1 : 0;
end
always_comb begin
	D_r_wb_comb = D_r_wb;
	if(c_state==READ_ID_INV) D_r_wb_comb=1;
	else if(c_state==READ_RES_INV) D_r_wb_comb=1;
	else if(c_state==WRITE_ID_INV || c_state==WRITE_ID) D_r_wb_comb=0;
	else if(c_state==WRITE_RES_INV || c_state==WRITE_RES)D_r_wb_comb=0;
	else D_r_wb_comb = D_r_wb;
end
always_comb begin
	//initial-------------------------------------
	D_data=0;
	D_addr_comb = D_addr;

	if(c_state==READ_ID_INV) begin 
		D_addr_comb = id;
		D_data = 0;
	end
	else if(c_state==READ_RES_INV) begin
		if(act == Take) D_addr_comb = customer.res_ID;
		else D_addr_comb = res_id;
		D_data = 0;
	end
	else if(c_state==WRITE_ID_INV || c_state== WRITE_ID) begin
		D_addr_comb = id;
		D_data=reverse_write_data;
	end
	else if(c_state==WRITE_RES_INV || c_state==WRITE_RES)begin
		if(act == Take) D_addr_comb = customer.res_ID;
		else D_addr_comb = res_id;
		D_data = reverse_write_data;
	end
	else begin
		D_data = 0;
		D_addr_comb = D_addr;
	end	
end

always_comb begin
	reverse_write_data =0;
	case(act)
		Take:begin
			if(id == customer.res_ID)
				reverse_write_data = {out[39:32],out[47:40],out[55:48],out[63:56],out[7:0],out[15:8],out[23:16],out[31:24]};
			else if(c_state == WRITE_ID_INV || c_state == WRITE_ID)
				reverse_write_data = 	{out[39:32],out[47:40],out[55:48],out[63:56],gold_restaurant.ser_FOOD3,gold_restaurant.ser_FOOD2,gold_restaurant.ser_FOOD1,gold_restaurant.limit_num_orders}; 
			else if(c_state == WRITE_RES_INV || c_state == WRITE_RES)
				reverse_write_data =	{gold_deliver_man[7:0],gold_deliver_man[15:8],gold_deliver_man[23:16],gold_deliver_man[31:24],out[7:0],out[15:8],out[23:16],out[31:24]};
			else reverse_write_data = 0;
		end
		Deliver:begin
			reverse_write_data = {out[39:32],out[47:40],out[55:48],out[63:56],gold_restaurant.ser_FOOD3,gold_restaurant.ser_FOOD2,gold_restaurant.ser_FOOD1,gold_restaurant.limit_num_orders}; 
		end
		Order:begin
			reverse_write_data ={gold_deliver_man[7:0],gold_deliver_man[15:8],gold_deliver_man[23:16],gold_deliver_man[31:24],out[7:0],out[15:8],out[23:16],out[31:24]};
		end
		Cancel:begin
			reverse_write_data = {out[39:32],out[47:40],out[55:48],out[63:56],gold_restaurant.ser_FOOD3,gold_restaurant.ser_FOOD2,gold_restaurant.ser_FOOD1,gold_restaurant.limit_num_orders}; 
		end
	endcase
end

//output
always_ff@(posedge clk or negedge inf.rst_n)begin
 	if(!inf.rst_n) begin
 		inf.out_valid   <=0 ;
 		inf.err_msg		<=No_Err ;
		inf.complete	<=0 ;
		inf.out_info	<=0	;
 	end 
	else if(c_state == OUT) begin 
 		inf.out_valid   <=1 ;
 		inf.err_msg		<=err_msg ;
		if(err_msg)inf.complete	<=0;
		else inf.complete	<=1;
		inf.out_info	<=out ;
	end	
	else begin
		inf.out_valid   <=0 ;
 		inf.err_msg		<=No_Err ;
		inf.complete	<=1 ;
		inf.out_info	<=0	;
	end
end

endmodule