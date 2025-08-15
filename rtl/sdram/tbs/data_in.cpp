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
const char *fname = "data_in.vcd";

#define MAX_SIM_TIME 10000000

vluint64_t sim_time = 0;
void tick(Vmodule *top, VerilatedVcdC *m_trace)
{
    // printf("Clock: %lu\n", sim_time);
    if (sim_time >= MAX_SIM_TIME)
        exit(1);
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
    top->wr_addr = 0;
    top->wr_data = 0;
    top->rd_enable = 0;
    top->wr_enable = 0;
    top->data_in = gen() & 65535;
    top->rd_addr = 0;
    top->rst_n = 1;
    tick(top, m_trace);
    tick(top, m_trace);
    top->rst_n = 0;
    tick(top, m_trace);
    tick(top, m_trace);
    top->rst_n = 0;

    for (int i = 0; i != 60; ++i)
        tick(top, m_trace);
    top->wr_addr = 0xbedfed;
    tick(top, m_trace);
    tick(top, m_trace);
    top->rd_enable = 1;
    tick(top, m_trace);
    tick(top, m_trace);
    tick(top, m_trace);
    top->rd_enable = 0;
    top->wr_addr = 0;

    tick(top, m_trace);
    tick(top, m_trace);
    tick(top, m_trace);
    tick(top, m_trace);
    top->data_in = 0xbbbb;
    tick(top, m_trace);
    top->data_in = gen() & 65535;

    for (int i = 0; i != 500; ++i)
        tick(top, m_trace);

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}