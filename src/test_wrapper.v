module test_wrapper(
    input clk,
    input rst,
    input [3:0] wrap_top,
    input [3:0] wrap_bottom,
    input [3:0] jump,
    input jump_en,
    input pc_en,
    output reg [3:0] pc,
    input [15:0] data_in,
    input [3:0] write_addr,
    input write_en,
    input [3:0] read_addr,
    output [15:0] data_out
    );

    initial begin
        pc = 4'b0;
    end

    program_counter uut_program_counter(
        .clk(clk),
        .rst(rst),
        .wrap_top(wrap_top),
        .wrap_bottom(wrap_bottom),
        .jump(jump),
        .jump_en(jump_en),
        .pc_en(pc_en),
        .pc(pc)
    );

    instruction_regfile uut_instruction_regfile(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .write_addr(write_addr),
        .write_en(write_en),
        .read_addr(read_addr),
        .data_out(data_out)
    );

endmodule
