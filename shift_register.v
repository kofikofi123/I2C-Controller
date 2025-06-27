
module shift_register(clock, reset_n, load, shift, inb, outb, ins, out);
	parameter REGISTER_SIZE = 8;

	input clock, reset_n, load, inb, shift;

	input [REGISTER_SIZE-1:0] ins;

	output outb;

	output [REGISTER_SIZE-1:0] out;


	reg [REGISTER_SIZE-1:0] out, out_n;


	reg outb, outb_n;


	always @(posedge clock) begin
		if (~reset_n) begin
			out <= {REGISTER_SIZE{1'b0}};
			outb <= 1'b0;
		end
		else begin
			out <= out_n;
			outb <= outb_n;
		end
	end

	always @(*) begin
		if (load) out_n = ins;
		else if (shift) out_n = {out[REGISTER_SIZE-2:0], inb};
		else out_n = out;
	end

	always @(*) begin
		if (shift) outb_n = out[REGISTER_SIZE-1];
		else outb_n = outb_n; //latch
	end

endmodule