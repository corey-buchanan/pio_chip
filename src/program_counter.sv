module program_counter(
    input logic clk, rst,
    input logic [4:0] wrap_top,
    input logic [4:0] wrap_bottom,
    input logic [4:0] jump,
    input logic jump_en,
    input logic pc_en,
    output logic [4:0] pc
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
        else begin
            // Otherwise stalls
            pc <= pc;
        end
    end

endmodule