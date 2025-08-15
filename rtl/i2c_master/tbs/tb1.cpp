#include "verilated.h"
#include "Vmodule.h"
#include "verilated_vcd_c.h"

#include <cstdio>
#include <cstdlib>
#include <random>
#include <cstdint>
#include <fstream>

using namespace std;

const char *fname = "tb1.vcd";

int main(int argc, char **argv, char **)
{
    auto *contextp = new VerilatedContext();
    contextp->traceEverOn(true);
    // contextp->commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating
    auto *top = new Vmodule{contextp};
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    top->trace(m_trace, 2);
    m_trace->open(fname);
    uint64_t t = 0;

    // Simulate until $finish
    while (!contextp->gotFinish())
    {
        // Evaluate model
        top->eval();
        m_trace->dump(t);
        // Advance time
        if (!top->eventsPending())
            break;
        t = top->nextTimeSlot();
        if (t >= 100000000)
            break;
        contextp->time(t);
    }

    if (!contextp->gotFinish())
    {
        VL_DEBUG_IF(VL_PRINTF("+ Exiting without $finish; no events left\n"););
    }

    // Execute 'final' processes
    top->final();

    m_trace->close();
    delete m_trace;
    delete top;
    delete contextp;
    // Print statistical summary report
    // contextp->statsPrintSummary();

    return 0;
}
