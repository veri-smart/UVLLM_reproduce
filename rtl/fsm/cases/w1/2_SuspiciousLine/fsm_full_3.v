module fsm_full (
    input clock,
    input reset,
    input req_0,
    input req_1,
    input req_2,
    input req_3,
    output reg gnt_0,
    output reg gnt_1,
    output reg gnt_2,
    output reg gnt_3
);


  parameter [2:0] IDLE = 3'b000;
  parameter [2:0] GNT0 = 3'b001;
  parameter [2:0] GNT1 = 3'b010;
  parameter [2:0] GNT2 = 3'b011;
  parameter [2:0] GNT3 = 3'b100;

  reg [2:0] state, next_state;

  always @(*) begin
    next_state = 0;
    case (state)
      IDLE:
      if (req_0 == 1'b1) begin
        next_state = GNT0;
      end else if (req_1 == 1'b1) begin
        next_state = GNT1;
      end else if (req_2 == 1'b1) begin
        next_state = GNT2;
      end else if (req_3 == 1'b1) begin
        next_state = GNT3;
      end else begin
        next_state = IDLE;
      end
      GNT0:
      if (req_0 == 1'b0) begin
        next_state = IDLE;
      end else begin
        next_state = GNT0;
      end
      GNT1:
      if (req_1 == 1'b0) begin
        next_state = IDLE;
      end else begin
        next_state = GNT1;
      end
      GNT2:
      if (req_2 == 1'b0) begin
        next_state = IDLE;
      end else begin
        next_state = GNT2;
      end
      GNT3:
      if (req_3 == 1'b0) begin
        next_state = IDLE;
      end else begin
        next_state = GNT3;
      end
      default: next_state = IDLE;
    endcase
  end

  always @(posedge clock) begin : OUTPUT_LOGIC
    if (reset) begin
      if (state == IDLE) gnt_0 <= 1'b0;
      if (state == IDLE) gnt_1 <= 1'b0;
      if (state == IDLE) gnt_2 <= 1'b0;
      if (state == IDLE) gnt_3 <= 1'b0;
      state <= IDLE;
    end else begin
      state <= next_state;
      if (state == IDLE) gnt_0 <= 1'b0;
      if (state == IDLE) gnt_1 <= 1'b0;
      if (state == IDLE) gnt_2 <= 1'b0;
      if (state == IDLE) gnt_3 <= 1'b0;
      case (state)
        GNT0: gnt_0 <= 1'b1;
        GNT1: gnt_1 <= 1'b1;
        GNT2: gnt_2 <= 1'b1;
        GNT3: gnt_3 <= 1'b1;
        default: ;
      endcase
    end
  end

endmodule
