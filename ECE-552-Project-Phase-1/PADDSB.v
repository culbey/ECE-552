module PADDSB(A, B, rslt);

input [15:0] A, B;

output [15:0] rslt;

sat_addsub4 paddsb[3:0](.A(A), .B(B), .sub(1'b0), .rslt(rslt));

endmodule
