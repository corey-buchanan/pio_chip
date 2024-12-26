module control_regfile(
    input clk,
    input rst,
    input [31:0] data_in,
    input [9:0] write_addr,
    input write_en,
    input [4:0] read_addr,
    output [31:0] data_out,
    input [3:0] tx_stall, tx_over, rx_under, rx_stall,
    input [7:0] irq_set, irq_clr
    );
    
    reg [31:0] ctrl;                // 0x000 - SC/RW
    reg [31:0] fstat;               // 0x004 - RO
    reg [31:0] fdebug;              // 0x008 - WC
    reg [31:0] flevel;              // 0x00C - RO
    reg [31:0] irq;                 // 0x030 - WC
    reg [31:0] input_sync_bypass    // 0x038 - RW
    reg [31:0] dbg_padout           // 0x03C - RO
    reg [31:0] dbg_padoe            // 0x040 - RO


    // RW - Processor can read/write
    // RO - Processor can read only
    // WO - Processor can write only

    // WC - Set by hardware and cleared by processor (by writing a 1)
    // SC - Set by processor and cleared on next clock cycle
    
    // RF - Read from hardware - likely the fifo buffers, etc.
    // WF - Write to hardware - likely the fifo buffers, etc.
    // RWF - Read from / write to hardware - likely the fifo buffers, etc.
    
    // Reads from the RW/RO/WC registers
    always @(read_addr) begin
        case (read_addr)
            9'h000: data_out = ctrl;
            9'h004: data_out = fstat;
            9'h008: data_out = fdebug;
            9'h00C: data_out = flevel;
            9'h038: data_out = input_sync_bypass;
            9'h03C: data_out = dbg_padout;
            9'h040: data_out = dbg_padoe;
            default: data_out = 32'b0;
        endcase
    end

    // Writes to the SC registers
    always @(posedge clk or posedge rst) begin
        if (rst) ; // Reset logic handled by RW/WO block
        ctrl[11:4] <= (data_in[11:4] & {8{(write_addr == 9'h000 & write_en)}});
    end

    // Writes to the WC registers
    always @(posedge clk or posedge rst) begin
        if (rst) ; // Reset logic handled by RW/WO block
        else if (write_en) begin
            fdebug[27:24] <= (fdebug[27:24] | tx_stall[3:0]) & ~(data_in[27:24] & {4{(write_addr == 9'h008 & write_en)}});
            fdebug[19:16] <= (fdebug[19:16] | tx_over[3:0]) & ~(data_in[19:16] & {4{(write_addr == 9'h008 & write_en)}});
            fdebug[11:8] <= (fdebug[11:8] | rx_under[3:0]) & ~(data_in[11:8] & {4{(write_addr == 9'h008 & write_en)}});
            fdebug[3:0] <= (fdebug[3:0] | rx_stall[3:0]) & ~(data_in[3:0] & {4{(write_addr == 9'h008 & write_en)}});
            irq[7:0] <= (irq[7:0] | irq_set[7:0]) & ~irq_clr[7:0] & ~(data_in[7:0] & {8{(write_addr == 9'h008 & write_en)}});
        end
    end

    // Writes to the RW/WO registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // TODO - write the default state of all registers
        end else if (write_en) begin
            case (write_addr)
                9'h000: ctrl[3:0] <= data_in[3:0];
                9'h038: input_sync_bypass <= data_in;
                default: ;
            endcase
        end
    end
endmodule
