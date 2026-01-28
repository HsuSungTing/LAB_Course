module max3 #(
    parameter WIDTH = 5
)(
    input  [WIDTH-1:0] input0,
    input  [WIDTH-1:0] input1,
    input  [WIDTH-1:0] input2,
    output reg [WIDTH-1:0] max_val,
    output reg [1:0] max_idx
);

always @(*) begin
    // input0 最大或與他人相等 → 優先選 0
    if ((input0 >= input1) && (input0 >= input2)) begin
        max_val = input0;
        max_idx = 2'd0;
    end
    // input1 比 input0 大，且 >= input2 → 選 1
    else if ((input1 >= input0) && (input1 >= input2)) begin
        max_val = input1;
        max_idx = 2'd1;
    end
    // 否則就是 input2 最大
    else begin
        max_val = input2;
        max_idx = 2'd2;
    end
end

endmodule