module test_wrapper(
    input clk,
    input rst,
    input [3:0] wrap_top,
    input [3:0] wrap_bottom,
    input [3:0] jump,
    input jump_en,
    input pc_en,
    output reg [3:0] pc
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

endmodule
