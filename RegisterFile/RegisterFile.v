module RegisterFile(
	input clk, 
	input rst, 
	input [3:0] SrcReg1, 
	input [3:0] SrcReg2, 
	input [3:0] DstReg, 
	input WriteReg, 
	input [15:0] DstData, 
	inout [15:0] SrcData1, 
	inout [15:0] SrcData2
);


wire [15:0] read_reg1, read_reg2, write_reg1;

ReadDecoder_4_16 read_decoder1(.RegId(SrcReg1), .Wordline(read_reg1));		// will produce a one-hot enable for the 16 register's -> bitcell's tristate enables (ie. 0x0001 will set the enable for all bitcells tristate1 for reg 1)
ReadDecoder_4_16 read_decoder2(.RegId(SrcReg2), .Wordline(read_reg2));		// same thing but for tristate2

WriteDecoder_4_16 write_decoder1(.RegId(DstReg), .WriteReg(WriteReg), .Wordline(write_reg1));	// will produce a one-hot enable for the 16 registers to write. If WriteReg is not enabled then it will return 0x0000.


//Register regs[15:0] (.clk(clk), .rst(rst), .D({{15{DstData}}, 16'h0000}), .WriteReg(write_reg1), .ReadEnable1(read_reg1), .ReadEnable2(read_reg2), .Bitline1(SrcData1), .Bitline2(SrcData2));


// enable bypass
wire [15:0] bypass1, bypass2;

Register regs[15:0] (.clk(clk), .rst(rst), .D({{15{DstData}}, 16'h0000}), .WriteReg(write_reg1), .ReadEnable1(read_reg1), .ReadEnable2(read_reg2), .Bitline1(bypass1), .Bitline2(bypass2));

assign SrcData1 = ( write_reg1 == read_reg1 )	?	DstData	: bypass1;
assign SrcData2 = ( write_reg1 == read_reg2 )	?	DstData	: bypass2;

endmodule

