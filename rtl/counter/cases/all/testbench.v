`timescale 1ns/1ps

module testbench();

    reg clk;
    reg reset;
    reg enable;

    wire [3:0] counter_out;
    wire overflow_out;

    reg [3:0] ref_counter;
    reg ref_overflow;

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the DUT
    first_counter uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .counter_out(counter_out),
        .overflow_out(overflow_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #2 clk = ~clk; // 10ns period
    end

    // Dump VCD
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, testbench);
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Reference model
    task ref_model;
        input reset_i;
        input enable_i;
        if(reset_i==1'b1) begin
            ref_counter = 4'b0000;
            ref_overflow = 1'b0;
        end
        else if(enable_i == 1'b1) begin
            ref_counter = ref_counter + 1;
        end
        if(ref_counter == 4'b1111)
        begin
            ref_overflow = 1'b1;
        end
    endtask

    // Result checking
    task check_results;
        begin
            if (counter_out !== ref_counter || overflow_out !== ref_overflow) begin
                error = error + 1;
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: reset = %b, enable = %b\n", reset, enable);
                $fwrite(log_file, "DUT Output: counter_out = 4'b%0b, overflow_out = %b\n", counter_out, overflow_out);
                $fwrite(log_file, "Reference Output: counter_out = 4'b%0b, overflow_out = %b\n", ref_counter, ref_overflow);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Main stimulus block
    initial begin
        reset = 0;
        enable = 0;
        ref_counter = 0;
        ref_overflow = 0;

        // ----------- No Overflow -----------
        $display("[Test] No Overflow");
        #2; reset = 1;
        #10; reset = 0;

        repeat(15) begin
            @(posedge clk);
            enable = 1;
            reset = 0;
            ref_model(reset, enable);
            check_results();
        end

        // ----------- Overflow -----------
        $display("[Test] Overflow");
        reset = 1;
        @(posedge clk); ref_model(reset, enable); check_results();
        reset = 0;

        repeat(30) begin
            @(posedge clk);
            enable = 1;
            ref_model(reset, enable);
            check_results();
        end

        // ----------- Reset In Middle -----------
        $display("[Test] Reset in Middle");
        reset = 1;
        @(posedge clk); ref_model(reset, enable); check_results();
        reset = 0;
        enable = 1;

        repeat(15) begin
            @(posedge clk);
            ref_model(reset, enable);
            check_results();
        end

        reset = 1;
        @(posedge clk);
        ref_model(reset, enable);
        check_results();

        reset = 0;

        repeat(15) begin
            @(posedge clk);
            ref_model(reset, enable);
            check_results();
        end

        // ----------- Random Pattern -----------
        $display("[Test] Random Input");
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            reset = $random & 1;
            enable = ($random & 15 == 0);
            ref_model(reset, enable);
            check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Final result
    initial begin
        #3000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
