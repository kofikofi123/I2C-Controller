
module positive_pulse_detector(clock, reset_n, data_in, out);
	input clock, reset_n, data_in;

	output out;
	reg delay;


	always @(posedge clock) begin
		delay <= data_in;
	end

	assign out = ~delay & data_in;
endmodule