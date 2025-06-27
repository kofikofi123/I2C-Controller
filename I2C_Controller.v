
`define MAX(a,b) ((a > b) ? a : b)
module I2C_Controller(clock, reset_n, init_transaction, rw, address, data, bytesend, i2c_sda, i2c_scl, debug_signal, debug_send);
	parameter CLOCK_F 		= 50_000_000;

	localparam INIT_COUNT 	= (CLOCK_F / 250_000) - 1;
	localparam SEND_COUNT	= 8;
	localparam I2C_COUNTER_WIDTH = `MAX($clog2(INIT_COUNT), 5);


	
	input clock, reset_n, init_transaction, rw;

	input [6:0] address;
	input [31:0] data;
	input [3:0] bytesend;


	inout i2c_sda, i2c_scl;

	output debug_signal, debug_send;

	wire data_register_load, data_register_inb, data_register_outb, data_register_shift;
	wire [39:0] data_register_ins, data_register_out;

	wire bytesend_register_load, bytesend_register_shift, bytesend_register_outb;
	wire [3:0] bytesend_register_out;


	wire rw_register_load, rw_register_out;

	wire i2c_counter_reset, i2c_counter_en;
	wire [I2C_COUNTER_WIDTH-1:0] i2c_counter_out;


	wire i2c_scl_div_en, i2c_scl_div_out;
	wire clk_det_out;

	wire i2c_sda_driver_en, i2c_sda_driver_in;
	wire i2c_scl_driver_en;

	wire i2c_scl_setup_div_en, i2c_scl_setup_div_out;

	wire clk_det2_out;

	wire data_clk;

	wire data_counter_reset, data_counter_en;
	wire [4:0] data_counter_out;


	positive_pulse_detector clk_det(clock, reset_n, i2c_scl_setup_div_out, clk_det_out);
	positive_pulse_detector clk_det2(clock, reset_n, i2c_scl_div_out, clk_det2_out);
	clock_divider #(CLOCK_F, CLOCK_F / 8) i2c_scl_setup_div(clock, reset_n, i2c_scl_setup_div_en, i2c_scl_setup_div_out);
	clock_divider #(CLOCK_F, CLOCK_F / 16) i2c_scl_div(clock, reset_n, i2c_scl_div_en, i2c_scl_div_out);


	counter #(I2C_COUNTER_WIDTH) i2c_counter(clock, i2c_counter_reset, i2c_counter_en, i2c_counter_out);
	counter #(5)				 data_counter(clock, data_counter_reset, data_counter_en, data_counter_out);

	shift_register #(4) bytesend_register(clock,
							   			  reset_n,
							   			  bytesend_register_load,
							   			  bytesend_register_shift,
							   			  1'b0,
							   			  bytesend_register_outb,
							   			  bytesend,
							   			  bytesend_register_out);

	register #(1) rw_register(clock,
							  reset_n,
							  rw_register_load,
							  rw,
							  rw_register_out);

	shift_register #(40) data_register(clock,
								 	   reset_n,
								 	   data_register_load,
								 	   data_register_shift,
								 	   data_register_inb,
								 	   data_register_outb,
								 	   data_register_ins,
								 	   data_register_out);


	bidir_driver i2c_sda_driver(i2c_sda_driver_en, i2c_sda_driver_in, i2c_sda);
	bidir_driver i2c_scl_driver(i2c_scl_driver_en, i2c_scl_div_out, i2c_scl);

	localparam 	STATE_IDLE 		= 4'd0,
				STATE_INIT		= 4'd1,
				STATE_SEND_ADDR	= 4'd2,
				STATE_ACK_ADDR	= 4'd3,
				STATE_RW		= 4'd4,
				STATE_SEND_DATA = 4'd5,
				STATE_RECV_DATA	= 4'd6,
				STATE_FINI_DATA = 4'd7,
				STATE_ACK_DATA	= 4'd8,
				STATE_STOP		= 4'd9;


	reg [3:0] state, state_n;


	always @(posedge clock) begin
		if (~reset_n) state <= STATE_IDLE;
		else state <= state_n;
	end


	always @(*) begin
		case (state)
			STATE_IDLE: state_n = init_transaction ? STATE_INIT : STATE_IDLE;
			STATE_INIT:	state_n = (i2c_counter_out == INIT_COUNT) ? STATE_SEND_ADDR : STATE_INIT;
			STATE_SEND_ADDR: state_n = (data_counter_out == SEND_COUNT) ? STATE_ACK_ADDR : STATE_SEND_ADDR;
			STATE_ACK_ADDR:	state_n = ((i2c_sda == 1'b1) & clk_det2_out) ? STATE_STOP : (clk_det2_out ? STATE_RW : STATE_ACK_ADDR);
			STATE_RW: state_n = (rw_register_out ? STATE_SEND_DATA : STATE_RECV_DATA);
			STATE_SEND_DATA: state_n = (data_counter_out == SEND_COUNT) ? STATE_FINI_DATA : STATE_SEND_DATA;
			STATE_RECV_DATA: state_n = (data_counter_out == SEND_COUNT) ? STATE_FINI_DATA : STATE_RECV_DATA;
			STATE_FINI_DATA: state_n = STATE_ACK_DATA;
			STATE_ACK_DATA: state_n = ((i2c_sda == 1'b1) & clk_det2_out) ? STATE_STOP : 
									  	((bytesend_register_out == 4'd0) & clk_det2_out) ? STATE_STOP : 
									  		clk_det2_out ? STATE_RW : STATE_ACK_DATA;
  			STATE_STOP: state_n = (i2c_counter_out == INIT_COUNT) ? STATE_IDLE : STATE_STOP;
			default: state_n = 4'bxxxx;
		endcase
	end


	assign data_register_load		= ((state == STATE_INIT));
	assign data_register_shift		= (((state == STATE_RECV_DATA) & data_clk) |
									   ((state == STATE_SEND_ADDR) & data_clk) |
									   ((state == STATE_SEND_DATA) & data_clk));
	assign data_register_inb		= (state == STATE_RECV_DATA) ? i2c_sda : 1'b0;
	assign data_register_ins 		= {address, rw, data};

	assign bytesend_register_shift 	= ((state == STATE_FINI_DATA));
	assign bytesend_register_load 	= ((state == STATE_INIT));


	assign rw_register_load			= ((state == STATE_INIT));


	assign i2c_counter_reset		= ((state == STATE_INIT) |
									   (state == STATE_STOP));

	assign i2c_counter_en			= ((state == STATE_INIT) |
									   (state == STATE_STOP));


	assign data_counter_reset		= ((state == STATE_SEND_ADDR) |
									   (state == STATE_SEND_DATA) | 
									   (state == STATE_RECV_DATA));

	assign data_counter_en			= (((state == STATE_SEND_ADDR) & clk_det2_out) |
									   ((state == STATE_SEND_DATA) & clk_det2_out) | 
									   ((state == STATE_RECV_DATA) & clk_det2_out));

	
	assign i2c_scl_div_en			= (state != STATE_INIT) & (state != STATE_IDLE) & (state != STATE_STOP);


	assign i2c_scl_setup_div_en		= ((state != STATE_IDLE) &
									   (state != STATE_INIT) &
									   (state != STATE_STOP));

	assign i2c_sda_driver_en 		= ((state == STATE_INIT) |
									   (state == STATE_SEND_ADDR) |
									   (state == STATE_SEND_DATA) |
									   (state == STATE_RECV_DATA) |
									   (state == STATE_STOP));
	assign i2c_sda_driver_in 		= (state == STATE_INIT) ? 1'b0 :
										(((state == STATE_SEND_ADDR) |
										  (state == STATE_SEND_DATA) |
										  (state == STATE_RW)		 |
										  (state == STATE_RECV_DATA)) ? data_register_outb : 1'b1);

	assign i2c_scl_driver_en		= ((state != STATE_IDLE) &
									   (state != STATE_INIT) &
									   (state != STATE_STOP));

	assign debug_signal = (state_n == STATE_ACK_ADDR) | (state_n == STATE_ACK_DATA) | (state == STATE_ACK_ADDR) | (state == STATE_ACK_DATA);
	assign debug_send = (state == STATE_SEND_DATA) | (state == STATE_RECV_DATA);


	assign data_clk					= clk_det_out & ~i2c_scl_div_out;
endmodule
