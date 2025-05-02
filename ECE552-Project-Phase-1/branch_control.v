module branch_control(
    input [11:0] instr,  // lowest 11 bits of instruction contain ccc and imm
    input Z,  // from flag registers [Z, V, N]
    input V,
    input N,
    input B, // if B instruction (need to calc offset)
    input BR, // if BR (new PC must be reg contents)
    input [15:0] read_data, // from RegFile
    input [15:0] PC_in, // curr PC
    output [15:0] PC_out    // new PC (needs to be normal for PCS)
);


    wire [2:0] F;
    assign F = {Z, V, N};

    wire [8:0] offset;
    assign offset = B ? instr[8:0] : 9'h000;

    wire [2:0] C;
    assign C = instr[11:9];
	wire [15:0] PC_B;


    PC_control branch_taker(.C(C), .I(offset), .F(F), .PC_in(PC_in), .PC_out(PC_B));

    assign PC_out = BR ? read_data : PC_B;



endmodule