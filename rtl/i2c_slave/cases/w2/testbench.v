`timescale 1ns / 10ps

module testbench;

  integer error_count;
  integer file_out;

  reg clk;
  reg instrument_clk;
  reg rstn;

  wire [31:0] adr;
  wire [31:0] adr_ref;
  wire [7:0] dat_i, dat_o, dat0_i, dat1_i;
  wire [7:0] dat_i_ref, dat_o_ref, dat0_i_ref, dat1_i_ref;
  wire we, we_ref;
  wire stb, stb_ref;
  wire cyc, cyc_ref;
  wire ack, ack_ref;
  wire inta, inta_ref;

  reg [7:0] q, qq;
  reg [7:0] q_ref, qq_ref;

  wire scl, scl0_o, scl0_oen, scl1_o, scl1_oen;
  wire scl_ref, scl0_o_ref, scl0_oen_ref, scl1_o_ref, scl1_oen_ref;
  wire sda, sda0_o, sda0_oen, sda1_o, sda1_oen;
  wire sda_ref, sda0_o_ref, sda0_oen_ref, sda1_o_ref, sda1_oen_ref;

  parameter PRER_LO = 3'b000;
  parameter PRER_HI = 3'b001;
  parameter CTR = 3'b010;
  parameter RXR = 3'b011;
  parameter TXR = 3'b011;
  parameter CR = 3'b100;
  parameter SR = 3'b100;

  parameter TXR_R = 3'b101;
  parameter CR_R = 3'b110;

  parameter RD = 1'b1;
  parameter WR = 1'b0;
  parameter SADR = 7'b0010_000;

  always #5 clk = ~clk;
  always #20 instrument_clk = ~instrument_clk;

  integer f;

  wire wb_ack_o;
  wire wb_inta_o;
  wire wb_ack_o_ref;
  wire wb_inta_o_ref;

  wb_master_model #(8, 32) u0 (
      .clk (clk),
      .rst (rstn),
      .adr (adr),
      .din (dat_i),
      .dout(dat_o),
      .cyc (cyc),
      .stb (stb),
      .we  (we),
      .sel (),
      .ack (ack || wb_ack_o),
      .err (1'b0),
      .rty (1'b0)
  );
  wb_master_model #(8, 32) u0_ref (
      .clk (clk),
      .rst (rstn),
      .adr (adr_ref),
      .din (dat_i_ref),
      .dout(dat_o_ref),
      .cyc (cyc_ref),
      .stb (stb_ref),
      .we  (we_ref),
      .sel (),
      .ack (ack_ref || wb_ack_o_ref),
      .err (1'b0),
      .rty (1'b0)
  );

  wire stb0 = stb & ~adr[3];
  wire stb1 = stb & adr[3];
  wire stb0_ref = stb_ref & ~adr_ref[3];
  wire stb1_ref = stb_ref & adr_ref[3];

  assign dat_i = ({{8'd8} {stb0}} & dat0_i) | ({{8'd8} {stb1}} & dat1_i);
  assign dat_i_ref = ({{8'd8} {stb0_ref}} & dat0_i_ref) | ({{8'd8} {stb1_ref}} & dat1_i);

  i2c_master_top_ref
      i2c_top (

          .wb_clk_i(clk),
          .wb_rst_i(1'b0),
          .arst_i(rstn),
          .wb_adr_i(adr[2:0]),
          .wb_dat_i(dat_o),
          .wb_dat_o(dat0_i),
          .wb_we_i(we),
          .wb_stb_i(stb0),
          .wb_cyc_i(cyc),
          .wb_ack_o(wb_ack_o),
          .wb_inta_o(wb_inta_o),

          .scl_pad_i(scl),
          .scl_pad_o(scl0_o),
          .scl_padoen_o(scl0_oen),
          .sda_pad_i(sda),
          .sda_pad_o(sda0_o),
          .sda_padoen_o(sda0_oen)
      ),
      i2c_top2 (

          .wb_clk_i(clk),
          .wb_rst_i(1'b0),
          .arst_i(rstn),
          .wb_adr_i(adr[2:0]),
          .wb_dat_i(dat_o),
          .wb_dat_o(dat1_i),
          .wb_we_i(we),
          .wb_stb_i(stb1),
          .wb_cyc_i(cyc),
          .wb_ack_o(ack),
          .wb_inta_o(inta),

          .scl_pad_i(scl),
          .scl_pad_o(scl1_o),
          .scl_padoen_o(scl1_oen),
          .sda_pad_i(sda),
          .sda_pad_o(sda1_o),
          .sda_padoen_o(sda1_oen)
      );

  i2c_master_top_ref
      i2c_top_ref (

          .wb_clk_i(clk),
          .wb_rst_i(1'b0),
          .arst_i(rstn),
          .wb_adr_i(adr_ref[2:0]),
          .wb_dat_i(dat_o_ref),
          .wb_dat_o(dat0_i_ref),
          .wb_we_i(we_ref),
          .wb_stb_i(stb0_ref),
          .wb_cyc_i(cyc_ref),
          .wb_ack_o(wb_ack_o_ref),
          .wb_inta_o(wb_inta_o_ref),

          .scl_pad_i(scl_ref),
          .scl_pad_o(scl0_o_ref),
          .scl_padoen_o(scl0_oen_ref),
          .sda_pad_i(sda_ref),
          .sda_pad_o(sda0_o_ref),
          .sda_padoen_o(sda0_oen_ref)
      ),
      i2c_top2_ref (

          .wb_clk_i(clk),
          .wb_rst_i(1'b0),
          .arst_i(rstn),
          .wb_adr_i(adr_ref[2:0]),
          .wb_dat_i(dat_o_ref),
          .wb_dat_o(dat1_i_ref),
          .wb_we_i(we_ref),
          .wb_stb_i(stb1_ref),
          .wb_cyc_i(cyc_ref),
          .wb_ack_o(ack_ref),
          .wb_inta_o(inta_ref),

          .scl_pad_i(scl_ref),
          .scl_pad_o(scl1_o_ref),
          .scl_padoen_o(scl1_oen_ref),
          .sda_pad_i(sda_ref),
          .sda_pad_o(sda1_o_ref),
          .sda_padoen_o(sda1_oen_ref)
      ); 

  i2c_slave_model #(SADR) i2c_slave (
      .scl(scl),
      .sda(sda)
  );
  i2c_slave_model_ref #(SADR) i2c_slave_ref (
      .scl(scl_ref),
      .sda(sda_ref)
  );

  delay
      m0_scl (
          scl0_oen ? 1'bz : scl0_o,
          scl
      ),
      m1_scl (
          scl1_oen ? 1'bz : scl1_o,
          scl
      ),
      m0_sda (
          sda0_oen ? 1'bz : sda0_o,
          sda
      ),
      m1_sda (
          sda1_oen ? 1'bz : sda1_o,
          sda
      );

  delay
      m0_scl_ref (
          scl0_oen_ref ? 1'bz : scl0_o_ref,
          scl_ref
      ),
      m1_scl_ref (
          scl1_oen_ref ? 1'bz : scl1_o_ref,
          scl_ref
      ),
      m0_sda_ref (
          sda0_oen_ref ? 1'bz : sda0_o_ref,
          sda_ref
      ),
      m1_sda_ref (
          sda1_oen_ref ? 1'bz : sda1_o_ref,
          sda_ref
      );

  pullup p1 (scl);
  pullup p2 (sda);
  pullup p1_ref (scl_ref);
  pullup p2_ref (sda_ref);

  initial begin
    file_out = $fopen("test.txt", "w");
    $dumpfile("test.vcd");
    $dumpvars(0, testbench);
  end

  reg start, finished;

  initial begin
    force i2c_slave.debug = 1'b0;

    clk = 0;
    instrument_clk = 0;
    start = 0;
    finished = 0;

    rstn = 1'b1;
    #2;
    rstn = 1'b0;
    repeat (1) @(posedge clk);
    rstn = 1'b1;

    @(posedge clk);
    start = 1;
  end

  initial begin
    @(start);
    u0.wb_write(1, PRER_LO, 8'hfa);
    u0.wb_write(1, PRER_LO, 8'hc8);
    u0.wb_write(1, PRER_HI, 8'h00);

    u0.wb_cmp(0, PRER_LO, 8'hc8);
    u0.wb_cmp(0, PRER_HI, 8'h00);

    u0.wb_write(1, CTR, 8'h80);

    u0.wb_write(1, TXR, {SADR, WR});
    u0.wb_write(0, CR, 8'h90);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(0, SR, q);

    u0.wb_write(1, TXR, 8'h01);
    u0.wb_write(0, CR, 8'h10);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(0, SR, q);

    u0.wb_write(1, TXR, 8'ha5);
    u0.wb_write(0, CR, 8'h10);

    while (scl) #1;
    force scl = 1'b0;
    #100000;
    release scl;

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, TXR, 8'h5a);
    u0.wb_write(0, CR, 8'h50);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, TXR, {SADR, WR});
    u0.wb_write(0, CR, 8'h90);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, TXR, 8'h01);
    u0.wb_write(0, CR, 8'h10);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, TXR, {SADR, RD});
    u0.wb_write(0, CR, 8'h90);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, CR, 8'h20);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_read(1, RXR, qq);

    u0.wb_write(1, CR, 8'h20);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_read(1, RXR, qq);

    u0.wb_write(1, CR, 8'h20);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_read(1, RXR, qq);

    u0.wb_write(1, CR, 8'h28);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_read(1, RXR, qq);

    u0.wb_write(1, TXR, {SADR, WR});
    u0.wb_write(0, CR, 8'h90);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, TXR, 8'h10);
    u0.wb_write(0, CR, 8'h10);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    u0.wb_write(1, CR, 8'h40);

    u0.wb_read(1, SR, q);
    while (q[1]) u0.wb_read(1, SR, q);

    #250000;
  end

  initial begin
    @(start);
    u0_ref.wb_write(1, PRER_LO, 8'hfa);
    u0_ref.wb_write(1, PRER_LO, 8'hc8);
    u0_ref.wb_write(1, PRER_HI, 8'h00);

    u0_ref.wb_cmp(0, PRER_LO, 8'hc8);
    u0_ref.wb_cmp(0, PRER_HI, 8'h00);

    u0_ref.wb_write(1, CTR, 8'h80);

    u0_ref.wb_write(1, TXR, {SADR, WR});
    u0_ref.wb_write(0, CR, 8'h90);

    u0_ref.wb_read(1, SR, q_ref);
    while (q[1]) u0_ref.wb_read(0, SR, q_ref);

    u0_ref.wb_write(1, TXR, 8'h01);
    u0_ref.wb_write(0, CR, 8'h10);

    u0_ref.wb_read(1, SR, q_ref);
    while (q[1]) u0_ref.wb_read(0, SR, q_ref);

    u0_ref.wb_write(1, TXR, 8'ha5);
    u0_ref.wb_write(0, CR, 8'h10);

    while (scl_ref) #1;
    force scl_ref = 1'b0;
    #100000;
    release scl_ref;

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, TXR, 8'h5a);
    u0_ref.wb_write(0, CR, 8'h50);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, TXR, {SADR, WR});
    u0_ref.wb_write(0, CR, 8'h90);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, TXR, 8'h01);
    u0_ref.wb_write(0, CR, 8'h10);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, TXR, {SADR, RD});
    u0_ref.wb_write(0, CR, 8'h90);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, CR, 8'h20);

    u0_ref.wb_read(1, SR, q_ref);
    while (q[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_read(1, RXR, qq_ref);

    u0_ref.wb_write(1, CR, 8'h20);

    u0_ref.wb_read(1, SR, q_ref);
    while (q[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_read(1, RXR, qq_ref);

    u0_ref.wb_write(1, CR, 8'h20);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_read(1, RXR, qq_ref);

    u0_ref.wb_write(1, CR, 8'h28);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    u0_ref.wb_read(1, RXR, qq_ref);

    u0_ref.wb_write(1, TXR, {SADR, WR});
    u0_ref.wb_write(0, CR, 8'h90);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, TXR, 8'h10);
    u0_ref.wb_write(0, CR, 8'h10);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0.wb_read(1, SR, q_ref);

    u0_ref.wb_write(1, CR, 8'h40);

    u0_ref.wb_read(1, SR, q_ref);
    while (q_ref[1]) u0_ref.wb_read(1, SR, q_ref);

    #250000;
    if (error_count == 0) begin
      $display("=========== Your Design Passed ===========");
      $fwrite(file_out, "=========== Your Design Passed ===========\n");
    end else begin
      $display("=========== Your Design Failed ===========");
    end
    $fclose(file_out);
    $finish;
  end

  task check_results;
    begin
      if (scl !== scl_ref || sda !== sda_ref) begin
        $fwrite(file_out, "Error Time: %g ns\n", $time);
        $fwrite(file_out, "DUT Output: scl = %h sda = %h\n", 
                scl, sda);
        $fwrite(file_out, "Reference Output: scl = %h sda = %h\n", 
                scl_ref, sda_ref);
        $fwrite(file_out, "-----------------------------\n");
        error_count = error_count + 1;
      end
    end
  endtask

  always @(clk) begin
    check_results();
  end

endmodule

module delay (
    in,
    out
);
  input in;
  output out;

  assign out = in;

  specify
    (in => out) = (600, 600);
  endspecify
endmodule


module i2c_slave_model_ref (
    scl,
    sda
);

  parameter I2C_ADR = 7'b001_0000;

  input scl;
  inout sda;

  wire debug = 1'b1;

  reg [7:0] mem[3:0];
  reg [7:0] mem_adr;
  reg [7:0] mem_do;

  reg sta, d_sta;
  reg sto, d_sto;

  reg  [7:0] sr;
  reg        rw;

  wire       my_adr;
  wire       i2c_reset;
  reg  [2:0] bit_cnt;
  wire       acc_done;
  reg        ld;

  reg        sda_o;
  wire       sda_dly;

  parameter idle = 3'b000;
  parameter slave_ack = 3'b001;
  parameter get_mem_adr = 3'b010;
  parameter gma_ack = 3'b011;
  parameter data = 3'b100;
  parameter data_ack = 3'b101;

  reg [2:0] state;

  initial begin
    sda_o = 1'b1;
    state = idle;
  end

  always @(posedge scl) sr <= #1{sr[6:0], sda};

  assign my_adr = (sr[7:1] == I2C_ADR);

  always @(posedge scl)
    if (ld) bit_cnt <= #1 3'b111;
    else bit_cnt <= #1 bit_cnt - 3'h1;

  assign acc_done = !(|bit_cnt);

  assign #1 sda_dly = sda;

  always @(negedge sda)
    if (scl) begin
      sta   <= #1 1'b1;
      d_sta <= #1 1'b0;
      sto   <= #1 1'b0;

    end else sta <= #1 1'b0;

  always @(posedge scl) d_sta <= #1 sta;

  always @(posedge sda)
    if (scl) begin
      sta <= #1 1'b0;
      sto <= #1 1'b1;

    end else sto <= #1 1'b0;

  assign i2c_reset = sta || sto;

  always @(negedge scl or posedge sto)
    if (sto || (sta && !d_sta)) begin
      state <= #1 idle;

      sda_o <= #1 1'b1;
      ld    <= #1 1'b1;
    end else begin

      sda_o <= #1 1'b1;
      ld    <= #1 1'b0;

      case (state)
        idle:
        if (acc_done && my_adr) begin
          state <= #1 slave_ack;
          rw <= #1 sr[0];
          sda_o <= #1 1'b0;

          #2;

          if (rw) begin
            mem_do <= #1 mem[mem_adr];

          end
        end

        slave_ack: begin
          if (rw) begin
            state <= #1 data;
            sda_o <= #1 mem_do[7];
          end else state <= #1 get_mem_adr;

          ld <= #1 1'b1;
        end

        get_mem_adr:
        if (acc_done) begin
          state   <= #1 gma_ack;
          mem_adr <= #1 sr;
          sda_o   <= #1 !(sr <= 15);

        end

        gma_ack: begin
          state <= #1 data;
          ld    <= #1 1'b1;
        end

        data: begin
          if (rw) sda_o <= #1 mem_do[7];

          if (acc_done) begin
            state   <= #1 data_ack;
            mem_adr <= #2 mem_adr + 8'h1;
            sda_o   <= #1 (rw && (mem_adr <= 15));

            if (rw) begin
              #3 mem_do <= mem[mem_adr];

            end

            if (!rw) begin
              mem[mem_adr[3:0]] <= #1 sr;

            end
          end
        end

        data_ack: begin
          ld <= #1 1'b1;

          if (rw)
            if (sr[0]) begin
              state <= #1 idle;
              sda_o <= #1 1'b1;
            end else begin
              state <= #1 data;
              sda_o <= #1 mem_do[7];
            end
          else begin
            state <= #1 data;
            sda_o <= #1 1'b1;
          end
        end

      endcase
    end

  always @(posedge scl) if (!acc_done && rw) mem_do <= #1{mem_do[6:0], 1'b1};

  assign sda = sda_o ? 1'bz : 1'b0;

  wire tst_sto = sto;
  wire tst_sta = sta;

endmodule

module wb_master_model (
    clk,
    rst,
    adr,
    din,
    dout,
    cyc,
    stb,
    we,
    sel,
    ack,
    err,
    rty
);

  parameter dwidth = 32;
  parameter awidth = 32;

  input clk, rst;
  output [awidth   -1:0] adr;
  input [dwidth   -1:0] din;
  output [dwidth   -1:0] dout;
  output cyc, stb;
  output we;
  output [dwidth/8 -1:0] sel;
  input ack, err, rty;

  reg [awidth   -1:0] adr;
  reg [dwidth   -1:0] dout;
  reg cyc, stb;
  reg                 we;
  reg [dwidth/8 -1:0] sel;

  reg [dwidth   -1:0] q;

  initial begin

    adr  = {awidth{1'b0}};
    dout = {dwidth{1'bx}};
    cyc  = 1'b0;
    stb  = 1'bx;
    we   = 1'hx;
    sel  = {dwidth / 8{1'bx}};
    #1;
  end

  task wb_write;
    input delay;
    integer delay;

    input [awidth -1:0] a;
    input [dwidth -1:0] d;

    begin

      repeat (delay) @(posedge clk);

      #1;
      adr  = a;
      dout = d;
      cyc  = 1'b1;
      stb  = 1'b1;
      we   = 1'b1;
      sel  = {dwidth / 8{1'b1}};
      @(posedge clk);

      while (~ack) @(posedge clk);

      #1;
      cyc  = 1'b0;
      stb  = 1'bx;

      adr  = {awidth{1'b0}};
      dout = {dwidth{1'bx}};
      we   = 1'hx;
      sel  = {dwidth / 8{1'bx}};

    end
  endtask

  task wb_read;
    input delay;
    integer delay;

    input [awidth -1:0] a;
    output [dwidth -1:0] d;

    begin

      repeat (delay) @(posedge clk);

      #1;
      adr  = a;
      dout = {dwidth{1'bx}};
      cyc  = 1'b1;
      stb  = 1'b1;
      we   = 1'b0;
      sel  = {dwidth / 8{1'b1}};
      @(posedge clk);

      while (~ack) @(posedge clk);

      #1;
      cyc  = 1'b0;
      stb  = 1'bx;

      adr  = {awidth{1'b0}};
      dout = {dwidth{1'bx}};
      we   = 1'hx;
      sel  = {dwidth/8{1'bx}};
      d    = din;

    end
  endtask

  task wb_cmp;
    input delay;
    integer delay;

    input [awidth -1:0] a;
    input [dwidth -1:0] d_exp;

    begin
      wb_read(delay, a, q);

      if (d_exp !== q)
        $display("Data compare error. Received %h, expected %h at time %t", q, d_exp, $time);
    end
  endtask

endmodule


`define I2C_CMD_NOP 4'b0000
`define I2C_CMD_START 4'b0001
`define I2C_CMD_STOP 4'b0010
`define I2C_CMD_WRITE 4'b0100
`define I2C_CMD_READ 4'b1000

