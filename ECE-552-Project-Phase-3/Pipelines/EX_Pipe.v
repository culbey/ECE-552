module EX_Pipe(
  input en,
  input clk,
  input rst,
  input [15:0] rslt,
  input [15:0] Src2Data,
  input [3:0] rd,
  input [15:0] inc_pc,
  input [3:0] opcode,
  input MemRead,
  input MemWrite,
  input WritePC,
  input MemtoReg,
  input WriteReg,

  output [15:0] rslt_pipe,
  output [15:0] Src2Data_pipe,
  output [3:0] rd_pipe,
  output [15:0] inc_pc_pipe,
  output [3:0] opcode_pipe,
  output MemRead_pipe,
  output MemWrite_pipe,
  output WritePC_pipe,
  output MemtoReg_pipe,
  output WriteReg_pipe
);


  dff rslt_reg[15:0] (.q(rslt_pipe), .d(rslt), .wen(en), .clk(clk), .rst(rst));
  dff Src2Data_reg[15:0] (.q(Src2Data_pipe), .d(Src2Data), .wen(en), .clk(clk), .rst(rst));
  dff rd_reg[3:0] (.q(rd_pipe), .d(rd), .wen(en), .clk(clk), .rst(rst));
  dff inc_pc_reg[15:0] (.q(inc_pc_pipe), .d(inc_pc), .wen(en), .clk(clk), .rst(rst));
  dff opcode_reg[3:0] (.q(opcode_pipe), .d(opcode), .wen(en), .clk(clk), .rst(rst));
  dff MemRead_reg (.q(MemRead_pipe), .d(MemRead), .wen(en), .clk(clk), .rst(rst));
  dff MemWrite_reg (.q(MemWrite_pipe), .d(MemWrite), .wen(en), .clk(clk), .rst(rst));
  dff WritePC_reg (.q(WritePC_pipe), .d(WritePC), .wen(en), .clk(clk), .rst(rst));
  dff MemtoReg_reg (.q(MemtoReg_pipe), .d(MemtoReg), .wen(en), .clk(clk), .rst(rst));
  dff WriteReg_reg (.q(WriteReg_pipe), .d(WriteReg), .wen(en), .clk(clk), .rst(rst));
endmodule