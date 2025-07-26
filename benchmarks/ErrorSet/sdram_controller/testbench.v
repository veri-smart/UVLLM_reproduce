`timescale 1ns / 1ps

module testbench;

// Test signals for HOST INTERFACE
reg [23:0] wr_addr;  // HADDR_WIDTH = 24 (2+13+9)
reg [15:0] wr_data;
reg wr_enable;

reg [23:0] rd_addr;
wire [15:0] rd_data;
wire rd_ready;
reg rd_enable;

wire busy;
reg rst_n;
reg clk;

// Test signals for SDRAM SIDE
wire [12:0] addr;
wire [1:0] bank_addr;
wire data_oe;
wire [15:0] data_out;
reg [15:0] data_in;
wire clock_enable;
wire cs_n;
wire ras_n;
wire cas_n;
wire we_n;
wire data_mask_low;
wire data_mask_high;

// Reference signals
wire [15:0] ref_rd_data;
wire ref_rd_ready;
wire ref_busy;
wire [12:0] ref_addr;
wire [1:0] ref_bank_addr;
wire ref_data_oe;
wire [15:0] ref_data_out;
wire ref_clock_enable;
wire ref_cs_n;
wire ref_ras_n;
wire ref_cas_n;
wire ref_we_n;
wire ref_data_mask_low;
wire ref_data_mask_high;

// Test control
integer test_case;
integer pass_count;
integer fail_count;
integer cycle_count;
integer operation_count;
integer log_file;

// Instantiate DUT (Device Under Test)
sdram_controller uut (
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_enable(wr_enable),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rd_ready(rd_ready),
    .rd_enable(rd_enable),
    .busy(busy),
    .rst_n(rst_n),
    .clk(clk),
    .addr(addr),
    .bank_addr(bank_addr),
    .data_out(data_out),
    .data_in(data_in),
    .data_oe(data_oe),
    .clock_enable(clock_enable),
    .cs_n(cs_n),
    .ras_n(ras_n),
    .cas_n(cas_n),
    .we_n(we_n),
    .data_mask_low(data_mask_low),
    .data_mask_high(data_mask_high)
);

// Instantiate reference model
ref_sdram_controller ref_model (
    .wr_addr(wr_addr),
    .wr_data(wr_data),
    .wr_enable(wr_enable),
    .rd_addr(rd_addr),
    .rd_data(ref_rd_data),
    .rd_ready(ref_rd_ready),
    .rd_enable(rd_enable),
    .busy(ref_busy),
    .rst_n(rst_n),
    .clk(clk),
    .addr(ref_addr),
    .bank_addr(ref_bank_addr),
    .data_out(ref_data_out),
    .data_in(data_in),
    .data_oe(ref_data_oe),
    .clock_enable(ref_clock_enable),
    .cs_n(ref_cs_n),
    .ras_n(ref_ras_n),
    .cas_n(ref_cas_n),
    .we_n(ref_we_n),
    .data_mask_low(ref_data_mask_low),
    .data_mask_high(ref_data_mask_high)
);

// Clock generation (133MHz)
always begin
    #3.75 clk = ~clk; // 133MHz = 7.5ns period
end

// Test application task
task apply_test(
    input rst,
    input [23:0] wr_addr_in,
    input [15:0] wr_data_in,
    input wr_en,
    input [23:0] rd_addr_in,
    input rd_en,
    input [15:0] data_in_val
);
begin
    rst_n = rst;
    wr_addr = wr_addr_in;
    wr_data = wr_data_in;
    wr_enable = wr_en;
    rd_addr = rd_addr_in;
    rd_enable = rd_en;
    data_in = data_in_val;
    
    @(posedge clk);
    cycle_count = cycle_count + 1;
end
endtask

// Result checking task
task check_results;
begin
    if (rd_data !== ref_rd_data || rd_ready !== ref_rd_ready || 
        busy !== ref_busy || addr !== ref_addr || bank_addr !== ref_bank_addr ||
        data_oe !== ref_data_oe || data_out !== ref_data_out ||
        clock_enable !== ref_clock_enable || cs_n !== ref_cs_n ||
        ras_n !== ref_ras_n || cas_n !== ref_cas_n || we_n !== ref_we_n ||
        data_mask_low !== ref_data_mask_low || data_mask_high !== ref_data_mask_high) begin
        $display("FAIL: Test case %d, Cycle %d", test_case, cycle_count);
        $display("  Host Interface:");
        $display("    wr_addr=%h, wr_data=%h, wr_enable=%b", wr_addr, wr_data, wr_enable);
        $display("    rd_addr=%h, rd_enable=%b, data_in=%h", rd_addr, rd_enable, data_in);
        $display("  Expected: rd_data=%h, rd_ready=%b, busy=%b", ref_rd_data, ref_rd_ready, ref_busy);
        $display("  Actual:   rd_data=%h, rd_ready=%b, busy=%b", rd_data, rd_ready, busy);
        $display("  SDRAM Control Expected: addr=%h, bank=%h, oe=%b", ref_addr, ref_bank_addr, ref_data_oe);
        $display("  SDRAM Control Actual:   addr=%h, bank=%h, oe=%b", addr, bank_addr, data_oe);
        fail_count = fail_count + 1;
    end else begin
        pass_count = pass_count + 1;
    end
end
endtask

initial begin
  $dumpfile("test.vcd");
  $dumpvars(0, uut);
  log_file = $fopen("test.txt", "w");
end

// Result verification task
task verify_results;
begin
    check_results;
end
endtask

// Wait for busy to clear
task wait_for_ready;
integer timeout;
begin
    timeout = 0;
    while (busy && timeout < 1000) begin
        @(posedge clk);
        timeout = timeout + 1;
        cycle_count = cycle_count + 1;
    end
    
    if (timeout >= 1000) begin
        $display("ERROR: Timeout waiting for SDRAM ready");
        fail_count = fail_count + 1;
    end
end
endtask

// === Main Test Sequence ===
initial begin
    // Init
    clk = 0;
    rst_n = 1;
    wr_addr = 0;
    wr_data = 0;
    wr_enable = 0;
    rd_addr = 0;
    rd_enable = 0;
    data_in = 0;
    pass_count = 0;
    fail_count = 0;

    // Reset sequence
    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'h0);
    check_results;

    apply_test(1'b1, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'h0);
    check_results;

    // Write operation
    apply_test(1'b0, 24'hfedbed, 16'h3333, 1'b1, 24'h0, 1'b0, 16'h0);
    check_results;

    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'h0);
    check_results;

    // Read operation
    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'hbedfed, 1'b1, 16'h0);
    check_results;

    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'h0);
    check_results;

    // Data manipulation
    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'hbbbb);
    check_results;

    apply_test(1'b0, 24'h0, 16'h0, 1'b0, 24'h0, 1'b0, 16'hzzzz);
    check_results;

    // Summary
    $display("\n=== Summary ===");
    $display("Total: %0d, Passed: %0d, Failed: %0d", pass_count + fail_count, pass_count, fail_count);
    if (fail_count == 0)
        $display("All tests passed!");
    else
        $display("Some tests failed!");

    $finish;
end

endmodule

// Reference model for SDRAM Controller (simplified version for comparison)
module ref_sdram_controller (
    /* HOST INTERFACE */
    wr_addr,
    wr_data,
    wr_enable,

    rd_addr,
    rd_data,
    rd_ready,
    rd_enable,

    busy,
    rst_n,
    clk,

    /* SDRAM SIDE */
    addr,
    bank_addr,
    // replaced tri-state `data
    data_out,
    data_in,
    data_oe,
    clock_enable,
    cs_n,
    ras_n,
    cas_n,
    we_n,
    data_mask_low,
    data_mask_high
);

  /* Internal Parameters */
  parameter ROW_WIDTH = 13;
  parameter COL_WIDTH = 9;
  parameter BANK_WIDTH = 2;

  parameter SDRADDR_WIDTH = ROW_WIDTH > COL_WIDTH ? ROW_WIDTH : COL_WIDTH;
  parameter HADDR_WIDTH = BANK_WIDTH + ROW_WIDTH + COL_WIDTH;

  parameter CLK_FREQUENCY = 133;  // Mhz
  parameter REFRESH_TIME = 32;  // ms     (how often we need to refresh)
  parameter REFRESH_COUNT = 8192;  // cycles (how many refreshes required per refresh time)

  // clk / refresh =  clk / sec
  //                , sec / refbatch
  //                , ref / refbatch
  localparam CYCLES_BETWEEN_REFRESH = (CLK_FREQUENCY * 1_000 * REFRESH_TIME) / REFRESH_COUNT;

  // STATES - State
  localparam IDLE = 5'b00000;

  localparam INIT_NOP1 = 5'b01000,
           INIT_PRE1 = 5'b01001,
           INIT_NOP1_1=5'b00101,
           INIT_REF1 = 5'b01010,
           INIT_NOP2 = 5'b01011,
           INIT_REF2 = 5'b01100,
           INIT_NOP3 = 5'b01101,
           INIT_LOAD = 5'b01110,
           INIT_NOP4 = 5'b01111;

  localparam REF_PRE = 5'b00001, REF_NOP1 = 5'b00010, REF_REF = 5'b00011, REF_NOP2 = 5'b00100;

  localparam READ_ACT  = 5'b10000,
           READ_NOP1 = 5'b10001,
           READ_CAS  = 5'b10010,
           READ_NOP2 = 5'b10011,
           READ_READ = 5'b10100;

  localparam WRIT_ACT = 5'b11000, WRIT_NOP1 = 5'b11001, WRIT_CAS = 5'b11010, WRIT_NOP2 = 5'b11011;

  // Commands              CCRCWBBA
  //                       ESSSE100
  localparam CMD_PALL = 8'b10010001,
           CMD_REF  = 8'b10001000,
           CMD_NOP  = 8'b10111000,
           CMD_MRS  = 8'b1000000x,
           CMD_BACT = 8'b10011xxx,
           CMD_READ = 8'b10101xx1,
           CMD_WRIT = 8'b10100xx1;

  /* Interface Definition */
  /* HOST INTERFACE */
  input [HADDR_WIDTH-1:0] wr_addr;
  input [15:0] wr_data;
  input wr_enable;

  input [HADDR_WIDTH-1:0] rd_addr;
  output [15:0] rd_data;
  input rd_enable;
  output rd_ready;

  output busy;
  input rst_n;
  input clk;

  /* SDRAM SIDE */
  //output [SDRADDR_WIDTH-1:0] addr;
  //output [BANK_WIDTH-1:0]    bank_addr;
  output [12:0] addr;
  output [1:0] bank_addr;
  // replaced tri-state
  //inout  [15:0]              data;
  output data_oe;
  output [15:0] data_out;
  input [15:0] data_in;
  output clock_enable;
  output cs_n;
  output ras_n;
  output cas_n;
  output we_n;
  output data_mask_low;
  output data_mask_high;

  /* I/O Registers */

  reg  [  HADDR_WIDTH-1:0] haddr_r;
  reg  [             15:0] wr_data_r;
  reg  [             15:0] rd_data_r;
  reg                      busy;
  reg                      data_mask_low_r;
  reg                      data_mask_high_r;
  reg  [SDRADDR_WIDTH-1:0] addr_r;
  reg  [   BANK_WIDTH-1:0] bank_addr_r;
  reg                      rd_ready_r;

  wire [             15:0] data_output;
  wire data_mask_low, data_mask_high;

  assign data_mask_high = data_mask_high_r;
  assign data_mask_low  = data_mask_low_r;
  assign rd_data        = rd_data_r;

  /* Internal Wiring */
  reg [3:0] state_cnt;
  reg [9:0] refresh_cnt;

  reg [7:0] command;
  reg [4:0] state;

  // TODO output addr[6:4] when programming mode register

  reg [7:0] command_nxt;
  reg [3:0] state_cnt_nxt;
  reg [4:0] next;

  assign {clock_enable, cs_n, ras_n, cas_n, we_n} = command[7:3];
  // state[4] will be set if mode is read/write
  assign bank_addr = (state[4]) ? bank_addr_r : command[2:1];
  assign addr           = (state[4] | state == INIT_LOAD) ? addr_r : { {SDRADDR_WIDTH-11{1'b0}}, command[0], 10'd0 };

  // replaced tri-state
  //assign data = (state == WRIT_CAS) ? wr_data_r : 16'bz;
  assign data_oe = state == WRIT_CAS;
  assign data_out = wr_data_r;
  assign rd_ready = rd_ready_r;

  // HOST INTERFACE
  // all registered on posedge
  always @(posedge clk)
    if (~rst_n) begin
      state <= INIT_NOP1;
      command <= CMD_NOP;
      state_cnt <= 4'hf;

      haddr_r <= {HADDR_WIDTH{1'b0}};
      wr_data_r <= 16'b0;
      rd_data_r <= 16'b0;
      busy <= 1'b0;
    end else begin

      state   <= next;
      command <= command_nxt;

      if (!state_cnt) state_cnt <= state_cnt_nxt;
      else state_cnt <= state_cnt - 1'b1;

      if (wr_enable) wr_data_r <= wr_data;

      if (state == READ_READ) begin
        rd_data_r  <= data_in;
        rd_ready_r <= 1'b1;
      end else rd_ready_r <= 1'b0;

      busy <= state[4];

      if (rd_enable) haddr_r <= rd_addr;
      else if (wr_enable) haddr_r <= wr_addr;

    end

  // Handle refresh counter
  always @(posedge clk)
    if (~rst_n) refresh_cnt <= 10'b0;
    else if (state == REF_NOP2) refresh_cnt <= 10'b0;
    else refresh_cnt <= refresh_cnt + 1'b1;


  /* Handle logic for sending addresses to SDRAM based on current state*/
  always @(*) begin
    if (state[4]) {data_mask_low_r, data_mask_high_r} = 2'b00;
    else {data_mask_low_r, data_mask_high_r} = 2'b11;

    bank_addr_r = 2'b00;
    addr_r = {SDRADDR_WIDTH{1'b0}};

    if (state == READ_ACT | state == WRIT_ACT) begin
      bank_addr_r = haddr_r[HADDR_WIDTH-1:HADDR_WIDTH-(BANK_WIDTH)];
      addr_r = haddr_r[HADDR_WIDTH-(BANK_WIDTH+1):HADDR_WIDTH-(BANK_WIDTH+ROW_WIDTH)];
    end else if (state == READ_CAS | state == WRIT_CAS) begin
      // Send Column Address
      // Set bank to bank to precharge
      bank_addr_r = haddr_r[HADDR_WIDTH-1:HADDR_WIDTH-(BANK_WIDTH)];

      // Examples for math
      //               BANK  ROW    COL
      // HADDR_WIDTH   2 +   13 +   9   = 24
      // SDRADDR_WIDTH 13

      // Set CAS address to:
      //   0s,
      //   1 (A10 is always for auto precharge),
      //   0s,
      //   column address
      addr_r = {
        {SDRADDR_WIDTH - (11) {1'b0}},
        1'b1,  /* A10 */
        {10 - COL_WIDTH{1'b0}},
        haddr_r[COL_WIDTH-1:0]
      };
    end else if (state == INIT_LOAD) begin
      // Program mode register during load cycle
      //                                       B  C  SB
      //                                       R  A  EUR
      //                                       S  S-3Q ST
      //                                       T  654L210
      addr_r = {{SDRADDR_WIDTH - 10{1'b0}}, 10'b1000110000};
    end
  end

  // Next state logic
  always @(*) begin
    state_cnt_nxt = 4'd0;
    command_nxt   = CMD_NOP;
    if (state == IDLE)
      // Monitor for refresh or hold
      if (refresh_cnt >= CYCLES_BETWEEN_REFRESH) begin
        next = REF_PRE;
        command_nxt = CMD_PALL;
      end else if (rd_enable) begin
        next = READ_ACT;
        command_nxt = CMD_BACT;
      end else if (wr_enable) begin
        next = WRIT_ACT;
        command_nxt = CMD_BACT;
      end else begin
        // HOLD
        next = IDLE;
      end
    else if (!state_cnt)
      case (state)
        // INIT ENGINE
        INIT_NOP1: begin
          next = INIT_PRE1;
          command_nxt = CMD_PALL;
        end
        INIT_PRE1: begin
          next = INIT_NOP1_1;
        end
        INIT_NOP1_1: begin
          next = INIT_REF1;
          command_nxt = CMD_REF;
        end
        INIT_REF1: begin
          next = INIT_NOP2;
          state_cnt_nxt = 4'd7;
        end
        INIT_NOP2: begin
          next = INIT_REF2;
          command_nxt = CMD_REF;
        end
        INIT_REF2: begin
          next = INIT_NOP3;
          state_cnt_nxt = 4'd7;
        end
        INIT_NOP3: begin
          next = INIT_LOAD;
          command_nxt = CMD_MRS;
        end
        INIT_LOAD: begin
          next = INIT_NOP4;
          state_cnt_nxt = 4'd1;
        end
        // INIT_NOP4: default - IDLE

        // REFRESH
        REF_PRE: begin
          next = REF_NOP1;
        end
        REF_NOP1: begin
          next = REF_REF;
          command_nxt = CMD_REF;
        end
        REF_REF: begin
          next = REF_NOP2;
          state_cnt_nxt = 4'd7;
        end
        // REF_NOP2: default - IDLE

        // WRITE
        WRIT_ACT: begin
          next = WRIT_NOP1;
          state_cnt_nxt = 4'd1;
        end
        WRIT_NOP1: begin
          next = WRIT_CAS;
          command_nxt = CMD_WRIT;
        end
        WRIT_CAS: begin
          next = WRIT_NOP2;
          state_cnt_nxt = 4'd1;
        end
        // WRIT_NOP2: default - IDLE

        // READ
        READ_ACT: begin
          next = READ_NOP1;
          state_cnt_nxt = 4'd1;
        end
        READ_NOP1: begin
          next = READ_CAS;
          command_nxt = CMD_READ;
        end
        READ_CAS: begin
          next = READ_NOP2;
          state_cnt_nxt = 4'd1;
        end
        READ_NOP2: begin
          next = READ_READ;
        end
        // READ_READ: default - IDLE

        default: begin
          next = IDLE;
        end
      endcase
    else begin
      // Counter Not Reached - HOLD
      next = state;
      command_nxt = command;
    end
  end

endmodule
