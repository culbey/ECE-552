module F_Pipe(
    input [15:0] inc_pc,    // the incremented pc
    input [15:0] instr,     // the fetched instruction
    input IF_Flush,          // signal to flush the pipeline
    input clk,
    input rst,
    input stall,

    output [15:0] inc_pc_pipe,  // piped value of inc_pc
    output [15:0] instr_pipe    // piped value of instr
);

wire clear_pipe;
assign clear_pipe = rst | IF_Flush;

// inc_pc
dff inc_pc_reg[15:0] (.q(inc_pc_pipe), .d(inc_pc), .wen(~stall), .clk(clk), .rst(clear_pipe));

// instr
dff instr_reg[15:0] (.q(instr_pipe), .d(instr), .wen(~stall), .clk(clk), .rst(clear_pipe));


endmodule