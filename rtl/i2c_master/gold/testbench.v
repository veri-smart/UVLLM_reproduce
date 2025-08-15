`timescale 1ns / 10ps

module i2c_master_top_tb();
	//
	// wires && regs
	//
	reg  clk;
	reg instrument_clk; // instrumentation clock cycle
	reg  rstn;
	wire [31:0] adr;
	wire [ 7:0] dat_i, dat_o, dat0_i, dat1_i;
	wire we;
	wire stb;
	wire cyc;
	wire ack;
	wire inta;
	reg [7:0] q, qq;
	wire scl, scl0_o, scl0_oen, scl1_o, scl1_oen;
	wire sda, sda0_o, sda0_oen, sda1_o, sda1_oen;
	integer error; // 错误计数变量
	integer log_file; // 日志文件句柄
	parameter PRER_LO = 3'b000;
	parameter PRER_HI = 3'b001;
	parameter CTR     = 3'b010;
	parameter RXR     = 3'b011;
	parameter TXR     = 3'b011;
	parameter CR      = 3'b100;
	parameter SR      = 3'b100;
	parameter TXR_R   = 3'b101; // undocumented / reserved output
	parameter CR_R    = 3'b110; // undocumented / reserved output
	parameter RD      = 1'b1;
	parameter WR      = 1'b0;
	parameter SADR    = 7'b0010_000;
	//
	// Module body
	//
	// generate clock
	always #5 clk = ~clk;
	always #20 instrument_clk = ~instrument_clk;
	
	// hookup wishbone master model
	wb_master_model #(8, 32) u0 (
		.clk(clk),
		.rst(rstn),
		.adr(adr),
		.din(dat_i),
		.dout(dat_o),
		.cyc(cyc),
		.stb(stb),
		.we(we),
		.sel(),
		.ack(ack),
		.err(1'b0),
		.rty(1'b0)
	);
	wire stb0 = stb & ~adr[3];
	wire stb1 = stb &  adr[3];
	assign dat_i = ({{8'd8}{stb0}} & dat0_i) | ({{8'd8}{stb1}} & dat1_i);
	// hookup wishbone_i2c_master core
	i2c_master_top i2c_top (
		// wishbone interface
		.wb_clk_i(clk),
		.wb_rst_i(1'b0),
		.arst_i(rstn),
		.wb_adr_i(adr[2:0]),
		.wb_dat_i(dat_o),
		.wb_dat_o(dat0_i),
		.wb_we_i(we),
		.wb_stb_i(stb0),
		.wb_cyc_i(cyc),
		.wb_ack_o(ack),
		.wb_inta_o(inta),
		// i2c signals
		.scl_pad_i(scl),
		.scl_pad_o(scl0_o),
		.scl_padoen_o(scl0_oen),
		.sda_pad_i(sda),
		.sda_pad_o(sda0_o),
		.sda_padoen_o(sda0_oen)
	),
	i2c_top2 (
		// wishbone interface
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
		// i2c signals
		.scl_pad_i(scl),
		.scl_pad_o(scl1_o),
		.scl_padoen_o(scl1_oen),
		.sda_pad_i(sda),
		.sda_pad_o(sda1_o),
		.sda_padoen_o(sda1_oen)
	);
// the first i2c master is the one CirFix checked the oracle against, thus it is also the one we want to look at to determine O
`ifdef DUMP_TRACE // used for our OSDD calculations
initial begin
	$dumpfile("test.vcd"); // 波形图输出到test.vcd
	$dumpvars(0, i2c_top);
