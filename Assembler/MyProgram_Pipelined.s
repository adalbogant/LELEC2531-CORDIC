/************* CODE SECTION *************/
@Name Here
.text   @ the following is executable assembly

@ Ensure code section is 4-byte aligned:
.balign 4

@ main is the entry point and must be global
.global main

B main          @ begin at main
.balign 128

/************* MAIN SECTION *************/

main:
	@ Base registry for accessing adresses
	SUB R0, R15, R15 	@ R0 = 0

	@ To have visual confirmation that the code is running, clear (to be sure) then turn on a LED
	STR R0, [R0, #0x500] @ Clear
	ADD R1, R0, #0x01
	STR R1, [R0, #0x500] @ LED 0 = 1

	@ Get data from Raspberry via SPI
	LDR R1, [R0, #0x400] @ Config (byte 3 : coord_syst, byte 2 : mode)
	LDR R2, [R0, #0x404] @ x_in
	LDR R3, [R0, #0x408] @ y_in
	LDR R4, [R0, #0x40C] @ z_in

	@ Write to CORDIC
	STR R2, [R0, #0x604] @ x_in
	STR R3, [R0, #0x608] @ y_in
	STR R4, [R0, #0x60C] @ z_in

	@ Start CORDIC (force start bit to 1 then write to CORDIC)
	ORR R1, R1, #0x01
	STR R1, [R0, #0x600]

wait_cordic:
	LDR R5, [R0, #0x600] @ Get "config/status" bytes
	ANDS R5, R5, #0x01 @ Check bit 0 (done) to see whether it is 1 or not
	BEQ wait_cordic @ If done = 0, keep waiting

	@ Make all LEDs light up when done (visual confirmation)
	ADD R6, R0, #0xFF
	STR R6, [R0, #0x500]
	
	@ TODO: We could add a delay here so that the LEDs being turned on can be seen 
	@ (otherwise too short)

	@ Get results from CORDIC
	LDR R7, [R0, #0x610] @ x_out
	LDR R8, [R0, #0x614] @ y_out
	LDR R9, [R0, #0x618] @ z_out
	
	@ Write CORDIC results to SPI
	STR R7, [R0, #0x410] @ x_out
	STR R8, [R0, #0x414] @ y_out
	STR R9, [R0, #0x418] @ z_out

	@ Next
	B main

.end