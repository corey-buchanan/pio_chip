module control_regfile(
    input clk,
    input rst,
    input [31:0] data_in,
    input [9:0] write_addr,
    input write_en,
    input [4:0] read_addr,
    output [31:0] data_out,
    output [3:0] clkdiv_restart, sm_restart, sm_en, // CTRL reg
    input [3:0] tx_empty, tx_full, rx_empty, rx_full, // FSTAT reg
    input [3:0] tx_stall, tx_over, rx_under, rx_stall, // FDEBUG reg
    input [3:0] rx [3:0], // FLEVEL reg
    input [3:0] tx [3:0], // FLEVEL reg
    input [7:0] irq_set, irq_clr, // IRQ reg
    output [31:0] gpio_sync_bypass // input_sync_bypass
    );

    // RW - Processor can read/write
    // RO - Processor can read only
    // WO - Processor can write only

    // WC - Set by hardware and cleared by processor (by writing a 1)
    // SC - Set by processor and cleared on next clock cycle
    
    // RF - Read from hardware - likely the fifo buffers, etc.
    // WF - Write to hardware - likely the fifo buffers, etc.
    // RWF - Read from / write to hardware - likely the fifo buffers, etc.
    
    // Registers
    reg [31:0] ctrl;                    // 0x000 - SC/RW
    reg [31:0] fstat;                   // 0x004 - RO
    reg [31:0] fdebug;                  // 0x008 - WC
    reg [31:0] flevel;                  // 0x00C - RO
    reg [31:0] irq;                     // 0x030 - WC
    reg [31:0] input_sync_bypass;       // 0x038 - RW
    reg [31:0] dbg_padout;              // 0x03C - RO
    reg [31:0] dbg_padoe;               // 0x040 - RO
    reg [31:0] dbg_cfginfo;             // 0x044 - RO
    reg [31:0] sm_clkdiv [0:3];         // 0x0C8, Ox0E0, Ox0F8, 0x110 - RW
    reg [31:0] sm_execctrl [0:3];       // 0x0CC, 0x0E4, 0x0FC, 0x114 - RO/RW
    reg [31:0] sm_shiftctrl [0:3];      // 0x0D0, 0x0E8, 0x100, 0x118 - RW
    reg [31:0] sm_addr [0:3];           // 0x0D4, 0x0EC, 0x104, 0x11C - R0
    reg [31:0] sm_instr [0:3];          // 0x0D8, 0x0F0, 0x108, 0x120 - RW
    reg [31:0] sm_pinctrl [0:3];        // 0x0DC, 0x0F4, 0x10C, 0x124 - RW
    reg [31:0] intr;                    // 0x128 - RO
    reg [31:0] irq0_inte, irq1_inte;    // 0x12C, 0x138 - RW
    reg [31:0] irq0_intf, irq1_intf;    // 0x130, 0x13C - RW
    reg [31:0] irq0_ints, irq1_ints;    // 0x134, 0x140 - RO

    // HW input and output wire assignments
    assign clkdiv_restart = ctrl[11:8];
    assign sm_restart = ctrl[7:4];
    assign sm_en = ctrl[3:0];
    assign tx_empty = fstat[27:24];
    assign tx_full = fstat[19:16];
    assign rx_empty = fstat[11:8];
    assign rx_full = fstat[3:0];
    assign rx[3] = flevel[31:28];
    assign tx[3] = flevel[27:24];
    assign rx[2] = flevel[23:20];
    assign tx[2] = flevel[19:16];
    assign rx[1] = flevel[15:12];
    assign tx[1] = flevel[11:8];
    assign rx[0] = flevel[7:4];
    assign tx[0] = flevel[3:0];
    assign gpio_sync_bypass = input_sync_bypass[31:0];

    
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
            9'h044: data_out = dbg_cfginfo;

            // SM0
            9'h0C8: data_out = sm_clkdiv[0];
            9'h0CC: data_out = sm_execctrl[0];
            9'h0D0: data_out = sm_shiftctrl[0];
            9'h0D4: data_out = sm_addr[0];
            9'h0D8: data_out = sm_instr[0];
            9'h0DC: data_out = sm_pinctrl[0];

            // SM1
            9'h0E0: data_out = sm_clkdiv[1];
            9'h0E4: data_out = sm_execctrl[1];
            9'h0E8: data_out = sm_shiftctrl[1];
            9'h0EC: data_out = sm_addr[1];
            9'h0F0: data_out = sm_instr[1];
            9'h0F4: data_out = sm_pinctrl[1];

            // SM2
            9'h0F8: data_out = sm_clkdiv[2];
            9'h0FC: data_out = sm_execctrl[2];
            9'h100: data_out = sm_shiftctrl[2];
            9'h104: data_out = sm_addr[2];
            9'h108: data_out = sm_instr[2];
            9'h10C: data_out = sm_pinctrl[2];

            // SM3
            9'h110: data_out = sm_clkdiv[3];
            9'h114: data_out = sm_execctrl[3];
            9'h118: data_out = sm_shiftctrl[3];
            9'h11C: data_out = sm_addr[3];
            9'h120: data_out = sm_instr[3];
            9'h124: data_out = sm_pinctrl[3];

            9'h128: data_out = intr;

            // IRQ0
            9'h12C: data_out = irq0_inte;
            9'h130: data_out = irq0_intf;
            9'h134: data_out = irq0_ints;

            // IRQ1
            9'h138: data_out = irq1_inte;
            9'h13C: data_out = irq1_intf;
            9'h140: data_out = irq1_ints;
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

                // SM0
                9'h0C8: sm_clkdiv[0][31:8] <= data_in[31:8];
                9'h0CC: begin
                    sm_execctrl[0][30:7] <= data_in[30:7];
                    sm_execctrl[0][4:0] <= data_in[4:0];
                end
                9'h0D0: sm_shiftctrl[0][31:16] <= data_in[31:16];
                9'h0D8: sm_instr[0][15:0] <= data_in[15:0];
                9'h0DC: sm_pinctrl[0] <= data_in;

                // SM1
                9'h0E0: sm_clkdiv[1][31:8] <= data_in[31:8];
                9'h0E4: begin
                    sm_execctrl[1][30:7] <= data_in[30:7];
                    sm_execctrl[1][4:0] <= data_in[4:0];
                end
                9'h0E8: sm_shiftctrl[1][31:16] <= data_in[31:16];
                9'h0F0: sm_instr[1][15:0] <= data_in[15:0];
                9'h0F4: sm_pinctrl[1] <= data_in;

                // SM2
                9'h0F8: sm_clkdiv[2][31:8] <= data_in[31:8];
                9'h0FC: begin
                    sm_execctrl[2][30:7] <= data_in[30:7];
                    sm_execctrl[2][4:0] <= data_in[4:0];
                end
                9'h100: sm_shiftctrl[2][31:16] <= data_in[31:16];
                9'h108: sm_instr[2][15:0] <= data_in[15:0];
                9'h10C: sm_pinctrl[2] <= data_in;

                // SM3
                9'h110: sm_clkdiv[3][31:8] <= data_in[31:8];
                9'h114: begin
                    sm_execctrl[3][30:7] <= data_in[30:7];
                    sm_execctrl[3][4:0] <= data_in[4:0];
                end
                9'h118: sm_shiftctrl[3][31:16] <= data_in[31:16];
                9'h120: sm_instr[3][15:0] <= data_in[15:0];
                9'h124: sm_pinctrl[3] <= data_in;

                // IRQ0
                9'h12C: irq0_inte[11:0] <= data_in[11:0];
                9'h130: irq0_intf[11:0] <= data_in[11:0];

                // IRQ1
                9'h138: irq1_inte[11:0] <= data_in[11:0];
                9'h13C: irq1_intf[11:0] <= data_in[11:0];
                default: ;
            endcase
        end
    end
endmodule