end
`endif // DUMP_TRACE
	// hookup i2c slave model
	i2c_slave_model #(SADR) i2c_slave (
		.scl(scl),
		.sda(sda)
	);
        // create i2c lines
	delay m0_scl (scl0_oen ? 1'bz : scl0_o, scl),
	      m1_scl (scl1_oen ? 1'bz : scl1_o, scl),
	      m0_sda (sda0_oen ? 1'bz : sda0_o, sda),
	      m1_sda (sda1_oen ? 1'bz : sda1_o, sda);
	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line
	initial begin
		log_file = $fopen("test.txt"); // log输出到test.txt
		$fwrite(log_file, "time,wb_dat_o[7],wb_dat_o[6],wb_dat_o[5],wb_dat_o[4],wb_dat_o[3],wb_dat_o[2],wb_dat_o[1],wb_dat_o[0],wb_ack_o,wb_inta_o,scl_pad_o,scl_padoen_o\n");
		
		forever begin
			@(posedge clk);
			$fwrite(log_file, "%g,%b,%b,%b,%b,%b,%b,%b,%b,%b,%b,%b,%b\n", 
			$time,dat0_i[7],dat0_i[6],dat0_i[5],dat0_i[4],dat0_i[3],dat0_i[2],dat0_i[1],dat0_i[0],ack,inta,scl0_o,scl0_oen);
		end
	end
	initial
	  begin
	      error = 0; // 初始化错误计数
	      `ifdef WAVES
	         $shm_open("waves");
	         $shm_probe("AS",tst_bench_top,"AS");
	         $display("INFO: Signal dump enabled ...\n\n");
	      `endif
	      force i2c_slave.debug = 1'b0; // disable i2c_slave debug information
	      $display("\nstatus: %t Testbench started\n\n", $time);
	      // initially values
	      clk = 0;
		  instrument_clk = 0;
	      // reset system
	      rstn = 1'b1; // negate reset
	      #2;
	      rstn = 1'b0; // assert reset
	      repeat(1) @(posedge clk);
	      rstn = 1'b1; // negate reset
	      $display("status: %t done reset", $time);
	      @(posedge clk);
	      //
	      // program core
	      //
	      // program internal registers
	      u0.wb_write(1, PRER_LO, 8'hfa); // load prescaler lo-byte
	      u0.wb_write(1, PRER_LO, 8'hc8); // load prescaler lo-byte
	      u0.wb_write(1, PRER_HI, 8'h00); // load prescaler hi-byte
	      $display("status: %t programmed registers", $time);
	      u0.wb_cmp(0, PRER_LO, 8'hc8, error); // verify prescaler lo-byte
	      u0.wb_cmp(0, PRER_HI, 8'h00, error); // verify prescaler hi-byte
	      $display("status: %t verified registers", $time);
	      u0.wb_write(1, CTR,     8'h80); // enable core
	      $display("status: %t core enabled", $time);
	      //
	      // access slave (write)
	      //
	      // drive slave address
	      u0.wb_write(1, TXR, {SADR,WR} ); // present slave address, set write-bit
	      u0.wb_write(0, CR,      8'h90 ); // set command (start, write)
	      $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(0, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // send memory address
	      u0.wb_write(1, TXR,     8'h01); // present slave's memory address
	      u0.wb_write(0, CR,      8'h10); // set command (write)
	      $display("status: %t write slave memory address 01", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(0, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // send memory contents
	      u0.wb_write(1, TXR,     8'ha5); // present data
	      u0.wb_write(0, CR,      8'h10); // set command (write)
	      $display("status: %t write data a5", $time);
while (scl) #1;
force scl= 1'b0;
#100000;
release scl;
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // send memory contents for next memory address (auto_inc)
	      u0.wb_write(1, TXR,     8'h5a); // present data
	      u0.wb_write(0, CR,      8'h50); // set command (stop, write)
	      $display("status: %t write next data 5a, generate 'stop'", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // drive slave address
	      u0.wb_write(1, TXR,{SADR,WR} ); // present slave address, set write-bit
	      u0.wb_write(0, CR,     8'h90 ); // set command (start, write)
	      $display("status: %t generate 'start', write cmd %0h (slave address+write)", $time, {SADR,WR} );
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // send memory address
	      u0.wb_write(1, TXR,     8'h01); // present slave's memory address
	      u0.wb_write(0, CR,      8'h10); // set command (write)
	      $display("status: %t write slave address 01", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // drive slave address
	      u0.wb_write(1, TXR, {SADR,RD} ); // present slave's address, set read-bit
	      u0.wb_write(0, CR,      8'h90 ); // set command (start, write)
	      $display("status: %t generate 'repeated start', write cmd %0h (slave address+read)", $time, {SADR,RD} );
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // read data from slave
	      u0.wb_write(1, CR,      8'h20); // set command (read, ack_read)
	      $display("status: %t read + ack", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // check data just received
	      u0.wb_read(1, RXR, qq);
	      if(qq !== 8'ha5) begin
	        $display("\nERROR: Expected a5, received %x at time %t", qq, $time);
	        error = error + 1; // 错误计数+1
	      end else
	        $display("status: %t received %x", $time, qq);
	      // read data from slave
	      u0.wb_write(1, CR,      8'h20); // set command (read, ack_read)
	      $display("status: %t read + ack", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // check data just received
	      u0.wb_read(1, RXR, qq);
	      if(qq !== 8'h5a) begin
	        $display("\nERROR: Expected 5a, received %x at time %t", qq, $time);
	        error = error + 1; // 错误计数+1
	      end else
	        $display("status: %t received %x", $time, qq);
	      // read data from slave
	      u0.wb_write(1, CR,      8'h20); // set command (read, ack_read)
	      $display("status: %t read + ack", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // check data just received
	      u0.wb_read(1, RXR, qq);
	      $display("status: %t received %x from 3rd read address", $time, qq);
	      // read data from slave
	      u0.wb_write(1, CR,      8'h28); // set command (read, nack_read)
	      $display("status: %t read + nack", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // check data just received
	      u0.wb_read(1, RXR, qq);
	      $display("status: %t received %x from 4th read address", $time, qq);
	      u0.wb_write(1, TXR, {SADR,WR} ); // present slave address, set write-bit
	      u0.wb_write(0, CR,      8'h90 ); // set command (start, write)
	      $display("status: %t generate 'start', write cmd %0h (slave address+write). Check invalid address", $time, {SADR,WR} );
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // send memory address
	      u0.wb_write(1, TXR,     8'h10); // present slave's memory address
	      u0.wb_write(0, CR,      8'h10); // set command (write)
	      $display("status: %t write slave memory address 10", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	           u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      // slave should have send NACK
	      $display("status: %t Check for nack", $time);
	      if(!q[7]) begin
	        $display("\nERROR: Expected NACK, received ACK\n");
	        error = error + 1; // 错误计数+1
	      end
	      // read data from slave
	      u0.wb_write(1, CR,      8'h40); // set command (stop)
	      $display("status: %t generate 'stop'", $time);
	      // check tip bit
	      u0.wb_read(1, SR, q);
	      while(q[1])
	      u0.wb_read(1, SR, q); // poll it until it is zero
	      $display("status: %t tip==0", $time);
	      #250000; // wait 250us
	      $display("\n\nstatus: %t Testbench done", $time);
	  end

	// Final result output
	initial begin
		#3000;
		if (error == 0) begin
			$display("=========== Your Design Passed ===========");
			$fwrite(log_file, "=========== Your Design Passed ===========\n");
		end else begin
			$display("=========== Your Design Failed ===========");
		end
		$fclose(log_file); // 关闭日志文件
		$finish;
	end
endmodule

module delay (in, out);
  input  in;
  output out;
  assign out = in;
  specify
    (in => out) = (600,600);
  endspecify
endmodule

// verilator lint_off WIDTHTRUNC
// verilator lint_off CASEINCOMPLETE
module i2c_slave_model (
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
// verilator lint_on WIDTHTRUNC
// verilator lint_on CASEINCOMPLETE

module wb_master_model(clk, rst, adr, din, dout, cyc, stb, we, sel, ack, err, rty);

    parameter dwidth = 32;
    parameter awidth = 32;

    input                  clk, rst;
    output [awidth   -1:0]	adr;
    input  [dwidth   -1:0]	din;
    output [dwidth   -1:0]	dout;
    output                 cyc, stb;
    output       	        	we;
    output [dwidth/8 -1:0] sel;
    input		                ack, err, rty;

    ////////////////////////////////////////////////////////////////////
    //
    // Local Wires
    //

    reg	[awidth   -1:0]	adr;
    reg	[dwidth   -1:0]	dout;
    reg		               cyc, stb;
    reg		               we;
    reg [dwidth/8 -1:0] sel;

    reg [dwidth   -1:0] q;

    ////////////////////////////////////////////////////////////////////
    //
    // Memory Logic
    //

    initial
        begin
            //adr = 32'hxxxx_xxxx;
            //adr = 0;
            adr  = {awidth{1'bx}};
            dout = {dwidth{1'bx}};
            cyc  = 1'b0;
            stb  = 1'bx;
            we   = 1'hx;
            sel  = {dwidth/8{1'bx}};
            #1;
            $display("\nINFO: WISHBONE MASTER MODEL INSTANTIATED (%m)\n");
        end

    ////////////////////////////////////////////////////////////////////
    //
    // Wishbone write cycle
    //

    task wb_write;
        input   delay;
        integer delay;

        input	[awidth -1:0]	a;
        input	[dwidth -1:0]	d;

        begin

            // wait initial delay
            repeat(delay) @(posedge clk);

            // assert wishbone signal
            #1;
            adr  = a;
            dout = d;
            cyc  = 1'b1;
            stb  = 1'b1;
            we   = 1'b1;
            sel  = {dwidth/8{1'b1}};
            @(posedge clk);

            // wait for acknowledge from slave
            while(~ack)	@(posedge clk);

            // negate wishbone signals
            #1;
            cyc  = 1'b0;
            stb  = 1'bx;
            adr  = {awidth{1'bx}};
            dout = {dwidth{1'bx}};
            we   = 1'hx;
            sel  = {dwidth/8{1'bx}};

        end
    endtask

    ////////////////////////////////////////////////////////////////////
    //
    // Wishbone read cycle
    //

    task wb_read;
        input   delay;
        integer delay;

        input	 [awidth -1:0]	a;
        output	[dwidth -1:0]	d;

        begin

            // wait initial delay
            repeat(delay) @(posedge clk);

            // assert wishbone signals
            #1;
            adr  = a;
            dout = {dwidth{1'bx}};
            cyc  = 1'b1;
            stb  = 1'b1;
            we   = 1'b0;
            sel  = {dwidth/8{1'b1}};
            @(posedge clk);

            // wait for acknowledge from slave
            while(~ack)	@(posedge clk);

            // negate wishbone signals
            #1;
            cyc  = 1'b0;
            stb  = 1'bx;
            adr  = {awidth{1'bx}};
            dout = {dwidth{1'bx}};
            we   = 1'hx;
            sel  = {dwidth/8{1'bx}};
            d    = din;

        end
    endtask

    ////////////////////////////////////////////////////////////////////
    //
    // Wishbone compare cycle (read data from location and compare with expected data)
    //

    task wb_cmp;
        input   delay;
        integer delay;

        input [awidth -1:0]	a;
        input	[dwidth -1:0]	d_exp;

		inout integer       error_count;

        begin
            wb_read (delay, a, q);

            if (d_exp !== q)
                $display("Data compare error. Received %h, expected %h at time %t", q, d_exp, $time);
				error_count = error_count + 1;
        end
    endtask

endmodule


