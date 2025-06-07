module pio_chip(
    input logic clk, rst,
    output logic [1:0] counter, // TODO - what is this doing here? clock divider?
    inout logic [31:0] gpio
);

    logic [1:0] core_select [31:0];

    logic [31:0] core_0_output, core_1_output, core_2_output, core_3_output;
    logic [31:0] core_0_drive, core_1_drive, core_2_drive, core_3_drive;

    logic [31:0] core_output [3:0];
    logic [31:0] core_drive [3:0];

    logic [31:0] out_data;
    logic [31:0] sync_bypass;
    logic [31:0] dir;
    logic [31:0] pde, pue;
    logic [31:0] in_data;

    pio_core core_0(
        .clk(clk),
        .rst(rst),
        .core_output(core_0_output),
        .core_drive(core_0_drive),
        .gpio_input(in_data)
    );

    pio_core core_1(
        .clk(clk),
        .rst(rst),
        .core_output(core_1_output),
        .core_drive(core_1_drive),
        .gpio_input(in_data)
    );

    pio_core core_2(
        .clk(clk),
        .rst(rst),
        .core_output(core_2_output),
        .core_drive(core_2_drive),
        .gpio_input(in_data)
    );

    pio_core core_3(
        .clk(clk),
        .rst(rst),
        .core_output(core_3_output),
        .core_drive(core_3_drive),
        .gpio_input(in_data)
    );

    assign core_output[0] = core_0_output;
    assign core_output[1] = core_1_output;
    assign core_output[2] = core_2_output;
    assign core_output[3] = core_3_output;

    assign core_drive[0] = core_0_drive;
    assign core_drive[1] = core_1_drive;
    assign core_drive[2] = core_2_drive;
    assign core_drive[3] = core_3_drive;

    core_output_arbitrator core_output_arbitrator(
        .core_select(core_select),
        .core_output(core_output),
        .core_drive(core_drive),
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
