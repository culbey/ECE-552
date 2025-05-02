module sat_addsub4(A, B, sub, rslt);

input [3:0] A, B;	// operands
input sub;

output [3:0] rslt;

wire [3:0] sum;
wire overflow;

CLA_4bit addsub4(.A(A), .B(B ^ {4{sub}}), .Cin(sub), .Sum(sum), .Cout(), .overflow(overflow));

assign rslt = (overflow) ? ( (A[3]) ? 4'h8 : 4'h7 ) : sum;		// if overflow was detected, saturate to whichever side A is


endmodule
