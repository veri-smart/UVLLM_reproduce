`timescale 1ns / 1ps

module testbench;

// Test signals for xxxxx (synthetic) module
reg clk;
reg rst;
reg a;
reg [3:0] b;
reg [7:0] c;
reg [9:0] d;

wire e;
wire [15:0] f;
wire [3:0] g;
wire h;

// Reference signals
wire ref_e;
wire [15:0] ref_f;
wire [3:0] ref_g;
wire ref_h;

// Test control
integer test_case;
integer pass_count;
integer fail_count;
integer cycle_count;
integer operation_count;
integer log_file;

// Test data arrays
reg [25:0] test_vectors [0:31]; // Combined input vectors {a, b[3:0], c[7:0], d[9:0], rst}

// Instantiate DUT (Device Under Test)
xxxxx uut (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .e(e),
    .f(f),
    .g(g),
    .h(h)
);

// Instantiate reference model
ref_xxxxx ref_model (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .c(c),
    .d(d),
    .e(ref_e),
    .f(ref_f),
    .g(ref_g),
    .h(ref_h)
);

// Clock generation (50MHz)
always begin
    #10 clk = ~clk;
end

// Test application task
task apply_test(
    input reset,
    input a_val,
    input [3:0] b_val,
    input [7:0] c_val,
    input [9:0] d_val
);
begin
    rst = reset;
    a = a_val;
    b = b_val;
    c = c_val;
    d = d_val;
    
    @(posedge clk);
    cycle_count = cycle_count + 1;
end
endtask

// Result checking task
task check_results;
begin
    if (e !== ref_e || f !== ref_f || g !== ref_g || h !== ref_h) begin
        $fdisplay(log_file ,"FAIL: Test case %d, Cycle %d", test_case, cycle_count);
        $fdisplay(log_file ,"  Input: rst=%b, a=%b, b=%h, c=%h, d=%h", rst, a, b, c, d);
        $fdisplay(log_file ,"  Expected: e=%b, f=%h, g=%h, h=%b", ref_e, ref_f, ref_g, ref_h);
        $fdisplay(log_file ,"  Actual:   e=%b, f=%h, g=%h, h=%b", e, f, g, h);
        $fdisplay(log_file ,"  Combinational output e: expected=%b, actual=%b", ref_e, e);
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

// Reset module
task reset_module;
begin
    $fdisplay(log_file ,"Resetting module...");
    apply_test(1'b1, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    apply_test(1'b0, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
end
endtask

// Test with a=0 (zero_a.cpp pattern)
task test_zero_a;
integer i;
reg [3:0] rand_b;
reg [7:0] rand_c;
reg [9:0] rand_d;
integer seed;
begin
    $fdisplay(log_file ,"Starting zero_a test...");
    test_case = 1;
    
    seed = 12345; // Fixed seed for reproducibility
    
    // Reset first
    apply_test(1'b1, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    apply_test(1'b0, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    // Test with a=0 and random b,c,d values
    for (i = 0; i < 100; i = i + 1) begin
        // Generate pseudo-random values
        rand_b = (i * 17 + 23) & 4'hF;
        rand_c = (i * 31 + 47) & 8'hFF;
        rand_d = (i * 61 + 89) & 10'h3FF;
        
        apply_test(1'b0, 1'b0, rand_b, rand_c, rand_d);
        verify_results;
        
        if ((i % 20) == 0) begin
            $fdisplay(log_file ,"  Zero_a cycle %d: b=%h, c=%h, d=%h -> e=%b, f=%h, g=%h, h=%b", 
                     i, rand_b, rand_c, rand_d, e, f, g, h);
        end
        
        operation_count = operation_count + 1;
    end
    
    $fdisplay(log_file ,"  Zero_a test completed");
end
endtask

// Test with a=1 (one_a.cpp pattern)
task test_one_a;
integer i;
reg [3:0] rand_b;
reg [7:0] rand_c;
reg [9:0] rand_d;
integer seed;
begin
    $fdisplay(log_file ,"Starting one_a test...");
    test_case = 2;
    
    seed = 54321; // Different seed for reproducibility
    
    // Reset first
    apply_test(1'b1, 1'b1, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    apply_test(1'b0, 1'b1, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    // Test with a=1 and random b,c,d values
    for (i = 0; i < 100; i = i + 1) begin
        // Generate pseudo-random values (different pattern)
        rand_b = (i * 13 + 29) & 4'hF;
        rand_c = (i * 37 + 53) & 8'hFF;
        rand_d = (i * 67 + 97) & 10'h3FF;
        
        apply_test(1'b0, 1'b1, rand_b, rand_c, rand_d);
        verify_results;
        
        if ((i % 20) == 0) begin
            $fdisplay(log_file ,"  One_a cycle %d: b=%h, c=%h, d=%h -> e=%b, f=%h, g=%h, h=%b", 
                     i, rand_b, rand_c, rand_d, e, f, g, h);
        end
        
        operation_count = operation_count + 1;
    end
    
    $fdisplay(log_file ,"  One_a test completed");
end
endtask

// Test with random inputs (rand.cpp pattern)
task test_random;
integer i;
reg rand_a;
reg [3:0] rand_b;
reg [7:0] rand_c;
reg [9:0] rand_d;
integer seed;
begin
    $fdisplay(log_file ,"Starting random test...");
    test_case = 3;
    
    seed = 98765; // Another seed
    
    // Reset first
    apply_test(1'b1, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    apply_test(1'b0, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    
    // Test with random a,b,c,d values
    for (i = 0; i < 100; i = i + 1) begin
        // Generate pseudo-random values for all inputs
        rand_a = (i * 19 + 7) & 1'h1;
        rand_b = (i * 41 + 11) & 4'hF;
        rand_c = (i * 71 + 13) & 8'hFF;
        rand_d = (i * 101 + 17) & 10'h3FF;
        
        apply_test(1'b0, rand_a, rand_b, rand_c, rand_d);
        verify_results;
        
        if ((i % 20) == 0) begin
            $fdisplay(log_file ,"  Random cycle %d: a=%b, b=%h, c=%h, d=%h -> e=%b, f=%h, g=%h, h=%b", 
                     i, rand_a, rand_b, rand_c, rand_d, e, f, g, h);
        end
        
        operation_count = operation_count + 1;
    end
    
    $fdisplay(log_file ,"  Random test completed");
end
endtask

// Test specific patterns


// Test reset behavior
task test_reset_behavior;
integer i;
begin
    $fdisplay(log_file ,"Starting reset behavior test...");
    test_case = 5;
    
    // Set some non-zero inputs
    apply_test(1'b0, 1'b1, 4'hA, 8'h5A, 10'h2A5);
    verify_results;
    $fdisplay(log_file ,"  Before reset: f=%h, g=%h, h=%b", f, g, h);
    
    // Apply reset
    apply_test(1'b1, 1'b1, 4'hA, 8'h5A, 10'h2A5);
    verify_results;
    $fdisplay(log_file ,"  During reset: f=%h, g=%h, h=%b", f, g, h);
    
    // Check if outputs are reset properly
    if (f == 16'h0000 && g == 4'h0 && h == 1'b0) begin
        $fdisplay(log_file ,"  ✓ Reset behavior correct");
    end else begin
        $fdisplay(log_file ,"  ✗ Reset behavior incorrect");
    end
    
    // Release reset
    apply_test(1'b0, 1'b1, 4'hA, 8'h5A, 10'h2A5);
    verify_results;
    $fdisplay(log_file ,"  After reset: f=%h, g=%h, h=%b", f, g, h);
    
    // Run a few cycles to see behavior
    for (i = 0; i < 5; i = i + 1) begin
        apply_test(1'b0, 1'b1, 4'hA, 8'h5A, 10'h2A5);
        verify_results;
        $fdisplay(log_file ,"  Cycle %d after reset: f=%h, g=%h, h=%b", i+1, f, g, h);
    end
    
    $fdisplay(log_file ,"  Reset behavior test completed");
end
endtask

// Test combinational logic (output e)
task test_combinational_logic;
integer i, j, k;
reg test_a;
reg [3:0] test_b;
reg [7:0] test_c;
reg [9:0] test_d;
reg expected_e;
begin
    $fdisplay(log_file ,"Starting combinational logic test...");
    test_case = 6;
    
    reset_module;
    
    // Test specific combinations that affect output e
    // e = a + b[0] * c[2] ^ d[7]
    for (i = 0; i < 2; i = i + 1) begin // a values
        for (j = 0; j < 2; j = j + 1) begin // b[0] values
            for (k = 0; k < 2; k = k + 1) begin // c[2] values
                test_a = i[0];
                test_b = {3'b101, j[0]}; // Set b[0] specifically
                test_c = {5'b10101, k[0], 2'b01}; // Set c[2] specifically
                test_d = {2'b10, 1'b1, 7'b0101010}; // Set d[7] specifically
                
                apply_test(1'b0, test_a, test_b, test_c, test_d);
                verify_results;
                
                // Calculate expected e
                expected_e = test_a + (test_b[0] * test_c[2]) ^ test_d[7];
                
                $fdisplay(log_file ,"  Comb test: a=%b, b[0]=%b, c[2]=%b, d[7]=%b -> e=%b (exp=%b)", 
                         test_a, test_b[0], test_c[2], test_d[7], e, expected_e);
            end
        end
    end
    
    $fdisplay(log_file ,"  Combinational logic test completed");
end
endtask

// Test edge cases
task test_edge_cases;
begin
    $fdisplay(log_file, "Starting edge cases test...");
    test_case = 7;
    
    reset_module;
    
    // Test with maximum values
    apply_test(1'b0, 1'b1, 4'hF, 8'hFF, 10'h3FF);
    verify_results;
    $fdisplay(log_file, "  Max values: e=%b, f=%h, g=%h, h=%b", e, f, g, h);
    
    // Test with minimum values
    apply_test(1'b0, 1'b0, 4'h0, 8'h00, 10'h000);
    verify_results;
    $fdisplay(log_file, "  Min values: e=%b, f=%h, g=%h, h=%b", e, f, g, h);
    
    // Test alternating bit patterns
    apply_test(1'b0, 1'b1, 4'h5, 8'h55, 10'h155);
    verify_results;
    $fdisplay(log_file, "  Alt pattern 1: e=%b, f=%h, g=%h, h=%b", e, f, g, h);
    
    apply_test(1'b0, 1'b0, 4'hA, 8'hAA, 10'h2AA);
    verify_results;
    $fdisplay(log_file, "  Alt pattern 2: e=%b, f=%h, g=%h, h=%b", e, f, g, h);
    
    // Test rapid input changes
    apply_test(1'b0, 1'b1, 4'h1, 8'h01, 10'h001);
    verify_results;
    apply_test(1'b0, 1'b0, 4'hE, 8'hFE, 10'h3FE);
    verify_results;
    apply_test(1'b0, 1'b1, 4'h7, 8'h7F, 10'h1FF);
    verify_results;
    $fdisplay(log_file, "  Rapid changes completed");
    
    $fdisplay(log_file, "  Edge cases test completed");
end
endtask

// Main test sequence
initial begin
    // Initialize signals
    clk = 0;
    rst = 1;
    a = 0;
    b = 0;
    c = 0;
    d = 0;
    test_case = 0;
    pass_count = 0;
    fail_count = 0;
    cycle_count = 0;
    operation_count = 0;
    
    // Start VCD dump
    $dumpfile("test.vcd");
    $dumpvars(0, uut);
    log_file = $fopen("test.txt", "w");

    // Wait for initial setup
    repeat(10) @(posedge clk);
    
    // Run test sequences
    test_zero_a;
    test_one_a;
    test_random;
    // test_specific_patterns;
    test_reset_behavior;
    test_combinational_logic;
    test_edge_cases;
    
    // Report results
    $fdisplay(log_file, "\n=== Test Results ===");
    $fdisplay(log_file, "Total tests: %d", pass_count + fail_count);
    $fdisplay(log_file, "Passed: %d", pass_count);
    $fdisplay(log_file, "Failed: %d", fail_count);
    $fdisplay(log_file, "Total cycles: %d", cycle_count);
    $fdisplay(log_file, "Operations tested: %d", operation_count);
    if (fail_count == 0) begin
        $fdisplay(log_file, "All tests PASSED!");
    end else begin
        $fdisplay(log_file, "Some tests FAILED!");
    end
    
    $finish;
end

endmodule

// Reference model for xxxxx (synthetic module) 
module ref_xxxxx (
    input clk,
    input rst,
    input a,
    input [3:0] b,
    input [7:0] c,
    input [9:0] d,
    output e,
    output reg [15:0] f,
    output reg [3:0] g,
    output reg h
);

  assign e = a + b[0] * c[2] ^ d[7];

  always @(posedge clk) begin
    if (rst) f <= 0;
    else if (a) f <= {b, b, c};
    else f <= ({c, c} & {d, 2'b01, b}) * 3;
  end

  always @(posedge clk) begin
    if (rst) g <= 0;
    else g <= b;
  end

  always @(posedge clk) begin
    if (rst) h <= 0;
    else h <= a ^ (|b);
  end

endmodule
