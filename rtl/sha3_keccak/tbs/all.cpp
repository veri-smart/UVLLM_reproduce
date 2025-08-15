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
const char *fname = "all.vcd";

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

    const char words[11][4] = {
        {'T', 'h', 'e', ' '},
        {'q', 'u', 'i', 'c'},
        {'k', ' ', 'b', 'r'},
        {'o', 'w', 'n', ' '},
        {'f', 'o', 'x', ' '},
        {'j', 'u', 'm', 'p'},
        {'s', ' ', 'o', 'v'},
        {'e', 'r', ' ', 't'},
        {'h', 'e', ' ', 'l'},
        {'a', 'z', 'y', ' '},
        {'d', 'o', 'g', ' '}};

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

    for (int i = 0; i != 11; ++i)
    {
        top->in = *reinterpret_cast<const int *>(words[i]);
        if (i == 10)
        {
            top->byte_num = 3;
            top->is_last = 1;
        }
        tick(top, m_trace);
    }
    top->in_ready = 0;
    top->is_last = 0;
    while (!top->out_ready)
        tick(top, m_trace);

    const char words2[11][4] = {
        {'T', 'h', 'e', ' '},
        {'q', 'u', 'i', 'c'},
        {'k', ' ', 'b', 'r'},
        {'o', 'w', 'n', ' '},
        {'f', 'o', 'x', ' '},
        {'j', 'u', 'm', 'p'},
        {'s', ' ', 'o', 'v'},
        {'e', 'r', ' ', 't'},
        {'h', 'e', ' ', 'l'},
        {'a', 'z', 'y', ' '},
        {'d', 'o', 'g', '.'}};

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    top->in_ready = 1;
    top->is_last = 0;

    for (int i = 0; i != 11; ++i)
    {
        top->in = *reinterpret_cast<const int *>(words2[i]);
        if (i == 10)
        {
            top->byte_num = 0;
            top->is_last = 1;
        }
        tick(top, m_trace);
    }
    top->in_ready = 0;
    top->is_last = 0;
    while (!top->out_ready)
        tick(top, m_trace);

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    for (int i = 0; i != 7; ++i)
        tick(top, m_trace);
    top->in_ready = 1;
    top->is_last = 0;
    top->byte_num = 1;
    top->in = 0xA1A2A3A4;
    tick(top, m_trace);
    top->is_last = 1;
    top->byte_num = 1;
    top->in = 0xA5000000;
    tick(top, m_trace);
    top->in = 0x12345678;
    top->in_ready = 1;
    top->is_last = 1;
    tick(top, m_trace);
    top->in_ready = 0;
    top->is_last = 0;
    while (!top->out_ready)
        tick(top, m_trace);
    for (int i = 0; i != 5; ++i)
        tick(top, m_trace);

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

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    for (int i = 0; i != 4; ++i)
        tick(top, m_trace);
    top->in_ready = 1;
    top->is_last = 0;
    top->byte_num = 3;
    for (int i = 0; i < 8; ++i)
    {
        top->in = 0xEFCDAB90;
        tick(top, m_trace);
        top->in = 0x78563412;
        tick(top, m_trace);
    }
    top->in = 0xEFCDAB90;
    tick(top, m_trace);
    top->in = 0x78563412;
    top->is_last = 1;
    tick(top, m_trace);
    top->in_ready = 0;
    top->is_last = 0;
    while (!top->out_ready)
        tick(top, m_trace);

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    for (int i = 0; i != 4; ++i)
        tick(top, m_trace);
    top->in_ready = 1;
    top->is_last = 0;
    top->byte_num = 7;
    for (int i = 0; i < 8; ++i)
    {
        top->in = 0xEFCDAB90;
        tick(top, m_trace);
        top->in = 0x78563412;
        tick(top, m_trace);
    }
    top->in = 0xEFCDAB90;
    tick(top, m_trace);
    top->in = 0x78563412;
    top->is_last = 1;
    tick(top, m_trace);
    top->in_ready = 0;
    top->is_last = 0;
    top->in = 0;
    while (!top->out_ready)
        tick(top, m_trace);

    top->reset = 1;
    tick(top, m_trace);
    top->reset = 0;
    top->in_ready = 1;
    top->is_last = 0;
    top->byte_num = 1;
    for (int i = 0; i < 9; ++i)
    {
        top->in = 0xEFCDAB90;
        tick(top, m_trace);
        top->in = 0x78563412;
        tick(top, m_trace);
    }
    tick(top, m_trace);
    top->in = 0x999;
    top->in_ready = 0;
    tick(top, m_trace);
    top->in_ready = 1;
    for (int i = 0; i < 8; ++i)
    {
        top->in = 0xEFCDAB90;
        tick(top, m_trace);
        top->in = 0x78563412;
        tick(top, m_trace);
    }
    top->in = 0xEFCDAB90;
    tick(top, m_trace);
    top->is_last = 1;
    top->byte_num = 2;
    top->in = 0x78563412;
    tick(top, m_trace);
    top->is_last = 0;
    top->in_ready = 0;
    while (!top->out_ready)
        tick(top, m_trace);

    m_trace->close();

    delete m_trace;
    delete top;
    delete contextp;
    return 0;
}