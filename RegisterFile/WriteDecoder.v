module WriteDecoder_4_16(
    input [3:0] RegId,    // 4-bit register ID input
    input       WriteReg,  // Write enable signal
    output [15:0] Wordline // 16-bit wordline output
);
    

wire [15:0] decoded_reg;

Shifter shift_to_onehot2(.Shift_Out(decoded_reg), .Shift_In(16'h0001), .Shift_Val(RegId), .Mode(2'b00));

assign Wordline = (WriteReg & ~|(decoded_reg & 16'h0001)) ? decoded_reg : 16'h0000;		// if the write reg is not enabled then we should not enable any registers

endmodule 