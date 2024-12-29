module pio_core(
    input clk,
    input rst,
    input [31:0] gpio_input,
    output [31:0] fsm_output [3:0],
    output [31:0] fsm_drive [3:0]
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