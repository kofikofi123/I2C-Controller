////////////////////////////////////////////////////////////////////////////////
// Filename:    start_pulse_detector.v
// Author:      Kofi Ofosu-Tuffour
// Date:        28 November 2024
// Version:     1
// Description: Behavioral model of the start pulse detection.
//				Start pulse begins as defined in the U6050-U6051B datasheet 
//				as a falling-edge signal.
//				Synchronous active-low reseting through reset_n.
////////////////////////////////////////////////////////////////////////////////

module start_pulse_detector(clock, reset_n, data_in, out);
	input clock, reset_n, data_in;

	output out;
	reg out;

	reg [1:0] state;
	localparam 	STATE_IDLE_S = 2'b00,
					STATE_HIGH = 2'b01,
					STATE_LOW  = 2'b10;


	always @(posedge clock or negedge reset_n) begin
		if (~reset_n) begin
			state <= STATE_IDLE_S;
		end
		else begin
			case (state)
				
				STATE_IDLE_S: begin
					if (data_in) begin
						state <= STATE_HIGH;
					end
					else begin
						state <= state;
					end
				end
				STATE_HIGH: begin
					if (~data_in) begin
						state <= STATE_LOW;
					end
					else begin
						state <= state;
					end
				end
				STATE_LOW: begin
					state <= STATE_IDLE_S;
				end
				default: begin
					state <= 2'bxx;
				end
			endcase
		end
	end

	always @(state) begin
		case (state)
			STATE_IDLE_S: out = 1'b0;
			STATE_HIGH: out = 1'b0;
			STATE_LOW:	out = 1'b1;
			default:	out = 1'bx;
		endcase
	end

endmodule