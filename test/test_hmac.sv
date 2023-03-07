`timescale 1ns / 1ps

module test_hmac();
    reg clk;
    integer clk_count;
    reg reset;
    reg done;

    reg [3:0] state;
    reg [3:0] next;

    localparam BIRTH = 0;
    localparam INIT = 1;
    localparam RUN = 2;
    localparam DEATH = 3;

    initial begin
        clk = 0;
        clk_count = -1;
        state = BIRTH;
    end
    always begin
        #5 clk = ~clk;
    end

    always @(posedge clk) begin
        state <= next;
        clk_count <= clk_count + 1;
    end

    always @(*) begin
        case(state)
        default:
            next = BIRTH;
        DEATH:
            next = DEATH;

        BIRTH:
            next = INIT;
        INIT:
            if (clk_count < 32)
                next = INIT;
            else
                next = RUN;
        RUN:
            if (!done)
                next = RUN;
            else
                next = DEATH;
        endcase
    end

    reg mode;
    reg [1023:0] key;
    reg [511:0] msg;
    wire [511:0] oH;

    always @(posedge clk) begin
        case(next)
        INIT: begin
            reset <= 0;

            mode <= 0;
            key <= 0;
            msg <= 0;
        end

        RUN:
            reset <= 1;
        endcase
    end

    hmac hmac_0(
        clk,
        reset,
        done,

        mode,
        key,
        msg,
        oH
    );

endmodule
