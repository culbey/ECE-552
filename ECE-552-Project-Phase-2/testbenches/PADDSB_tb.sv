module PADDSB_tb();

logic [15:0] A, B;
logic [15:0] rslt;

PADDSB DUT(.A(A), .B(B), .rslt(rslt));


logic [15:0] expected;
logic signed [4:0] a_ex, b_ex, c_ex, d_ex;
assign {a_ex, b_ex, c_ex, d_ex} = { $signed({A[15], A[15:12]}) + $signed({B[15], B[15:12]}),
                                    $signed({A[11], A[11:8]}) + $signed({B[11], B[11:8]}),
                                    $signed({A[7], A[7:4]}) + $signed({B[7], B[7:4]}),
                                    $signed({A[3], A[3:0]}) + $signed({B[3], B[3:0]}) };

logic [3:0] ax, bx, cx, dx;
assign ax = (a_ex > 7) ? 4'h7 : (a_ex < -8) ? 4'h8 : a_ex;
assign bx = (b_ex > 7) ? 4'h7 : (b_ex < -8) ? 4'h8 : b_ex;
assign cx = (c_ex > 7) ? 4'h7 : (c_ex < -8) ? 4'h8 : c_ex;
assign dx = (d_ex > 7) ? 4'h7 : (d_ex < -8) ? 4'h8 : d_ex;

assign expected = {ax , bx, cx, dx};


initial begin

A = 0;
B = 0;

#5;

for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end


end




$display("YAHOO! All tests passed!");
$stop;


end




endmodule
