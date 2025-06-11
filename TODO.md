# TODOs

- [-] Implement instructions in the FSM
- [-] Unit test everything
- [-] Document anything that is different than the PIO
- [ ] Build an assembler, or import it to make testing easier
  - The FSM tests are tricky to read and write. Being able to call a function to assemble the instructions would make things much simpler
- [ ] Add UVM testbenches - may not be necessary right now, but I want to study and understand UVM
- [ ] Add SPI controller
- [ ] Create instructions for programming the instruction memory and control registers
- [ ] Create integration tests
- [ ] Separate 2 resets, global reset and soft reset (see note on fsm.v)
- [ ] Implement clock divider
- [ ] Add ISR
- [ ] Create interrupt controller
- [x] Convert to System Verilog, using its useful extensions - we can try to bundle and better name the myriad of wires
- [x] Decide on number of cores and FSMs/core - 4 cores, 4 FSMs/core
  - 2x the # of cores of the RPI PIO, but same #FSMs per core. Will require adjusting some of the memory mapped registers.
- [x] Add control registers
- [x] Add FIFO buffers
- [x] Add GPIO
- [x] Add scratch registers
- [x] Add OSR

# Instruction Implementation Tracking

## JMP

- [x] 000 | Always/unconditional
- [x] 001 | !X | Scratch X zero
- [x] 010 | X-- | Scratch X nonzero before decrement
- [x] 011 | !Y | Scratch Y zero
- [x] 100 | Y-- | Scratch Y nonzero before decrement
- [x] 101 | X!=Y | Scratch X not equal to scratch Y
- [ ] 110 | PIN | Branch on input pin
- [ ] 111 | !OSRE | Output shift register not empty

## WAIT

- [ ] Polarity
- [ ] 00 | GPIO source (no mapping applied)
- [ ] 01 | PIN source (mapping applied)
- [ ] 10 | IRQ flag

## IN

Remember bitcount is encoded as 1-32, with 32 being encoded as 00000.

- [ ] 000 | PINS source
- [ ] 001 | X source
- [ ] 010 | Y source
- [ ] 011 | NULL source (zeroes)
- [ ] 110 | ISR source
- [ ] 111 | OSR source

## OUT

Remember bitcount is encoded as 1-32, with 32 being encoded as 00000.

- [ ] 000 | PINS dest
- [-] 001 | X dest
- [-] 010 | Y dest
- [x] 011 | NULL dest (discard) - we get this functionality for free
- [ ] 110 | ISR dest
- [ ] 111 | EXEC dest

## PUSH

- [ ] Normal
- [ ] IfFull
- [ ] Block

## PULL

- [-] Normal
- [-] IfEmpty
- [-] Block

## MOV

### Sources

- [ ] 000 | PINS (same mapping as OUT)
- [-] 001 | X
- [-] 010 | Y
- [-] 011 | NULL
- [ ] 101 | STATUS
- [ ] 110 | ISR
- [-] 111 | OSR

### Destinations

- [ ] 000 | PINS (same mapping as OUT)
- [-] 001 | X
- [-] 010 | Y
- [ ] 100 | EXEC
- [ ] 101 | PC
- [ ] 110 | ISR
- [-] 111 | OSR

### Operations

- [-] 00 | None
- [ ] 01 | Invert (bit-wise complement)
- [ ] 10 | Bit-reverse

## IRQ

- [ ] Normal
- [ ] Clr
- [ ] Wait
- [ ] Index MSB

## SET

- [ ] 000 | PINS
- [x] 001 | X - 5 lsbs to data, others cleared to zero
- [x] 010 | Y - 5 lsbs to data, others cleared to zero
- [ ] 100 | PINDIRS

## Misc

- [ ] Delay cycles
- [ ] Sideset
- [-] Shift directions
- [-] Autopull
- [ ] Autopush
- [ ] FIFO-Joining

# Register Locations
Done means not only added to register file, but associated functionality implemented.

| Addr  | Register           | Regfile     | Done |
|-------|--------------------|-------------|------|
| 0x000 | CTRL               | Control     |      |
| 0x004 | FSTAT              | Control     |      |
| 0x008 | FDEBUG             | Control     |      |
| 0x00C | FLEVEL             | Control     |      |
| 0x010 | TXF0               | FIFO        |      |
| 0x014 | TXF1               | FIFO        |      |
| 0x018 | TXF2               | FIFO        |      |
| 0x01C | TXF3               | FIFO        |      |
| 0x020 | RXF0               | FIFO        |      |
| 0x024 | RXF1               | FIFO        |      |
| 0x028 | RXF2               | FIFO        |      |
| 0x02C | RXF3               | FIFO        |      |
| 0x030 | IRQ                | Control     |      |
| 0x034 | IRQ_FORCE          | Interrupt   |      |
| 0x038 | INPUT_SYNC_BYPASS  | Control     |      |
| 0x03C | DBG_PADOUT         | Control     |      |
| 0x040 | DBG_PADOE          | Control     |      |
| 0x044 | DBG_CFGINFO        | Control     |      |
| 0x048 | INSTR_MEM0...31    | Instruction | X    |
| 0x0C8 | SM0_CLKDIV         | Control     |      |
| 0x0CC | SM0_EXECCTRL       | Control     |      |
| 0x0D0 | SM0_SHIFTCTRL      | Control     |      |
| 0x0D4 | SM0_ADDR           | Control     |      |
| 0x0D8 | SM0_INSTR          | Control     |      |
| 0x0DC | SM0_PINCTRL        | Control     |      |
| 0x0E0 | SM1_CLKDIV         | Control     |      |
| 0x0E4 | SM1_EXECCTRL       | Control     |      |
| 0x0E8 | SM1_SHIFTCTRL      | Control     |      |
| 0x0EC | SM1_ADDR           | Control     |      |
| 0x0F0 | SM1_INSTR          | Control     |      |
| 0x0F4 | SM1_PINCTRL        | Control     |      |
| 0x0F8 | SM2_CLKDIV         | Control     |      |
| 0x0FC | SM2_EXECCTRL       | Control     |      |
| 0x0E0 | SM2_SHIFTCTRL      | Control     |      |
| 0x0E4 | SM2_ADDR           | Control     |      |
| 0x0E8 | SM2_INSTR          | Control     |      |
| 0x0EC | SM2_PINCTRL        | Control     |      |
| 0x110 | SM3_CLKDIV         | Control     |      |
| 0x114 | SM3_EXECCTRL       | Control     |      |
| 0x118 | SM3_SHIFTCTRL      | Control     |      |
| 0x11C | SM3_ADDR           | Control     |      |
| 0x120 | SM3_INSTR          | Control     |      |
| 0x124 | SM3_PINCTRL        | Control     |      |
| 0x128 | INTR               | Control     |      |
| 0x12C | IRQ0_INTE          | Control     |      |
| 0x130 | IRQ0_INTF          | Control     |      |
| 0x134 | IRQ0_INTS          | Control     |      |
| 0x138 | IRQ1_INTE          | Control     |      |
| 0x13C | IRQ1_INTF          | Control     |      |
| 0x140 | IRQ1_INTS          | Control     |      |
| TBD   | GPIO_CTRL          | TBD         |      |
