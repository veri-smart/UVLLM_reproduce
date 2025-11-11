`timescale 1ns/1ps

module testbench();

    reg A, B, C;
    reg en;

    wire Y0, Y1, Y2, Y3, Y4, Y5, Y6, Y7;
    wire [7:0] Y;
    reg [7:0] ref_Y;

    assign Y = {Y7, Y6, Y5, Y4, Y3, Y2, Y1, Y0};

    integer i;
    integer error = 0;
    integer log_file;

    decoder_3to8 uut (
        .A(A), .B(B), .C(C), .en(en),
        .Y0(Y0), .Y1(Y1), .Y2(Y2), .Y3(Y3),
        .Y4(Y4), .Y5(Y5), .Y6(Y6), .Y7(Y7)
    );

    function [7:0] decoder_ref;
        input A, B, C, en;
        reg [2:0] sel;
        begin
            if (!en) decoder_ref = 8'b1111_1111;
            else begin
                sel = {A, B, C};
                decoder_ref = ~(8'b0000_0001 << sel);
            end
        end
    endfunction

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, testbench);
        log_file = $fopen("test.txt", "w");

        // --- Stimulus Set 1 (tb1.cpp) ---
        apply_and_check(0, 0, 0, 0);
        apply_and_check(0, 0, 1, 1);
        apply_and_check(0, 1, 0, 1);
        apply_and_check(0, 1, 1, 1);
        apply_and_check(1, 0, 0, 1);
        apply_and_check(1, 0, 1, 1);
        apply_and_check(1, 1, 0, 1);
        apply_and_check(1, 1, 1, 1);
        apply_and_check(1, 0, 0, 0);
        apply_and_check(1, 1, 0, 0);

        // --- Stimulus Set 2 (tb3.cpp) ---
        apply_and_check(0, 1, 0, 1);
        apply_and_check(1, 0, 0, 1);
        apply_and_check(0, 0, 0, 0);
        apply_and_check(1, 1, 1, 1);
        apply_and_check(0, 0, 0, 1);

        // --- Stimulus Set 3 (tb2.cpp) ---
        for (i = 0; i < 1000; i = i + 1) begin
            A = $random % 2;
            B = $random % 2;
            C = $random % 2;
            en = $random % 2;
            #5;
            check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Apply inputs and check
    task apply_and_check;
        input a, b, c, enable;
        begin
            A = a; B = b; C = c; en = enable;
            #5;
            check_results();
        end
    endtask

    task check_results;
        begin
            #1;
            ref_Y = decoder_ref(A, B, C, en);
            if (Y !== ref_Y) begin
                error = error + 1;
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "DUT Input: en = %b, A = %b, B = %b, C = %b\n", en, A, B, C);
                $fwrite(log_file, "DUT Output: Y = 8'b%0b\n", Y);
                $fwrite(log_file, "Reference Output: Y = 8'b%0b\n", ref_Y);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Summary
    initial begin
        #1000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed (%0d errors) ===========", error);
        end
        $finish;
    end

endmodule
