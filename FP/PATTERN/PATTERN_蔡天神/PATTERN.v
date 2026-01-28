`ifdef RTL
    `define CYCLE_TIME 15.0
`endif
`ifdef GATE
    `define CYCLE_TIME 15.0
`endif
`ifdef POST
    `define CYCLE_TIME 15.0
`endif

`define CYCLE_TIME 15.0

module PATTERN(
    clk,
    rst_n,
    in_valid,
    in_valid2,
    in_data,
    out_valid,
    out_sad
);
output reg clk, rst_n, in_valid, in_valid2;
output reg [8:0] in_data;
input out_valid;
input out_sad;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk; //clock

// ========================================
// integer & parameter
// ========================================
parameter SIZE   = 8;
parameter PATNUM = 10;
parameter SETNUM = 64;
parameter INST_NUM = 8;
parameter IMG_NUMS = 2;
parameter IMG_SIZE = 128;
parameter MAX_LATENCY = 1000;
parameter SIZE_OF_TRANSFORM = 4;
parameter DUMP_MODE = 2;
parameter DEBUG = 3;

integer i, j, k, l, pat, set, order;
integer latency, total_latency;
integer point_x, point_y;
integer point_y_temp;
integer image_num;
integer Summation;
reg signed [23:0] SATD  [0:1];
reg        [3:0]  Point [0:1];

// ========================================
// wire & reg
// ========================================
// Golden images
reg [7:0] input_img   [0:IMG_NUMS-1][0:IMG_SIZE-1][0:IMG_SIZE-1];
reg [8:0] instruction [0:INST_NUM-1];
integer   pixel_value [0:5];
reg [8:0] pixel_temp  [0:5];

integer pixel_value_10x15 [0:9][0:14];
integer pixel_value_15x15 [0:14][0:14];

reg frac_x;
reg frac_y;

integer BI_matrix [0:IMG_NUMS-1][0:8][0:9][0:9];

reg [23:0] SATD_min [0:1];
reg [3:0]  SATD_idx [0:1];

//================================================================
// initial
//================================================================

initial begin
    clk = 0;
    rst_n = 1;
    in_valid = 0;
    in_valid2 = 0;
    in_data = 'bx;
    total_latency = 0;
    
    force clk = 0;
    reset_task;
    @(negedge clk);
       
    // Test patterns
    for (pat=0; pat<PATNUM; pat=pat+1) begin
        //Generate and input images
        generate_images;
        //dump_images_csv;
        input_images;

        for (set=0; set<SETNUM; set=set+1) begin
            input_instruction;
            Interpolation;

            pack_BI_matrix_s_point; 
            calc_residual_s_point; 
            had4x4_all; 
            calc_SATD_from_int_tran; 
            find_min_SATD_per_point;

            wait_out_valid;
            check_answer;
        end
    end
    $display("pass all pattern");
    $finish;
    // YOU_PASS_task;
end

//================================================================
// task
//================================================================

