module fetch(
    input [15:0] branch_addr,   // address computed for branch instr
    input branch_taken,         // signal from branch control
    input stall,                // signal from hazard detection
    input halt,                 // signal to halt and stop pc inc
    input clk,
    input rst,
	
	output [15:0] pc,
    output [15:0] inc_pc_pipe,  // piped value of inc_pc
    output [15:0] instr_pipe    // piped value of instr
);

/* PC REGISTER (16-bits) */
wire [15:0] curr_pc, inc_pc, nxt_pc;
wire [15:0] instr;

assign pc = curr_pc;
wire disable_pc = halt | stall | ( (instr[15:12] == 4'b1111) & ~branch_taken);

assign nxt_pc = (branch_taken) ? branch_addr : inc_pc;

dff pc_reg[15:0] (.q(curr_pc), .d(nxt_pc), .wen(~disable_pc), .clk(clk), .rst(rst));


/* FETCH INSTRUCTION */
memory1c_i instr_memory (
    .data_out(instr),
    .data_in(/* UNCONNECTED */),
    .addr(curr_pc),
    .enable(1'b1),
    .wr(1'b0),
    .clk(clk),
    .rst(rst)
);

/* Increment PC by 2 */ 
CLA_16bit iADDER1(.A(curr_pc), .B(16'h0002), .Cin(1'b0), .Sum(inc_pc), .Cout(/* UNCONNECTED */) , .overflow(/* UNCONNECTED */));

F_Pipe fetch_pipeline(.inc_pc(inc_pc), .instr(instr), .IF_Flush(branch_taken), .clk(clk), .rst(rst), .inc_pc_pipe(inc_pc_pipe), .instr_pipe(instr_pipe), .stall(stall));

endmodule