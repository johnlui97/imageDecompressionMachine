`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module project (
		input logic CLOCK_50_I,                   // 50 MHz clock

		input logic[3:0] PUSH_BUTTON_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[9:0] VGA_RED_O,              // VGA red
		output logic[9:0] VGA_GREEN_O,            // VGA green
		output logic[9:0] VGA_BLUE_O,             // VGA blue
		
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[17:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);

top_state_type top_state;

// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

//For Milestone 1
logic M1_start;
logic M1_done;
logic [17:0] M1_SRAM_address;
logic [15:0] M1_SRAM_write_data;
logic M1_SRAM_we_n;

//For Milestone 2
logic M2_start;
logic M2_done;
logic [17:0] M2_SRAM_address;
logic [15:0] M2_SRAM_write_data;
logic M2_SRAM_we_n;
logic DRAM_0_we_a;
logic DRAM_0_we_b;
logic DRAM_1_we_a;
logic DRAM_1_we_b;
logic DRAM_2_we_a;
logic DRAM_2_we_b;
logic [31:0] DRAM_0_Read_Data_a;
logic [31:0] DRAM_0_Read_Data_b;
logic [31:0] DRAM_1_Read_Data_a;
logic [31:0] DRAM_1_Read_Data_b;
logic [31:0] DRAM_2_Read_Data_a;
logic [31:0] DRAM_2_Read_Data_b;
logic [6:0] DRAM_0_Address_a;
logic [6:0] DRAM_0_Address_b;
logic [6:0] DRAM_1_Address_a;
logic [6:0] DRAM_1_Address_b;
logic [6:0] DRAM_2_Address_a;
logic [6:0] DRAM_2_Address_b;
logic [32:0] DRAM_0_Write_Data_a;
logic [32:0] DRAM_0_Write_Data_b;
logic [32:0] DRAM_1_Write_Data_a;
logic [32:0] DRAM_1_Write_Data_b;
logic [32:0] DRAM_2_Write_Data_a;
logic [32:0] DRAM_2_Write_Data_b;
logic [4:0] c_traversal_counter;

// For SRAM
logic [17:0] SRAM_address;
logic [15:0] SRAM_write_data;
logic SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;
logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic [3:0] Frame_error;
logic resetn;

// For disabling UART transmit
assign UART_TX_O = 1'b1;
assign resetn = ~SWITCH_I[17] && SRAM_ready;

//Milestone 1 unit
M1_unit Milestone1_unit (
	.CLOCK_50_I(CLOCK_50_I),   //clock
	.M1_start(M1_start),       //trigger to start fsm in M1 unit
	.Resetn(resetn),
	.SRAM_read_data(SRAM_read_data),
	
	//Milestone 1's SRAM requests
	.SRAM_address(M1_SRAM_address),
	.SRAM_write_data(M1_SRAM_write_data),
	.SRAM_we_n(M1_SRAM_we_n),

	//flag to say M1 is done
	.M1_done(M1_done)
);

//Milestone 2 unit
M2_unit Milestone2_unit (
	.CLOCK_50_I(CLOCK_50_I), //clocl
	.M2_start(M2_start),     //trigger to srart fsm in M2 Unit
	.Resetn(resetn),

	//inputing read data into M2 unit
	.SRAM_read_data(SRAM_read_data),
	.DRAM_0_Read_Data_a(DRAM_0_Read_Data_a),
	.DRAM_0_Read_Data_b(DRAM_0_Read_Data_b),
	.DRAM_1_Read_Data_a(DRAM_1_Read_Data_a),
	.DRAM_1_Read_Data_b(DRAM_1_Read_Data_b),
	.DRAM_2_Read_Data_a(DRAM_2_Read_Data_a),
	.DRAM_2_Read_Data_b(DRAM_2_Read_Data_b),

	//SRAM and DRAM requests from M2 unit
	.SRAM_we_n(M2_SRAM_we_n),
	.DRAM_0_we_a(DRAM_0_we_a),
	.DRAM_0_we_b(DRAM_0_we_b),
	.DRAM_1_we_a(DRAM_1_we_a),
	.DRAM_1_we_b(DRAM_1_we_b),
	.DRAM_2_we_a(DRAM_2_we_a),
	.DRAM_2_we_b(DRAM_2_we_b),

	.SRAM_address(M2_SRAM_address),
	.DRAM_0_Address_a(DRAM_0_Address_a),
	.DRAM_0_Address_b(DRAM_0_Address_b),
	.DRAM_1_Address_a(DRAM_1_Address_a),
	.DRAM_1_Address_b(DRAM_1_Address_b),
	.DRAM_2_Address_a(DRAM_2_Address_a),
	.DRAM_2_Address_b(DRAM_2_Address_b),

	.SRAM_write_data(M2_SRAM_write_data),
	.DRAM_0_Write_Data_a(DRAM_0_Write_Data_a),
	.DRAM_0_Write_Data_b(DRAM_0_Write_Data_b),
	.DRAM_1_Write_Data_a(DRAM_1_Write_Data_a),
	.DRAM_1_Write_Data_b(DRAM_1_Write_Data_b),
	.DRAM_2_Write_Data_a(DRAM_2_Write_Data_a),
	.DRAM_2_Write_Data_b(DRAM_2_Write_Data_b),

	//flag to indicate milestone 2 is done
	.M2_done(M2_done)
);

// DRAM moduels for 3 distinct dynamic RAMS
dual_port_RAM0 DRAM_unit_0 (
	.address_a(DRAM_0_Address_a),
	.address_b(DRAM_0_Address_b),
	.clock(CLOCK_50_I),
	.data_a(DRAM_0_Write_Data_a),
	.data_b(DRAM_0_Write_Data_b),
	.wren_a(DRAM_0_we_a),
	.wren_b(DRAM_0_we_b),

	.q_a(	),
	.q_b(DRAM_0_Read_Data_b)
);
dual_port_RAM1 DRAM_unit_1 (
	.address_a(DRAM_1_Address_a),
	.address_b(DRAM_1_Address_b),
	.clock(CLOCK_50_I),
	.data_a(DRAM_1_Write_Data_a),
	.data_b(DRAM_1_Write_Data_b),
	.wren_a(DRAM_1_we_a),
	.wren_b(DRAM_1_we_b),

	.q_a(DRAM_1_Read_Data_a),
	.q_b(DRAM_1_Read_Data_b)
);
dual_port_RAM2 DRAM_unit_2 (
	.address_a(DRAM_2_Address_a),
	.address_b(DRAM_2_Address_b),
	.clock(CLOCK_50_I),
	.data_a(DRAM_2_Write_Data_a),
	.data_b(DRAM_2_Write_Data_b),
	.wren_a(DRAM_2_we_a),
	.wren_b(DRAM_2_we_b),

	.q_a(DRAM_2_Read_Data_a),
	.q_b(DRAM_2_Read_Data_b)
);

// Push Button unit
PB_Controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_I),	
	.PB_pushed(PB_pushed)
);

// VGA SRAM interface
VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_Controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		//initailly dont start any milestone units
		M1_start <= 1'b0;
		M2_start <= 1'b0;

		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		VGA_enable <= 1'b1;
	end else begin
		UART_rx_initialize <= 1'b0; 
		UART_rx_enable <= 1'b0; 
		
		// Timer for timeout on UART
		// This counter reset itself every time a new data is received on UART
		if (UART_rx_initialize | ~UART_SRAM_we_n) UART_timer <= 26'd0;
		else UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;   
			
			`ifdef SIMULATION
				if(UART_timer <= 26'd10) begin
					top_state <= S_Milestone_3;
				end
			`endif
			
			if (~UART_RX_I | PB_pushed[0]) begin
				// UART detected a signal, or PB0 is pressed
				UART_rx_initialize <= 1'b1;
				
				VGA_enable <= 1'b0;
								
				top_state <= S_ENABLE_UART_RX;
			end
		end
		S_ENABLE_UART_RX: begin
			// Enable the UART receiver
			UART_rx_enable <= 1'b1;
			top_state <= S_WAIT_UART_RX;
		end
		S_WAIT_UART_RX: begin
			if ((UART_timer == 26'd49999999) && (UART_SRAM_address != 18'h00000)) begin
				// Timeout for 1 sec on UART for detecting if file transmission is finished
				UART_rx_initialize <= 1'b1;
				 				
				VGA_enable <= 1'b1;
				//top_state <= S_IDLE;
				top_state <= S_Milestone_3;
			end
		end
		//Buffer to wait until PB0 is pressed to start the unit
		S_PROJECT_DELAY: begin
			`ifdef SIMULATION
				top_state <= S_Milestone_3;
			`endif
			
			if(PB_pushed[0]) begin
				top_state <= S_Milestone_3;
			end
		end
		//Decompression process is begun here
		S_Milestone_3: begin
			//if Milestone 3 is done:
			M2_start <= 1'b1;
			top_state <= S_Milestone_2;
		end
		S_Milestone_2: begin
			//if milestone 2 is done intitiate milestone 1
			if(M2_done) begin
				M2_start <= 1'b0;
				M1_start <= 1'b1;
				top_state <= S_Milestone_1;
			end
		end
		S_Milestone_1: begin
			//if milestone1 is done, go back to idle
			if(M1_done) begin
				M1_start <= 1'b0;
				top_state <= S_IDLE;
			end
		end
		default: top_state <= S_IDLE;
		endcase
	end
end

assign VGA_base_address = 18'd146944;

// Give access to SRAM to Milestone 1, Milestone 2, UART or VGA moduels at a given time
assign SRAM_address = ((top_state == S_ENABLE_UART_RX) | (top_state == S_WAIT_UART_RX)) ? UART_SRAM_address 
					: (top_state == S_Milestone_2)? M2_SRAM_address
					: (top_state == S_Milestone_1)? M1_SRAM_address
					: VGA_SRAM_address;

assign SRAM_write_data = ((top_state == S_ENABLE_UART_RX) | (top_state == S_WAIT_UART_RX))? UART_SRAM_write_data 
						: (top_state == S_Milestone_2)? M2_SRAM_write_data 
						: M1_SRAM_write_data;

assign SRAM_we_n = ((top_state == S_ENABLE_UART_RX) | (top_state == S_WAIT_UART_RX))? UART_SRAM_we_n
						: (top_state == S_Milestone_2)? M2_SRAM_we_n 
						: M1_SRAM_we_n;

// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, top_state};

endmodule
