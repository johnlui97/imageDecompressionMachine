`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

module M1_unit (
		input logic CLOCK_50_I,          
		input logic M1_start, //to indicate moduel start
		input logic Resetn,
		input logic [15:0] SRAM_read_data,

		output logic [17:0] SRAM_address,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,		
		output logic M1_done //to indicate moduel end
);

state_M1_type state_M1;

logic [15:0] Buffer_Y ; // buffer Ye and Yo
logic [7:0] Buffer_U ; // buffer Uo
logic [15:0] Buffer_V ; // buffer Ve and Vo

 //to hold calculated odd U odd and V odd values
logic [31:0] Buffer_U_odd, Buffer_V_odd, Buffer_U_odd_divided, Buffer_V_odd_divided;

//to hold calculated RGB values
logic [31:0] Buffer_R, Buffer_G, Buffer_B ;
logic [7:0] Buffer_R_clipped, Buffer_G_clipped, Buffer_B_clipped, Buffer_Bo_clipped, Buffer_Go_clipped; //migth not need R and G

//shift registers for U and V values
logic [47:0] U_data_register, V_data_register ;

//address counters
logic [17:0] address_Y, address_U, address_V, address_write;	

//counters for commoncase to leadout to leadin detection
logic [4:0] Lead_Out_Counter;
logic [8:0] Row_Counter, Column_Counter;

//logic for multiplication and arithmitic
logic [7:0] select;
logic [31:0] temp_arithmitic0, temp_arithmitic1, temp_arithmitic2;
logic [31:0] op0, op1, op2, op3, op4, op5, M1, M2, M3;
logic [63:0] M1_long, M2_long, M3_long;

always_comb begin
	//defaults varibles in comb block incase no if statements are met
	op0 = 32'd0;
	op1 = 32'd0; 
	op2 = 32'd0;
	op3 = 32'd0;
	op4 = 32'd0;
	op5 = 32'd0;

	//used to conduct arithmitic prior to clipping
	temp_arithmitic0 = 8'd0;
	temp_arithmitic1 = 8'd0;
	temp_arithmitic2 = 8'd0;

	//clipped values of rgb
	Buffer_R_clipped = (Buffer_R[31] == 1'b1)? 8'd0 : ((Buffer_R[31:24] >= 8'd1)? 8'd255 : Buffer_R[23:16]); 
	Buffer_G_clipped = (Buffer_G[31] == 1'b1)? 8'd0 : ((Buffer_G[31:24] >= 8'd1)? 8'd255 : Buffer_G[23:16]); 
	Buffer_B_clipped = (Buffer_B[31] == 1'b1)? 8'd0 : ((Buffer_B[31:24] >= 8'd1)? 8'd255 : Buffer_B[23:16]); 

	//uand v odd values after division
	Buffer_U_odd_divided = {8'd0, Buffer_U_odd[31:8]};
	Buffer_V_odd_divided = {8'd0, Buffer_V_odd[31:8]};

	//based on select, operation one/two are given a value from the u and v registers
	//operation one/two are multiplied together, then clipped
	//similat implementation to figure 20 in project document
	if(select == 8'd0) begin
		temp_arithmitic0 = Buffer_Y[15:8] - 8'd16;
		op0 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op1 = 32'd76284;
		
		temp_arithmitic1 = U_data_register[23:16] - 8'd128;
		op2 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op3 = 32'd25624;
		
		op4 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op5 = 32'd132251;
	end else if (select == 8'd1) begin
		temp_arithmitic0 = V_data_register[31:24]  - 8'd128;
		op2 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op3 = 32'd104595;
		
		op4 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op5 = 32'd53281;//-53281
	end else if (select == 8'd2) begin
		temp_arithmitic0 = U_data_register[47:40] + U_data_register[7:0];
		op0 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op1 = 32'd21;
		
		temp_arithmitic1 = U_data_register[39:32] + U_data_register[15:8];
		op2 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op3 = 32'd52;

		temp_arithmitic2 = U_data_register[31:24] + U_data_register[23:16];
		op4 = (temp_arithmitic2[7] == 1'b1)? {24'd1 , temp_arithmitic2} : {24'd0 , temp_arithmitic2};
		op5 = 32'd159;
	end else if (select == 8'd3) begin
		temp_arithmitic0 = V_data_register[47:40] + V_data_register[7:0];
		op0 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op1 = 32'd21;
		
		temp_arithmitic1 = V_data_register[39:32] + V_data_register[15:8];
		op2 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op3 = 32'd52;

		temp_arithmitic2 = V_data_register[31:24] + V_data_register[23:16];
		op4 = (temp_arithmitic2[7] == 1'b1)? {24'd1 , temp_arithmitic2} : {24'd0 , temp_arithmitic2};
		op5 = 32'd159;
	end else if (select == 8'd4) begin
		temp_arithmitic0 = Buffer_Y[7:0] - 8'd16;
		op0 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op1 = 32'd76284;
		
		temp_arithmitic1 = Buffer_U_odd_divided - 8'd128;  
		op2 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op3 = 32'd25624;
		
		op4 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op5 = 32'd132251;
	end else if (select == 8'd5) begin
		temp_arithmitic0 = Buffer_V_odd_divided - 8'd128;
		op2 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op3 = 32'd104595;
		
		op4 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op5 = 32'd53281;

	 //special case when u and v data registers are not bias due to lead in
	end else if (select == 8'd6) begin
		temp_arithmitic0 = Buffer_Y[15:8] - 8'd16;
		op0 = (temp_arithmitic0[7] == 1'b1)? {24'd1 , temp_arithmitic0} : {24'd0 , temp_arithmitic0};
		op1 = 32'd76284;
		
		temp_arithmitic1 = U_data_register[31:24] - 8'd128;
		op2 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op3 = 32'd25624;
		
		op4 = (temp_arithmitic1[7] == 1'b1)? {24'd1 , temp_arithmitic1} : {24'd0 , temp_arithmitic1};
		op5 = 32'd132251;
	end
end

//code to multiple then clip the operands
assign M1_long = op0 * op1;
assign M2_long = op2 * op3;
assign M3_long = op4 * op5;
assign M1 = M1_long[31:0];
assign M2 = M2_long[31:0];
assign M3 = M3_long[31:0];

always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		//intialized SRAM to read mode when not being used
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		SRAM_address <= 18'd0;

		//Buffer varibles for future use in cycles
		Buffer_Y <= 16'd0;
		Buffer_U <= 8'd0;
		Buffer_V <= 16'd0;

		//accumulators for RGB
		Buffer_R <= 32'd0;
		Buffer_G <= 32'd0;
		Buffer_B <= 32'd0;

		//to buffer odd and even values for uv
		Buffer_U_odd <= 32'd0;
		Buffer_V_odd <= 32'd0;

		//clipped B and G values for when RGB buffers begin calculating next RGB value
		Buffer_Bo_clipped <= 8'd0;
		Buffer_Go_clipped <= 8'd0;

		//data registers to hold values
		U_data_register <= 48'd0;
		V_data_register <= 48'd0;
		
		//initalized addressing to respective locations in SRAM
		address_Y <= 18'd0;
		address_U <= 18'd38400;
		address_V <= 18'd57600;		
		address_write <= 18'd146944;

		//counters used to determine when to enter lead out and finish program
		Lead_Out_Counter <= 8'd0;
		Row_Counter <= 9'd0;
		Column_Counter <= 9'd0;
		select <= 8'd0;

		M1_done <= 1'b0;
		state_M1 <= S_IDLE_M1;	
	end else begin
        case (state_M1)
        S_IDLE_M1: begin
		//when M1_start flag is triggered and we have not gotten to row 240 we begin lead in
		// o o u v e e
		// o o u v e e
		// o   u v e  
		//this is our multiplier states
			if (M1_start && Row_Counter != 9'd240) begin //0
				//calls u value
				SRAM_we_n <= 1'b1;
				SRAM_address <= address_U;
				address_U <= address_U + 1'b1;
				state_M1 <= S_LEADIN_0_M1;		
			end else if(Row_Counter == 9'd240) begin
				M1_done <= 1'b1;
			end
		end
		S_LEADIN_0_M1: begin
			//calls u value
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_U;
			address_U <= address_U + 1'b1;

			state_M1 <= S_LEADIN_1_M1;
		end
		S_LEADIN_1_M1: begin 
			//calls v value
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_V;
			address_V <= address_V + 1'b1;
		
			state_M1 <= S_LEADIN_2_M1;
		end
		S_LEADIN_2_M1: begin 
			//calls v value
			//recieved u values
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_V;
			address_V <= address_V + 1'b1;
			
			U_data_register[47:16] <= {SRAM_read_data[15:8], SRAM_read_data[15:8], SRAM_read_data[15:8], SRAM_read_data[7:0]}; //{even even even odd}
			state_M1 <= S_LEADIN_3_M1;
		end
		S_LEADIN_3_M1: begin 
			//calls y value
			//recieved u values
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_Y;
			address_Y <= address_Y + 1'b1;

			U_data_register[15:0] <= {SRAM_read_data[15:8], SRAM_read_data[7:0]};
			state_M1 <= S_LEADIN_4_M1;
		end
		S_LEADIN_4_M1: begin //4
			//calls v value for future use -> placed in buffer
			//recieved v values
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_V;
			address_V <= address_V + 1'b1;

			V_data_register[47:16] <= {SRAM_read_data[15:8], SRAM_read_data[15:8], SRAM_read_data[15:8], SRAM_read_data[7:0]}; //{even even even odd}
			state_M1 <= S_LEADIN_5_M1;
		end
		S_LEADIN_5_M1: begin //5
			V_data_register[15:0] <= {SRAM_read_data[15:8], SRAM_read_data[7:0]};
			state_M1 <= S_LEADIN_6_M1;
		end
		S_LEADIN_6_M1: begin //6
			Buffer_Y <= SRAM_read_data;
			
            select <= 8'd6;
			state_M1 <= S_LEADIN_7_M1;
		end
		//at this point, u and v data registers are updated
		
        // LEAD IN and COMMON CASE overlap
        S_LEADIN_7_M1: begin
			Buffer_V <= SRAM_read_data; //{even, odd}

			//accumulatred rgb
			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

            select <= 8'd1;
            state_M1 <= S_LEADIN_8_M1;
        end
        S_LEADIN_8_M1: begin
			//accumulator rgb, this state gives final value for rgb even
			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

			select <= 8'd2;
			state_M1 <= S_COMMON_CASE_2u_M1; 
        end

        // Common case for U cycle
        S_COMMON_CASE_0u_M1: begin
			//when v values are read, the last v value from buffer v is shifted in
			U_data_register <= {U_data_register[39:0], Buffer_U[7:0]};
			V_data_register <= {V_data_register[39:0], Buffer_V[7:0]}; 
			Buffer_V <= SRAM_read_data;

			//write B from previous cycle and R from this one
			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Bo_clipped, Buffer_R_clipped};
			//keep G and B values to write in next cycle
			Buffer_Go_clipped <= Buffer_G_clipped;
			Buffer_Bo_clipped <= Buffer_B_clipped;

			//calcualtes RGB for this cycle
			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			select <= 8'd1;
			state_M1 <= S_COMMON_CASE_1u_M1;
        end

		S_COMMON_CASE_1u_M1: begin 
			//increment column counter by 2 as 2 RGB values are now written
			Column_Counter <= Column_Counter + 2'd2;

			//accumulates RGB from previous cycle
			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;
			
			//writes the G and B values from previous cycle
			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Go_clipped, Buffer_Bo_clipped};

            select <= 8'd2;
			state_M1 <= S_COMMON_CASE_2u_M1;
		end
		S_COMMON_CASE_2u_M1: begin 
			//calls y values for next cycle
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_Y;
			address_Y <= address_Y + 1'b1;

			//recieved U odd value from arithmitic and multipliers
			Buffer_U_odd[31:0] <= M1 - M2 + M3 + 32'd128;

            select <= 8'd3;
			state_M1 <= S_COMMON_CASE_3u_M1;
		end
		S_COMMON_CASE_3u_M1: begin 
			//calls U values for next cycle
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_U;
			address_U <= address_U + 1'b1;

			//recieved V odd value from arithmitic and multipliers
			Buffer_V_odd[31:0] <=  M1 - M2 + M3 + 32'd128;

            select <= 8'd4;
			state_M1 <= S_COMMON_CASE_4u_M1;
		end
		S_COMMON_CASE_4u_M1: begin 
        	SRAM_we_n <= 1'b0;

			//writes RGB values obtaned using u and v odd value
			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_R_clipped, Buffer_G_clipped};
			//Buffers B odd value as it needs to be written with R even
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1;
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

            select <= 8'd5;
			state_M1 <= S_COMMON_CASE_5u_M1;
		end
		S_COMMON_CASE_5u_M1: begin 
			SRAM_we_n <= 1'b1;
            Buffer_Y <= SRAM_read_data;

			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

  			select <= 8'd0;
    		//get out of cc and into lead out based on amount of rgb values written
			if(Column_Counter == 9'd308) begin
				state_M1 <= S_LEAD_OUT_LEAD_IN;
			end else begin
				state_M1 <= S_COMMON_CASE_0v_M1;
			end
		end


		// COMMON CASE FOR V CYCLE
		// SIMILAR TO U CYCLE, CHANGES COMMENTED BELOW
		S_LEAD_OUT_LEAD_IN: begin
			select <= 8'd1;
			U_data_register <= {U_data_register[39:0], SRAM_read_data[15:8]}; 
			V_data_register <= {V_data_register[39:0], Buffer_V[15:8]}; 
			Buffer_U[7:0] <= SRAM_read_data[7:0];

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Bo_clipped, Buffer_R_clipped};
			Buffer_Go_clipped <= Buffer_G_clipped;
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			state_M1 <= S_LEAD_OUT1_M1;
		end
		
		S_COMMON_CASE_0v_M1: begin // 7/13/19
			//recieved u values here instead of v, one u value is placed in directly
			U_data_register <= {U_data_register[39:0], SRAM_read_data[15:8]}; 
			V_data_register <= {V_data_register[39:0], Buffer_V[15:8]}; 
			//other u value is buffered
			Buffer_U[7:0] <= SRAM_read_data[7:0];

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Bo_clipped, Buffer_R_clipped};
			Buffer_Go_clipped <= Buffer_G_clipped;
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;
			
			select <= 8'd1;
			state_M1 <= S_COMMON_CASE_1v_M1;
		end
		S_COMMON_CASE_1v_M1: begin 
			Column_Counter <= Column_Counter + 2'd2;

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Go_clipped, Buffer_Bo_clipped};

			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

			select <= 8'd2;
			state_M1 <= S_COMMON_CASE_2v_M1;
		end
		S_COMMON_CASE_2v_M1: begin
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_Y;
			address_Y <= address_Y + 1'b1;

			Buffer_U_odd[31:0] <= M1 - M2 + M3 + 32'd128;

			select <= 8'd3;
			state_M1 <= S_COMMON_CASE_3v_M1;
		end
		S_COMMON_CASE_3v_M1: begin 
			//calls v for next cycle
			SRAM_we_n <= 1'b1;
			SRAM_address <= address_V;
			address_V <= address_V + 1'b1;

			Buffer_V_odd[31:0] <=  M1 - M2 + M3 + 32'd128;

			select <= 8'd4;
			state_M1 <= S_COMMON_CASE_4v_M1;
		end
		S_COMMON_CASE_4v_M1: begin 
			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_R_clipped, Buffer_G_clipped};
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			select <= 8'd5;
			state_M1 <= S_COMMON_CASE_5v_M1;
		end
		S_COMMON_CASE_5v_M1: begin 
			SRAM_we_n <= 1'b1;

			Buffer_Y <= SRAM_read_data;

			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

			select <= 8'd0;
			state_M1 <= S_COMMON_CASE_0u_M1;
		end


		//SIMILAR TO V CYCLE changes commented below
		// lead out repeats until u and v 159 have been pushed in register appropriate amount of times
		S_LEAD_OUT_LEAD_IN: begin
			//first cycle is different as it needs to recieve the u 158 and 159 values
			//buffers u159 for future lead out cycles and 
			select <= 8'd1;
			U_data_register <= {U_data_register[39:0], SRAM_read_data[15:8]}; 
			V_data_register <= {V_data_register[39:0], Buffer_V[15:8]}; 
			Buffer_U[7:0] <= SRAM_read_data[7:0];

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Bo_clipped, Buffer_R_clipped};
			Buffer_Go_clipped <= Buffer_G_clipped;
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			state_M1 <= S_LEAD_OUT1_M1;
		end

		// LEAD OUT STATES
		S_LEAD_OUT0_M1: begin 
			select <= 8'd1;
			U_data_register <= {U_data_register[39:0], Buffer_U[7:0]};
			V_data_register <= {V_data_register[39:0], Buffer_V[7:0]}; 

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Bo_clipped, Buffer_R_clipped};
			Buffer_Go_clipped <= Buffer_G_clipped;
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			state_M1 <= S_LEAD_OUT1_M1;
		end
		S_LEAD_OUT1_M1: begin 
			select <= 8'd2;
			Column_Counter <= Column_Counter + 2'd2;

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_Go_clipped, Buffer_Bo_clipped};

			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

			state_M1 <= S_LEAD_OUT2_M1;
		end
		S_LEAD_OUT2_M1: begin 
		//leadout check is here as the last rgb value will be written in S_LEAD_OUT1_M1
			if(Lead_Out_Counter == 4'd5) begin //exit lead out when enough 159 calues have been pushed
				//resets varibels for next lead in
				//addresses are not reset as they need to maintain their value throughout the image
				SRAM_we_n <= 1'b1;
				SRAM_write_data <= 16'd0;
				SRAM_address <= 18'd0;
				select <= 0;
				U_data_register <= 48'd0;
				V_data_register <= 48'd0;
				Lead_Out_Counter <= 4'd0;
				Column_Counter <= 9'd0;
				Buffer_U <= 8'd0;
				Buffer_V <= 16'd0;
				Buffer_R <= 32'd0;
				Buffer_G <= 32'd0;
				Buffer_B <= 32'd0;
				Buffer_U_odd <= 32'd0;
				Buffer_V_odd <= 32'd0;
				Buffer_Bo_clipped <= 8'd0;
				Buffer_Go_clipped <= 8'd0;
				address_Y <= address_Y - 1'b1;
				Row_Counter <= Row_Counter + 1'b1;
				
				state_M1 <= S_IDLE_M1;
			end else begin
				select <= 8'd3;
				SRAM_we_n <= 1'b1;
				SRAM_address <= address_Y;
				address_Y <= address_Y + 1'b1;

				Buffer_U_odd[31:0] <= M1 - M2 + M3 + 32'd128;

				state_M1 <= S_LEAD_OUT3_M1;
			end
		end
		S_LEAD_OUT3_M1: begin // 10/16/22
			select <= 8'd4;

			Buffer_V_odd[31:0] <=  M1 - M2 + M3 + 32'd128;

			state_M1 <= S_LEAD_OUT4_M1;
		end
		S_LEAD_OUT4_M1: begin // 11/17/23
			select <= 8'd5;

			SRAM_we_n <= 1'b0;
			SRAM_address <= address_write;
			address_write <= address_write + 1'b1;
			SRAM_write_data <= {Buffer_R_clipped, Buffer_G_clipped};
			Buffer_Bo_clipped <= Buffer_B_clipped;

			Buffer_R <= M1; 
			Buffer_G <= M1 - M2;
			Buffer_B <= M1 + M3;

			state_M1 <= S_LEAD_OUT5_M1;
		end 
		S_LEAD_OUT5_M1: begin // 12/18/24
			select <= 8'd0;
			SRAM_we_n <= 1'b1;
			Buffer_Y <= SRAM_read_data;

			Buffer_R <= Buffer_R + M2;
			Buffer_G <= Buffer_G - M3;

			Lead_Out_Counter <= Lead_Out_Counter + 1'b1;
			state_M1 <= S_LEAD_OUT0_M1;
		end
		
        endcase
    end
end
endmodule