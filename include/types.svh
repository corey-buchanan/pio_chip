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

`endif
