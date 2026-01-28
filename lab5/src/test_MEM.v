module Kernel_memory_wrapper (
    input wire [6:0] A ,
    output wire [39:0] Dout ,//Q
    input wire [39:0] Din ,
    input wire clk ,
    input wire WEB ,
    input wire OE ,
    input wire CS 
);
SP_80W_40B_1M memory (  .A0(A[0]),       .A1(A[1]),       .A2(A[2]),       .A3(A[3]),
                        .A4(A[4]),       .A5(A[5]),       .A6(A[6]),
                        .DO0(Dout[0]),   .DO1(Dout[1]),   .DO2(Dout[2]),   .DO3(Dout[3]), 
                        .DO4(Dout[4]),   .DO5(Dout[5]),   .DO6(Dout[6]),   .DO7(Dout[7]), 
                        .DO8(Dout[8]),   .DO9(Dout[9]),   .DO10(Dout[10]), .DO11(Dout[11]), 
                        .DO12(Dout[12]), .DO13(Dout[13]), .DO14(Dout[14]), .DO15(Dout[15]), 
                        .DO16(Dout[16]), .DO17(Dout[17]), .DO18(Dout[18]), .DO19(Dout[19]), 
                        .DO20(Dout[20]), .DO21(Dout[21]), .DO22(Dout[22]), .DO23(Dout[23]), 
                        .DO24(Dout[24]), .DO25(Dout[25]), .DO26(Dout[26]), .DO27(Dout[27]), 
                        .DO28(Dout[28]), .DO29(Dout[29]), .DO30(Dout[30]), .DO31(Dout[31]), 
                        .DO32(Dout[32]), .DO33(Dout[33]), .DO34(Dout[34]), .DO35(Dout[35]), 
                        .DO36(Dout[36]), .DO37(Dout[37]), .DO38(Dout[38]), .DO39(Dout[39]),
                        .DI0(Din[0]),    .DI1(Din[1]),    .DI2(Din[2]),    .DI3(Din[3]), 
                        .DI4(Din[4]),    .DI5(Din[5]),    .DI6(Din[6]),    .DI7(Din[7]), 
                        .DI8(Din[8]),    .DI9(Din[9]),    .DI10(Din[10]),  .DI11(Din[11]), 
                        .DI12(Din[12]),  .DI13(Din[13]),  .DI14(Din[14]),  .DI15(Din[15]), 
                        .DI16(Din[16]),  .DI17(Din[17]),  .DI18(Din[18]),  .DI19(Din[19]), 
                        .DI20(Din[20]),  .DI21(Din[21]),  .DI22(Din[22]),  .DI23(Din[23]), 
                        .DI24(Din[24]),  .DI25(Din[25]),  .DI26(Din[26]),  .DI27(Din[27]), 
                        .DI28(Din[28]),  .DI29(Din[29]),  .DI30(Din[30]),  .DI31(Din[31]), 
                        .DI32(Din[32]),  .DI33(Din[33]),  .DI34(Din[34]),  .DI35(Din[35]), 
                        .DI36(Din[36]),  .DI37(Din[37]),  .DI38(Din[38]),  .DI39(Din[39]),
                        .CK(clk),        .WEB(WEB),       .OE(OE),         .CS(CS)      );
endmodule

module MEM_768(
    input clk, input [9:0] A, input [7:0] DIA, input WEAN, input CSA, input OEA,
    output [7:0] DOA
);

    SUMA180_768X8X1BM2 SUMA180_768X8X1BM2_instance (
        .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .A4(A[4]), .A5(A[5]), .A6(A[6]), .A7(A[7]), .A8(A[8]), .A9(A[9]),
        .DO0(DOA[0]), .DO1(DOA[1]), .DO2(DOA[2]), .DO3(DOA[3]), .DO4(DOA[4]), .DO5(DOA[5]), .DO6(DOA[6]), .DO7(DOA[7]),
        .DI0(DIA[0]), .DI1(DIA[1]), .DI2(DIA[2]), .DI3(DIA[3]), .DI4(DIA[4]), .DI5(DIA[5]), .DI6(DIA[6]), .DI7(DIA[7]),
        .CK(clk), .WEB(WEAN), .OE(OEA), .CS(CSA)
    );

endmodule

module MEM
# (parameter ADDR_WIDTH=10, parameter DATA_WIDTH=8, parameter DEPTH=1024)
(
   input [ADDR_WIDTH-1:0]       A,
   output reg [DATA_WIDTH-1:0]  Dout,
   input [DATA_WIDTH-1:0]       Din,
   input                        clk,
   input                        WEB,
   input                        OE,
   input                        CS
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    // write
    always @(posedge clk) begin
        if (CS==1'b1 && WEB==1'b0)
            mem[A] <= Din;
    end
    // read (synchronous)
    always @(posedge clk) begin
        if (CS==1'b1 && WEB==1'b1) // WEN==1 means read enabled
            Dout <= mem[A];
        // else keep Dout (or drive 0) depending on your desired behavior
    end
endmodule