`timescale 1ns/1ps

module testbench;

    reg clk;
    reg rstn;
    reg [7:0] load_val;
    reg load_en;

    wire [7:0] op;

    reg [7:0] ref_op;
    integer i;
    integer cycle;
    integer error = 0;
    integer log_file;`

    // Instantiate the module under test
    lshift_reg uut (
        .clk(clk),
        .rstn(rstn),
        .load_val(load_val),
        .load_en(load_en),
        .op(op)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Dump waveform
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Stimulus
    initial begin
        //load_stop
        rstn = 0;
        load_val = 8'd123;
        load_en = 0;
        ref_op = 8'd0;

        #20;
        rstn = 1;
        #50;

        load_en = 1;
        ref_op = load_val;
        #10;

        load_en = 0;
        #10; #10; #10;

        load_en = 1;
        ref_op = load_val;
        #10;

        load_en = 0;
        #10;

        load_en = 1;
        ref_op = load_val;
        #100;

        load_en = 0;
        for (i = 0; i < 20; i = i + 1) begin
            #10;
            ref_op = {ref_op[6:0], ref_op[7]};
            check_results();
        end
        #200

        //rand
        rstn = 0;
        load_val = 8'd0;
        load_en = 0;
        ref_op = 8'd0;

        #10;
        rstn = 1;
        #10;

        for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
            #10;
            rstn = ($random % 100) == 0;
            load_en = $random % 10 == 0;
            load_val = $random & 255;

            if (load_en)
                ref_op = load_val;
            else
                ref_op = {ref_op[6:0], ref_op[7]};
            check_results();
        end
        #200


        //simple
        rstn = 0;
        load_val = 8'd1;
        load_en = 0;
        ref_op = 8'd0;

        #20;

        rstn = 1;
        #50;

        load_en = 1;
        ref_op = load_val;
        #10;

        load_en = 0;
        for (i = 0; i < 20; i = i + 1) begin
            #10;
            ref_op = {ref_op[6:0], ref_op[7]};
            check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Result checker
    task check_results;
        begin
            if (op !== ref_op) begin
                error = error + 1;
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "Inputs: rstn = %b, load_en = %b, load_val = 8'b%0b\n", rstn, load_en, load_val);
                $fwrite(log_file, "DUT Output: op = 8'b%0b\n", op);
                $fwrite(log_file, "Ref Output: op = 8'b%0b\n", ref_op);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Final report
    initial begin
        #3000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
