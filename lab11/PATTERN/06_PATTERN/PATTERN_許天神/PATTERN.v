//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   ICLAB 2025 Fall 
// Lab11 Exercise : Geometric Transform Engine (GTE)
//      File Name : GTE.v
//    Module Name : GTE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

`ifdef RTL
	`define CYCLE_TIME  20.0
`elsif GATE
    `define CYCLE_TIME  20.0
`elsif POST
    `define CYCLE_TIME  20.0
`endif


parameter SEED = 7777445;
parameter PATUM = 300000;

module PATTERN(
    // Output signals
    clk,
    rst_n,
	
    in_valid_data,
	data,
	
    in_valid_cmd,
    cmd,    

    // Input signals
	busy
);

// ========================================
// I/O declaration
// ========================================
// Output
output reg        clk, rst_n;
output reg        in_valid_data;
output reg  [7:0] data;
output reg        in_valid_cmd;
output reg [17:0] cmd;

// Input
input busy;

// ========================================
// clock
// ========================================
real CYCLE = `CYCLE_TIME;
initial clk = 1'b0;
always	#(CYCLE/2.0) clk = ~clk; //clock

initial void'($urandom(SEED)); // fix urandom seed

// ========================================
// integer & parameter
// ========================================
integer i, j, k, t;
integer total_latency;
integer latency_count;
// ========================================
// wire & reg
// ========================================
reg [7:0] golden_sram [0:127][0:255];
reg [3:0] op_func;
reg [6:0] ms, md;
reg [7:0] temp_array [0:15][0:15];  // read from sram
reg [7:0] ans_array [0:15][0:15];   // write to sram
//================================================================
// design
//================================================================
/*
You should fetch the data in SRAMs first and then check answer!
Example code:
	golden_ans = u_GTE.MEM7.Memory[ 5 ];  (used in 01_RTL / 03_GATE simulation)
	golden_ans = u_CHIP.MEM7.Memory[ 5 ]; (used in 06_POST simulation)
*/
initial begin
    #100;
    total_latency = 0;
    for(t=0; t<PATUM; t=t+1) begin
        latency_count = 0;
        @(negedge in_valid_cmd);
        @(negedge clk);
        while(busy!==1'b0)begin
            latency_count = latency_count + 1;
            @(negedge clk);
            if(latency_count > 5000) begin
                $display("=================================================");
                $display("PATTERN NO%0d The execution latency is over 5000.", t+1);
                $display("=================================================");
                $finish;
            end
        end
        @(posedge clk);
        total_latency = total_latency + latency_count;
    end
end


initial begin
    // reset
    reset_task;
    // input data
    generate_images_128_16_16_task;
    check_sram_after_write_task;
    // send command
    i=0;
    send_command_task;
    cal_sram_ans_task;
    wait (busy == 1'b0);
    @ (negedge clk);
    check_sram_after_write_task;
    $display("PATTERN NO %6d passed! op_func = %2d    latency = %4d", i, op_func, latency_count);
    for(i=1; i<PATUM; i=i+1) begin
        repeat($urandom_range(2, 4)) @(negedge clk);
        send_command_task;
        cal_sram_ans_task;
        wait (busy == 1'b0);
        @ (negedge clk);
        check_sram_after_write_task;
        $display("PATTERN NO %6d passed! op_func = %2d    latency = %4d", i, op_func, latency_count);
    end
    $display("=============================================");
    $display(" Congratulations! You've passed all PATTERN!");
    $display(" total PATTERN NO : %0d", PATUM);
    $display(" average latency  : %0d cycles", total_latency / PATUM);
    $display(" total   latency  : %0d cycles", total_latency);
    $display("=============================================");
    $finish;
end


task reset_task;
    rst_n = 1'b1;
    in_valid_data = 1'b0;
    data = 8'b0;
    in_valid_cmd = 1'b0;
    cmd = 18'b0;
    #(10);
    force clk = 1'b0;
    #(5);
    rst_n = 1'b0;
    #(CYCLE*2);
    rst_n = 1'b1;
    #(CYCLE*4);
    release clk;
    if(busy!==1) begin
        $display("=================================================");
        $display("      Busy signal should be 1 after reset!       ");
        $display("=================================================");
        $finish;
    end
    @(negedge clk);
endtask

task generate_images_128_16_16_task;
    in_valid_data = 1'b1;
    for(i=0; i<128*16*16; i=i+1) begin
        data = $urandom_range(0, 255);
        golden_sram[i/256][i%256] = data;
        @(negedge clk);
    end
    in_valid_data = 1'b0;
    data = 8'b0;
    repeat($urandom_range(2, 4)) @(negedge clk);
endtask

task send_command_task;
    if(i<16)begin
        op_func = i[3:0];
    end
    else begin
        op_func = $urandom_range(0, 15);
    end
    while(op_func === 4'd7) begin
        op_func = $urandom_range(0, 15);
    end
    ms = $urandom_range(0, 127);
    md = $urandom_range(0, 127);
    cmd = {op_func, ms, md};
    in_valid_cmd = 1'b1;
    @(negedge clk);
    in_valid_cmd = 1'b0;
    cmd = 18'b0;
endtask

task cal_sram_ans_task;
    case(op_func)
        4'b0000: begin // MIRROR ALONG X-AXIS
            // TO DO : check for op_func 0 
            mirror_x_axis_task;
        end
        4'b0001: begin // MIRROR ALONG Y-AXIS
            // TO DO : check for op_func 1
            mirror_y_axis_task;
        end
        4'b0010: begin // TRANSPOSE
            // TO DO : check for op_func 2
            transpose_task;
        end
        4'b0011: begin // SECONDARY TRANSPOSE
            // TO DO : check for op_func 3
            secondary_transpose_task;
        end
        4'b0100: begin // ROTATE 90 DEGREE CLOCKWISE
            // TO DO : check for op_func 4
            rotate_90_task;
        end
        4'b0101: begin // ROTATE 180 DEGREE
            // TO DO : check for op_func 5
            rotate_180_task;
        end
        4'b0110: begin // ROTATE 270 DEGREE CLOCKWISE
            // TO DO : check for op_func 6
            rotate_270_task;
        end
        4'b1000: begin // RIGHT SHIFT
            // TO DO : check for op_func 8
            shift_right_task;
        end
        4'b1001: begin // LEFT SHIFT
            // TO DO : check for op_func 9
            shift_left_task;
        end
        4'b1010: begin // UP SHIFT
            // TO DO : check for op_func 10
            shift_up_task;
        end
        4'b1011: begin // DOWN SHIFT
            // TO DO : check for op_func 11
            shift_down_task;
        end
        4'b1100: begin // 4*4 ZIG-ZAG
            // TO DO : check for op_func 12
            zigzag_4x4_task;
        end
        4'b1101: begin // 8*8 ZIG-ZAG
            // TO DO : check for op_func 13
            zigzag_8x8_task;
        end
        4'b1110: begin // 4*4 MORTON ORDER
            // TO DO : check for op_func 14
            morton_4x4_task;
        end
        4'b1111: begin // 8*8 MORTON ORDER
            // TO DO : check for op_func 15
            morton_8x8_task; 
        end
        default: begin
            $display("=================================================");
            $display("                Invalid op_func!                 ");
            $display("=================================================");
            $finish;
        end
    endcase
endtask

integer row, col;
task mirror_x_axis_task; // op_func = 0
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][(15 - row)*16 + col] = temp_array[row][col];
            ans_array[15 - row][col] = temp_array[row][col];
        end
    end
endtask

task mirror_y_axis_task; // op_func = 1
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][row*16 + (15 - col)] = temp_array[row][col];
            ans_array[row][15 - col] = temp_array[row][col];
        end
    end
endtask

task transpose_task; // op_func = 2
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][col*16 + row] = temp_array[row][col];
            ans_array[col][row] = temp_array[row][col];
        end
    end
endtask

task secondary_transpose_task; // op_func = 3
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][(15 - col)*16 + (15 - row)] = temp_array[row][col];
            ans_array[15 - col][15 - row] = temp_array[row][col];
        end
    end
