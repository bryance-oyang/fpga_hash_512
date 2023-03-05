`timescale 1ns / 1ps

module sha512_chunk_2(
    input clk,
    input reset,
    output done,

    input [1023:0] chunk0, // 128 bytes
    input [1023:0] chunk1, // 128 bytes

    output reg [63:0] oH0,
    output reg [63:0] oH1,
    output reg [63:0] oH2,
    output reg [63:0] oH3,
    output reg [63:0] oH4,
    output reg [63:0] oH5,
    output reg [63:0] oH6,
    output reg [63:0] oH7
);
    localparam [63:0] H_const[0:7] = {
        64'h6a09e667f3bcc908,
        64'hbb67ae8584caa73b,
        64'h3c6ef372fe94f82b,
        64'ha54ff53a5f1d36f1,
        64'h510e527fade682d1,
        64'h9b05688c2b3e6c1f,
        64'h1f83d9abfb41bd6b,
        64'h5be0cd19137e2179
    };
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

    reg [63:0] ai;
    reg [63:0] bi;
    reg [63:0] ci;
    reg [63:0] di;
    reg [63:0] ei;
    reg [63:0] fi;
    reg [63:0] gi;
    reg [63:0] hi;
    reg [63:0] tmp1;
    reg [63:0] tmp2;

    // updated H
    wire [63:0] uH0;
    wire [63:0] uH1;
    wire [63:0] uH2;
    wire [63:0] uH3;
    wire [63:0] uH4;
    wire [63:0] uH5;
    wire [63:0] uH6;
    wire [63:0] uH7;
    assign uH0 = oH0 + ai;
    assign uH1 = oH1 + bi;
    assign uH2 = oH2 + ci;
    assign uH3 = oH3 + di;
    assign uH4 = oH4 + ei;
    assign uH5 = oH5 + fi;
    assign uH6 = oH6 + gi;
    assign uH7 = oH7 + hi;

    reg [0:16][63:0] w; // 16th is for scratch space to hold next w calculation

    reg [2:0] state;
    reg [2:0] next;
    reg [6:0] i;
    reg ichunk; // to know whether operating on 0th or 1st chunk

    localparam BIRTH =    0;
    localparam INIT =     1;
    localparam TMPW =     2;
    localparam COMPRESS = 3;
    localparam SECOND =   4;
    localparam OUT =      5;
    localparam DEATH =    6;

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
        COMPRESS: begin
            if (i < 80) begin
                next = TMPW;
            end else begin
                if (ichunk == 0)
                    next = SECOND;
                else
                    next = OUT;
            end
        end
        SECOND:
            next = TMPW;
        OUT:
            next = DEATH;
        endcase
    end

    always @(posedge clk) begin
        case(next)
        INIT: begin
            for (integer j = 0; j < 16; j++) begin
                w[j][63:0] <= chunk0[64*(15-j) +: 64];
            end

            oH0 <= H_const[0];
            oH1 <= H_const[1];
            oH2 <= H_const[2];
            oH3 <= H_const[3];
            oH4 <= H_const[4];
            oH5 <= H_const[5];
            oH6 <= H_const[6];
            oH7 <= H_const[7];

            ai <= H_const[0];
            bi <= H_const[1];
            ci <= H_const[2];
            di <= H_const[3];
            ei <= H_const[4];
            fi <= H_const[5];
            gi <= H_const[6];
            hi <= H_const[7];

            i <= 0;
            ichunk <= 0;
        end

        TMPW: begin
            tmp1 <= hi + K_const[i] + w[0]
                + (((ei >> 14) | (ei << (64-14)))
                  ^((ei >> 18) | (ei << (64-18)))
                  ^((ei >> 41) | (ei << (64-41))))
                + ((ei & fi) ^ ((~ei) & gi));

            tmp2 <= (((ai >> 28) | (ai << (64-28)))
                    ^((ai >> 34) | (ai << (64-34)))
                    ^((ai >> 39) | (ai << (64-39))))
                + ((ai & bi) ^ (ai & ci) ^ (bi & ci));

            w[16] <= w[0] + w[9]
                // s0
                + (((w[1] >> 1) | (w[1] << (64-1)))
                ^ ((w[1] >> 8) | (w[1] << (64-8)))
                ^ ((w[1] >> 7)))
                // s1
                + (((w[14] >> 19) | (w[14] << (64-19)))
                ^ ((w[14] >> 61) | (w[14] << (64-61)))
                ^ ((w[14] >> 6)));
        end

        COMPRESS: begin
            hi <= gi;
            gi <= fi;
            fi <= ei;
            ei <= di + tmp1;
            di <= ci;
            ci <= bi;
            bi <= ai;
            ai <= tmp1 + tmp2;

            w <= (w << 64);
            i <= i + 1;
        end

        SECOND: begin
            for (integer j = 0; j < 16; j++) begin
                w[j][63:0] <= chunk1[64*(15-j) +: 64];
            end

            oH0 <= uH0;
            oH1 <= uH1;
            oH2 <= uH2;
            oH3 <= uH3;
            oH4 <= uH4;
            oH5 <= uH5;
            oH6 <= uH6;
            oH7 <= uH7;

            ai <= uH0;
            bi <= uH1;
            ci <= uH2;
            di <= uH3;
            ei <= uH4;
            fi <= uH5;
            gi <= uH6;
            hi <= uH7;

            i <= 0;
            ichunk <= 1;
        end

        OUT: begin
            oH0 <= uH0;
            oH1 <= uH1;
            oH2 <= uH2;
            oH3 <= uH3;
            oH4 <= uH4;
            oH5 <= uH5;
            oH6 <= uH6;
            oH7 <= uH7;
        end
        endcase
    end

endmodule
