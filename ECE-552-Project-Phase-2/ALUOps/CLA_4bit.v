module CLA_4bit(A, B, Cin, Sum, Cout, overflow);

  input [3:0] A, B;
  input Cin;
  output [3:0] Sum;
  output Cout;
  output overflow;

  // Generate, Propagate, and Carry Signals
  wire [3:0] G;	// Generate
  wire [3:0] P;	// Propagate
  wire [4:0] C;	// Carry

  // Creation of Generate and Propgate Signals
  assign G = A & B;
  assign P = A ^ B;

  // Calculation of Carry Out Signals
  assign C[0] = Cin;
  assign C[1] = G[0] | (P[0] & C[0]);
  assign C[2] = G[1] | (P[1] & C[1]);
  assign C[3] = G[2] | (P[2] & C[2]);
  assign C[4] = G[3] | (P[3] & C[3]);

  assign Sum = P ^ C[3:0];
  assign Cout = C[4];
  assign overflow = C[3] ^ C[4];    // check if the carry in to the most sig bit is the same as the carry out

endmodule
