module PC_control(
    input [2:0] C,  // cond codes in instr
    input [8:0] I,  // immediate val of instr
    input [2:0] F,  // from flag registers [Z, V, N]
    input [15:0] PC_in, // curr PC
    output [15:0] PC_out    // new PC (needs to be normal for PCS)
);

    wire [15:0] incr_PC;
    wire [15:0] offset_PC;
    wire [15:0] branch_offset;
    wire condition_met;

    wire Z;
    wire V;
    wire N;

    assign Z = F[2];
    assign V = F[1];
    assign N = F[0];

    assign condition_met =  (C === 3'b000) ?  ~Z              :   // Not Equal
                            (C === 3'b001) ?  Z               :   // Equal
                            (C === 3'b010) ?  ~Z & ~N         :   // Greater Than
                            (C === 3'b011) ?  N               :   // Less Than
                            (C === 3'b100) ?  Z | (~Z & ~N)   :     // Greater Than or Equal
                            (C === 3'b101) ?  N | Z	          :   // Less Than or Equal
                            (C === 3'b110) ?  V            	  :   // Overflow
                            1'b1;		                            // Unconditional


    CLA_16bit iADDER1(.A(PC_in), .B(16'h0002), .Cin(1'b0), .Sum(incr_PC), .Cout() , .overflow());

    assign branch_offset = {{6{I[8]}}, I[8:0], 1'b0};
    CLA_16bit iADDER2(.A(incr_PC), .B(branch_offset), .Cin(1'b0), .Sum(offset_PC), .Cout() , .overflow());

    assign PC_out = condition_met ? offset_PC : incr_PC;


endmodule