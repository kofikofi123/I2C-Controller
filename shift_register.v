
module shift_register(clock, reset_n, load, in_shift, inb, shift, ins, out);
	parameter REGISTER_SIZE = 8;

	input clock, reset_n, load, in_shift, shift, inb;

	input [REGISTER_SIZE-1:0] ins;

	output [REGISTER_SIZE-1:0] out;


	reg [REGISTER_SIZE-1:0] out, out_n;

	always @(posedge clock) begin
		if (~reset_n) begin
			out <= {REGISTER_SIZE{1'b0}};
		end
		else begin
			out <= out_n;
		end
	end

	always @(*) begin
		if (load) begin
			out_n = ins;
		end
		else if (shift) begin
			out_n = {out[REGISTER_SIZE-2:0], 1'b0};
		end
		else if (in_shift) begin
			out_n = {out[REGISTER_SIZE-2:0], inb};
		end
		else begin
			out_n = out;
		end
	end

endmodule