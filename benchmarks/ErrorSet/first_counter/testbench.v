`timescale 1ns/1ns

module first_counter_tb();

    reg clk;
    reg reset;
    reg enable;
    wire [3:0] counter_out;
    wire overflow_out;

    // Reference model outputs
    reg [3:0] counter_out_ref;
    reg overflow_out_ref;

    integer i;
    integer log_file;

    // Instantiate DUT
    first_counter uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .counter_out(counter_out),
        .overflow_out(overflow_out)
    );

    // Reference Model
    ref_first_counter ref_model (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .counter_out(counter_out_ref),
        .overflow_out(overflow_out_ref)
    );
    integer error_count = 0;

    initial begin
        $display("Starting simulation...");
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
        $display("Dumpfile initialized.");
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        enable = 0;

        // Apply reset to the design
        repeat (2) @ (posedge clk);
        reset = 1;
        repeat (5) @ (posedge clk);

        // Apply test vectors using apply_test
        apply_test(1'b1, 1'b0, "Reset Test");
        apply_test(1'b0, 1'b0, "Hold Test");
        apply_test(1'b0, 1'b1, "Enable Test");

        // Let design run for 100 clocks and check results at each clock
        repeat (50) begin
          @(posedge clk);
          check_results("Periodic Check");
        end

        verify_results;
        $finish;
      end

    // Apply test and check results
    task apply_test(input rst, input en, input [80*8:1] test_name);
        begin
            reset = rst;
            enable = en;
            #10; // Wait for clock edge
            check_results(test_name);
        end
    endtask

    // Check results against reference model
    task check_results(input [80*8:1] test_name);
        begin
            if(counter_out != counter_out_ref || overflow_out != overflow_out_ref)begin
                error_count = error_count + 1;
                $fwrite(log_file, "Error Time: %0t ns\n", $time);
                $fwrite(log_file, "DUT Input: clk = %d, reset = %d, enable = %d\n", clk, reset, enable);
                $fwrite(log_file, "DUT Output: counter_out = %h, overflow_out = %b\n", counter_out, overflow_out);
                $fwrite(log_file, "Reference Output: counter_out = %h, overflow_out = %b\n", counter_out_ref, overflow_out_ref);
                $fwrite(log_file, "------------------------------------\n");
            end
        end
    endtask

    // Final verification
    task verify_results;
        begin
            if (error_count == 0) begin
                $display("=========== Your Design Passed ===========");
                $fwrite(log_file, "=========== Your Design Passed ===========\n");
            end else begin
                $display("=========== Your Design Failed  ===========");
                $fwrite(log_file, "=========== Your Design Failed  ===========\n");
            end
        end

    endtask

endmodule

// Reference Model
//-----------------------------------------
//Design name: first_counter
//File Name: first_counter.v
//Function: This is a 4-bit up-counter with
//Synchronous active high reset and 
//with active high enable signal
//------------------------------------------
module ref_first_counter(
    clk,
    reset,
    enable,
    counter_out,
    overflow_out
);
input clk;
input reset;
input enable;
output[3:0] counter_out;
output overflow_out;
wire clk;
wire reset;
wire enable;
reg[3:0] counter_out;
reg overflow_out;

always@(posedge clk)
begin: COUNTER 
    if(reset==1'b1) begin
        counter_out <= 4'b0000;
        overflow_out <= 1'b0;
    end
    else if(enable == 1'b1) begin
        counter_out <=  counter_out + 1;

    end
    if(counter_out == 4'b1111)
    begin
        overflow_out <= 1'b1;
    end
end 

endmodule


