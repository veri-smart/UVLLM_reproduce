`timescale 1ns / 1ps

module testbench;

// Test signals for keccak module
reg clk;
reg reset;
reg [31:0] in;
reg in_ready;
reg is_last;
reg [1:0] byte_num;

wire buffer_full;
wire [511:0] out;
wire out_ready;

// Reference signals
wire ref_buffer_full;
wire [511:0] ref_out;
wire ref_out_ready;

// Test control
integer test_case;
integer pass_count;
integer fail_count;
integer cycle_count;
integer hash_count;
integer word_index;
integer log_file;

// Test data arrays
reg [31:0] test_message [0:15]; // For storing test messages
reg [511:0] expected_hash;

// Instantiate DUT (Device Under Test)
keccak uut (
    .clk(clk),
    .reset(reset),
    .in(in),
    .in_ready(in_ready),
    .is_last(is_last),
    .byte_num(byte_num),
    .buffer_full(buffer_full),
    .out(out),
    .out_ready(out_ready)
);

// Instantiate reference model
ref_keccak ref_model (
    .clk(clk),
    .reset(reset),
    .in(in),
    .in_ready(in_ready),
    .is_last(is_last),
    .byte_num(byte_num),
    .buffer_full(ref_buffer_full),
    .out(ref_out),
    .out_ready(ref_out_ready)
);

// Clock generation (50MHz)
always begin
    #10 clk = ~clk;
end

// Test application task
task apply_test(
    input rst,
    input [31:0] data_in,
    input ready,
    input last,
    input [1:0] bytes
);
begin
    reset = rst;
    in = data_in;
    in_ready = ready;
    is_last = last;
    byte_num = bytes;
    
    @(posedge clk);
    cycle_count = cycle_count + 1;
end
endtask

// Result checking task
task check_results;
begin
    if (buffer_full !== ref_buffer_full || out !== ref_out || out_ready !== ref_out_ready) begin
        $fdisplay(log_file,"FAIL: Test case %d, Cycle %d", test_case, cycle_count);
        $fdisplay(log_file,"  Input: in=%h, in_ready=%b, is_last=%b, byte_num=%d", in, in_ready, is_last, byte_num);
        $fdisplay(log_file,"  Expected: buffer_full=%b, out_ready=%b", ref_buffer_full, ref_out_ready);
        $fdisplay(log_file,"  Actual:   buffer_full=%b, out_ready=%b", buffer_full, out_ready);
        if (out_ready && ref_out_ready) begin
            $fdisplay(log_file,"  Expected hash: %h", ref_out);
            $fdisplay(log_file,"  Actual hash:   %h", out);
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

// Wait for hash completion
task wait_for_hash_ready;
integer timeout;
begin
    timeout = 0;
    while (!out_ready && timeout < 1000) begin
        apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
        timeout = timeout + 1;
    end
    
    if (timeout >= 1000) begin
        $fdisplay(log_file,"ERROR: Timeout waiting for hash completion");
        fail_count = fail_count + 1;
    end else if (out_ready) begin
        $fdisplay(log_file,"  Hash completed after %d cycles", timeout);
        $fdisplay(log_file,"  Result: %h", out);
        hash_count = hash_count + 1;
    end
end
endtask

// Main test sequence 
initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    in = 0;
    in_ready = 0;
    is_last = 0;
    byte_num = 0;
    test_case = 0;
    pass_count = 0;
    fail_count = 0;
    cycle_count = 0;
    word_index = 0;
    
    // Start VCD dump
    $dumpfile("test.vcd");
    // $dumpvars(0,uut);
    $dumpvars(5, clk, reset, in, in_ready, is_last, byte_num, buffer_full, out, out_ready);
    log_file= $fopen("test.txt", "w");
    
    // Wait for initial setup
    repeat(10) @(posedge clk);
    reset = 0;
    
    // Test 1: SHA3-512("The quick brown fox jumps over the lazy dog")
    $fdisplay(log_file,"Test 1: SHA3-512 'The quick brown fox jumps over the lazy dog'");
    test_case = 1;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    
    apply_test(1'b0, 32'h54686520, 1'b1, 1'b0, 2'b0); // "The "
    verify_results;
    apply_test(1'b0, 32'h71756963, 1'b1, 1'b0, 2'b0); // "quic"
    verify_results;
    apply_test(1'b0, 32'h6B206272, 1'b1, 1'b0, 2'b0); // "k br"
    verify_results;
    apply_test(1'b0, 32'h6F776E20, 1'b1, 1'b0, 2'b0); // "own "
    verify_results;
    apply_test(1'b0, 32'h666F7820, 1'b1, 1'b0, 2'b0); // "fox "
    verify_results;
    apply_test(1'b0, 32'h6A756D70, 1'b1, 1'b0, 2'b0); // "jump"
    verify_results;
    apply_test(1'b0, 32'h73206F76, 1'b1, 1'b0, 2'b0); // "s ov"
    verify_results;
    apply_test(1'b0, 32'h65722074, 1'b1, 1'b0, 2'b0); // "er t"
    verify_results;
    apply_test(1'b0, 32'h6865206C, 1'b1, 1'b0, 2'b0); // "he l"
    verify_results;
    apply_test(1'b0, 32'h617A7920, 1'b1, 1'b0, 2'b0); // "azy "
    verify_results;
    apply_test(1'b0, 32'h646F6720, 1'b1, 1'b1, 2'd3); // "dog " (last word, 3 bytes)
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Test 2: SHA3-512("The quick brown fox jumps over the lazy dog.")
    $fdisplay(log_file,"Test 2: SHA3-512 'The quick brown fox jumps over the lazy dog.'");
    test_case = 2;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    

    apply_test(1'b0, 32'h54686520, 1'b1, 1'b0, 2'b0); // "The "
    verify_results;
    apply_test(1'b0, 32'h71756963, 1'b1, 1'b0, 2'b0); // "quic"
    verify_results;
    apply_test(1'b0, 32'h6B206272, 1'b1, 1'b0, 2'b0); // "k br"
    verify_results;
    apply_test(1'b0, 32'h6F776E20, 1'b1, 1'b0, 2'b0); // "own "
    verify_results;
    apply_test(1'b0, 32'h666F7820, 1'b1, 1'b0, 2'b0); // "fox "
    verify_results;
    apply_test(1'b0, 32'h6A756D70, 1'b1, 1'b0, 2'b0); // "jump"
    verify_results;
    apply_test(1'b0, 32'h73206F76, 1'b1, 1'b0, 2'b0); // "s ov"
    verify_results;
    apply_test(1'b0, 32'h65722074, 1'b1, 1'b0, 2'b0); // "er t"
    verify_results;
    apply_test(1'b0, 32'h6865206C, 1'b1, 1'b0, 2'b0); // "he l"
    verify_results;
    apply_test(1'b0, 32'h617A7920, 1'b1, 1'b0, 2'b0); // "azy "
    verify_results;
    apply_test(1'b0, 32'h646F672E, 1'b1, 1'b0, 2'b0); // "dog."
    verify_results;
    apply_test(1'b0, 32'h0, 1'b1, 1'b1, 2'b0); // empty last word
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Test 3: Hash string "\xA1\xA2\xA3\xA4\xA5", len == 5
    $fdisplay(log_file,"Test 3: Hash byte sequence A1A2A3A4A5");
    test_case = 3;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    
    // Wait some cycles
    repeat(7) begin
        apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
        verify_results;
    end
    
    apply_test(1'b0, 32'hA1A2A3A4, 1'b1, 1'b0, 2'b1);
    verify_results;
    apply_test(1'b0, 32'hA5000000, 1'b1, 1'b1, 2'b0);
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Test 4: Hash empty string
    $fdisplay(log_file,"Test 4: Hash empty string");
    test_case = 4;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    
    // Wait some cycles
    repeat(7) begin
        apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
        verify_results;
    end
    
    apply_test(1'b0, 32'h0, 1'b1, 1'b1, 2'b0); // empty message
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Test 5: Hash (576-8) bit string  
    $fdisplay(log_file,"Test 5: Hash (576-8) bit string");
    test_case = 5;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    
    // Wait some cycles
    repeat(4) begin
        apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
        verify_results;
    end
    
    // Send data pattern
    for (word_index = 0; word_index < 8; word_index = word_index + 1) begin
        apply_test(1'b0, 32'hEFCDAB90, 1'b1, 1'b0, 2'd3);
        verify_results;
        apply_test(1'b0, 32'h78563412, 1'b1, 1'b0, 2'b0);
        verify_results;
    end
    apply_test(1'b0, 32'hEFCDAB90, 1'b1, 1'b0, 2'b0);
    verify_results;
    apply_test(1'b0, 32'h78563412, 1'b1, 1'b1, 2'b0); // last word
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Test 6: Pad (576-64) bit string
    $fdisplay(log_file,"Test 6: Pad (576-64) bit string");
    test_case = 6;
    apply_test(1'b1, 32'h0, 1'b0, 1'b0, 2'b0); // reset
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0);
    verify_results;
    
    // Send data pattern immediately
    for (word_index = 0; word_index < 8; word_index = word_index + 1) begin
        apply_test(1'b0, 32'hEFCDAB90, 1'b1, 1'b0, 2'b0);
        verify_results;
        apply_test(1'b0, 32'h78563412, 1'b1, 1'b0, 2'b0);
        verify_results;
    end
    apply_test(1'b0, 32'h0, 1'b1, 1'b1, 2'b0); // last empty word
    verify_results;
    
    apply_test(1'b0, 32'h0, 1'b0, 1'b0, 2'b0); // stop input
    verify_results;
    wait_for_hash_ready;
    verify_results;
    
    // Report results
    $fdisplay(log_file,"\n=== Test Results ===");
    $fdisplay(log_file,"Total tests: %d", pass_count + fail_count);
    $fdisplay(log_file,"Passed: %d", pass_count);
    $fdisplay(log_file,"Failed: %d", fail_count);
    $fdisplay(log_file,"Total cycles: %d", cycle_count);
    $fdisplay(log_file,"Hashes computed: %d", hash_count);
    if (fail_count == 0) begin
        $fdisplay(log_file,"All tests PASSED!");
    end else begin
        $fdisplay(log_file,"Some tests FAILED!");
    end
    
    $finish;
end

endmodule

`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)
// Reference model for keccak (simplified version for comparison)

