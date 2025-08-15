`timescale 1ns/1ps

module tff_tb();

    reg clk;
    reg rstn;
    reg t;

    wire q;

    reg ref_q; // 参考模型
    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the T-Flip-Flop module under test
    tff uut (
        .clk(clk),
        .rstn(rstn),
        .t(t),
        .q(q)
    );

    // Clock generation: 10ns周期
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    // VCD dump
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Reference model update at posedge clk
    always @(posedge clk) begin
        if (!rstn)
            ref_q <= 0;
        else if (t)
            ref_q <= ~ref_q;
        else
            ref_q <= ref_q;
    end

    // Test sequence
    initial begin
        // Initialization
        rstn = 0;
        t = 0;
        ref_q = 0;
        #12; // 上升沿，模拟 tick 一次

        // rand.vcd 样例
        rstn = 0; t = $random & 1; #10; check_results();
        rstn = 1; t = $random & 1; #10; check_results();
        rstn = 0; t = $random & 1; #10; check_results();
        repeat (20) begin
            int j, x;
            x = $urandom_range(0, 15);
            for (j = 0; j < x; j = j + 1) begin
                #10; check_results();
            end
            t = $random & 1;
        end
        #10; check_results();

        // reset.vcd 样例
        rstn = 0; t = $random & 1; #10; check_results();
        rstn = 1; t = $random & 1; #10; check_results();
        rstn = 0; t = $random & 1; #10; check_results();
        for (i = 0; i < 20; i = i + 1) begin
            int j, x;
            x = $urandom_range(0, 15);
            for (j = 0; j < x; j = j + 1)
                #10; // tick
            rstn = ($urandom_range(0,9) == 0) ? 1 : 0;
            t = $random & 1;
            #10; check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Result checking task
    task check_results;
        begin
            if (q !== ref_q) begin
                error = error + 1;
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "Inputs: rstn = %b, t = %b\n", rstn, t);
                $fwrite(log_file, "DUT Output: q = %b\n", q);
                $fwrite(log_file, "Reference Output: q = %b\n", ref_q);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Final result reporting
    initial begin
        #2000; // maximum sim time
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file,"=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
