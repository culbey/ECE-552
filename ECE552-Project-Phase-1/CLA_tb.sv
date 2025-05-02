module CLA_tb();

logic [15:0] Sum, A, B, Bin;
logic overflow, Cin, Cout;

CLA_16bit CLA16DUT(.A(A), .B(Bin), .Cin(Cin), .Sum(Sum), .Cout(Cout), .overflow(overflow));

logic signed [16:0] Sum_expected;

assign Sum_expected =  (Cin) ? $signed(A) - $signed(B) : $signed(A) + $signed(B);


initial begin

A = 0;
B = 0;
Cin = 0;

#5;

for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);
	Bin = B;

	#5;

// CHECK FULL
	if ( ($signed(Sum_expected) > $signed(16'h7FFF) || Sum_expected < $signed(16'h8000)) && ~overflow) begin
		$display("should be overflow");
		$stop;
	end
	else if (~overflow && (Sum_expected[15:0] !== Sum) ) begin
		$display("Sums are not the same.");
		$stop;
	end


end


Cin = 1;

#5;

for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);
	Bin = ~B;
	

	#5;

// CHECK SUB
	if ( ($signed(Sum_expected) > $signed(16'h7FFF) || Sum_expected < $signed(16'h8000)) && ~overflow) begin
		$display("should be overflow");
		$stop;
	end
	else if (~overflow && (Sum_expected[15:0] !== Sum) ) begin
		$display("Sums are not the same.");
		$stop;
	end


end

$display("YAHOO! All tests passed.");
$stop;



end


endmodule

