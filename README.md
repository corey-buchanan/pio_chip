# Project Description

I'm trying to create something similar to the RPI Programmable I/O, but as a standalone chip. I plan to implement compatible instructions such that programs can be easily be ported over.

# TODOs

- Decide on number of cores and FSMs/core (likely 4 and 4)
- Add control registers
- Add FIFO buffers
- Add GPIO
- Add scratch registers
- Add SPI controller
- Create instructions for programming the instruction memory and control registers
- Implement instructions in the FSM
- Implement delay cycles
- Create integration tests
- Unit test everything
- Separate 2 resets, global reset and soft reset (see note on fsm.v)
- Build an assembler, or import it to make testing easier
- Implement clock divider

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
- [ ] 001 | !X | Scratch X zero
- [ ] 010 | X-- | Scratch X nonzero before decrement
- [ ] 011 | !Y | Scratch Y zero
- [ ] 100 | Y-- | Scratch Y nonzero before decrement
- [ ] 101 | X!=Y | Scratch X not equal to scratch Y
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