module control_sig(
    input [3:0] opcode,
    output reg B,
    output reg BR,
    output reg MemRead,
    output reg [2:0] ALUOp,
    output reg MemWrite,
    output reg MemtoReg,
    output reg ALUSrc,
    output reg WritePC,
    output reg WriteReg,
    output reg NewN,
    output reg NewV,
    output reg NewZ,
    output reg Halt,
    output reg LoadByte, // HLB or LLB instr
    output reg LLB
);

    always @(*) begin
        B = 1'b0;
	    BR = 1'b0;
        MemRead = 1'b0;
        ALUOp = 3'b000;
        MemWrite  = 1'b0;
	    MemtoReg = 1'b0;
        ALUSrc = 1'b0;
        WritePC = 1'b0;
        WriteReg = 1'b0;
        NewN = 1'b0;
        NewV = 1'b0;
        NewZ = 1'b0;
        Halt = 1'b0;
	    LoadByte = 1'b0;
    	LLB = 1'b0;

        case (opcode)
            // ADD - Simple add (need to use CLA) | FLAGS (N,Z,V)
            4'b0000: begin
                NewN = 1'b1;
                NewV = 1'b1;
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
		    end

            // SUB 0001	- Simple sub (need to use CLA) | FLAGS (N,Z,V)
            4'b0001: begin
                NewN = 1'b1;
                NewV = 1'b1;
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
		    end
	
            // XOR 0010	- Simple XOR | FLAGS (Z)
            4'b0010: begin
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
		    end		

            // RED 0011 - Use reduction unit		
            4'b0011: begin
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
		    end

            // SLL 0100 - Use shifter where op[1:0] is the mode	| FLAGS (Z)
            4'b0100: begin
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
                ALUSrc = 1'b1;
		    end		

            // SRA 0101 - Use shifter where op[1:0] is the mode	| FLAGS (Z)
            4'b0101: begin
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
                ALUSrc = 1'b1;
		    end
		

            // ROR 0110 - Use shifter where op[1:0] is the mode	| FLAGS (Z)
            4'b0110: begin
                NewZ = 1'b1;
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
                ALUSrc = 1'b1;
		    end


            // PADDSB 0111 - Make a PADDSB unit that will use 4 4-bit CLA adders and saturates each result
            4'b0111: begin
                ALUOp = opcode[2:0];
                WriteReg = 1'b1;
		    end		

            // LW 1000 - Uses the adder to compute mem address, stores to reg
            4'b1000: begin
                WriteReg = 1'b1;
                MemRead = 1'b1;
                ALUOp = opcode[2:0];
                ALUSrc = 1'b1;
                MemtoReg = 1'b1;
		    end		

            // SW 1001 - Uses the adder to compute mem address, stores to mem
            4'b1001: begin
                MemWrite = 1'b1;
                ALUOp = 3'b000;	// ADD
                ALUSrc = 1'b1;
		    end

            // LLB 1010	- Needs to perform (A & 0xFF00) | uuuuuuuu
            4'b1010: begin
                WriteReg = 1'b1;
                ALUSrc = 1'b1;
		        LoadByte = 1'b1;
    		    LLB = 1'b1;
		    end
            // LHB 1011	- Needs to perform (A & 0x00FF) | (uuuuuuuu << 8)
            4'b1011: begin
                WriteReg = 1'b1;
                ALUSrc = 1'b1;
		        LoadByte = 1'b1;
		    end

            // B 1100 - Needs the flags to be set
            4'b1100: begin
                B = 1'b1;
		    end

            // BR 1101 - Needs the flags to be set
            4'b1101: begin
		        BR = 1'b1;
		    end

            // PCS 1110 - May need another control signal to get the value of the PC into the WriteData
            4'b1110: begin
                WritePC = 1'b1;
                WriteReg = 1'b1;
		    end

            // HLT 1111	- Does not matter (stops incrementing the PC)
            default:
                Halt = 1'b1;

        endcase
	end

endmodule