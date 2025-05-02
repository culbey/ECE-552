/*
Module to convert immed bits to whatever is needed.
*/
module immediate_decoder(
    input [3:0] opcode,
    input [7:0] immed,
    output [15:0] ALUInput         // to B input of main ALU
);

    // 0100, 0101, 0110
    // if SLL, SRA, ROR: take bottom 4 as immed, pass into ALU for B

    // 1000, 1001
    // if LW, SW: pass sign_extend(lower 4) << 1 as B

    // 1010, 1011
    // if LLB, LHB: either bottom 8, or bottom 8 << 8

	assign ALUInput =   (opcode[3] === 1'b0)    ?   {{12{1'b0}}, immed[3:0]}    :   // shift instr to feed alu
						(opcode[1] & opcode[0]) ?   {immed[7:0], {8{1'b0}}}     :   // LHB
                        (opcode[1])             ?   {{8{1'b0}}, immed[7:0]}     :   // LLB
                        {{11{immed[3]}}, immed[3:0], 1'b0};                         // LW OR SW


endmodule