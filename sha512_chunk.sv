`timescale 1ns / 1ps
/*
	uint64_t w[80];

    // INIT
	for (int i = 0; i < 16; i++) {
		w[i] = 0;
		// 8 bytes per 64-bit word
		for (int j = 0; j < 8; j++) {
			uint64_t tmp = chunk[8*i + j];
			w[i] |= tmp << 8*(7-j);
		}
	}

    // W_00
    // W_16 - W_64
	uint64_t s0;
	uint64_t s1;
	for (int i = 16; i < 80; i++) {
		s0 =
			  ((w[i-15] >> 1) | (w[i-15] << (64-1)))
			^ ((w[i-15] >> 8) | (w[i-15] << (64-8)))
			^ ((w[i-15] >> 7));

		s1 =
			  ((w[i-2] >> 19) | (w[i-2] << (64-19)))
			^ ((w[i-2] >> 61) | (w[i-2] << (64-61)))
			^ ((w[i-2] >> 6));

		w[i] = w[i-16] + s0 + w[i-7] + s1;
	}

	uint64_t ai = H0i;
	uint64_t bi = H1i;
	uint64_t ci = H2i;
	uint64_t di = H3i;
	uint64_t ei = H4i;
	uint64_t fi = H5i;
	uint64_t gi = H6i;
	uint64_t hi = H7i;

    // RUN_COMPRESS
	uint64_t oa, ob, oc, od, oe, of, og, oh;
	for (int i = 0; i < 80; i++) {
		sha512_compression(
			w[i],
			K_const[i],

			ai,
			bi,
			ci,
			di,
			ei,
			fi,
			gi,
			hi,

			&oa,
			&ob,
			&oc,
			&od,
			&oe,
			&of,
			&og,
			&oh
		);

        // OUT_COMPRESS
		ai = oa;
		bi = ob;
		ci = oc;
		di = od;
		ei = oe;
		fi = of;
		gi = og;
		hi = oh;
	}

	// can be combinational, just need a done flag for loops
	*oH0 = H0i + ai;
	*oH1 = H1i + bi;
	*oH2 = H2i + ci;
	*oH3 = H3i + di;
	*oH4 = H4i + ei;
	*oH5 = H5i + fi;
	*oH6 = H6i + gi;
	*oH7 = H7i + hi;
*/

module sha512_chunk(
    input clk,
    input reset,
    output done,

    input [1023:0] chunk, // 128 bytes

    input [63:0] H0i,
    input [63:0] H1i,
    input [63:0] H2i,
    input [63:0] H3i,
    input [63:0] H4i,
    input [63:0] H5i,
    input [63:0] H6i,
    input [63:0] H7i,

    output [63:0] oH0,
    output [63:0] oH1,
    output [63:0] oH2,
    output [63:0] oH3,
    output [63:0] oH4,
    output [63:0] oH5,
    output [63:0] oH6,
    output [63:0] oH7
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

    reg [63:0] ai;
    reg [63:0] bi;
    reg [63:0] ci;
    reg [63:0] di;
    reg [63:0] ei;
    reg [63:0] fi;
    reg [63:0] gi;
    reg [63:0] hi;
    reg [63:0] S0;
    reg [63:0] S1;
    reg [63:0] ch;
    reg [63:0] maj;
    reg [63:0] tmp1;
    reg [63:0] tmp2;

    reg [0:16][63:0] w;

    // generate output
    assign oH0 = H0i + ai;
    assign oH1 = H1i + bi;
    assign oH2 = H2i + ci;
    assign oH3 = H3i + di;
    assign oH4 = H4i + ei;
    assign oH5 = H5i + fi;
    assign oH6 = H6i + gi;
    assign oH7 = H7i + hi;

    reg [3:0] state;
    reg [3:0] next;
    reg [6:0] i;

    localparam BIRTH =        0;
    localparam INIT =         1;
    localparam SCHMAJW =       2;
    localparam TMPS =         3;
    localparam OUT_COMPRESS = 4;
    localparam DEATH =        5;

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
            next = SCHMAJW;
        SCHMAJW:
            next = TMPS;
        TMPS:
            next = OUT_COMPRESS;
        OUT_COMPRESS:
            if (i < 80)
                next = SCHMAJW;
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

            ai <= H0i;
            bi <= H1i;
            ci <= H2i;
            di <= H3i;
            ei <= H4i;
            fi <= H5i;
            gi <= H6i;
            hi <= H7i;

            i <= 0;
        end

        SCHMAJW: begin
            w[16] <= w[0] + w[9]
                // s0
                + (((w[1] >> 1) | (w[1] << (64-1)))
                ^ ((w[1] >> 8) | (w[1] << (64-8)))
                ^ ((w[1] >> 7)))
                // s1
                + (((w[14] >> 19) | (w[14] << (64-19)))
                ^ ((w[14] >> 61) | (w[14] << (64-61)))
                ^ ((w[14] >> 6)));

            S0 <= ((ai >> 28) | (ai << (64-28)))
                ^((ai >> 34) | (ai << (64-34)))
                ^((ai >> 39) | (ai << (64-39)));
            S1 <= ((ei >> 14) | (ei << (64-14)))
                ^((ei >> 18) | (ei << (64-18)))
                ^((ei >> 41) | (ei << (64-41)));
            ch <= (ei & fi) ^ ((~ei) & gi);
            maj <= (ai & bi) ^ (ai & ci) ^ (bi & ci);
        end

        TMPS: begin
            tmp1 <= hi + S1 + ch + K_const[i] + w[0];
            tmp2 <= S0 + maj;
        end

        OUT_COMPRESS: begin
            w <= (w << 64);

            hi <= gi;
            gi <= fi;
            fi <= ei;
            ei <= di + tmp1;
            di <= ci;
            ci <= bi;
            bi <= ai;
            ai <= tmp1 + tmp2;

            i <= i + 1;
        end
        endcase
    end

endmodule
