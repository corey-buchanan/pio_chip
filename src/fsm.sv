`include "types.svh"

module fsm(
    input logic clk, rst,
    input logic external_push_en, external_pop_en,
    input logic [31:0] external_data_in,
    input logic [15:0] instruction,
    output logic [4:0] pc,
    output logic [31:0] external_data_out,
    // Inputs from control_regfile
    input logic out_shiftdir,
    input autopull,
    input logic [4:0] pull_thresh
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
    fifo_status tx_status, rx_status;
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
    // AUTOPULL
    logic [5:0] true_pull_thresh;
    logic [5:0] out_shift_counter;
    logic osr_empty;
    // OSR DATA
    logic [31:0] osr_data_in;
    logic [31:0] osr_data;
    logic [31:0] osr_shift_out;
    // OSR CTRL
    logic osr_load;
    logic out_shift_en;
    logic [4:0] out_shift_count; // Instruction[4:0]
    logic [5:0] true_out_shift_count;

    assign out_shift_count = instruction[4:0];

    assign osr_empty = out_shift_counter >= true_pull_thresh;

    always_comb begin
        if (pull_thresh == 0) true_pull_thresh = 6'd32;
        else true_pull_thresh = {1'b0, pull_thresh};

        if (out_shift_count == 0) true_out_shift_count = 6'd32;
        else true_out_shift_count = {1'b0, out_shift_count};
    end

    output_shift_register osr(
        .clk(clk),
        .rst(rst),
        .data_in(osr_data_in),
        .osr(osr_data),
        .shift_out(osr_shift_out),
        .load(osr_load),
        .shift_en(out_shift_en),
        .shiftdir(out_shiftdir),
        .shift_count(true_out_shift_count)
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
                            x <= x - 1; // TODO - move this to the x, y logic
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
                            y <= y - 1; // TODO - move this to the x, y logic
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
                            if (!osr_empty) jump_en <= 1;
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
                OUT: begin
                    if (autopull && osr_empty) begin
                        // STALL
                        jump_en <= 0;
                        pc_en <= 0;
                    end else begin
                        jump_en <= 0;
                        pc_en <= 1;
                    end
                end
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
                OUT: begin
                    if (instruction[7:5] == OUT_X) begin
                        x <= osr_shift_out;
                    end else if (instruction[7:5] == OUT_Y) begin
                        y <= osr_shift_out;
                    end
                end
                MOV: begin
                    if (instruction[7:5] == MOV_X) begin
                    // If X is the destination
                        case (instruction[2:0]) // Source
                            MOV_PINS: begin
                                // TODO - implement
                            end
                            MOV_X: begin
                                // NOOP
                            end
                            MOV_Y: begin
                                x <= y;
                            end
                            MOV_NULL: begin
                                x <= 32'b0;
                            end
                            MOV_EXEC: begin
                                // TODO - implement
                            end
                            MOV_PC: begin
                                // TODO - implement
                            end
                            MOV_ISR: begin
                                // TODO - implement
                            end
                            MOV_OSR: begin
                                x <= osr_data;
                            end
                        endcase
                    end else if (instruction[7:5] == MOV_Y) begin
                    // If Y is the destination
                        case (instruction[2:0]) // Source
                            MOV_PINS: begin
                                // TODO - implement
                            end
                            MOV_X: begin
                                y <= x;
                            end
                            MOV_Y: begin
                                // NOOP
                            end
                            MOV_NULL: begin
                                y <= 32'b0;
                            end
                            MOV_EXEC: begin
                                // TODO - implement
                            end
                            MOV_PC: begin
                                // TODO - implement
                            end
                            MOV_ISR: begin
                                // TODO - implement
                            end
                            MOV_OSR: begin
                                y <= osr_data;
                            end
                        endcase
                    end
                end
                SET: begin
                    case (instruction[7:5])
                        SET_X: begin
                            x[31:5] <= 27'b0;
                            x[4:0] <= instruction[4:0];
                        end
                        SET_Y: begin
                            y[31:5] <= 27'b0;
                            y[4:0] <= instruction[4:0];
                        end
                        default: begin

                        end
                    endcase
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    // Logic for tx_pop_en, rx_push_en, out_shift_en, osr_load, out_shift_counter
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_pop_en <= 0;
            rx_push_en <= 0;
            osr_load <= 0;
            osr_data_in <= 32'b0;
            out_shift_en <= 0;
            out_shift_counter <= 6'b0;
        end else begin
            case (instruction[15:13])
                MOV: begin
                    out_shift_en <= 0;
                    if (instruction[7:5] == MOV_ISR) begin // Destination
                        // TODO implement
                        osr_load <= 0;
                    end
                    else if (instruction[7:5] == MOV_OSR) begin // Destination
                        out_shift_counter <= 6'b0;
                        case (instruction[2:0]) // Source
                            MOV_PINS: begin
                                // TODO implement
                                osr_load <= 0;
                            end
                            MOV_X: begin
                                osr_data_in <= x;
                                osr_load <= 1;
                            end
                            MOV_Y: begin
                                osr_data_in <= y;
                                osr_load <= 1;
                            end
                            MOV_NULL: begin
                                osr_data_in <= 32'b0;
                                osr_load <= 1;
                            end
                            MOV_PC: begin
                                // TODO Implement, based on exectrl_statusctrl
                                osr_load <= 0;
                            end
                            MOV_ISR: begin
                                // TODO implement
                                osr_load <= 0;
                            end
                            MOV_OSR: begin
                                // Equivalent to a NOOP
                                osr_load <= 0;
                            end
                            default: begin
                                osr_load <= 0;
                            end
                        endcase
                    end
                end
                OUT: begin
                    // Shift count is assigned combinationally
                    if (autopull && osr_empty) begin
                        // STALL (implemented in PC logic)
                        out_shift_en <= 0;
                        if (tx_status.empty && !external_push_en) begin
                            osr_load <= 0;
                        end
                        else begin
                            osr_data_in <= tx_data_out;
                            osr_load <= 1;
                            out_shift_counter <= 6'b0;
                        end
                    end else begin
                        osr_load <= 0;
                        out_shift_en <= 1;

                        if (out_shift_counter + true_out_shift_count >= true_pull_thresh
                            && !(tx_status.empty && !external_push_en)) begin
                            osr_data_in <= tx_data_out;
                            osr_load <= 1;
                            out_shift_counter <= 6'b0;
                        end else begin
                            out_shift_counter <= out_shift_counter + true_out_shift_count;
                        end
                    end
                end
                PUSH_PULL: begin
                    out_shift_en <= 0;
                    if (!instruction[7]) begin
                        // PUSH
                        // TODO - finish implementing
                        osr_load <= 0;
                        if (rx_fifo_count == 4 && !external_pop_en) begin
                            // Can't push to FIFO
                            rx_push_en <= 0;
                        end else begin
                            // Can push to FIFO
                            if (instruction[6] /* isr_input_shift_counter < pull_thresh */) begin
                                rx_push_en <= 0;
                            end else begin
                                rx_push_en <= 1;
                            end
                        end
                    end
                    else begin
                        // PULL
                        if (tx_status.empty && !external_push_en) begin
                            // Can't pull from FIFO
                            tx_pop_en <= 0;
                            if (instruction[5]) begin
                                // Block = 1 - pull from empty means stall
                                osr_load <= 0;
                            end
                            else begin
                                // Block = 0 - pull from empty means copy scratch X to OSR
                                osr_data_in <= x;
                                osr_load <= 1;
                                out_shift_counter <= 6'b0;
                            end
                        end else begin
                            // Can pull from FIFO
                            if (instruction[6] && osr_empty) begin
                                // IfEmpty = 1 - do nothing unless total output shift count >= autopull threshold
                                tx_pop_en <= 0;
                                osr_load <= 0;
                            end else begin
                                // Pull from FIFO as normal
                                tx_pop_en <= 1;
                                osr_data_in <= tx_data_out;
                                osr_load <= 1;
                                out_shift_counter <= 6'b0;
                            end
                        end
                    end
                end
                default: begin
                    osr_load <= 0;

                    if (out_shift_counter + true_out_shift_count >= true_pull_thresh
                            && !(tx_status.empty && !external_push_en)) begin
                        osr_data_in <= tx_data_out;
                        osr_load <= 1;
                        out_shift_counter <= 6'b0;
                    end else begin
                        osr_load <= 0;
                        out_shift_en <= 0;
                    end
                end
            endcase
        end
    end

endmodule