`define low_pos(w,b)      ((w)*64 + (b)*8)
`define low_pos2(w,b)     `low_pos(w,7-b)
`define high_pos(w,b)     (`low_pos(w,b) + 7)
`define high_pos2(w,b)    (`low_pos2(w,b) + 7)

module ref_keccak(clk, reset, in, in_ready, is_last, byte_num, buffer_full, out, out_ready);
    input              clk, reset;
    input      [31:0]  in;
    input              in_ready, is_last;
    input      [1:0]   byte_num;
    output             buffer_full;  
    output     [511:0] out;
    output reg         out_ready;

    reg                state;      
    wire       [575:0] padder_out,
                       padder_out_1;  
    wire               padder_out_ready;
    wire               f_ack;
    wire      [1599:0] f_out;
    wire               f_out_ready;
    wire       [511:0] out1;       
    reg        [22:0]  i;          

    genvar w, b;

    assign out1 = f_out[1599:1599-511];

    always @ (posedge clk)
      if (reset)
        i <= 0;
      else
        i <= {i[21:0], state & f_ack};

    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;

     
    generate
      for(w=0; w<8; w=w+1)
        begin : L0
          for(b=0; b<8; b=b+1)
            begin : L1
              assign out[`high_pos(w,b):`low_pos(w,b)] = out1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

     
    generate
      for(w=0; w<9; w=w+1)
        begin : L2
          for(b=0; b<8; b=b+1)
            begin : L3
              assign padder_out[`high_pos(w,b):`low_pos(w,b)] = padder_out_1[`high_pos2(w,b):`low_pos2(w,b)];
            end
        end
    endgenerate

    always @ (posedge clk)
      if (reset)
        out_ready <= 0;
      else if (i[22])
        out_ready <= 1;

    ref_padder
      ref_padder_ (clk, reset, in, in_ready, is_last, byte_num, buffer_full, padder_out_1, padder_out_ready, f_ack);

    ref_f_permutation
      ref_f_permutation_ (clk, reset, padder_out, padder_out_ready, f_ack, f_out, f_out_ready);
endmodule

`undef low_pos
`undef low_pos2
`undef high_pos
`undef high_pos2



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

  ref_padder1 ref_p0 (
      .in(in),
      .byte_num(byte_num),
      .out(v0)
  );

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

module ref_f_permutation (
    clk,
    reset,
    in,
    in_ready,
    ack,
    out,
    out_ready
);
  input clk, reset;
  input [575:0] in;
  input in_ready;
  output ack;
  output reg [1599:0] out;
  output reg out_ready;

  reg [22:0] i;
  wire [1599:0] round_in, round_out;
  wire [63:0] rc;
  wire        update;
  wire        accept;
  reg         calc;

  assign accept = in_ready & (~calc);

  always @(posedge clk)
    if (reset) i <= 0;
    else i <= {i[21:0], accept};

  always @(posedge clk)
    if (reset) calc <= 0;
    else calc <= (calc & (~i[22])) | accept;

  assign update = calc | accept;

  assign ack = accept;

  always @(posedge clk)
    if (reset) out_ready <= 0;
    else if (accept) out_ready <= 0;
    else if (i[22]) out_ready <= 1;

  assign round_in = accept ? {in ^ out[1599:1599-575], out[1599-576:0]} : out;

  ref_rconst ref_rconst_ (
      {i, accept},
      rc
  );

  ref_round ref_round_ (
      round_in,
      rc,
      round_out
  );

  always @(posedge clk)
    if (reset) out <= 0;
    else if (update) out <= round_out;
endmodule

module ref_rconst (
    i,
    rc
);
  input [23:0] i;
  output reg [63:0] rc;

  always @(i) begin
    rc = 0;
    rc[0] = i[0] | i[4] | i[5] | i[6] | i[7] | i[10] | i[12] | i[13] | i[14] | i[15] | i[20] | i[22];
    rc[1] = i[1] | i[2] | i[4] | i[8] | i[11] | i[12] | i[13] | i[15] | i[16] | i[18] | i[19];
    rc[3] = i[2] | i[4] | i[7] | i[8] | i[9] | i[10] | i[11] | i[12] | i[13] | i[14] | i[18] | i[19] | i[23];
    rc[7] = i[1] | i[2] | i[4] | i[6] | i[8] | i[9] | i[12] | i[13] | i[14] | i[17] | i[20] | i[21];
    rc[15] = i[1] | i[2] | i[3] | i[4] | i[6] | i[7] | i[10] | i[12] | i[14] | i[15] | i[16] | i[18] | i[20] | i[21] | i[23];
    rc[31] = i[3] | i[5] | i[6] | i[10] | i[11] | i[12] | i[19] | i[20] | i[22] | i[23];
    rc[63] = i[2] | i[3] | i[6] | i[7] | i[13] | i[14] | i[15] | i[16] | i[17] | i[19] | i[20] | i[21] | i[23];
  end
endmodule

`define low_pos(x, y) `high_pos(x,y) - 63
`define high_pos(x, y) 1599 - 64*(5*y+x)
`define add_1(x) (x == 4 ? 0 : x + 1)
`define add_2(x) (x == 3 ? 0 : x == 4 ? 1 : x + 2)
`define sub_1(x) (x == 0 ? 4 : x - 1)
`define rot_up(in, n) {in[63-n:0], in[63:63-n+1]}
`define rot_up_1(in) {in[62:0], in[63]}

module ref_round (
    in,
    round_const,
    out
);
  input [1599:0] in;
  input [63:0] round_const;
  output [1599:0] out;

  wire [63:0] a[4:0] [4:0];
  wire [63:0] b[4:0];
  wire [63:0] c[4:0][4:0], d[4:0][4:0], e[4:0][4:0], f[4:0][4:0], g[4:0][4:0];

  genvar x, y;

  generate
    for (y = 0; y < 5; y = y + 1) begin : L0
      for (x = 0; x < 5; x = x + 1) begin : L1
        assign a[x][y] = in[`high_pos(x, y) : `low_pos(x, y)];
      end
    end
  endgenerate

  generate
    for (x = 0; x < 5; x = x + 1) begin : L2
      assign b[x] = a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4];
    end
  endgenerate

  generate
    for (y = 0; y < 5; y = y + 1) begin : L3
      for (x = 0; x < 5; x = x + 1) begin : L4
        assign c[x][y] = a[x][y] ^ b[`sub_1(x)] ^ `rot_up_1(b[`add_1(x)]);
      end
    end
  endgenerate

  assign d[0][0] = c[0][0];
  assign d[1][0] = `rot_up_1(c[1][0]);
  assign d[2][0] = `rot_up(c[2][0], 62);
  assign d[3][0] = `rot_up(c[3][0], 28);
  assign d[4][0] = `rot_up(c[4][0], 27);
  assign d[0][1] = `rot_up(c[0][1], 36);
  assign d[1][1] = `rot_up(c[1][1], 44);
  assign d[2][1] = `rot_up(c[2][1], 6);
  assign d[3][1] = `rot_up(c[3][1], 55);
  assign d[4][1] = `rot_up(c[4][1], 20);
  assign d[0][2] = `rot_up(c[0][2], 3);
  assign d[1][2] = `rot_up(c[1][2], 10);
  assign d[2][2] = `rot_up(c[2][2], 43);
  assign d[3][2] = `rot_up(c[3][2], 25);
  assign d[4][2] = `rot_up(c[4][2], 39);
  assign d[0][3] = `rot_up(c[0][3], 41);
  assign d[1][3] = `rot_up(c[1][3], 45);
  assign d[2][3] = `rot_up(c[2][3], 15);
  assign d[3][3] = `rot_up(c[3][3], 21);
  assign d[4][3] = `rot_up(c[4][3], 8);
  assign d[0][4] = `rot_up(c[0][4], 18);
  assign d[1][4] = `rot_up(c[1][4], 2);
  assign d[2][4] = `rot_up(c[2][4], 61);
  assign d[3][4] = `rot_up(c[3][4], 56);
  assign d[4][4] = `rot_up(c[4][4], 14);

  assign e[0][0] = d[0][0];
  assign e[0][2] = d[1][0];
  assign e[0][4] = d[2][0];
  assign e[0][1] = d[3][0];
  assign e[0][3] = d[4][0];
  assign e[1][3] = d[0][1];
  assign e[1][0] = d[1][1];
  assign e[1][2] = d[2][1];
  assign e[1][4] = d[3][1];
  assign e[1][1] = d[4][1];
  assign e[2][1] = d[0][2];
  assign e[2][3] = d[1][2];
  assign e[2][0] = d[2][2];
  assign e[2][2] = d[3][2];
  assign e[2][4] = d[4][2];
  assign e[3][4] = d[0][3];
  assign e[3][1] = d[1][3];
  assign e[3][3] = d[2][3];
  assign e[3][0] = d[3][3];
  assign e[3][2] = d[4][3];
  assign e[4][2] = d[0][4];
  assign e[4][4] = d[1][4];
  assign e[4][1] = d[2][4];
  assign e[4][3] = d[3][4];
  assign e[4][0] = d[4][4];

  generate
    for (y = 0; y < 5; y = y + 1) begin : L5
      for (x = 0; x < 5; x = x + 1) begin : L6
        assign f[x][y] = e[x][y] ^ ((~e[`add_1(x)][y]) & e[`add_2(x)][y]);
      end
    end
  endgenerate

  generate
    for (x = 0; x < 64; x = x + 1) begin : L60
      if (x == 0 || x == 1 || x == 3 || x == 7 || x == 15 || x == 31 || x == 63) begin : L20
        assign g[0][0][x] = f[0][0][x] ^ round_const[x];
      end else begin : L30
       assign g[0][0][x] = f[0][0][x];
      end
    end
  endgenerate

  generate
    for (y = 0; y < 5; y = y + 1) begin : L7
      for (x = 0; x < 5; x = x + 1) begin : L8
        if (x != 0 || y != 0) begin : L40
        assign g[x][y] = f[x][y];
        end
      end
    end
  endgenerate

  generate
    for (y = 0; y < 5; y = y + 1) begin : L99
      for (x = 0; x < 5; x = x + 1) begin : L100
        assign out[`high_pos(x, y) : `low_pos(x, y)] = g[x][y];
      end
    end
  endgenerate
endmodule

`undef low_pos
`undef high_pos
`undef add_1
`undef add_2
`undef sub_1
`undef rot_up
`undef rot_up_1

module ref_padder1 (
    in,
    byte_num,
    out
);
  input [31:0] in;
  input [1:0] byte_num;
  output reg [31:0] out;

  always @(*)
    case (byte_num)
      0: out = 32'h1000000;
      1: out = {in[31:24], 24'h010000};
      2: out = {in[31:16], 16'h0100};
      3: out = {in[31:8], 8'h01};
    endcase
endmodule
