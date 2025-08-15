module DP_RAM (
    clk,
    we,
    re,
    address_read,
    address_write,
    data_in,
    data_out
);

  parameter address_width = 8;
  parameter data_width = 8;
  parameter num_words = 205;

  input clk, we, re;
  input [address_width-1:0] address_read, address_write;
  input [data_width-1:0] data_in;
  output [data_width-1:0] data_out;

  reg [data_width-1:0] data_out;
  reg [data_width-1:0] mem[0:num_words-1];

  integer i;
  initial begin
    for (i = 0; i < num_words; i = i + 1) mem[i] = 0;
  end

  always @(posedge (clk)) begin
    if (we == 1'b1) begin
      mem[address_write] <= data_in;
    end
    if (re == 1'b1) begin
      data_out <= mem[address_read];
    end
  end

endmodule
