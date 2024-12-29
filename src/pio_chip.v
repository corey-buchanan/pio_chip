module pio_chip(
    input clk,
    input rst,
    output reg[1:0] counter,
    inout [31:0] gpio
);

    reg [1:0] core_select [31:0];

    wire [31:0] core_0_output [3:0];
    wire [31:0] core_1_output [3:0];
    wire [31:0] core_2_output [3:0];
    wire [31:0] core_3_output [3:0];

    wire [31:0] core_0_drive [3:0];
    wire [31:0] core_1_drive [3:0];
    wire [31:0] core_2_drive [3:0];
    wire [31:0] core_3_drive [3:0];

    wire [31:0] fsm_output [3:0][3:0];
    wire [31:0] fsm_drive [3:0][3:0];

    wire [31:0] out_data;
    reg [31:0] sync_bypass;
    wire [31:0] dir;
    reg [31:0] pde, pue;
    reg [31:0] in_data;

    pio_core core_0(
        .clk(clk),
        .rst(rst),
        .fsm_output(core_0_output),
        .fsm_drive(core_0_drive),
        .gpio_input(in_data)
    );

    pio_core core_1(
        .clk(clk),
        .rst(rst),
        .fsm_output(core_1_output),
        .fsm_drive(core_1_drive),
        .gpio_input(in_data)
    );

    pio_core core_2(
        .clk(clk),
        .rst(rst),
        .fsm_output(core_2_output),
        .fsm_drive(core_2_drive),
        .gpio_input(in_data)
    );

    pio_core core_3(
        .clk(clk),
        .rst(rst),
        .fsm_output(core_3_output),
        .fsm_drive(core_3_drive),
        .gpio_input(in_data)
    );

    assign fsm_output[0] = core_0_output;
    assign fsm_output[1] = core_1_output;
    assign fsm_output[2] = core_2_output;
    assign fsm_output[3] = core_3_output;

    assign fsm_drive[0] = core_0_drive;
    assign fsm_drive[1] = core_1_drive;
    assign fsm_drive[2] = core_2_drive;
    assign fsm_drive[3] = core_3_drive;

    output_arbitrator output_arbitrator(
        .core_select(core_select),
        .fsm_output(fsm_output),
        .fsm_drive(fsm_drive),
        .gpio_output(out_data),
        .gpio_drive(dir)
    );

    gpio gpio_bank(
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

endmodule
