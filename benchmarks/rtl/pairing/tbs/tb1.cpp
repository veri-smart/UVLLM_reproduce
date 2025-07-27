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

#define MAX_SIM_TIME 150000

vluint64_t sim_time = 0;
void tick(Vmodule *top, VerilatedVcdC *m_trace)
{
    // printf("Clock: %lu\n", sim_time);
    // if (sim_time >= MAX_SIM_TIME)
    //     exit(1);
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
    for (int i = 0; i <= 6; ++i)
    {
        top->xp[i] = 0;
        top->yp[i] = 0;
        top->xr[i] = 0;
        top->yr[i] = 0;
    }
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);

    top->xp[6] = 0x0u;
    top->xp[5] = 0xaa5a8129u;
    top->xp[4] = 0xa02a0544u;
    top->xp[3] = 0xa4409a50u;
    top->xp[2] = 0x00454589u;
    top->xp[1] = 0x01280969u;
    top->xp[0] = 0x815aa820u;

    top->yp[6] = 0x1u;
    top->yp[5] = 0x414a205au;
    top->yp[4] = 0x21a44289u;
    top->yp[3] = 0x68985650u;
    top->yp[2] = 0x89546440u;
    top->yp[1] = 0x22492584u;
    top->yp[0] = 0x28049204u;

    top->xr[6] = 0x0u;
    top->xr[5] = 0x61401149u;
    top->xr[4] = 0x95225066u;
    top->xr[3] = 0x68a01a20u;
    top->xr[2] = 0x98881246u;
    top->xr[1] = 0x8a5aa864u;
    top->xr[0] = 0x1aa24595u;

    top->yr[6] = 0x0u;
    top->yr[5] = 0xaa011455u;
    top->yr[4] = 0x90659058u;
    top->yr[3] = 0x124a0261u;
    top->yr[2] = 0x41068286u;
    top->yr[1] = 0x02259091u;
    top->yr[0] = 0x82a92189u;
    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    while (!top->done && sim_time <= MAX_SIM_TIME)
        tick(top, m_trace);
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}