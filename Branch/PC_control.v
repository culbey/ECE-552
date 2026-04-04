module PC_control(
    input [2:0] C,  // cond codes in instr
    input [8:0] I,  // immediate val of instr
    input [2:0] F,  // from flag registers [Z, V, N]
    input [15:0] PC_in, // next PC
    output [15:0] PC_out,    // new PC (needs to be normal for PCS)
    output condition_met   // if the condition is met
);

    wire [15:0] branch_offset;

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



    assign branch_offset = {{6{I[8]}}, I[8:0], 1'b0};
    CLA_16bit iADDER2(.A(PC_in), .B(branch_offset), .Cin(1'b0), .Sum(PC_out), .Cout() , .overflow());


endmodule