// verilator lint_off WIDTHEXPAND
module GF_mult_add_syndromes (
    input clk,
    input reset,
    input CE,
    input [7:0] ip1,
    ip2,
    input [2:0] count_in,

    output reg S_Ready,
    output reg [7:0] S
);

  reg  [8:0] add_inputs;
  reg  [7:0] out_GF_mult_0;

  reg  [7:0] address_GF_dec;
  wire [7:0] out_GF_dec;

  reg [7:0] xor_reg0, xor_reg1, xor_reg2, xor_reg3, xor_reg4, xor_reg5, xor_reg6, xor_reg7;

  reg [7:0] cnt203_0, cnt203_1, cnt203_2, cnt203_3, cnt203_4, cnt203_5, cnt203_6, cnt203_7;

  reg CE1;

  GF_matrix_dec rom_instant (
      .clk(clk),
      .re(CE || CE1),
      .address_read(address_GF_dec),
      .data_out(out_GF_dec)
  );

  reg [7:0] ip1_0;
  reg [2:0] count_in0, count_in1, count_in2, count_in3;
  reg F;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      add_inputs <= 0;
      out_GF_mult_0 <= 0;
      address_GF_dec <= 0;

      xor_reg0 <= 0;
      xor_reg1 <= 0;
      xor_reg2 <= 0;
      xor_reg3 <= 0;
      xor_reg4 <= 0;
      xor_reg5 <= 0;
      xor_reg6 <= 0;
      xor_reg7 <= 0;

      cnt203_0 <= 204;
      cnt203_1 <= 204;
      cnt203_2 <= 204;
      cnt203_3 <= 204;
      cnt203_4 <= 204;
      cnt203_5 <= 204;
      cnt203_6 <= 204;
      cnt203_7 <= 204;

      S_Ready <= 0;
      S <= 0;
      F <= 1;
      ip1_0 <= 8'hFF;

      count_in0 <= 0;
      count_in1 <= 0;
      count_in2 <= 0;
      count_in3 <= 0;
      CE1 <= 1;
    end else begin
      if (CE) begin
        CE1 <= 0;

        ip1_0 <= ip1;
        count_in0 <= count_in;
        add_inputs <= ip1 + ip2;

        out_GF_mult_0 <= add_inputs[7:0] + add_inputs[8];
        count_in1 <= count_in0;

        if (&ip1_0) F <= 1;
        else F <= 0;

        count_in2 <= count_in1;
        address_GF_dec <= (F) ? 8'h00 : (&out_GF_mult_0) ? 8'h01 : out_GF_mult_0 + 1;

        count_in3 <= count_in2;

        case (count_in3)
          4: xor_reg4 <= xor_reg4 ^ out_GF_dec;
          5: xor_reg5 <= xor_reg5 ^ out_GF_dec;
          6: xor_reg6 <= xor_reg6 ^ out_GF_dec;
          7: xor_reg7 <= xor_reg7 ^ out_GF_dec;
          0: xor_reg0 <= xor_reg0 ^ out_GF_dec;
          1: xor_reg1 <= xor_reg1 ^ out_GF_dec;
          2: xor_reg2 <= xor_reg2 ^ out_GF_dec;
          default: xor_reg3 <= xor_reg3 ^ out_GF_dec;
        endcase

        if (S_Ready) begin
          S_Ready <= 0;
        end

        case (count_in)

          0: begin
            if (cnt203_0 == 0) begin

              S_Ready <= 1;
              cnt203_0 <= 203;
              S <= xor_reg0;
              xor_reg0 <= 0;

            end else cnt203_0 <= cnt203_0 - 1;
          end

          1: begin
            if (cnt203_1 == 0) begin
              cnt203_1 <= 203;
              S <= xor_reg1;
              xor_reg1 <= 0;

            end else cnt203_1 <= cnt203_1 - 1;
          end

          2: begin
            if (cnt203_2 == 0) begin
              cnt203_2 <= 203;
              S <= xor_reg2;
              xor_reg2 <= 0;

            end else cnt203_2 <= cnt203_2 - 1;
          end

          3: begin
            if (cnt203_3 == 0) begin
              cnt203_3 <= 203;
              S <= xor_reg3;
              xor_reg3 <= 0;

            end else cnt203_3 <= cnt203_3 - 1;
          end

          4: begin
            if (cnt203_4 == 0) begin
              cnt203_4 <= 203;
              S <= xor_reg4;
              xor_reg4 <= 0;

            end else cnt203_4 <= cnt203_4 - 1;
          end

          5: begin
            if (cnt203_5 == 0) begin
              cnt203_5 <= 203;
              S <= xor_reg5;
              xor_reg5 <= 0;

            end else cnt203_5 <= cnt203_5 - 1;
          end

          6: begin
            if (cnt203_6 == 0) begin
              cnt203_6 <= 203;
              S <= xor_reg6;
              xor_reg6 <= 0;

            end else cnt203_6 <= cnt203_6 - 1;
          end

          default: begin
            if (cnt203_7 == 0) begin
              cnt203_7 <= 203;
              S <= xor_reg7;
              xor_reg7 <= 0;

            end else cnt203_7 <= cnt203_7 - 1;
          end

        endcase

      end

    end
  end

endmodule
// verilator lint_on WIDTHEXPAND