endtask

task rotate_90_task; // op_func = 4
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][col*16 + (15 - row)] = temp_array[row][col];
            ans_array[col][15 - row] = temp_array[row][col];
        end
    end
endtask

task rotate_180_task; // op_func = 5
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][(15 - row)*16 + (15 - col)] = temp_array[row][col];
            ans_array[15 - row][15 - col] = temp_array[row][col];
        end
    end
endtask

task rotate_270_task; // op_func = 6
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            golden_sram[md][(15 - col)*16 + row] = temp_array[row][col];
            ans_array[15 - col][row] = temp_array[row][col];
        end
    end
endtask

task shift_right_task; // op_func = 8
integer srcc;
begin
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            temp_array[row][col] = golden_sram[ms][row*16 + col];
        end
    end
    for(row=0; row<16; row=row+1) begin
        for(col=0; col<16; col=col+1) begin
            srcc = col - 5;
            if(srcc>=0) begin
                golden_sram[md][row*16 + col] = temp_array[row][srcc];
                ans_array[row][col] = temp_array[row][srcc];
            end
            else begin
                golden_sram[md][row*16 + col] = temp_array[row][(-srcc) - 1];
                ans_array[row][col] = temp_array[row][(-srcc) - 1];
            end
        end
    end
end
endtask

