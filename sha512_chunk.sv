`timescale 1ns / 1ps

module sha512_chunk(
    input clk,
    input reset,
    output reg done,

    input H0i,
    input H1i,
    input H2i,
    input H3i,
    input H4i,
    input H5i,
    input H6i,
    input H7i,

    input [0:1024] chunk, // 128 bytes

    output oH0,
    output oH1,
    output oH2,
    output oH3,
    output oH4,
    output oH5,
    output oH6,
    output oH7
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

    integer i;
    reg [0:3] rip;
    reg loop_ip;
    reg [0:7] nloop;

    reg [63:0] w[0:79];
    wire [63:0] gen_w[0:79];

    // make the new w's
    sha512_gen_w sha512_gen_w_0(w[0:15], gen_w[16:31]);
    sha512_gen_w sha512_gen_w_1(w[16:31], gen_w[32:47]);
    sha512_gen_w sha512_gen_w_2(w[32:47], gen_w[48:63]);
    sha512_gen_w sha512_gen_w_3(w[48:63], gen_w[64:79]);

    reg [63:0] feed_w;
    reg [63:0] feed_K;
    reg [63:0] ai;
    reg [63:0] bi;
    reg [63:0] ci;
    reg [63:0] di;
    reg [63:0] ei;
    reg [63:0] fi;
    reg [63:0] gi;
    reg [63:0] hi;
    reg [63:0] a;
    reg [63:0] b;
    reg [63:0] c;
    reg [63:0] d;
    reg [63:0] e;
    reg [63:0] f;
    reg [63:0] g;
    reg [63:0] h;
    wire [63:0] oa;
    wire [63:0] ob;
    wire [63:0] oc;
    wire [63:0] od;
    wire [63:0] oe;
    wire [63:0] of;
    wire [63:0] og;
    wire [63:0] oh;
    sha512_compression sha512_compression_0(
        feed_w,
        feed_K,

        ai,
        bi,
        ci,
        di,
        ei,
        fi,
        gi,
        hi,

        oa,
        ob,
        oc,
        od,
        oe,
        of,
        og,
        oh
    );

    always @(posedge clk) begin
        if (reset) begin
            rip <= 4'd0;
            done <= 0;
        end else begin
            case(rip)
            default:
                rip <= 4'd0;
                done <= 0;

            4'd0:
                rip <= rip + 1;
                for (i = 0; i < 16; i++) {
                    w[i] <= chunk[64*i : 64*(i+1) - 1]
                }
            4'd1:
                rip <= rip + 1;
                w[16:31] <= gen_w[16:31]
            4'd2:
                rip <= rip + 1;
                w[32:47] <= gen_w[32:47]
            4'd3:
                rip <= rip + 1;
                w[48:63] <= gen_w[48:63]
            4'd4:
                rip <= rip + 1;
                w[64:79] <= gen_w[64:79]

                // setup for loop
                nloop <= 8'd0;
                loop_ip <= 0;

                a <= H0i;
                b <= H1i;
                c <= H2i;
                d <= H3i;
                e <= H4i;
                f <= H5i;
                g <= H6i;
                h <= H7i;

            4'd5:
                // run 80 sha512 compression loops
                if (nloop == 8'd80) {
                    rip <= rip + 1;
                } else {
                    loop_ip <= loop_ip + 1;
                    if (!loop_ip) {
                        feed_w <= w[nloop];
                        feed_K <= K_const[nloop];
                        ai <= a;
                        bi <= b;
                        ci <= c;
                        di <= d;
                        ei <= e;
                        fi <= f;
                        gi <= g;
                        hi <= h;
                    } else {
                        a <= oa;
                        b <= ob;
                        c <= oc;
                        d <= od;
                        e <= oe;
                        f <= of;
                        g <= og;
                        h <= oh;
                        nloop <= nloop + 1;
                    }
                }

            4'd6:
                done = 1;

            endcase
        end
    end

    // can be combinational, just need a done flag for loops
    assign oH0 = H0i + a;
    assign oH1 = H1i + b;
    assign oH2 = H2i + c;
    assign oH3 = H3i + d;
    assign oH4 = H4i + e;
    assign oH5 = H5i + f;
    assign oH6 = H6i + g;
    assign oH7 = H7i + h;
endmodule
