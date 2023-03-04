`timescale 1ns / 1ps

module sha512_compression(
    input [63:0] wi,
    input [63:0] ki,

    input [63:0] ai,
    input [63:0] bi,
    input [63:0] ci,
    input [63:0] di,
    input [63:0] ei,
    input [63:0] fi,
    input [63:0] gi,
    input [63:0] hi,

    output reg [63:0] oa,
    output reg [63:0] ob,
    output reg [63:0] oc,
    output reg [63:0] od,
    output reg [63:0] oe,
    output reg [63:0] of,
    output reg [63:0] og,
    output reg [63:0] oh
    );

    reg [63:0] S0;
    reg [63:0] S1;
    reg [63:0] ch;
    reg [63:0] maj;
    reg [63:0] tmp1;
    reg [63:0] tmp2;

    always @(*) begin
        S0 = ((ai >> 28) | (ai << (64-28)))
            ^((ai >> 34) | (ai << (64-34)))
            ^((ai >> 39) | (ai << (64-39)));
        S1 = ((ei >> 14) | (ei << (64-14)))
            ^((ei >> 18) | (ei << (64-18)))
            ^((ei >> 41) | (ei << (64-41)));
        ch = (ei & fi) ^ ((~ei) & gi);
        tmp1 = hi + S1 + ch + ki + wi;
        maj = (ai & bi) ^ (ai & ci) ^ (bi & ci);
        tmp2 = S0 + maj;

        oh = gi;
        og = fi;
        of = ei;
        oe = di + tmp1;
        od = ci;
        oc = bi;
        ob = ai;
        oa = tmp1 + tmp2;
    end
endmodule