module i2c_master_bit_ctrl_ref (
    input clk,
    input rst,
    input nReset,
    input ena,

    input [15:0] clk_cnt,

    input      [3:0] cmd,
    output reg       cmd_ack,
    output reg       busy,
    output reg       al,

    input      din,
    output reg dout,

    input      scl_i,
    output     scl_o,
    output reg scl_oen,
    input      sda_i,
    output     sda_o,
    output reg sda_oen
);

  reg [1:0] cSCL, cSDA;
  reg [2:0] fSCL, fSDA;
  reg sSCL, sSDA;
  reg dSCL, dSDA;
  reg        dscl_oen;
  reg        sda_chk;
  reg        clk_en;
  reg        slave_wait;
  reg [15:0] cnt;
  reg [13:0] filter_cnt;

  reg [17:0] c_state;

  always @(posedge clk) dscl_oen <= #1 scl_oen;

  always @(posedge clk)
    if (!nReset) slave_wait <= 1'b0;
    else slave_wait <= (scl_oen & ~dscl_oen & ~sSCL) | (slave_wait & ~sSCL);

  wire scl_sync = dSCL & ~sSCL & scl_oen;

  always @(posedge clk)
    if (~nReset) begin
      cnt    <= #1 16'h0;
      clk_en <= #1 1'b1;
    end else if (rst || ~|cnt || !ena || scl_sync) begin
      cnt    <= #1 clk_cnt;
      clk_en <= #1 1'b1;
    end else if (slave_wait) begin
      cnt    <= #1 cnt;
      clk_en <= #1 1'b0;
    end else begin
      cnt    <= #1 cnt - 16'h1;
      clk_en <= #1 1'b0;
    end

  always @(posedge clk)
    if (!nReset) begin
      cSCL <= #1 2'b00;
      cSDA <= #1 2'b00;
    end else if (rst) begin
      cSCL <= #1 2'b00;
      cSDA <= #1 2'b00;
    end else begin
      cSCL <= {cSCL[0], scl_i};
      cSDA <= {cSDA[0], sda_i};
    end

  always @(posedge clk)
    if (!nReset) filter_cnt <= 14'h0;
    else if (rst || !ena) filter_cnt <= 14'h0;
    else if (~|filter_cnt) filter_cnt <= clk_cnt >> 2;
    else filter_cnt <= filter_cnt - 1;

  always @(posedge clk)
    if (!nReset) begin
      fSCL <= 3'b111;
      fSDA <= 3'b111;
    end else if (rst) begin
      fSCL <= 3'b111;
      fSDA <= 3'b111;
    end else if (~|filter_cnt) begin
      fSCL <= {fSCL[1:0], cSCL[1]};
      fSDA <= {fSDA[1:0], cSDA[1]};
    end

  always @(posedge clk)
    if (~nReset) begin
      sSCL <= #1 1'b1;
      sSDA <= #1 1'b1;

      dSCL <= #1 1'b1;
      dSDA <= #1 1'b1;
    end else if (rst) begin
      sSCL <= #1 1'b1;
      sSDA <= #1 1'b1;

      dSCL <= #1 1'b1;
      dSDA <= #1 1'b1;
    end else begin
      sSCL <= #1 &fSCL[2:1] | &fSCL[1:0] | (fSCL[2] & fSCL[0]);
      sSDA <= #1 &fSDA[2:1] | &fSDA[1:0] | (fSDA[2] & fSDA[0]);

      dSCL <= #1 sSCL;
      dSDA <= #1 sSDA;
    end

  reg sta_condition;
  reg sto_condition;
  always @(posedge clk)
    if (~nReset) begin
      sta_condition <= #1 1'b0;
      sto_condition <= #1 1'b0;
    end else if (rst) begin
      sta_condition <= #1 1'b0;
      sto_condition <= #1 1'b0;
    end else begin
      sta_condition <= #1 ~sSDA & dSDA & sSCL;
      sto_condition <= #1 sSDA & ~dSDA & sSCL;
    end

  always @(posedge clk)
    if (!nReset) busy <= #1 1'b0;
    else if (rst) busy <= #1 1'b0;
    else busy <= #1 (sta_condition | busy) & ~sto_condition;

  reg cmd_stop;
  always @(posedge clk)
    if (~nReset) cmd_stop <= #1 1'b0;
    else if (rst) cmd_stop <= #1 1'b0;
    else if (clk_en) cmd_stop <= #1 cmd == `I2C_CMD_STOP;

  always @(posedge clk)
    if (~nReset) al <= #1 1'b0;
    else if (rst) al <= #1 1'b0;
    else al <= #1 (sda_chk & ~sSDA & sda_oen) | (|c_state & sto_condition & ~cmd_stop);

  always @(posedge clk) if (sSCL & ~dSCL) dout <= #1 sSDA;

  parameter [17:0] idle = 18'b0_0000_0000_0000_0000;
  parameter [17:0] start_a = 18'b0_0000_0000_0000_0001;
  parameter [17:0] start_b = 18'b0_0000_0000_0000_0010;
  parameter [17:0] start_c = 18'b0_0000_0000_0000_0100;
  parameter [17:0] start_d = 18'b0_0000_0000_0000_1000;
  parameter [17:0] start_e = 18'b0_0000_0000_0001_0000;
  parameter [17:0] stop_a = 18'b0_0000_0000_0010_0000;
  parameter [17:0] stop_b = 18'b0_0000_0000_0100_0000;
  parameter [17:0] stop_c = 18'b0_0000_0000_1000_0000;
  parameter [17:0] stop_d = 18'b0_0000_0001_0000_0000;
  parameter [17:0] rd_a = 18'b0_0000_0010_0000_0000;
  parameter [17:0] rd_b = 18'b0_0000_0100_0000_0000;
  parameter [17:0] rd_c = 18'b0_0000_1000_0000_0000;
  parameter [17:0] rd_d = 18'b0_0001_0000_0000_0000;
  parameter [17:0] wr_a = 18'b0_0010_0000_0000_0000;
  parameter [17:0] wr_b = 18'b0_0100_0000_0000_0000;
  parameter [17:0] wr_c = 18'b0_1000_0000_0000_0000;
  parameter [17:0] wr_d = 18'b1_0000_0000_0000_0000;

  always @(posedge clk)
    if (!nReset) begin
      c_state <= #1 idle;
      cmd_ack <= #1 1'b0;
      scl_oen <= #1 1'b1;
      sda_oen <= #1 1'b1;
      sda_chk <= #1 1'b0;
    end else if (rst | al) begin
      c_state <= #1 idle;
      cmd_ack <= #1 1'b0;
      scl_oen <= #1 1'b1;
      sda_oen <= #1 1'b1;
      sda_chk <= #1 1'b0;
    end else begin
      cmd_ack <= #1 1'b0;

      if (clk_en)
        case (c_state)

          idle: begin
            case (cmd)
              `I2C_CMD_START: c_state <= #1 start_a;
              `I2C_CMD_STOP:  c_state <= #1 stop_a;
              `I2C_CMD_WRITE: c_state <= #1 wr_a;
              `I2C_CMD_READ:  c_state <= #1 rd_a;
              default:        c_state <= #1 idle;
            endcase

            scl_oen <= #1 scl_oen;
            sda_oen <= #1 sda_oen;
            sda_chk <= #1 1'b0;
          end

          start_a: begin
            c_state <= #1 start_b;
            scl_oen <= #1 scl_oen;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          start_b: begin
            c_state <= #1 start_c;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          start_c: begin
            c_state <= #1 start_d;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          start_d: begin
            c_state <= #1 start_e;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          start_e: begin
            c_state <= #1 idle;
            cmd_ack <= #1 1'b1;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          stop_a: begin
            c_state <= #1 stop_b;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          stop_b: begin
            c_state <= #1 stop_c;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          stop_c: begin
            c_state <= #1 stop_d;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b0;
            sda_chk <= #1 1'b0;
          end

          stop_d: begin
            c_state <= #1 idle;
            cmd_ack <= #1 1'b1;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          rd_a: begin
            c_state <= #1 rd_b;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          rd_b: begin
            c_state <= #1 rd_c;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          rd_c: begin
            c_state <= #1 rd_d;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          rd_d: begin
            c_state <= #1 idle;
            cmd_ack <= #1 1'b1;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 1'b1;
            sda_chk <= #1 1'b0;
          end

          wr_a: begin
            c_state <= #1 wr_b;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 din;
            sda_chk <= #1 1'b0;
          end

          wr_b: begin
            c_state <= #1 wr_c;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 din;
            sda_chk <= #1 1'b0;

          end

          wr_c: begin
            c_state <= #1 wr_d;
            scl_oen <= #1 1'b1;
            sda_oen <= #1 din;
            sda_chk <= #1 1'b1;
          end

          wr_d: begin
            c_state <= #1 idle;
            cmd_ack <= #1 1'b1;
            scl_oen <= #1 1'b0;
            sda_oen <= #1 din;
            sda_chk <= #1 1'b0;
          end

        endcase
    end

  assign scl_o = 1'b0;
  assign sda_o = 1'b0;

