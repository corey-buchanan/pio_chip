module instruction_regfile(
    input clk,
    input rst,
    input [7:0] data_in,
    input [3:0] write_addr,
    input write_en,
    input [3:0] read_addr,
    output [7:0] data_out
    );
    
    reg [15:0] registers [15:0];

    assign data_out = registers[read_addr];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 8'b0;  // Reset each register to 0
            end
        end else if (write_en) begin
            registers[write_addr] <= data_in;
        end
    end
endmodule
