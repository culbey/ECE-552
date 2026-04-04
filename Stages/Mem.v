module memory_mod(
    input clk,
    input rst,
    input nop,

    /* piped data signals from EX_Pipe_Reg */
    input [15:0] rslt,
    input [3:0] rd,
    input [15:0] inc_pc,
    input [15:0] mem_data,

    /* piped control signals from EX_Pipe_Reg */
    input WritePC,      // send to next pipe
    input MemtoReg,     // send to next pipe
    input WriteReg,
	input [3:0] opcode,

    /* output controls to MEM_Pipe_Reg */
    output WritePC_pipe,
    output MemtoReg_pipe,
    output WriteReg_pipe,

    /* output data to MEM_Pipe_Reg */
    output [15:0] inc_pc_pipe,
    output [15:0] rslt_pipe,
    output [15:0] mem_data_pipe,
    output [3:0] rd_pipe,
	output [3:0] opcode_pipe


);


    MEM_Pipe memory_pipeline (
    // Inputs
    .clk(clk),
    .rst(rst | nop),
    .WritePC(WritePC),
    .MemtoReg(MemtoReg),
    .WriteReg(WriteReg),
    .inc_pc(inc_pc),
    .rslt(rslt),
    .mem_data(mem_data),
    .rd(rd),
	.opcode(opcode),

    // Outputs
    .WritePC_pipe(WritePC_pipe),
    .MemtoReg_pipe(MemtoReg_pipe),
    .WriteReg_pipe(WriteReg_pipe),
    .inc_pc_pipe(inc_pc_pipe),
    .rslt_pipe(rslt_pipe),
    .mem_data_pipe(mem_data_pipe),
    .rd_pipe(rd_pipe),
	.opcode_pipe(opcode_pipe)
);





endmodule