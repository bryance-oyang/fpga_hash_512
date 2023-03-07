/*
Synchronize the de-assertion of an async, active-low reset.

References:
- https://www.intel.com/content/www/us/en/docs/programmable/683082/22-1/use-synchronized-asynchronous-reset.html
- https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/ASYNC_REG
*/

module better_reset(
    input clk,
    input reset,

    output breset
);
    (* ASYNC_REG = "TRUE" *) reg buf0;
    (* ASYNC_REG = "TRUE" *) reg buf1;
    assign breset = buf1;

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            buf0 <= 0;
            buf1 <= 0;
        end else begin
            buf0 <= 1;
            buf1 <= buf0;
        end
    end
endmodule
