`timescale 1ns / 1ps

module sha512_compression(
    input [0:63] wi,
    input [0:63] ki,

    input [0:63] ai,
    input [0:63] bi,
    input [0:63] ci,
    input [0:63] di,
    input [0:63] ei,
    input [0:63] fi,
    input [0:63] gi,
    input [0:63] hi,

    output reg [0:63] ao,
    output reg [0:63] bo,
    output reg [0:63] co,
    output reg [0:63] do,
    output reg [0:63] eo,
    output reg [0:63] fo,
    output reg [0:63] go,
    output reg [0:63] ho
    );

    reg [0:63] S0;
    reg [0:63] S1;
    reg [0:63] ch;
    reg [0:63] maj;
    reg [0:63] tmp1;
    reg [0:63] tmp2;

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

        ho = gi;
        go = fi;
        fo = ei;
        eo = di + tmp1;
        do = ci;
        co = bi;
        bo = ai;
        ao = tmp1 + tmp2;
    end
endmodule
