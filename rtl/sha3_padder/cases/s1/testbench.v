`timescale 1ns / 1ps

module testbench;

// Test signals for padder module
reg clk;
reg instrumented_clk;
reg reset;
reg [31:0] in;
reg in_ready;
reg is_last;
reg [1:0] byte_num;
reg f_ack;

wire buffer_full;
wire [575:0] out;
wire out_ready;

// Reference signals  
wire ref_buffer_full;
wire [575:0] ref_out;
wire ref_out_ready;

// Test control
integer test_case;
integer pass_count;
integer fail_count;
integer cycle_count;
integer padding_count;
integer word_index;
integer log_file;

// Test data arrays
reg [31:0] test_data [0:31]; // For storing test data

// Instantiate DUT (Device Under Test)
padder uut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .in_ready(in_ready),
    .is_last(is_last),
    .byte_num(byte_num),
    .buffer_full(buffer_full),
    .out(out),
    .out_ready(out_ready),
    .f_ack(f_ack)
);

// Instantiate reference model
ref_padder ref_model (
    .clk(clk),
    .reset(reset),
    .in(in),
    .in_ready(in_ready),
    .is_last(is_last),
    .byte_num(byte_num),
    .buffer_full(ref_buffer_full),
    .out(ref_out),
    .out_ready(ref_out_ready),
    .f_ack(f_ack)
);

// Clock generation (25MHz, 20ns period to match testbench_new.v)
always begin
    #10 clk = ~clk;
end

// Instrumented clock for tracing
always begin
    #40 instrumented_clk = ~instrumented_clk;
end

// Test application task
task apply_test(
    input rst,
    input [31:0] data_in,
    input ready,
    input last,
    input [1:0] bytes,
    input ack
);
begin
    reset = rst;
    in = data_in;
    in_ready = ready;
    is_last = last;
    byte_num = bytes;
    f_ack = ack;
    
    @(posedge clk);
    cycle_count = cycle_count + 1;
end
endtask

// Result checking task
task check_results;
begin
    if (buffer_full !== ref_buffer_full || out !== ref_out || out_ready !== ref_out_ready) begin
        $fdisplay(log_file,"FAIL: Test case %d, Cycle %d", test_case, cycle_count);
        $fdisplay(log_file,"  Input: in=%h, in_ready=%b, is_last=%b, byte_num=%d, f_ack=%b", 
                 in, in_ready, is_last, byte_num, f_ack);
        $fdisplay(log_file,"  Expected: buffer_full=%b, out_ready=%b", ref_buffer_full, ref_out_ready);
        $fdisplay(log_file,"  Actual:   buffer_full=%b, out_ready=%b", buffer_full, out_ready);
        if (out_ready && ref_out_ready) begin
            $fdisplay(log_file,"  Expected padded output: %h", ref_out);
            $fdisplay(log_file,"  Actual padded output:   %h", out);
        end
        fail_count = fail_count + 1;
    end else begin
        pass_count = pass_count + 1;
    end
end
endtask

// Result verification task
task verify_results;
begin
    check_results;
end
endtask

// Error handling task
task error;
begin
    $display("E");
    fail_count = fail_count + 1;
    $finish;
end
endtask


// Main test sequence
initial begin
    // Initialize signals
    clk = 0;
    instrumented_clk = 0;
    reset = 1;
    in = 0;
    in_ready = 0;
    is_last = 0;
    byte_num = 0;
    f_ack = 0;
    test_case = 0;
    pass_count = 0;
    fail_count = 0;
    cycle_count = 0;
    padding_count = 0;
    word_index = 0;
    
    // Start VCD dump
    $dumpfile("test.vcd");
    $dumpvars(0, uut);
    log_file = $fopen("test.txt", "w");
    
    // Wait for initial setup (100ns like testbench_new.v)
    #100;
    
    // Run test sequences (based on testbench_new.v)
    run_testbench_sequence;
    
    // Report results
    $fdisplay(log_file,"\n=== Test Results ===");
    $fdisplay(log_file,"Total tests: %d", pass_count + fail_count);
    $fdisplay(log_file,"Passed: %d", pass_count);
    $fdisplay(log_file,"Failed: %d", fail_count);
    $fdisplay(log_file,"Total cycles: %d", cycle_count);
    $fdisplay(log_file,"Padding operations: %d", padding_count);
    if (fail_count == 0) begin
        $fdisplay(log_file,"All tests PASSED!");
    end else begin
        $fdisplay(log_file,"Some tests FAILED!");
    end
    
    $finish;
end

// Main test sequence task based on testbench_new.v
task run_testbench_sequence;
integer i;
begin
    $fdisplay(log_file,"Running testbench_new.v test sequence...");
    
    // Wait for initial setup like in testbench_new.v
    @ (negedge clk);

    // Test 1: pad an empty string, should not eat next input
    $fdisplay(log_file,"Test 1: Empty string padding");
    reset = 1; 
    apply_test(1, 0, 0, 0, 0, 0);  // reset = 1
    apply_test(0, 0, 0, 0, 0, 0);  // reset = 0
    
    // wait some cycles (7*P in original)
    repeat(7) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    if (buffer_full !== 0) begin
        $fdisplay(log_file,"FAIL: buffer_full should be 0");
        fail_count = fail_count + 1;
    end
    
    apply_test(0, 0, 1, 1, 0, 0);  // in_ready = 1, is_last = 1
    verify_results;
    
    apply_test(0, 0, 1, 1, 0, 0);  // next input, in_ready = 1, is_last = 1  
    verify_results;
    
    apply_test(0, 0, 0, 0, 0, 0);  // in_ready = 0, is_last = 0
    verify_results;

    // Wait for output ready
    while (out_ready !== 1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    // Acknowledge output
    apply_test(0, 0, 0, 0, 0, 1);  // f_ack = 1
    verify_results;
    apply_test(0, 0, 0, 0, 0, 0);  // f_ack = 0  
    verify_results;
    
    // Check buffer_full should be 0 for next 5 cycles
    for(i=0; i<5; i=i+1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
        if (buffer_full !== 0) begin
            $fdisplay(log_file,"FAIL: buffer_full should be 0");
            fail_count = fail_count + 1;
        end
    end

    // Test 2: pad a (576-8) bit string
    $display("Test 2: 568-bit string padding");
    apply_test(1, 0, 0, 0, 0, 0);  // reset = 1
    apply_test(0, 0, 0, 0, 0, 0);  // reset = 0
    
    // wait some cycles (4*P in original)
    repeat(4) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    apply_test(0, 0, 1, 0, 3, 0);  // in_ready = 1, is_last = 0, byte_num = 3
    verify_results;
    
    for (i=0; i<8; i=i+1) begin
        apply_test(0, 32'h12345678, 1, 0, 3, 0);
        verify_results;
        apply_test(0, 32'h90ABCDEF, 1, 0, 3, 0);
        verify_results;
    end
    
    apply_test(0, 32'h12345678, 1, 0, 3, 0);
    verify_results;
    apply_test(0, 32'h90ABCDEF, 1, 1, 3, 0);  // is_last = 1
    verify_results;
    
    apply_test(0, 0, 0, 0, 0, 0);  // in_ready = 0, is_last = 0
    verify_results;

    // Test 3: pad a (576-64) bit string
    $fdisplay(log_file,"Test 3: 512-bit string padding");
    apply_test(1, 0, 0, 0, 0, 0);  // reset = 1
    apply_test(0, 0, 0, 0, 0, 0);  // reset = 0
    // don't wait any cycle (as in original)
    
    apply_test(0, 0, 1, 0, 1, 0);  // in_ready = 1, is_last = 0, byte_num = 1
    verify_results;
    
    for (i=0; i<8; i=i+1) begin
        apply_test(0, 32'h12345678, 1, 0, 1, 0);
        verify_results;
        apply_test(0, 32'h90ABCDEF, 1, 0, 1, 0);
        verify_results;
    end
    
    apply_test(0, 0, 1, 1, 0, 0);  // is_last = 1, byte_num = 0
    verify_results;
    
    apply_test(0, 0, 0, 0, 0, 0);  // in_ready = 0, is_last = 0
    verify_results;
    
    apply_test(0, 0, 0, 0, 0, 0);
    verify_results;

    // Test 4: pad a (576*2-16) bit string (multi-block)
    $fdisplay(log_file,"Test 4: 1136-bit string padding (multi-block)");
    apply_test(1, 0, 0, 0, 0, 0);  // reset = 1
    apply_test(0, 0, 0, 0, 0, 0);  // reset = 0
    
    apply_test(0, 0, 1, 0, 7, 0);  // in_ready = 1, byte_num = 7, is_last = 0
    verify_results;
    
    for (i=0; i<9; i=i+1) begin
        apply_test(0, 32'h12345678, 1, 0, 7, 0);
        verify_results;
        apply_test(0, 32'h90ABCDEF, 1, 0, 7, 0);
        verify_results;
    end
    
    if (out_ready !== 1) begin
        $fdisplay(log_file,"FAIL: First block should be ready");
        fail_count = fail_count + 1;
    end else begin
        $fdisplay(log_file,"PASS: First block ready");
    end
    
    // Half cycle delays like in original (using repeat to approximate)
    repeat(1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    if (buffer_full !== 1) begin
        $fdisplay(log_file,"FAIL: buffer_full should be 1 (should not eat)");
        fail_count = fail_count + 1;
    end
    
    repeat(1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    apply_test(0, 32'h999, 1, 0, 7, 0);  // should not eat this
    verify_results;
    
    repeat(1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    if (buffer_full !== 1) begin
        $fdisplay(log_file,"FAIL: buffer_full should still be 1 (should not eat)");
        fail_count = fail_count + 1;
    end
    
    repeat(1) begin
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    apply_test(0, 0, 0, 0, 0, 1);  // f_ack = 1
    verify_results;
    apply_test(0, 0, 0, 0, 0, 0);  // f_ack = 0
    verify_results;
    
    if (out_ready !== 0) begin
        $fdisplay(log_file,"FAIL: out_ready should be 0 after ack");
        fail_count = fail_count + 1;
    end
    
    // feed next (576-16) bit
    for (i=0; i<8; i=i+1) begin
        apply_test(0, 32'h12345678, 1, 0, 0, 0);
        verify_results;
        apply_test(0, 32'h90ABCDEF, 1, 0, 0, 0);
        verify_results;
    end
    
    apply_test(0, 32'h12345678, 1, 0, 0, 0);
    verify_results;
    
    apply_test(0, 32'h90ABCDEF, 1, 1, 2, 0);  // byte_num = 2, is_last = 1
    verify_results;
    
    if (out_ready !== 1) begin
        $fdisplay(log_file,"FAIL: Second block should be ready");
        fail_count = fail_count + 1;
    end else begin
        $fdisplay(log_file,"PASS: Second block ready");
    end
    
    apply_test(0, 0, 0, 0, 0, 0);  // is_last = 0
    verify_results;
    
    // eat these bits
    apply_test(0, 0, 0, 0, 0, 1);  // f_ack = 1
    verify_results;
    apply_test(0, 0, 0, 0, 0, 0);  // f_ack = 0
    verify_results;
    
    // should not provide any more bits, if user provides nothing
    apply_test(0, 0, 0, 0, 0, 0);  // in_ready = 0, is_last = 0
    verify_results;
    
    for (i=0; i<10; i=i+1) begin
        if (out_ready === 1) begin
            $fdisplay(log_file,"FAIL: Should not have more output");
            fail_count = fail_count + 1;
        end
        apply_test(0, 0, 0, 0, 0, 0);
        verify_results;
    end
    
    apply_test(0, 0, 0, 0, 0, 0);  // final in_ready = 0
    verify_results;

end
endtask

endmodule

// Reference model for padder (simplified version for comparison)
module ref_padder (
    clk,
    reset,
    in,
    in_ready,
    is_last,
    byte_num,
    buffer_full,
    out,
    out_ready,
    f_ack
);
  input clk, reset;
  input [31:0] in;
  input in_ready, is_last;
  input [1:0] byte_num;
  output buffer_full;   
  output reg [575:0] out;   
  output out_ready;   
  input f_ack;   

  reg state;   
  reg done;   
  reg [17:0] i;   
  wire [31:0] v0;   
  reg [31:0] v1;   
  wire accept, update;

  assign buffer_full = i[17];
  assign out_ready = buffer_full;
  assign accept = (~state) & in_ready & (~buffer_full);  
  assign update = (accept | (state & (~buffer_full))) & (~done);  

  always @(posedge clk)
    if (reset) out <= 0;
    else if (update) out <= {out[575-32:0], v1};

  always @(posedge clk)
    if (reset) i <= 0;
    else if (f_ack | update) i <= {i[16:0], 1'b1} & {18{~f_ack}};

  always @(posedge clk)
    if (reset) state <= 0;
    else if (is_last) state <= 1;

  always @(posedge clk)
    if (reset) done <= 0;
    else if (state & out_ready) done <= 1;

  always @(*)
    case (byte_num)
      0: out = 32'h01000000;
      1: out = {in[31:24], 24'h010000};
      2: out = {in[31:16], 16'h0100};
      3: out = {in[31:8], 8'h01};
    endcase

  always @(*) begin
    if (state) begin
      v1 = 0;
      v1[7] = v1[7] | i[16];  
    end else if (is_last == 0) v1 = in;
    else begin
      v1 = v0;
      v1[7] = v1[7] | i[16];
    end
  end
endmodule

// module padder1 (
//     in,
//     byte_num,
//     out
// );
//   input [31:0] in;
//   input [1:0] byte_num;
//   output reg [31:0] out;

  
// endmodule

