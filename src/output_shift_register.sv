`include "types.svh"

module output_shift_register(
    input logic clk, rst,
    input osr_data_t data,
    input osr_control_t control
);

// Essentially the OSR needs to know whether it is to pull the value
// from a MOV or PULL instruction, or how many bits to shift out
// via an out instruction, FSM should handle keeping track of
// how many bits have been shifted out and when to autopull.

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        data.shift_out <= 32'b0;
        data.osr <= 32'b0;
    end else begin
        if (control.osr_load) begin
            data.osr <= data.data_in;
        end else if (control.shift_en) begin
            if (control.shiftdir) begin
                data.shift_out <= data.osr[control.shift_count-1:0] << (32 - control.shift_count);
                data.osr <= data.osr >> control.shift_count;
            end else begin
                data.shift_out <= data.osr[31 -: control.shift_count] >> (32 - control.shift_count);
                data.osr <= data.osr << control.shift_count;
            end
        end
    end
end

// From the PIO spec:
//
// Non-out cycles
// 1 if MOV or PULL:
// 2    osr count = 0
// 3
// 4 if osr count >= threshold:
// 5    if tx fifo not empty:
// 6        osr = pull()
// 7        osr count = 0

// OUT cycles
//  1 if osr count >= threshold:
//  2   if tx fifo not empty:
//  3       osr = pull()
//  4       osr count = 0
//  5   stall
//  6 else:
//  7   output(osr)
//  8   osr = shift(osr, out count)
//  9   osr count = saturate(osr count + out count)
// 10
// 11 if osr count >= threshold:
// 12    if tx fifo not empty:
// 13        osr = pull()
// 14        osr count = 0

endmodule
