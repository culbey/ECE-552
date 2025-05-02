module cpu(
    input clk, 		    // system clock, active low reset - when first on, resets the processor and causes execution to start at address 0x0000
    input rst_n, 
    output hlt, 	    // asserted when the program encounters a hlt instruction - halt
    output [15:0] pc	// outputs the current pc throughout the execution of the program
);


wire rst;
assign rst = ~rst_n;

/* CONTROL SIGNALS */
wire B;              // branch instruction
wire BR;             // BR instruction
wire MemRead;        // Signal to read memory
wire [2:0] ALUOp;    // ALU Control signal
wire MemWrite;       // Signal to write to memory
wire MemtoReg;       // signal for mem read to reg write
wire ALUSrc;         // Control what is input to ALU's B
wire WritePC;        // Write incremented PC value to register
wire WriteReg;       // signal when a register is being written
wire NewN;           // signal to load new N flag
wire NewV;           // signal to laod new V flag
wire NewZ;           // signal to load new Z flag
wire Halt;           // signal for HLT instruction
wire LoadByte;       // HLB or LLB instr
wire LLB;            // LLB?


/* PC REGISTER (16-bits) */
wire [15:0] curr_pc, nxt_pc;
dff pc_reg[15:0] (.q(curr_pc), .d(nxt_pc), .wen(~Halt), .clk(clk), .rst(rst));

/* FLAG REGISTERS AS {Zero, oVerflow, Negative} */
wire Z, V, N;
wire ALU_Z, ALU_V, ALU_N;
dff flag_reg[2:0] (.q({Z, V, N}), .d({ALU_Z, ALU_V, ALU_N}), .wen({NewZ, NewV, NewN}), .clk(clk), .rst(rst));

/* FETCH INSTRUCTION */
wire [15:0] instr;
wire [7:0] Imm;
wire [3:0] opcode, Src1, Src2, Dst;
assign opcode = instr[15:12];
assign Src1 = instr[7:4];
assign Src2 = (LoadByte | MemWrite) ? instr[11:8] : instr[3:0];
assign Dst = instr[11:8];
assign Imm = instr[7:0];
memory1c_i instr_memory (
    .data_out(instr),
    .data_in(/* UNCONNECTED */),
    .addr(curr_pc),
    .enable(1'b1),
    .wr(1'b0),
    .clk(clk),
    .rst(rst)
);


/* IMMEDIATE DECODER - FOR SHIFT, HLB, LLB, LW, SW */
wire [15:0] ALUInput;
immediate_decoder decode_imm(
    .opcode(opcode),
    .immed(Imm),
    .ALUInput(ALUInput)         // to B input of main ALU
);


/* CONTROL SIGNAL ASSIGNMENT */
control_sig control_signals(
    .opcode(opcode),
    .B(B),
    .BR(BR),
    .MemRead(MemRead),
    .ALUOp(ALUOp),
    .MemWrite(MemWrite),
    .MemtoReg(MemtoReg),
    .ALUSrc(ALUSrc),
    .WritePC(WritePC),
    .WriteReg(WriteReg),
    .NewN(NewN),
    .NewV(NewV),
    .NewZ(NewZ),
    .Halt(Halt),
    .LoadByte(LoadByte),
    .LLB(LLB)
);


/* REGISTER FILE */
wire [15:0] DstData;
wire [15:0] Src1Data, Src2Data;
RegisterFile registers(
	.clk(clk), 
	.rst(rst), 
	.SrcReg1(Src1), 
	.SrcReg2(Src2), 
	.DstReg(Dst), 
	.WriteReg(WriteReg), 
	.DstData(DstData), 
	.SrcData1(Src1Data), 
	.SrcData2(Src2Data)
);

/* BRANCH CONTROL */
branch_control branch(
    .instr(instr[11:0]),    // lowest 11 bits of instruction contain ccc and imm
    .Z(Z),                  // from flag registers [Z, V, N]
    .V(V),
    .N(N),
    .B(B),                      // if B instruction (need to calc offset)
    .BR(BR),                    // if BR (new PC must be reg contents)
    .read_data(Src1Data),       // from RegFile
    .PC_in(curr_pc),            // curr PC
    .PC_out(nxt_pc)             // new PC (needs to be normal for PCS)
);


/* ALU */
wire [15:0] ALU_A, ALU_B;
wire [15:0] ALUrslt;
assign ALU_A = (MemRead | MemWrite) ? Src1Data & 16'hFFFE : Src1Data;
assign ALU_B = (ALUSrc) ? ALUInput : Src2Data;
ALU alu(
    .A(ALU_A),              // A operand
    .B(ALU_B),              // B operand
    .Control(ALUOp),    // ALU control signal to determine which operation
    .rslt(ALUrslt),     // rslt from the ALU
    .N(ALU_N),          // The resulting N flag from the operation
    .Z(ALU_Z),          // resulting Z flag from the operation
    .V(ALU_V)           // resulting V flag from the operation
);


/* DATA MEMORY */
wire dMemEnable, dMemWR; 
wire [15:0] dMemOut;
assign dMemEnable = MemRead | MemWrite;
assign dMemWR = MemWrite;
memory1c data_memory (
    .data_out(dMemOut),
    .data_in(Src2Data),
    .addr(ALUrslt),
    .enable(dMemEnable),
    .wr(dMemWR),
    .clk(clk),
    .rst(rst)
);


/* REGISTER FILE WRITE BACK */
wire [15:0] LoadByteConst, LoadedByte;
assign LoadByteConst = (LLB) ? 16'hFF00 : 16'h00FF;
assign LoadedByte = (Src2Data & LoadByteConst) | ALUInput;

assign DstData =    (LoadByte)  ?   LoadedByte  :   // get the updated value from either load upper bytes or lower bytes
                    (WritePC)   ?   nxt_pc      :   // get the next pc value for pcs
                    (MemtoReg)  ?   dMemOut     :   // take the output from data memory
                    ALUrslt;                        // take alu result

assign hlt = Halt;
assign pc = curr_pc;


endmodule
