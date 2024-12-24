module test_wrapper(
    input clk,
    input rst,
    input [4:0] wrap_top,
    input [4:0] wrap_bottom,
    input [4:0] jump,
    input jump_en,
    input pc_en,
    output reg [4:0] pc,
    input [15:0] data_in,
    input [4:0] write_addr,
    input write_en,
    input [4:0] read_addr,
    output reg [15:0] data_out,
    input [15:0] instruction
    );

    initial begin
        pc = 5'b0;
        data_out = 16'b0;
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

    fsm uut_fsm(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc(pc)
    );

endmodule
