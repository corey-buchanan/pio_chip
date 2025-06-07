module pio_core(
    input logic clk, rst,
    input logic [31:0] gpio_input,
    output logic [31:0] core_output,
    output logic [31:0] core_drive
    );

    logic [4:0] pc;
    logic [15:0] instruction;
    logic [15:0] instr_in;
    logic [4:0] write_addr;
    logic write_en;

    // TODO: Remove when spi is wired up
    initial begin
        write_addr = 5'b00000;
        write_en = 0;
    end

    // TODO: Wire these up properly
    logic push_en, pop_en;
    logic [31:0] fifo_in, fifo_out;

    // TODO: Add the other FSMs later
    fsm fsm(
        .clk(clk),
        .rst(rst),
        .external_push_en(push_en),
        .external_pop_en(pop_en),
        .external_data_in(fifo_in),
        .instruction(instruction),
        .pc(pc),
        .external_data_out(fifo_out)
    );

    // TODO - Wire these up to the FSMs
    logic [31:0] fsm_output [3:0];
    logic [31:0] fsm_drive [3:0];

    fsm_output_arbitrator fsm_output_arbitrator(
        .fsm_output(fsm_output),
        .fsm_drive(fsm_drive),
        .core_output(core_output),
        .core_drive(core_drive)
    );

    instruction_regfile instruction_regfile(
        .clk(clk),
        .rst(rst),
        .instr_in(instr_in),
        .write_addr(write_addr),
        .write_en(write_en),
        .read_addr(pc),
        .instr_out(instruction)
    );

endmodule