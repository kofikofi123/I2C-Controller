


module register(clock, reset_n, load, ins, out);
	parameter REGISTER_SIZE = 8;
	input clock, reset_n, load;

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
		else begin
			out_n = out;
		end
	end
endmodule