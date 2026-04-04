module decode(
    input [15:0] inc_pc,    // incremented pc
    input [15:0] instr,     // current instruction

    input [3:0] WB_rd,          // rd for WB stage's register file write
    input [15:0] WB_dstData,    // data from WB stage to be written to reg file
    input WB_WriteReg,          // whether WB stage is doing a reg write

    input clk,
    input rst,
    input nop,
    input stall,

    input N,             
    input Z,
    input V,

    output [15:0] branch_addr,      // the address produced by branch control
    output branch_taken,            // 1 if there is a branch and the branch is taken

    output [15:0] ALU_A_pipe,       // piped value of ALU A input OR Immediate value for LHB/LLB
    output [15:0] ALU_B_pipe,       // piped value of ALU B input
    output [15:0] Src2Data_pipe,    // piped value of Src2Data from read port 2
    output [3:0] rt_pipe,           // piped rt register value for determining EX-EX forwarding (instr[3:0])
    output [3:0] rs_pipe,           // piped rs register value for determining EX-EX forwarding (instr[7:4])
    output [3:0] rd_pipe,           // piped rd register value for the current instruction (instr[11:8])
    output [15:0] inc_pc_pipe,      // piped value of inc_pc
    output [3:0] opcode_pipe,       // piped opcode for current instruction

    /* Piped signals */
    output MemRead_pipe,
    output MemWrite_pipe,
    output [2:0] ALUOp_pipe,
    output WritePC_pipe,
    output LLB_pipe,
    output MemtoReg_pipe,
    output LoadByte_pipe,
    output WriteReg_pipe,

    output NewN_pipe,
    output NewV_pipe,
    output NewZ_pipe,
	output hlt
);


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

assign hlt = Halt;
/* Signals for decode stage */
wire [7:0] Imm;
wire [3:0] Src1, Src2;
wire [3:0] opcode;
wire [3:0] rt, rs, rd;

assign opcode = instr[15:12];
assign Src1 = instr[7:4];
assign Src2 = (LoadByte | MemWrite) ? instr[11:8] : instr[3:0];
assign rt = instr[3:0];
assign rs = instr[7:4];
assign rd = instr[11:8];
assign Imm = instr[7:0];

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


/* IMMEDIATE DECODER - FOR SHIFT, LHB, LLB, LW, SW */
wire [15:0] ALUInput;
immediate_decoder decode_imm(
    .opcode(opcode),
    .immed(Imm),
    .ALUInput(ALUInput)         // to B input of main ALU
);



/* REGISTER FILE */
wire [15:0] Src1Data, Src2Data;
RegisterFile registers(
	.clk(clk), 
	.rst(rst), 
	.SrcReg1(Src1), 
	.SrcReg2(Src2), 
	.DstReg(WB_rd), 
	.WriteReg(WB_WriteReg), 
	.DstData(WB_dstData), 
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
    .PC_in(inc_pc),             // next PC
    .PC_out(branch_addr),         // PC for branch
    .IF_Flush(branch_taken)
);


/* D PIPELINE */
wire [15:0] ALU_A, ALU_B;
assign ALU_A = (LoadByte) ? ALUInput : Src1Data;
assign ALU_B = (ALUSrc) ? ALUInput : Src2Data;
D_Pipe decode_pipeline(
 .en(~stall),
 .clk(clk),
 .rst(rst | nop),

 .NewN(NewN),
 .NewZ(NewZ),
 .NewV(NewV),

 .ALU_A(ALU_A),
 .ALU_B(ALU_B),
 .Src2Data(Src2Data),
 .rt(rt),
 .rs(rs),
 .rd(rd),
 .inc_pc(inc_pc),
 .opcode(opcode),

 .MemRead(MemRead),
 .MemWrite(MemWrite),
 .ALUOp(ALUOp),
 .WritePC(WritePC),
 .LLB(LLB),
 .MemtoReg(MemtoReg),
 .LoadByte(LoadByte),
 .WriteReg(WriteReg),

 .ALU_A_pipe(ALU_A_pipe),
 .ALU_B_pipe(ALU_B_pipe),
 .Src2Data_pipe(Src2Data_pipe),
 .rt_pipe(rt_pipe),
 .rs_pipe(rs_pipe),
 .rd_pipe(rd_pipe),
 .inc_pc_pipe(inc_pc_pipe),
 .opcode_pipe(opcode_pipe),

 .MemRead_pipe(MemRead_pipe),
 .MemWrite_pipe(MemWrite_pipe),
 .ALUOp_pipe(ALUOp_pipe),
 .WritePC_pipe(WritePC_pipe),
 .LLB_pipe(LLB_pipe),
 .MemtoReg_pipe(MemtoReg_pipe),
 .LoadByte_pipe(LoadByte_pipe),
 .WriteReg_pipe(WriteReg_pipe),

 .NewN_pipe(NewN_pipe),
 .NewZ_pipe(NewZ_pipe),
 .NewV_pipe(NewV_pipe)
);




endmodule