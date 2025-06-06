typedef struct packed {
    logic empty, full;
} fifo_status;

module fifo(
    input logic rst, clk,
    input logic[31:0] data_in,
    input logic push_en, pop_en,
    output logic [31:0] data_out,
    output fifo_status status,
    output logic [2:0] fifo_count // 0-4
);

assign status.empty = fifo_count == 3'b000;
assign status.full = fifo_count == 3'b100;

// Read from head, write to tail
logic [31:0] memory [0:3];
logic [1:0] head, tail;

logic can_push, can_pop;

assign can_push = push_en && !status.full;
assign can_pop = pop_en && !status.empty;

// FIFO memory and pointer logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Clear all the memory
        for (int i = 0; i < 4; i = i + 1) begin
            memory[i] <= 32'b0;
        end
        // Reset pointers and flags
        head <= 2'b00;
        tail <= 2'b00;
        data_out <= 32'b0;
    end else begin
        // Push
        if (can_push) begin
            memory[head] <= data_in;
            head <= head + 1;
        end
        // Pop
        if (can_pop) begin
            data_out <= memory[tail];
            tail <= tail + 1;
        end
    end
end

// Counter logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fifo_count <= 3'b000;
    end else begin
        if (can_push && can_pop) begin
            fifo_count <= fifo_count;
        end else if (can_push) begin
            fifo_count <= fifo_count + 1;
        end else if (can_pop) begin
            fifo_count <= fifo_count - 1;
        end
    end
end

endmodule