`timescale 1ns / 1ps

module tb_mux_4to1_case;

  // Test signals
  reg [3:0] a, b, c, d;
  reg [1:0] sel;
  wire [3:0] out_dut, out_ref;
  reg clk, instrumented_clk;

  // Instantiate DUT
  mux_4to1_case uut (
    .a(a), .b(b), .c(c), .d(d),
    .sel(sel),
    .out(out_dut)
  );

  // Instantiate Reference Model
  ref_mux_4to1_case ref_model (
    .a(a), .b(b), .c(c), .d(d),
    .sel(sel),
    .out(out_ref)
  );

  // Logging
  integer log_file;
  integer error_count = 0;

  // Waveform generation
  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    log_file = $fopen("test.txt", "w");
    $display("===== Starting MUX Testbench =====");
  end

  initial begin
    // Initialize signals
    clk = 0;
    instrumented_clk = 0;
    sel = 2'b00;
    a = 4'b0001;
    b = 4'b0010;
    c = 4'b0100;
    d = 4'b1000;

    // Add stimulus here using apply_test
    apply_test(4'b0001, 4'b0010, 4'b0100, 4'b1000, 2'b01, "Test Case 1");
    apply_test(4'b0001, 4'b0010, 4'b0100, 4'b1000, 2'b10, "Test Case 2");
    apply_test(4'b0001, 4'b0010, 4'b0100, 4'b1000, 2'b11, "Test Case 3");

    apply_test(4'b1000, 4'b0100, 4'b0010, 4'b0001, 2'b00, "Test Case 4");
    apply_test(4'b1000, 4'b0100, 4'b0010, 4'b0001, 2'b01, "Test Case 5");
    apply_test(4'b1000, 4'b0100, 4'b0010, 4'b0001, 2'b10, "Test Case 6");
    apply_test(4'b1000, 4'b0100, 4'b0010, 4'b0001, 2'b11, "Test Case 7");

    // Verify results using reference model
    forever begin
        @(posedge clk);
        verify_results;
    end

    $finish;
  end

  // Apply and check a test vector
  task apply_test(
    input [3:0] a_in, b_in, c_in, d_in,
    input [1:0] sel_in,
    input [80*8:1] test_name
  );
    begin
      a = a_in; b = b_in; c = c_in; d = d_in;
      sel = sel_in;
      #1;
      check_results(test_name);
    end
  endtask

  task check_results(input [80*8:1] test_name);
    begin
      if (out_dut !== out_ref) begin
        error_count = error_count + 1;
        $fwrite(log_file, "Error @ %0t ns: %s\n", $time, test_name);
        $fwrite(log_file, "Inputs: a=%h, b=%h, c=%h, d=%h, sel=%b\n", a, b, c, d, sel);
        $fwrite(log_file, "DUT Output: %h, REF Output: %h\n", out_dut, out_ref);
        $fwrite(log_file, "-----------------------------\n");
        $display("Mismatch in: %s", test_name);
      end
    end
  endtask

  task verify_results;
    begin
      if (error_count == 0) begin
        $display("=========== Your Design Passed ===========");
        $fwrite(log_file, "=========== Your Design Passed ===========\n");
      end else begin
        $display("=========== Your Design Failed (%0d errors) ===========", error_count);
        $fwrite(log_file, "=========== Your Design Failed (%0d errors) ===========\n", error_count);
      end
    end
  endtask

endmodule

module ref_mux_4to1_case (
    input [3:0] a,
    input [3:0] b,
    input [3:0] c,
    input [3:0] d,
    input [1:0] sel,
    output reg [3:0] out
);

// Reference implementation using case statement (same as DUT)
always @(a or b or c or d or sel) begin
    case (sel)
        2'b00: out <= a;
        2'b01: out <= b;
        2'b10: out <= c;
        2'b11: out <= d;
    endcase
end

endmodule