

module fsm_full
(
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
  reg [2:0] state;
  reg [2:0] next_state;

  always @(state, req_0, req_1, req_2, req_3) begin
    case(state)
      IDLE: if(req_0) next_state = GNT0;
            else if(req_1) next_state = GNT1;
            else if(req_2) next_state = GNT2;
            else if(req_3) next_state = GNT3;
            else next_state = IDLE;
      GNT0: next_state = req_0 ? GNT0 : IDLE;
      GNT1: next_state = req_1 ? GNT1 : IDLE;
      GNT2: next_state = req_2 ? GNT2 : IDLE;
      GNT3: next_state = req_3 ? GNT3 : IDLE;
      default: next_state = IDLE;
    endcase
  end


  always @(posedge clock) begin
  if (reset) begin
    state <= IDLE;
    gnt_0 <= 1'b0;
    gnt_1 <= 1'b0;
    gnt_2 <= 1'b0;
    gnt_3 <= 1'b0;
  end else begin
    state <= next_state;
    case(next_state)
        IDLE: begin
          gnt_0 <= 1'b0;
          gnt_1 <= 1'b0;
          gnt_2 <= 1'b0;
          gnt_3 <= 1'b0;
        end
        GNT0: begin
          gnt_0 <= 1'b1;
          gnt_1 <= 1'b0;
          gnt_2 <= 1'b0;
          gnt_3 <= 1'b0;
        end
        GNT1: begin
          gnt_0 <= 1'b0;
          gnt_1 <= 1'b1;
          gnt_2 <= 1'b0;
          gnt_3 <= 1'b0;
        end
        GNT2: begin
          gnt_0 <= 1'b0;
          gnt_1 <= 1'b0;
          gnt_2 <= 1'b1;
          gnt_3 <= 1'b0;
        end
        GNT3: begin
          gnt_0 <= 1'b0;
          gnt_1 <= 1'b0;
          gnt_2 <= 1'b0;
          gnt_3 <= 1'b1;
        end
        default: begin
          gnt_0 <= 1'b0;
          gnt_1 <= 1'b0;
          gnt_2 <= 1'b0;
          gnt_3 <= 1'b0;
        end
      endcase
    end
  end


endmodule

