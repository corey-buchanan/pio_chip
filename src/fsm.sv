`include "types.svh"

module fsm(
    input logic clk, rst,
    input logic external_push_en, external_pop_en,
    input logic [31:0] external_data_in,
    input logic [15:0] instruction,
    output logic [4:0] pc,
    output logic [31:0] external_data_out
    );

    logic [4:0] wrap_top, wrap_bottom;
    logic [4:0] jump;
    logic jump_en, pc_en;

    // Scratch registers
    logic [31:0] x, y;

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

    // FIFO Management
    // TODO: Split empty_next_cycle and full_next_cycle by TX and RX
    logic empty_next_cycle, full_next_cycle; // TODO: Figure out what to do on non-push/pull instructions, interactions w/ autopull
    logic pull_op, push_op;
    logic [31:0] rx_data_in, tx_data_out;
    logic [1:0] tx_status, rx_status;
    logic [2:0] tx_fifo_count, rx_fifo_count;

    fifo rx_fifo(
        .clk(clk),
        .rst(rst),
        .data_in(rx_data_in),
        .push_en(push_op),
        .pop_en(external_pop_en),
        .data_out(external_data_out),
        .status(rx_status),
        .fifo_count(rx_fifo_count)
    );

    fifo tx_fifo(
        .clk(clk),
        .rst(rst),
        .data_in(external_data_in),
        .push_en(external_push_en),
        .pop_en(push_op),
        .data_out(tx_data_out),
        .status(tx_status),
        .fifo_count(tx_fifo_count)
    );

    // OSR Management
    logic [31:0] osr_mov_in;
    logic [1:0] osr_mov;

    output_shift_register osr(
        .clk(clk),
        .rst(rst),
        .mov_in(osr_mov_in),
        .mov_out(),
        .mov(osr_mov),
        .fifo_in(tx_data_out),
        .fifo_pull(),
        .data_out(),
        .shift_en(),
        .pull_thresh(),
        .shiftdir(),
        .autopull(),
        .shift_count(),
        .fifo_pulled(),
        .output_shift_counter()
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 32'b0;
            y <= 32'b0;
        end
        else begin
            case (instruction[15:13])
                JMP: begin
                    jump <= instruction[4:0];
                    pc_en <= 1;

                    case(instruction[7:5])
                        UNCOND: begin
                            // Unconditional
                            jump_en <= 1;
                        end
                        X_ZERO: begin
                            // If !X (X zero)
                            if (x == 0) jump_en <= 1;
                            else jump_en <= 0;
                        end
                        X_NZ_DEC: begin
                            // If X-- (X non-zero prior to decrement)
                            if (x != 0) jump_en <= 1;
                            else jump_en <= 0;
                            x <= x - 1;
                        end
                        Y_ZERO: begin
                            // If !Y (Y zero)
                            if (y == 0) jump_en <= 1;
                            else jump_en <= 0;
                        end
                        Y_NZ_DEC: begin
                            // If Y-- (Y non-zero prior to decrement)
                            if (y != 0) jump_en <= 1;
                            else jump_en <= 0;
                            y <= y - 1;
                        end
                        X_NE_Y: begin
                            // If X!=Y
                            if (x != y) jump_en <= 1;
                            else jump_en <= 0;
                        end
                        PIN: begin
                            // If push_en is set
                            if (1) jump_en <= 1; // TODO - wire up to EXECCTRL_JMP_PIN
                            else jump_en <= 0;
                        end
                        OSR_NOT_EMPTY: begin
                            // If OSR is not empty
                            if (1) jump_en <= 1; // TODO - wire up to OSR empty signal
                            else jump_en <= 0;
                        end
                        default: begin
                            jump_en <= 0;
                        end
                    endcase
                end
                WAIT: begin
                    // Do nothing for now
                    // We'll pretend it's a no-op instruction for the moment
                    jump_en <= 0;
                    pc_en <= 1;
                end
                // IN

                // OUT

                // TODO - I may need to draw this out as a[n] [extended] state graph - it's getting a bit complex
                PUSH_PULL: begin
                    if (!instruction[7]) begin
                        // PUSH

                    end
                    else begin
                        // PULL
                        jump_en <= 0;
                        if (instruction[5]) begin
                            // Block = 1 - stall if TX FIFO is empty
                        end else begin
                            // Block = 0 - pull from empty means copy scratch X to OSR
                        end
                        
                        if (instruction[6]) begin
                            // IfEmpty = 1 - do nothing unless total output shift count > autopull threshold
                        end
                        // We will need similar logic to this for the autopull
                        if ((tx_fifo_count == 1 && !external_push_en)
                            || (empty_next_cycle && !external_push_en)) begin
                            empty_next_cycle <= 1; // Empty from last cycle, can't pull
                            if (instruction[6]) begin
                                // Do nothing
                                pc_en <= 1;
                            end else begin
                                if (instruction[5]) begin
                                    // Stall
                                    pc_en <= 0;
                                end else begin
                                    // Copy X to OSR
                                    // TODO - wire up osr_mov_in, osr_mov in other cases
                                    osr_mov_in <= x;
                                    osr_mov <= 2'b01;
                                    pc_en <= 1;
                                end
                            end
                        end else begin 
                            if (empty_next_cycle && external_push_en) begin
                                empty_next_cycle <= 1; // Will be empty, but we can pull
                            end else begin
                                empty_next_cycle <= 0; // Not empty, so we can pull
                            end
                            // Can pull
                            // TODO - wire up osr_output_shift_counter
                            if (instruction[6] /* && osr_output_shift_counter < autopull_threshold */) begin
                                // Do nothing because autopull threshold is not exceeded
                                pc_en <= 1;
                            end else begin 
                                // Pull from TX FIFO
                                pull_op <= 1;
                                pc_en <= 1;
                            end
                        end
                    end
                end

                // MOV

                // IRQ

                SET: begin
                    jump_en <= 0;
                    pc_en <= 1;
                    case (instruction[7:5])
                        3'b001: begin
                            x[31:5] <= 27'b0;
                            x[4:0] <= instruction[4:0];
                        end
                        3'b010: begin
                            y[31:5] <= 27'b0;
                            y[4:0] <= instruction[4:0];
                        end
                        default: begin
                        end
                    endcase
                end
                default: begin
                    jump_en <= 0;
                    pc_en <= 1;
                end
            endcase
        end
    end

endmodule