task shift_left_task; // op_func = 9
    integer row, col, srcc;
begin
    // backup source(ms)
    for (row=0; row<16; row=row+1)
        for (col=0; col<16; col=col+1)
            temp_array[row][col] = golden_sram[ms][row*16 + col];

    // write dest(md)
    for (row=0; row<16; row=row+1) begin
        for (col=0; col<16; col=col+1) begin
            srcc = col + 5;
            if (srcc <= 15)begin
                golden_sram[md][row*16 + col] = temp_array[row][srcc];
                ans_array[row][col] = temp_array[row][srcc];
            end
            else begin
                golden_sram[md][row*16 + col] = temp_array[row][31 - srcc]; // mirror right edge
                ans_array[row][col] = temp_array[row][31 - srcc]; // mirror right edge
            end

        end
    end
end
endtask

task shift_up_task; // op_func = 10
    integer row, col, srcr;
begin
    for (row=0; row<16; row=row+1)
        for (col=0; col<16; col=col+1)
            temp_array[row][col] = golden_sram[ms][row*16 + col];
    for (row=0; row<16; row=row+1) begin
        for (col=0; col<16; col=col+1) begin
            srcr = row + 5;
            if (srcr <= 15)begin
                golden_sram[md][row*16 + col] = temp_array[srcr][col];
                ans_array[row][col] = temp_array[srcr][col];
            end
            else begin
                golden_sram[md][row*16 + col] = temp_array[31 - srcr][col]; // mirror bottom edge
                ans_array[row][col] = temp_array[31 - srcr][col]; // mirror bottom edge
            end
        end
    end
end
endtask

task shift_down_task; // op_func = 11
    integer row, col, srcr;
begin
    for (row=0; row<16; row=row+1)
        for (col=0; col<16; col=col+1)
            temp_array[row][col] = golden_sram[ms][row*16 + col];
    for (row=0; row<16; row=row+1) begin
        for (col=0; col<16; col=col+1) begin
            srcr = row - 5;
            if (srcr >= 0)begin
                golden_sram[md][row*16 + col] = temp_array[srcr][col];
                ans_array[row][col] = temp_array[srcr][col];
            end
            else begin
                golden_sram[md][row*16 + col] = temp_array[(-srcr) - 1][col]; // mirror top edge
                ans_array[row][col] = temp_array[(-srcr) - 1][col]; // mirror top edge
            end
        end
    end
end
endtask

task zigzag_block_task(input integer B);
    integer bi, bj;
    integer r, c, s, t;
begin
    for (row=0; row<16; row=row+1)
        for (col=0; col<16; col=col+1)
            temp_array[row][col] = golden_sram[ms][row*16 + col];
    for (bi=0; bi<16; bi=bi+B)
        for (bj=0; bj<16; bj=bj+B) begin
            t = 0;
            for (s=0; s<=2*B-2; s=s+1) begin
                if ((s & 1) == 0) begin
                    for (r=(s<B)? s:(B-1); r>=0; r=r-1) begin
                        c = s - r;
                        if (c<B) begin
                            golden_sram[md][ (bi + (t/B))*16 + (bj + (t% B)) ] = temp_array[bi+r][bj+c];
                            ans_array[bi + (t/B)][bj + (t% B)] = temp_array[bi+r][bj+c];
                            t = t + 1;
                        end
                    end
                end
                else begin
                    for (r=0; r<=((s<B)? s:(B-1)); r=r+1) begin
                        c = s - r;
                        if (c<B) begin
                            golden_sram[md][ (bi + (t/B))*16 + (bj + (t% B)) ] = temp_array[bi+r][bj+c];
                            ans_array[bi + (t/B)][bj + (t% B)] = temp_array[bi+r][bj+c];
                            t = t + 1;
                        end
                    end
                end
            end
        end
