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
    logic rx_push_en, tx_pop_en;
    logic [31:0] rx_data_in, tx_data_out;
    logic [1:0] tx_status, rx_status;
    logic [2:0] tx_fifo_count, rx_fifo_count;

    fifo rx_fifo(
        .clk(clk),
        .rst(rst),
        .data_in(rx_data_in),
        .push_en(rx_push_en),
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
        .pop_en(tx_pop_en),
        .data_out(tx_data_out),
        .status(tx_status),
        .fifo_count(tx_fifo_count)
    );

    // OSR Management
    logic autopull;
    logic [4:0] pull_thresh; // Will be a register input
    logic [5:0] true_pull_thresh;
    logic [4:0] out_shift_count; // Might be a register input???
    logic [5:0] true_out_shift_count;
    logic [5:0] osr_shift_counter;

    osr_data_t osr_data;
    osr_control_t osr_control;

    assign osr_control.shift_count = true_out_shift_count;

    always_comb begin
        if (pull_thresh == 0) true_pull_thresh = 6'd32;
        else true_pull_thresh = {1'b0, pull_thresh};

        if (out_shift_count == 0) true_out_shift_count = 6'd32;
        else true_out_shift_count = {1'b0, out_shift_count};
    end

    output_shift_register osr(
        .clk(clk),
        .rst(rst),
        .data(osr_data),
        .control(osr_control)
    );

    // Logic for: jump, jump_en, pc_en
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            jump <= 5'b0;
            jump_en <= 0;
            pc_en <= 0;
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

                PUSH_PULL: begin
                    jump_en <= 0;
                    if (!instruction[7]) begin
                        // PUSH
                        if (rx_fifo_count == 4 && !external_pop_en) begin
                            if (instruction[5]) begin
                                // Block = 1 - stall if RX FIFO is full
                                pc_en <= 0;
                            end else begin
                                // Block = 0 - do nothing
                                pc_en <= 1;
                            end
                        end else begin
                            pc_en <= 1;
                        end
                    end
                    else begin
                        // PULL
                        // We will need similar logic to this for the autopull
                        if (tx_fifo_count == 0 && !external_push_en) begin
                            if (instruction[5]) begin
                                // Block = 1 - stall if TX FIFO is empty
                                pc_en <= 0;
                            end else begin
                                // Block = 0 - pull from empty means copy scratch X to OSR
                                pc_en <= 1;
                            end
                        end else begin
                            pc_en <= 1;
                        end
                    end
                end

                // MOV

                // IRQ

                default: begin
                    jump_en <= 0;
                    pc_en <= 1;
                end
            endcase
        end
    end

    // Logic for x, y
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 32'b0;
            y <= 32'b0;
        end else begin
            case (instruction[15:13])
                MOV: begin
                    if (instruction[7:5] == mov_src_dest_t.X) begin
                    // If X is the destination
                        case (instruction[2:0]) // Source
                            mov_src_dest_t.PINS: begin
                                // TODO - implement
                            end
                            mov_src_dest_t.X: begin
                                // NOOP
                            end
                            mov_src_dest_t.Y: begin
                                x <= y;
                            end
                            NULL: begin
                                x <= 32'b0;
                            end
                            EXEC: begin
                                // TODO - implement
                            end
                            PC: begin
                                // TODO - implement
                            end
                            ISR: begin
                                // TODO - implement
                            end
                            OSR: begin
                                x <= osr_data.osr;
                            end
                        endcase
                    end else if (instruction[7:5] == mov_src_dest_t.Y) begin
                    // If Y is the destination
                        case (instruction[2:0]) // Source
                            mov_src_dest_t.PINS: begin
                                // TODO - implement
                            end
                            mov_src_dest_t.X: begin
                                y <= x;
                            end
                            mov_src_dest_t.Y: begin
                                // NOOP
                            end
                            NULL: begin
                                y <= 32'b0;
                            end
                            EXEC: begin
                                // TODO - implement
                            end
                            PC: begin
                                // TODO - implement
                            end
                            ISR: begin
                                // TODO - implement
                            end
                            OSR: begin
                                y <= osr_data.osr;
                            end
                        endcase
                    end
                end
                SET: begin
                    case (instruction[7:5])
                        set_dest_t.X: begin
                            x[31:5] <= 27'b0;
                            x[4:0] <= instruction[4:0];
                        end
                        set_dest_t.Y: begin
                            y[31:5] <= 27'b0;
                            y[4:0] <= instruction[4:0];
                        end
                    endcase
                end
            endcase
        end
    end

    // Logic for tx_pop_en, rx_push_en
    // Probabily will have most of the OSR/ISR logic here
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_pop_en <= 0;
            rx_push_en <= 0;
        end else begin
            case (instruction[15:13])
                // TODO: MOV, OUT
                MOV: begin

                end
                OUT: begin

                end
                PUSH_PULL: begin
                    if (!instruction[7]) begin
                        // PUSH
                        if (rx_fifo_count == 4 && !external_pop_en) begin
                            // Can't push to FIFO
                            rx_push_en <= 0; // TODO - wire up autopull logic for other instructions
                        end else begin
                            // Can push to FIFO
                            if (instruction[6] /* isr_input_shift_counter < autopush_threshold */) begin
                                rx_push_en <= 0;
                            end else begin
                                rx_push_en <= 1;
                            end
                        end
                    end
                    else begin
                        // PULL
                        // We will need similar logic to this for the autopull
                        if (tx_fifo_count == 0 && !external_push_en) begin
                            // Can't pull from FIFO
                            tx_pop_en <= 1; // TODO - Wire up autopull logic for other instructions
                            if (!instruction[5]) begin
                                // Block = 0 - pull from empty means copy scratch X to OSR
                                osr_data.data_in <= x;
                                osr_control.osr_load <= 1;
                            end
                        end else begin
                            // Can pull from FIFO
                            if (instruction[6] /* osr_output_shift_counter < autopull_threshold */) begin
                                // IfEmpty = 1 - do nothing unless total output shift count > autopull threshold
                                tx_pop_en <= 0;
                            end else begin
                                tx_pop_en <= 1;
                            end
                        end
                    end
                end
                default: begin
                    // TODO: Autopull logic for non MOV, PULL, OUT instructions
                end
            endcase
        end
    end

endmodule