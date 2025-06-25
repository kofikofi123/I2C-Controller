

module I2C_Controller(clock, reset_n, init, rw, address, data, bytesend, i2c_err, i2c_sda, i2c_scl);
	parameter ADDR_SIZE = 7;
	parameter CLOCK_F = 50_000_000;

	input clock, reset_n, init, rw;
	input [ADDR_SIZE-1:0] address;
	input [31:0] data;
	input [3:0] bytesend;
	inout i2c_sda, i2c_scl;


	output i2c_err;

	reg [3:0] state, state_n;
	
	reg i2c_sda_r, i2c_scl_r;

	reg [31:0] stored_data, stored_data_n;
	reg [7:0] shift_register, shift_register_n;

	wire cycle_counter_en, cycle_counter_clear;
	wire [7:0] cycle_counter_out;

	wire send_counter_clear, send_counter_en;
	wire [7:0] send_counter_out;

	wire rw_reg_load;
	wire rw_reg_out;

	wire bytesend_reg_load, bytesend_reg_shift;
	wire [3:0] bytesend_reg_out;

	wire data_reg_load, data_reg_shift;
	wire [31:0] data_reg_out;

	wire data_out_reg_load, data_out_reg_shift;
	wire [7:0] data_out_data, data_out_reg_out;

	wire shift_reg_load;
	wire shift_reg_out;


	wire i2c_sda_driver_en, i2c_scl_driver_en;

	start_pulse_detector spd(clock, reset_n, i2c_sda, spd_out);

	register #(32) data_reg(clock, reset_n, data_reg_load, data, data_reg_out);
	register #(1) rw_reg(clock, reset_n, rw_reg_load, rw, rw_reg_out);
	register #(1) shift_reg(clock, reset_n, shift_reg_load, data_out_reg_out[7], shift_reg_out);
	shift_register #(4) bytesend_reg(clock, reset_n, bytesend_reg_load, bytesend_reg_shift, bytesend, bytesend_reg_out);
	shift_register data_out_reg(clock, reset_n, data_out_reg_load, data_out_reg_shift, data_out_data, data_out_reg_out);


	counter cycle_counter(clock, cycle_counter_clear, cycle_counter_en, cycle_counter_out);
	counter send_counter(clock, send_counter_en, send_counter_en, send_counter_out);

	
	localparam START_COUNT_F = 250_000;
	
	localparam STATE_IDLE 			= 4'd0,
			   STATE_INIT 			= 4'd1,
			   STATE_SEND_ADDR 		= 4'd2,
			   STATE_WAIT_ACK 		= 4'd3,
			   STATE_T_SEND_DATA 	= 4'd4,
			   STATE_R_SEND_DATA 	= 4'd6,
			   STATE_I_WAIT_ACK		= 4'd7,
			   STATE_ERR			= 4'd8,
			   STATE_STOP 			= 4'd9;
	
	localparam START_COUNT = (CLOCK_F / START_COUNT_F) - 1;

	/* sequential logic */
	always @(posedge clock) begin
		if (~reset_n) begin
			state <= STATE_IDLE;
		end
		else begin
			state <= state_n;
		end
	end

	/* state combination logic */
	always @(*) begin
		case (state)
			STATE_IDLE: begin
				if (init) begin
					state_n = STATE_INIT;
				end
				else begin
					state_n = STATE_IDLE;
				end
			end
			STATE_INIT: begin
				if (cycle_counter_out == START_COUNT) begin
					state_n = STATE_SEND_ADDR;
				end
				else begin
					state_n = STATE_INIT;
				end
			end
			STATE_SEND_ADDR: begin
				if (send_counter_out == 8'd7) begin
					state_n = STATE_WAIT_ACK;
				end
				else begin
					state_n = STATE_SEND_ADDR;
				end
			end
			STATE_WAIT_ACK: begin
				if (i2c_sda) begin
					state_n = STATE_ERR;
				end
				else begin
					
					state_n = rw_reg_out ? STATE_T_SEND_DATA : STATE_R_SEND_DATA;
				end
			end
			STATE_T_SEND_DATA: begin
				state_n = STATE_T_SEND_DATA;
			end
			STATE_R_SEND_DATA: begin
				state_n = STATE_R_SEND_DATA;
			end
			STATE_I_WAIT_ACK: begin
				state_n = STATE_I_WAIT_ACK;
			end
			default: state_n = 1'bx;
		endcase
	end
	

	/* output stages */
	always @(*) begin
		case (state)
			STATE_IDLE: begin
				i2c_sda_r = 1'b1; //1'bz
				i2c_scl_r = 1'b1; //1'bz
			end
			STATE_INIT: begin
				i2c_sda_r = 1'b0;
				i2c_scl_r = 1'b1; //1'bx
			end
			STATE_SEND_ADDR, STATE_T_SEND_DATA, STATE_R_SEND_DATA: begin
				i2c_sda_r = shift_reg_out;
				i2c_scl_r = clock;
			end
			STATE_WAIT_ACK: begin
				i2c_sda_r = 1'b1;
				i2c_scl_r = clock;
			end
			STATE_I_WAIT_ACK: begin
				i2c_sda_r = 1'b1; //1'bx
				i2c_scl_r = clock;
			end
		endcase
	end

	assign rw_reg_load 			= ((state == STATE_IDLE) & init);
	assign bytesend_reg_load 	= ((state == STATE_IDLE) & init);
	assign data_reg_load		= ((state == STATE_IDLE) & init);
	assign data_out_reg_load	= ((state == STATE_IDLE) & init) | (state == STATE_WAIT_ACK);
	assign shift_reg_load 		= ((state == STATE_SEND_ADDR) | (state == STATE_T_SEND_DATA));

	assign data_out_reg_shift 	= ((state == STATE_SEND_ADDR) | (state == STATE_T_SEND_DATA));
	assign bytesend_reg_shift 	= 1'b0;



	assign cycle_counter_clear = (state == STATE_INIT);
	assign send_counter_clear = ((state == STATE_SEND_ADDR) | (state == STATE_T_SEND_DATA));

	assign cycle_counter_en = (state == STATE_INIT);
	assign send_counter_en 	= ((state == STATE_SEND_ADDR) | (state == STATE_T_SEND_DATA));

	assign data_out_data = (state == STATE_IDLE) ? ({address, rw}) : (data_reg_out);

	assign i2c_sda_driver_en = (state != STATE_WAIT_ACK);
	assign i2c_scl_driver_en = 1'b1;

	bidir_driver i2c_sda_driver(i2c_sda_driver_en, i2c_sda_r, i2c_sda);
	bidir_driver i2c_scl_driver(i2c_scl_driver_en, i2c_scl_r, i2c_scl);

	assign i2c_err = (state == STATE_ERR);
	//assign i2c_sda = i2c_sda_r;
	//assign i2c_scl = i2c_scl_r;
endmodule
