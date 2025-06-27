
`timescale 1ns/1ns
module tb_I2C_Controller();
	
	localparam PERIOD = 20;

	reg clock, reset_n, init, rw;
	reg [6:0] address;
	reg [31:0] data;
	reg [3:0] bytesend;

	wire i2c_sda, i2c_scl;


	wire debug_w, debug_s;

	reg driver_en, driver_in;

	wire test_reg_outb;
	wire [31:0] test_reg_out;


	pullup(i2c_sda);
	pullup(i2c_scl);


	wire en;

	bidir_driver driver(debug_w, driver_in, i2c_sda);

	shift_register #(32) test_reg(i2c_scl, 
								  reset_n,
								  1'b0,
								  debug_s,
								  i2c_sda,
								  test_reg_outb,
								  32'd0,
								  test_reg_out);



	I2C_Controller dut_m(clock,
						 reset_n,
						 init,
						 rw,
						 address,
						 data,
						 bytesend,
						 i2c_sda,
						 i2c_scl,
						 debug_w,
						 debug_s);


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
		driver_en = 1'b0;
		driver_in = 1'b1;
		#(PERIOD);
		reset_n = 1'b1;
		#(PERIOD);
		data = 32'd32;
		bytesend = 4'b1111;
		rw = 1'b1;
		init = 1'b1;
		#(PERIOD);
		init = 1'b0;
		@(posedge debug_w);
		driver_en = 1'b1;
		driver_in = 1'b0;
		@(posedge i2c_scl);
		driver_en = 1'b0;
		repeat (4) begin
			@(posedge debug_w);
			driver_en = 1'b1;
			driver_in = 1'b0;
			@(negedge debug_w);
			driver_en = 1'b0;
		end
		$stop;

	end


	assign en = i2c_scl & debug_s;
endmodule