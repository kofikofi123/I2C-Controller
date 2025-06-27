
`timescale 1ns/1ns
module tb_I2C_Controller();
	
	localparam PERIOD = 20;

	reg clock, reset_n, init, rw;
	reg [6:0] address;
	reg [31:0] data;
	reg [3:0] bytesend;

	wire i2c_sda, i2c_scl;

	wire i2c_err_s;

	pullup(i2c_sda);
	pullup(i2c_scl);

	I2C_Controller dut_m(clock,
						 reset_n,
						 init,
						 rw,
						 address,
						 data,
						 bytesend,
						 i2c_sda,
						 i2c_scl);


	initial begin
		clock = 1'b0;

		forever begin
			#(PERIOD / 2);
			clock = ~clock;
		end
	end


	initial begin
		reset_n = 1'b0;
		init = 1'b0;
		rw = 1'b0;
		address = 7'h1F;
		data = 32'd0;
		bytesend = 4'b0000;
		#(PERIOD);
		reset_n = 1'b1;
		#(PERIOD);
		data = 32'd32;
		bytesend = 4'b1000;
		init = 1'b1;
		#(PERIOD);
		init = 1'b0;
		#(PERIOD * 300);
		$stop;

	end
endmodule