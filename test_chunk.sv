`timescale 1ns / 1ps

module test_chunk();
    reg clk;
    integer clk_count;
    reg reset;
    reg done;

    reg [1023:0] chunk; // 128 bytes
    reg [0:7][63:0] iH;
    wire [0:7][63:0] oH;

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

            iH <= 0;
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
        iH,
        oH
    );

endmodule
