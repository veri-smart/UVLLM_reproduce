`timescale 1ns/1ps

module xxxxx_tb();

    reg clk;
    reg rst;
    reg a;
    reg [3:0] b;
    reg [7:0] c;
    reg [9:0] d;

    wire e;
    wire [15:0] f;
    wire [3:0] g;
    wire h;

    // Reference model outputs
    wire ref_e;
    reg [15:0] ref_f;
    reg [3:0] ref_g;
    reg ref_h;

    // Internal state for checking
    reg [15:0] f_prev;
    reg [3:0] g_prev;
    reg h_prev;

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate DUT
    xxxxx uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .g(g),
        .h(h)
    );

    // Reference model for output `e`
    assign ref_e = a + b[0] * c[2] ^ d[7];

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Dump waveform
    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Stimulus generation
    initial begin
        //one_a
        for (i = 0; i < 100; i = i + 1) begin
            a = 1'b1;
            b = $random % 16;
            c = $random % 256;
            d = $random % 1024;
            @(posedge clk); #1;
            check_results();
        end

        //zero_a
        for (i = 0; i < 100; i = i + 1) begin
            a = 1'b0;
            b = $random % 16;
            c = $random % 256;
            d = $random % 1024;
            @(posedge clk); #1;
            check_results();
        end

        //rand
        for (i = 0; i < 100; i = i + 1) begin
            a = $random % 2;
            b = $random % 16;
            c = $random % 256;
            d = $random % 1024;
            @(posedge clk); #1;
            check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Reference model: simulate synchronous behavior
    always @(posedge clk) begin
        if (rst) begin
            ref_f <= 0;
            ref_g <= 0;
            ref_h <= 0;
        end else begin
            if (a)
                ref_f <= {b, b, c};
            else
                ref_f <= ({c, c} & {d, 2'b01, b}) * 3;
            ref_g <= b;
            ref_h <= a ^ (|b);
        end
    end

    // Result checking task
    task check_results;
        begin
            if (e !== ref_e || f !== ref_f || g !== ref_g || h !== ref_h) begin
                error = error + 1;
                $fwrite(log_file, "Error at time: %g ns\n", $time);
                $fwrite(log_file, "Inputs: a=%b, b=0x%0h, c=0x%0h, d=0x%0h, rst=%b\n", a, b, c, d, rst);
                $fwrite(log_file, "DUT     -> e=%b, f=0x%0h, g=0x%0h, h=%b\n", e, f, g, h);
                $fwrite(log_file, "REF     -> e=%b, f=0x%0h, g=0x%0h, h=%b\n", ref_e, ref_f, ref_g, ref_h);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Final result display
    initial begin
        #20000;
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
