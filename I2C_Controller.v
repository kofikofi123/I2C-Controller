
`define MAX(a,b) ((a > b) ? a : b)
module I2C_Controller(clock, reset_n, init_transaction, rw, address, data, bytesend, i2c_sda, i2c_scl);
	parameter CLOCK_F 		= 50_000_000;

	localparam INIT_COUNT 	= (CLOCK_F / 250_000) - 1;

	localparam I2C_COUNTER_WIDTH = `MAX($clog2(INIT_COUNT), 5);
	
	input clock, reset_n, init_transaction, rw;

	input [7:0] address;
	input [31:0] data;
	input [3:0] bytesend;


	inout i2c_sda, i2c_scl;

	wire data_register_load, data_register_inb, data_register_outb, data_register_shift;

	wire bytesend_register_load, bytesend_register_shift, bytesend_register_outb;
	wire [3:0] bytesend_register_out;


	wire rw_register_load, rw_register_out;

	wire i2c_counter_reset, i2c_counter_en;
	wire [I2C_COUNTER_WIDTH-1:0] i2c_counter_out;

	wire [31:0] data_register_ins;
	wire i2c_scl_div_en, i2c_scl_div_out;
	wire clk_det_out;


	start_pulse_detector clk_det(clock, reset_n, i2c_scl_div_out, clk_det_out);
	clock_divider #(CLOCK_F, CLOCK_F / 16) i2c_scl_div(clock, reset_n, i2c_scl_div_en, i2c_scl_div_out);

	counter #(I2C_COUNTER_WIDTH) i2c_counter(clock, i2c_counter_reset, i2c_counter_en, i2c_counter_out);

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

	localparam 	STATE_IDLE 		= 4'd0,
				STATE_INIT		= 4'd1,
				STATE_SEND_ADDR	= 4'd2,
				STATE_ADDR_ACK	= 4'd3,
				STATE_RW		= 4'd4,
				STATE_SEND_DATA = 4'd5,
				STATE_RECV_DATA	= 4'd6,
				STATE_ACK_DATA	= 4'd7,
				STATE_STOP		= 4'd8;


	reg state, state_n;


	always @(posedge clock) begin
		if (~reset_n) state <= STATE_IDLE;
		else state <= state_n;
	end


	always @(*) begin
		case (state)
			STATE_IDLE: state_n = init_transaction ? STATE_INIT : STATE_IDLE;
			STATE_INIT:	state_n = (i2c_counter_out == INIT_COUNT) ? STATE_SEND_ADDR : STATE_INIT;
			STATE_SEND_ADDR: state_n = (i2c_counter_out == 8) ? STATE_ADDR_ACK : STATE_SEND_ADDR;
			STATE_ADDR_ACK:	state_n = (i2c_sda == 1'b1) ? STATE_STOP : STATE_RW;
			STATE_RW: state_n = (rw_register_out ? STATE_SEND_DATA : STATE_RECV_DATA);
			STATE_SEND_DATA: state_n = (i2c_counter_out == 8) ? STATE_ACK_DATA : STATE_SEND_DATA;
			STATE_RECV_DATA: state_n = (i2c_counter_out == 8) ? STATE_ACK_DATA : STATE_RECV_DATA;
			STATE_ACK_DATA: state_n = (i2c_sda == 1'b1) ? STATE_STOP : 
									  	(bytesend_register_out == 4'd0) ? STATE_STOP : STATE_RW;
			default: state_n = 4'bxxxx;
		endcase
	end


	assign data_register_load		= ((state == STATE_INIT));
	assign data_register_shift		= (((state == STATE_RECV_DATA) & clk_det_out) |
									   ((state == STATE_SEND_ADDR) & clk_det_out) |
									   ((state == STATE_SEND_DATA) & clk_det_out));
	assign data_register_inb		= (state == STATE_RECV_DATA) ? i2c_sda : 1'b0;
	assign data_register_ins 		= {address, data};

	assign bytesend_register_shift 	= ((state == STATE_ACK_DATA));
	assign bytesend_register_load 	= ((state == STATE_INIT));


	assign rw_register_load			= ((state == STATE_INIT));


	assign i2c_counter_reset		= ((state == STATE_INIT) | 
									   (state == STATE_SEND_ADDR) | 
									   (state == STATE_RECV_DATA));

	
	assign i2c_scl_div_en	= 1'b1;	
endmodule
