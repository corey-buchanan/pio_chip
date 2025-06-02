module fifo(
    input rst,
    input clk,
    input [31:0] data_in,
    input push_en,
    input pop_en,
    output reg [31:0] data_out,
    output empty,
    output full,
    output almost_empty,
    output almost_full
);

assign empty = head == tail;
assign full = wrap_around & (head[1:0] == tail[1:0]);
assign wrap_around = head[2] ^ tail[2];

assign almost_empty = tail + 1 == head;
assign almost_full = wrap_around & (head[1:0] + 1 == tail[1:0]);

// Read from head, write to tail
reg [31:0] memory [0:3];
reg [2:0] head;
reg [2:0] tail;
wire wrap_around;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Clear all the memory
        for (int i = 0; i < 4; i = i + 1) begin
            memory[i] <= 32'b0;
        end
        // Reset pointers and flags
        head <= 3'b000;
        tail <= 3'b000;
        wrap_around <= 1'b0;
        data_out <= 32'b0;
    end else begin
        // Push
        if (push_en && !full) begin
            memory[head[1:0]] <= data_in;
            head <= head + 1;
        end
        // Pop
        if (pop_en && !empty) begin
            data_out <= memory[tail[1:0]];
            tail <= tail + 1;
        end
    end
end

endmodule