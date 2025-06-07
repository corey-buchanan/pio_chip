module core_output_arbitrator(
    input logic [1:0] core_select [31:0],
    input logic [31:0] core_output [3:0],
    input logic [31:0] core_drive [3:0],
    output logic [31:0] gpio_output,
    output logic [31:0] gpio_drive
);

// Select which core drives gpio
integer i;
always @(*) begin
    for (i = 0; i < 32; i = i + 1) begin
        gpio_output[i] = core_output[core_select[i]][i];
        gpio_drive[i] = core_drive[core_select[i]][i];
    end
end

endmodule