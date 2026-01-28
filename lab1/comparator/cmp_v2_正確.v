module comparator(
    input  signed [6:0] a, b,           //7-bit signed inputs
    input  [2:0]        a_char, b_char, //5-bit unsigned tokens
    output signed [6:0] min_out, max_out,
    output [2:0]        min_char, max_char
);

    wire a_gt_b = (a > b);
    wire a_lt_b = (a < b);
    wire a_eq_b = ~a_gt_b & ~a_lt_b;

    wire [6:0] max_val_eq, min_val_eq;
    wire [2:0] max_char_eq, min_char_eq;
    assign {max_val_eq, max_char_eq, min_val_eq, min_char_eq} =
        (a_char < b_char) ? {a, a_char, b, b_char} : {b, b_char, a, a_char};

    wire [6:0] max_val_a_gt_b = a;
    wire [6:0] min_val_a_gt_b = b;
    wire [6:0] max_val_b_gt_a = b;
    wire [6:0] min_val_b_gt_a = a;

    assign max_out = a_gt_b ? max_val_a_gt_b :
                     a_lt_b ? max_val_b_gt_a :
                              max_val_eq;

    assign min_out = a_gt_b ? min_val_a_gt_b :
                     a_lt_b ? min_val_b_gt_a :
                              min_val_eq;

    assign max_char = a_gt_b ? a_char :
                      a_lt_b ? b_char :
                               max_char_eq;

    assign min_char = a_gt_b ? b_char :
                      a_lt_b ? a_char :
                               min_char_eq;
endmodule