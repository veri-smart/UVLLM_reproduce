`timescale 1ns/1ns

module tb_decoder_3to8;

  reg A, B, C, en;
  wire Y7, Y6, Y5, Y4, Y3, Y2, Y1, Y0;
  wire Y7_ref, Y6_ref, Y5_ref, Y4_ref, Y3_ref, Y2_ref, Y1_ref, Y0_ref;
  
  // Instantiate DUT
  decoder_3to8 uut (
    .Y7(Y7), .Y6(Y6), .Y5(Y5), .Y4(Y4),
    .Y3(Y3), .Y2(Y2), .Y1(Y1), .Y0(Y0),
    .A(A), .B(B), .C(C), .en(en)
  );

  // Instantiate Reference Model
  ref_decoder_3to8 ref_model (
    .Y7(Y7_ref), .Y6(Y6_ref), .Y5(Y5_ref), .Y4(Y4_ref),
    .Y3(Y3_ref), .Y2(Y2_ref), .Y1(Y1_ref), .Y0(Y0_ref),
    .A(A), .B(B), .C(C), .en(en)
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

  // Test sequence
  initial begin
    A = 0;
    B = 0;
    C = 0;
    en = 0;

    #20;

    // Directed Tests: Known patterns
    $display("Directed Tests: Known patterns");

    // Testcase1: Disable test - all outputs should be high
    apply_test(0, 0, 0, 0, "Disable Test - Expect all Y=1");

    // Testcase2: Enable with all input combinations
    $display("Testing all input combinations with enable=1");
    apply_test(0, 0, 0, 1, "Input 000 - Expect Y0=0, others=1");
    apply_test(0, 0, 1, 1, "Input 001 - Expect Y1=0, others=1");
    apply_test(0, 1, 0, 1, "Input 010 - Expect Y2=0, others=1");
    apply_test(0, 1, 1, 1, "Input 011 - Expect Y3=0, others=1");
    apply_test(1, 0, 0, 1, "Input 100 - Expect Y4=0, others=1");
    apply_test(1, 0, 1, 1, "Input 101 - Expect Y5=0, others=1");
    apply_test(1, 1, 0, 1, "Input 110 - Expect Y6=0, others=1");
    apply_test(1, 1, 1, 1, "Input 111 - Expect Y7=0, others=1");

    // Boundary Tests: Test enable/disable transitions
    $display("Boundary Tests: Enable/Disable transitions");
    apply_test(1, 0, 1, 0, "Boundary Test - Input 101 with en=0");
    apply_test(1, 0, 1, 1, "Boundary Test - Input 101 with en=1");

    // Random Tests: Random sequences
    // $display("Random Tests: Random input patterns");
    // repeat(10) begin
    //   apply_test($random % 2, $random % 2, $random % 2, $random % 2, "Random Test");
    // end

    // Final Verification
    // verify_results();
    $finish;
  end

  // Apply a test vector
  task apply_test(input A_val, input B_val, input C_val, input en_val, input [80*8:1] test_name);
    begin
      A = A_val;
      B = B_val;
      C = C_val;
      en = en_val;
      #10;
      check_results(test_name);
    end
  endtask

  // Check results and log any mismatches
  task check_results(input [80*8:1] test_name);
    begin
      if (Y7 !== Y7_ref || Y6 !== Y6_ref || Y5 !== Y5_ref || Y4 !== Y4_ref ||
          Y3 !== Y3_ref || Y2 !== Y2_ref || Y1 !== Y1_ref || Y0 !== Y0_ref) begin
        error_count = error_count + 1;
        $fwrite(log_file, "Error Time: %0t ns\n", $time);
        $fwrite(log_file, "DUT Input: A = %d, B = %d, C = %d, en = %d\n", A, B, C, en);
        $fwrite(log_file, "DUT Output: Y7=%b, Y6=%b, Y5=%b, Y4=%b, Y3=%b, Y2=%b, Y1=%b, Y0=%b\n", 
                Y7, Y6, Y5, Y4, Y3, Y2, Y1, Y0);
        $fwrite(log_file, "Reference Input: A = %d, B = %d, C = %d, en = %d\n", A, B, C, en);
        $fwrite(log_file, "Reference Output: Y7=%b, Y6=%b, Y5=%b, Y4=%b, Y3=%b, Y2=%b, Y1=%b, Y0=%b\n", 
                Y7_ref, Y6_ref, Y5_ref, Y4_ref, Y3_ref, Y2_ref, Y1_ref, Y0_ref);
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
module ref_decoder_3to8 (
  output Y7, Y6, Y5, Y4, Y3, Y2, Y1, Y0,
  input A, B, C, en
);
  assign {Y7,Y6,Y5,Y4,Y3,Y2,Y1,Y0} = ( {en,A,B,C} == 4'b1000) ? 8'b1111_1110 :
                                     ( {en,A,B,C} == 4'b1001) ? 8'b1111_1101 :
                                     ( {en,A,B,C} == 4'b1010) ? 8'b1111_1011 :
                                     ( {en,A,B,C} == 4'b1011) ? 8'b1111_0111 :
                                     ( {en,A,B,C} == 4'b1100) ? 8'b1110_1111 :
                                     ( {en,A,B,C} == 4'b1101) ? 8'b1101_1111 :
                                     ( {en,A,B,C} == 4'b1110) ? 8'b1011_1111 :
                                     ( {en,A,B,C} == 4'b1111) ? 8'b0111_1111 :
                                                                8'b1111_1111;
endmodule
