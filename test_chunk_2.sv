`timescale 1ns / 1ps

module test_chunk_2();
    reg clk;
    integer clk_count;
    reg reset;
    reg done;

    reg [1023:0] chunk0; // 128 bytes
    reg [1023:0] chunk1; // 128 bytes

    wire [63:0] oH0;
    wire [63:0] oH1;
    wire [63:0] oH2;
    wire [63:0] oH3;
    wire [63:0] oH4;
    wire [63:0] oH5;
    wire [63:0] oH6;
    wire [63:0] oH7;

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
        chunk0 = 0;
        chunk1 = 0;
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
            if (clk_count < 128)
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

    always @(posedge clk) begin
        case(next)
        INIT: begin
            chunk0[1024-64 +: 64] <= 64'd1;
            chunk1[1024-64 +: 64] <= 64'd2;

            reset <= 0;
        end

        RUN:
            reset <= 1;
        endcase
    end

    sha512_chunk_2 sha512_0(
        clk,
        reset,
        done,

        chunk0, // 128 bytes
        chunk1,

        oH0,
        oH1,
        oH2,
        oH3,
        oH4,
        oH5,
        oH6,
        oH7
    );

endmodule
