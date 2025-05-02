module MEM_Pipe(
    input clk,
    input rst,

    input WritePC,
    input MemtoReg,
    input WriteReg,
    input [15:0] inc_pc,
    input [15:0] rslt,
    input [15:0] mem_data,
    input [3:0] rd,
	input [3:0] opcode,

    output WritePC_pipe,
    output MemtoReg_pipe,
    output WriteReg_pipe,

    output [15:0] inc_pc_pipe,
    output [15:0] rslt_pipe,
    output [15:0] mem_data_pipe,
    output [3:0] rd_pipe,
	output [3:0] opcode_pipe

);

    // control
    dff WritePC_reg (.q(WritePC_pipe), .d(WritePC), .wen(1'b1), .clk(clk), .rst(rst));
    dff MemtoReg_reg (.q(MemtoReg_pipe), .d(MemtoReg), .wen(1'b1), .clk(clk), .rst(rst));
    dff WriteReg_reg (.q(WriteReg_pipe), .d(WriteReg), .wen(1'b1), .clk(clk), .rst(rst));
    
    // data
    dff inc_pc_reg[15:0] (.q(inc_pc_pipe), .d(inc_pc), .wen(1'b1), .clk(clk), .rst(rst));
    dff rslt_reg[15:0] (.q(rslt_pipe), .d(rslt), .wen(1'b1), .clk(clk), .rst(rst));
    dff mem_data_reg[15:0] (.q(mem_data_pipe), .d(mem_data), .wen(1'b1), .clk(clk), .rst(rst));
    dff rd_reg[3:0] (.q(rd_pipe), .d(rd), .wen(1'b1), .clk(clk), .rst(rst));
	dff opcode_reg[3:0] (.q(opcode_pipe), .d(opcode), .wen(1'b1), .clk(clk), .rst(rst));


endmodule