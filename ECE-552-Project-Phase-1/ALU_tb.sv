module ALU_tb();

logic [15:0] A, B, rslt;
logic N, Z, V;
logic [2:0] Control;

ALU ALU_DUT(.A(A), .B(B), .Control(Control), .rslt(rslt), .N(N), .Z(Z), .V(V));



logic signed [15:0] expected;
logic signed [15:0] add, sub, xxor, red, sll, sra, ror, paddsb;


// EXPECTED ADD
logic signed [16:0] add_x, sub_x;
assign add_x = $signed(A) + $signed(B);
assign add = (add_x > 16'sh7FFF) ? 16'h7FFF : (add_x < 16'sh8000) ? 16'h8000 : add_x;

// EXPECTED SUB
assign sub_x = $signed(A) - $signed(B);
assign sub = (sub_x > 16'sh7FFF) ? 16'h7FFF : (sub_x < 16'sh8000) ? 16'h8000 : sub_x;

// EXPECTED XOR
assign xxor = A ^ B;

// EXPECTED RED
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
assign red = $signed(s);

// EXPECTED SLL
assign sll = A << B[3:0];

// EXPECTED SRA
assign sra = $signed(A) >>> B[3:0];

// EXPECTED ROR
assign ror = (A >> B[3:0]) | (A << (16 - B[3:0]));

// EXPECTED PADDSB
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

assign paddsb = {ax , bx, cx, dx};


// EXPECTED RSLT WITH CONTROL
assign expected = 	(Control === 3'b000)	?	add		:	// ADD
					(Control === 3'b001)	?	sub		:	// SUB
					(Control === 3'b010)	?	xxor	:	// XOR
					(Control === 3'b011)	?	red		:	// RED
					(Control === 3'b100)	?	sll		:	// SLL
					(Control === 3'b101)	?	sra		:	// SRA
					(Control === 3'b110)	?	ror		:	// ROR
					paddsb;									// PADDSB


// EXPECTED FLAGS
logic N_ex, Z_ex, V_ex;
assign N_ex = (expected < 0) ? 1'b1 : 1'b0;
assign Z_ex = (expected === 16'h0000) ? 1'b1 : 1'b0;
assign V_ex = ( (add_x != $signed(add) && Control === 3'b000) || (sub_x != $signed(sub) && Control === 3'b001) ) ? 1'b1 : 1'b0;


initial begin


A = 0;
B = 0;

#5;

// TEST ADD
Control = 0;
for (integer i = 0; i < 20000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end
	if (V_ex !== V) begin
		$display("wrong");
		$stop;
	end

end

// test for 0
for (integer i = 0; i < 20; i = i + 1) begin
	A = $random % (1 << 16);
	B = -A;

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end
	if (V_ex !== V) begin
		$display("wrong");
		$stop;
	end

end
// test for 0
for (integer i = 0; i < 20; i = i + 1) begin
	B = $random % (1 << 16);
	A = -B;

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end
	if (V_ex !== V) begin
		$display("wrong");
		$stop;
	end

end


// TEST SUB
Control = 1;
for (integer i = 0; i < 20000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end
	if (V_ex !== V) begin
		$display("wrong");
		$stop;
	end

end

// test for 0
for (integer i = 0; i < 50; i = i + 1) begin
	B = $random % (1 << 16);
	A = B;

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end
	if (V_ex !== V) begin
		$display("wrong");
		$stop;
	end

end


// TEST XOR
Control = 2;
for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end

// TEST RED
Control = 3;
for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end

// TEST SLL
Control = 4;
for (integer i= 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end


// TEST SRA
Control = 5;
for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end

// TEST ROR
Control = 6;
for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end

// TEST PADDSB
Control = 7;
for (integer i = 0; i < 5000; i = i + 1) begin
	A = $random % (1 << 16);
	B = $random % (1 << 16);

	#5;

	if ( expected !== rslt ) begin
		$display("wrong");
		$stop;
	end
	if (N_ex !== N) begin
		$display("wrong");
		$stop;
	end
	if (Z_ex !== Z) begin
		$display("wrong");
		$stop;
	end

end


$display("YAHOO! Tests passed.");
$stop;


end

endmodule 


