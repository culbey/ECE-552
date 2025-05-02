module cpu(
    input clk, 		    // system clock, active low reset - when first on, resets the processor and causes execution to start at address 0x0000
    input rst_n, 
    output hlt, 	    // asserted when the program encounters a hlt instruction - halt
    output [15:0] pc 	// outputs the current pc throughout the execution of the program
);


wire rst;
assign rst = ~rst_n;



/*
*   FETCH STAGE START
*/

/* Signals assigned in Decode */
wire [15:0] branch_addr;
wire branch_taken;

/* Signal assigned in Hazard Detection */
wire stall;
wire halt;
wire [3:0] WB_opcode;
assign hlt = halt & (WB_opcode == 4'b1111);
/* Piped Signals */
wire [15:0] D_inc_pc, D_instr;

/* FETCH STAGE*/
fetch fetch_stage(
    .branch_addr(branch_addr),
    .branch_taken(branch_taken),
    .stall(stall),
    .halt(halt),
    .clk(clk),
    .rst(rst),
    .inc_pc_pipe(D_inc_pc),
    .instr_pipe(D_instr),
	.pc(pc)
);

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
dff flag_reg[2:0] (.q({Z, V, N}), .d({ALU_Z, ALU_V, ALU_N}), .wen({EX_NewZ, EX_NewV, EX_NewN}), .clk(clk), .rst(rst));

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
 .rst(rst | stall),         // insert a NOP into the EX stage if we have a stall

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








/*
*
*   MEM STAGE START
*   TODO:
*   - Create Forwarding Unit
*   - Create MEM/WB pipeline module
*
*/

/* forwarded signals */
wire [15:0] WB_mem_out, WB_inc_pc, WB_rslt;
wire WB_WritePC, WB_MemtoReg;


memory_mod u_memory_mod(
    .clk(clk),
    .rst(rst),
    .mem_to_mem_frwd(mem_mem_frwrd_enable),
    .forwarded_mem(WB_mem_out),
    .rslt(MEM_rslt),
    .Src2Data(MEM_Src2Data),
    .rd(MEM_rd),
    .inc_pc(MEM_inc_pc),
    .MemRead(MEM_MemRead),
    .MemWrite(MEM_MemWrite),
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

