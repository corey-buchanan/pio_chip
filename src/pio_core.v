module pio_core(
    input clk,
    input rst,
    input [31:0] gpio_input,
    output reg [31:0] core_output,
    output reg [31:0] core_drive
    );

    reg [4:0] pc;
    reg [15:0] instruction;
    reg [15:0] data_in;
    reg [4:0] write_addr;
    reg write_en;

    // Remove when spi is wired up
    initial begin
        write_addr = 5'b00000;
        write_en = 0;
    end

    // Add the other FSMs later
    fsm fsm(
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .pc(pc)
    );

    // TODO - Wire these up to the FSMs
    reg [31:0] fsm_output [3:0];
    reg [31:0] fsm_drive [3:0];

    // TODO Add fifos

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
        .data_in(data_in),
        .write_addr(write_addr),
        .write_en(write_en),
        .read_addr(pc),
        .data_out(instruction)
    );

endmodule