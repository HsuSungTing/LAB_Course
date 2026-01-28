`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`ifdef POST
    `define CYCLE_TIME 10.0
`endif

`ifndef CYCLE_TIME
`define CYCLE_TIME 10.0
`endif

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
reg [7:0] in_data_value;
input out_valid;
input out_sad;

parameter SEED = 666745;
parameter PAT_NUM = 100;
parameter IMG_SIZE = 128*128;
parameter IMG_WH = 128;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

// ========================================
// integer & parameter
// ========================================
integer i, j, k, l, m, n;
integer latency_count;
integer total_latency;

// ========================================
// wire & reg
// ========================================
reg [7:0] rand_img_pix;
reg [7:0] img0_mem [0:IMG_SIZE-1];
reg [7:0] img1_mem [0:IMG_SIZE-1];

reg [127:0] img0_mem_16 [0:1023];
reg [127:0] img1_mem_16 [0:1023];

reg [7:0] img0_mem_2d [0:IMG_WH-1][0:IMG_WH-1];
reg [7:0] img1_mem_2d [0:IMG_WH-1][0:IMG_WH-1];

// in_valid2 -> MV data
reg [7:0] mvx_l0_p1, mvy_l0_p1;
reg [7:0] mvx_l1_p1, mvy_l1_p1;
reg [7:0] mvx_l0_p2, mvy_l0_p2;
reg [7:0] mvx_l1_p2, mvy_l1_p2;
reg frac_x_l0_p1, frac_y_l0_p1;
reg frac_x_l1_p1, frac_y_l1_p1;
reg frac_x_l0_p2, frac_y_l0_p2;
reg frac_x_l1_p2, frac_y_l1_p2;

// interpolation result (10x10)
reg signed [8:0] l0_p1_interp [0:9][0:9];
reg signed [8:0] l1_p1_interp [0:9][0:9];
reg signed [8:0] l0_p2_interp [0:9][0:9];
reg signed [8:0] l1_p2_interp [0:9][0:9];

// answer
reg [27:0] pack_p1, pack_p2;
reg [55:0] golden_ans;

// debug: 15x15 view
reg [7:0] image15x15_l0_p2 [0:14][0:14];
reg [7:0] image15x15_l1_p2 [0:14][0:14];
reg [7:0] image15x15_l0_p1 [0:14][0:14];
reg [7:0] image15x15_l1_p1 [0:14][0:14];

//================================================================
// main
//================================================================
initial begin
    void'($urandom(SEED));
    $srandom(SEED);
    reset_task;

    for (n=0; n<PAT_NUM; n=n+1) begin
        img_gen_task;
        for (m=0; m<64; m=m+1) begin
            MV_gen_task;
            caculate_ans_task;
            wait_out_valid_task;
            check_ans_task;
        end
    end
    $finish;
end

//================================================================
// reset
//================================================================
task reset_task;
    force clk = 0;
    latency_count = 0;
    total_latency = 0;
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_valid2 = 1'b0;
    in_data = 9'dxxxxxxxxx;
    #(CYCLE);
    rst_n = 1'b0;
    #(CYCLE/2);
    rst_n = 1'b1;
    #(CYCLE/2);
    release clk;

    // out_sad 是 1-bit serial，reset 應為 0
    if (out_valid !== 1'b0 || out_sad !== 1'b0) begin
        $display("======================================================");
        $display("     Output signal should be 0 after reset at %t", $time);
        $display("======================================================");
        $finish;
    end
    @(negedge clk);
endtask

//================================================================
// image gen + send
//================================================================
task img_gen_task;
    repeat($urandom_range(3, 6)) @(negedge clk);

    for (i=0; i<IMG_SIZE; i=i+1) begin
        rand_img_pix = $urandom_range(0, 255);
        img0_mem[i] = rand_img_pix;
        rand_img_pix = $urandom_range(0, 255);
        img1_mem[i] = rand_img_pix;
    end

    for (i=0; i<IMG_WH; i=i+1) begin
        for (j=0; j<IMG_WH; j=j+1) begin
            img0_mem_2d[i][j] = img0_mem[i*IMG_WH + j];
            img1_mem_2d[i][j] = img1_mem[i*IMG_WH + j];
        end
    end

    in_valid = 1'b1;

    for (i=0; i<IMG_SIZE; i=i+1) begin
        in_data = {img0_mem[i], 1'bx};
        in_data_value = img0_mem[i];
        @(negedge clk);
    end
    for (i=0; i<IMG_SIZE; i=i+1) begin
        in_data = {img1_mem[i], 1'bx};
        in_data_value = img1_mem[i];
        @(negedge clk);
    end

    for (i=0; i<1024; i=i+1) begin
        img0_mem_16[i] = {img0_mem[i*16 +15], img0_mem[i*16 +14], img0_mem[i*16 +13], img0_mem[i*16 +12],
                          img0_mem[i*16 +11], img0_mem[i*16 +10], img0_mem[i*16 + 9], img0_mem[i*16 + 8],
                          img0_mem[i*16 + 7], img0_mem[i*16 + 6], img0_mem[i*16 + 5], img0_mem[i*16 + 4],
                          img0_mem[i*16 + 3], img0_mem[i*16 + 2], img0_mem[i*16 + 1], img0_mem[i*16 + 0]};
        img1_mem_16[i] = {img1_mem[i*16 +15], img1_mem[i*16 +14], img1_mem[i*16 +13], img1_mem[i*16 +12],
                          img1_mem[i*16 +11], img1_mem[i*16 +10], img1_mem[i*16 + 9], img1_mem[i*16 + 8],
                          img1_mem[i*16 + 7], img1_mem[i*16 + 6], img1_mem[i*16 + 5], img1_mem[i*16 + 4],
                          img1_mem[i*16 + 3], img1_mem[i*16 + 2], img1_mem[i*16 + 1], img1_mem[i*16 + 0]};
    end

    in_valid = 1'b0;
    in_data = 9'dxxxxxxxxx;
    in_data_value = 8'dxx;
endtask

//================================================================
// helpers
//================================================================
function automatic int clip_idx(input int q);
    if (q < 0) clip_idx = 0;
    else if (q > IMG_WH-1) clip_idx = IMG_WH-1;
    else clip_idx = q;
endfunction

function automatic [7:0] get_px(input bit isL1, input int yy, input int xx);
    if (!isL1) get_px = img0_mem_2d[clip_idx(yy)][clip_idx(xx)];
    else       get_px = img1_mem_2d[clip_idx(yy)][clip_idx(xx)];
endfunction

function automatic int clip_mv117(input int v);
    if (v < 0) clip_mv117 = 0;
    else if (v > 117) clip_mv117 = 117;
    else clip_mv117 = v;
endfunction

function automatic int clip127(input int v);
    if (v < 0) clip127 = 0;
    else if (v > 127) clip127 = 127;
    else clip127 = v;
endfunction

// Clip 到像素範圍 0..255，回傳 signed[8:0]（但不會負）
function automatic signed [8:0] sat_s9_m0_255(input int v);
begin
    if (v < 0)       sat_s9_m0_255 = -9'sd0;   // = 9'b1_0000_0000
    else if (v > 255)   sat_s9_m0_255 =  9'sd255;
    else                sat_s9_m0_255 = $signed(v); // v 保證已在範圍內，直接 cast 會正確保留負號
end
endfunction

// 6-tap unscaled
function automatic int fir6_h_unscaled(input bit isL1, input int yy, input int xx);
    int p_2,p_1,p0,p1,p2,p3;
    p_2 = get_px(isL1, yy, xx-2);
    p_1 = get_px(isL1, yy, xx-1);
    p0  = get_px(isL1, yy, xx  );
    p1  = get_px(isL1, yy, xx+1);
    p2  = get_px(isL1, yy, xx+2);
    p3  = get_px(isL1, yy, xx+3);
    fir6_h_unscaled = (p_2 -5*p_1 +20*p0 +20*p1 -5*p2 + p3);
endfunction

function automatic int fir6_v_on_pix_unscaled(input bit isL1, input int yy, input int xx);
    int p_2,p_1,p0,p1,p2,p3;
    p_2 = get_px(isL1, yy-2, xx);
    p_1 = get_px(isL1, yy-1, xx);
    p0  = get_px(isL1, yy  , xx);
    p1  = get_px(isL1, yy+1, xx);
    p2  = get_px(isL1, yy+2, xx);
    p3  = get_px(isL1, yy+3, xx);
    fir6_v_on_pix_unscaled = (p_2 -5*p_1 +20*p0 +20*p1 -5*p2 + p3);
endfunction

function automatic int fir6_v_on_mid_unscaled(
    input int m_2, input int m_1, input int m0, input int m1, input int m2, input int m3
);
    fir6_v_on_mid_unscaled = (m_2 -5*m_1 +20*m0 +20*m1 -5*m2 + m3);
endfunction



function automatic signed [8:0] interp_px_s9(
    input bit isL1, input int yy, input int xx, input bit fx, input bit fy
);
    int val, k, mid[0:5];
begin
    if (!fx && !fy) begin
        // 整數像素 0..255 仍可直接放進 signed[8:0]
        interp_px_s9 = $signed({1'b0, get_px(isL1, yy, xx)});
    end
    else if (fx && !fy) begin
        val = fir6_h_unscaled(isL1, yy, xx);
        interp_px_s9 = sat_s9_m0_255( (val + 16) >>> 5 );
    end
    else if (!fx && fy) begin
        val = fir6_v_on_pix_unscaled(isL1, yy, xx);
        interp_px_s9 = sat_s9_m0_255( (val + 16) >>> 5 );
    end
    else begin
        for (k=0; k<6; k=k+1) mid[k] = fir6_h_unscaled(isL1, yy-2+k, xx);
        val = fir6_v_on_mid_unscaled(mid[0],mid[1],mid[2],mid[3],mid[4],mid[5]);
        interp_px_s9 = sat_s9_m0_255( (val + 512) >>> 10 );
    end
end
endfunction
//================================================================
// MV gen (含 P2 = P1 ± 5)
//================================================================
task MV_gen_task;
    int mvx_temp, mvy_temp;
    repeat($urandom_range(3, 6)) @(negedge clk);
    in_valid2 = 1'b1;

    // L0 P1 (你保留 debug 固定 2,2)
    mvx_l0_p1 = $urandom_range(0, 117);
    mvy_l0_p1 = $urandom_range(0, 117);
    frac_x_l0_p1 = $urandom_range(0, 1);
    frac_y_l0_p1 = $urandom_range(0, 1);

    // L1 P1
    mvx_l1_p1 = $urandom_range(0, 117);
    mvy_l1_p1 = $urandom_range(0, 117);
    frac_x_l1_p1 = $urandom_range(0, 1);
    frac_y_l1_p1 = $urandom_range(0, 1);

    // L0 P2 = L0 P1 ± 5 (clip 到 0..117)
    mvx_temp  = $signed(mvx_l0_p1) + $urandom_range(-5, 5);
    mvy_temp  = $signed(mvy_l0_p1) + $urandom_range(-5, 5);
    mvx_l0_p2 = clip_mv117(mvx_temp);
    mvy_l0_p2 = clip_mv117(mvy_temp);
    frac_x_l0_p2 = $urandom_range(0, 1);
    frac_y_l0_p2 = $urandom_range(0, 1);

    // L1 P2 = L1 P1 ± 5
    mvx_temp  = $signed(mvx_l1_p1) + $urandom_range(-5, 5);
    mvy_temp  = $signed(mvy_l1_p1) + $urandom_range(-5, 5);
    mvx_l1_p2 = clip_mv117(mvx_temp);
    mvy_l1_p2 = clip_mv117(mvy_temp);
    frac_x_l1_p2 = $urandom_range(0, 1);
    frac_y_l1_p2 = $urandom_range(0, 1);

    // Input MV data (8 cycles)
    for (i=0; i<8; i=i+1) begin
        case(i)
            0: in_data = {mvx_l0_p1, frac_x_l0_p1};
            1: in_data = {mvy_l0_p1, frac_y_l0_p1};
            2: in_data = {mvx_l1_p1, frac_x_l1_p1};
            3: in_data = {mvy_l1_p1, frac_y_l1_p1};
            4: in_data = {mvx_l0_p2, frac_x_l0_p2};
            5: in_data = {mvy_l0_p2, frac_y_l0_p2};
            6: in_data = {mvx_l1_p2, frac_x_l1_p2};
            7: in_data = {mvy_l1_p2, frac_y_l1_p2};
            default: in_data = 9'd0;
        endcase
        in_data_value = in_data[8:1];
        @(negedge clk);
    end

    // debug 15x15
    for (i=0; i<15; i=i+1) begin
        for (j=0; j<15; j=j+1) begin
            int yy0, xx0, yy1, xx1;

            yy0 = clip127(mvy_l0_p1 + (i - 2));
            xx0 = clip127(mvx_l0_p1 + (j - 2));
            image15x15_l0_p1[i][j] = img0_mem_2d[yy0][xx0];

            yy1 = clip127(mvy_l1_p1 + (i - 2));
            xx1 = clip127(mvx_l1_p1 + (j - 2));
            image15x15_l1_p1[i][j] = img1_mem_2d[yy1][xx1];

            yy0 = clip127(mvy_l0_p2 + (i - 2));
            xx0 = clip127(mvx_l0_p2 + (j - 2));
            image15x15_l0_p2[i][j] = img0_mem_2d[yy0][xx0];

            yy1 = clip127(mvy_l1_p2 + (i - 2));
            xx1 = clip127(mvx_l1_p2 + (j - 2));
            image15x15_l1_p2[i][j] = img1_mem_2d[yy1][xx1];
        end
    end

    in_valid2 = 1'b0;
    in_data_value = 8'dxx;
    in_data = 9'dxxxxxxxxx;
endtask

//================================================================
// 10x10 interpolation fill
//================================================================
task cal_interpolation(
    input reg [7:0] mvx, mvy,
    input reg fracx, fracy,
    input int l_num, p_num
);
    bit isL1;
    bit fx, fy;
    int r,c;
begin
    isL1 = (l_num==1);
    fx = fracx;
    fy = fracy;

    for (r=0; r<10; r=r+1) begin
        for (c=0; c<10; c=c+1) begin
            if (!isL1 && p_num==1) l0_p1_interp[r][c] = interp_px_s9(1'b0, mvy+r, mvx+c, fx, fy);
            if ( isL1 && p_num==1) l1_p1_interp[r][c] = interp_px_s9(1'b1, mvy+r, mvx+c, fx, fy);
            if (!isL1 && p_num==2) l0_p2_interp[r][c] = interp_px_s9(1'b0, mvy+r, mvx+c, fx, fy);
            if ( isL1 && p_num==2) l1_p2_interp[r][c] = interp_px_s9(1'b1, mvy+r, mvx+c, fx, fy);
        end
    end
end
endtask

//================================================================
// slice 8x8 from 10x10
//================================================================
task automatic slice8x8_from10(
    input  signed [8:0] T[0:9][0:9],
    input  int off_y, input int off_x,
    output signed [8:0] B[0:7][0:7]
);
    int r,c;
begin
    for (r=0; r<8; r=r+1)
        for (c=0; c<8; c=c+1)
            B[r][c] = T[off_y + r][off_x + c];
end
endtask

//================================================================
// SATD
//================================================================
function automatic int satd4x4(input int D[0:3][0:3]);
    int r,c, sum;
    int t0,t1,t2,t3;
    int T[0:3][0:3];
    int u0,u1,u2,u3;
begin
    for (r=0; r<4; r=r+1) begin
        t0 = D[r][0] + D[r][1];
        t1 = D[r][0] - D[r][1];
        t2 = D[r][2] + D[r][3];
        t3 = D[r][2] - D[r][3];
        T[r][0] = t0 + t2;
        T[r][1] = t1 + t3;
        T[r][2] = t0 - t2;
        T[r][3] = t1 - t3;
    end
    sum = 0;
    for (c=0; c<4; c=c+1) begin
        u0 = T[0][c] + T[1][c];
        u1 = T[0][c] - T[1][c];
        u2 = T[2][c] + T[3][c];
        u3 = T[2][c] - T[3][c];
        sum += (u0+u2 >= 0 ? (u0+u2) : -(u0+u2));
        sum += (u1+u3 >= 0 ? (u1+u3) : -(u1+u3));
        sum += (u0-u2 >= 0 ? (u0-u2) : -(u0-u2));
        sum += (u1-u3 >= 0 ? (u1-u3) : -(u1-u3));
    end
    satd4x4 = sum;
end
endfunction

function automatic int satd8x8(
    input signed [8:0] A[0:7][0:7],
    input signed [8:0] B[0:7][0:7]
);
    int D[0:3][0:3];
    int rr,cc, sum;
begin
    sum = 0;
    for (rr=0; rr<4; rr=rr+1) for (cc=0; cc<4; cc=cc+1) D[rr][cc] = A[rr][cc] - B[rr][cc];
    sum += satd4x4(D);

    for (rr=0; rr<4; rr=rr+1) for (cc=0; cc<4; cc=cc+1) D[rr][cc] = A[rr][cc+4] - B[rr][cc+4];
    sum += satd4x4(D);

    for (rr=0; rr<4; rr=rr+1) for (cc=0; cc<4; cc=cc+1) D[rr][cc] = A[rr+4][cc] - B[rr+4][cc];
    sum += satd4x4(D);

    for (rr=0; rr<4; rr=rr+1) for (cc=0; cc<4; cc=cc+1) D[rr][cc] = A[rr+4][cc+4] - B[rr+4][cc+4];
    sum += satd4x4(D);

    satd8x8 = sum;
end
endfunction

//================================================================
// Mirror 3x3 search using 10x10 matrices (真正用前面算的 10x10)
//================================================================
task automatic mirror_search_one_point_from10(
    input  signed [8:0] T0[0:9][0:9],  // L0 10x10
    input  signed [8:0] T1[0:9][0:9],  // L1 10x10
    output int best_satd,
    output int best_point
);
    int dx,dy, idx;
    reg signed [8:0] B0[0:7][0:7];
    reg signed [8:0] B1[0:7][0:7];
    int s;
begin
    best_satd  = 32'h7fffffff;
    best_point = 0;

    // Fig.6 順序：idx = dx*3 + dy
    for (dx=0; dx<=2; dx=dx+1) begin
        for (dy=0; dy<=2; dy=dy+1) begin
            idx = dx*3 + dy;

            // L0: (dx,dy)
            slice8x8_from10(T0, dy, dx, B0);
            // L1 mirror: (2-dx, 2-dy)
            slice8x8_from10(T1, (2-dy), (2-dx), B1);

            s = satd8x8(B0, B1);

            // tie-break: 只在更小才更新，會保留較早 idx
            if (s < best_satd) begin
                best_satd  = s;
                best_point = idx;
            end
        end
    end
end
endtask

//================================================================
// pack (28b) : [27:24]=point, [23:0]=satd
//================================================================
function automatic [27:0] pack28(input int satd, input int point);
    pack28 = { point[3:0], satd[23:0] };
endfunction

//================================================================
// golden compute (P1/P2)
//================================================================
task caculate_ans_task;
    int p1_satd, p1_point;
    int p2_satd, p2_point;
begin
    // 先算出四個 10x10
    cal_interpolation(mvx_l0_p1, mvy_l0_p1, frac_x_l0_p1, frac_y_l0_p1, 0, 1);
    cal_interpolation(mvx_l1_p1, mvy_l1_p1, frac_x_l1_p1, frac_y_l1_p1, 1, 1);
    cal_interpolation(mvx_l0_p2, mvy_l0_p2, frac_x_l0_p2, frac_y_l0_p2, 0, 2);
    cal_interpolation(mvx_l1_p2, mvy_l1_p2, frac_x_l1_p2, frac_y_l1_p2, 1, 2);

    // ✅ SATD search 用「10x10 切 8x8」
    mirror_search_one_point_from10(l0_p1_interp, l1_p1_interp, p1_satd, p1_point);
    pack_p1 = pack28(p1_satd, p1_point);

    mirror_search_one_point_from10(l0_p2_interp, l1_p2_interp, p2_satd, p2_point);
    pack_p2 = pack28(p2_satd, p2_point);

    // P2 在高位、P1 在低位；DUT serial LSB-first
    golden_ans = {pack_p2, pack_p1};
end
endtask

//================================================================
// wait/check
//================================================================
task wait_out_valid_task;
    latency_count = 0;
    while(out_valid !== 1'b1) begin
        @(negedge clk);
        latency_count = latency_count + 1;
        if(latency_count > 1000 ) begin
            $display("==================================================================");
            $display("   The execution latency is over 1000 cycles at PATTERN\033[1;33m NO %0d\033[0m ", n*m);
            $display("==================================================================");
            $finish;
        end
    end
    total_latency = total_latency + latency_count;
endtask

task check_ans_task;
    integer b;
    reg [55:0] got;
begin
    got = 56'd0;

    if (out_valid !== 1'b1) begin
        $display("\033[1;31m[ERR]\033[0m out_valid deasserted too early at %t", $time);
        $finish;
    end
    got[0] = out_sad;

    for (b=1; b<56; b=b+1) begin
        @(negedge clk);
        if (out_valid !== 1'b1) begin
            $display("\033[1;31m[ERR]\033[0m out_valid dropped before 56 cycles (b=%0d) at %t", b, $time);
            $finish;
        end
        got[b] = out_sad;
    end

    if (got !== golden_ans) begin
        $display("\033[1;31m[MISMATCH]\033[0m got=0x%014h  exp=0x%014h", got, golden_ans);
        $display("got =%056b", got);
        $display("exp =%056b", golden_ans);
        $finish;
    end else begin
        $display("\033[1;32m[PASS]\033[0m set=%0d  packed56=0x%014h", m, golden_ans);
    end
end
endtask

endmodule
