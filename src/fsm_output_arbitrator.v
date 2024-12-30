module fsm_output_arbitrator(
    input [31:0] fsm_output [3:0],
    input [31:0] fsm_drive [3:0],
    output reg [31:0] core_output,
    output reg [31:0] core_drive
);

// Lowest indexed FSM gets priority for each core
integer i;
always @(*) begin
    for (i = 0; i < 32; i = i + 1) begin
        if (fsm_drive[0][i]) begin
            core_drive[i] = 1;
            core_output[i] = fsm_output[0][i];
        end else if (fsm_drive[1][i]) begin
            core_drive[i] = 1;
            core_output[i] = fsm_output[1][i];
        end else if (fsm_drive[2][i]) begin
            core_drive[i] = 1;
            core_output[i] = fsm_output[2][i];
        end else if (fsm_drive[3][i]) begin
            core_drive[i] = 1;
            core_output[i] = fsm_output[3][i];
        end else begin
            core_drive[i] = 0;
            core_output[i] = 0;
        end
    end
end

endmodule