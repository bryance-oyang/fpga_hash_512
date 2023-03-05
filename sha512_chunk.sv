`timescale 1ns / 1ps

/*
The w generation and compression rounds are combined into the same loop.
w[0] is always the input to the compression, and newly generated w's are
shifted left during the looping.
*/

module sha512_chunk(
    input clk,
    input reset,
    output done,

    input [1023:0] chunk, // 128 bytes
    input [0:7][63:0] iH, // 64 bytes == 512 bits input hash
    output [0:7][63:0] oH // 64 bytes == 512 bits output hash
);
    localparam [63:0] K_const[0:79] = {
        64'h428a2f98d728ae22,
        64'h7137449123ef65cd,
        64'hb5c0fbcfec4d3b2f,
        64'he9b5dba58189dbbc,
        64'h3956c25bf348b538,
        64'h59f111f1b605d019,
        64'h923f82a4af194f9b,
        64'hab1c5ed5da6d8118,
        64'hd807aa98a3030242,
        64'h12835b0145706fbe,
        64'h243185be4ee4b28c,
        64'h550c7dc3d5ffb4e2,
        64'h72be5d74f27b896f,
        64'h80deb1fe3b1696b1,
        64'h9bdc06a725c71235,
        64'hc19bf174cf692694,
        64'he49b69c19ef14ad2,
        64'hefbe4786384f25e3,
        64'h0fc19dc68b8cd5b5,
        64'h240ca1cc77ac9c65,
        64'h2de92c6f592b0275,
        64'h4a7484aa6ea6e483,
        64'h5cb0a9dcbd41fbd4,
        64'h76f988da831153b5,
        64'h983e5152ee66dfab,
        64'ha831c66d2db43210,
        64'hb00327c898fb213f,
        64'hbf597fc7beef0ee4,
        64'hc6e00bf33da88fc2,
        64'hd5a79147930aa725,
        64'h06ca6351e003826f,
        64'h142929670a0e6e70,
        64'h27b70a8546d22ffc,
        64'h2e1b21385c26c926,
        64'h4d2c6dfc5ac42aed,
        64'h53380d139d95b3df,
        64'h650a73548baf63de,
        64'h766a0abb3c77b2a8,
        64'h81c2c92e47edaee6,
        64'h92722c851482353b,
        64'ha2bfe8a14cf10364,
        64'ha81a664bbc423001,
        64'hc24b8b70d0f89791,
        64'hc76c51a30654be30,
        64'hd192e819d6ef5218,
        64'hd69906245565a910,
        64'hf40e35855771202a,
        64'h106aa07032bbd1b8,
        64'h19a4c116b8d2d0c8,
        64'h1e376c085141ab53,
        64'h2748774cdf8eeb99,
        64'h34b0bcb5e19b48a8,
        64'h391c0cb3c5c95a63,
        64'h4ed8aa4ae3418acb,
        64'h5b9cca4f7763e373,
        64'h682e6ff3d6b2b8a3,
        64'h748f82ee5defb2fc,
        64'h78a5636f43172f60,
        64'h84c87814a1f0ab72,
        64'h8cc702081a6439ec,
        64'h90befffa23631e28,
        64'ha4506cebde82bde9,
        64'hbef9a3f7b2c67915,
        64'hc67178f2e372532b,
        64'hca273eceea26619c,
        64'hd186b8c721c0c207,
        64'heada7dd6cde0eb1e,
        64'hf57d4f7fee6ed178,
        64'h06f067aa72176fba,
        64'h0a637dc5a2c898a6,
        64'h113f9804bef90dae,
        64'h1b710b35131c471b,
        64'h28db77f523047d84,
        64'h32caab7b40c72493,
        64'h3c9ebe0a15c9bebc,
        64'h431d67c49c100d4c,
        64'h4cc5d4becb3e42b6,
        64'h597f299cfc657e2a,
        64'h5fcb6fab3ad6faec,
        64'h6c44198c4a475817
    };

    reg [0:16][63:0] w; // 16th is for scratch space to hold next w calculation
    reg [0:7][63:0] a; // a,b,c,d,e,f,g,h
    reg [63:0] tmp1;

    // generate output
    assign oH[0] = iH[0] + a[0];
    assign oH[1] = iH[1] + a[1];
    assign oH[2] = iH[2] + a[2];
    assign oH[3] = iH[3] + a[3];
    assign oH[4] = iH[4] + a[4];
    assign oH[5] = iH[5] + a[5];
    assign oH[6] = iH[6] + a[6];
    assign oH[7] = iH[7] + a[7];

    reg [2:0] state;
    reg [2:0] next;
    reg [6:0] i;

    localparam BIRTH =    0;
    localparam INIT =     1;
    localparam TMPW =     2;
    localparam COMPRESS = 3;
    localparam DEATH =    4;

    always @(posedge clk or negedge reset) begin
        if (!reset)
            state <= BIRTH;
        else
            state <= next;
    end
    assign done = (state == DEATH);

    always @(*) begin
        case(state)
        default:
            next = BIRTH;
        DEATH:
            next = DEATH;

        BIRTH:
            next = INIT;
        INIT:
            next = TMPW;
        TMPW:
            next = COMPRESS;
        COMPRESS:
            if (i < 80)
                next = TMPW;
            else
                next = DEATH;
        endcase
    end

    always @(posedge clk) begin
        case(next)
        INIT: begin
            for (integer j = 0; j < 16; j++) begin
                w[j][63:0] <= chunk[64*(15-j) +: 64];
            end

            a <= iH;
            i <= 0;
        end

        TMPW: begin
            tmp1 <= a[7] + K_const[i] + w[0]
                + (((a[4] >> 14) | (a[4] << (64-14)))
                  ^((a[4] >> 18) | (a[4] << (64-18)))
                  ^((a[4] >> 41) | (a[4] << (64-41))))
                + ((a[4] & a[5]) ^ ((~a[4]) & a[6]));

            w[16] <= w[0] + w[9]
                // s0
                + (((w[1] >> 1) | (w[1] << (64-1)))
                ^ ((w[1] >> 8) | (w[1] << (64-8)))
                ^ ((w[1] >> 7)))
                // s1
                + (((w[14] >> 19) | (w[14] << (64-19)))
                ^ ((w[14] >> 61) | (w[14] << (64-61)))
                ^ ((w[14] >> 6)));
            
            a[0] <= (((a[0] >> 28) | (a[0] << (64-28)))
                    ^((a[0] >> 34) | (a[0] << (64-34)))
                    ^((a[0] >> 39) | (a[0] << (64-39))))
                + ((a[0] & a[1]) ^ (a[0] & a[2]) ^ (a[1] & a[2])); // a = tmp2 (+ tmp1 later)
            a[1:7] <= a[0:6]; // b = a, c = b, etc
        end

        COMPRESS: begin
            a[0] <= a[0] + tmp1;
            a[4] <= a[4] + tmp1;

            w <= (w << 64); // make next input w the w[0]
            i <= i + 1;
        end
        endcase
    end
endmodule
