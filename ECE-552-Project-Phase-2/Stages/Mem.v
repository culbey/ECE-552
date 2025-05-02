module memory_mod(
    input clk,
    input rst,

    /* forwarding signals */
    input mem_to_mem_frwd,
    input [15:0] forwarded_mem,

    /* piped data signals from EX_Pipe_Reg */
    input [15:0] rslt,
    input [15:0] Src2Data,
    input [3:0] rd,
    input [15:0] inc_pc,

    /* piped control signals from EX_Pipe_Reg */
    input MemRead,      // only for R/W
    input MemWrite,     // only for data memory enable, R/W
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


    wire [15:0] d_mem_out;
    wire enable;
    wire [15:0] mem_data_in;
    assign enable = MemWrite | MemRead;
    assign mem_data_in = (mem_to_mem_frwd) ? forwarded_mem : Src2Data;
    
    memory1c data_memory(.data_out(d_mem_out), .data_in(mem_data_in), .addr(rslt), .enable(enable), .wr(MemWrite), .clk(clk), .rst(rst));

    MEM_Pipe memory_pipeline (
    // Inputs
    .clk(clk),
    .rst(rst),
    .WritePC(WritePC),
    .MemtoReg(MemtoReg),
    .WriteReg(WriteReg),
    .inc_pc(inc_pc),
    .rslt(rslt),
    .mem_data(d_mem_out),
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