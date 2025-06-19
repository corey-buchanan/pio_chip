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

logic [31:0] osr_next;

// Essentially the OSR needs to know whether it is to pull the value
// from a MOV or PULL instruction, or how many bits to shift out
// via an out instruction, FSM should handle keeping track of
// how many bits have been shifted out and when to autopull.

always_comb begin
    // Default values
    if (rst) begin
        shift_out = 32'b0;
        osr_next = 32'b0;
    end else if (load) begin
        osr_next = data_in;
        shift_out = 32'b0;
    end else if (shift_en) begin
        if (shiftdir) begin
            // Right shift
            shift_out = (osr << (32 - shift_count)) >> (32 - shift_count);
            osr_next = osr >> shift_count;
        end else begin
            // Left shift
            shift_out = (osr >> (32 - shift_count));
            osr_next = osr << shift_count;
        end
    end else begin
        shift_out = 32'b0; // No shift operation
        osr_next = osr; // Keep the current value
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        osr <= 32'b0;
    end else begin
        osr <= osr_next;
    end
end

endmodule
