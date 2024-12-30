module test_wrapper(
    input clk,
    input rst,
    input [4:0] wrap_top, wrap_bottom,
    input [4:0] jump,
    input jump_en,
    input pc_en,
    output reg [4:0] pc,
    input [15:0] data_in,
    input [4:0] write_addr,
    input write_en,
    input [4:0] read_addr,
    output reg [15:0] data_out,
    input [15:0] instruction,
    output reg[4:0] fsm_pc,
    output reg [31:0] x, y,
    input [31:0] out_data, sync_bypass, dir, pde, pue,
    output reg [31:0] in_data,
    inout [31:0] gpio,
    input [1:0] core_select [31:0],
    input [31:0] fsm_output [3:0],
    input [31:0] fsm_drive [3:0],
    output reg [31:0] fsm_core_output,
    output reg [31:0] fsm_core_drive,
    input [31:0] core_output [3:0],
    input [31:0] core_drive [3:0],
    output reg [31:0] gpio_output,
    output reg [31:0] gpio_drive
    );

    initial begin
        pc = 5'b0;
        fsm_pc = 5'b0;
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
        .pc(fsm_pc)
    );
    
    assign x = uut_fsm.x;
    assign y = uut_fsm.y;

    gpio uut_gpio(
        .clk(clk),
        .rst(rst),
        .out_data(out_data),
        .sync_bypass(sync_bypass),
        .dir(dir),
        .pde(pde),
        .pue(pue),
        .in_data(in_data),
        .gpio(gpio)
    );

    fsm_output_arbitrator fsm_output_arbitrator(
        .fsm_output(fsm_output),
        .fsm_drive(fsm_drive),
        .core_output(fsm_core_output),
        .core_drive(fsm_core_drive)
    );

    core_output_arbitrator uut_core_output_arbitrator(
        .core_select(core_select),
        .core_output(core_output),
        .core_drive(core_drive),
        .gpio_output(gpio_output),
        .gpio_drive(gpio_drive)
    );

endmodule
