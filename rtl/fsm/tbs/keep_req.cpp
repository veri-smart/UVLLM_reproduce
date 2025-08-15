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
const char *fname = "keep_req.vcd";

#define MAX_SIM_TIME 10000000

vluint64_t sim_time = 0;
void tick(Vmodule *top, VerilatedVcdC *m_trace)
{
    if (sim_time >= MAX_SIM_TIME)
        exit(1);
    // printf("Clock: %lu\n", sim_time);
    top->clock = 0;
    top->eval();
    m_trace->dump(sim_time++);
    top->clock = 1;
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
    top->req_0 = 0;
    top->req_1 = 0;
    top->req_2 = 0;
    top->req_3 = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->reset = 1;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->reset = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->req_0 = 1;
    for (int i = 0; i != 10; ++i)
        tick(top, m_trace);
    top->req_0 = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->req_0 = 1;
    for (int i = 0; i != 10; ++i)
        tick(top, m_trace);
    top->req_0 = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->req_0 = 1;
    for (int i = 0; i != 10; ++i)
        tick(top, m_trace);
    top->req_0 = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);
    top->req_0 = 1;
    for (int i = 0; i != 10; ++i)
        tick(top, m_trace);
    top->req_0 = 0;
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}