# add waves to waveform
add wave Clock_50

add wave -divider {Basic Values Below:}
add wave uut/SRAM_we_n
add wave -unsigned uut/SRAM_address
add wave -decimal uut/SRAM_write_data
add wave -decimal uut/SRAM_read_data
add wave -divider {Basic Values Below:}
add wave -divider {States Below:}
add wave -decimal uut/top_state
add wave -unsigned uut/Milestone2_unit/state_M2
add wave -unsigned uut/Milestone2_unit/enable
add wave -divider {States Below:}
add wave -unsigned uut/Milestone2_unit/FetchSCounter
add wave -unsigned uut/Milestone2_unit/FirstComputeT_Counter
add wave -unsigned uut/Milestone2_unit/CommonCaseCounter
add wave -unsigned uut/Milestone2_unit/c_traversal_counter
add wave -unsigned uut/Milestone2_unit/Left_op0
add wave -unsigned uut/Milestone2_unit/Left_op1
add wave -unsigned uut/Milestone2_unit/Left_op2
add wave -unsigned uut/Milestone2_unit/Left_op3
add wave -unsigned uut/Milestone2_unit/Right_op0
add wave -unsigned uut/Milestone2_unit/Right_op1
add wave -unsigned uut/Milestone2_unit/Right_op2
add wave -unsigned uut/Milestone2_unit/Right_op3
add wave -decimal uut/Milestone2_unit/answer0
add wave -decimal uut/Milestone2_unit/answer1
add wave -decimal uut/Milestone2_unit/answer2
add wave -decimal uut/Milestone2_unit/answer3
add wave -unsigned uut/Milestone2_unit/Buffer_Mult2
add wave -unsigned uut/Milestone2_unit/Buffer_Mult3
add wave -divider {DRAM_0:}
add wave -unsigned uut/Milestone2_unit/DRAM_0_we_a;
add wave -unsigned uut/Milestone2_unit/DRAM_0_we_b;
add wave -unsigned uut/Milestone2_unit/DRAM_0_Address_a;
add wave -unsigned uut/Milestone2_unit/DRAM_0_Address_b;
add wave -unsigned uut/DRAM_0_Read_Data_a;
add wave -unsigned uut/DRAM_0_Read_Data_b;
add wave -unsigned uut/DRAM_0_Write_Data_a;
add wave -unsigned uut/DRAM_0_Write_Data_b;
add wave -divider {DRAM_1:}
add wave -unsigned uut/Milestone2_unit/DRAM_1_we_a;
add wave -unsigned uut/Milestone2_unit/DRAM_1_we_b;
add wave -unsigned uut/Milestone2_unit/DRAM_1_Address_a;
add wave -unsigned uut/Milestone2_unit/DRAM_1_Address_b;
add wave -hexadecimal uut/DRAM_1_Read_Data_a;
add wave -hexadecimal uut/DRAM_1_Read_Data_b;
add wave -divider {DRAM_1:}
add wave -unsigned uut/Milestone2_unit/DRAM_2_we_a;
add wave -unsigned uut/Milestone2_unit/DRAM_2_we_b;
add wave -unsigned uut/Milestone2_unit/DRAM_2_Address_a;
add wave -unsigned uut/Milestone2_unit/DRAM_2_Address_b;
add wave -unsigned uut/DRAM_2_Read_Data_a;
add wave -unsigned uut/DRAM_2_Read_Data_b;
add wave -unsigned uut/DRAM_2_Write_Data_a;
add wave -unsigned uut/DRAM_2_Write_Data_b;