`timescale 1ns / 1ps

module testbench;

// Test signals for lshift_reg module
reg clk;
reg rstn;
reg [7:0] load_val;
reg load_en;

wire [7:0] op;

// Reference signals
wire [7:0] ref_op;

// Test control
integer test_case;
integer pass_count;
integer fail_count;
integer cycle_count;
integer shift_count;
integer log_file;
// Test data arrays
reg [7:0] test_values [0:15]; // For storing test values

// Instantiate DUT (Device Under Test)
lshift_reg uut (
    .clk(clk),
    .rstn(rstn),
    .load_val(load_val),
    .load_en(load_en),
    .op(op)
);

// Instantiate reference model
ref_lshift_reg ref_model (
    .clk(clk),
    .rstn(rstn),
    .load_val(load_val),
    .load_en(load_en),
    .op(ref_op)
);

// Clock generation (50MHz)
always begin
    #10 clk = ~clk;
end

// Main test sequence
initial begin
    // Initialize signals
    clk = 0;
    rstn = 0;
    load_val = 8'h01;
    load_en = 0;

    $dumpfile("test.vcd");
    $dumpvars(0, uut);
    log_file = $fopen("test.txt", "w");

    // Apply reset to the design
    repeat (2) @ (posedge clk);
    rstn = 1;
    repeat (5) @ (posedge clk);

    // Apply test vectors using apply_test
    apply_test(1'b1, 8'h01, 1'b1, "Load Value Test");
    apply_test(1'b1, 8'h02, 1'b1, "Shift Test 1");
    apply_test(1'b1, 8'h04, 1'b1, "Shift Test 2");

    // Let design run for 20 clocks and check results at each clock
    repeat (20) begin
      @(posedge clk);
      check_results("Periodic Check");
    end

    verify_results;
    $finish;
  end

  task apply_test(
    input rst,
    input [7:0] load_value,
    input load_enable,
    input [80*8:1] test_name
  );
    begin
      rstn = rst;
      load_val = load_value;
      load_en = load_enable;
      @(posedge clk);
      check_results(test_name);
    end
  endtask

  task check_results(input [80*8:1] test_name);
    begin
      if (op !== ref_op) begin
        $fdisplay(log_file, "Mismatch in: %s", test_name);
      end
    end
  endtask

  task verify_results;
    begin
      $fdisplay(log_file, "Verification complete.");
    end
  endtask
endmodule

// Reference model for lshift_reg (simplified version for comparison)
module ref_lshift_reg (
    input            clk,
    input            rstn,
    input      [7:0] load_val,
    input            load_en,
    output reg [7:0] op
);

  integer i;
  always @(posedge clk) begin
    if (rstn) begin
      op <= 0;
    end else begin
      if (load_en) begin
        op <= load_val;
      end else begin
        for (i = 0; i < 8; i = i + 1) begin
          op[i+1] <= op[i];
        end
        op[0] <= op[7];
      end
    end
  end
endmodule