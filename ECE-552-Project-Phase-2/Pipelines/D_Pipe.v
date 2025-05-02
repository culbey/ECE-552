module D_Pipe(
    input clk,
    input rst,

    input NewN,
    input NewV,
    input NewZ,

    output NewN_pipe,
    output NewV_pipe,
    output NewZ_pipe,

    input [15:0] ALU_A,       // piped value of ALU A input OR Immediate value for LHB/LLB
    input [15:0] ALU_B,       // piped value of ALU B input
    input [15:0] Src2Data,    // piped value of Src2Data from read port 2
    output [3:0] rt,           // piped rt register value for determining EX-EX forwarding (instr[3:0])
    output [3:0] rs,           // piped rs register value for determining EX-EX forwarding (instr[7:4])
    input [3:0] rd,           // piped rd register value for the current instruction (instr[11:8])
    input [15:0] inc_pc,      // piped value of inc_pc
    input [3:0] opcode,       // piped opcode for current instruction

    input MemRead,
    input MemWrite,
    input [2:0] ALUOp,
    input WritePC,
    input LLB,
    input MemtoReg,
    input LoadByte,
	input WriteReg,

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
	output WriteReg_pipe

);


dff ALU_A_reg[15:0] (.q(ALU_A_pipe), .d(ALU_A), .wen(1'b1), .clk(clk), .rst(rst));
dff ALU_B_reg[15:0] (.q(ALU_B_pipe), .d(ALU_B), .wen(1'b1), .clk(clk), .rst(rst));
dff Src2Data_reg[15:0] (.q(Src2Data_pipe), .d(Src2Data), .wen(1'b1), .clk(clk), .rst(rst));
dff rt_reg[3:0] (.q(rt_pipe), .d(rt), .wen(1'b1), .clk(clk), .rst(rst));
dff rs_reg[3:0] (.q(rs_pipe), .d(rs), .wen(1'b1), .clk(clk), .rst(rst));
dff rd_reg[3:0] (.q(rd_pipe), .d(rd), .wen(1'b1), .clk(clk), .rst(rst));
dff inc_pc_reg[15:0] (.q(inc_pc_pipe), .d(inc_pc), .wen(1'b1), .clk(clk), .rst(rst));
dff opcode_reg[3:0] (.q(opcode_pipe), .d(opcode), .wen(1'b1), .clk(clk), .rst(rst));

dff MemRead_reg (.q(MemRead_pipe), .d(MemRead), .wen(1'b1), .clk(clk), .rst(rst));
dff MemWrite_reg (.q(MemWrite_pipe), .d(MemWrite), .wen(1'b1), .clk(clk), .rst(rst));
dff ALUOp_reg[2:0] (.q(ALUOp_pipe), .d(ALUOp), .wen(1'b1), .clk(clk), .rst(rst));
dff WritePC_reg (.q(WritePC_pipe), .d(WritePC), .wen(1'b1), .clk(clk), .rst(rst));
dff LLB_reg (.q(LLB_pipe), .d(LLB), .wen(1'b1), .clk(clk), .rst(rst));
dff MemtoReg_reg (.q(MemtoReg_pipe), .d(MemtoReg), .wen(1'b1), .clk(clk), .rst(rst));
dff LoadByte_reg (.q(LoadByte_pipe), .d(LoadByte), .wen(1'b1), .clk(clk), .rst(rst));
dff WriteReg_reg (.q(WriteReg_pipe), .d(WriteReg), .wen(1'b1), .clk(clk), .rst(rst));
dff NewN_reg (.q(NewN_pipe), .d(NewN), .wen(1'b1), .clk(clk), .rst(rst));
dff NewZ_reg (.q(NewZ_pipe), .d(NewZ), .wen(1'b1), .clk(clk), .rst(rst));
dff NewV_reg (.q(NewV_pipe), .d(NewV), .wen(1'b1), .clk(clk), .rst(rst));



endmodule