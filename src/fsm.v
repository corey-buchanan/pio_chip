module fsm(
    input clk,
    input rst,
    input [15:0] instruction,
    output reg [4:0] pc
    );

    reg [4:0] wrap_top, wrap_bottom;
    reg [4:0] jump;
    reg jump_en, pc_en;

    // Remove when control registers are wired up
    initial begin
        wrap_top = 5'b00000;
        wrap_bottom = 5'b11111;
    end

    program_counter program_counter(
        .clk(clk),
        .rst(rst),
        .wrap_top(wrap_top),
        .wrap_bottom(wrap_bottom),
        .jump(jump),
        .jump_en(jump_en),
        .pc_en(pc_en),
        .pc(pc)
    );

    always @(posedge clk) begin
        // JMP
        if (instruction[15:13] == 3'b000) begin
            jump <= instruction[4:0];
            jump_en <= 1;
        end
        // WAIT
        else if (instruction[15:13] == 3'b001) begin
            // Do nothing for now
            // We'll pretend it's a no-op instruction
            jump_en <= 0;
        end
        else begin
            jump_en <= 0;
        end
        // IN

        // OUT

        // PUSH

        // PULL

        // MOV

        // IRQ

        // SET
    end

endmodule