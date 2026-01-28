// tb_mul_H.v
`timescale 1ns/1ps

module tb_mul_H;

    // DUT inputs (signed 10-bit)
    reg signed [12:0] a00,a01,a02,a03;
    reg signed [12:0] a10,a11,a12,a13;
    reg signed [12:0] a20,a21,a22,a23;
    reg signed [12:0] a30,a31,a32,a33;

    // DUT outputs (signed 13-bit)
    wire signed [15:0] b00,b01,b02,b03;
    wire signed [15:0] b10,b11,b12,b13;
    wire signed [15:0] b20,b21,b22,b23;
    wire signed [15:0] b30,b31,b32,b33;

    // instantiate DUT (your module)
    mul_H dut (
        .a00(a00), .a01(a01), .a02(a02), .a03(a03),
        .a10(a10), .a11(a11), .a12(a12), .a13(a13),
        .a20(a20), .a21(a21), .a22(a22), .a23(a23),
        .a30(a30), .a31(a31), .a32(a32), .a33(a33),
        .b00(b00), .b01(b01), .b02(b02), .b03(b03),
        .b10(b10), .b11(b11), .b12(b12), .b13(b13),
        .b20(b20), .b21(b21), .b22(b22), .b23(b23),
        .b30(b30), .b31(b31), .b32(b32), .b33(b33)
    );

    integer errors;
    integer i;
    reg signed [15:0] ref00,ref01,ref02,ref03;
    reg signed [15:0] ref10,ref11,ref12,ref13;
    reg signed [15:0] ref20,ref21,ref22,ref23;
    reg signed [15:0] ref30,ref31,ref32,ref33;

    // ----------------------
    // Task to print a 4x4 matrix (all signals individually)
    // ----------------------
    task print_matrix;
        input [8*20:1] title;
        input signed [15:0] m00,m01,m02,m03;
        input signed [15:0] m10,m11,m12,m13;
        input signed [15:0] m20,m21,m22,m23;
        input signed [15:0] m30,m31,m32,m33;
    begin
        $display("%s", title);
        $display("%8d %8d %8d %8d", m00,m01,m02,m03);
        $display("%8d %8d %8d %8d", m10,m11,m12,m13);
        $display("%8d %8d %8d %8d", m20,m21,m22,m23);
        $display("%8d %8d %8d %8d", m30,m31,m32,m33);
    end
    endtask

    // ----------------------
    // Task to compute reference matrix for given input row
    // ----------------------
    task compute_ref_row;
        input signed [12:0] r0,r1,r2,r3;
        output signed [15:0] ref0,ref1,ref2,ref3;
    begin
        ref0 = r0 + r1 + r2 + r3; // column 0
        ref1 = r0 - r1 + r2 - r3; // column 1
        ref2 = r0 + r1 - r2 - r3; // column 2
        ref3 = r0 - r1 - r2 + r3; // column 3
    end
    endtask

    initial begin
        errors = 0;

        // ----------------------
        // TEST 0: edge case
        // ----------------------
        a00=-512; a01=-512; a02=-512; a03=-512;
        a10=511; a11=511; a12=511; a13=511;
        a20=-512; a21=511; a22=-512; a23=511;
        a30=0; a31=1; a32=-1; a33=123;
        #2;

        // reference matrix

        compute_ref_row(a00,a01,a02,a03, ref00,ref01,ref02,ref03);
        compute_ref_row(a10,a11,a12,a13, ref10,ref11,ref12,ref13);
        compute_ref_row(a20,a21,a22,a23, ref20,ref21,ref22,ref23);
        compute_ref_row(a30,a31,a32,a33, ref30,ref31,ref32,ref33);

        print_matrix("REF Matrix:", ref00,ref01,ref02,ref03,
                                    ref10,ref11,ref12,ref13,
                                    ref20,ref21,ref22,ref23,
                                    ref30,ref31,ref32,ref33);

        print_matrix("DUT Matrix:", b00,b01,b02,b03,
                                     b10,b11,b12,b13,
                                     b20,b21,b22,b23,
                                     b30,b31,b32,b33);

        // compare
        if (ref00!==b00 || ref01!==b01 || ref02!==b02 || ref03!==b03 ||
            ref10!==b10 || ref11!==b11 || ref12!==b12 || ref13!==b13 ||
            ref20!==b20 || ref21!==b21 || ref22!==b22 || ref23!==b23 ||
            ref30!==b30 || ref31!==b31 || ref32!==b32 || ref33!==b33) begin
            $display("Result: FAIL\n");
            errors = errors + 1;
        end else begin
            $display("Result: PASS\n");
        end

        // ----------------------
        // TEST 1..N: random tests
        // ----------------------
        for (i=1;i<=20;i=i+1) begin
            a00 = $urandom%1024-512; a01 = $urandom%1024-512; a02 = $urandom%1024-512; a03 = $urandom%1024-512;
            a10 = $urandom%1024-512; a11 = $urandom%1024-512; a12 = $urandom%1024-512; a13 = $urandom%1024-512;
            a20 = $urandom%1024-512; a21 = $urandom%1024-512; a22 = $urandom%1024-512; a23 = $urandom%1024-512;
            a30 = $urandom%1024-512; a31 = $urandom%1024-512; a32 = $urandom%1024-512; a33 = $urandom%1024-512;
            #2;

            compute_ref_row(a00,a01,a02,a03, ref00,ref01,ref02,ref03);
            compute_ref_row(a10,a11,a12,a13, ref10,ref11,ref12,ref13);
            compute_ref_row(a20,a21,a22,a23, ref20,ref21,ref22,ref23);
            compute_ref_row(a30,a31,a32,a33, ref30,ref31,ref32,ref33);

            $display("\n=== TEST %0d ===", i);
            print_matrix("REF Matrix:", ref00,ref01,ref02,ref03,
                                        ref10,ref11,ref12,ref13,
                                        ref20,ref21,ref22,ref23,
                                        ref30,ref31,ref32,ref33);

            print_matrix("DUT Matrix:", b00,b01,b02,b03,
                                         b10,b11,b12,b13,
                                         b20,b21,b22,b23,
                                         b30,b31,b32,b33);

            if (ref00!==b00 || ref01!==b01 || ref02!==b02 || ref03!==b03 ||
                ref10!==b10 || ref11!==b11 || ref12!==b12 || ref13!==b13 ||
                ref20!==b20 || ref21!==b21 || ref22!==b22 || ref23!==b23 ||
                ref30!==b30 || ref31!==b31 || ref32!==b32 || ref33!==b33) begin
                $display("Result: FAIL\n");
                errors = errors + 1;
            end else begin
                $display("Result: PASS\n");
            end
        end

        $display("Total errors = %0d", errors);
        $finish;
    end

endmodule
