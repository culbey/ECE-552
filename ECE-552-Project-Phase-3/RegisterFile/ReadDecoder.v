module ReadDecoder_4_16(
    input [3:0] RegId,
    output [15:0] Wordline
);

Shifter shift_to_onehot1(.Shift_Out(Wordline), .Shift_In(16'h0001), .Shift_Val(RegId), .Mode(2'b00));
    
endmodule
