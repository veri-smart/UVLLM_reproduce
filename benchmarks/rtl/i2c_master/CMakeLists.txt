cmake_minimum_required(VERSION 3.30)
project(tb)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_package(verilator HINTS $ENV{VERILATOR_ROOT})

add_executable(Vsim tbs/tb1.cpp)

verilate(Vsim
    SOURCES gold/i2c_master_bit_ctrl.v gold/i2c_master_byte_ctrl.v gold/i2c_master_defines.v gold/i2c_master_top.v tbs/tst_bench_top_t1.v
    PREFIX Vmodule
    TOP_MODULE tst_bench_top
    TRACE
    INCLUDE_DIRS inc gold
    VERILATOR_ARGS --trace-depth 1 --timing -Wno-fatal
)