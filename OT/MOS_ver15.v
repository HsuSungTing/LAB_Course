module MOS(
  // Input Port
  rst_n, clk, 
  matrix_size,
  in_valid,
  in_data,
    
    
  // Output Port
  out_valid,
  out_data
);

integer i,j,k;

input rst_n, clk, matrix_size,in_valid;
input signed[15:0] in_data;
output reg                  out_valid;
output reg signed[39:0]      out_data;


//Part 1 FSM (& FSM Tag)
reg [3:0] cur_state,next_state;
parameter IDLE=4'd0,INPUT=4'd1,EVAL=4'd2, OUTPUT=4'd3, CLEAR=4'd4;

reg EVAL_done;                      //FSM tag
reg [7:0] input_cnt;
reg [4:0] output_cnt;    
reg [5:0] global_cnt;  
reg matrix_size_q;                  //input

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) cur_state<=IDLE;
    else cur_state<=next_state;
end

//Part 1 FSM (&FSM reg)
always@(*)begin
    case (cur_state)
        IDLE: begin
            if(in_valid==1'b1) next_state=INPUT;
            else next_state=IDLE;
        end
        INPUT: begin
            if(input_cnt>=31 && matrix_size_q==0) next_state= EVAL;
            else if(input_cnt>=127 && matrix_size_q==1) next_state= EVAL;
            else next_state=INPUT;
        end
        EVAL: begin
            if(global_cnt>=19) next_state=OUTPUT;
            else next_state=EVAL;
        end
        OUTPUT: begin
            if(output_cnt>=6 && matrix_size_q==0) next_state=CLEAR; 
            else if(output_cnt>=14&&matrix_size_q==1) next_state=CLEAR;     
            else next_state=OUTPUT;
        end
        CLEAR: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

//Part 2 Comb Logic
reg [2:0] pool_size;  //3 for 4X4, 7 for 8X8
always@(*)begin
  if(matrix_size_q==0) pool_size=3'd3;
  else pool_size=3'd7;
end

//Part 3 Seq Logic (for input)
reg signed [15:0] A_in [1:8][1:8];
reg signed [15:0] B_in [1:8][1:8];
reg [3:0] in_row, in_col;

always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    in_row<=4'd0; in_col<=4'd0; input_cnt<=6'd0; matrix_size_q<=0;
    for(i=1;i<9;i=i+1)begin
      for(j=1;j<9;j=j+1)begin
        A_in[i][j]<=16'd0;  B_in[i][j]<=16'd0;
      end
    end
  end
  else if(in_valid==1'b1)begin
    input_cnt<=input_cnt+1;
    //===take matrix_size_q===
    if(input_cnt==0) matrix_size_q<=matrix_size;
    else matrix_size_q<=matrix_size_q;
    //update in_col in_row for A_in & B_in
    if(in_col==pool_size)begin
      in_row<=in_row+1; in_col<=0;
    end
    else begin
      in_row<=in_row; in_col<=in_col+1;
    end

    if(input_cnt<=15 && matrix_size_q==0)begin    
      A_in[in_row+1][in_col+1]<=in_data;
    end
    else if(input_cnt<=63 && matrix_size_q==1)begin    
      A_in[in_row+1][in_col+1]<=in_data;
    end
    else if(input_cnt>=16 && input_cnt<=31 && matrix_size_q==0)begin
      B_in[in_row+1-4][in_col+1]<=in_data;
    end
    else if(input_cnt>=64 && input_cnt<=127 && matrix_size_q==1)begin
      B_in[in_row+1-8][in_col+1]<=in_data;
    end

  end
  else if(cur_state==CLEAR)begin
    in_row<=2'd0; in_col<=2'd0; input_cnt<=6'd0; matrix_size_q<=0;
    for(i=1;i<9;i=i+1)begin
      for(j=1;j<9;j=j+1)begin
        A_in[i][j]<=16'd0;  B_in[i][j]<=16'd0;
      end
    end
  end
end

//Part 2 Comb Logic 
reg signed [15:0] A_row [0:7] [0:14]; 
reg signed [15:0] B_row [0:7] [0:14]; 

always@(*)begin
  if(cur_state!=CLEAR)begin
    A_row[0][0]=A_in[1][1]; 
    A_row[0][1]=A_in[1][2];
    A_row[0][2]=A_in[1][3];
    A_row[0][3]=A_in[1][4];
    A_row[0][4]=A_in[1][5];
    A_row[0][5]=A_in[1][6];
    A_row[0][6]=A_in[1][7];
    A_row[0][7]=A_in[1][8];
    A_row[0][8]=16'd0;
    A_row[0][9]=16'd0;
    A_row[0][10]=16'd0;
    A_row[0][11]=16'd0;
    A_row[0][12]=16'd0;
    A_row[0][13]=16'd0;
    A_row[0][14]=16'd0;

    A_row[1][0]=16'd0; 
    A_row[1][1]=A_in[2][1];
    A_row[1][2]=A_in[2][2];
    A_row[1][3]=A_in[2][3];
    A_row[1][4]=A_in[2][4];
    A_row[1][5]=A_in[2][5];
    A_row[1][6]=A_in[2][6];
    A_row[1][7]=A_in[2][7];
    A_row[1][8]=A_in[2][8];
    A_row[1][9]=16'd0;
    A_row[1][10]=16'd0;
    A_row[1][11]=16'd0;
    A_row[1][12]=16'd0;
    A_row[1][13]=16'd0;
    A_row[1][14]=16'd0;

    A_row[2][0]=16'd0; 
    A_row[2][1]=16'd0; 
    A_row[2][2]=A_in[3][1];
    A_row[2][3]=A_in[3][2];
    A_row[2][4]=A_in[3][3];
    A_row[2][5]=A_in[3][4];
    A_row[2][6]=A_in[3][5];
    A_row[2][7]=A_in[3][6];
    A_row[2][8]=A_in[3][7];
    A_row[2][9]=A_in[3][8];
    A_row[2][10]=16'd0;
    A_row[2][11]=16'd0;
    A_row[2][12]=16'd0;
    A_row[2][13]=16'd0;
    A_row[2][14]=16'd0;

    A_row[3][0]=16'd0; 
    A_row[3][1]=16'd0; 
    A_row[3][2]=16'd0; 
    A_row[3][3]=A_in[4][1];
    A_row[3][4]=A_in[4][2];
    A_row[3][5]=A_in[4][3];
    A_row[3][6]=A_in[4][4];
    A_row[3][7]=A_in[4][5];
    A_row[3][8]=A_in[4][6];
    A_row[3][9]=A_in[4][7];
    A_row[3][10]=A_in[4][8];
    A_row[3][11]=16'd0;
    A_row[3][12]=16'd0;
    A_row[3][13]=16'd0;
    A_row[3][14]=16'd0;

    A_row[4][0]=16'd0;
    A_row[4][1]=16'd0;
    A_row[4][2]=16'd0;
    A_row[4][3]=16'd0;
    A_row[4][4]=A_in[5][1];
    A_row[4][5]=A_in[5][2];
    A_row[4][6]=A_in[5][3];
    A_row[4][7]=A_in[5][4];
    A_row[4][8]=A_in[5][5];
    A_row[4][9]=A_in[5][6];
    A_row[4][10]=A_in[5][7];
    A_row[4][11]=A_in[5][8];
    A_row[4][12]=16'd0;
    A_row[4][13]=16'd0;
    A_row[4][14]=16'd0;

    A_row[5][0]=16'd0;
    A_row[5][1]=16'd0;
    A_row[5][2]=16'd0;
    A_row[5][3]=16'd0;
    A_row[5][4]=16'd0;
    A_row[5][5]=A_in[6][1];
    A_row[5][6]=A_in[6][2];
    A_row[5][7]=A_in[6][3];
    A_row[5][8]=A_in[6][4];
    A_row[5][9]=A_in[6][5];
    A_row[5][10]=A_in[6][6];
    A_row[5][11]=A_in[6][7];
    A_row[5][12]=A_in[6][8];
    A_row[5][13]=16'd0;
    A_row[5][14]=16'd0;

    A_row[6][0]=16'd0;
    A_row[6][1]=16'd0;
    A_row[6][2]=16'd0;
    A_row[6][3]=16'd0;
    A_row[6][4]=16'd0;
    A_row[6][5]=16'd0;
    A_row[6][6]=A_in[7][1];
    A_row[6][7]=A_in[7][2];
    A_row[6][8]=A_in[7][3];
    A_row[6][9]=A_in[7][4];
    A_row[6][10]=A_in[7][5];
    A_row[6][11]=A_in[7][6];
    A_row[6][12]=A_in[7][7];
    A_row[6][13]=A_in[7][8];
    A_row[6][14]=16'd0;

    A_row[7][0]=16'd0;
    A_row[7][1]=16'd0;
    A_row[7][2]=16'd0;
    A_row[7][3]=16'd0;
    A_row[7][4]=16'd0;
    A_row[7][5]=16'd0;
    A_row[7][6]=16'd0;
    A_row[7][7]=A_in[8][1];
    A_row[7][8]=A_in[8][2];
    A_row[7][9]=A_in[8][3];
    A_row[7][10]=A_in[8][4];
    A_row[7][11]=A_in[8][5];
    A_row[7][12]=A_in[8][6];
    A_row[7][13]=A_in[8][7];
    A_row[7][14]=A_in[8][8];

    B_row[0][0]=B_in[1][1]; 
    B_row[0][1]=B_in[2][1];
    B_row[0][2]=B_in[3][1];
    B_row[0][3]=B_in[4][1];
    B_row[0][4]=B_in[5][1]; 
    B_row[0][5]=B_in[6][1]; 
    B_row[0][6]=B_in[7][1]; 
    B_row[0][7]=B_in[8][1]; 
    B_row[0][8]=16'd0;
    B_row[0][9]=16'd0;
    B_row[0][10]=16'd0;
    B_row[0][11]=16'd0;
    B_row[0][12]=16'd0;
    B_row[0][13]=16'd0;
    B_row[0][14]=16'd0;

    B_row[1][0]=16'd0;
    B_row[1][1]=B_in[1][2]; 
    B_row[1][2]=B_in[2][2];
    B_row[1][3]=B_in[3][2];
    B_row[1][4]=B_in[4][2];
    B_row[1][5]=B_in[5][2]; 
    B_row[1][6]=B_in[6][2]; 
    B_row[1][7]=B_in[7][2]; 
    B_row[1][8]=B_in[8][2]; 
    B_row[1][9]=16'd0;
    B_row[1][10]=16'd0;
    B_row[1][11]=16'd0;
    B_row[1][12]=16'd0;
    B_row[1][13]=16'd0;
    B_row[1][14]=16'd0;

    B_row[2][0]=16'd0;
    B_row[2][1]=16'd0;
    B_row[2][2]=B_in[1][3];
    B_row[2][3]=B_in[2][3];
    B_row[2][4]=B_in[3][3];
    B_row[2][5]=B_in[4][3]; 
    B_row[2][6]=B_in[5][3]; 
    B_row[2][7]=B_in[6][3]; 
    B_row[2][8]=B_in[7][3]; 
    B_row[2][9]=B_in[8][3];
    B_row[2][10]=16'd0;
    B_row[2][11]=16'd0;
    B_row[2][12]=16'd0;
    B_row[2][13]=16'd0;
    B_row[2][14]=16'd0;

    B_row[3][0]=16'd0;
    B_row[3][1]=16'd0;
    B_row[3][2]=16'd0;
    B_row[3][3]=B_in[1][4];
    B_row[3][4]=B_in[2][4];
    B_row[3][5]=B_in[3][4];
    B_row[3][6]=B_in[4][4];
    B_row[3][7]=B_in[5][4];
    B_row[3][8]=B_in[6][4];
    B_row[3][9]=B_in[7][4];
    B_row[3][10]=B_in[8][4];
    B_row[3][11]=16'd0;
    B_row[3][12]=16'd0;
    B_row[3][13]=16'd0;
    B_row[3][14]=16'd0;

    B_row[4][0]=16'd0;
    B_row[4][1]=16'd0;
    B_row[4][2]=16'd0;
    B_row[4][3]=16'd0;
    B_row[4][4]=B_in[1][5];
    B_row[4][5]=B_in[2][5];
    B_row[4][6]=B_in[3][5];
    B_row[4][7]=B_in[4][5];
    B_row[4][8]=B_in[5][5];
    B_row[4][9]=B_in[6][5];
    B_row[4][10]=B_in[7][5];
    B_row[4][11]=B_in[8][5];
    B_row[4][12]=16'd0;
    B_row[4][13]=16'd0;
    B_row[4][14]=16'd0;

    B_row[5][0]=16'd0;
    B_row[5][1]=16'd0;
    B_row[5][2]=16'd0;
    B_row[5][3]=16'd0;
    B_row[5][4]=16'd0;
    B_row[5][5]=B_in[1][6];
    B_row[5][6]=B_in[2][6];
    B_row[5][7]=B_in[3][6];
    B_row[5][8]=B_in[4][6];
    B_row[5][9]=B_in[5][6];
    B_row[5][10]=B_in[6][6];
    B_row[5][11]=B_in[7][6];
    B_row[5][12]=B_in[8][6];
    B_row[5][13]=16'd0;
    B_row[5][14]=16'd0;

    B_row[6][0]=16'd0;
    B_row[6][1]=16'd0;
    B_row[6][2]=16'd0;
    B_row[6][3]=16'd0;
    B_row[6][4]=16'd0;
    B_row[6][5]=16'd0;
    B_row[6][6]=B_in[1][7];
    B_row[6][7]=B_in[2][7];
    B_row[6][8]=B_in[3][7];
    B_row[6][9]=B_in[4][7];
    B_row[6][10]=B_in[5][7];
    B_row[6][11]=B_in[6][7];
    B_row[6][12]=B_in[7][7];
    B_row[6][13]=B_in[8][7];
    B_row[6][14]=16'd0;

    B_row[7][0]=16'd0;
    B_row[7][1]=16'd0;
    B_row[7][2]=16'd0;
    B_row[7][3]=16'd0;
    B_row[7][4]=16'd0;
    B_row[7][5]=16'd0;
    B_row[7][6]=16'd0;
    B_row[7][7]=B_in[1][8];
    B_row[7][8]=B_in[2][8];
    B_row[7][9]=B_in[3][8];
    B_row[7][10]=B_in[4][8];
    B_row[7][11]=B_in[5][8];
    B_row[7][12]=B_in[6][8];
    B_row[7][13]=B_in[7][8];
    B_row[7][14]=B_in[8][8];
  end
  else begin
    for(i=0;i<8;i=i+1)begin
      for(j=0;j<15;j=j+1)begin
        A_row[i][j]=16'd0; B_row[i][j]=16'd0;
      end
    end
  end
end

//8x8 PE
reg signed [32:0] last_mul_result[0:7][0:7];
reg signed [39:0] cur_sum[0:7][0:7];

//Part 2 Comb Logic
reg signed [15:0] a_in [0:7][0:7];
reg signed [15:0] b_in [0:7][0:7];
wire signed [32:0] mul_out [0:7][0:7];
wire signed [39:0] pe_sum_out [0:7][0:7];

genvar mul_i, mul_j;

generate
  for(mul_i = 0; mul_i < 8; mul_i = mul_i + 1) begin : mul_i_block
    for(mul_j = 0; mul_j < 8; mul_j = mul_j + 1) begin : mul_j_block
      Comb_MUL mul_inst (
        .a_in(a_in[mul_i][mul_j]),
        .b_in(b_in[mul_i][mul_j]),
        .mul_out(mul_out[mul_i][mul_j])
      );
      Comb_ADD add_inst (
        .a_in(last_mul_result[mul_i][mul_j]),
        .b_in(cur_sum[mul_i][mul_j]),
        .sum_out(pe_sum_out[mul_i][mul_j])
      );
    end
  end
endgenerate

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    global_cnt<=5'd0; 
  end
  else if(cur_state==CLEAR)begin
    global_cnt<=5'd0; 
  end
  else if(((input_cnt>=27&&matrix_size_q==0)||(input_cnt>=121&&matrix_size_q==1)))begin
    global_cnt<=global_cnt+1; 
  end
end

//Part 2 Comb Logic
always@(*)begin
  // a_in[][0] to a_in[][7]
  if(global_cnt<=14) begin
      a_in[0][0]=A_row[0][global_cnt]; 
      a_in[1][0]=A_row[1][global_cnt]; 
      a_in[2][0]=A_row[2][global_cnt]; 
      a_in[3][0]=A_row[3][global_cnt];
      a_in[4][0]=A_row[4][global_cnt]; 
      a_in[5][0]=A_row[5][global_cnt]; 
      a_in[6][0]=A_row[6][global_cnt]; 
      a_in[7][0]=A_row[7][global_cnt];
  end else begin
      a_in[0][0]=16'd0; a_in[1][0]=16'd0; a_in[2][0]=16'd0; a_in[3][0]=16'd0;
      a_in[4][0]=16'd0; a_in[5][0]=16'd0; a_in[6][0]=16'd0; a_in[7][0]=16'd0;
  end

  if(global_cnt>=1 && global_cnt<=15) begin
      a_in[0][1]=A_row[0][global_cnt-1]; 
      a_in[1][1]=A_row[1][global_cnt-1];
      a_in[2][1]=A_row[2][global_cnt-1]; 
      a_in[3][1]=A_row[3][global_cnt-1];
      a_in[4][1]=A_row[4][global_cnt-1]; 
      a_in[5][1]=A_row[5][global_cnt-1];
      a_in[6][1]=A_row[6][global_cnt-1]; 
      a_in[7][1]=A_row[7][global_cnt-1];
  end else begin
      a_in[0][1]=16'd0; a_in[1][1]=16'd0; a_in[2][1]=16'd0; a_in[3][1]=16'd0;
      a_in[4][1]=16'd0; a_in[5][1]=16'd0; a_in[6][1]=16'd0; a_in[7][1]=16'd0;
  end

  if(global_cnt>=2 && global_cnt<=16) begin
      a_in[0][2]=A_row[0][global_cnt-2]; 
      a_in[1][2]=A_row[1][global_cnt-2];
      a_in[2][2]=A_row[2][global_cnt-2]; 
      a_in[3][2]=A_row[3][global_cnt-2];
      a_in[4][2]=A_row[4][global_cnt-2]; 
      a_in[5][2]=A_row[5][global_cnt-2];
      a_in[6][2]=A_row[6][global_cnt-2]; 
      a_in[7][2]=A_row[7][global_cnt-2];
  end else begin
      a_in[0][2]=16'd0; a_in[1][2]=16'd0; a_in[2][2]=16'd0; a_in[3][2]=16'd0;
      a_in[4][2]=16'd0; a_in[5][2]=16'd0; a_in[6][2]=16'd0; a_in[7][2]=16'd0;
  end

  if(global_cnt>=3 && global_cnt<=17) begin
      a_in[0][3]=A_row[0][global_cnt-3];
      a_in[1][3]=A_row[1][global_cnt-3];
      a_in[2][3]=A_row[2][global_cnt-3]; 
      a_in[3][3]=A_row[3][global_cnt-3];
      a_in[4][3]=A_row[4][global_cnt-3]; 
      a_in[5][3]=A_row[5][global_cnt-3];
      a_in[6][3]=A_row[6][global_cnt-3]; 
      a_in[7][3]=A_row[7][global_cnt-3];
  end else begin
      a_in[0][3]=16'd0; a_in[1][3]=16'd0; a_in[2][3]=16'd0; a_in[3][3]=16'd0;
      a_in[4][3]=16'd0; a_in[5][3]=16'd0; a_in[6][3]=16'd0; a_in[7][3]=16'd0;
  end

  if(global_cnt>=4 && global_cnt<=18) begin
      a_in[0][4]=A_row[0][global_cnt-4]; 
      a_in[1][4]=A_row[1][global_cnt-4]; 
      a_in[2][4]=A_row[2][global_cnt-4]; 
      a_in[3][4]=A_row[3][global_cnt-4]; 
      a_in[4][4]=A_row[4][global_cnt-4]; 
      a_in[5][4]=A_row[5][global_cnt-4]; 
      a_in[6][4]=A_row[6][global_cnt-4]; 
      a_in[7][4]=A_row[7][global_cnt-4]; 
  end else begin
      a_in[0][4]=16'd0; a_in[1][4]=16'd0; a_in[2][4]=16'd0; a_in[3][4]=16'd0;
      a_in[4][4]=16'd0; a_in[5][4]=16'd0; a_in[6][4]=16'd0; a_in[7][4]=16'd0;
  end

  if(global_cnt>=5 && global_cnt<=19) begin
      a_in[0][5]=A_row[0][global_cnt-5]; 
      a_in[1][5]=A_row[1][global_cnt-5]; 
      a_in[2][5]=A_row[2][global_cnt-5]; 
      a_in[3][5]=A_row[3][global_cnt-5]; 
      a_in[4][5]=A_row[4][global_cnt-5]; 
      a_in[5][5]=A_row[5][global_cnt-5]; 
      a_in[6][5]=A_row[6][global_cnt-5]; 
      a_in[7][5]=A_row[7][global_cnt-5]; 
  end else begin
      a_in[0][5]=16'd0; a_in[1][5]=16'd0; a_in[2][5]=16'd0; a_in[3][5]=16'd0;
      a_in[4][5]=16'd0; a_in[5][5]=16'd0; a_in[6][5]=16'd0; a_in[7][5]=16'd0;
  end

  if(global_cnt>=6 && global_cnt<=20) begin
      a_in[0][6]=A_row[0][global_cnt-6]; 
      a_in[1][6]=A_row[1][global_cnt-6]; 
      a_in[2][6]=A_row[2][global_cnt-6]; 
      a_in[3][6]=A_row[3][global_cnt-6]; 
      a_in[4][6]=A_row[4][global_cnt-6]; 
      a_in[5][6]=A_row[5][global_cnt-6]; 
      a_in[6][6]=A_row[6][global_cnt-6]; 
      a_in[7][6]=A_row[7][global_cnt-6]; 
  end else begin
      a_in[0][6]=16'd0; a_in[1][6]=16'd0; a_in[2][6]=16'd0; a_in[3][6]=16'd0;
      a_in[4][6]=16'd0; a_in[5][6]=16'd0; a_in[6][6]=16'd0; a_in[7][6]=16'd0;
  end

  if(global_cnt>=7 && global_cnt<=21) begin
      a_in[0][7]=A_row[0][global_cnt-7]; 
      a_in[1][7]=A_row[1][global_cnt-7]; 
      a_in[2][7]=A_row[2][global_cnt-7]; 
      a_in[3][7]=A_row[3][global_cnt-7]; 
      a_in[4][7]=A_row[4][global_cnt-7]; 
      a_in[5][7]=A_row[5][global_cnt-7]; 
      a_in[6][7]=A_row[6][global_cnt-7]; 
      a_in[7][7]=A_row[7][global_cnt-7]; 
  end else begin
      a_in[0][7]=16'd0; a_in[1][7]=16'd0; a_in[2][7]=16'd0; a_in[3][7]=16'd0;
      a_in[4][7]=16'd0; a_in[5][7]=16'd0; a_in[6][7]=16'd0; a_in[7][7]=16'd0;
  end
end

always@(*)begin
  // b_in[][0] to b_in[][7]
  if(global_cnt>=0 && global_cnt<=14) begin
      b_in[0][0]=B_row[0][global_cnt]; b_in[0][1]=B_row[1][global_cnt]; 
      b_in[0][2]=B_row[2][global_cnt]; b_in[0][3]=B_row[3][global_cnt];
      b_in[0][4]=B_row[4][global_cnt]; b_in[0][5]=B_row[5][global_cnt];
      b_in[0][6]=B_row[6][global_cnt]; b_in[0][7]=B_row[7][global_cnt];
  end else begin
      b_in[0][0]=16'd0; b_in[0][1]=16'd0; b_in[0][2]=16'd0; b_in[0][3]=16'd0;
      b_in[0][4]=16'd0; b_in[0][5]=16'd0; b_in[0][6]=16'd0; b_in[0][7]=16'd0;
  end

  if(global_cnt>=1 && global_cnt<=15) begin
      b_in[1][0]=B_row[0][global_cnt-1]; b_in[1][1]=B_row[1][global_cnt-1]; 
      b_in[1][2]=B_row[2][global_cnt-1]; b_in[1][3]=B_row[3][global_cnt-1];
      b_in[1][4]=B_row[4][global_cnt-1]; b_in[1][5]=B_row[5][global_cnt-1];
      b_in[1][6]=B_row[6][global_cnt-1]; b_in[1][7]=B_row[7][global_cnt-1];
  end else begin
      b_in[1][0]=16'd0; b_in[1][1]=16'd0; b_in[1][2]=16'd0; b_in[1][3]=16'd0;
      b_in[1][4]=16'd0; b_in[1][5]=16'd0; b_in[1][6]=16'd0; b_in[1][7]=16'd0;
  end

  if(global_cnt>=2 && global_cnt<=16) begin
      b_in[2][0]=B_row[0][global_cnt-2]; b_in[2][1]=B_row[1][global_cnt-2]; 
      b_in[2][2]=B_row[2][global_cnt-2]; b_in[2][3]=B_row[3][global_cnt-2];
      b_in[2][4]=B_row[4][global_cnt-2]; b_in[2][5]=B_row[5][global_cnt-2];
      b_in[2][6]=B_row[6][global_cnt-2]; b_in[2][7]=B_row[7][global_cnt-2];
  end else begin
      b_in[2][0]=16'd0; b_in[2][1]=16'd0; b_in[2][2]=16'd0; b_in[2][3]=16'd0;
      b_in[2][4]=16'd0; b_in[2][5]=16'd0; b_in[2][6]=16'd0; b_in[2][7]=16'd0;
  end

  if(global_cnt>=3 && global_cnt<=17) begin
      b_in[3][0]=B_row[0][global_cnt-3]; b_in[3][1]=B_row[1][global_cnt-3]; 
      b_in[3][2]=B_row[2][global_cnt-3]; b_in[3][3]=B_row[3][global_cnt-3];
      b_in[3][4]=B_row[4][global_cnt-3]; b_in[3][5]=B_row[5][global_cnt-3];
      b_in[3][6]=B_row[6][global_cnt-3]; b_in[3][7]=B_row[7][global_cnt-3];
  end else begin
      b_in[3][0]=16'd0; b_in[3][1]=16'd0; b_in[3][2]=16'd0; b_in[3][3]=16'd0;
      b_in[3][4]=16'd0; b_in[3][5]=16'd0; b_in[3][6]=16'd0; b_in[3][7]=16'd0;
  end

  if(global_cnt>=4 && global_cnt<=18) begin
      b_in[4][0]=B_row[0][global_cnt-4]; b_in[4][1]=B_row[1][global_cnt-4]; 
      b_in[4][2]=B_row[2][global_cnt-4]; b_in[4][3]=B_row[3][global_cnt-4];
      b_in[4][4]=B_row[4][global_cnt-4]; b_in[4][5]=B_row[5][global_cnt-4];
      b_in[4][6]=B_row[6][global_cnt-4]; b_in[4][7]=B_row[7][global_cnt-4];
  end else begin
      b_in[4][0]=16'd0; b_in[4][1]=16'd0; b_in[4][2]=16'd0; b_in[4][3]=16'd0;
      b_in[4][4]=16'd0; b_in[4][5]=16'd0; b_in[4][6]=16'd0; b_in[4][7]=16'd0;
  end

  if(global_cnt>=5 && global_cnt<=19) begin
      b_in[5][0]=B_row[0][global_cnt-5]; b_in[5][1]=B_row[1][global_cnt-5]; 
      b_in[5][2]=B_row[2][global_cnt-5]; b_in[5][3]=B_row[3][global_cnt-5];
      b_in[5][4]=B_row[4][global_cnt-5]; b_in[5][5]=B_row[5][global_cnt-5];
      b_in[5][6]=B_row[6][global_cnt-5]; b_in[5][7]=B_row[7][global_cnt-5];
  end else begin
      b_in[5][0]=16'd0; b_in[5][1]=16'd0; b_in[5][2]=16'd0; b_in[5][3]=16'd0;
      b_in[5][4]=16'd0; b_in[5][5]=16'd0; b_in[5][6]=16'd0; b_in[5][7]=16'd0;
  end

  if(global_cnt>=6 && global_cnt<=20) begin
      b_in[6][0]=B_row[0][global_cnt-6]; b_in[6][1]=B_row[1][global_cnt-6]; 
      b_in[6][2]=B_row[2][global_cnt-6]; b_in[6][3]=B_row[3][global_cnt-6];
      b_in[6][4]=B_row[4][global_cnt-6]; b_in[6][5]=B_row[5][global_cnt-6];
      b_in[6][6]=B_row[6][global_cnt-6]; b_in[6][7]=B_row[7][global_cnt-6];
  end else begin
      b_in[6][0]=16'd0; b_in[6][1]=16'd0; b_in[6][2]=16'd0; b_in[6][3]=16'd0;
      b_in[6][4]=16'd0; b_in[6][5]=16'd0; b_in[6][6]=16'd0; b_in[6][7]=16'd0;
  end

  if(global_cnt>=7 && global_cnt<=21) begin
      b_in[7][0]=B_row[0][global_cnt-7]; b_in[7][1]=B_row[1][global_cnt-7]; 
      b_in[7][2]=B_row[2][global_cnt-7]; b_in[7][3]=B_row[3][global_cnt-7];
      b_in[7][4]=B_row[4][global_cnt-7]; b_in[7][5]=B_row[5][global_cnt-7];
      b_in[7][6]=B_row[6][global_cnt-7]; b_in[7][7]=B_row[7][global_cnt-7];
  end else begin
      b_in[7][0]=16'd0; b_in[7][1]=16'd0; b_in[7][2]=16'd0; b_in[7][3]=16'd0;
      b_in[7][4]=16'd0; b_in[7][5]=16'd0; b_in[7][6]=16'd0; b_in[7][7]=16'd0;
  end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    for(i=0;i<8;i=i+1)begin
      for(j=0;j<8;j=j+1)begin
        last_mul_result [i][j]<=40'd0;   
      end
    end 
  end
  else if(((input_cnt>=27&&matrix_size_q==0)||(input_cnt>=121&&matrix_size_q==1)))begin
    if(global_cnt>=0&&global_cnt<=21)begin
      for(i=0;i<8;i=i+1)begin
        for(j=0;j<8;j=j+1)begin
          last_mul_result [i][j]<=mul_out[i][j];  
        end
      end 
    end
  end
  else if(cur_state==CLEAR)begin
    for(i=0;i<8;i=i+1)begin
      for(j=0;j<8;j=j+1)begin
        last_mul_result [i][j]<=40'd0;          
      end
    end 
  end
end

//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    for(i=0;i<8;i=i+1)begin
      for(j=0;j<8;j=j+1)begin
        cur_sum [i][j]<=40'd0;   
      end
    end 
  end
  else if(((input_cnt>=27&&matrix_size_q==0)||(input_cnt>=121&&matrix_size_q==1)) && global_cnt<=22)begin
    if(global_cnt>=1&&global_cnt<=22)begin
      for(i=0;i<8;i=i+1)begin
        for(j=0;j<8;j=j+1)begin
          cur_sum [i][j]<=pe_sum_out[i][j];  
        end
      end 
    end
  end
  else if(cur_state==CLEAR)begin
    for(i=0;i<8;i=i+1)begin
      for(j=0;j<8;j=j+1)begin
        cur_sum [i][j]<=40'd0;          
      end
    end 
  end
end

//Part 2 Comb Logic
reg signed [39:0] in_1 [1:13];
reg signed [39:0] in_2 [1:13];
reg signed [39:0] sum2_out [1:13];
sum2 sum2_inst_1 (.in_1(in_1[1]),  .in_2(in_2[1]),  .sum2_out(sum2_out[1]));
sum2 sum2_inst_2 (.in_1(in_1[2]),  .in_2(in_2[2]),  .sum2_out(sum2_out[2]));
sum2 sum2_inst_3 (.in_1(in_1[3]),  .in_2(in_2[3]),  .sum2_out(sum2_out[3]));
sum2 sum2_inst_4 (.in_1(in_1[4]),  .in_2(in_2[4]),  .sum2_out(sum2_out[4]));
sum2 sum2_inst_5 (.in_1(in_1[5]),  .in_2(in_2[5]),  .sum2_out(sum2_out[5]));
sum2 sum2_inst_6 (.in_1(in_1[6]),  .in_2(in_2[6]),  .sum2_out(sum2_out[6]));
sum2 sum2_inst_7 (.in_1(in_1[7]),  .in_2(in_2[7]),  .sum2_out(sum2_out[7]));
sum2 sum2_inst_8 (.in_1(in_1[8]),  .in_2(in_2[8]),  .sum2_out(sum2_out[8]));
sum2 sum2_inst_9 (.in_1(in_1[9]),  .in_2(in_2[9]),  .sum2_out(sum2_out[9]));
sum2 sum2_inst_10(.in_1(in_1[10]), .in_2(in_2[10]), .sum2_out(sum2_out[10]));
sum2 sum2_inst_11(.in_1(in_1[11]), .in_2(in_2[11]), .sum2_out(sum2_out[11]));
sum2 sum2_inst_12(.in_1(in_1[12]), .in_2(in_2[12]), .sum2_out(sum2_out[12]));
sum2 sum2_inst_13(.in_1(in_1[13]), .in_2(in_2[13]), .sum2_out(sum2_out[13]));

always@(*)begin
  // [1]
  if(global_cnt==10)begin 
    in_1[1]=0;                in_2[1]=cur_sum[0][1];
  end
  else if(global_cnt==11)begin 
    in_1[1]=diagnal_sum[1];   in_2[1]=cur_sum[1][0];
  end 
  else begin 
    in_1[1]=0;                in_2[1]=0;
  end

  // [2]
  if(global_cnt==11)begin 
    in_1[2]=0;                in_2[2]=cur_sum[0][2];
  end
  else if(global_cnt==12)begin 
    in_1[2]=diagnal_sum[2];   in_2[2]=cur_sum[1][1];
  end 
  else if(global_cnt==13)begin 
    in_1[2]=diagnal_sum[2];   in_2[2]=cur_sum[2][0];
  end 
  else begin 
    in_1[2]=0;                in_2[2]=0;
  end

  // [3]
  if(global_cnt==12)begin 
    in_1[3]=0;                in_2[3]=cur_sum[0][3];
  end
  else if(global_cnt==13)begin 
    in_1[3]=diagnal_sum[3];   in_2[3]=cur_sum[1][2];
  end 
  else if(global_cnt==14)begin 
    in_1[3]=diagnal_sum[3];   in_2[3]=cur_sum[2][1];
  end 
  else if(global_cnt==15)begin 
    in_1[3]=diagnal_sum[3];   in_2[3]=cur_sum[3][0];
  end 
  else begin 
    in_1[3]=0;                in_2[3]=0;
  end

  // [4]
  if(global_cnt==13)begin 
    in_1[4]=0;                in_2[4]=cur_sum[0][4];
  end
  else if(global_cnt==14)begin 
    in_1[4]=diagnal_sum[4];   in_2[4]=cur_sum[1][3];
  end 
  else if(global_cnt==15)begin 
    in_1[4]=diagnal_sum[4];   in_2[4]=cur_sum[2][2];
  end 
  else if(global_cnt==16)begin 
    in_1[4]=diagnal_sum[4];   in_2[4]=cur_sum[3][1];
  end 
  else if(global_cnt==17)begin 
    in_1[4]=diagnal_sum[4];   in_2[4]=cur_sum[4][0];
  end 
  else begin 
    in_1[4]=0;                in_2[4]=0;
  end

  // [5]
  if(global_cnt==14)begin 
    in_1[5]=0;                in_2[5]=cur_sum[0][5];
  end
  else if(global_cnt==15)begin 
    in_1[5]=diagnal_sum[5];   in_2[5]=cur_sum[1][4];
  end 
  else if(global_cnt==16)begin 
    in_1[5]=diagnal_sum[5];   in_2[5]=cur_sum[2][3];
  end 
  else if(global_cnt==17)begin 
    in_1[5]=diagnal_sum[5];   in_2[5]=cur_sum[3][2];
  end 
  else if(global_cnt==18)begin 
    in_1[5]=diagnal_sum[5];   in_2[5]=cur_sum[4][1];
  end 
  else if(global_cnt==19)begin 
    in_1[5]=diagnal_sum[5];   in_2[5]=cur_sum[5][0];
  end 
  else begin 
    in_1[5]=0;                in_2[5]=0;
  end

  // [6]
  if(global_cnt==15)begin 
    in_1[6]=0;                in_2[6]=cur_sum[0][6];
  end
  else if(global_cnt==16)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[1][5];
  end 
  else if(global_cnt==17)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[2][4];
  end 
  else if(global_cnt==18)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[3][3];
  end 
  else if(global_cnt==19)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[4][2];
  end 
  else if(global_cnt==20)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[5][1];
  end 
  else if(global_cnt==21)begin 
    in_1[6]=diagnal_sum[6];   in_2[6]=cur_sum[6][0];
  end 
  else begin 
    in_1[6]=0;                in_2[6]=0;
  end

  // [7]
  if(global_cnt==16)begin 
    in_1[7]=0;                in_2[7]=cur_sum[0][7];
  end
  else if(global_cnt==17)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[1][6];
  end 
  else if(global_cnt==18)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[2][5];
  end 
  else if(global_cnt==19)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[3][4];
  end 
  else if(global_cnt==20)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[4][3];
  end 
  else if(global_cnt==21)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[5][2];
  end 
  else if(global_cnt==22)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[6][1];
  end 
  else if(global_cnt==23)begin 
    in_1[7]=diagnal_sum[7];   in_2[7]=cur_sum[7][0];
  end 
  else begin 
    in_1[7]=0;                in_2[7]=0;
  end

  // [8]
  if(global_cnt==17)begin 
    in_1[8]=0;                in_2[8]=cur_sum[1][7];
  end
  else if(global_cnt==18)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[2][6];
  end 
  else if(global_cnt==19)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[3][5];
  end 
  else if(global_cnt==20)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[4][4];
  end 
  else if(global_cnt==21)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[5][3];
  end 
  else if(global_cnt==22)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[6][2];
  end 
  else if(global_cnt==23)begin 
    in_1[8]=diagnal_sum[8];   in_2[8]=cur_sum[7][1];
  end 
  else begin 
    in_1[8]=0;                in_2[8]=0;
  end

  // [9]
  if(global_cnt==18)begin 
    in_1[9]=0;                in_2[9]=cur_sum[2][7];
  end
  else if(global_cnt==19)begin 
    in_1[9]=diagnal_sum[9];   in_2[9]=cur_sum[3][6];
  end 
  else if(global_cnt==20)begin 
    in_1[9]=diagnal_sum[9];   in_2[9]=cur_sum[4][5];
  end 
  else if(global_cnt==21)begin 
    in_1[9]=diagnal_sum[9];   in_2[9]=cur_sum[5][4];
  end 
  else if(global_cnt==22)begin 
    in_1[9]=diagnal_sum[9];   in_2[9]=cur_sum[6][3];
  end 
  else if(global_cnt==23)begin 
    in_1[9]=diagnal_sum[9];   in_2[9]=cur_sum[7][2];
  end 
  else begin 
    in_1[9]=0;                in_2[9]=0;
  end

  // [10]
  if(global_cnt==19)begin 
    in_1[10]=0;               in_2[10]=cur_sum[3][7];
  end
  else if(global_cnt==20)begin 
    in_1[10]=diagnal_sum[10]; in_2[10]=cur_sum[4][6];
  end 
  else if(global_cnt==21)begin 
    in_1[10]=diagnal_sum[10]; in_2[10]=cur_sum[5][5];
  end 
  else if(global_cnt==22)begin 
    in_1[10]=diagnal_sum[10]; in_2[10]=cur_sum[6][4];
  end 
  else if(global_cnt==23)begin 
    in_1[10]=diagnal_sum[10]; in_2[10]=cur_sum[7][3];
  end 
  else begin 
    in_1[10]=0;               in_2[10]=0;
  end

  // [11]
  if(global_cnt==20)begin 
    in_1[11]=0;               in_2[11]=cur_sum[4][7];
  end
  else if(global_cnt==21)begin 
    in_1[11]=diagnal_sum[11]; in_2[11]=cur_sum[5][6];
  end 
  else if(global_cnt==22)begin 
    in_1[11]=diagnal_sum[11]; in_2[11]=cur_sum[6][5];
  end 
  else if(global_cnt==23)begin 
    in_1[11]=diagnal_sum[11]; in_2[11]=cur_sum[7][4];
  end 
  else begin 
    in_1[11]=0;               in_2[11]=0;
  end

  // [12]
  if(global_cnt==21)begin 
    in_1[12]=0;               in_2[12]=cur_sum[5][7];
  end
  else if(global_cnt==22)begin 
    in_1[12]=diagnal_sum[12]; in_2[12]=cur_sum[6][6];
  end 
  else if(global_cnt==23)begin 
    in_1[12]=diagnal_sum[12]; in_2[12]=cur_sum[7][5];
  end 
  else begin 
    in_1[12]=0;               in_2[12]=0;
  end

  // [13]
  if(global_cnt==22)begin 
    in_1[13]=0;               in_2[13]=cur_sum[6][7];
  end
  else if(global_cnt==23)begin 
    in_1[13]=diagnal_sum[13]; in_2[13]=cur_sum[7][6];
  end 
  else begin 
    in_1[13]=0;               in_2[13]=0;
  end

end

//Part 3 Seq Logic 
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    for(i=0;i<15;i=i+1)begin
      diagnal_sum[i]<=40'd0;   
    end 
  end
  else if(((input_cnt>=27&&matrix_size_q==0)||(input_cnt>=121&&matrix_size_q==1)))begin
    //15 cycle
    // diagnal_sum[0]
    if(global_cnt==9) diagnal_sum[0] <= cur_sum[0][0];
    else diagnal_sum[0] <= diagnal_sum[0];

    // diagnal_sum[1]
    if(global_cnt==10) diagnal_sum[1] <= cur_sum[0][1];
    else if(global_cnt==11) diagnal_sum[1] <= sum2_out[1];
    else diagnal_sum[1] <= diagnal_sum[1];

    // diagnal_sum[2]
    if(global_cnt==11) diagnal_sum[2] <= cur_sum[0][2];
    else if(global_cnt==12) diagnal_sum[2] <= sum2_out[2];
    else if(global_cnt==13) diagnal_sum[2] <= sum2_out[2];
    else diagnal_sum[2] <= diagnal_sum[2];

    // diagnal_sum[3]
    if(global_cnt==12) diagnal_sum[3] <= cur_sum[0][3];
    else if(global_cnt==13) diagnal_sum[3] <= sum2_out[3];
    else if(global_cnt==14) diagnal_sum[3] <= sum2_out[3];
    else if(global_cnt==15) diagnal_sum[3] <= sum2_out[3];
    else diagnal_sum[3] <= diagnal_sum[3];

    // diagnal_sum[4]
    if(global_cnt==13) diagnal_sum[4] <= cur_sum[0][4];
    else if(global_cnt==14) diagnal_sum[4] <= sum2_out[4];
    else if(global_cnt==15) diagnal_sum[4] <= sum2_out[4];
    else if(global_cnt==16) diagnal_sum[4] <= sum2_out[4];
    else if(global_cnt==17) diagnal_sum[4] <= sum2_out[4];
    else diagnal_sum[4] <= diagnal_sum[4];

    // diagnal_sum[5]
    if(global_cnt==14) diagnal_sum[5] <= cur_sum[0][5];
    else if(global_cnt==15) diagnal_sum[5] <= sum2_out[5];
    else if(global_cnt==16) diagnal_sum[5] <= sum2_out[5];
    else if(global_cnt==17) diagnal_sum[5] <= sum2_out[5];
    else if(global_cnt==18) diagnal_sum[5] <= sum2_out[5];
    else if(global_cnt==19) diagnal_sum[5] <= sum2_out[5];
    else diagnal_sum[5] <= diagnal_sum[5];

    // diagnal_sum[6]
    if(global_cnt==15) diagnal_sum[6] <= cur_sum[0][6];
    else if(global_cnt==16) diagnal_sum[6] <= sum2_out[6];
    else if(global_cnt==17) diagnal_sum[6] <= sum2_out[6];
    else if(global_cnt==18) diagnal_sum[6] <= sum2_out[6];
    else if(global_cnt==19) diagnal_sum[6] <= sum2_out[6];
    else if(global_cnt==20) diagnal_sum[6] <= sum2_out[6];
    else if(global_cnt==21) diagnal_sum[6] <= sum2_out[6];
    else diagnal_sum[6] <= diagnal_sum[6];

    // diagnal_sum[7]
    if(global_cnt==16) diagnal_sum[7] <= cur_sum[0][7];
    else if(global_cnt==17) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==18) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==19) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==20) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==21) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==22) diagnal_sum[7] <= sum2_out[7];
    else if(global_cnt==23) diagnal_sum[7] <= sum2_out[7];
    else diagnal_sum[7] <= diagnal_sum[7];

    // diagnal_sum[8]
    if(global_cnt==17) diagnal_sum[8] <= cur_sum[1][7];
    else if(global_cnt==18) diagnal_sum[8] <= sum2_out[8];
    else if(global_cnt==19) diagnal_sum[8] <= sum2_out[8];
    else if(global_cnt==20) diagnal_sum[8] <= sum2_out[8];
    else if(global_cnt==21) diagnal_sum[8] <= sum2_out[8];
    else if(global_cnt==22) diagnal_sum[8] <= sum2_out[8];
    else if(global_cnt==23) diagnal_sum[8] <= sum2_out[8];
    else diagnal_sum[8] <= diagnal_sum[8];

    // diagnal_sum[9]
    if(global_cnt==18) diagnal_sum[9] <= cur_sum[2][7];
    else if(global_cnt==19) diagnal_sum[9] <= sum2_out[9];
    else if(global_cnt==20) diagnal_sum[9] <= sum2_out[9];
    else if(global_cnt==21) diagnal_sum[9] <= sum2_out[9];
    else if(global_cnt==22) diagnal_sum[9] <= sum2_out[9];
    else if(global_cnt==23) diagnal_sum[9] <= sum2_out[9];
    else diagnal_sum[9] <= diagnal_sum[9];

    // diagnal_sum[10]
    if(global_cnt==19) diagnal_sum[10] <= cur_sum[3][7];
    else if(global_cnt==20) diagnal_sum[10] <= sum2_out[10];
    else if(global_cnt==21) diagnal_sum[10] <= sum2_out[10];
    else if(global_cnt==22) diagnal_sum[10] <= sum2_out[10];
    else if(global_cnt==23) diagnal_sum[10] <= sum2_out[10];
    else diagnal_sum[10] <= diagnal_sum[10];

    // diagnal_sum[11]
    if(global_cnt==20) diagnal_sum[11] <= cur_sum[4][7];
    else if(global_cnt==21) diagnal_sum[11] <= sum2_out[11];
    else if(global_cnt==22) diagnal_sum[11] <= sum2_out[11];
    else if(global_cnt==23) diagnal_sum[11] <= sum2_out[11];
    else diagnal_sum[11] <= diagnal_sum[11];

    // diagnal_sum[12]
    if(global_cnt==21) diagnal_sum[12] <= cur_sum[5][7];
    else if(global_cnt==22) diagnal_sum[12] <= sum2_out[12];
    else if(global_cnt==23) diagnal_sum[12] <= sum2_out[12];
    else diagnal_sum[12] <= diagnal_sum[12];

    // diagnal_sum[13]
    if(global_cnt==22) diagnal_sum[13] <= cur_sum[6][7];
    else if(global_cnt==23) diagnal_sum[13] <= sum2_out[13];
    else diagnal_sum[13] <= diagnal_sum[13];

    // diagnal_sum[14]
    if(global_cnt==23) diagnal_sum[14] <= cur_sum[7][7];
    else diagnal_sum[14] <= diagnal_sum[14];

  end
  else if(cur_state==CLEAR)begin
    for(i=0;i<15;i=i+1)begin
      diagnal_sum[i]<=40'd0;   
    end 
  end
