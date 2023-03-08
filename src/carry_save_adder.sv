`timescale 1ns / 1ps

module carry_save_adder#(
    parameter n // n >= 3
)(
    input [63:0] a[0:n-1],
    output [63:0] sum
);
    wire [63:0] psum[0:n-3];
    wire [63:0] carry[0:n-3];

    assign psum[0] = a[0] ^ a[1] ^ a[2];
    assign carry[0] = ((a[0] & a[1]) | (a[0] & a[2]) | (a[1] & a[2])) << 1;

    genvar i;
    generate for (i = 1; i < n-2; i++) begin
        assign psum[i] = a[i+2] ^ psum[i-1] ^ carry[i-1];
        assign carry[i] = ((a[i+2] & psum[i-1]) | (a[i+2] & carry[i-1]) | (psum[i-1] & carry[i-1])) << 1;
    end endgenerate

    assign sum = psum[n-3] + carry[n-3];
endmodule