end
endtask

task zigzag_4x4_task; // op_func = 12
    zigzag_block_task(4);
endtask

task zigzag_8x8_task; // op_func = 13
    zigzag_block_task(8);
endtask


function integer morton_row_bits(input integer t, input integer bits);
    integer b;
begin
    morton_row_bits = 0;
    for (b=0; b<bits; b=b+1)
        morton_row_bits = morton_row_bits | (((t >> (2*b+1)) & 1) << b);
end
endfunction

function integer morton_col_bits(input integer t, input integer bits);
    integer b;
begin
    morton_col_bits = 0;
    for (b=0; b<bits; b=b+1)
        morton_col_bits = morton_col_bits | (((t >> (2*b  )) & 1) << b);
end
endfunction

task morton_block_task(input integer B);
    integer bi, bj, t, bits, rr, cc;
    integer r, c;
begin
    for (r=0; r<16; r=r+1)
        for (c=0; c<16; c=c+1)
            temp_array[r][c] = golden_sram[ms][r*16 + c];
    bits = (B==4)? 2 : 3; // 4→2 bits；8→3 bits
    for (bi=0; bi<16; bi=bi+B)
        for (bj=0; bj<16; bj=bj+B) begin
            for (t=0; t<B*B; t=t+1) begin
                rr = morton_row_bits(t, bits);
                cc = morton_col_bits(t, bits);
                golden_sram[md][ (bi + (t/B))*16 + (bj + (t% B)) ] = temp_array[bi+rr][bj+cc];
                ans_array[bi + (t/B)][bj + (t% B)] = temp_array[bi+rr][bj+cc];
            end
        end
end
endtask

task morton_4x4_task; // op_func = 14
    morton_block_task(4);
endtask

task morton_8x8_task; // op_func = 15
    morton_block_task(8);
endtask


