module CLA_16bit(A, B, Cin, Sum, Cout, overflow);

  input [15:0] A, B; 
  input Cin; 
  output [15:0] Sum;
  output Cout;
  output overflow;

  wire [3:0] C;	// Carry Out Signals

  // Instantiation of 4 bit CLAs  
  CLA_4bit iADD0(.A(A[3:0]), .B(B[3:0]), .Cin(Cin), .Sum(Sum[3:0]), .Cout(C[0]), .overflow());        // We dont care if it overflows until the last 4bit CLA
  CLA_4bit iADD1(.A(A[7:4]), .B(B[7:4]), .Cin(C[0]), .Sum(Sum[7:4]), .Cout(C[1]), .overflow());
  CLA_4bit iADD2(.A(A[11:8]), .B(B[11:8]), .Cin(C[1]), .Sum(Sum[11:8]), .Cout(C[2]), .overflow());
  CLA_4bit iADD3(.A(A[15:12]), .B(B[15:12]), .Cin(C[2]), .Sum(Sum[15:12]), .Cout(Cout), .overflow(overflow));

endmodule
