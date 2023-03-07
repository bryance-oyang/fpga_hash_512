`timescale 1ns / 1ps

/*
{ // INIT
    out = 0;
    msg = salt;
    msg[35] = 0x01;
    int i = 0;
}

{ // HMAC_36
    hmac_36(key, msg, &result); // first round uses salt + 4 Byte int (1)
}

{ // DATA
    out = out ^ result;
    msg = result;

    i++;
} // if (i < iterations) goto HMAC_64; else goto DEATH;

{ // HMAC_64
    hmac_64(key, msg, &result); // remaining rounds use previous hash
} // goto DATA;
*/

module pbkdf2 #(
    parameter salt = 256'hf8633243a3b19a9980bac1dc2c92d76c1db342b19c910f6c94bf32160ae95783, // MUST be 32 Bytes == 256 bits
    parameter iterations = 10
)(
    input clk,
    input reset,
    output done,

    input [1023:0] key, // NEEDS to be zero padded
    output reg [511:0] out
);
    reg hmac_reset;
    reg hmac_done;
    reg hmac_mode;
    reg [511:0] hmac_msg;
    wire [511:0] hmac_out;
    hmac hmac_0(clk, hmac_reset, hmac_done, hmac_mode, key, hmac_msg, hmac_out);

    reg [2:0] state;
    reg [2:0] next;
    reg [16:0] i;

    localparam BIRTH   = 0;
    localparam INIT    = 1;
    localparam HMAC_36 = 2;
    localparam DATA    = 3;
    localparam HMAC_64 = 4;
    localparam DEATH   = 5;

    reg breset;
    better_reset better_reset_0(clk, reset, breset);
    always @(posedge clk or negedge breset) begin
        if (!breset)
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
                next = HMAC_36;
            HMAC_36:
                if (!hmac_done)
                    next = HMAC_36;
                else
                    next = DATA;
            DATA:
                if (i < iterations)
                    next = HMAC_64;
                else
                    next = DEATH;
            HMAC_64:
                if (!hmac_done)
                    next = HMAC_64;
                else
                    next = DATA;
        endcase
    end

    always @(posedge clk) begin
        case(next)
            INIT: begin
                out <= 0;
                hmac_msg[511:256] <= salt;
                hmac_msg[255:225] <= 0;
                hmac_msg[224] <= 1;

                i <= 0;
                hmac_mode <= 0;
                hmac_reset <= 0;
            end

            HMAC_36:
                hmac_reset <= 1;

            DATA: begin
                out <= out ^ hmac_out;
                hmac_msg <= hmac_out;

                i <= i + 1;
                hmac_mode <= 1;
                hmac_reset <= 0;
            end

            HMAC_64:
                hmac_reset <= 1;
        endcase
    end
endmodule
