module execute_mod(
    input clk,
    input rst,
    input stall,

    /* forwarding signals from forwarding unit */
    input [1:0] frwrdA, frwrdB,
    input [15:0] frwrd_A_EX,
    input [15:0] frwrd_B_EX,
    input [15:0] frwrd_A_MEM,
    input [15:0] frwrd_B_MEM,

    /* piped data signals from D_Pipe_Reg */
    input [15:0] ALU_A,
    input [15:0] ALU_B,
    input [15:0] Src2Data,
    input [3:0] rd,
    input [15:0] inc_pc,
    input [3:0] opcode,

    /* piped control signals from D_Pipe_Reg */
    input MemRead,
    input MemWrite,
    input [2:0] ALUOp,
    input WritePC,
    input MemtoReg,
    input LLB,
    input LoadByte,
    input WriteReg,

    output MemRead_pipe,
    output MemWrite_pipe,
    output WritePC_pipe,
    output MemtoReg_pipe,
    output WriteReg_pipe,
    output [15:0] rslt_pipe,
    output [15:0] Src2Data_pipe,
    output [3:0] rd_pipe,
    output [15:0] inc_pc_pipe,
    output [3:0] opcode_pipe,

    output ALU_N,
    output ALU_V,
    output ALU_Z
);


    wire [15:0] A_ALU0, A_ALU, B_ALU;


    assign A_ALU0 =  (frwrdA === 2'b01)  ?   frwrd_A_MEM     :   // 01 = take A from data mem (MEM)
                    (frwrdA === 2'b10)  ?   frwrd_A_EX      :   // 10 = take A from prev ALU output (EX)
                    ALU_A;                                      // 00 = take A input from D

    assign A_ALU = (MemRead | MemWrite) ? A_ALU0 & 16'hFFFE : A_ALU0;   // clear bit0 for loads and stores

    assign B_ALU =  (frwrdB === 2'b01)  ?   frwrd_B_MEM     :
                    (frwrdB === 2'b10)  ?   frwrd_B_EX      :
                    ALU_B;


    wire [15:0] LoadByteData;
    assign LoadByteData = (LLB) ? ((B_ALU & 16'hFF00) | A_ALU) : ((B_ALU & 16'h00FF) | A_ALU);
    
    wire [15:0] rslt, new_rslt;
    ALU ALU_execute(.A(A_ALU), .B(B_ALU), .Control(ALUOp), .rslt(rslt), .N(ALU_N), .Z(ALU_Z), .V(ALU_V));

    assign new_rslt = (LoadByte) ? LoadByteData : rslt;
        
    EX_Pipe execute_pipeline(
        .en(~stall),
        .clk(clk), 
        .rst(rst), 
        .rslt(new_rslt), 
        .Src2Data(Src2Data),
        .rd(rd), 
        .inc_pc(inc_pc), 
        .opcode(opcode), 
        .MemRead(MemRead),
        .MemWrite(MemWrite), 
        .WritePC(WritePC), 
        .MemtoReg(MemtoReg),
        .WriteReg(WriteReg),
        .rslt_pipe(rslt_pipe), 
        .Src2Data_pipe(Src2Data_pipe), 
        .rd_pipe(rd_pipe),
        .inc_pc_pipe(inc_pc_pipe), 
        .opcode_pipe(opcode_pipe), 
        .MemRead_pipe(MemRead_pipe),
        .MemWrite_pipe(MemWrite_pipe), 
        .WritePC_pipe(WritePC_pipe), 
        .MemtoReg_pipe(MemtoReg_pipe),
        .WriteReg_pipe(WriteReg_pipe)
    );


endmodule