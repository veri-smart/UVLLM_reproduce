module first_counter (
    clk,
    reset,
    enable,
    counter_out,
    overflow_out
);
  input wire clk;
  input wire reset;
  input wire enable;
  output [3:0] counter_out;
  output overflow_out;
  reg [3:0] counter_out;
  reg overflow_out;

  always @(posedge clk) begin : COUNTER
    if (reset) begin
      counter_out  <= 4'b0000;
      overflow_out <= 1'b0;
    end else if (enable == 1'b1) begin
      overflow_out <= (counter_out == 4'b1111);
      counter_out <= counter_out + 1;
    end
end endmodule

