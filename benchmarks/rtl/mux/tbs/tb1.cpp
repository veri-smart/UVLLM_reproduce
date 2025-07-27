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
const char *fname = "tb1.vcd";

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

    top->sel = 0;
    top->a = 1;
    top->b = 2;
    top->c = 4;
    top->d = 8;
    tick(top, m_trace);
    top->sel = 1;
    tick(top, m_trace);
    top->sel = 2;
    tick(top, m_trace);
    top->sel = 3;
    tick(top, m_trace);
    top->sel = 0;
    top->a = 8;
    top->b = 4;
    top->c = 2;
    top->d = 1;
    tick(top, m_trace);
    top->sel = 1;
    tick(top, m_trace);
    top->sel = 2;
    tick(top, m_trace);
    top->sel = 3;

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}