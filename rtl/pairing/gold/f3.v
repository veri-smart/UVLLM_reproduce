module f3_add (
    A,
    B,
    C
);
  input [1:0] A, B;
  output [1:0] C;
  wire a0, a1, b0, b1, c0, c1;
  assign {a1, a0} = A;
  assign {b1, b0} = B;
  assign C = {c1, c0};
  assign c0 = (a0 & ~a1 & ~b0 & ~b1) | (~a0 & ~a1 & b0 & ~b1) | (~a0 & a1 & ~b0 & b1);
  assign c1 = (~a0 & a1 & ~b0 & ~b1) | (a0 & ~a1 & b0 & ~b1) | (~a0 & ~a1 & ~b0 & b1);
endmodule

module f3_sub (
    A,
    B,
    C
);
  input [1:0] A, B;
  output [1:0] C;
  f3_add m1 (
      A,
      {B[0], B[1]},
      C
  );
endmodule

module f3_mult (
    A,
    B,
    C
);
  input [1:0] A;
  input [1:0] B;
  output [1:0] C;
  wire a0, a1, b0, b1;
  assign {a1, a0} = A;
  assign {b1, b0} = B;
  assign C[0] = (~a1 & a0 & ~b1 & b0) | (a1 & ~a0 & b1 & ~b0);
  assign C[1] = (~a1 & a0 & b1 & ~b0) | (a1 & ~a0 & ~b1 & b0);
endmodule

module f3_add1 (
    a,
    c
);
  input [1:0] a;
  output [1:0] c;
  assign c[0] = (~a[0]) & (~a[1]);
  assign c[1] = a[0] & (~a[1]);
endmodule

module f3_sub1 (
    a,
    c
);
  input [1:0] a;
  output [1:0] c;
  assign c[0] = (~a[0]) & a[1];
  assign c[1] = (~a[0]) & (~a[1]);
endmodule
