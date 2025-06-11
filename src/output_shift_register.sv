`include "types.svh"

module output_shift_register(
    input logic clk, rst,
    // DATA
    input logic [31:0] data_in, // Set on MOV, PULL or autopull
    output logic [31:0] osr, // Allows FSM to read OSR for MOV instructions
    output logic [31:0] shift_out, // Set on OUT
    // CTRL
    input logic load, // Set on MOV, PULL, or autopull
    input logic shift_en, // Set on OUT
    input logic shiftdir, // Set by control register 0 = left, 1 = right
    input logic [5:0] shift_count // Set on OUT
);

// Essentially the OSR needs to know whether it is to pull the value
// from a MOV or PULL instruction, or how many bits to shift out
// via an out instruction, FSM should handle keeping track of
// how many bits have been shifted out and when to autopull.

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_out <= 32'b0;
        osr <= 32'b0;
    end else begin
        if (load) begin
            osr <= data_in;
        end else if (shift_en) begin
            if (shiftdir) begin
                // Right shift
                shift_out <= (osr << (32 - shift_count)) >> (32 - shift_count);
                osr <= osr >> shift_count;
            end else begin
                // Left shift
                shift_out <= (osr >> (32 - shift_count));
                osr <= osr << shift_count;
            end
        end
    end
end

endmodule
