`timescale 1ns/1ps

module mux_4to1_case_tb();

    reg [3:0] a;
    reg [3:0] b;
    reg [3:0] c;
    reg [3:0] d;
    reg [1:0] sel;

    wire [3:0] out;

    reg [3:0] tb_out;

    integer i;
    integer error = 0;
    integer log_file;

    // Instantiate the 4-to-1 mux module under test
    mux_4to1_case uut (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .sel(sel),
        .out(out)
    );

    initial begin
        $dumpfile("test.vcd"); 
        $dumpvars(0, uut); 
    end

    // Initialize log file
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Directed and random stimulus
    initial begin
        // Directed stimulus: Test all select values with known inputs
        a = 4'b0001;
        b = 4'b0010;
        c = 4'b0100;
        d = 4'b1000;

        sel = 2'b00; #10; check_results();
        sel = 2'b01; #10; check_results();
        sel = 2'b10; #10; check_results();
        sel = 2'b11; #10; check_results();

        // Random stimulus
        for (i = 0; i < 1000; i = i + 1) begin
            a = $random;
            b = $random;
            c = $random;
            d = $random;
            sel = $random % 4; // sel should only be 0~3
            #10;
            check_results();
        end

        $fclose(log_file);
        $finish;
    end

    // Reference model
    always @(*) begin
        case (sel)
            2'b00: tb_out = a;
            2'b01: tb_out = b;
            2'b10: tb_out = c;
            2'b11: tb_out = d;
        endcase
    end

    // Result checking task
    task check_results;
        begin
            if (out !== tb_out) begin
                error = error + 1;
                $fwrite(log_file, "Error Time: %g ns\n", $time);
                $fwrite(log_file, "Inputs: a = 4'b%0b, b = 4'b%0b, c = 4'b%0b, d = 4'b%0b, sel = 2'b%0b\n", a, b, c, d, sel);
                $fwrite(log_file, "DUT Output:       out = 4'b%0b\n", out);
                $fwrite(log_file, "Reference Output: out = 4'b%0b\n", tb_out);
                $fwrite(log_file, "-----------------------------\n");
            end
        end
    endtask

    // Display test results at the end
    initial begin
        #10000; // End of simulation time
        if (error == 0) begin
            $display("=========== Your Design Passed ===========");
            $fwrite(log_file, "=========== Your Design Passed ===========\n");
        end else begin
            $display("=========== Your Design Failed ===========");
        end
        $finish;
    end

endmodule
