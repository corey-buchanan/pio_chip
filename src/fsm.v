module fsm(
    input clk,
    input rst,
    input [15:0] instruction,
    output reg [4:0] pc
    );

    reg [4:0] wrap_top, wrap_bottom;
    reg [4:0] jump;
    reg jump_en, pc_en;

    // Scratch registers
    reg [31:0] x, y;

    // Remove when control registers are wired up
    initial begin
        wrap_top = 5'b00000;
        wrap_bottom = 5'b11111;
    end

    // The chip in general might need two resets:
    // 1) One that resets everything including instruction memory and control registers
    // 2) One that restarts the state machine, etc., but leaves instruction memory and control registers alone.
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

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 32'b0;
            y <= 32'b0;
        end
        else begin
            // JMP
            if (instruction[15:13] == 3'b000) begin
                jump <= instruction[4:0];
                pc_en <= 1;

                if (instruction[7:5] == 3'b000) begin
                    // Unconditional
                    jump_en <= 1;
                end else if (instruction[7:5] == 3'b001) begin
                    // If !X
                    if (x == 0) begin
                        jump_en <= 1;
                    end
                    else begin
                        jump_en <= 0;
                    end
                end else begin
                    jump_en <= 0;
                end
            end
            // WAIT
            else if (instruction[15:13] == 3'b001) begin
                // Do nothing for now
                // We'll pretend it's a no-op instruction for the moment
                jump_en <= 0;
                pc_en <= 1;
            end
            // IN

            // OUT

            // PUSH

            // PULL

            // MOV

            // IRQ

            // SET
            else if (instruction[15:13] == 3'b111) begin
                jump_en <= 0;
                pc_en <= 1;
                if (instruction[7:5] == 3'b001) begin
                    x[31:5] <= 27'b0;
                    x[4:0] <= instruction[4:0];
                end else if (instruction[7:5] == 3'b010) begin
                    y[31:5] <= 27'b0;
                    y[4:0] <= instruction[4:0];
                end
            end
            else begin
                jump_en <= 0;
                pc_en <= 1;
            end
        end
    end

endmodule