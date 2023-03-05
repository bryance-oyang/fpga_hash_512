`timescale 1ns / 1ps

/*
index conversion
char c_array[M];
reg [N:0] v_array;
c_array[x] <-> v_array[N + 1 - 8*(x + 1) +: 8]
*/
`define CIDX(ind, bsize) (bsize - 8*(ind + 1))

/*
// IPAD_0
chunk = ipad ^ key;
iH = init;

// IPAD_R
sha512(chunk);

// MSG_0
chunk = msg and pad;
iH = oH;

// MSG_R
sha512(chunk);

// OPAD_0
out = oH; // use out buffer to store tmp sha_sum_1
chunk = opad ^ key;
iH = init;

// OPAD_R
sha512(chunk);

// SUM_0
chunk = out and pad;
iH = oH;

// SUM_R
sha512(chunk);

// OUT
out = oH
*/

module hmac(
    input clk,
    input reset,
    output done,

    input mode, // mode == 0 means 36B/288b msg; mode == 1 means 64B/512b msg (32 byte salt + 4 byte int in PBKDF2 or prior hash)
    input [1023:0] key, // NEEDS to be zero padded
    input [511:0] msg, // does NOT need to be zero padded
    output reg [511:0] out
);
    localparam [0:7][63:0] H_const = {
        64'h6a09e667f3bcc908,
        64'hbb67ae8584caa73b,
        64'h3c6ef372fe94f82b,
        64'ha54ff53a5f1d36f1,
        64'h510e527fade682d1,
        64'h9b05688c2b3e6c1f,
        64'h1f83d9abfb41bd6b,
        64'h5be0cd19137e2179
    };

    // sha512
    reg sha512_reset;
    wire sha512_done;
    reg [1023:0] chunk;
    reg [0:7][63:0] iH;
    reg [0:7][63:0] oH;
    sha512_chunk sha512_chunk_0(
        clk,
        sha512_reset,
        sha512_done,

        chunk,
        iH,
        oH
    );

    reg [3:0] state;
    reg [3:0] next;

    localparam BIRTH =   0;

    localparam IPAD_0 =  1;
    localparam IPAD_R =  2;

    localparam MSG_0 =   3;
    localparam MSG_R =   4;

    localparam OPAD_0 =  5;
    localparam OPAD_R =  6;

    localparam SUM_0 =   7;
    localparam SUM_R =   8;

    localparam OUT =     9;
    localparam DEATH =   10;

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
            next = IPAD_0;

        IPAD_0:
            next = IPAD_R;
        IPAD_R:
            if (!sha512_done)
                next = IPAD_R;
            else
                next = MSG_0;

        MSG_0:
            next = MSG_R;
        MSG_R:
            if (!sha512_done)
                next = MSG_R;
            else
                next = OPAD_0;

        OPAD_0:
            next = OPAD_R;
        OPAD_R:
            if (!sha512_done)
                next = OPAD_R;
            else
                next = SUM_0;

        SUM_0:
            next = SUM_R;
        SUM_R:
            if (!sha512_done)
                next = SUM_R;
            else
                next = OUT;

        OUT:
            next = DEATH;
        endcase
    end

    always @(posedge clk) begin
        case(next)
        IPAD_0: begin
            sha512_reset <= 0;
            iH <= H_const;

            // i_pad
            for (integer i = 0; i < 128; i++) begin
                chunk[`CIDX(i,1024) +: 8] <= 8'h36 ^ key[`CIDX(i,1024) +: 8];
            end
        end

        IPAD_R:
            sha512_reset <= 1;

        MSG_0: begin
            sha512_reset <= 0;
            iH <= oH;

            if (!mode) begin
                // 36 bytes == 288 bits
                chunk[736 +: 288] <= msg[224 +: 288];

                // sha512 padding: 1 and msg len in bits
                chunk[`CIDX(36,1024) +: 8] <= 8'h80;
                for (integer i = 37; i < 126; i++) begin
                    chunk[`CIDX(i,1024) +: 8] <= 0;
                end
                chunk[`CIDX(126,1024) +: 8] <= 8'h05;
                chunk[`CIDX(127,1024) +: 8] <= 8'h20;
            end else begin
                // 64 bytes == 512 bits
                chunk[1023:512] <= msg[511:0];

                // sha512 padding: 1 and msg len in bits
                chunk[`CIDX(64,1024) +: 8] <= 8'h80;
                for (integer i = 65; i < 126; i++) begin
                    chunk[`CIDX(i,1024) +: 8] <= 0;
                end
                chunk[`CIDX(126,1024) +: 8] <= 8'h06;
                chunk[`CIDX(127,1024) +: 8] <= 0;
            end
        end

        MSG_R:
            sha512_reset <= 1;

        OPAD_0: begin
            sha512_reset <= 0;
            iH <= H_const;

            out <= oH; // use out buffer to store tmp sha_sum_1
            // o_pad
            for (integer i = 0; i < 128; i++) begin
                chunk[`CIDX(i,1024) +: 8] <= 8'h5c ^ key[`CIDX(i,1024) +: 8];
            end
        end

        OPAD_R:
            sha512_reset <= 1;

        SUM_0: begin
            sha512_reset <= 0;
            iH <= oH;

            chunk[1023:512] <= out[511:0];

            // sha512 padding: 1 and msg len in bits
            chunk[`CIDX(64,1024) +: 8] <= 8'h80;
            for (integer i = 65; i < 126; i++) begin
                chunk[`CIDX(i,1024) +: 8] <= 0;
            end
            chunk[`CIDX(126,1024) +: 8] <= 8'h06;
            chunk[`CIDX(127,1024) +: 8] <= 0;
        end

        SUM_R:
            sha512_reset <= 1;

        OUT:
            out <= oH;
        endcase
    end

endmodule
