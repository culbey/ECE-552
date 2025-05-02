module RED_tb;

  // Testbench signals
  logic [15:0] A, B;
  logic [15:0] rslt;

  // Instantiate RED module
  RED uut (
    .A(A),
    .B(B),
    .rslt(rslt)
  );


logic signed [15:0] expected;

//assign expected = $signed($signed(A[15:12]) + $signed(B[15:12])) + $signed($signed(A[11:8]) + $signed(B[11:8])) + $signed($signed(A[7:4]) + $signed(B[7:4])) + $signed($signed(A[3:0]) + $signed(B[3:0]));
//assign expected[6:0] = (A[15:12] + B[15:12]) + (A[11:8] + B[11:8]) + (A[7:4] + B[7:4]) + (A[3:0] + B[3:0]);
//assign expected[15:7] = {9{expected[6]}};


logic [4:0] ae, bf, cg, dh;
assign ae = ($signed(A[15:12]) + $signed(B[15:12]));
assign bf = $signed(A[11:8]) + $signed(B[11:8]);
assign cg = $signed(A[7:4]) + $signed(B[7:4]);
assign dh = $signed(A[3:0]) + $signed(B[3:0]);

logic signed [5:0] s1, s2;
assign s1 = $signed(ae) + $signed(bf);
assign s2 = $signed(cg) + $signed(dh);

logic signed [6:0] s;
assign s = $signed(s1) + $signed(s2);


/*
assign bf = (A[11:8] + B[11:8]);
assign cg = (A[7:4] + B[7:4]);
assign dh = (A[3:0] + B[3:0]);

logic [5:0] s1, s2;
assign s1 = ae + bf;
assign s2 = cg + dh;

logic [6:0] s;
assign s = s1 + s2;
*/

assign expected = $signed(s);



initial begin

A = 0;
B = 0;

#5;

for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== $signed(rslt) ) begin
		$display("wrong");
		$stop;
	end


end




$display("YAHOO! All tests passed!");
$stop;

end


endmodule
