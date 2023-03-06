`timescale 1ns / 1ps

module test_pbkdf2();
    reg clk;
    integer clk_count;
    reg reset;
    reg done;

    reg [1:0] state;
    reg [1:0] next;

    localparam BIRTH = 0;
    localparam INIT = 1;
    localparam RUN = 2;
    localparam DEATH = 3;

    reg [0:127][8:0] key;
    initial begin
        clk = 0;
        clk_count = -1;
        state = BIRTH;
        key = 0;
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
    wire [511:0] result;

    always @(posedge clk) begin
        case(next)
        INIT: begin
            reset <= 0;
            key <= 0;
            /*
            key[0] <= 8'd116;
            key[1] <= 8'd101;
            key[2] <= 8'd97;
            key[3] <= 8'd67;
            key[4] <= 8'd104;
            key[5] <= 8'd101;
            key[6] <= 8'd114;
            */
        end

        RUN:
            reset <= 1;
        endcase
    end

    pbkdf2 #(.salt(0)) pbkdf2_0 (
        clk,
        reset,
        done,

        key,
        result
    );

endmodule
