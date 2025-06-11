# Project Description

I'm reverse engineering the Programmable I/O module in the RP2040 from its specification to see if I can implement its functionality as a standalone chip. The PIO is a remarkable work of engineering that makes the RP2040 a very powerful microcontroller, and building a separate PIO chip would allow one to extend the functionality of other existing microcontrollers. Currently, I am working on the RTL implementation, but if this goes well, I will take this design to silicon via one of OpenMPW shuttle programs (provided they continue to exist).

I am implementing compatible instructions such that programs can be easily be ported over. Given the flexibility of writing my own implementation, I may change or add to some of the functionality.

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

# Notes, things that might be different than RP2040 implementation etc.

Register(s) need to be added to control GPIO directions, pullup/pulldown, and select which cores the pins are driven by. On the RP2040, the GPIO registers control these rather than the PIO registers, but we aren't going to import all of the GPIO functionality.

Currently output arbitration is done at the chip level. It might be reasonable to break it up between the chip (muxing) and core (resolving FSM driver). But it's already written and tested among other things to get done, so I don't plan on changing it right now.

Interrupts may have to work slightly differently with a standalone chip. The tentative idea is to implement an interrupt pin that can be raised by the IRQ, and then the processor can inquire (via SPI) the source of the interrupt and clear it.

From the PIO spec: "Note that a 'MOV' from the OSR is undefined whilst autopull is enabled; you will read either any residual data that has not been shifted out, or a fresh word from the FIFO, depending on a race against system DMA. Likewise, a 'MOV' to the OSR may overwrite data which has just been autopulled. However, data which you 'MOV' into the OSR will never be overwritten, since 'MOV' updates the shift counter." I implemented autopull to occur only on non-MOV cycles, so this non-determinism should not occur. Whether this was a good design choice or not is yet to be determined.