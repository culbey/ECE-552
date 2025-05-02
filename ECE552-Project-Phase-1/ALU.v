module ALU(A, B, Control, rslt, N, Z, V);

input [15:0] A, B; 		// inputs to be ALU'ed -> IMMEDIATES FED THROUGH B
input [2:0] Control;	// need to determine which control does what

output [15:0] rslt;		// ALU output 
output N, Z, V;			// N = Negative, Z = Zero, V = Overflow

/*

ADD 0000		- Simple add (need to use CLA) 	| FLAGS (N,Z,V)
SUB 0001		- Simple sub (need to use CLA) 	| FLAGS	(N,Z,V)
XOR 0010		- Simple XOR					| FLAGS	(Z)
RED 0011		- Use reduction unit			
SLL 0100		- Use shifter where op[1:0] is the mode	| FLAGS (Z)
SRA 0101		- Use shifter where op[1:0] is the mode	| FLAGS (Z)
ROR 0110		- Use shifter where op[1:0] is the mode	| FLAGS (Z)
PADDSB 0111		- Make a PADDSB unit that will use 4 4-bit CLA adders and saturates each result
LW 1000			- Uses the adder to compute mem address
SW 1001			- Uses the adder to compute mem address
LLB 1010		- Needs to perform (A & 0xFF00) | uuuuuuuu
LHB 1011		- Needs to perform (A & 0x00FF) | (uuuuuuuu << 8)
B 1100			- Needs the flags to be set
BR 1101			- Needs the flags to be set
PCS 1110		- May need another control signal to get the value of the PC into the WriteData
HLT 1111		- Does not matter (stops incrementing the PC)

*/


/* ADD (000) & SUB (001) */
wire [15:0] addsub_rslt;
wire overflow;

sat_addsub16 add_sub1(.A(A), .B(B), .sub(Control[0]), .rslt(addsub_rslt), .overflow(overflow));

/* XOR (010) */
wire [15:0] xor_rslt;
assign xor_rslt = A ^ B;

/* RED (011) */
wire [15:0] red_rslt;
RED red1(.A(A), .B(B), .rslt(red_rslt));

/* SLL (100) & SRA (101) & ROR (110) */
wire [15:0] shift_rslt;
Shifter shift1(.Shift_Out(shift_rslt), .Shift_In(A), .Shift_Val(B[3:0]), .Mode(Control[1:0]));

/* PADDSB (111) */
wire [15:0] paddsb_rslt;
PADDSB paddsb1(.A(A), .B(B), .rslt(paddsb_rslt));


assign rslt = 	(Control === 3'b000)	?	addsub_rslt		:	// ADD
				(Control === 3'b001)	?	addsub_rslt		:	// SUB
				(Control === 3'b010)	?	xor_rslt		:	// XOR
				(Control === 3'b011)	?	red_rslt		:	// RED
				(Control === 3'b100)	?	shift_rslt		:	// SLL
				(Control === 3'b101)	?	shift_rslt		:	// SRA
				(Control === 3'b110)	?	shift_rslt		:	// ROR
				paddsb_rslt;									// PADDSB

/* TODO: ONLY UPDATE FLAGS FOR GIVEN INSTRUCTIONS */ 
assign N = rslt[15];
assign Z = (rslt === 16'h0000);
assign V = overflow;

endmodule
