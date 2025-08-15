`timescale 1ns/1ps

module testbench();

    // Inputs
    reg clock;
    reg reset;
    reg req_0;
    reg req_1;
    reg req_2;
    reg req_3;

    // Outputs
    wire gnt_0;
    wire gnt_1;
    wire gnt_2;
    wire gnt_3;

    // Reference model signals
    reg [3:0] req;
    wire [3:0] ref_gnt;

    assign req = {req_3, req_2, req_1, req_0};

    // Priority encoder reference model
    assign ref_gnt = (req_0) ? 4'b0001 :
                     (req_1) ? 4'b0010 :
                     (req_2) ? 4'b0100 :
                     (req_3) ? 4'b1000 :
                               4'b0000;

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the FSM module
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

    // Clock generation
    initial begin
        clock = 0;
        forever #2 clock = ~clock;
    end

    // Dump waveform
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Open log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Stimulus
    initial begin
        reset = 1;
        req_0 = 0; req_1 = 0; req_2 = 0; req_3 = 0;
        #20;
        reset = 0;

        // keep_req
        reset = 0;
        req_0 = 0; req_1 = 0; req_2 = 0; req_3 = 0;
        #10;
        reset = 1;
        #10;
        reset = 0;
        #10;

        repeat (5) begin
            req_0 = 1;
            #20;
            req_0 = 0;
            #10;
        end

        // rand_req
        for (i = 0; i < 1000; i = i + 1) begin
            {req_3, req_2, req_1, req_0} = $random;
            if ($urandom % 100 < 10) begin
                reset = 1;
                #10;
                reset = 0;
            end
            #20;
        end

        // seq_req
        reset = 0;
        req_0 = 0; req_1 = 0; req_2 = 0; req_3 = 0;
        #20;
        reset = 1;
        #20;
        reset = 0;
        #20;

        req_0 = 1; #20; req_0 = 0; #10;
        req_1 = 1; #20; req_1 = 0; #10;
        req_2 = 1; #20; req_2 = 0; #10;
        req_3 = 1; #20; req_3 = 0; #10;

        $fclose(log_file);
        $finish;
    end

    // Helper task to apply request and check results
    task apply_request(input [3:0] request);
        begin
            {req_3, req_2, req_1, req_0} = request;
            #20; // Wait some cycles for FSM response

            check_results();
        end
    endtask

    task check_results;
        reg [3:0] dut_gnt;
        begin
            dut_gnt = {gnt_3, gnt_2, gnt_1, gnt_0};
            if (dut_gnt !== ref_gnt) begin
                error = error + 1;
                $fwrite(log_file, "Error at time %g ns\n", $time);
                $fwrite(log_file, "Request: req = 4'b%b\n", req);
                $fwrite(log_file, "DUT grant:     gnt = 4'b%b\n", dut_gnt);
                $fwrite(log_file, "Expected grant:gnt = 4'b%b\n", ref_gnt);
                $fwrite(log_file, "------------------------------\n");
            end
        end
    endtask

    // Display test result
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
