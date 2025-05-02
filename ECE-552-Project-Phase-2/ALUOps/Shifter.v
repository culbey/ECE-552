module Shifter(Shift_Out, Shift_In, Shift_Val, Mode);

input [15:0] Shift_In; 	// This is the input data to perform shift operation on
input [3:0] Shift_Val; 	// Shift amount (used to shift the input data)
input [1:0] Mode; 		// To indicate 00=SLL, 01=SRA, 10=ROR

output [15:0] Shift_Out; // Shifted output data



wire [15:0] shift8, shift4, shift2;


assign shift8 =		( Shift_Val[3] & (Mode == 2'b00) )	?	Shift_In << 8'h8						:	// logical shift left
					( Shift_Val[3] & (Mode == 2'b01) ) 	?	{{8{Shift_In[15]}}, Shift_In[15:8]}		:	// arithmetic shift right
					( Shift_Val[3] & (Mode == 2'b10) ) 	?	{Shift_In[7:0], Shift_In[15:8]}			:	// right rotate
					Shift_In;

assign shift4 =		( Shift_Val[2] & (Mode == 2'b00) )	?	shift8 << 4'h4						:	// logical shift left
					( Shift_Val[2] & (Mode == 2'b01) ) 	?	{{4{shift8[15]}}, shift8[15:4]}		:	// arithmetic shift right
					( Shift_Val[2] & (Mode == 2'b10) ) 	?	{shift8[3:0], shift8[15:4]}			:	// right rotate
					shift8;


assign shift2 =		( Shift_Val[1] & (Mode == 2'b00) )	?	shift4 << 2'h2						:	// logical shift left
					( Shift_Val[1] & (Mode == 2'b01) ) 	?	{{2{shift4[15]}}, shift4[15:2]}		:	// arithmetic shift right
					( Shift_Val[1] & (Mode == 2'b10) ) 	?	{shift4[1:0], shift4[15:2]}			:	// right rotate
					shift4;

assign Shift_Out =	( Shift_Val[0] & (Mode == 2'b00) )	?	shift2 << 1'h1						:	// logical shift left
					( Shift_Val[0] & (Mode == 2'b01) ) 	?	{shift2[15], shift2[15:1]}			:	// arithmetic shift right
					( Shift_Val[0] & (Mode == 2'b10) ) 	?	{shift2[0], shift2[15:1]}			:	// right rotate
					shift2;


endmodule

