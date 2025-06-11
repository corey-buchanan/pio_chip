`include "types.svh"

module test_wrapper(
    input logic clk, rst,
    // PROGRAM COUNTER
    input logic [4:0] wrap_top, wrap_bottom,
    input logic [4:0] jump,
    input logic jump_en,
    input logic pc_en,
    output logic [4:0] pc,
    // INSTRUCTION REGFILE
    input logic [15:0] instr_in,
    input logic [4:0] write_addr,
    input logic write_en,
    input logic [4:0] read_addr,
    output logic [15:0] instr_out,
    // GPIO
    input logic [31:0] out_data, sync_bypass, dir, pde, pue,
    output logic [31:0] in_data,
    inout logic [31:0] gpio,
    // FSM OUTPUT ARBITRATOR
    input logic [31:0] fsm_output [3:0],
    input logic [31:0] fsm_drive [3:0],
    output logic [31:0] fsm_core_output,
    output logic [31:0] fsm_core_drive,
    // CORE OUTPUT ARBITRATOR
    input logic [1:0] core_select [31:0],
    input logic [31:0] core_output [3:0],
    input logic [31:0] core_drive [3:0],
    output logic [31:0] gpio_output,
    output logic [31:0] gpio_drive,
    // OSR
    input logic [31:0] osr_data_in,
    output logic [31:0] osr, osr_shift_out,
    input logic osr_load,
    input logic osr_shift_en,
    input logic osr_shiftdir,
    input logic [5:0] osr_shift_count,
    // FIFO
    input logic [31:0] fifo_in,
    input logic push_en,
    input logic pop_en,
    output logic [31:0] fifo_out,
    output logic empty,
    output logic full,
    output logic [2:0] fifo_count,
    output [31:0] fifo_memory [0:3],
    output logic [1:0] fifo_head,
    output logic [1:0] fifo_tail,
    // FSM
    input logic [15:0] instruction,
    output logic [4:0] fsm_pc,
    input logic external_push_en, external_pop_en,
    input logic [31:0] external_data_in,
    output logic [31:0] external_data_out,
    input logic out_shiftdir,
    output logic [31:0] x, y
    );

    initial begin
        pc = 5'b0;
        fsm_pc = 5'b0;
        instr_out = 16'b0;
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
        .instr_in(instr_in),
        .write_addr(write_addr),
        .write_en(write_en),
        .read_addr(read_addr),
        .instr_out(instr_out)
    );

    fsm uut_fsm(
        .clk(clk),
        .rst(rst),
        .external_push_en(external_push_en),
        .external_data_in(external_data_in),
        .external_pop_en(external_pop_en),
        .instruction(instruction),
        .pc(fsm_pc),
        .external_data_out(external_data_out),
        .out_shiftdir(out_shiftdir)
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

    fsm_output_arbitrator uut_fsm_output_arbitrator(
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

    output_shift_register uut_output_shift_register(
        .clk(clk),
        .rst(rst),
        .data_in(osr_data_in),
        .osr(osr),
        .shift_out(osr_shift_out),
        .load(osr_load),
        .shift_en(osr_shift_en),
        .shiftdir(osr_shiftdir),
        .shift_count(osr_shift_count)
    );

    fifo uut_fifo(
        .clk(clk),
        .rst(rst),
        .data_in(fifo_in),
        .push_en(push_en),
        .pop_en(pop_en),
        .data_out(fifo_out),
        .status(status),
        .fifo_count(fifo_count)
    );

    fifo_status status;
    assign empty = status.empty;
    assign full = status.full;

    assign fifo_memory = uut_fifo.memory;
    assign fifo_head = uut_fifo.head;
    assign fifo_tail = uut_fifo.tail;

endmodule
