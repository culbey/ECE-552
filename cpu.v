module cpu(
    input clk, 		    // system clock, active low reset - when first on, resets the processor and causes execution to start at address 0x0000
    input rst_n, 
    output hlt, 	    // asserted when the program encounters a hlt instruction - halt
    output [15:0] pc 	// outputs the current pc throughout the execution of the program
);


wire rst;
assign rst = ~rst_n;





wire D_cache_stall, I_cache_stall;
wire [15:0] branch_addr;
wire branch_taken;

/* Signal assigned in Hazard Detection */
wire stall;
wire halt;
wire [3:0] WB_opcode;
assign hlt = halt & (WB_opcode == 4'b1111);
/* Piped Signals */
wire [15:0] D_inc_pc, D_instr;


/* PC REGISTER (16-bits) */
wire [15:0] curr_pc, inc_pc, nxt_pc;
wire [15:0] instr;

assign pc = curr_pc;
wire disable_pc = halt | stall | ( (instr[15:12] == 4'b1111) & ~branch_taken) | I_cache_stall | D_cache_stall;

wire [15:0] flopped_branch;
dff branch_dff [15:0] (.q(flopped_branch), .d(branch_addr), .wen(branch_taken), .clk(clk), .rst(rst));

assign nxt_pc = (branch_taken) ? flopped_branch : inc_pc;

dff pc_reg[15:0] (.q(curr_pc), .d(nxt_pc), .wen(~disable_pc), .clk(clk), .rst(rst));


// /* FETCH INSTRUCTION */
// memory1c_i instr_memory (
//     .data_out(instr),
//     .data_in(/* UNCONNECTED */),
//     .addr(curr_pc),
//     .enable(1'b1),
//     .wr(1'b0),
//     .clk(clk),
//     .rst(rst)
// );

/* Increment PC by 2 */ 
CLA_16bit iADDER1(.A(curr_pc), .B(16'h0002), .Cin(1'b0), .Sum(inc_pc), .Cout(/* UNCONNECTED */) , .overflow(/* UNCONNECTED */));

F_Pipe fetch_pipeline(.inc_pc(inc_pc), .instr(instr), .IF_Flush((branch_taken & ~I_cache_stall) | (I_cache_stall & ~D_cache_stall & ~branch_taken)), .clk(clk), .rst(rst), .inc_pc_pipe(D_inc_pc), .instr_pipe(D_instr), .stall(stall | D_cache_stall | (branch_taken & I_cache_stall)));



/*
*   FETCH STAGE START
*/

/* Signals assigned in Decode */
// wire [15:0] branch_addr;
// wire branch_taken;

// /* Signal assigned in Hazard Detection */
// wire stall;
// wire D_cache_stall, I_cache_stall;
// wire halt;
// wire [3:0] WB_opcode;
// assign hlt = (WB_opcode == 4'b1111);
// /* Piped Signals */
// wire [15:0] D_inc_pc, instr, D_instr;

// /* FETCH STAGE*/
// /* PC REGISTER (16-bits) */
// wire [15:0] inc_pc, curr_pc, nxt_pc, nxt_pipe_pc;

// assign pc = curr_pc;
// wire disable_pc = halt | stall | ( (nxt_pipe_pc[15:12] == 4'b1111) & ~branch_taken) | D_cache_stall | I_cache_stall;

// assign nxt_pc = (branch_taken) ? branch_addr : inc_pc;

// dff pc_reg[15:0] (.q(curr_pc), .d(nxt_pc), .wen(~disable_pc), .clk(clk), .rst(rst));

// /* PC PIPE REGISTER (16-bits) */
// wire [15:0] pipe_pc;

// assign nxt_pipe_pc = (I_cache_stall | halt | D_cache_stall) ? pipe_pc : curr_pc;

// dff pipe_pc_reg[15:0] (.q(pipe_pc), .d(nxt_pipe_pc), .wen(1'b1), .clk(clk), .rst(rst));

// CLA_16bit iADDER1(.A(pipe_pc), .B(16'h0002), .Cin(1'b0), .Sum(D_inc_pc), .Cout(/* UNCONNECTED */) , .overflow(/* UNCONNECTED */));
// CLA_16bit iADDER2(.A(nxt_pipe_pc), .B(16'h0002), .Cin(1'b0), .Sum(inc_pc), .Cout(/* UNCONNECTED */) , .overflow(/* UNCONNECTED */));







/*
*   FETCH STAGE END
*/





/*
ADD HAZARD DETECTION UNIT
*/
wire [1:0] EX_frwrdA, EX_frwrdB;    // 00 - NO forwarding, 01 - MEM-EX forwarding, 10 - EX-EX forwarding
wire mem_mem_frwrd_enable;

/* assigned in decode */
wire [3:0] EX_rt, EX_rs, EX_rd;
wire [3:0] EX_opcode;
wire EX_WriteReg;

/* assigned in EX */
wire [3:0] MEM_rd;
wire [3:0] MEM_opcode;
wire MEM_WriteReg;

hazard_det_frwd u_hazard_det_frwd (
    .EX_WriteReg(EX_WriteReg),
    .MEM_WriteReg(MEM_WriteReg),
    .ccc(D_instr[11:9]),
    .id_rd(D_instr[11:8]),
    .id_rs(D_instr[7:4]),
    .id_rt(D_instr[3:0]),
    .id_op(D_instr[15:12]),
    .ex_rd(EX_rd),
    .ex_rs(EX_rs),
    .ex_rt(EX_rt),
    .ex_op(EX_opcode),
    .mem_rd(MEM_rd),
    .mem_op(MEM_opcode),
    .frwdA(EX_frwrdA),
    .frwdB(EX_frwrdB),
    .mem_to_mem_frwd(mem_mem_frwrd_enable),
    .stall(stall),
    .clk(clk),
    .rst(rst)
);


/*
*
*   DECODE STAGE START
*   TODO:
*   - Set up A and B signals to feed directly to ALU
*       - Update Flag registers if we have an ADD, SUB, XOR, SLL, SRA, ROR
            - I think we will have to perform all of these operations in the decode stage to set the flags
            - Do we want to remove those functions from the ALU and in EX just pass along the result from decode straight to mem for those operations?
*   - Create ID/EX pipeline module
*   - Enable RF bypassing
*
*/

/* FLAG REGISTERS AS {Zero, oVerflow, Negative} */
wire Z, V, N;
wire ALU_Z, ALU_V, ALU_N;
wire EX_NewN, EX_NewV, EX_NewZ;
dff flag_reg[2:0] (.q({Z, V, N}), .d({ALU_Z, ALU_V, ALU_N}), .wen({EX_NewZ & |EX_rd, EX_NewV, EX_NewN}), .clk(clk), .rst(rst));

/* Signals from Write Back */
wire [3:0] WB_rd;
wire [15:0] WB_dstData;
wire WB_WriteReg;

/* Piped Signals */
wire [15:0] EX_inc_pc;
wire [15:0] EX_ALU_A, EX_ALU_B, EX_Src2Data;
wire EX_MemRead, EX_MemWrite, EX_WritePC, EX_LLB, EX_MemtoReg, EX_LoadByte;
wire [2:0] EX_ALUOp;

decode decode_stage (
 .clk(clk),
 .rst(rst),         // insert a NOP into the EX stage if we have a stall
 .nop(stall | (I_cache_stall & branch_taken & ~D_cache_stall)),
 .stall(D_cache_stall),

 .N(N),
 .Z(Z),
 .V(V),

 .inc_pc(D_inc_pc),
 .instr(D_instr),

 .WB_rd(WB_rd),
 .WB_dstData(WB_dstData),
 .WB_WriteReg(WB_WriteReg),

 .branch_addr(branch_addr),
 .branch_taken(branch_taken),

 .ALU_A_pipe(EX_ALU_A),
 .ALU_B_pipe(EX_ALU_B),
 .Src2Data_pipe(EX_Src2Data),
 .rt_pipe(EX_rt),
 .rs_pipe(EX_rs),
 .rd_pipe(EX_rd),
 .inc_pc_pipe(EX_inc_pc),
 .opcode_pipe(EX_opcode),

 .MemRead_pipe(EX_MemRead),
 .MemWrite_pipe(EX_MemWrite),
 .ALUOp_pipe(EX_ALUOp),
 .WritePC_pipe(EX_WritePC),
 .LLB_pipe(EX_LLB),
 .MemtoReg_pipe(EX_MemtoReg),
 .LoadByte_pipe(EX_LoadByte),
 .WriteReg_pipe(EX_WriteReg),

 .NewN_pipe(EX_NewN),
 .NewV_pipe(EX_NewV),
 .NewZ_pipe(EX_NewZ),

 .hlt(halt)

);


/*
*
*   DECODE STAGE END
*
*/




/*
*
*   EXECUTE STAGE START
*   TODO:
*   - Remove Flag assignments from ALU
*   - Create Forwarding Unit
*   - Create EX/MEM pipeline module
*
*/

/* Execute Stage */

/* forwarded signals, CHANGE NAMES */
wire [15:0] MEM_rslt, MEM_Src2Data;
wire [15:0] MEM_inc_pc;
wire MEM_MemRead, MEM_MemWrite, MEM_WritePC, MEM_MemtoReg;


execute_mod execute_stage(
  .clk(clk),
  .rst(rst),
  .stall(D_cache_stall),

  .frwrdA(EX_frwrdA),       // From hazard detection unit
  .frwrdB(EX_frwrdB),       // From hazard detection unit
  .frwrd_A_EX(MEM_rslt),        // Forward from MEM stage
  .frwrd_B_EX(MEM_rslt),        // Forward from MEM stage
  .frwrd_A_MEM(WB_dstData),     // Forward from WB stage
  .frwrd_B_MEM(WB_dstData),     // Forward from WB stage
  
  /* Piped data signals from Decode stage */
  .ALU_A(EX_ALU_A),
  .ALU_B(EX_ALU_B),
  .Src2Data(EX_Src2Data),
  .rd(EX_rd),
  .inc_pc(EX_inc_pc),
  .opcode(EX_opcode),
  
  /* Control signals from Decode stage */
  .MemRead(EX_MemRead),
  .MemWrite(EX_MemWrite),
  .ALUOp(EX_ALUOp),
  .WritePC(EX_WritePC),
  .MemtoReg(EX_MemtoReg),
  .LLB(EX_LLB),
  .LoadByte(EX_LoadByte),
  .WriteReg(EX_WriteReg),
  
  /* Piped outputs to Memory stage */
  .rslt_pipe(MEM_rslt),
  .Src2Data_pipe(MEM_Src2Data),
  .rd_pipe(MEM_rd),
  .inc_pc_pipe(MEM_inc_pc),
  .opcode_pipe(MEM_opcode),
  .MemRead_pipe(MEM_MemRead),
  .MemWrite_pipe(MEM_MemWrite),
  .WritePC_pipe(MEM_WritePC),
  .MemtoReg_pipe(MEM_MemtoReg),
  .WriteReg_pipe(MEM_WriteReg),

  .ALU_N(ALU_N),
  .ALU_Z(ALU_Z),
  .ALU_V(ALU_V)
);




/*
*
*   EXECUTE STAGE END
*
*/

/* CACHE/MEM FSM */
wire memory_data_valid;
wire I_write_data, D_write_data;
wire I_filled, D_filled;
wire I_busy, D_busy;
wire imiss, dmiss;
wire ihit, dhit;

wire [15:0] cache_fill_address;
wire [15:0] mem_out, mem_data_in, WB_mem_out;

wire [15:0] d_cache_in, d_cache_out;
wire [15:0] d_cache_addr;
assign d_cache_addr = (D_busy) ? cache_fill_address : MEM_rslt;

assign mem_data_in = (mem_mem_frwrd_enable) ? WB_mem_out : MEM_Src2Data;
assign d_cache_in = (D_busy) ? mem_out : mem_data_in;

cache_FSM D_cache_FSM (
    .clk(clk),
    .rst(rst),
    .rw(MEM_MemWrite),
    .check(MEM_MemRead | MEM_MemWrite),
    .mem_data_valid(D_write_data),
    .filled(D_filled),
    .addr(d_cache_addr),
    .write_data(d_cache_in),
    .miss(dmiss),
    .hit(dhit),
    .data_out(d_cache_out)
);


wire [15:0] i_cache_in, i_cache_out;
wire [15:0] i_cache_addr;
assign i_cache_addr = (I_busy) ? cache_fill_address : curr_pc;
assign i_cache_in = mem_out;

cache_FSM I_cache_FSM (
    .clk(clk),
    .rst(rst),
    .rw(1'b0),
    .check(~halt),
    .mem_data_valid(I_write_data),
    .filled(I_filled),
    .addr(i_cache_addr),
    .write_data(i_cache_in),
    .miss(imiss),
    .hit(ihit),
    .data_out(i_cache_out)
);

assign instr = i_cache_out; //& {16{ihit}};



wire [15:0] miss_address, memory_in_address;
assign miss_address = ((dmiss & ~I_busy) | D_busy) ? MEM_rslt : curr_pc;

wire all_mem_sent;

cache_fill_FSM u_cache_fill_FSM (
    .clk(clk),
    .rst(rst),
    .dmiss(dmiss),

    .imiss(imiss),
    .miss_address(miss_address),
    .memory_data_valid(memory_data_valid),
    .I_busy(I_busy),
    .D_busy(D_busy),
    .I_write_data(I_write_data),
    .D_write_data(D_write_data),
    .I_filled(I_filled),
    .D_filled(D_filled),
    .memory_in_address(memory_in_address),
    .memory_out_address(cache_fill_address),
    .all_mem_sent(all_mem_sent)
);



wire mem_enable, mem_wr;
wire [15:0] mem_addr;

assign mem_enable = ((I_busy | D_busy) & ~all_mem_sent) | (dhit & MEM_MemWrite & ~imiss);
assign mem_wr = dhit & MEM_MemWrite & ~imiss;

assign mem_addr = (mem_wr) ? MEM_rslt : memory_in_address;  

memory4c u_memory (
    .data_out(mem_out),
    .data_in(mem_data_in),
    .addr(mem_addr),
    .enable(mem_enable),
    .wr(mem_wr),
    .clk(clk),
    .rst(rst),
    .data_valid(memory_data_valid)
);

assign I_cache_stall = ~ihit;
assign D_cache_stall = ((MEM_MemRead | MEM_MemWrite) & ~dhit) | (MEM_MemWrite & dhit & imiss);

/*
*
*   MEM STAGE START
*   TODO:
*   - Create Forwarding Unit
*   - Create MEM/WB pipeline module
*
*/

/* forwarded signals */
wire [15:0] WB_inc_pc, WB_rslt;
wire WB_WritePC, WB_MemtoReg;


memory_mod u_memory_mod(
    .clk(clk),
    .rst(rst),
    .nop(D_cache_stall),

    .rslt(MEM_rslt),
    .rd(MEM_rd),
    .inc_pc(MEM_inc_pc),
    .mem_data(d_cache_out),

    .WritePC(MEM_WritePC),
    .MemtoReg(MEM_MemtoReg),
    .WriteReg(MEM_WriteReg),
	.opcode(MEM_opcode),

    .WritePC_pipe(WB_WritePC),
    .MemtoReg_pipe(WB_MemtoReg),
    .WriteReg_pipe(WB_WriteReg),
    .inc_pc_pipe(WB_inc_pc),
    .rslt_pipe(WB_rslt),
    .mem_data_pipe(WB_mem_out),
    .rd_pipe(WB_rd),
	.opcode_pipe(WB_opcode)

);


/*
*
*   MEM STAGE END
*
*/




/*
*
*   WRITE BACK STAGE START
*   TODO:
*   - Create ID/EX pipeline module
*
*/

assign WB_dstData =    (WB_WritePC)   ?   WB_inc_pc      :
                        (WB_MemtoReg)  ?   WB_mem_out    :
                        WB_rslt;


endmodule

