
module counter(clock, reset_n, en, out);
	parameter COUNTER_SIZE = 8;
	input clock, reset_n, en;

	output [COUNTER_SIZE-1:0] out;

	reg [COUNTER_SIZE-1:0] out, out_n;
	
	always @(posedge clock) begin
		if (~reset_n) begin
			out <= {COUNTER_SIZE{1'b0}};
		end
		else begin
			out <= out_n;
		end
	end

	always @(*) begin
		if (en) begin
			out_n = out + 1;// + {{COUNTER_SIZE-1{1'b0}}, 1'b1};
		end
		else begin
			out_n = out;
		end
	end
endmodule
