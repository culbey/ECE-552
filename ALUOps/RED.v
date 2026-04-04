module RED(A, B, rslt);

input [15:0] A, B;		// A: aaaa_bbbb_cccc_dddd	B: eeee_ffff_gggg_hhhh

/* rslt = [ (aaaa+eeee) + (bbbb+ffff) + (cccc+gggg) + (dddd+hhhh) ]
Will use a tree of 4-bit CLA adders where:
Level 1: 4-bits (aaaa)
Level 2: 5-bits	(aaaa+eeee)
Level 3: 6-bits	(5-bit + 5-bit)
Level 4: 7-bits	(6-bit + 6-bit)
*/
output [15:0] rslt;		// sign extended result of above operation


wire [4:0] sum_ae, sum_bf, sum_cg, sum_dh;
wire [3:0] ovfl;

CLA_4bit level1adders[3:0](.A(A), .B(B), .Cin(1'b0), .Sum({sum_ae[3:0], sum_bf[3:0], sum_cg[3:0], sum_dh[3:0]}), .Cout({sum_ae[4], sum_bf[4], sum_cg[4], sum_dh[4]}), .overflow(ovfl));



wire [7:0] ae, bf, cg, dh;
assign ae = (ovfl[3]) 	? { {3{sum_ae[4]}}, sum_ae} 	: { {4{sum_ae[3]}}, sum_ae[3:0] };
assign bf = (ovfl[2]) 	? { {3{sum_bf[4]}}, sum_bf} 	: { {4{sum_bf[3]}}, sum_bf[3:0] };
assign cg = (ovfl[1]) 	? { {3{sum_cg[4]}}, sum_cg} 	: { {4{sum_cg[3]}}, sum_cg[3:0] };
assign dh = (ovfl[0]) 	? { {3{sum_dh[4]}}, sum_dh} 	: { {4{sum_dh[3]}}, sum_dh[3:0] };

wire [7:0] sum_half1, sum_half2;
wire cout_half1, cout_half2;
wire _unused;
CLA_4bit level2adders[3:0](.A({ae, cg}), .B({bf, dh}), .Cin({ cout_half1 , 1'b0, cout_half2, 1'b0 }), .Sum({sum_half1, sum_half2}), .Cout({ /*unused*/ _unused , cout_half1, /*unused*/ _unused, cout_half2 }), .overflow());


wire [7:0] sum;
wire cout_sum;
CLA_4bit level3adders[1:0](.A(sum_half1), .B(sum_half2), .Cin({cout_sum, 1'b0}), .Sum(sum), .Cout({ _unused, cout_sum }), .overflow());


assign rslt = { {9{sum[6]}}, sum[6:0] };

/*
wire [7:0] sum_ae, sum_bf, sum_cg, sum_dh;
wire ovfl;

CLA_4bit level1adders[3:0](.A(A), .B(B), .Cin(1'b0), .Sum({sum_ae[3:0], sum_bf[3:0], sum_cg[3:0], sum_dh[3:0]}), .Cout({sum_ae[4], sum_bf[4], sum_cg[4], sum_dh[4]}), .overflow(ovfl));

assign sum_ae[7:5] = (ovfl) ? 3'b000;
assign sum_bf[7:5] = 3'b000;
assign sum_cg[7:5] = 3'b000;
assign sum_dh[7:5] = 3'b000;

wire [7:0] sum_half1, sum_half2;
wire cout_half1, cout_half2;
wire _unused;

*/
//CLA_4bit level2adders[3:0](.A({sum_ae, sum_cg}), .B({sum_bf, sum_dh}), .Cin({ cout_half1 , 1'b0, cout_half2, 1'b0 }), .Sum({sum_half1, sum_half2}), .Cout({ /*unused*/ _unused , cout_half1, /*unused*/ _unused, cout_half2 }), .overflow());

/*
wire [7:0] sum;
wire cout_sum;
CLA_4bit level3adders[1:0](.A(sum_half1), .B(sum_half2), .Cin({cout_sum, 1'b0}), .Sum(sum), .Cout({ _unused, cout_sum }), .overflow());


assign rslt = { {9{sum[6]}}, sum[6:0] };
*/

endmodule
