// tb_hadamard4x4_clean.v
`timescale 1ns/1ps

module tb_hadamard4x4;

    // DUT inputs
    reg  signed [9:0] a00,a01,a02,a03;
    reg  signed [9:0] a10,a11,a12,a13;
    reg  signed [9:0] a20,a21,a22,a23;
    reg  signed [9:0] a30,a31,a32,a33;

    // DUT outputs
    wire signed [12:0] b00,b01,b02,b03;
    wire signed [12:0] b10,b11,b12,b13;
    wire signed [12:0] b20,b21,b22,b23;
    wire signed [12:0] b30,b31,b32,b33;

    // Instantiate DUT (assumes hadamard4x4_nosignext exists)
    hadamard4x4_nosignext dut(
        .a00(a00), .a01(a01), .a02(a02), .a03(a03),
        .a10(a10), .a11(a11), .a12(a12), .a13(a13),
        .a20(a20), .a21(a21), .a22(a22), .a23(a23),
        .a30(a30), .a31(a31), .a32(a32), .a33(a33),
        .b00(b00), .b01(b01), .b02(b02), .b03(b03),
        .b10(b10), .b11(b11), .b12(b12), .b13(b13),
        .b20(b20), .b21(b21), .b22(b22), .b23(b23),
        .b30(b30), .b31(b31), .b32(b32), .b33(b33)
    );

    integer i;
    integer errors;

    // global matrices
    integer ref_mat [0:3][0:3];
    integer dut_mat [0:3][0:3];

    // compute reference for a column and store into ref_mat[:, col]
    task compute_ref_col;
        input signed [9:0] c0, c1, c2, c3;
        input integer col;
    begin
        ref_mat[0][col] = $signed(c0) + $signed(c1) + $signed(c2) + $signed(c3);
        ref_mat[1][col] = $signed(c0) - $signed(c1) + $signed(c2) - $signed(c3);
        ref_mat[2][col] = $signed(c0) + $signed(c1) - $signed(c2) - $signed(c3);
        ref_mat[3][col] = $signed(c0) - $signed(c1) - $signed(c2) + $signed(c3);
    end
    endtask

    // fill DUT matrix from DUT outputs (no args)
    task fill_dut_mat;
    begin
        dut_mat[0][0]= b00; dut_mat[0][1]= b01; dut_mat[0][2]= b02; dut_mat[0][3]= b03;
        dut_mat[1][0]= b10; dut_mat[1][1]= b11; dut_mat[1][2]= b12; dut_mat[1][3]= b13;
        dut_mat[2][0]= b20; dut_mat[2][1]= b21; dut_mat[2][2]= b22; dut_mat[2][3]= b23;
        dut_mat[3][0]= b30; dut_mat[3][1]= b31; dut_mat[3][2]= b32; dut_mat[3][3]= b33;
    end
    endtask

    // print ref matrix (no args)
    task print_ref_mat;
    begin
        $display("REF Matrix:");
        $display("%8d %8d %8d %8d", ref_mat[0][0], ref_mat[0][1], ref_mat[0][2], ref_mat[0][3]);
        $display("%8d %8d %8d %8d", ref_mat[1][0], ref_mat[1][1], ref_mat[1][2], ref_mat[1][3]);
        $display("%8d %8d %8d %8d", ref_mat[2][0], ref_mat[2][1], ref_mat[2][2], ref_mat[2][3]);
        $display("%8d %8d %8d %8d", ref_mat[3][0], ref_mat[3][1], ref_mat[3][2], ref_mat[3][3]);
        $display("");
    end
    endtask

    // print dut matrix (no args)
    task print_dut_mat;
    begin
        $display("DUT Matrix:");
        $display("%8d %8d %8d %8d", dut_mat[0][0], dut_mat[0][1], dut_mat[0][2], dut_mat[0][3]);
        $display("%8d %8d %8d %8d", dut_mat[1][0], dut_mat[1][1], dut_mat[1][2], dut_mat[1][3]);
        $display("%8d %8d %8d %8d", dut_mat[2][0], dut_mat[2][1], dut_mat[2][2], dut_mat[2][3]);
        $display("%8d %8d %8d %8d", dut_mat[3][0], dut_mat[3][1], dut_mat[3][2], dut_mat[3][3]);
        $display("");
    end
    endtask

    // compare (increment errors)
    task compare_mats;
    integer r,c;
    begin
        for (r=0;r<4;r=r+1)
            for (c=0;c<4;c=c+1)
                if (ref_mat[r][c] !== dut_mat[r][c])
                    errors = errors + 1;
    end
    endtask

    initial begin
        errors = 0;

        // ---------- TEST 1 (edge cases) ----------
        a00 = -512; a10 = -512; a20 = -512; a30 = -512;
        a01 =  511; a11 =  511; a21 =  511; a31 =  511;
        a02 = -512; a12 =  511; a22 = -512; a32 =  511;
        a03 =    0; a13 =    1; a23 =   -1; a33 =  123;
        #5; // let DUT settle

        compute_ref_col(a00,a10,a20,a30, 0);
        compute_ref_col(a01,a11,a21,a31, 1);
        compute_ref_col(a02,a12,a22,a32, 2);
        compute_ref_col(a03,a13,a23,a33, 3);

        fill_dut_mat();

        print_ref_mat();
        print_dut_mat();

        compare_mats();

        // ---------- TEST 2 (random) ----------
        for (i=0;i<5;i=i+1) begin
            a00 = $urandom % 1024 - 512; a10 = $urandom % 1024 - 512;
            a20 = $urandom % 1024 - 512; a30 = $urandom % 1024 - 512;

            a01 = $urandom % 1024 - 512; a11 = $urandom % 1024 - 512;
            a21 = $urandom % 1024 - 512; a31 = $urandom % 1024 - 512;

            a02 = $urandom % 1024 - 512; a12 = $urandom % 1024 - 512;
            a22 = $urandom % 1024 - 512; a32 = $urandom % 1024 - 512;

            a03 = $urandom % 1024 - 512; a13 = $urandom % 1024 - 512;
            a23 = $urandom % 1024 - 512; a33 = $urandom % 1024 - 512;

            #2; // settle

            compute_ref_col(a00,a10,a20,a30, 0);
            compute_ref_col(a01,a11,a21,a31, 1);
            compute_ref_col(a02,a12,a22,a32, 2);
            compute_ref_col(a03,a13,a23,a33, 3);

            fill_dut_mat();

            print_ref_mat();
            print_dut_mat();

            compare_mats();
        end

        // final summary: only this line (besides the matrices)
        $display("Total errors = %0d", errors);

        $finish;
    end

endmodule