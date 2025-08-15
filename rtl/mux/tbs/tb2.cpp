#include "Vmodule.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <cstdio>
#include <cstdlib>
#include <random>
#include <cstdint>
#include <fstream>

using namespace std;

// using Vmodule = VMODULE;
const char *fname = "tb2.vcd";

#define MAX_SIM_TIME 10000000

vluint64_t sim_time = 0;
void tick(Vmodule *top, VerilatedVcdC *m_trace)
{
    // printf("Clock: %lu\n", sim_time);
    // top->clk = 0;
    // top->eval();
    // m_trace->dump(sim_time++);
    // top->clk = 1;
    if (sim_time >= MAX_SIM_TIME)
        exit(1);
    top->eval();
    m_trace->dump(sim_time++);
}

int main(int argc, char **argv)
{
    auto *contextp = new VerilatedContext();
    // contextp->commandArgs(argc, argv);
    auto *top = new Vmodule{contextp};
    Verilated::traceEverOn(true);
    VerilatedVcdC *m_trace = new VerilatedVcdC;
    top->trace(m_trace, 1);
    m_trace->open(fname);
    mt19937_64 gen;

    for (int i = 0; i != 100; ++i)
    {
        top->sel = gen() & 3;
        top->a = gen() & 15;
        top->b = gen() & 15;
        top->c = gen() & 15;
        top->d = gen() & 15;
        tick(top, m_trace);
    }

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}