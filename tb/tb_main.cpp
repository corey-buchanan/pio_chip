#include "Vpio_chip.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vpio_chip* pio_chip = new Vpio_chip;

    // Initialize trace dump
    VerilatedVcdC* tfp = new VerilatedVcdC();
    pio_chip->trace(tfp, 99); // Trace depth
    tfp->open("wave.vcd");

    // Clock generation
    vluint64_t time = 0;
    pio_chip->clk = false;

    while (time < 100) {                 // Simulate 100 cycles
        pio_chip->clk = !pio_chip->clk;       // Toggle clock signal
        pio_chip->eval();                     // Evaluate the design
        tfp->dump(time);                 // Dump signal states
        time += 5;                       // Increment simulation time
    }

    tfp->close();
    delete pio_chip;
    delete tfp;

    return 0;
}
