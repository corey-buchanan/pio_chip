`ifndef TYPES_SVH_
`define TYPES_SVH_

typedef struct packed {
    logic [3:0] clkdiv_restart, sm_restart, sm_en;
} ctrl_reg_out_t;

typedef struct packed {
    logic [3:0] tx_empty, tx_full, rx_empty, rx_full;
} fstat_reg_in_t;

typedef struct packed {
    logic [3:0] tx_stall, tx_over, rx_under, rx_stall;
} fdebug_reg_in_t;

typedef struct packed {
    logic [3:0][3:0] rx;
    logic [3:0][3:0] tx;
} flevel_reg_in_t;

typedef struct packed {
    logic [7:0] irq_set, irq_clr;
} irq_reg_in_t;

typedef struct packed {
    logic [3:0] intr_sm, intr_sm_txnfull, intr_sm_rxnfull;
} intr_reg_in_t;

typedef struct packed {
    logic empty, full;
} fifo_status;

typedef struct packed {
    logic [31:0] data_in; // Set on MOV, PULL, or autopull
    logic [31:0] shift_out; // Set on OUT
    logic [31:0] osr; // Allows FSM to read OSR for MOV instructions
} osr_data_t;

typedef struct packed {
    logic osr_load; // Set on MOV, PULL, or autopull
    logic shift_en; // Set on OUT
    logic shiftdir; // Set by control register 0 = left, 1 = right
    logic [5:0] shift_count; // Set on OUT
} osr_control_t;

typedef enum logic [2:0] {
    JMP = 3'b000,
    WAIT = 3'b001,
    IN = 3'b010,
    OUT = 3'b011,
    PUSH_PULL = 3'b100,
    MOV = 3'b101,
    IRQ = 3'b110,
    SET = 3'b111
} pio_instr_t;

typedef enum logic [2:0] {
    UNCOND = 3'b000,
    X_ZERO = 3'b001,
    X_NZ_DEC = 3'b010,
    Y_ZERO = 3'b011,
    Y_NZ_DEC = 3'b100,
    X_NE_Y = 3'b101,
    PIN = 3'b110,
    OSR_NOT_EMPTY = 3'b111
} jump_cond_t;

typedef enum logic [2:0] {
    PINS = 3'b000,
    X = 3'b001,
    Y = 3'b010,
    NULL = 3'b100,
    PC = 3'b101,
    ISR = 3'b110,
    OSR = 3'b111
} mov_src_dest_t;

typedef enum logic [2:0] {
    PINS = 3'b000,
    X = 3'b001,
    Y = 3'b010,
    PINDIRS = 3'b100
} set_dest_t;

`endif