endmodule

module i2c_master_byte_ctrl_ref (
    clk,
    rst,
    nReset,
    ena,
    clk_cnt,
    start,
    stop,
    read,
    write,
    ack_in,
    din,
    cmd_ack,
    ack_out,
    dout,
    i2c_busy,
    i2c_al,
    scl_i,
    scl_o,
    scl_oen,
    sda_i,
    sda_o,
    sda_oen
);

  input clk;
  input rst;
  input nReset;
  input ena;

  input [15:0] clk_cnt;

  input start;
  input stop;
  input read;
  input write;
  input ack_in;
  input [7:0] din;

  output cmd_ack;
  reg cmd_ack;
  output ack_out;
  reg ack_out;
  output i2c_busy;
  output i2c_al;
  output [7:0] dout;

  input scl_i;
  output scl_o;
  output scl_oen;
  input sda_i;
  output sda_o;
  output sda_oen;

  parameter [4:0] ST_IDLE = 5'b0_0000;
  parameter [4:0] ST_START = 5'b0_0001;
  parameter [4:0] ST_READ = 5'b0_0010;
  parameter [4:0] ST_WRITE = 5'b0_0100;
  parameter [4:0] ST_ACK = 5'b0_1000;
  parameter [4:0] ST_STOP = 5'b1_0000;

  reg [3:0] core_cmd;
  reg       core_txd;
  wire core_ack, core_rxd;

  reg [7:0] sr;
  reg shift, ld;

  wire       go;
  reg  [2:0] dcnt;
  wire       cnt_done;

  i2c_master_bit_ctrl_ref bit_controller (
      .clk    (clk),
      .rst    (rst),
      .nReset (nReset),
      .ena    (ena),
      .clk_cnt(clk_cnt),
      .cmd    (core_cmd),
      .cmd_ack(core_ack),
      .busy   (i2c_busy),
      .al     (i2c_al),
      .din    (core_txd),
      .dout   (core_rxd),
      .scl_i  (scl_i),
      .scl_o  (scl_o),
      .scl_oen(scl_oen),
      .sda_i  (sda_i),
      .sda_o  (sda_o),
      .sda_oen(sda_oen)
  );

  assign go   = (read | write | stop) & ~cmd_ack;

  assign dout = sr;

  always @(posedge clk)
    if (!nReset) sr <= #1 8'h0;
    else if (rst) sr <= #1 8'h0;
    else if (ld) sr <= #1 din;
    else if (shift) sr <= #1{sr[6:0], core_rxd};

  always @(posedge clk)
    if (!nReset) dcnt <= #1 3'h0;
    else if (rst) dcnt <= #1 3'h0;
    else if (ld) dcnt <= #1 3'h7;
    else if (shift) dcnt <= #1 dcnt - 3'h1;

  assign cnt_done = ~(|dcnt);

  reg [4:0] c_state;

  always @(posedge clk)
    if (!nReset) begin
      core_cmd <= #1 `I2C_CMD_NOP;
      core_txd <= #1 1'b0;
      shift    <= #1 1'b0;
      ld       <= #1 1'b0;
      cmd_ack  <= #1 1'b0;
      c_state  <= #1 ST_IDLE;
      ack_out  <= #1 1'b0;
    end else if (rst | i2c_al) begin
      core_cmd <= #1 `I2C_CMD_NOP;
      core_txd <= #1 1'b0;
      shift    <= #1 1'b0;
      ld       <= #1 1'b0;
      cmd_ack  <= #1 1'b0;
      c_state  <= #1 ST_IDLE;
      ack_out  <= #1 1'b0;
    end else begin

      core_txd <= #1 sr[7];
      shift    <= #1 1'b0;
      ld       <= #1 1'b0;
      cmd_ack  <= #1 1'b0;

      case (c_state)
        ST_IDLE:
        if (go) begin
          if (start) begin
            c_state  <= #1 ST_START;
            core_cmd <= #1 `I2C_CMD_START;
          end else if (read) begin
            c_state  <= #1 ST_READ;
            core_cmd <= #1 `I2C_CMD_READ;
          end else if (write) begin
            c_state  <= #1 ST_WRITE;
            core_cmd <= #1 `I2C_CMD_WRITE;
          end else begin
            c_state  <= #1 ST_STOP;
            core_cmd <= #1 `I2C_CMD_STOP;
          end

          ld <= #1 1'b1;
        end

        ST_START:
        if (core_ack) begin
          if (read) begin
            c_state  <= #1 ST_READ;
            core_cmd <= #1 `I2C_CMD_READ;
          end else begin
            c_state  <= #1 ST_WRITE;
            core_cmd <= #1 `I2C_CMD_WRITE;
          end

          ld <= #1 1'b1;
        end

        ST_WRITE:
        if (core_ack)
          if (cnt_done) begin
            c_state  <= #1 ST_ACK;
            core_cmd <= #1 `I2C_CMD_READ;
          end else begin
            c_state  <= #1 ST_WRITE;
            core_cmd <= #1 `I2C_CMD_WRITE;
            shift    <= #1 1'b1;
          end

        ST_READ:
        if (core_ack) begin
          if (cnt_done) begin
            c_state  <= #1 ST_ACK;
            core_cmd <= #1 `I2C_CMD_WRITE;
          end else begin
            c_state  <= #1 ST_READ;
            core_cmd <= #1 `I2C_CMD_READ;
          end

          shift    <= #1 1'b1;
          core_txd <= #1 ack_in;
        end

        ST_ACK:
        if (core_ack) begin
          if (stop) begin
            c_state  <= #1 ST_STOP;
            core_cmd <= #1 `I2C_CMD_STOP;
          end else begin
            c_state  <= #1 ST_IDLE;
            core_cmd <= #1 `I2C_CMD_NOP;

            cmd_ack  <= #1 1'b1;
          end

          ack_out  <= #1 core_rxd;

          core_txd <= #1 1'b1;
        end else core_txd <= #1 ack_in;

        ST_STOP:
        if (core_ack) begin
          c_state  <= #1 ST_IDLE;
          core_cmd <= #1 `I2C_CMD_NOP;

          cmd_ack  <= #1 1'b1;
        end

      endcase
    end
