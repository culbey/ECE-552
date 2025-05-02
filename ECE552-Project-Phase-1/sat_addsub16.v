module sat_addsub16(A, B, sub, rslt, overflow);

input [15:0] A, B;	// operands
input sub;			// 1 if subtract, 0 if add

output [15:0] rslt;
output overflow;

wire [15:0] sum;	// the sum before saturation

CLA_16bit addsub16(.A(A), .B(B ^ {16{sub}}), .Cin(sub), .Sum(sum), .Cout(), .overflow(overflow));	// if sub=1, then ~B and add 1 for the carry in

assign rslt = (overflow) ? ( (A[15]) ? 16'h8000 : 16'h7FFF ) : sum;		// if overflow was detected, saturate to whichever side A is

endmodule
