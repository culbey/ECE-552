module hazard_det_frwd(
    input MEM_WriteReg,
    input EX_WriteReg,
    input [2:0] ccc,    // condition codes for a branch

    input [3:0] id_rd,  // ID stage rd
    input [3:0] id_rs,  // ID stage rs
    input [3:0] id_rt,  // ID stage rt
    input [3:0] id_op,  // ID stage op
    input [3:0] ex_rd,  // EX stage rd
    input [3:0] ex_rs,  // EX stage rs
    input [3:0] ex_rt,  // EX stage rt
    input [3:0] ex_op,  // EX stage op
    input [3:0] mem_rd, // MEM stage rd
    input [3:0] mem_op, // MEM stage op
    output [1:0] frwdA, // Forwarding control for A input for ALU (EX-MEM & EX-EX) (00 - No forwarding, 01 - MEM-EX, 10 - EX-EX)
    output [1:0] frwdB, // Forwarding control for B input for ALU (EX-MEM & EX-EX) (00 - No forwarding, 01 - MEM-EX, 10 - EX-EX)
    output mem_to_mem_frwd, // Fowrading control for MEM stage (MEM-MEM)
    output stall, // Stall signal for control unit

    input clk, // Clock signal
    input rst // Reset signal
);

    wire [1:0] nxtfrwdA, nxtfrwdB; // Next values for forwarding control signals
    wire nxtmem_to_mem_frwd; // Next value for MEM-MEM forwarding control signal
    

    // Define opcodes as parameters for better readability
    localparam ADD = 4'b0000;    // ADD opcode
    localparam SUB = 4'b0001;    // SUB opcode
    localparam XOR = 4'b0010;    // XOR opcode
    localparam RED = 4'b0011;    // Sum and sign-extend half-bytes opcode
    localparam SLL = 4'b0100;    // Shift Logical Left opcode
    localparam SRA = 4'b0101;    // Shift Arithmetic Right opcode
    localparam ROR = 4'b0110;    // Rotate Right opcode
    localparam PADDSB = 4'b0111; // Parallel saturated half-byte additions opcode
    localparam LW = 4'b1000;     // Load Word opcode
    localparam SW = 4'b1001;     // Store Word opcode
    localparam LLB = 4'b1010;    // Load Lower byte opcode
    localparam LHB = 4'b1011;    // Load Higher byte opcode
    localparam B = 4'b1100;      // Branch opcode
    localparam BR = 4'b1101;     // Branch Register opcode
    
    /*
    * Hazard Detection Unit  
    * - Detects hazards in the pipeline and generates stalls
    * - Stalls pipeline if EX.opcode is a load and ID stage has a dependent instruction
    * - Checks for (EX.rd = ID.rs) for ID.opcode = ADD, SUB, PADDSB, XOR, RED, SLL, SRA, ROR, LW, SW, BR
    * - Checks for (EX.rd = ID.rt) for ID.opcode = ADD, SUB, PADDSB, XOR, RED
    * - Also should stall for MEM.opcode is a load (MEM.rd = ID.rs) for ID.opcode = BR  
    */


    /* ADD detection for LLB and LHB */

    // Determine which ID stage instructions dpend on rs
    wire id_uses_rs = (id_op == ADD) | (id_op == SUB) | (id_op == PADDSB) | (id_op == XOR) | 
                      (id_op == RED) | (id_op == SLL) | (id_op == SRA) | (id_op == ROR) | 
                      (id_op == LW) | (id_op == SW);

    // Determine which ID stage instructions depend on rt
    wire id_uses_rt = (id_op == ADD) | (id_op == SUB) | (id_op == PADDSB) | (id_op == XOR) | 
                      (id_op == RED);

    // Determine which ID stage instructions depend on rd
    wire id_uses_rd = (id_op == LLB) | (id_op == LHB);


    // Checks for load hazards (EX stage)
    wire ex_is_load = (ex_op == LW);
    wire ex_rd_matches_id_rs = (ex_rd == id_rs) & (ex_rd != 4'b0000);
    wire ex_rd_matches_id_rt = (ex_rd == id_rt) & (ex_rd != 4'b0000);
    wire ex_rd_matches_id_rd = (ex_rd == id_rd) & (ex_rd != 4'b0000);

    // For BR instructions if the register needed for BR is being written to in the future, we have to stall until it reaches WB since there is no forwarding to ID
    wire wait_for_BR = (id_op == BR) & ( (MEM_WriteReg & (mem_rd == id_rs)) | (EX_WriteReg & (ex_rd == id_rs)) );


    // For branches if the instruction currently in EX computes a flag, then we need to wait for the flags to be ready

    wire ex_computing_NV = ((ex_op == ADD) | (ex_op == SUB)) & (ex_rd != 4'b0000);
    wire ex_computing_Z = ((ex_op == XOR) | (ex_op == SLL) | (ex_op == SRA) | (ex_op == ROR) | (ex_op == ADD) | (ex_op == SUB)) & (ex_rd != 4'b0000);

    wire needs_N = (ccc == 3'b010) | (ccc == 3'b011) | (ccc == 3'b100) | (ccc == 3'b101);
    wire needs_Z = (ccc == 3'b000) | (ccc == 3'b001) | (ccc == 3'b010) | (ccc == 3'b100) | (ccc == 3'b101);
    wire needs_V = (ccc == 3'b110);


    wire wait_for_flags = ((id_op == B) | (id_op == BR)) & ( (needs_N & ex_computing_NV) | (needs_V & ex_computing_NV) | (needs_Z & ex_computing_Z) );
    
    // Perform stall detection
    // Stall if 
    // 1. EX stage is load AND
    // 2. ex.rd matches ID.rs/rt AND
    // 3. correct ID instruction is used
    assign stall = (ex_is_load & ((ex_rd_matches_id_rs & id_uses_rs) |
                          (ex_rd_matches_id_rt & id_uses_rt)  |
                          (ex_rd_matches_id_rd & id_uses_rd))) |
            		(wait_for_BR) | (wait_for_flags);


    /*
    * Forwarding Logic 
    * - Fowarding Used is EX-to-EX, MEM-to-EX, and MEM-to-MEM
    * - Fowarding is done whenever EX.rd and ID.(rs/rt/rd) match or
    * - Fowarding is done whenever MEM.rd and EX.(rt/rd) match 
    */

    ///////////////////////////////////////////////
    /* frwdA & frwdB (EX-EX & MEM-EX forwarding) */
    ///////////////////////////////////////////////


    // forward A if:
    // id uses rs and rs matches ex.rd or mem.rd and rd is not 0 and the rd is a regwrite

    /*
    forward B if:
    id uses rt and rs matches ex.rd or mem.rd and rd is not 0 and rd is a regwrite
    or
    id uses rd (for load byte) and matches ex.rd or mem.rd and rd is not 0 and rd is a regwrite
    */



    wire EX_EX_frwrdA, EX_EX_frwrdB, MEM_EX_frwrdA, MEM_EX_frwrdB;
    assign EX_EX_frwrdA =   (id_uses_rs) & 
                            ( (id_rs == ex_rd) & EX_WriteReg ) &
                            (id_rs != 4'b0000);

    assign MEM_EX_frwrdA =  (id_uses_rs) & 
                            ( (id_rs == mem_rd) & MEM_WriteReg ) &
                            (id_rs != 4'b0000) &
                            ~EX_EX_frwrdA;

    assign EX_EX_frwrdB =   ( ( id_uses_rt & ( (id_rt == ex_rd) & EX_WriteReg ) & (id_rt != 4'b0000) ) |
                            ( id_uses_rd & ( (id_rd == ex_rd) & EX_WriteReg ) & (id_rd != 4'b0000) ));


    assign MEM_EX_frwrdB =  ~EX_EX_frwrdB & 
                            ( ( id_uses_rt & ( (id_rt == mem_rd) & MEM_WriteReg ) & (id_rt != 4'b0000) ) |
                            ( id_uses_rd & ( (id_rd == mem_rd) & MEM_WriteReg ) & (id_rd != 4'b0000) ));


    assign nxtfrwdA =   {EX_EX_frwrdA, MEM_EX_frwrdA};
    assign nxtfrwdB =   {EX_EX_frwrdB, MEM_EX_frwrdB};

    /*
    
     flop frwd signals before output so that they will align with the correct cycle 
     
     */ 
 

    // Update frwdA and frwdB with the next values
    dff iFRWDA[1:0] (.q(frwdA), .d(nxtfrwdA), .wen(1'b1), .clk(clk), .rst(rst));
    dff iFRWDB[1:0] (.q(frwdB), .d(nxtfrwdB), .wen(1'b1), .clk(clk), .rst(rst));


    //////////////////////////////////////////
    /* mem_to_mem_frwd (MEM-MEM forwarding) */
    //////////////////////////////////////////

    /* if ex.op = SW and mem.op = LW and ex.rd (11:8) = mem.rd */
    assign nxtmem_to_mem_frwd = ( (ex_op === SW) & (mem_op === LW) & (ex_rd === mem_rd) & (mem_rd !== 4'b0000) );


    // Update mem_to_mem_frwd with the next value
    dff iMEMFRWD(.q(mem_to_mem_frwd), .d(nxtmem_to_mem_frwd), .wen(1'b1), .clk(clk), .rst(rst));
    

endmodule