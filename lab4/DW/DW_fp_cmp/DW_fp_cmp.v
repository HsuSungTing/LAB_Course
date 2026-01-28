module DW_fp_cmp #(parameter inst_sig_width = 23,
parameter inst_exp_width = 8,
parameter inst_ieee_compliance = 0)
(
input  [inst_sig_width+inst_exp_width:0] a,   
input  [inst_sig_width+inst_exp_width:0] b,   
input        zctr,                            
output reg   aeqb,                            
output reg   altb,                            
output reg   agtb,                            
output       unordered,                       
output reg   z0,                              
output reg   z1,                              
output [7:0] status0,                         
output [7:0] status1                          
);

wire sign_A, sign_B;
wire [inst_exp_width-1:0] exp_A, exp_B;
wire [inst_sig_width-1:0] frac_A, frac_B;

assign sign_A = a[inst_sig_width+inst_exp_width];
assign exp_A  = a[inst_sig_width+inst_exp_width-1 : inst_sig_width];
assign frac_A = a[inst_sig_width-1:0];

assign sign_B = b[inst_sig_width+inst_exp_width];
assign exp_B  = b[inst_sig_width+inst_exp_width-1 : inst_sig_width];
assign frac_B = b[inst_sig_width-1:0];

assign unordered = 1'b0;  // 這裡不實作 NaN 判斷
assign status0   = 8'd0;
assign status1   = 8'd0;

always @(*) begin
    aeqb = 0;
    altb = 0;
    agtb = 0;
    z0   = 0;
    z1   = 0;

    if (a == b) begin
        aeqb = 1'b1;
    end
    else begin
        if (sign_A != sign_B) begin
            if (sign_A == 1'b0) agtb = 1'b1; // A 正, B 負
            else altb = 1'b1;                // A 負, B 正
        end
        else begin
            if (exp_A > exp_B) begin
                if (sign_A == 1'b0) agtb = 1'b1;
                else altb = 1'b1;
            end
            else if (exp_A < exp_B) begin
                if (sign_A == 1'b0) altb = 1'b1;
                else agtb = 1'b1;
            end
            else begin
                if (frac_A > frac_B) begin
                    if (sign_A == 1'b0) agtb = 1'b1;
                    else altb = 1'b1;
                end
                else if (frac_A < frac_B) begin
                    if (sign_A == 1'b0) altb = 1'b1;
                    else agtb = 1'b1;
                end
            end
        end
    end

    // 根據 zctr 決定輸出 z0/z1 (這裡比照 DW_fp_cmp 的行為)
    if (zctr) begin
        z0 = altb;  // min
        z1 = agtb;  // max
    end
    else begin
        z0 = agtb;  // max
        z1 = altb;  // min
    end
end

endmodule