task reset_task; begin
    #(0.5); rst_n = 0;
    #(CYCLE*3);
    if (out_valid !== 0 || out_sad !== 0) begin
        $display("************************************************************");  
        $display("*           FAIL! Output should be 0 after reset           *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    #(CYCLE*0.5); rst_n = 1;
    #(CYCLE*3); release clk;
end endtask

// generating input image
task generate_images; begin
    for (i=0; i<IMG_NUMS; i=i+1) begin
        for (j=0; j<IMG_SIZE; j=j+1) begin
            for (k=0; k<IMG_SIZE; k=k+1) begin
                input_img[i][j][k] = $random % 'd256;
            end
        end
    end
end endtask

// generating input image
task input_images; begin
    // Check output overlap with in_valid
    if (out_valid === 1 || out_sad === 1) begin
        $display("************************************************************");  
        $display("*    FAIL! output should not be 0 when in_valid is high    *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    
    repeat($random % 4 + 3) @(negedge clk);
    
    in_valid = 1;
    for (i=0; i<IMG_NUMS; i=i+1) begin
        for (j=0; j<IMG_SIZE; j=j+1) begin
            for (k=0; k<IMG_SIZE; k=k+1) begin
                if (out_valid === 1 || out_sad === 1) begin
                    $display("************************************************************");  
                    $display("*           FAIL! output overlaps with in_valid            *");
                    $display("************************************************************");
                    repeat(2) @(negedge clk);
                    $finish;
                end
                in_data[8:1] = input_img[i][j][k];
                @(negedge clk);
            end
        end
    end
    in_valid = 0;
    in_data  = 'bx;
end endtask

// generating input instruction
task input_instruction; 
    integer temp;
begin
    // Check output overlap with in_valid_2
    if (out_valid === 1 || out_sad === 1) begin
        $display("************************************************************");  
        $display("*    FAIL! output should not be 0 when in_valid is high    *");
        $display("************************************************************");
        repeat(2) @(negedge clk);
        $finish;
    end
    
    // Generate random command
    for (i=0; i<(INST_NUM/2); i=i+1) begin
        instruction[i][8:1] = $random % 'd117;
        temp = instruction[i][8:1] + ($random % 6);
        if(temp > 117)
            instruction[i+4][8:1] = temp - 80;
        else 
            instruction[i+4][8:1] = temp;
        instruction[i][0]     = $random % 'd2;
        instruction[i+4][0]   = $random % 'd2;
    end
    
    // Wait 2-4 cycles
    repeat($random % 4 + 3) @(negedge clk);
    
    in_valid2 = 1;
    for (i=0; i<INST_NUM; i=i+1) begin
        in_data = instruction[i];
        if (out_valid === 1 || out_sad === 1) begin
            $display("************************************************************");  
            $display("*   FAIL! output should not be 0 when in_valid_2 is high   *");
            $display("************************************************************");
            repeat(2) @(negedge clk);
            $finish;
        end        
        @(negedge clk);
    end
    in_valid2 = 0;
    in_data   = 'bx;
    // Calculate golden answer
    // calculate_golden;

end endtask

task wait_out_valid; begin
    latency = 0;
    while(out_valid === 0) begin
        latency = latency + 1;
        if(latency > MAX_LATENCY) begin
            $display("************************************************************");  
            $display("*   FAIL! Latency exceeded %d cycles                       *", MAX_LATENCY);
            $display("************************************************************");
            repeat(2) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_answer;  
    integer cnt;
    reg [55:0] golden_out;
    reg        gbit;
begin
    golden_out = {SATD_idx[1], SATD_min[1], SATD_idx[0], SATD_min[0]};

    cnt = 0;
    while (out_valid === 1'b1) begin 

        if (cnt >= 56) begin
            if(DEBUG)begin
                //dump_BI_matrix_s_point;
                dump_Residual; 
                dump_int_tran;
                dump_SATD_val;
                dump_SATD_row_acc;
                dump_min_SATD; 
            end 

            $display("************************************************************");
            $display("*   FAIL! Pattern: %4d                                     *", pat*64+set);
            $display("*   Output longer than 56 bits                              *");
            $display("*   cnt=%4d                                                *", cnt);
            $display("************************************************************");

            repeat(2) @(negedge clk);
            $finish;
        end

        gbit = golden_out[cnt];
        if (out_sad !== gbit) begin
            if(DEBUG)begin
                //dump_BI_matrix_s_point;
                dump_Residual; 
                dump_int_tran;
                dump_SATD_val;
                dump_SATD_row_acc;
                dump_min_SATD; 
            end 

            $display("************************************************************");
            $display("*   FAIL! Pattern: %4d                                    *", pat*64+set);
            $display("*   Bit idx: %0d (MSB=0)                                   *", cnt);
            $display("*   Expected bit: %0d, Got bit: %0d                        *", gbit, out_sad);
            $display("*   Expected stream: %056b                                 *", golden_out);
            $display("************************************************************");
             
            repeat(2) @(negedge clk);
            $finish;
        end

        cnt = cnt + 1;
        @(negedge clk);
    end

    if (cnt < 56) begin
        if(DEBUG)begin
            //dump_BI_matrix_s_point;
            dump_Residual; 
            dump_int_tran;
            dump_SATD_val;
            dump_SATD_row_acc;
            dump_min_SATD; 
        end 

        $display("************************************************************");
        $display("*   FAIL! Pattern: %d                                     *", pat*64+set);
        $display("*   Output shorter than 56 bits                             *");
        $display("*   cnt=%0d                                                 *", cnt);
        $display("************************************************************");

        repeat(2) @(negedge clk);
        $finish;
    end

    $display("\033[1;32mPASS PATTERN NO.%4d\033[0m latency: %d cycles", pat*64+set, latency);
end
endtask

function integer FIR_filter; 
    input integer P_2, P_1, P0, P1, P2, P3;
    begin
        FIR_filter = P_2 - (5*P_1) + 20*P0 + 20*P1 - (5*P2) + P3;
    end 
endfunction

function integer Clip_16_5; 
    input integer data;
    begin
        Clip_16_5 = (data + 16) >>> 5;
        if(Clip_16_5 < 0)
            Clip_16_5 = 0;
        else if(Clip_16_5 > 255)
            Clip_16_5 = 255;
    end 
endfunction

function integer Clip_512_10; 
    input integer data;
    begin
        Clip_512_10 = (data + 512) >>> 10;
        if(Clip_512_10 < 0)
            Clip_512_10 = 0;
        else if(Clip_512_10 > 255)
            Clip_512_10 = 255;
    end 
endfunction

task dump_BI_matrix;
    input integer img_i;
    input integer ord_i;
    integer r, c;
    integer v;
begin
    $display("==============================================");
    $display("BI_matrix img=%0d ord=%0d", img_i, ord_i);
    $display("==============================================");
    for (r = 0; r < 10; r = r + 1) begin
        $write("row %0d : ", r);
        for (c = 0; c < 10; c = c + 1) begin
            v = BI_matrix[img_i][ord_i][r][c];
            $write("%0d ", v);
        end
        $write("\n");
    end
end
endtask

task no_filter_10x10;
    integer rr, cc;
    integer x0, y0;
    integer tmp;
begin
    for (rr = 0; rr < 10; rr = rr + 1) begin
        for (cc = 0; cc < 10; cc = cc + 1) begin
            y0 = point_y + rr;  if (y0 < 0) y0 = 0; else if (y0 > 127) y0 = 127;
            x0 = point_x + cc;  if (x0 < 0) x0 = 0; else if (x0 > 127) x0 = 127;

            tmp = input_img[image_num][y0][x0];

            BI_matrix[image_num][order][rr][cc] = tmp;
        end
    end
end
endtask

task action_X_1D_10x10;
    integer rr, cc, kk;
    integer x_idx, y_idx;
begin
    for (rr = 0; rr < 10; rr = rr + 1) begin
        y_idx = point_y + rr;
        if (y_idx < 0) y_idx = 0; else if (y_idx > 127) y_idx = 127;

        for (cc = 0; cc < 15; cc = cc + 1) begin
            x_idx = (point_x + cc) - 2;
            if (x_idx < 0) x_idx = 0; else if (x_idx > 127) x_idx = 127;
            pixel_value_10x15[rr][cc] = input_img[image_num][y_idx][x_idx];
        end
    end

    if(DEBUG)begin
        $display("==============================================");
        $display("pixel_value_10x15 pt=%0d img=%0d (10x15)", order, image_num);
        $display("==============================================");
        for (rr = 0; rr < 10; rr = rr + 1) begin
            $write("row %0d : ", rr);
            for (cc = 0; cc < 15; cc = cc + 1) begin
                $write("%0d ", pixel_value_10x15[rr][cc]);
            end
            $write("\n");
        end
    end 

    for (rr = 0; rr < 10; rr = rr + 1) begin
        for (cc = 0; cc < 10; cc = cc + 1) begin
            for (kk = 0; kk < 6; kk = kk + 1) begin
                pixel_value[kk] = pixel_value_10x15[rr][cc + kk];
            end

            //$write("pt=%0d img=%0d rr=%0d cc=%0d taps: ", order, image_num, rr, cc);
            //for (kk = 0; kk < 6; kk = kk + 1) begin
            //    $write("%0d ", pixel_value[kk]);
            //end
            //$write("\n");

            BI_matrix[image_num][order][rr][cc] = FIR_filter(
                pixel_value[0], pixel_value[1], pixel_value[2],
                pixel_value[3], pixel_value[4], pixel_value[5]
            );

            BI_matrix[image_num][order][rr][cc] = Clip_16_5(BI_matrix[image_num][order][rr][cc]);
        end
    end
end
endtask

task action_Y_1D_10x10;
    integer rr, cc, kk;
    integer x_idx, y_idx;
begin
    // prefetch 15x10 (15 rows x 10 cols)
    for (rr = 0; rr < 15; rr = rr + 1) begin
        y_idx = (point_y + rr) - 2;
        if (y_idx < 0) y_idx = 0; else if (y_idx > 127) y_idx = 127;

        for (cc = 0; cc < 15; cc = cc + 1) begin
            x_idx = (point_x + cc) - 2;
            if (x_idx < 0) x_idx = 0; else if (x_idx > 127) x_idx = 127;

            pixel_value_15x15[rr][cc] = input_img[image_num][y_idx][x_idx];
        end
    end

    if(DEBUG)begin
        $display("==============================================");
        $display("pixel_value_15x15 pt=%0d img=%0d (15x15)", order, image_num);
        $display("==============================================");
        for (rr = 0; rr < 15; rr = rr + 1) begin
            $write("row %0d : ", rr);
            for (cc = 0; cc < 15; cc = cc + 1) begin
                $write("%0d ", pixel_value_15x15[rr][cc]);
            end
            $write("\n");
        end    
    end

    // compute 10x10 by sliding 6-tap vertically
    for (rr = 0; rr < 10; rr = rr + 1) begin
        for (cc = 0; cc < 10; cc = cc + 1) begin
            for (kk = 0; kk < 6; kk = kk + 1) begin
                pixel_value[kk] = pixel_value_15x15[rr + kk][cc + 2];
            end 
            BI_matrix[image_num][order][rr][cc] = FIR_filter(
                pixel_value[0], pixel_value[1], pixel_value[2],
                pixel_value[3], pixel_value[4], pixel_value[5]
            );

            BI_matrix[image_num][order][rr][cc] = Clip_16_5(BI_matrix[image_num][order][rr][cc]);
        end
    end
end
endtask

integer pixel_temp_h [0:14][0:9]; // 15 rows x 10 cols 

task action_2D_10x10;
    integer rr, cc, kx, ky;
    integer x_idx, y_idx;
begin
    for (rr = 0; rr < 15; rr = rr + 1) begin
        y_idx = (point_y + rr) - 2;
        if (y_idx < 0)      y_idx = 0;
        else if (y_idx > 127) y_idx = 127;

        for (cc = 0; cc < 15; cc = cc + 1) begin
            x_idx = (point_x + cc) - 2;
            if (x_idx < 0)      x_idx = 0;
            else if (x_idx > 127) x_idx = 127;

            pixel_value_15x15[rr][cc] = input_img[image_num][y_idx][x_idx];
        end
    end

    if (DEBUG) begin
        $display("==============================================");
        $display("pixel_value_15x15 pt=%0d img=%0d (15x15)", order, image_num);
        $display("==============================================");
        for (rr = 0; rr < 15; rr = rr + 1) begin
            $write("row %0d : ", rr);
            for (cc = 0; cc < 15; cc = cc + 1) begin
                $write("%0d ", pixel_value_15x15[rr][cc]);
            end
            $write("\n");
        end
    end

    for (rr = 0; rr < 15; rr = rr + 1) begin
        for (cc = 0; cc < 10; cc = cc + 1) begin
            for (kx = 0; kx < 6; kx = kx + 1) begin
                pixel_value[kx] = pixel_value_15x15[rr][cc + kx];
            end

            pixel_temp_h[rr][cc] = FIR_filter(
                pixel_value[0], pixel_value[1], pixel_value[2],
                pixel_value[3], pixel_value[4], pixel_value[5]
            );
        end
    end

    for (rr = 0; rr < 10; rr = rr + 1) begin
        for (cc = 0; cc < 10; cc = cc + 1) begin
            for (ky = 0; ky < 6; ky = ky + 1) begin
                pixel_value[ky] = pixel_temp_h[rr + ky][cc];
            end

            BI_matrix[image_num][order][rr][cc] = FIR_filter(
                pixel_value[0], pixel_value[1], pixel_value[2],
                pixel_value[3], pixel_value[4], pixel_value[5]
            );

            BI_matrix[image_num][order][rr][cc] =
                Clip_512_10(BI_matrix[image_num][order][rr][cc]);
        end
    end

    dump_2D_mid;
end
endtask

task dump_2D_mid;
    integer r, c;
begin
`ifdef DEBUG
    $display("==============================================");
    $display("pixel_value_15x15 pt=%0d img=%0d (15x15)", order, image_num);
    $display("==============================================");
    for (r = 0; r < 15; r = r + 1) begin
        $write("row %0d : ", r);
        for (c = 0; c < 15; c = c + 1) begin
            $write("%0d ", pixel_value_15x15[r][c]);
        end
        $write("\n");
    end
`endif
end
endtask
task calc_addr_pair_fetch;
    input  integer x_in;
    input  integer y_in;
    input  integer mode;         // 0: no_filter, 1: X_1D, 2: Y_1D, 3: 2D
    output integer start_x;      // effective start x for fetch
    output integer start_y;      // effective start y for fetch
    output integer need_pad_y;   // 1 if (y-2)<0 in vertical/2D
    output integer addr_sram0;   // ASRAM0 word address to read
    output integer addr_sram1;   // ASRAM1 word address to read
    output integer word_base;    // ({start_y,start_x}/32)
    output integer bank_of_x;    // 0: SRAM0-half, 1: SRAM1-half
    output integer x_mod16;      // start_x % 16
    integer x_clp, y_clp;
    integer pix_idx;
begin
    x_clp = x_in;
    if (x_clp < 0) x_clp = 0;
    else if (x_clp > 127) x_clp = 127;

    y_clp = y_in;
    if (y_clp < 0) y_clp = 0;
    else if (y_clp > 127) y_clp = 127;

    need_pad_y = 0;

    // start position rule
    // vertical(2) or 2D(3): start at (x, y-2)
    if (mode == 2 || mode == 3) begin
        start_x = x_clp;
        if ((y_in - 2) < 0) begin
            start_y = 0;
            need_pad_y = 1;
        end else begin
            start_y = y_clp - 2;
        end
    end else begin
        start_x = x_clp;
        start_y = y_clp;
    end

    pix_idx   = ((start_y & 127) << 7) | (start_x & 127); // {y,x}
    word_base = (pix_idx >> 5);                             // /32
    bank_of_x = (pix_idx >> 4) & 1;                         // bit4
    x_mod16   = (start_x & 15);                             // %16

    addr_sram0 = word_base;
    addr_sram1 = word_base;

    // cross-boundary correction for 16-fetch but 15-need (X direction)
    // apply for X_1D(1) and 2D(3)
    if (bank_of_x == 1) begin
        if (x_mod16 >= 3) addr_sram0 = word_base + 1;
    end else begin
        if (x_mod16 <= 1) addr_sram1 = word_base - 1;
    end

    if (addr_sram0 < 0) addr_sram0 = 0;
    if (addr_sram1 < 0) addr_sram1 = 0;
    if (addr_sram0 > 511) addr_sram0 = 511;
    if (addr_sram1 > 511) addr_sram1 = 511;

    start_y = y_clp;
end
endtask


task Interpolation;
    integer iter;
    integer pt;
    integer sx, sy, pad, a0, a1, wb, bank, xm;
begin
    for (iter = 0; iter < 4; iter = iter + 1) begin
        pt        = iter / 2;          // 0: point1, 1: point2
        image_num = iter % 2;          // 0: L0, 1: L1
        order     = pt;                // use order as point index (0/1)

        point_x = instruction[2*iter][8:1];
        point_y = instruction[2*iter+1][8:1];
        frac_x  = instruction[2*iter][0];
        frac_y  = instruction[2*iter+1][0];
 
        calc_addr_pair_fetch(point_x, point_y, {frac_y,frac_x}, sx, sy, pad, a0, a1, wb, bank, xm);
        $display("\033[32mmode=%0d start=(%0d,%0d) pad_y=%0d base=%0d bank=%0d xmod16=%0d A0=%0d A1=%0d\033[0m",
                {frac_y,frac_x}, sx, sy, pad, wb, bank, xm, a0, a1);

        $display(" ------------------------------------------------------------------------- ");
        $display("iter=%0d pt=%0d img=%0d base_x=%0d base_y=%0d frac_x=%0d frac_y=%0d",
                 iter, pt, image_num, point_x, point_y, frac_x, frac_y);

        case ({frac_y, frac_x})
            2'b00: no_filter_10x10;
            2'b01: action_X_1D_10x10;
            2'b10: action_Y_1D_10x10;
            2'b11: action_2D_10x10;
        endcase

        dump_BI_matrix(image_num, order);
    end
end
endtask

// 4 sets (point1/2 x L0/L1) x 9 search points x 8x8
integer BI_matrix_s_point [0:1][0:1][0:8][0:7][0:7];   

task pack_BI_matrix_s_point;
    integer pt, img, set_id;
    integer dy, dx;
    integer ord_scan, ord_map;
    integer r, c;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        for (img = 0; img < 2; img = img + 1) begin

            for (dy = 0; dy < 3; dy = dy + 1) begin
                for (dx = 0; dx < 3; dx = dx + 1) begin
                    ord_scan = dy*3 + dx;

                    if (img == 0)
                        ord_map = 3*dx + dy;           // L0
                    else
                        ord_map = 8 - (3*dx + dy);     // L1

                    for (r = 0; r < 8; r = r + 1) begin
                        for (c = 0; c < 8; c = c + 1) begin
                            BI_matrix_s_point[img][pt][ord_map][r][c] =
                                BI_matrix[img][pt][r+dy][c+dx];
                        end
                    end
                end
            end
        end
    end
end
endtask

task dump_BI_matrix_s_point;
    integer pt, img, ord, r, c;
begin
    $display("\033[1;97;44m************************************************************\033[0m");  
    $display("\033[1;97;44m*            dump_BI_matrix_s_point START                  *\033[0m");
    $display("\033[1;97;44m************************************************************\033[0m");
    for (pt = 0; pt < 2; pt = pt + 1) begin
        if ( (DUMP_MODE == 1 && pt != 0) ||
             (DUMP_MODE == 2 && pt != 1) || DUMP_MODE == 0) begin
            // skip this pt
        end else begin
            for (img = 0; img < 2; img = img + 1) begin
                $display("==============================================");
                $display("BI_matrix_s_point pt=%0d img=%0d", pt, img);
                $display("==============================================");

                for (ord = 0; ord < 9; ord = ord + 1) begin
                    $display("----------------------------------------------");
                    $display("order=%0d", ord);
                    $display("----------------------------------------------");

                    for (r = 0; r < 8; r = r + 1) begin
                        $write("row %0d : ", r);
                        for (c = 0; c < 8; c = c + 1) begin
                            $write("%0d ", BI_matrix_s_point[img][pt][ord][r][c]);
                        end
                        $write("\n");
                    end
                end
            end
        end 
    end
end
endtask

// Residual[pt][ord][r][c] = BI_matrix_s_point[pt][0][ord][r][c] - BI_matrix_s_point[pt][1][ord][r][c]
integer pt, ord, r, c;
integer Residual_s_point [0:1][0:8][0:7][0:7];

task calc_residual_s_point;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        for (ord = 0; ord < 9; ord = ord + 1) begin
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) begin
                    Residual_s_point[pt][ord][r][c] =
                        BI_matrix_s_point[0][pt][ord][r][c] -
                        BI_matrix_s_point[1][pt][ord][r][c];
                end
            end
        end
    end
end
endtask

task dump_Residual;
    integer pt, ord, r, c;
begin
    $display("\033[1;97;44m************************************************************\033[0m");
    $display("\033[1;97;44m*            dump_Residual START                           *\033[0m");
    $display("\033[1;97;44m************************************************************\033[0m");

    for (pt = 0; pt < 2; pt = pt + 1) begin
        if ( (DUMP_MODE == 1 && pt != 0) ||
             (DUMP_MODE == 2 && pt != 1) || DUMP_MODE == 0) begin
            // skip this pt
        end else begin
            $display("==============================================");
            $display("Residual pt=%0d  (L0-L1)", pt);
            $display("==============================================");

            for (ord = 0; ord < 9; ord = ord + 1) begin
                $display("----------------------------------------------");
                $display("order=%0d", ord);
                $display("----------------------------------------------");

                for (r = 0; r < 8; r = r + 1) begin
                    $write("row %0d : ", r);
                    for (c = 0; c < 8; c = c + 1) begin
                        $write("%0d ", Residual_s_point[pt][ord][r][c]);
                    end
                    $write("\n");
                end
            end
        end
    end
end
endtask

integer int_tran [0:1][0:8][0:3][0:3][0:3];  // [pt][ord][sb][r][c]
integer t_tran   [0:1][0:8][0:3][0:3][0:3];  // row-transform results H4 * A

task had4x4_all;
    integer pt, ord, sb;
    integer r0, c0;

    integer a00,a01,a02,a03;
    integer a10,a11,a12,a13;
    integer a20,a21,a22,a23;
    integer a30,a31,a32,a33;

    integer c00,c01,c02,c03;
    integer c10,c11,c12,c13;
    integer c20,c21,c22,c23;
    integer c30,c31,c32,c33;

    integer o00,o01,o02,o03;
    integer o10,o11,o12,o13;
    integer o20,o21,o22,o23;
    integer o30,o31,o32,o33;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        for (ord = 0; ord < 9; ord = ord + 1) begin
            for (sb = 0; sb < 4; sb = sb + 1) begin
                r0 = (sb >= 2) ? 4 : 0;      // 0,0,4,4
                c0 = (sb[0])   ? 4 : 0;      // 0,4,0,4

                a00 = Residual_s_point[pt][ord][r0+0][c0+0];
                a01 = Residual_s_point[pt][ord][r0+0][c0+1];
                a02 = Residual_s_point[pt][ord][r0+0][c0+2];
                a03 = Residual_s_point[pt][ord][r0+0][c0+3];

                a10 = Residual_s_point[pt][ord][r0+1][c0+0];
                a11 = Residual_s_point[pt][ord][r0+1][c0+1];
                a12 = Residual_s_point[pt][ord][r0+1][c0+2];
                a13 = Residual_s_point[pt][ord][r0+1][c0+3];

                a20 = Residual_s_point[pt][ord][r0+2][c0+0];
                a21 = Residual_s_point[pt][ord][r0+2][c0+1];
                a22 = Residual_s_point[pt][ord][r0+2][c0+2];
                a23 = Residual_s_point[pt][ord][r0+2][c0+3];

                a30 = Residual_s_point[pt][ord][r0+3][c0+0];
                a31 = Residual_s_point[pt][ord][r0+3][c0+1];
                a32 = Residual_s_point[pt][ord][r0+3][c0+2];
                a33 = Residual_s_point[pt][ord][r0+3][c0+3];

                // column transform: A * H4^T (H4 is symmetric so same formula)
                // column 0: [a00,a10,a20,a30]^T
                c00 = a00 + a10 + a20 + a30;
                c10 = a00 - a10 + a20 - a30;
                c20 = a00 + a10 - a20 - a30;
                c30 = a00 - a10 - a20 + a30;

                // column 1: [a01,a11,a21,a31]^T
                c01 = a01 + a11 + a21 + a31;
                c11 = a01 - a11 + a21 - a31;
                c21 = a01 + a11 - a21 - a31;
                c31 = a01 - a11 - a21 + a31;

                // column 2: [a02,a12,a22,a32]^T
                c02 = a02 + a12 + a22 + a32;
                c12 = a02 - a12 + a22 - a32;
                c22 = a02 + a12 - a22 - a32;
                c32 = a02 - a12 - a22 + a32;

                // column 3: [a03,a13,a23,a33]^T
                c03 = a03 + a13 + a23 + a33;
                c13 = a03 - a13 + a23 - a33;
                c23 = a03 + a13 - a23 - a33;
                c33 = a03 - a13 - a23 + a33;

                // store column transform A * H4^T
                t_tran[pt][ord][sb][0][0] = c00;  t_tran[pt][ord][sb][0][1] = c01;  t_tran[pt][ord][sb][0][2] = c02;  t_tran[pt][ord][sb][0][3] = c03;
                t_tran[pt][ord][sb][1][0] = c10;  t_tran[pt][ord][sb][1][1] = c11;  t_tran[pt][ord][sb][1][2] = c12;  t_tran[pt][ord][sb][1][3] = c13;
                t_tran[pt][ord][sb][2][0] = c20;  t_tran[pt][ord][sb][2][1] = c21;  t_tran[pt][ord][sb][2][2] = c22;  t_tran[pt][ord][sb][2][3] = c23;
                t_tran[pt][ord][sb][3][0] = c30;  t_tran[pt][ord][sb][3][1] = c31;  t_tran[pt][ord][sb][3][2] = c32;  t_tran[pt][ord][sb][3][3] = c33;

                // row transform: H4 * (A * H4^T)
                o00 = c00 + c01 + c02 + c03;
                o01 = c00 - c01 + c02 - c03;
                o02 = c00 + c01 - c02 - c03;
                o03 = c00 - c01 - c02 + c03;

                o10 = c10 + c11 + c12 + c13;
                o11 = c10 - c11 + c12 - c13;
                o12 = c10 + c11 - c12 - c13;
                o13 = c10 - c11 - c12 + c13;

                o20 = c20 + c21 + c22 + c23;
                o21 = c20 - c21 + c22 - c23;
                o22 = c20 + c21 - c22 - c23;
                o23 = c20 - c21 - c22 + c23;

                o30 = c30 + c31 + c32 + c33;
                o31 = c30 - c31 + c32 - c33;
                o32 = c30 + c31 - c32 - c33;
                o33 = c30 - c31 - c32 + c33;

                int_tran[pt][ord][sb][0][0] = o00;  int_tran[pt][ord][sb][0][1] = o01;  int_tran[pt][ord][sb][0][2] = o02;  int_tran[pt][ord][sb][0][3] = o03;
                int_tran[pt][ord][sb][1][0] = o10;  int_tran[pt][ord][sb][1][1] = o11;  int_tran[pt][ord][sb][1][2] = o12;  int_tran[pt][ord][sb][1][3] = o13;
                int_tran[pt][ord][sb][2][0] = o20;  int_tran[pt][ord][sb][2][1] = o21;  int_tran[pt][ord][sb][2][2] = o22;  int_tran[pt][ord][sb][2][3] = o23;
                int_tran[pt][ord][sb][3][0] = o30;  int_tran[pt][ord][sb][3][1] = o31;  int_tran[pt][ord][sb][3][2] = o32;  int_tran[pt][ord][sb][3][3] = o33;
            end
        end
    end
end
endtask

task dump_int_tran;
    integer pt, ord, sb;
    integer r, c;
begin
    $display("==============================================");
    $display("Dump t_tran (row transform H4 * A) and int_tran (H4 * A * H4^T)");
    $display("==============================================");

    for (pt = 0; pt < 2; pt = pt + 1) begin
        for (ord = 0; ord < 9; ord = ord + 1) begin
            for (sb = 0; sb < 4; sb = sb + 1) begin
                $display("pt=%0d ord=%0d sb=%0d", pt, ord, sb);

                $display("t_tran (H4 * A):");
                for (r = 0; r < 4; r = r + 1) begin
                    $write("  row %0d : ", r);
                    for (c = 0; c < 4; c = c + 1) begin
                        $write("%0d ", t_tran[pt][ord][sb][r][c]);
                    end
                    $write("\n");
                end

                $display("int_tran (H4 * A * H4^T):");
                for (r = 0; r < 4; r = r + 1) begin
                    $write("  row %0d : ", r);
                    for (c = 0; c < 4; c = c + 1) begin
                        $write("%0d ", int_tran[pt][ord][sb][r][c]);
                    end
                    $write("\n");
                end

                $write("\n");
            end
        end
    end
end
endtask

integer SATD_val [0:1][0:8];  // [pt][ord]

task calc_SATD_from_int_tran;
    integer sum;
    integer pt, ord, sb, r, c;
    integer v;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        for (ord = 0; ord < 9; ord = ord + 1) begin
            sum = 0;
            for (sb = 0; sb < 4; sb = sb + 1) begin
                for (r = 0; r < 4; r = r + 1) begin
                    for (c = 0; c < 4; c = c + 1) begin
                        v = int_tran[pt][ord][sb][r][c];
                        if (v < 0) v = -v;
                        sum = sum + v;
                    end
                end
            end
            SATD_val[pt][ord] = sum;
        end
    end
end
endtask

task dump_SATD_val;
    integer pt, ord;
begin
    $display("************************************************************");
    $display("*              dump_SATD_val START                         *");
    $display("************************************************************");

    for (pt = 0; pt < 2; pt = pt + 1) begin
        if ( (DUMP_MODE == 0) ||
             (DUMP_MODE == 1 && pt != 0) ||
             (DUMP_MODE == 2 && pt != 1) ) begin
            // skip
        end else begin
            $display("");
            $display("############################################################");
            $display("# POINT %0d SATD_val", pt);
            $display("############################################################");
            $display("");
            for (ord = 0; ord < 9; ord = ord + 1) begin
                $display("ord=%0d  SATD=%0d", ord, SATD_val[pt][ord]);
            end
        end
    end

end
endtask

task dump_SATD_row_acc;
    integer pt, ord, sb, r, c;
    integer row_sum;
    integer v;
begin
    $display("************************************************************");
    $display("*            dump_SATD_row_acc START                        *");
    $display("************************************************************");

    for (pt = 0; pt < 2; pt = pt + 1) begin
        if ( (DUMP_MODE == 0) ||
             (DUMP_MODE == 1 && pt != 0) ||
             (DUMP_MODE == 2 && pt != 1) ) begin
            // skip
        end else begin
            $display("");
            $display("############################################################");
            $display("# POINT %0d SATD row accumulation (abs)", pt);
            $display("############################################################");

            for (ord = 0; ord < 9; ord = ord + 1) begin
                $display("");
                $display("------------------------------------------------------------");
                $display("ord=%0d", ord);
                $display("------------------------------------------------------------");

                for (sb = 0; sb < 4; sb = sb + 1) begin
                    $display("subblk=%0d", sb);
                    row_sum = 0;
                    for (r = 0; r < 4; r = r + 1) begin 
                        $write("  row %0d : ", r);
                        for (c = 0; c < 4; c = c + 1) begin
                            v = int_tran[pt][ord][sb][r][c];
                            if (v < 0) v = -v;
                            row_sum = row_sum + v;
                            $write("%0d ", v);
                        end
                        $write("| sum=%0d\n", row_sum);
                    end
                    $display("");
                end
            end
        end
    end
end
endtask

task find_min_SATD_per_point;
    integer pt, ord;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        SATD_min[pt] = SATD_val[pt][0];
        SATD_idx[pt] = 0;
        for (ord = 1; ord < 9; ord = ord + 1) begin
            if (SATD_val[pt][ord] < SATD_min[pt]) begin
                SATD_min[pt] = SATD_val[pt][ord];
                SATD_idx[pt] = ord;
            end
            // tie: keep smaller index (do nothing)
        end
    end
end
endtask

task dump_min_SATD;
    integer pt;
begin
    for (pt = 0; pt < 2; pt = pt + 1) begin
        if ( (DUMP_MODE == 0) ||
             (DUMP_MODE == 1 && pt != 0) ||
             (DUMP_MODE == 2 && pt != 1) ) begin
            // skip
        end else begin
            $display("************************************************************");
            $display("*              dump_min_SATD START                         *");
            $display("************************************************************");

            $display("pt=%0d  min_idx=%0d  min_SATD=%0d", pt, SATD_idx[pt], SATD_min[pt]);
        end
    end
end
endtask

//================================================================
// Dump Images to CSV Task (With Row/Col Headers)
//================================================================
task dump_images_csv; 
    integer f_l0, f_l1;
    integer r, c;
begin
    f_l0 = $fopen($sformatf("debug_img_L0_pat%0d.csv", pat), "w");
    f_l1 = $fopen($sformatf("debug_img_L1_pat%0d.csv", pat), "w");

    if (f_l0 == 0 || f_l1 == 0) begin
        $display("[ERROR] Can't open file for debug dump!");
        $finish;
    end

    // ==========================================
    // Dump L0
    // ==========================================
    for (c = 0; c < IMG_SIZE; c = c + 1) begin
        $fwrite(f_l0, ",%0d", c); 
    end
    $fwrite(f_l0, "\n"); 

    for (r = 0; r < IMG_SIZE; r = r + 1) begin
        $fwrite(f_l0, "%0d", r);
        
        for (c = 0; c < IMG_SIZE; c = c + 1) begin
            $fwrite(f_l0, ",%0d", input_img[0][r][c]);
        end
        $fwrite(f_l0, "\n");
    end

    // ==========================================
    // Dump L1 
    // ==========================================
    $fwrite(f_l1, "Y\\X"); 
    for (c = 0; c < IMG_SIZE; c = c + 1) begin
        $fwrite(f_l1, ",%0d", c);
    end
    $fwrite(f_l1, "\n");

    for (r = 0; r < IMG_SIZE; r = r + 1) begin
        $fwrite(f_l1, "%0d", r); // Row Header
        for (c = 0; c < IMG_SIZE; c = c + 1) begin
            $fwrite(f_l1, ",%0d", input_img[1][r][c]);
        end
        $fwrite(f_l1, "\n");
    end

    $fclose(f_l0);
    $fclose(f_l1);
    
    $display("[INFO] Dumped L0 and L1 images for Pattern %0d to CSV (with headers).", pat);

end endtask

endmodule
