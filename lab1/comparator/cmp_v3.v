module comparator(
    input  signed [6:0] a, b,           
    input  [2:0]        a_char, b_char,
    output [6:0] min_out, max_out,
    output [2:0] min_char, max_char
);

    wire [6:0] max_a, max_b;
    wire [6:0] min_a, min_b;
    wire [2:0] max_char_a, max_char_b;
    wire [2:0] min_char_a, min_char_b;

    // a > b
    assign max_a = a;
    assign min_a = b;
    assign max_char_a = a_char;
    assign min_char_a = b_char;

    // b > a
    assign max_b = b;
    assign min_b = a;
    assign max_char_b = b_char;
    assign min_char_b = a_char;

    // a == b, 用 token 决定
    wire [6:0] max_eq_val, min_eq_val;
    wire [2:0] max_eq_char, min_eq_char;
    assign {max_eq_val, max_eq_char, min_eq_val, min_eq_char} =
           (a_char < b_char) ? {a, a_char, b, b_char} :
                               {b, b_char, a, a_char};

    // 计算比较结果
    wire a_gt_b = a > b;
    wire a_eq_b = a == b;
    wire b_gt_a = b > a;

    //并行选择输出
    assign max_out  = ({7{a_gt_b}} & max_a) |
                      ({7{b_gt_a}} & max_b) |
                      ({7{a_eq_b}} & max_eq_val);

    assign min_out  = ({7{a_gt_b}} & min_a) |
                      ({7{b_gt_a}} & min_b) |
                      ({7{a_eq_b}} & min_eq_val);

    assign max_char = ({3{a_gt_b}} & max_char_a) |
                      ({3{b_gt_a}} & max_char_b) |
                      ({3{a_eq_b}} & max_eq_char);

    assign min_char = ({3{a_gt_b}} & min_char_a) |
                      ({3{b_gt_a}} & min_char_b) |
                      ({3{a_eq_b}} & min_eq_char);
endmodule
