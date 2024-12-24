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

<ul>
  <li><input type="checkbox" checked>000 | Always/unconditional</li>
  <li><input type="checkbox">001 | !X | Scratch X zero</li>
  <li><input type="checkbox">010 | X-- | Scratch X nonzero before decrement</li>
  <li><input type="checkbox">011 | !Y | Scratch Y zero</li>
  <li><input type="checkbox">100 | Y-- | Scratch Y nonzero before decrement</li>
  <li><input type="checkbox">101 | X!=Y | Scratch X not equal to scratch Y</li>
  <li><input type="checkbox">110 | PIN | Branch on input pin</li>
  <li><input type="checkbox">111 | !OSRE | Output shift register not empty</li>
</ul>

## WAIT

<ul>
  <li><input type="checkbox">Polarity</li>
  <li><input type="checkbox">00 | GPIO source (no mapping applied)</li>
  <li><input type="checkbox">01 | PIN source (mapping applied)</li>
  <li><input type="checkbox">10 | IRQ flag</li>
</ul>

## IN

Remember bitcount is encoded as 1-32, with 32 being encoded as 00000.

<ul>
  <li><input type="checkbox">000 | PINS source</li>
  <li><input type="checkbox">001 | X source</li>
  <li><input type="checkbox">010 | Y source</li>
  <li><input type="checkbox">011 | NULL source (zeroes)</li>
  <li><input type="checkbox">110 | ISR source</li>
  <li><input type="checkbox">111 | OSR source</li>
</ul>

## OUT

Remember bitcount is encoded as 1-32, with 32 being encoded as 00000.

<ul>
  <li><input type="checkbox">000 | PINS source</li>
  <li><input type="checkbox">001 | X source</li>
  <li><input type="checkbox">010 | Y source</li>
  <li><input type="checkbox">011 | NULL source (zeroes)</li>
  <li><input type="checkbox">110 | ISR source</li>
  <li><input type="checkbox">111 | EXEC source</li>
</ul>

## PUSH

<ul>
  <li><input type="checkbox">Normal</li>
  <li><input type="checkbox">IfFull</li>
  <li><input type="checkbox">Block</li>
</ul>

## PULL

<ul>
  <li><input type="checkbox">Normal</li>
  <li><input type="checkbox">IfEmpty</li>
  <li><input type="checkbox">Block</li>
</ul>

## MOV

<ul>
  <li><input type="checkbox">Normal</li>
  <li><input type="checkbox">IfEmpty</li>
  <li><input type="checkbox">Block</li>
</ul>

### Destinations

<ul>
  <li><input type="checkbox">000 | PINS (same mapping as OUT)</li>
  <li><input type="checkbox">001 | X</li>
  <li><input type="checkbox">010 | Y</li>
  <li><input type="checkbox">100 | EXEC</li>
  <li><input type="checkbox">101 | PC</li>
  <li><input type="checkbox">110 | ISR</li>
  <li><input type="checkbox">111 | OSR</li>
</ul>

### Operations

<ul>
  <li><input type="checkbox">00 | None</li>
  <li><input type="checkbox">01 | Invert (bit-wise complement)</li>
  <li><input type="checkbox">10 | Bit-reverse</li>
</ul>

## IRQ

<ul>
  <li><input type="checkbox">Normal</li>
  <li><input type="checkbox">Clr</li>
  <li><input type="checkbox">Wait</li>
  <li><input type="checkbox">Index MSB</li>
</ul>

## SET

<ul>
  <li><input type="checkbox">000 | PINS</li>
  <li><input type="checkbox" checked>001 | X - 5 lsbs to data, others cleared to zero</li>
  <li><input type="checkbox" checked>010 | Y - 5 lsbs to data, others cleared to zero</li>
  <li><input type="checkbox">100 | PINDIRS</li>
</ul>

## Misc

<ul>
  <li><input type="checkbox">Delay cycles</li>
  <li><input type="checkbox">Sideset</li>
  <li><input type="checkbox">Shift directions</li>
  <li><input type="checkbox">Autopush</li>
</ul>