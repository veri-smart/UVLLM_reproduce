`timescale 1ns/1ps

module sdram_controller_tb();

    // Parameters
    parameter ROW_WIDTH = 13;
    parameter COL_WIDTH = 9;
    parameter BANK_WIDTH = 2;
    parameter SDRADDR_WIDTH = ROW_WIDTH > COL_WIDTH ? ROW_WIDTH : COL_WIDTH;
    parameter HADDR_WIDTH = BANK_WIDTH + ROW_WIDTH + COL_WIDTH;

    // Inputs
    reg [HADDR_WIDTH-1:0] wr_addr;
    reg [15:0] wr_data;
    reg wr_enable;
    reg [HADDR_WIDTH-1:0] rd_addr;
    reg rd_enable;
    reg rst_n;
    reg clk;

    // Outputs
    wire [15:0] rd_data;
    wire rd_ready;
    wire busy;

    wire [12:0] addr;
    wire [1:0] bank_addr;
    wire [15:0] data_out;
    reg [15:0] data_in;
    wire data_oe;
    wire clock_enable;
    wire cs_n, ras_n, cas_n, we_n;
    wire data_mask_low, data_mask_high;

    // Instantiate the DUT
    sdram_controller uut (
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .wr_enable(wr_enable),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_ready(rd_ready),
        .rd_enable(rd_enable),
        .busy(busy),
        .rst_n(rst_n),
        .clk(clk),
        .addr(addr),
        .bank_addr(bank_addr),
        .data_out(data_out),
        .data_in(data_in),
        .data_oe(data_oe),
        .clock_enable(clock_enable),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .data_mask_low(data_mask_low),
        .data_mask_high(data_mask_high)
    );

    integer i;
    integer error = 0;
    integer log_file;

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, uut);
    end

    // Log file init
    initial begin
        log_file = $fopen("test.txt", "w");
    end

    // Main test process
    initial begin
        clk = 0;
        rst_n = 1;
        wr_enable = 0;
        rd_enable = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_addr = 0;
        data_in = 16'hABCD;

        #20;
        rst_n = 0;
        #20;
        rst_n = 0;
        #20;

        //all
        repeat (60) @(negedge clk);
        wr_addr = 24'hFEDBED;
        wr_data = 16'h3333;
        #10; wr_enable = 1;
        #30; wr_enable = 0;
        wr_addr = 0;
        wr_data = 0;

        repeat (60) @(negedge clk);
        wr_addr = 24'hBEDFED;
        #20;
        rd_enable = 1;
        #30; rd_enable = 0;
        wr_addr = 0;

        #40;
        data_in = 16'hBBBB;
        #10;
        data_in = $random & 16'hFFFF;

        repeat (500) @(negedge clk);

        //data_in
        wr_addr = 0;
        wr_data = 0;
        rd_enable = 0;
        wr_enable = 0;
        data_in = $random & 16'hFFFF;
        rd_addr = 0;
        rst_n = 1;
        #20;
        rst_n = 0;
        #20;
        rst_n = 0;

        repeat (60) @(negedge clk);
        wr_addr = 24'hBEDFED;
        #20;
        rd_enable = 1;
        #30; rd_enable = 0;
        wr_addr = 0;

        #40;
        data_in = 16'hBBBB;
        #10;
        data_in = $random & 16'hFFFF;
        repeat (500) @(negedge clk);

        //part1
        wr_addr = 0;
        wr_data = 0;
        rd_enable = 0;
        wr_enable = 0;
        data_in = $random & 16'hFFFF;
        rd_addr = 0;
        rst_n = 1;
        #20;
        rst_n = 0;
        #20;
        rst_n = 0;

        repeat (60) @(negedge clk);
        wr_addr = 24'hFEDBED;
        wr_data = 16'h3333;
        #20;
        wr_enable = 1;
        #30;
        wr_enable = 0;
        wr_addr = 0;
        wr_data = 0;
        repeat (500) @(negedge clk);

        //part2
        wr_addr = 0;
        wr_data = 0;
        rd_enable = 0;
        wr_enable = 0;
        data_in = $random & 16'hFFFF;
        rd_addr = 0;
        rst_n = 1;
        #20;
        rst_n = 0;
        #20;
        rst_n = 0;

        repeat (60) @(negedge clk);
        wr_addr = 24'hBEDFED;
        #20;
        rd_enable = 1;
        #30;
        rd_enable = 0;
        wr_addr = 0;
        repeat (500) @(negedge clk);

        $fclose(log_file);
        $display("=========== SDRAM Simulation Pattern Done ===========");
        $finish;
    end

    // Task to compare expected and actual results
    task check_results(input [15:0] actual, input [15:0] expected);
        begin
            if (actual !== expected) begin
                error = error + 1;
                $fwrite(log_file, "Error at time %g ns\n", $time);
                $fwrite(log_file, "Expected: %h, Got: %h\n", expected, actual);
                $fwrite(log_file, "---------------------------------\n");
            end
        end
    endtask

endmodule
