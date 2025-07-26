`timescale 1ns / 1ps

module testbench;

    // === DUT Inputs ===
    reg clock;
    reg reset;
    reg req_0, req_1, req_2, req_3;

    // === DUT Outputs ===
    wire gnt_0, gnt_1, gnt_2, gnt_3;

    // === Reference Model Outputs ===
    wire ref_gnt_0, ref_gnt_1, ref_gnt_2, ref_gnt_3;

    // === Test Control Variables ===
    integer test_case;
    integer pass_count;
    integer fail_count;
    integer cycle_count;
    integer log_file;

    // === Instantiate DUT ===
    fsm_full uut (
        .clock(clock),
        .reset(reset),
        .req_0(req_0),
        .req_1(req_1),
        .req_2(req_2),
        .req_3(req_3),
        .gnt_0(gnt_0),
        .gnt_1(gnt_1),
        .gnt_2(gnt_2),
        .gnt_3(gnt_3)
    );

    // === Instantiate Reference FSM ===
    ref_fsm_full ref_model (
        .clock(clock),
        .reset(reset),
        .req_0(req_0),
        .req_1(req_1),
        .req_2(req_2),
        .req_3(req_3),
        .gnt_0(ref_gnt_0),
        .gnt_1(ref_gnt_1),
        .gnt_2(ref_gnt_2),
        .gnt_3(ref_gnt_3)
    );

    // === Dump Waveform ===
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
        log_file = $fopen("test.txt", "w");
    end

    // === Clock Generation ===
    always #5 clock = ~clock;

    // === Apply a Single Test Vector ===
    task apply_test(input r, input r0, r1, r2, r3);
    begin
        reset = r;
        req_0 = r0;
        req_1 = r1;
        req_2 = r2;
        req_3 = r3;
        @(posedge clock);
        cycle_count = cycle_count + 1;
    end
    endtask

    // === Compare DUT and Reference Outputs ===
    task check_results;
    begin
        if ({gnt_0, gnt_1, gnt_2, gnt_3} !== {ref_gnt_0, ref_gnt_1, ref_gnt_2, ref_gnt_3}) begin
            $display("FAIL: Test case %0d, Cycle %0d", test_case, cycle_count);
            $display("  Input: reset=%b, req=[%b,%b,%b,%b]",
                     reset, req_0, req_1, req_2, req_3);
            $display("  Expected: gnt=[%b,%b,%b,%b]",
                     ref_gnt_0, ref_gnt_1, ref_gnt_2, ref_gnt_3);
            $display("  Actual:   gnt=[%b,%b,%b,%b]",
                     gnt_0, gnt_1, gnt_2, gnt_3);
            $fwrite(log_file, "FAIL: Test case %0d, Cycle %0d\n", test_case, cycle_count);
            $fwrite(log_file, "  Input: reset=%b, req=[%b,%b,%b,%b]\n",
                    reset, req_0, req_1, req_2, req_3);
            $fwrite(log_file, "  Expected: gnt=[%b,%b,%b,%b]\n",
                    ref_gnt_0, ref_gnt_1, ref_gnt_2, ref_gnt_3);
            $fwrite(log_file, "  Actual:   gnt=[%b,%b,%b,%b]\n\n",
                    gnt_0, gnt_1, gnt_2, gnt_3);
            fail_count = fail_count + 1;
        end else begin
            pass_count = pass_count + 1;
        end
    end
    endtask

    task verify_results;
    begin
        check_results;
    end
    endtask

    // === Directed Test: Sequential Requests ===
    task test_sequential_requests;
    integer i;
    begin
        $display("== Test 1: Sequential Requests ==");
        test_case = 1;

        apply_test(1, 0, 0, 0, 0);  // Reset
        verify_results;
        for (i = 0; i < 4; i = i + 1) begin
            apply_test(1, 0, 0, 0, 0);
            verify_results;
        end

        apply_test(0, 0, 0, 0, 0);  // Release reset
        for (i = 0; i < 4; i = i + 1) begin
            apply_test(0, 0, 0, 0, 0);
            verify_results;
        end

        // req_0
        for (i = 0; i < 10; i = i + 1) begin
          apply_test(0, 1, 0, 0, 0);
          verify_results;
        end
        for (i = 0; i < 5; i = i + 1) begin
          apply_test(0, 0, 0, 0, 0);
          verify_results;
        end
        for (i = 0; i < 10; i = i + 1) begin
          apply_test(0, 1, 0, 0, 0);
          verify_results;
        end
        for (i = 0; i < 5; i = i + 1) begin
          apply_test(0, 0, 0, 0, 0);
          verify_results;
        end
        for (i = 0; i < 10; i = i + 1)begin
            apply_test(0, 1, 0, 0, 0);
            verify_results;
        end
        for (i = 0; i < 5; i = i + 1)begin
            apply_test(0, 0, 0, 0, 0);
            verify_results;
        end

        // req_1
        for (i = 0; i < 10; i = i + 1)begin
            apply_test(0, 0, 1, 0, 0);
            verify_results;
        end
        for (i = 0; i < 5; i = i + 1)begin
            apply_test(0, 0, 0, 0, 0);
            verify_results;
        end

        // req_2
        for (i = 0; i < 10; i = i + 1)begin
            apply_test(0, 0, 0, 1, 0);
            verify_results;
        end
        for (i = 0; i < 5; i = i + 1)begin
            apply_test(0, 0, 0, 0, 0);
            verify_results;
        end
        // req_3
        for (i = 0; i < 10; i = i + 1)begin
            apply_test(0, 0, 0, 0, 1);
            verify_results;
        end
        for (i = 0; i < 5; i = i + 1)begin
            apply_test(0, 0, 0, 0, 0);
            verify_results;
        end
    end
    endtask

    // === Directed Test: Concurrent Requests ===
    task test_concurrent_requests;
    integer i;
    begin
        $display("== Test 2: Concurrent Requests ==");
        test_case = 2;

        apply_test(1, 0, 0, 0, 0);  // Reset
        verify_results;
        apply_test(0, 0, 0, 0, 0);  // Release reset
        verify_results;

        // req_0 and req_1
        for (i = 0; i < 20; i = i + 1)begin
            apply_test(0, 1, 1, 0, 0);
            verify_results;
        end
        // all high
        for (i = 0; i < 20; i = i + 1)begin
            apply_test(0, 1, 1, 1, 1);
            verify_results;
        end
    end
    endtask

    // === Directed Test: Priority Test ===
    task test_priority_behavior;
    integer i;
    begin
        $display("== Test 3: Priority Behavior ==");
        test_case = 3;

        apply_test(1, 0, 0, 0, 0);  // Reset
        verify_results;
        apply_test(0, 0, 0, 0, 0);  // Release reset
        verify_results;

        for (i = 0; i < 50; i = i + 1)begin
            apply_test(0, 1, 1, 1, 1);
            verify_results;
        end
    end
    endtask

    // === Randomized Test ===
    task test_random_requests;
    integer i;
    reg [3:0] rand_req;
    begin
        $display("== Test 4: Randomized Requests ==");
        test_case = 4;

        for (i = 0; i < 100; i = i + 1) begin
            rand_req = $random;
            apply_test(0, rand_req[0], rand_req[1], rand_req[2], rand_req[3]);
            verify_results;
        end

        // Reset randomly during random test
        for (i = 0; i < 20; i = i + 1) begin
            rand_req = $random;
            apply_test($random % 2, rand_req[0], rand_req[1], rand_req[2], rand_req[3]);
            verify_results;
        end
    end
    endtask

    // === Main Test Sequence ===
    initial begin
        // Init
        clock = 0;
        reset = 1;
        req_0 = 0; req_1 = 0; req_2 = 0; req_3 = 0;
        test_case = 0; pass_count = 0; fail_count = 0; cycle_count = 0;

        #1;
        test_sequential_requests;
        test_concurrent_requests;
        test_priority_behavior;
        test_random_requests;

        // Summary
        $display("\n=== Summary ===");
        $display("Total: %0d, Passed: %0d, Failed: %0d", pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("All tests passed!");
        else
            $display("Some tests failed!");

        $fclose(log_file);
        $finish;
    end

endmodule

module ref_fsm_full(
clock , // Clock
reset , // Active high reset
req_0 , // Active high request from agent 0
req_1 , // Active high request from agent 1
req_2 , // Active high request from agent 2
req_3 , // Active high request from agent 3
gnt_0 , // Active high grant to agent 0
gnt_1 , // Active high grant to agent 1
gnt_2 , // Active high grant to agent 2
gnt_3   // Active high grant to agent 3
);
// Port declaration here
input clock ; // Clock
input reset ; // Active high reset
input req_0 ; // Active high request from agent 0
input req_1 ; // Active high request from agent 1
input req_2 ; // Active high request from agent 2
input req_3 ; // Active high request from agent 3
output gnt_0 ; // Active high grant to agent 0
output gnt_1 ; // Active high grant to agent 1
output gnt_2 ; // Active high grant to agent 2
output gnt_3 ; // Active high grant to agent 

// Internal Variables
reg    gnt_0 ; // Active high grant to agent 0
reg    gnt_1 ; // Active high grant to agent 1
reg    gnt_2 ; // Active high grant to agent 2
reg    gnt_3 ; // Active high grant to agent 

parameter  [2:0]  IDLE  = 3'b000;
parameter  [2:0]  GNT0  = 3'b001;
parameter  [2:0]  GNT1  = 3'b010;
parameter  [2:0]  GNT2  = 3'b011;
parameter  [2:0]  GNT3  = 3'b100;

reg [2:0] state, next_state;

always @ (state or req_0 or req_1 or req_2 or req_3)
begin  
  next_state = 0;
  case(state)
    IDLE : if (req_0 == 1'b1) begin
  	     next_state = GNT0;
           end else if (req_1 == 1'b1) begin
  	     next_state= GNT1;
           end else if (req_2 == 1'b1) begin
  	     next_state= GNT2;
           end else if (req_3 == 1'b1) begin
  	     next_state= GNT3;
	   end else begin
  	     next_state = IDLE;
           end			
    GNT0 : if (req_0 == 1'b0) begin
  	     next_state = IDLE;
           end else begin
	     next_state = GNT0;
	  end
    GNT1 : if (req_1 == 1'b0) begin
  	     next_state = IDLE;
           end else begin
	     next_state = GNT1;
	  end
    GNT2 : if (req_2 == 1'b0) begin
  	     next_state = IDLE;
           end else begin
	     next_state = GNT2;
	  end
    GNT3 : if (req_3 == 1'b0) begin
  	     next_state = IDLE;
           end else begin
	     next_state = GNT3;
	  end
   default : next_state = IDLE;
  endcase
end

always @ (posedge clock)
begin : OUTPUT_LOGIC
  if (reset) begin
    gnt_0 <= 1'b0;
    gnt_1 <= 1'b0;
    gnt_2 <= 1'b0;
    gnt_3 <= 1'b0;
    state <= IDLE;
  end else begin
    state <= next_state;
    case(state)
	IDLE : begin
                gnt_0 <= 1'b0;
                gnt_1 <= 1'b0;
                gnt_2 <= 1'b0;
                gnt_3 <= 1'b0;
	       end
  	GNT0 : begin
  	         gnt_0 <= 1'b1;
  	       end
        GNT1 : begin
                 gnt_1 <= 1'b1;
               end
        GNT2 : begin
                 gnt_2 <= 1'b1;
               end
        GNT3 : begin
                 gnt_3 <= 1'b1;
               end
     default : begin
                 state <= IDLE;
               end
    endcase
  end
end

endmodule
