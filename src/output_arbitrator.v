module output_arbitrator(
    input [1:0] core_select [31:0],
    input [31:0] fsm_output [3:0][3:0],
    input [31:0] fsm_drive [3:0][3:0],
    output reg [31:0] gpio_output,
    output reg [31:0] gpio_drive
);

reg [31:0] core_output [3:0];
reg [31:0] core_drive [3:0];

// FSM Output/Drive are indexed [core][fsm][bit]
// Core Output/Drive are indexed [core][bit]

// Lowest indexed FSM gets priority for each core
integer a, i;
always @(*) begin
    for (a = 0; a < 4; a = a + 1) begin
        for (i = 0; i < 32; i = i + 1) begin
            if (fsm_drive[a][0][i]) begin
                core_drive[a][i] = 1;
                core_output[a][i] = fsm_output[a][0][i];
            end else if (fsm_drive[a][1][i]) begin
                core_drive[a][i] = 1;
                core_output[a][i] = fsm_output[a][1][i];
            end else if (fsm_drive[a][2][i]) begin
                core_drive[a][i] = 1;
                core_output[a][i] = fsm_output[a][2][i];
            end else if (fsm_drive[a][3][i]) begin
                core_drive[a][i] = 1;
                core_output[a][i] = fsm_output[a][3][i];
            end else begin
                core_drive[a][i] = 0;
                core_output[a][i] = 0;
            end
        end
    end
end

// Select which core drives gpio
integer j;
always @(*) begin
    for (j = 0; j < 32; j = j + 1) begin
        gpio_output[j] = core_output[core_select[j]][j];
        gpio_drive[j] = core_drive[core_select[j]][j];
    end
end

endmodule