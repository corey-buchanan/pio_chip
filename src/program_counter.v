module program_counter(
    input clk,
    input rst,
    input [3:0] wrap_top,
    input [3:0] wrap_bottom,
    input [3:0] jump,
    input jump_en,
    input pc_en,
    output reg [3:0] pc
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= wrap_top;
        end else if (pc_en) begin
            if (jump_en) begin
                // Jump instruction
                pc <= jump;
            end else if (pc == wrap_bottom) begin
                // Reached the bottom of the program wrapper
                pc <= wrap_top;
            end else begin
                // Normal flow
                pc <= pc + 1;
            end
        end

        // Otherwise stalls
    end

endmodule