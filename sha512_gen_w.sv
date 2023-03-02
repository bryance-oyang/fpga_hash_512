`timescale 1ns / 1ps

module sha512_gen_w(
    input [0:63] w[0:15],
    output [0:63] out[16:31]
);
    integer i;
    for (i = 16; i < 32; i++) {
        assign out[i] = w[i-16] + w[i-7]
            // s0
            + ((w[i-15] >> 1) | (w[i-15] << (64-1)))
            ^ ((w[i-15] >> 8) | (w[i-15] << (64-8)))
            ^ ((w[i-15] >> 7))
            // s1
            + ((w[i-2] >> 19) | (w[i-2] << (64-19)))
            ^ ((w[i-2] >> 61) | (w[i-2] << (64-61)))
            ^ ((w[i-2] >> 6));
    }
endmodule
