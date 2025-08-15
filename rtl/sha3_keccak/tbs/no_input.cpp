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
const char *fname = "no_input.vcd";

#define MAX_SIM_TIME 10000

vluint64_t sim_time = 0;
void tick(Vmodule *top, VerilatedVcdC *m_trace)
{
    if (sim_time >= MAX_SIM_TIME)
        exit(1);
    // printf("Clock: %lu\n", sim_time);
    top->clk = 0;
    top->eval();
    m_trace->dump(sim_time++);
    top->clk = 1;
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

    tick(top, m_trace);
    top->reset = 0;
    top->in = 0;
    top->in_ready = 0;
    top->is_last = 0;
    top->byte_num = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    top->in_ready = 1;
    top->is_last = 0;

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    for (int i = 0; i != 7; ++i)
        tick(top, m_trace);
    top->in = 0x12345678;
    top->in_ready = 1;
    top->is_last = 1;
    top->byte_num = 0;
    tick(top, m_trace);
    top->in = 0xddddd;
    top->in_ready = 1;
    top->is_last = 1;
    tick(top, m_trace);
    top->in_ready = 0;
    top->is_last = 0;
    while (!top->out_ready)
        tick(top, m_trace);
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}