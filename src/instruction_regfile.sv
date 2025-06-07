module instruction_regfile(
    input logic clk, rst,
    input logic [15:0] instr_in,
    input logic [4:0] write_addr,
    input logic write_en,
    input logic [4:0] read_addr,
    output logic [15:0] instr_out
);
    
logic [15:0] registers [31:0];

assign instr_out = registers[read_addr];

always @(posedge clk or posedge rst) begin
    if (rst) begin
        integer i;
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] <= 16'b0;  // Reset each register to 0
        end
    end else if (write_en) begin
        registers[write_addr] <= instr_in;
    end
end

endmodule