function automatic integer sram_no;
input [6:0] m;
begin
    if(m[6:4]==3'b000) begin
        sram_no = 3'd0; // MEM_0
    end
    else if(m[6:4]==3'b001) begin
        sram_no = 3'd1; // MEM_1
    end
    else if(m[6:4]==3'b010) begin
        sram_no = 3'd2; // MEM_2
    end
    else if(m[6:4]==3'b011) begin
        sram_no = 3'd3; // MEM_3
    end
    else if(m[5:4]==2'b00) begin
        sram_no = 3'd4; // MEM_4
    end
    else if(m[5:4]==2'b01) begin
        sram_no = 3'd5; // MEM_5
    end
    else if(m[5:4]==2'b10) begin
        sram_no = 3'd6; // MEM_6
    end
    else  begin
        sram_no = 3'd7; // MEM_7
    end
end
endfunction
task check_sram_after_write_task;
    integer err_cnt;
    integer img, p;
    integer mem_id, local_img;
    integer addr8, addr16, addr32;
    integer lane;
    reg [7:0]  got_b, exp_b;
    reg [15:0] w16;
    reg [31:0] w32;
begin
    err_cnt       = 0;
    for (img = 0; img < 128; img = img + 1) begin
        mem_id    = img[6:4];
        local_img = img[3:0]; 
        for (p = 0; p < 256; p = p + 1) begin
            exp_b = golden_sram[img][p];
            case (mem_id)
                0: begin
                    addr8 = local_img*256 + p;
                    `ifdef POST
                            got_b = $root.TESTBED.u_CHIP.CORE.MEM0.Memory[addr8];
                    `else
                            got_b = $root.TESTBED.u_GTE.CORE.MEM0.Memory[addr8];
                    `endif
                    lane  = 0;
                end
                1: begin
                    addr8 = local_img*256 + p;
                    `ifdef POST
                            got_b = $root.TESTBED.u_CHIP.CORE.MEM1.Memory[addr8];
                    `else
                            got_b = $root.TESTBED.u_GTE.CORE.MEM1.Memory[addr8];
                    `endif
                    lane  = 0;
                end
                2: begin
                    addr8 = local_img*256 + p;
                    `ifdef POST
                            got_b = $root.TESTBED.u_CHIP.CORE.MEM2.Memory[addr8];
                    `else
                            got_b = $root.TESTBED.u_GTE.CORE.MEM2.Memory[addr8];
                    `endif
                    lane  = 0;
                end
                3: begin
                    addr8 = local_img*256 + p;
                    `ifdef POST
                            got_b = $root.TESTBED.u_CHIP.CORE.MEM3.Memory[addr8];
                    `else
                            got_b = $root.TESTBED.u_GTE.CORE.MEM3.Memory[addr8];
                    `endif
                    lane  = 0;
                end

                4: begin
                    addr16 = local_img*(256/2) + (p >> 1);
                    `ifdef POST
                            w16 = $root.TESTBED.u_CHIP.CORE.MEM4.Memory[addr16];
                    `else
                            w16 = $root.TESTBED.u_GTE.CORE.MEM4.Memory[addr16];
                    `endif
                    lane = p[0];         
                    got_b = (lane==0) ? w16[15:8] : w16[7:0];
                end
                5: begin
                    addr16 = local_img*(256/2) + (p >> 1);
                    `ifdef POST
                            w16 = $root.TESTBED.u_CHIP.CORE.MEM5.Memory[addr16];
                    `else
                            w16 = $root.TESTBED.u_GTE.CORE.MEM5.Memory[addr16];
                    `endif
                    lane = p[0];
                    got_b = (lane==0) ? w16[15:8] : w16[7:0];
                end
                6: begin
                    addr32 = local_img*(256/4) + (p >> 2);
                    `ifdef POST
                            w32 = $root.TESTBED.u_CHIP.CORE.MEM6.Memory[addr32];
                    `else
                            w32 = $root.TESTBED.u_GTE.CORE.MEM6.Memory[addr32];
                    `endif
                    lane = p[1:0];        
                    case (lane)
                        2'd0: got_b = w32[31:24]; 
                        2'd1: got_b = w32[23:16];
                        2'd2: got_b = w32[15:8];
                        2'd3: got_b = w32[7:0]; 
                    endcase
                end
                7: begin
                    addr32 = local_img*(256/4) + (p >> 2);
                    `ifdef POST
                            w32 = $root.TESTBED.u_CHIP.CORE.MEM7.Memory[addr32];
                    `else
                            w32 = $root.TESTBED.u_GTE.CORE.MEM7.Memory[addr32];
                    `endif
                    lane = p[1:0];
                    case (lane)
                        2'd0: got_b = w32[31:24];
                        2'd1: got_b = w32[23:16];
                        2'd2: got_b = w32[15:8];
                        2'd3: got_b = w32[7:0];
                    endcase
                end
                default: begin
                    $display("[WRITE-CHECK] invalid mem_id=%0d", mem_id, $time);
                    err_cnt = err_cnt + 1;
                    got_b   = 8'hxx; // keep going
                end
            endcase
            if (got_b !== exp_b) begin
                err_cnt = err_cnt + 1;
                case (mem_id)
                    0: $write("[MEM0] ");
                    1: $write("[MEM1] ");
                    2: $write("[MEM2] ");
                    3: $write("[MEM3] ");
                    4: $write("[MEM4] ");
                    5: $write("[MEM5] ");
                    6: $write("[MEM6] ");
                    7: $write("[MEM7] ");
                    default: $write("[MEM?]  ");
                endcase
                if (mem_id <= 3)
                    $display("addr=%8d lane=%8d | img=%5d  pix=%5d | got=%5d exp=%5d",
                              addr8, 0, img, p, got_b, exp_b, $time);
                else if (mem_id <= 5)
                    $display("addr=%8d lane=%8d | img=%5d  pix=%5d | got=%5d exp=%5d",
                              addr16, lane, img, p, got_b, exp_b, $time);
                else
                    $display("addr=%8d lane=%8d | img=%5d  pix=%5d | got=%5d exp=%5d",
                              addr32, lane, img, p, got_b, exp_b, $time);
            end
        end
    end
    if (err_cnt == 0) begin
    end 
    else begin
        $display("=================================================");
        $display("    [WRITE-CHECK] total mismatches = %0d", err_cnt);
        $display("    At PATTERN NO %0d", i+1);
        $display("    function = %0d, ms = %0d, md = %0d", op_func, ms, md);
        $display("    sram_read_no = %0d,   sram_write_no = %0d", sram_no(ms), sram_no(md));
        $display("=================================================");
        $finish;
    end
end
endtask

endmodule



