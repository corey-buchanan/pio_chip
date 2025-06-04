typedef struct packed {
    logic empty, full, almost_empty, almost_full;
} fifo_status;

module fifo(
    input logic rst, clk,
    input logic[31:0] data_in,
    input logic push_en, pop_en,
    output logic [31:0] data_out,
    output fifo_status status
);

assign status.empty = head == tail;
assign status.full = wrap_around & (head[1:0] == tail[1:0]);
assign wrap_around = head[2] ^ tail[2];

assign status.almost_empty = tail + 1 == head;
assign status.almost_full = wrap_around & (head[1:0] + 1 == tail[1:0]);

// Read from head, write to tail
logic [31:0] memory [0:3];
logic [2:0] head, tail;
logic wrap_around;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Clear all the memory
        for (int i = 0; i < 4; i = i + 1) begin
            memory[i] <= 32'b0;
        end
        // Reset pointers and flags
        head <= 3'b000;
        tail <= 3'b000;
        data_out <= 32'b0;
    end else begin
        // Push
        if (push_en && !status.full) begin
            memory[head[1:0]] <= data_in;
            head <= head + 1;
        end
        // Pop
        if (pop_en && !status.empty) begin
            data_out <= memory[tail[1:0]];
            tail <= tail + 1;
        end
    end
end

endmodule