end


//Part 3 Seq Logic
always@(posedge clk or negedge rst_n)begin
  if(!rst_n)begin
    out_valid<=1'b0; out_data<=40'd0; output_cnt<=0;
  end
  // 4X4
  else if(cur_state==OUTPUT&&output_cnt<=6&&matrix_size_q==0)begin
    output_cnt<=output_cnt+1; out_valid<=1'b1; out_data<=diagnal_sum[output_cnt]; 
  end
  // 8X8
  else if(cur_state==OUTPUT&&output_cnt<=14&&matrix_size_q==1)begin
    output_cnt<=output_cnt+1; out_valid<=1'b1; out_data<=diagnal_sum[output_cnt]; 
  end
  else begin
    out_valid<=1'b0; out_data<=40'd0; output_cnt<=0;
  end
end

endmodule

module Comb_MUL (a_in, b_in, mul_out);
  input signed[15:0] a_in;
  input signed[15:0] b_in;
  output signed[32:0] mul_out;

  //Part 2 Comb Logic
  assign mul_out=(a_in*b_in);
endmodule

module Comb_ADD (a_in, b_in, sum_out);
  input signed[32:0] a_in;
  input signed[39:0] b_in;
  output signed[39:0] sum_out;

  //Part 2 Comb Logic
  assign sum_out=(a_in+b_in);
endmodule

module sum2 (in_1, in_2, sum2_out);
  input signed[39:0] in_1;
  input signed[39:0] in_2;
  output signed[39:0] sum2_out;

  //Part 2 Comb Logic
  assign sum2_out=(in_1+in_2);
endmodule