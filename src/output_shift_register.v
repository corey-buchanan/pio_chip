module output_shift_register(
    input clk,
    input rst,
    input [31:0] mov_in,
    input mov_en, // via MOV instruction
    input [31:0] fifo_in,
    input fifo_pull, // via PULL instruction
    output reg [31:0] data_out,
    input shift_en, // via OUT instruction
    input [4:0] pull_thresh, // 0 for a value of 32
    input shiftdir, // 0 = left, 1 = right
    input autopull,
    input [4:0] shift_count, // Set by OUT instruction
    output fifo_pulled, // Signal to the FIFO that we've pulled data
    output reg [5:0] output_shift_counter // How many bits to shift in from the FIFO on pull: 0 = full, 32 = empty
);

reg [31:0] osr;
reg [5:0] pull_threshold;
reg [5:0] true_shift_count;
reg [5:0] current_shift_counter;

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
        if (mov_en) begin
            data_out <= 32'b0;
            osr <= mov_in;
            output_shift_counter <= 6'd0;
            fifo_pulled <= 0;
        end else if (fifo_pull) begin
            data_out <= 32'b0;
            if (shiftdir) begin
                // Shift into the left side of OSR
                for (int i = 0; i < current_shift_counter; i = i + 1) begin
                    for (int i = 0; i < 32; i = i + 1) begin
                        if (i < 32 - {26'b0, current_shift_counter}) begin
                            osr[i] <= osr[i];
                        end else begin
                            osr[i] <= fifo_in[i - (32 - {26'b0, current_shift_counter})];
                        end
                    end
                end
            end else begin
                // Shift into the right side of OSR
                for (int i = 0; i < 32; i = i + 1) begin
                    if (i < current_shift_counter) begin
                        osr[i] <= fifo_in[i];
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
                    if (i + {26'b0, true_shift_count} < 32) begin
                        data_out[i] <= 1'b0;
                    end else begin
                        data_out[i] <= osr[{26'b0, true_shift_count} - i - 1];
                    end
                end

                if (autopull && (current_shift_counter >= pull_threshold)) begin
                    // Shift into the left side of OSR
                    for (int i = 0; i < 32; i = i + 1) begin
                        if (i < 32 - {26'b0, current_shift_counter}) begin
                            osr[i] <= osr[i + {26'b0, true_shift_count}];
                        end else begin
                            osr[i] <= fifo_in[i - (32 - {26'b0, current_shift_counter})];
                        end
                    end
                    fifo_pulled <= 1;
                end else begin
                    osr <= osr >> true_shift_count;
                    fifo_pulled <= 0;
                end
            end else begin
                // Shift osr bits left into right side of data_out
                data_out <= osr >> (32 - {26'b0, true_shift_count});
                // for (i = 0; i < 32; i = i + 1) begin
                //     if (i + {26'b0, true_shift_count} < 32) begin
                //         data_out[i] <= 1'b0;
                //     end else begin
                //         data_out[i] <= osr[i + (32 - {26'b0, true_shift_count})];
                //     end
                // end

                if (autopull && (current_shift_counter >= pull_threshold)) begin
                    // Shift into the right side of OSR
                    for (int i = 0; i < 32; i = i + 1) begin
                        if (i < current_shift_counter) begin
                            osr[i] <= fifo_in[i];
                        end else begin
                            osr[i] <= osr[i - {26'b0, true_shift_count}];
                        end
                    end

                    fifo_pulled <= 1;
                end else begin
                    osr <= osr << true_shift_count;
                    fifo_pulled <= 0;
                end
            end

            output_shift_counter <= (output_shift_counter + true_shift_count > 32) ? 6'd32 : output_shift_counter + true_shift_count;
        end else begin
            data_out <= 32'b0;
            fifo_pulled <= 0;
        end
    end
end

endmodule
