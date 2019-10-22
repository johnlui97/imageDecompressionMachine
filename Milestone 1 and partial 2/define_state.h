`ifndef DEFINE_STATE

// This defines the states
typedef enum logic [3:0] {
	S_IDLE,
	S_ENABLE_UART_RX,
	S_WAIT_UART_RX,
	S_PROJECT_DELAY,
	S_Milestone_1,
	S_Milestone_2,
	S_Milestone_3
} top_state_type;

typedef enum logic [7:0] {
	S_IDLE_M1,
	S_LEADIN_0_M1,
	S_LEADIN_1_M1,
	S_LEADIN_2_M1,
	S_LEADIN_3_M1,
	S_LEADIN_4_M1,
	S_LEADIN_5_M1,
	S_LEADIN_6_M1,
	S_LEADIN_7_M1,
	S_LEADIN_8_M1,
	S_COMMON_CASE_0u_M1,
	S_COMMON_CASE_1u_M1,
	S_COMMON_CASE_2u_M1,
	S_COMMON_CASE_3u_M1,
	S_COMMON_CASE_4u_M1,
	S_COMMON_CASE_5u_M1,
	S_COMMON_CASE_0v_M1,
	S_COMMON_CASE_1v_M1,
	S_COMMON_CASE_2v_M1,
	S_COMMON_CASE_3v_M1,
	S_COMMON_CASE_4v_M1,
	S_COMMON_CASE_5v_M1,
	S_LEAD_OUT_LEAD_IN,
	S_LEAD_OUT0_M1,
	S_LEAD_OUT1_M1,
	S_LEAD_OUT2_M1,
	S_LEAD_OUT3_M1,
	S_LEAD_OUT4_M1,
	S_LEAD_OUT5_M1,
	S_LEAD_OUT6_M1
} state_M1_type;

typedef enum logic [7:0] {
	S_IDLE_M2,
	S_Leadin_PreLoad_0,
	S_Leadin_Preload_1,
	S_Leadin_Preload_2,
	S_Leadin_FetchS,
	S_Leadin_Transition0,
	S_Leadin_Transition1,
	S_Leadin_Transition2,
	S_Leadin_Transition3,
	S_FirstCompute_T,
	S_FirstCompute_T_Transition0,
	S_Preloading_S_Calculations0,
	S_Preloading_S_Calculations1,
	S_Preloading_S_Calculations2,
	S_CommonCase_S,
	S_CommonCase_T_Transition0,
	S_CommonCase_T_Transition1,
	S_CommonCase_T_Transition2,
	S_CommonCase_T,
	S_LeadOut_Transition_In0,
	S_LeadoutTransition_In1,
	S_PreLoadS_Values0,
	S_PreLoadS_Values1,
	S_LeadOut_ComputeS,
	S_LeadOut_ComputeS_Transition0,
	S_LeadOut_ComputeS_Transition1,
	S_LeadOut_ComputeS_Transition2,
	S_Leadout_WriteS
} state_M2_type;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

`define DEFINE_STATE 1
`endif
