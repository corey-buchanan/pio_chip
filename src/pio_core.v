module pio_core(
    input clk,
    input rst
    );

    reg [4:0] pc;
    reg [15:0] instruction;
    reg [4:0] write_addr;
    reg write_en;

    // Remove when spi is wired up
    initial begin
        write_addr = 5'b00000;
        write_en = 0;
    end

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