endmodule

module i2c_master_top_ref (
    wb_clk_i,
    wb_rst_i,
    arst_i,
    wb_adr_i,
    wb_dat_i,
    wb_dat_o,
    wb_we_i,
    wb_stb_i,
    wb_cyc_i,
    wb_ack_o,
    wb_inta_o,
    scl_pad_i,
    scl_pad_o,
    scl_padoen_o,
    sda_pad_i,
    sda_pad_o,
    sda_padoen_o
);

  parameter ARST_LVL = 1'b0;

  input wb_clk_i;
  input wb_rst_i;
  input arst_i;
  input [2:0] wb_adr_i;
  input [7:0] wb_dat_i;
  output [7:0] wb_dat_o;
  input wb_we_i;
  input wb_stb_i;
  input wb_cyc_i;
  output wb_ack_o;
  output wb_inta_o;

  reg [7:0] wb_dat_o;
  reg wb_ack_o;
  reg wb_inta_o;

  input scl_pad_i;
  output scl_pad_o;
  output scl_padoen_o;

  input sda_pad_i;
  output sda_pad_o;
  output sda_padoen_o;

  reg [15:0] prer;
  reg [7:0] ctr;
  reg [7:0] txr;
  wire [7:0] rxr;
  reg [7:0] cr;
  wire [7:0] sr;

  wire done;

  wire core_en;
  wire ien;

  wire irxack;
  reg rxack;
  reg tip;
  reg irq_flag;
  wire i2c_busy;
  wire i2c_al;
  reg al;

  wire rst_i = arst_i ^ ARST_LVL;

  wire wb_wacc = wb_we_i & wb_ack_o;

  always @(posedge wb_clk_i) wb_ack_o <= #1 wb_cyc_i & wb_stb_i & ~wb_ack_o;

  always @(posedge wb_clk_i) begin
    case (wb_adr_i)
      3'b000: wb_dat_o <= #1 prer[7:0];
      3'b001: wb_dat_o <= #1 prer[15:8];
      3'b010: wb_dat_o <= #1 ctr;
      3'b011: wb_dat_o <= #1 rxr;
      3'b100: wb_dat_o <= #1 sr;
      3'b101: wb_dat_o <= #1 txr;
      3'b110: wb_dat_o <= #1 cr;
      3'b111: wb_dat_o <= #1 0;
    endcase
  end

  always @(posedge wb_clk_i)
    if (!rst_i) begin
      prer <= #1 16'hffff;
      ctr  <= #1 8'h0;
      txr  <= #1 8'h0;
    end else if (wb_rst_i) begin
      prer <= #1 16'hffff;
      ctr  <= #1 8'h0;
      txr  <= #1 8'h0;
    end else if (wb_wacc)
      case (wb_adr_i)
        3'b000:  prer[7:0] <= #1 wb_dat_i;
        3'b001:  prer[15:8] <= #1 wb_dat_i;
        3'b010:  ctr <= #1 wb_dat_i;
        3'b011:  txr <= #1 wb_dat_i;
        default: #1;
      endcase

  always @(posedge wb_clk_i)
    if (!rst_i) cr <= #1 8'h0;
    else if (wb_rst_i) cr <= #1 8'h0;
    else if (wb_wacc) begin
      if (core_en & (wb_adr_i == 3'b100)) cr <= #1 wb_dat_i;
    end else begin
      if (done | i2c_al) cr[7:4] <= #1 4'h0;

      cr[2:1] <= #1 2'b0;
      cr[0]   <= #1 1'b0;
    end

  wire sta = cr[7];
  wire sto = cr[6];
  wire rd = cr[5];
  wire wr = cr[4];
  wire ack = cr[3];
  wire iack = cr[0];

  assign core_en = ctr[7];
  assign ien = ctr[6];

  i2c_master_byte_ctrl_ref byte_controller (
      .clk     (wb_clk_i),
      .rst     (wb_rst_i),
      .nReset  (rst_i),
      .ena     (core_en),
      .clk_cnt (prer),
      .start   (sta),
      .stop    (sto),
      .read    (rd),
      .write   (wr),
      .ack_in  (ack),
      .din     (txr),
      .cmd_ack (done),
      .ack_out (irxack),
      .dout    (rxr),
      .i2c_busy(i2c_busy),
      .i2c_al  (i2c_al),
      .scl_i   (scl_pad_i),
      .scl_o   (scl_pad_o),
      .scl_oen (scl_padoen_o),
      .sda_i   (sda_pad_i),
      .sda_o   (sda_pad_o),
      .sda_oen (sda_padoen_o)
  );

  always @(posedge wb_clk_i)
    if (!rst_i) begin
      al       <= #1 1'b0;
      rxack    <= #1 1'b0;
      tip      <= #1 1'b0;
      irq_flag <= #1 1'b0;
    end else if (wb_rst_i) begin
      al       <= #1 1'b0;
      rxack    <= #1 1'b0;
      tip      <= #1 1'b0;
      irq_flag <= #1 1'b0;
    end else begin
      al       <= #1 i2c_al | (al & ~sta);
      rxack    <= #1 irxack;
      tip      <= #1 (rd | wr);
      irq_flag <= #1 (done | i2c_al | irq_flag) & ~iack;
    end

  always @(posedge wb_clk_i)
    if (!rst_i) wb_inta_o <= #1 1'b0;
    else if (wb_rst_i) wb_inta_o <= #1 1'b0;
    else wb_inta_o <= #1 irq_flag && ien;

  assign sr[7]   = rxack;
  assign sr[6]   = i2c_busy;
  assign sr[5]   = al;
  assign sr[4:2] = 3'h0;
  assign sr[1]   = tip;
  assign sr[0]   = irq_flag;

endmodule
