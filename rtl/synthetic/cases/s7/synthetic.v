module xxxxx (
    input clk,
    input rst,
    input a,
    input [3:0] b,
    input [7:0] c,
    input [9:0] d,
    output e,
    output reg [15:0] f,
    output reg [3:0] g,
    output reg h
);
  reg [3:0] r;

  assign e = a + b[0] * c[2] ^ d[7];

  always @(posedge clk) begin
    if (rst) f <= 0;
    else if (a) f <= {b, b, c};
    else f <= ({c, c} & {d, 2'b01, b}) * 3;
  end

  always @(posedge clk) begin
    if (rst) r <= 0;
    else r <= b;
    g <= r;
  end

  always @(posedge clk) begin
    if (rst) h <= 0;
    else h <= a ^ (|b);
  end

endmodule
