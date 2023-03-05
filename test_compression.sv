`timescale 1ns / 1ps

module test_compression();
    reg clk;

    reg sha512_reset;
    reg sha512_done;

    reg [63:0] wi;
    reg [63:0] ki;

    reg [63:0] ai;
    reg [63:0] bi;
    reg [63:0] ci;
    reg [63:0] di;
    reg [63:0] ei;
    reg [63:0] fi;
    reg [63:0] gi;
    reg [63:0] hi;

    wire [63:0] oa;
    wire [63:0] ob;
    wire [63:0] oc;
    wire [63:0] od;
    wire [63:0] oe;
    wire [63:0] of;
    wire [63:0] og;
    wire [63:0] oh;
    sha512_compression sha512_compression_0(
        clk,
        sha512_reset,

        wi,
        ki,

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
        oh,

        sha512_done
    );

    reg [3:0] state;
    reg [3:0] next;

    localparam BIRTH = 0;
    localparam INIT = 1;
    localparam RUN = 2;
    localparam DEATH = 3;

    initial begin
        clk = 0;
        state = BIRTH;
    end
    always begin
        #5 clk = ~clk;
    end

    always @(posedge clk)
        state <= next;

    always @(*) begin
        case(state)
        default:
            next = BIRTH;
        DEATH:
            next = DEATH;

        BIRTH:
            next = INIT;
        INIT:
            next = RUN;
        RUN:
            if (!sha512_done)
                next = RUN;
            else
                next = DEATH;
        endcase
    end

    always @(posedge clk) begin
        case(next)
        INIT: begin
            sha512_reset <= 0;

            wi <= 1;
            ki <= 2;

            ai <= 3;
            bi <= 4;
            ci <= 5;
            di <= 6;
            ei <= 7;
            fi <= 8;
            gi <= 9;
            hi <= 10;
        end
        RUN:
            sha512_reset <= 1;
        endcase
    end

endmodule
