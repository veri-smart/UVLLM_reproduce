module first_counter (
    clk,
    reset,
    enable,
    counter_out,
    overflow_out
);
  input clk;
  input reset;
  input enable;
  output reg [3:0] counter_out;
  output reg overflow_out;
  wire clk;
  wire reset;
  wire enable;
  
  

  always @(posedge clk) begin : COUNTER
    if (reset == 1'b1) begin
      counter_out  <= 4'b0000;
      overflow_out <= 1'b0;
    end else if (enable == 1'b1) begin
      if (counter_out == 4'b1110) begin
        overflow_out <= 1'b1;
      end
      counter_out <= counter_out + 1;
    end
  end

endmodule

