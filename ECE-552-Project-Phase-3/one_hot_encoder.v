module one_hot_encoder_64(Shift_Out, Shift_Val);

input [5:0] Shift_Val; 	// Shift amount (used to shift the input data)

output [63:0] Shift_Out; // Shifted output data

wire [63:0] stage0, stage1, stage2, stage3, stage4, stage5;


assign stage0 = 64'b1;

// Shift by 32 if Shift_Val[5] is set
assign stage1 = Shift_Val[5] ? (stage0 << 32) : stage0;

// Shift by 16 if Shift_Val[4] is set
assign stage2 = Shift_Val[4] ? (stage1 << 16) : stage1;

// Shift by 8 if Shift_Val[3] is set
assign stage3 = Shift_Val[3] ? (stage2 << 8) : stage2;

// Shift by 4 if Shift_Val[2] is set
assign stage4 = Shift_Val[2] ? (stage3 << 4) : stage3;

// Shift by 2 if Shift_Val[1] is set
assign stage5 = Shift_Val[1] ? (stage4 << 2) : stage4;

// Shift by 1 if Shift_Val[0] is set
assign Shift_Out = Shift_Val[0] ? (stage5 << 1) : stage5;


endmodule


module one_hot_encoder_8(Shift_Out, Shift_Val);

input [2:0] Shift_Val; 	// Shift amount (used to shift the input data)

output [7:0] Shift_Out; // Shifted output data

wire [7:0] stage0, stage3, stage4, stage5;


assign stage0 = 64'b1;


// Shift by 4 if Shift_Val[2] is set
assign stage4 = Shift_Val[2] ? (stage0 << 4) : stage0;

// Shift by 2 if Shift_Val[1] is set
assign stage5 = Shift_Val[1] ? (stage4 << 2) : stage4;

// Shift by 1 if Shift_Val[0] is set
assign Shift_Out = Shift_Val[0] ? (stage5 << 1) : stage5;


endmodule