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

    // TODO: Add the other FSMs later
    fsm fsm(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc(pc)
        // TODO - add fifo push/pop en, status, etc.
    );

    // TODO - Wire these up to the FSMs
    logic [31:0] fsm_output [3:0];
    logic [31:0] fsm_drive [3:0];

    // TODO - Wire signals up to fsm
    // These FIFOs are reversable, will need to store direction
    // the names right now refer to their default direction
    // I'll have a look at the docs to see if that's the best way
    // to name these fifos
    logic [31:0] tx_data_in;
    logic tx_push_en;
    logic tx_pop_en;
    logic [31:0] tx_data_out;
    logic [1:0] tx_status;
    logic [2:0] tx_fifo_count;

    logic [31:0] rx_data_in;
    logic rx_push_en;
    logic rx_pop_en;
    logic [31:0] rx_data_out;
    logic [1:0] rx_status;
    logic [2:0] rx_fifo_count;

    fifo tx_fifo (
        .clk(clk),
        .rst(rst),
        .data_in(tx_data_in),
        .push_en(tx_push_en),
        .pop_en(tx_pop_en),
        .data_out(tx_data_out),
        .status(tx_status),
        .fifo_count(tx_fifo_count)
    );

    fifo rx_fifo (
        .clk(clk),
        .rst(rst),
        .data_in(gpio_input),
        .push_en(1),
        .pop_en(1),
        .data_out(rx_data_out),
        .status(rx_status),
        .fifo_count(rx_fifo_count)
    );

    // TODO Add OSR

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