

# add waves to waveform
add wave Clock_50

add wave -divider {Basic Values Below:}
add wave uut/SRAM_we_n
add wave -unsigned uut/SRAM_address
add wave -hexadecimal uut/SRAM_write_data
add wave -hexadecimal uut/SRAM_read_data

add wave -divider {skr}
add wave -hexadecimal uut/Milestone1_unit/U_data_register
add wave -hexadecimal uut/Milestone1_unit/V_data_register
add wave -hexadecimal uut/Milestone1_unit/Buffer_Y
add wave -hexadecimal uut/Milestone1_unit/Buffer_U
add wave -hexadecimal uut/Milestone1_unit/Buffer_V

add wave -divider {skr}
add wave -decimal uut/Milestone1_unit/temp_arithmitic0
add wave -decimal uut/Milestone1_unit/temp_arithmitic1
add wave -decimal uut/Milestone1_unit/temp_arithmitic2

add wave -divider {skr}
add wave -decimal uut/Milestone1_unit/M1
add wave -decimal uut/Milestone1_unit/M2
add wave -decimal uut/Milestone1_unit/M3
add wave -divider {skr}
add wave -hexadecimal uut/Milestone1_unit/Buffer_R
add wave -hexadecimal uut/Milestone1_unit/Buffer_G
add wave -hexadecimal uut/Milestone1_unit/Buffer_B
add wave -divider {skr}
add wave -hexadecimal uut/Milestone1_unit/Buffer_R_clipped
add wave -hexadecimal uut/Milestone1_unit/Buffer_G_clipped
add wave -hexadecimal uut/Milestone1_unit/Buffer_B_clipped

add wave -divider {skr}
add wave -unsigned uut/Milestone1_unit/state_M1
add wave -unsigned uut/Milestone1_unit/select