module instruction_regfile(
    input clk,
    input rst,
    input [15:0] data_in,
    input [4:0] write_addr,
    input write_en,
    input [4:0] read_addr,
    output [15:0] data_out
    );
    
    reg [15:0] registers [31:0];

    assign data_out = registers[read_addr];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 16'b0;  // Reset each register to 0
            end
        end else if (write_en) begin
            registers[write_addr] <= data_in;
        end
    end
endmodule
