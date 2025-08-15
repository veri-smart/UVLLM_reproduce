module f_permutation (
    clk,
    reset,
    in,
    in_ready,
    ack,
    out,
    out_ready
);
  input clk, reset;
  input [575:0] in;
  input in_ready;
  output ack;
  output reg [1599:0] out;
  output reg out_ready;

  reg [22:0] i;
  wire [1599:0] round_in, round_out;
  wire [63:0] rc;
  wire        update;
  wire        accept;
  reg         calc;

  assign accept = in_ready & (~calc);

  always @(posedge clk)
    if (reset) i <= 0;
    else i <= {i[21:0], accept};

  always @(posedge clk)
    if (reset) calc <= 0;
    else calc <= (calc & (~i[22])) | accept;

  assign update = calc | accept;

  assign ack = accept;

  always @(posedge clk)
    if (reset) out_ready <= 0;
    else if (accept) out_ready <= 0;
    else if (i[22]) out_ready <= 1;

  assign round_in = accept ? {in ^ out[1599:1599-575], out[1599-576:0]} : out;

  rconst rconst_ (
      {i, accept},
      rc
  );

  round round_ (
      round_in,
      rc,
      round_out
  );

  always @(posedge clk)
    if (reset) out <= 0;
    else if (update) out <= round_out;
endmodule
