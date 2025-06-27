

module clock_divider(clock, reset_n, enable, out);
   input        clock;
   input        reset_n; 
   input        enable; 
   output       out; 
	
	reg 	 [32:0] 	state;
	reg 				out;
	
	parameter REF_FREQ = 32'd50_000_000;
	parameter DSR_FREQ = 32'd25_600;
	localparam COUNT = ((REF_FREQ / (2 * DSR_FREQ)) - 1);
	
	always@(posedge clock) begin
		if (!reset_n) begin
			state <= 32'd0;
			out <= 1'b1;
		end
		else if (enable) begin
			if (state == COUNT) begin
				out <= ~out;
				state <= 32'd0;
			end
			else begin
				out <= out;
				state <= state + 32'd1;
			end
		end
		else out <= 1'b1;
	end
		
endmodule