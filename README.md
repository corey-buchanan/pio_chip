# Project Description

I'm trying to create something similar to the RPI Programmable I/O, but as a standalone chip. I plan to implement compatible instructions such that programs can be easily be ported over.

# Running the project

Build:

```
cmake -B build
cmake --build build
```

Test:
```
./build/bin/unit_tests
```

or

```
cd build
ctest
```

# TODOs

- [x] Decide on number of cores and FSMs/core - 4 cores, 4 FSMs/core
  - 2x the # of cores of the RPI PIO, but same #FSMs per core. Will require adjusting some of the memory mapped registers.
- [x] Add control registers
- [ ] Add FIFO buffers
- [x] Add GPIO
- [x] Add scratch registers
- [ ] Add SPI controller
- [ ] Create instructions for programming the instruction memory and control registers
- [-] Implement instructions in the FSM
- [ ] Implement delay cycles
- [ ] Create integration tests
- [-] Unit test everything
- [ ] Separate 2 resets, global reset and soft reset (see note on fsm.v)
- [ ] Build an assembler, or import it to make testing easier
- [ ] Implement clock divider
- [ ] Document anything that is different than the PIO
- [x] Add OSR
- [ ] Add ISR
- [ ] Create interrupt controller

# Instruction Encoding Reference

<table border="1">
  <tr>
    <th>Bit</th>
    <th>15</th>
    <th>14</th>
    <th>13</th>
    <th>12</th>
    <th>11</th>
    <th>10</th>
    <th>9</th>
    <th>8</th>
    <th>7</th>
    <th>6</th>
    <th>5</th>
    <th>4</th>
    <th>3</th>
    <th>2</th>
    <th>1</th>
    <th>0</th>
  </tr>
  <tr>
    <td>JMP</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
    <td colspan="5">Delay/Side-set</td>
    <td colspan="3">Condition</td>
    <td colspan="5">Address</td>
  </tr>
  <tr>
    <td>WAIT</td>
    <td>0</td>
    <td>0</td>
    <td>1</td>
    <td colspan="5">Delay/Side-set</td>
    <td>Pol</td>
    <td colspan="2">Source</td>
    <td colspan="5">Address</td>
  </tr>
  <tr>
    <td>IN</td>
    <td>0</td>
    <td>1</td>
    <td>0</td>
    <td colspan="5">Delay/Side-set</td>
    <td colspan="3">Source</td>
    <td colspan="5">Bit count</td>
  </tr>
  <tr>
    <td>OUT</td>
    <td>0</td>
    <td>1</td>
    <td>1</td>
    <td colspan="5">Delay/Side-set</td>
    <td colspan="3">Source</td>
    <td colspan="5">Bit count</td>
  </tr>
  <tr>
    <td>PUSH</td>
    <td>1</td>
    <td>0</td>
    <td>0</td>
    <td colspan="5">Delay/Side-set</td>
    <td>0</td>
    <td>IfF</td>
    <td>Blk</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
  </tr>
  <tr>
    <td>PULL</td>
    <td>1</td>
    <td>0</td>
    <td>0</td>
    <td colspan="5">Delay/Side-set</td>
    <td>1</td>
    <td>IfE</td>
    <td>Blk</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
    <td>0</td>
  </tr>
  <tr>
    <td>MOV</td>
    <td>1</td>
    <td>0</td>
    <td>1</td>
    <td colspan="5">Delay/Side-set</td>
    <td colspan="3">Destination</td>
    <td colspan="2">Op</td>
    <td colspan="3">Source</td>
  </tr>
  <tr>
    <td>IRQ</td>
    <td>1</td>
    <td>1</td>
    <td>0</td>
    <td colspan="5">Delay/Side-set</td>
    <td>0</td>
    <td>Clr</td>
    <td>Wait</td>
    <td colspan="5">Index</td>
  </tr>
  <tr>
    <td>SET</td>
    <td>1</td>
    <td>1</td>
    <td>1</td>
    <td colspan="5">Delay/Side-set</td>
    <td colspan="3">Destination</td>
    <td colspan="5">Data</td>
  </tr>
</table>

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

- [ ] 000 | PINS source
- [ ] 001 | X source
- [ ] 010 | Y source
- [ ] 011 | NULL source (zeroes)
- [ ] 110 | ISR source
- [ ] 111 | EXEC source

## PUSH

- [ ] Normal
- [ ] IfFull
- [ ] Block

## PULL

- [ ] Normal
- [ ] IfEmpty
- [ ] Block

## MOV

- [ ] Normal
- [ ] IfEmpty
- [ ] Block

### Destinations

- [ ] 000 | PINS (same mapping as OUT)
- [ ] 001 | X
- [ ] 010 | Y
- [ ] 100 | EXEC
- [ ] 101 | PC
- [ ] 110 | ISR
- [ ] 111 | OSR

### Operations

- [ ] 00 | None
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
- [ ] Shift directions
- [ ] Autopush

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

# Notes, things that might be different than RP2040 implementation etc.

Register(s) need to be added to control GPIO directions, pullup/pulldown, and select which cores the pins are driven by. On the RP2040, the GPIO registers control these rather than the PIO registers, but we aren't going to import all of the GPIO functionality.

Currently output arbitration is done at the chip level. It might be reasonable to break it up between the chip (muxing) and core (resolving FSM driver). But it's already written and tested among other things to get done, so I don't plan on changing it right now.

Interrupts may have to work slightly differently with a standalone chip. The tentative idea is to implement an interrupt pin that can be raised by the IRQ, and then the processor can inquire (via SPI) the source of the interrupt and clear it.