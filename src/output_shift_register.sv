// TODO: group these into sensible structs

module output_shift_register(
    input logic clk, rst,
    input logic [31:0] mov_in,
    output logic [31:0] mov_out,
    input logic [1:0] mov, // via MOV instruction - bit 1 set - osr as src, bit 0 set - osr as dest
    input logic [31:0] fifo_in,
    input logic fifo_pull, // via PULL instruction
    output logic [31:0] data_out,
    input logic shift_en, // via OUT instruction
    input logic [4:0] pull_thresh, // 0 for a value of 32
    input logic shiftdir, // 0 = left, 1 = right
    input logic autopull,
    input logic [4:0] shift_count, // Set by OUT instruction
    output logic fifo_pulled, // Signal to the FIFO that we've pulled data
    output logic [5:0] output_shift_counter // How many bits to shift in from the FIFO on pull: 0 = full, 32 = empty
);

logic [31:0] osr;
logic [5:0] pull_threshold;
logic [5:0] true_shift_count;
logic [5:0] current_shift_counter;

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

always @(*) begin
    if (pull_thresh == 0) pull_threshold = 6'd32;
    else pull_threshold = {1'b0, pull_thresh};

    if (shift_count == 0) true_shift_count = 6'd32;
    else true_shift_count = {1'b0, shift_count};

    current_shift_counter = (output_shift_counter + true_shift_count > 32) ? 6'd32 : output_shift_counter + true_shift_count;
end

integer i;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 32'b0;
        osr <= 32'b0;
        output_shift_counter <= 6'd32;
        fifo_pulled <= 0;
    end else begin
        // Fortunately mov_en, fifo_pull, and shift_en are mutually exclusive because only
        // one instruction can execute at a time. However, autopull can occur whenever there
        // is an OUT instruction
        if (mov[0]) begin
            // OSR as DEST
            osr <= mov_in;
            output_shift_counter <= 6'd0;
            fifo_pulled <= 0;
        end else if (mov[1]) begin
            // OSR as SRC
            // Can be non-deterministic with autopull enabled, use PULL as a fence
            mov_out <= osr;
        end else if (fifo_pull) begin
            if (shiftdir) begin
                // Shift into the left side of OSR
                for (i = 0; i < 32; i = i + 1) begin
                    if (i < 32 - {26'b0, output_shift_counter}) begin
                        osr[i] <= osr[i];
                    end else begin
                        osr[i] <= fifo_in[i - (32 - {26'b0, output_shift_counter})];
                    end
                end
            end else begin
                // Shift into the right side of OSR
                for (i = 0; i < 32; i = i + 1) begin
                    if (i < output_shift_counter) begin
                        osr[i] <= fifo_in[{26'b0, output_shift_counter} - i - 1];
                    end else begin
                        osr[i] <= osr[i];
                    end
                end
            end
            output_shift_counter <= 6'd0;
            fifo_pulled <= 1;
        end
        else if (shift_en) begin
            if (shiftdir) begin
                // Shift osr bits right into right side of data_out
                for (i = 0; i < 32; i = i + 1) begin
                    if (i < true_shift_count) begin
                        data_out[i] <= osr[{26'b0, true_shift_count} - i - 1];
                    end else begin
                        data_out[i] <= 1'b0;
                    end
                end

                if (autopull && (current_shift_counter >= pull_threshold)) begin
                    // Shift into the left side of OSR
                    for (i = 0; i < 32; i = i + 1) begin
                        if (i < 32 - {26'b0, current_shift_counter}) begin
                            osr[i] <= osr[i + {26'b0, true_shift_count}];
                        end else begin
                            osr[i] <= fifo_in[i - (32 - {26'b0, current_shift_counter})];
                        end
                    end
                    output_shift_counter <= 6'd0;
                    fifo_pulled <= 1;
                end else begin
                    osr <= osr >> true_shift_count;
                    output_shift_counter <= (output_shift_counter + true_shift_count > 32) ? 6'd32 : output_shift_counter + true_shift_count;
                    fifo_pulled <= 0;
                end
            end else begin
                // Shift osr bits left into right side of data_out
                data_out <= osr >> (32 - {26'b0, true_shift_count});

                if (autopull && (current_shift_counter >= pull_threshold)) begin
                    // Shift into the right side of OSR
                    for (int i = 0; i < 32; i = i + 1) begin
                        if (i < current_shift_counter) begin
                            osr[i] <= fifo_in[{26'b0, current_shift_counter} - i - 1];
                        end else begin
                            osr[i] <= osr[i - {26'b0, true_shift_count}];
                        end
                    end
                    output_shift_counter <= 6'd0;
                    fifo_pulled <= 1;
                end else begin
                    osr <= osr << true_shift_count;
                    output_shift_counter <= (output_shift_counter + true_shift_count > 32) ? 6'd32 : output_shift_counter + true_shift_count;
                    fifo_pulled <= 0;
                end
            end
        end else begin
            fifo_pulled <= 0;
        end
    end
end

endmodule
