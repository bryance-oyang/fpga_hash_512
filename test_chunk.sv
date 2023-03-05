`timescale 1ns / 1ps

module test_chunk();
    reg clk;
    integer clk_count;
    reg reset;
    reg done;

    reg [1023:0] chunk; // 128 bytes

    reg [63:0] H0i;
    reg [63:0] H1i;
    reg [63:0] H2i;
    reg [63:0] H3i;
    reg [63:0] H4i;
    reg [63:0] H5i;
    reg [63:0] H6i;
    reg [63:0] H7i;

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
        chunk = 0;
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
            chunk[1024-64 +: 64] <= 64'd1;

            H0i <= 0;
            H1i <= 0;
            H2i <= 0;
            H3i <= 0;
            H4i <= 0;
            H5i <= 0;
            H6i <= 0;
            H7i <= 0;

            reset <= 0;
        end

        RUN:
            reset <= 1;
        endcase
    end

    sha512_chunk chunk_0(
        clk,
        reset,
        done,

        chunk, // 128 bytes

        H0i,
        H1i,
        H2i,
        H3i,
        H4i,
        H5i,
        H6i,
        H7i,

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
