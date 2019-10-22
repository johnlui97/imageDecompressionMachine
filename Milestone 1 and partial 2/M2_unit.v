`timescale 1ns/100ps
`default_nettype none

`include "define_state.h"

// This is the top module
// It connects the SRAM and VGA together
// It will first write RGB data of an image with 8x8 rectangles of size 40x30 pixels into the SRAM
// The VGA will then read the SRAM and display the image
module M2_unit (
		input logic CLOCK_50_I,                   // 50 MHz clock
		input logic Resetn,
		input logic M2_start,

		input logic signed [15:0] SRAM_read_data,
		input logic [31:0] DRAM_0_Read_Data_a,
		input logic [31:0] DRAM_0_Read_Data_b,
		input logic [31:0] DRAM_1_Read_Data_a,
		input logic [31:0] DRAM_1_Read_Data_b,
		input logic [31:0] DRAM_2_Read_Data_a,
		input logic [31:0] DRAM_2_Read_Data_b,

	////////
		output logic SRAM_we_n,
		output logic DRAM_0_we_a,
		output logic DRAM_0_we_b,
		output logic DRAM_1_we_a,
		output logic DRAM_1_we_b,
		output logic DRAM_2_we_a,
		output logic DRAM_2_we_b,

		output logic [17:0] SRAM_address,
		output logic [6:0] DRAM_0_Address_a,
		output logic [6:0] DRAM_0_Address_b,
		output logic [6:0] DRAM_1_Address_a,
		output logic [6:0] DRAM_1_Address_b,
		output logic [6:0] DRAM_2_Address_a,
		output logic [6:0] DRAM_2_Address_b,

		output logic [15:0] SRAM_write_data,
		output logic signed [31:0] DRAM_0_Write_Data_a,
		output logic [31:0] DRAM_0_Write_Data_b,
		output logic [31:0] DRAM_1_Write_Data_a,
		output logic [31:0] DRAM_1_Write_Data_b,
		output logic [31:0] DRAM_2_Write_Data_a,
		output logic [31:0] DRAM_2_Write_Data_b,

		output logic M2_done
);

state_M2_type state_M2;

//addressing registers and logic
logic enable;
logic [5:0] SynchronousCounter;
logic [5:0] ColumnBlockCounter;
logic [4:0] RowBlockCounter;
logic [8:0] ColumnAccumalator;
logic [8:0] RowAccumalator;
logic [17:0] rowindex_element, columnindex_element, rowindex_256_multiple, rowindex_64_multiple;

//SRAM logic
logic [15:0] SRAM_read_address; 
logic [15:0] SRAM_write_address;

//Multiplier logic and registers
logic signed [31:0]  Left_op0, Left_op1, Left_op2, Left_op3;
logic signed [31:0]  Right_op0, Right_op1, Right_op2, Right_op3;
logic signed [31:0] answer0, answer1, answer2, answer3;
logic [63:0]  Mult_Result0, Mult_Result1, Mult_Result2, Mult_Result3;
logic [7:0] clipped_S_0;
logic [7:0] clipped_S_1;
logic [7:0] clipped_S_2;
logic [7:0] clipped_S_3;

logic [31:0] Buffer_Mult2;
logic [31:0] Buffer_Mult3;

//counters
logic [6:0] LeadinCounter;
logic [6:0] FetchSCounter;
logic [7:0] FirstComputeT_Counter;
logic [6:0] WriteSCounter;
logic [6:0] LeadoutCounter;
logic [2:0] Column_Calculation_Index;
logic [7:0] WriteCounter;
logic [7:0] CommonCaseCounter;
logic [4:0] c_traversal_counter;

logic [6:0] ColumnIndex;
//////////////////////////////////////////// Set a flag for doing U and V for shortened Screen Size
logic RepetitionFlag;
logic NonRepetitionFlag;
logic LeadoutRepeatFlag;
logic c_left_transverse;

//Counting Mechanism In MilestoneII
//implementation of circuit drawn in class
always_ff @ (posedge CLOCK_50_I) begin
	if (Resetn == 1'b0) begin
		SynchronousCounter <= 18'd0;
		ColumnBlockCounter <= 18'd0;
		RowBlockCounter <= 18'd0;
	end else if(enable) begin
		SynchronousCounter <= SynchronousCounter + 1'b1;
		if(SynchronousCounter == 6'd63) begin
			if(ColumnBlockCounter == 6'd39) begin
				ColumnBlockCounter <= 6'd0;
				if(RowBlockCounter <= 5'd29) begin
					RowBlockCounter <= 5'd0;
				end else begin
					RowBlockCounter <= RowBlockCounter + 1'b1;
				end
			end else begin
				ColumnBlockCounter <= ColumnBlockCounter + 1'b1;
			end
		end
	end
end
assign columnindex_element = {9'd0, ColumnBlockCounter, SynchronousCounter[2:0]};
assign rowindex_256_multiple = {12'd0, RowBlockCounter, SynchronousCounter[5:3], 8'd0};
assign rowindex_64_multiple = {6'd0, RowBlockCounter, SynchronousCounter[5:3], 6'd0};
assign rowindex_element = rowindex_256_multiple + rowindex_64_multiple;
assign SRAM_address = (enable)? (columnindex_element + rowindex_element + 18'd76800): SRAM_write_address;

always_ff @ (posedge CLOCK_50_I) begin
	if (Resetn == 1'b0) begin
		Mult_Result0 <= 6'd0;
		Mult_Result1 <= 6'd0;
		Mult_Result2 <= 6'd0;
		Mult_Result3 <= 6'd0;

//multiplers based on states
//for either S*C or CT*T
	end else begin
		if(Column_Calculation_Index == 3'd1) begin

			Mult_Result0 <= $signed (Left_op0*Right_op0);
			Mult_Result1 <= $signed(Left_op1*Right_op1);
			Mult_Result2 <= $signed(Left_op2*Right_op2);
			Mult_Result3 <= $signed(Left_op3*Right_op3);

		end else begin

			Mult_Result0 <=  $signed (Mult_Result0 +  (Left_op0*Right_op0));
			Mult_Result1 <=  $signed (Mult_Result1 +  (Left_op1*Right_op1));
			Mult_Result2 <=  $signed (Mult_Result2 +  (Left_op2*Right_op2));
			Mult_Result3 <=  $signed (Mult_Result3 +  (Left_op3*Right_op3));

		end
	end

end
assign answer0 = Mult_Result0[31:0];
assign answer1 = Mult_Result1[31:0];
assign answer2 = Mult_Result2[31:0];
assign answer3 = Mult_Result3[31:0];

//Comb block to identofy operands based on state
always_comb begin
	Left_op0  = 6'd0;
	Right_op0 = 6'd0;
	Left_op1  = 6'd0;
	Right_op1 = 6'd0;
	Left_op2  = 6'd0;
	Right_op2 = 6'd0;
	Left_op3  = 6'd0;
	Right_op3 = 6'd0;

	if(state_M2 == S_CommonCase_T || state_M2 == S_FirstCompute_T) begin
	
		//Multiplier0
		Left_op0 = DRAM_0_Read_Data_b[31:0];
		Right_op0 = DRAM_1_Read_Data_a[15:0];
		
		//Multiplier1
		Left_op1 = DRAM_0_Read_Data_b[31:0];
		Right_op1 = DRAM_1_Read_Data_a[31:16];
		
		//Multiplier2
		Left_op2 = DRAM_0_Read_Data_b[31:0];
		Right_op2 = DRAM_1_Read_Data_b[15:0];
		
		//Multiplier3
		Left_op3 = DRAM_0_Read_Data_b[31:0];
		Right_op3 = DRAM_1_Read_Data_b[31:16];
		
	end if(state_M2 == S_CommonCase_S) begin // May need Fixing

		//Multiplier0
		Left_op0 = DRAM_0_Read_Data_a[31:0];
		Right_op0 = DRAM_1_Read_Data_a[31:0];
		
		//Multiplier1
		Left_op1 = DRAM_0_Read_Data_a[31:0];
		Right_op1 = DRAM_1_Read_Data_b[31:0];
		
		//Multiplier2
		Left_op2 = DRAM_0_Read_Data_a[31:0];
		Right_op2 = DRAM_2_Read_Data_a[31:0];
		
		//Multiplier3
		Left_op3 = DRAM_0_Read_Data_a[31:0];
		Right_op3 = DRAM_2_Read_Data_b[31:0];

	end
	//clipping final values
	clipped_S_0 = (DRAM_0_Read_Data_a[31] == 1'b1) ? 8'd0: ((DRAM_0_Read_Data_a[31:24]) ? 8'd255: DRAM_0_Read_Data_a[15:0]); 
	clipped_S_1 = (DRAM_0_Read_Data_b[31] == 1'b1) ? 8'd0: ((DRAM_0_Read_Data_b[31:24]) ? 8'd255: DRAM_0_Read_Data_b[31:16]);
	clipped_S_2 = (DRAM_1_Read_Data_a[31] == 1'b1) ? 8'd0: ((DRAM_1_Read_Data_a[31:24]) ? 8'd255: DRAM_1_Read_Data_a[15:0]);
	clipped_S_3 = (DRAM_1_Read_Data_b[31] == 1'b1) ? 8'd0: ((DRAM_1_Read_Data_b[31:24]) ? 8'd255: DRAM_1_Read_Data_b[31:16]);
	
end

always_ff @ (posedge CLOCK_50_I or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		enable <= 1'b0;
		SRAM_write_address <= 18'd0;
		
		LeadinCounter <= 6'd0;
		FetchSCounter <= 6'd0;
		FirstComputeT_Counter <= 6'd0;
		WriteSCounter <= 6'd0;
		LeadoutCounter <= 6'd0;
		Column_Calculation_Index <= 3'd0;
		c_left_transverse <= 1'b1;
		c_traversal_counter <= 5'd0;

		DRAM_0_Address_a <= 7'd0;
		DRAM_0_Address_b <= 7'd63;
		DRAM_0_Write_Data_a <= 32'd0;
		DRAM_0_Write_Data_b <= 32'd0;
		DRAM_0_we_a <= 1'b0;
		DRAM_0_we_b <= 1'b0;
		
		DRAM_1_Address_a <= 7'd0;
		DRAM_1_Address_b <= 7'd1;
		DRAM_1_Write_Data_a <= 6'd0;
		DRAM_1_Write_Data_b <= 6'd0;
		DRAM_1_we_a <= 1'b0;
		DRAM_1_we_b <= 1'b0;
		
		DRAM_2_Address_a <= 7'd0;
		DRAM_2_Address_b <= 7'd1;
		DRAM_2_Write_Data_a <= 6'd0;
		DRAM_2_Write_Data_b <= 6'd0;
		DRAM_2_we_a <= 1'b0;
		DRAM_2_we_b <= 1'b0;

		M2_done <= 1'b0;
		state_M2 <= S_IDLE_M2;	
	end else begin
		case (state_M2)
		S_IDLE_M2: begin
		//begin fetching S values
			if (M2_start) begin			
				enable <= 1'b1;
				SRAM_we_n <= 1'b1;
				state_M2 <= S_Leadin_PreLoad_0;		
			end
		end
		
		S_Leadin_PreLoad_0: begin
		
			// This state is to simply start the SRAM Reading Process
			// SRAM_Read_data will show in S_Leadin_FetchS
			enable <= 1'b1;
			SRAM_we_n <= 1'b1;

			state_M2 <= S_Leadin_Preload_1;
			
		end
		
		S_Leadin_Preload_1: begin
		
			// This state is to simply start the SRAM Reading Process
			// SRAM_Read_data will show in S_Leadin_FetchS
			enable <= 1'b1;
			SRAM_we_n <= 1'b1;


			state_M2 <= S_Leadin_Preload_2;
		
		end

		S_Leadin_Preload_2: begin
		
			// This state is to simply start the SRAM Reading Process
			// SRAM_Read_data will show in S_Leadin_FetchS
			enable <= 1'b1;
			SRAM_we_n <= 1'b1;

			DRAM_0_we_a <= 1'b1;
			DRAM_0_Write_Data_a <= $signed(SRAM_read_data>>>8);


			state_M2 <= S_Leadin_FetchS;
		
		end
	
		//This state loops until all s values for the block are fetched
		S_Leadin_FetchS: begin
			enable <= 1'b1;

			// Continue Reading From the SRAM
			SRAM_we_n <= 1'b1;
			
			// Prepare to write the SRAM Values we read in the Preload States into DRAM
			DRAM_0_we_a <= 1'b1;
			
			// We want to store S' as a 32 bit value, which is why it will be padded
			// with 32 bits and we simply increment the address.
			DRAM_0_Write_Data_a <= $signed(SRAM_read_data >>> 8);
			DRAM_0_Address_a <= DRAM_0_Address_a + 7'd1;

			if(SynchronousCounter == 6'd63) begin
				state_M2 <= S_Leadin_Transition0;
				enable <= 1'b0;
			end
		end
		
		S_Leadin_Transition0: begin
		// Buffer State for the Writing Process to Catch up, we have allocated 2 states
		// to account for this latency.
			DRAM_0_we_a <= 1'b1;	
			DRAM_0_Write_Data_a <= $signed(SRAM_read_data >>> 8);
			DRAM_0_Address_a <= DRAM_0_Address_a + 7'd1;

			state_M2 <= S_Leadin_Transition1;
		end
		
		S_Leadin_Transition1: begin
		//begins to call S values and C values
		// DRAM_0 Line A Manipulations
			DRAM_0_we_a <= 1'b1;	
			DRAM_0_Write_Data_a <= $signed(SRAM_read_data >>> 8);
			DRAM_0_Address_a <= DRAM_0_Address_a + 7'd1;
		
		// DRAM_0 Line B Manipulations
			
			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;

			FirstComputeT_Counter <= 7'd0;

			state_M2 <= S_Leadin_Transition2;
		end
		
		S_Leadin_Transition2: begin
			DRAM_0_we_a <= 1'b0;	
			DRAM_0_Write_Data_a <= $signed(SRAM_read_data >>> 8);
			DRAM_0_Address_a <= 7'd127;
			DRAM_0_Address_b <= 7'd0;

			// DRAM_0 Line B Manipulations
			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			
			state_M2 <= S_Leadin_Transition3;
		end

		S_Leadin_Transition3: begin
			// DRAM_0 Line B Manipulations
			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			DRAM_1_Address_a <= DRAM_1_Address_a + 7'd4;
			DRAM_1_Address_b <= DRAM_1_Address_b + 7'd4;

			DRAM_0_Address_b <= DRAM_0_Address_b + 7'd1;

			DRAM_2_we_b <= 1'b0;
			DRAM_2_we_a <= 1'b0;
			DRAM_2_Address_a <= 7'd122;
			DRAM_2_Address_b <= 7'd123;

			Column_Calculation_Index <= Column_Calculation_Index + 3'd1;
			state_M2 <= S_FirstCompute_T;
		end

		//iterates through S and C matricies to compute matrix multiplication
		S_FirstCompute_T: begin
			Column_Calculation_Index <= Column_Calculation_Index + 3'd1;

			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			DRAM_1_Address_a <= DRAM_1_Address_a + 7'd4;
			DRAM_1_Address_b <= DRAM_1_Address_b + 7'd4;
			
			DRAM_0_we_b <= 1'b0;
			DRAM_0_Address_b <= DRAM_0_Address_b + 7'd1;

			if(Column_Calculation_Index == 6'd7) begin
				c_traversal_counter <= c_traversal_counter + 5'd1;

				//if on left half of matrix is done
				if(c_traversal_counter == 5'd6) begin
					c_left_transverse <= ~c_left_transverse;
				end
				//when entire matrix calculation is done
				if(c_traversal_counter == 5'd15 && c_left_transverse <= 1'b0) begin
					state_M2 <= S_FirstCompute_T_Transition0;
				end

				//reset when one iteration fo C is done
				if(c_left_transverse) begin
					DRAM_1_Address_a <= 7'd0;
					DRAM_1_Address_b <= 7'd1;
				end else begin
					DRAM_1_Address_a <= 7'd2;
					DRAM_1_Address_b <= 7'd3;		
				end	
			end

			//writing values once accumulator is done processing
			if(Column_Calculation_Index == 6'd1) begin
				DRAM_2_we_a <= 1'b1;
				DRAM_2_we_b <= 1'b1;
				DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
				DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
				DRAM_2_Write_Data_a <= answer0;
				DRAM_2_Write_Data_b <= answer1;

				Buffer_Mult2 <= answer2;
				Buffer_Mult3 <= answer3;
			end

			if(Column_Calculation_Index == 6'd2) begin
				DRAM_2_we_a <= 1'b1;
				DRAM_2_we_b <= 1'b1;
				DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
				DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
				DRAM_2_Write_Data_a <= Buffer_Mult2;
				DRAM_2_Write_Data_b <= Buffer_Mult3;
			end

		end
		
		//trasnition to Cs state
		//catches up to last two writes that need to be dobe
		S_FirstCompute_T_Transition0: begin

			DRAM_2_we_a <= 1'b1;
			DRAM_2_we_b <= 1'b1;
			DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
			DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
			DRAM_2_Write_Data_a <= answer0;
			DRAM_2_Write_Data_b <= answer1;

			Buffer_Mult2 <= answer2;
			Buffer_Mult3 <= answer3;

			enable <= 1'b1;
			SRAM_we_n <= 1'b1;
			
			state_M2 <= S_Preloading_S_Calculations0;
		end
		
		//repeating same process as Compute T but with T and CT values
		S_Preloading_S_Calculations0: begin
			DRAM_2_we_a <= 1'b1;
			DRAM_2_we_b <= 1'b1;
			DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
			DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
			DRAM_2_Write_Data_a <= Buffer_Mult2;
			DRAM_2_Write_Data_b <= Buffer_Mult3;

			enable <= 1'b1;
			SRAM_we_n <= 1'b1;

			state_M2 <= S_Preloading_S_Calculations1;
		end
		
		S_Preloading_S_Calculations1: begin
			
			enable <= 1'b1;
			SRAM_we_n <= 1'b1;
			DRAM_2_we_a <= 1'b0;
			DRAM_2_we_b <= 1'b0;
			DRAM_2_Address_a <= 7'd0;
			DRAM_2_Address_b <= 7'd127;
			
			state_M2 <= S_Preloading_S_Calculations2;
		end
		
		S_Preloading_S_Calculations2: begin
		
			SRAM_we_n <= 1'b1;
			enable <= 1'b1;
			
			DRAM_0_Address_a <= 6'd0;
			DRAM_0_Address_b <= 6'd1;

			DRAM_1_we_b <= 1'b0;
			DRAM_1_we_a <= 1'b0;
			DRAM_1_Address_a <= 6'd0;
			DRAM_1_Address_b <= 6'd1;

			DRAM_2_we_a <= 1'b0;
			DRAM_2_Address_a <= 6'd0;

			FetchSCounter <= 6'd0;
			CommonCaseCounter <= 7'd0;
			Column_Calculation_Index <= 6'd0;
			c_traversal_counter <= 6'd0;
			c_left_transverse <= 1'b1;
			
			state_M2 <= S_CommonCase_S;

		end

		S_CommonCase_S: begin
			
			Column_Calculation_Index <= Column_Calculation_Index + 3'd1;

			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			DRAM_1_Address_a <= DRAM_1_Address_a + 7'd4;
			DRAM_1_Address_b <= DRAM_1_Address_b + 7'd4;

			if(FetchSCounter < 6'd62) begin

				enable <= 1'b1;
				SRAM_we_n <= 1'b1;

				DRAM_0_Write_Data_a <= $signed(SRAM_read_data);
				DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
				FetchSCounter <= FetchSCounter + 6'd1;

			end

			if(Column_Calculation_Index == 6'd7) begin
				c_traversal_counter <= c_traversal_counter + 5'd1;

				if(c_traversal_counter == 5'd6) begin
					c_left_transverse <= ~c_left_transverse;
				end
				if(c_traversal_counter == 5'd15 && c_left_transverse <= 1'b0) begin
					state_M2 <= S_CommonCase_T_Transition0;
				end

				if(c_left_transverse) begin
					DRAM_1_Address_a <= 7'd0;
					DRAM_1_Address_b <= 7'd1;
				end else begin
					DRAM_1_Address_a <= 7'd2;
					DRAM_1_Address_b <= 7'd3;		
				end	
			end

			if(Column_Calculation_Index == 6'd1) begin
				DRAM_2_we_a <= 1'b1;
				DRAM_2_we_b <= 1'b1;
				DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
				DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
				DRAM_2_Write_Data_a <= answer0;
				DRAM_2_Write_Data_b <= answer1;

				Buffer_Mult2 <= answer2;
				Buffer_Mult3 <= answer3;
			end

			if(Column_Calculation_Index == 6'd2) begin
				DRAM_2_we_a <= 1'b1;
				DRAM_2_we_b <= 1'b1;
				DRAM_2_Address_a <= DRAM_2_Address_a + 2'd2;
				DRAM_2_Address_b <= DRAM_2_Address_b + 2'd2;
				DRAM_2_Write_Data_a <= Buffer_Mult2;
				DRAM_2_Write_Data_b <= Buffer_Mult3;
			end


		end
		
		S_CommonCase_T_Transition0: begin
	
			DRAM_0_we_a <= 1'b1;
			DRAM_0_we_b <= 1'b0;
			
			DRAM_0_Write_Data_a <= Buffer_Mult2;
			DRAM_0_Write_Data_b <= Buffer_Mult3;
			
			DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
			DRAM_0_Address_b <= DRAM_0_Address_b + 6'd1;
			
			state_M2 <= S_CommonCase_T_Transition1;
			
		end
		
		S_CommonCase_T_Transition1: begin
		
			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			DRAM_0_we_b <= 1'b0;
			
			DRAM_0_Address_b <= DRAM_0_Address_b + 6'd1;
			DRAM_1_Address_a <= DRAM_0_Address_a + 6'd1;
			DRAM_1_Address_b <= DRAM_0_Address_b + 6'd1;
			
			state_M2 <= S_CommonCase_T_Transition2;
		
		end
		
		S_CommonCase_T_Transition2: begin
		
			DRAM_1_we_a <= 1'b0;
			DRAM_1_we_b <= 1'b0;
			DRAM_0_we_b <= 1'b0;
			
			DRAM_0_Address_b <= DRAM_0_Address_b + 6'd1;
			DRAM_1_Address_a <= DRAM_0_Address_a + 6'd2;
			DRAM_1_Address_b <= DRAM_0_Address_b + 6'd1;
			
			state_M2 <= S_CommonCase_T;
		
		end
		
		S_CommonCase_T: begin
		
		if(RowBlockCounter < 6'd29 && ColumnBlockCounter < 6'd39) begin
		
				if(WriteSCounter < 6'd31) begin
				
				//Implement Keiths Algorithm:
				
					SRAM_we_n <= 1'b0;
					DRAM_0_we_a <= 1'b0;
					SRAM_write_address <= DRAM_0_Read_Data_a;
					DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
					
					WriteSCounter <= WriteSCounter + 6'd1;
				
				end
				
				if(SynchronousCounter < 6'd63) begin
				
					enable <= 1'b1;
				
					DRAM_0_we_b <= 1'b0;
					DRAM_1_we_a <= 1'b0;
					DRAM_1_we_b <= 1'b0;
					
					DRAM_0_Address_b <= DRAM_0_Address_b + 6'd1;
					DRAM_1_Address_a <= DRAM_1_Address_a + 6'd1;
					DRAM_1_Address_b <= DRAM_1_Address_b + 6'd1;
					
					if(ColumnIndex == 6'd7) begin
					
						DRAM_2_we_a <= 1'b1;
						DRAM_2_we_b <= 1'b1;
						
						DRAM_2_Write_Data_a <= answer0;
						DRAM_2_Write_Data_b <=  answer1;
						
						DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
						DRAM_2_Address_b <= DRAM_2_Address_b + 6'd1;
					
					end else if (ColumnIndex == 6'd0) begin
					
						DRAM_2_we_a <= 1'b1;
						DRAM_2_we_b <= 1'b1;
						
						DRAM_2_Write_Data_a <= Buffer_Mult2;
						DRAM_2_Write_Data_b <=  Buffer_Mult3;
						
						DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
						DRAM_2_Address_b <= DRAM_2_Address_b + 6'd1;
					
					end
				end
				
			end else begin
				state_M2 <= S_LeadOut_Transition_In0;
			end
			state_M2 <= S_CommonCase_S;
		end
		
		S_LeadOut_Transition_In0: begin
		
			DRAM_2_we_a <= 1'b0;
			DRAM_2_we_b <= 1'b0;
						
		
			state_M2 <= S_LeadoutTransition_In1;
		end
		
		S_LeadoutTransition_In1: begin
		
			DRAM_2_we_a <= 1'b0;
			DRAM_2_we_b <= 1'b0;
						
			
			DRAM_2_Address_a <= 6'd0;
			DRAM_2_Address_a <= 6'd0;
		
			state_M2 <= S_PreLoadS_Values0;
		end
		
		S_PreLoadS_Values0: begin
		
			DRAM_2_we_a <= 1'b0;
			DRAM_2_we_b <= 1'b0;
			
			DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
			DRAM_2_Address_b <= DRAM_2_Address_b + 6'd1;
		
			state_M2 <= S_PreLoadS_Values1;
		end
		
		S_PreLoadS_Values1: begin
					
			DRAM_2_we_a <= 1'b0;
			DRAM_2_we_b <= 1'b0;
			
			DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
			DRAM_2_Address_b <= DRAM_2_Address_b + 6'd1;
			
			LeadoutRepeatFlag <= 1'b1;
			WriteCounter <= 6'd0;

			state_M2 <= S_LeadOut_ComputeS;
		end
		
		S_LeadOut_ComputeS: begin
		
			if(LeadoutRepeatFlag == 1'b1) begin
			
				enable <= 1'b1;
				
				// DRAM_0 Line A Manipulations
				DRAM_0_we_a <= 1'b0;
				DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
				
				// DRAM_1 Line A Manipulations
				DRAM_1_we_a <= 1'b0;
				DRAM_1_Address_a <= DRAM_1_Address_a + 6'd1;
				
				// DRAM_1 Line B Manipulations
				DRAM_1_we_b <= 1'b0;
				DRAM_1_Address_b <= DRAM_0_Address_b + 6'd1;
				
			end else begin		
				RepetitionFlag <= 1'b1;
				DRAM_2_Address_a <= 6'd0;
				DRAM_2_Address_b <= 6'd0;
				
				DRAM_2_we_a <= 1'b1;
				DRAM_2_we_b <= 1'b1;
				
				DRAM_2_Write_Data_a <= answer0;
				DRAM_2_Write_Data_b <= answer1;
				
				DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
				DRAM_2_Address_a <= DRAM_2_Address_b + 6'd1;
				
			end
			if(SynchronousCounter == 6'd56) begin
				if(RepetitionFlag == 1'b1) begin
				
					enable <= 1'b1;
				
					if(WriteCounter <= 6'd7) begin
						//// Writing Values in DRAM 2 For T Values
						
						DRAM_2_we_a <= 1'b1;
						DRAM_2_we_b <= 1'b1;
						
						//////////////////////////////////////////////
						////////////////////////////////////////////// Fix These Write one Cycle at a time
						DRAM_2_Write_Data_a <= answer0;
						DRAM_2_Write_Data_b <= answer1;
						
						DRAM_2_Address_a <= DRAM_2_Address_a + 6'd1;
						DRAM_2_Address_a <= DRAM_2_Address_b + 6'd1;
						
					end
					
					//// Continue Reading from DRAM 0 and 1 All Reading below
					// DRAM_0 Line A Manipulations
					DRAM_0_we_a <= 1'b0;
					DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
					
					// DRAM_1 Line A Manipulations
					DRAM_1_we_a <= 1'b0;
					DRAM_1_Address_a <= DRAM_1_Address_a + 6'd1;
					
					// DRAM_1 Line B Manipulations
					DRAM_1_we_b <= 1'b0;
					DRAM_1_Address_b <= DRAM_0_Address_b + 6'd1;	
					
				end
				state_M2 <= S_LeadOut_ComputeS_Transition0;
			end
		end
		S_LeadOut_ComputeS_Transition0: begin
			
			DRAM_0_we_a <= 1'b1;
			DRAM_0_we_b <= 1'b1;
			
			
			DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
			DRAM_0_Address_a <= DRAM_0_Address_b + 6'd1;
			
			state_M2 <= S_LeadOut_ComputeS_Transition1;
			
		end
		
		S_LeadOut_ComputeS_Transition1: begin
		
			DRAM_0_we_a <= 1'b0;
			DRAM_0_we_b <= 1'b0;
			
	
			state_M2 <= S_LeadOut_ComputeS_Transition2;
		end
		
		S_LeadOut_ComputeS_Transition2: begin
		
			DRAM_0_we_a <= 1'b0;
			DRAM_0_we_b <= 1'b0;
			
		
			state_M2 <= S_Leadout_WriteS;
		
		end
		
		S_Leadout_WriteS: begin
		
			if(LeadoutCounter < 7'd65) begin
			
				SRAM_we_n <= 1'b1;
				
				DRAM_0_we_a <= 1'b1;
				DRAM_0_Address_a <= {16'd0,SRAM_read_data};
				DRAM_0_Address_a <= DRAM_0_Address_a + 6'd1;
				
				LeadinCounter <= LeadinCounter + 6'd1;
			
			end else begin
				state_M2 <= S_Leadin_Transition0;
			end
		
			state_M2 <= S_IDLE_M2; 
		end
		default: state_M2 <= S_IDLE_M2;
		endcase
	end
end
endmodule