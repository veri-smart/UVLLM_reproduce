`timescale 1ns/1ns

module tff_tb;

  reg clk, rstn, t;
  wire q;
  wire q_ref;
  
  // Instantiate DUT
  tff uut (
    .clk(clk),
    .rstn(rstn),
    .t(t),
    .q(q)
  );

  // Instantiate Reference Model
  ref_tff ref_model (
    .clk(clk),
    .rstn(rstn),
    .t(t),
    .q(q_ref)
  );

  integer log_file;
  integer error_count = 0;

  initial begin
    $dumpfile("test.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    log_file = $fopen("test.txt", "w");
  end

  // Generate clock
  always #5 clk = ~clk;

  // Test sequence
  initial begin
    // Initialize signals
    clk = 0;
    rstn = 0;
    t = 0;

    // Wait for global reset to finish
    #20 rstn = 1;

    // Add stimulus here
    for (integer i = 0; i < 20; i = i + 1) begin
        reg [4:0] dly = $random;
        #(dly) t <= $random;
        @(posedge clk);
        check_results("Test Case " + i);
    end

    $finish;
  end

  // Check results and log any mismatches
  task check_results(input [80*8:1] test_name);
    begin
      if (q !== q_ref) begin
        error_count = error_count + 1;
        $fwrite(log_file, "Error Time: %0t ns\n", $time);
        $fwrite(log_file, "DUT Input: clk = %d, rstn = %d, t = %d\n", clk, rstn, t);
        $fwrite(log_file, "DUT Output: q = %b\n", q);
        $fwrite(log_file, "Reference Input: clk = %d, rstn = %d, t = %d\n", clk, rstn, t);
        $fwrite(log_file, "Reference Output: q = %b\n", q_ref);
        $fwrite(log_file, "------------------------------------\n");
      end
    end
  endtask

  // Display final result
  task verify_results;
    begin
      if (error_count == 0) begin
        $display("=========== Your Design Passed ===========");
        $fwrite(log_file, "=========== Your Design Passed ===========\n");
      end else begin
        $display("=========== Your Design Failed  ===========");
        $fwrite(log_file, "=========== Your Design Failed ===========\n");
      end
    end
  endtask

endmodule

// Reference model definition (same as DUT for simulation comparison)
module ref_tff (   input clk,
              input rstn,
              input t,
            output reg q);
 
  always @ (posedge clk) begin
    if (!rstn) 
      q <= 0;
    else
      if (t)
          q <= ~q;
      else
          q <= q;
  end
endmodule