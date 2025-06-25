
module bidir_driver(en, in, out);
	input en, in;
	inout out;


	assign out = (en & ~in) ? 1'b0 : 1'bz;
endmodule
