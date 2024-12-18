;====================================
;	8051 TIC TAC TOE GAME
;	AUTHOR: ASHWIN VALLABAN
;	https://ashvnv.github.io/ashvnv/
;====================================

;====================================================================================
;	MIT License
;
;	Copyright (c) 2024 Ashwin Vallaban (ashvnv)
;
;	Permission is hereby granted, free of charge, to any person obtaining a copy
;	of this software and associated documentation files (the "Software"), to deal
;	in the Software without restriction, including without limitation the rights
;	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;	copies of the Software, and to permit persons to whom the Software is
;	furnished to do so, subject to the following conditions:
;
;	The above copyright notice and this permission notice shall be included in all
;	copies or substantial portions of the Software.
;
;	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;	SOFTWARE.
;====================================================================================


;	IN THIS PROJECT, CLASSIC TIC TAC TOE GAME IS SIMULATED.
;	3x3 DOT MATRIX DISPLAY IS USED TO SHOW THE X & AND 0
;	THERE ARE TWO MODES IN WHICH THE GAME CAN BE PLAYED. ONE IS MANUALLY WHEREIN TWO PLAYERS HAVE TO USE THE KAYBOARD.
;		SECOND MODE IS WITH THE ALGORITHM WHEREIN ONLY A SINGLE PLAYER IS PLAYING THE GAME AND THE COMPUTER ACTS AS A SECOND PLAYER.

;	ALGORITHM:
;		PLAYER VS PLAYER:
;			WHEN THE GAME STARTS, THE 7 SEGMENT DISPLAY SHOWS '1' INDICATING THAT PLAYER 1 HAS TO PLAY THE GAME;
;			THE PLAYER 1 IS ASSIGNED A 'X' ALWAYS.
;			PLAYER 1 CAN USE THE KEYBOARD TO PLACE THE X ANYWHERE ON THE 3x3 MATRIX.
;			AFTER THE X IS PLACED, THE 7 SEGMENT WILL SHOW '2', INDICATING THAT PLAYER 2 HAS TO TAKE THE TURN.
;			PLAYER 2 IS ASSIGNED A '0' AND CAN PLACE IT ANYWHERE ON THE MATRIX LEAVING THE BLOCKS OCCUPIED BY 'X'.
;			
;			AFTER EACH STEP, THE THE ALGORITHM CHECKS IF A PLAYER HAS WON OR NOT.
;			IF A PLAYER IS ABLE TO PERFORM A 3 PATTERN MATCH IN A STRAIGHT LINE, THAT PLAYER WINS THE GAME.

;		HOW ALGORITHM CHECKS IF THE PLAYER WON:
;			THE GAME MATRIX OCCUPIES THE RAM LOCATION 0x40 TO 0x48.

;---------- DISPLAY CONFIG --------------
;			|   40H	 |	41H	 |	42H	 |
;			|   43H	 |	44H	 |	45H	 |
;			|   46H	 |	47H	 |	48H	 |

;			THE CHECKING IS DONE AS FOLLOWS:

;				;	-------- HORIZONTAL ----------
;				1. CHECK THE 1ST ROW (40H TO 42H)
;				2. CHECK THE 2ND ROW (43H TO 45H)
;				3. CHECK THE 3RD ROW (46H TO 48H)
;			
;				;	-------- VERTICAL ------------
;				4. CHECK THE 1ST COLUMN (40H, 43H, 46H)
;				5. CHECK THE 1ST COLUMN (41H, 44H, 47H)
;				6. CHECK THE 1ST COLUMN (42H, 45H, 48H)

;				;	-------- DIAGONAL ------------
;				7. CHECK THE BACK-DIAGONAL (40H, 44H, 48H)
;				8. CHECK THE FORWARD-DIAGONAL (42H, 44H, 46H)

;			THESE 8 STEPS ARE FOLLOWED AFTER EACH STEP TO CHECK IF A PLAYER HAS WON OR NOT

;	DOT MATRIX PATTERN
;		0: SHOW BLANK
;		1: SHOW 0
;		4: SHOW 1


;---------- DISPLAY CONFIG --------------
;			|   40H	 |	41H	 |	42H	 |
;			|   43H	 |	44H	 |	45H	 |
;			|   46H	 |	47H	 |	48H	 |
 
;DISPLAY UNIT 1: 0x40 0x41 0x42 0x43 0x44 0x45 0x46 0x47 0x48
	

;=== PORT PINS DEFINED ==
;FOR 4094
DAT EQU P1.0
CLK EQU P1.1
CLK1 EQU P1.2
OE_SHFT EQU P1.3
CLK2 EQU P2.2; 7 SEGMENT DISPLAY 
	
;PCF8574A
BTN0 EQU P2.3
BTN1 EQU P2.4


;I2C BUS
SCL EQU P2.5
SDA EQU P2.6
	
PLAY_MODE EQU P2.7
	
	
	
	
; === UTILIZED RAM LOCATIONS ===


;!!!!!!!!!!!!!!!!!! USED IN TIMER 1 ISR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;0x40 TO 0x48 FOR DISPLAY UNIT

;0x54 IS THE 8 BIT COUNTER
;0x39 HAS THE ADDRESS OFFSET OF THE PARTICULAR CHARACTER [UNIT 1 DISP]

;0x3C STORING R1 POINTER VALUE FOR PRESERVING ISR
;0x3D STORING R0 POINTER VALUE FOR PRESERVING ISR

;0x3E FOR BACKING UP R1 AFTER ISR IS INITIATED
;0x3F FOR BACKING UP R0 AFTER ISR IS INITIATED

;0x55 FOR BACKING UP A
;0x3B IS USED TO BACKUP B REGISTER

;0x20.0 IS USED IN DISPLAY SUBROUTINE. IF CLR THEN STAGE 1 EXECUTED AFTER INTERRUPT IS SERVICES ELSE STAGE 2
;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

;R7 IS USED AS A COUNTER IN GAME SUBROUTINES

;R4 USED AS A COUNTER IN I2C SUBROUTINE

;0x21 AND 0x4D ARE USED BY THE I2C KEYBOARD SUBROUTINE
;0x20.2 STATES IF THE READ BUTTON STATE IS VALID OR NOT


;0x20.1 IF CLR THEN PLAYER 1 IS PLAYING THE TURN, ELSE PLAYER 2

;0x20.3 STATES THE GAME MODE I.E. PLAYER VS PLAYER, PLAYER VS COMPUTER. IF SET THEN PLAYER VS PLAYER

;R2 IS USED TO STATE 0x01 (X) OR 0x02 (O) VALUE FOR UPDATING THE DISPLAY MATRIX AFTER BUTTON CLICK

;0x30 0x31 0x32 AND 0x20.4 ARE USED BY COMPUTER ALGORITHM ROUTINE

;R3 IS USED TO PRODUCE DELAY WHEN THE COMPUTER ALGORITHM PLAYS THE GAME

	

ORG 0H
	LJMP START


ORG 001BH
	;TIMER 1 OVERFLOW OCCURS HERE
	;THIS ROUTINE IS USED FOR UPDATING THE DISPLAY

	;0x54 IS THE 8 BIT COUNTER
	;0x39 HAS THE ADDRESS OFFSET OF THE PARTICULAR CHARACTER [UNIT 1 DISP]
	
	
	CLR TR1
	MOV 0x55, A; BACKUP A
	MOV 0x3B, B; BACKUP B
	
	MOV 0x3E, 0x01; BACKUP R1 POINTER
	MOV 0x3F, 0x00; BACKUP R0 POINTER
	
	
	MOV 0x01, 0x3C; RESTORE R1 POINTER
	MOV 0x00, 0x3D; RESTORE R0 POINTER
	
	;-------------- LOGIC STARTS HERE -------------
	JB 0x20.0, STAGE_2_DISPLAY
	
	
	;---------- STAGE 1 -------------
	REPEAT_MAIN:
	;TOGGLE THE ROW 4094
	CLR CLK1
	CLR DAT
	SETB CLK1
	
	REPEAT_SUBMAIN:
	MOV R1, #0x40
	
	REPEAT_CYCLE:	
	MOV A, @R1
	MOV B, #8
	MUL AB
	ADD A, 0x39; 0x39 HAS THE COLUMN ADDRESS OFFSET
	LCALL GET_DOT_PATTERN
	CPL A
	;MOVE THE VALUE IN ACC SERIALLY
	MOV 0x54, #8
	
	KEEP_SHIFTING_DAT:
	CLR C
	RLC A
	CLR CLK
	MOV DAT, C
	SETB CLK
	DJNZ 0x54, KEEP_SHIFTING_DAT
	
	INC R1
	CJNE R1, #0x49, REPEAT_CYCLE
	;SEND COMPLETE

	SETB OE_SHFT


	;---------- STAGE 1 END ----------
	
	SETB 0x20.0
	LJMP RETURN_FROM_DISPLAY_SUBR
	
	
	STAGE_2_DISPLAY:
	;----------- STAGE 2 -------------
	CLR OE_SHFT
	MOV A, 0x39
	ADD A, #0x01
	MOV 0x39, A
	ANL 0x39, #0x07
	ANL A, #0x08
	CJNE A, #0x08, REPEAT_MAIN
	
	;SEND 1, ENABLE A ROW
	CLR CLK1
	SETB DAT
	SETB CLK1
	LJMP REPEAT_SUBMAIN
	;---------- STAGE 2 ENDS -------
	
	
	
	;----------------------------------------------
	
	RETURN_FROM_DISPLAY_SUBR:
	MOV 0x3C, 0x01; BACKUP R1 POINTER
	MOV 0x3D, 0x00; BACKUP R0 POINTER
	
	MOV A, 0x55; RESTORE A
	MOV B, 0x3B; RESTORE B
	MOV 0x01, 0x3E; RESTORE R1 POINTER
	MOV 0x00, 0x3F; RESTORE R0 POINTER
	
	MOV TL1, #0x00
	SETB TR1
	RETI




;REFERENCE: https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h
;PATTERN SHOWN FROM LAST ROW TO FIRST ROW
;DATA SHOULD BE CPL BEFORE MOVING TO PORT
ORG 100H
	;DEFINE DOT MATRIX CHARACTER PATTERNS
	
;TO ACCESS THIS DATA, USE MOVC A, @A + PC
	GET_DOT_PATTERN:
	INC A; GET AROUND RET
	MOVC A, @A + PC
	RET
	
ORG 103H
	;----- FOR 0 (SHOW BLANK) -------
	DB 0x00
	DB 0x00
	DB 0x00
	DB 0x00
	DB 0x00
	DB 0x00
	DB 0x00
	DB 0x00
	
	;----- FOR 1 (SHOW 0) ------
	DB 0x00
	DB 0x1C
	DB 0x36
	DB 0x63 			
	DB 0x63	 
	DB 0x63 
	DB 0x36
	DB 0x1C 
		
ORG 123H
	;----- FOR 4 (SHOW X) ------
	DB 0x00
	DB 0x63 
	DB 0x36 
	DB 0x1C	
	DB 0x1C 
	DB 0x36
	DB 0x63  
	DB 0x63 
	



	
	
;============= MAIN PROGRAM STARTS HERE =========
ORG 250H
	START:
	
	;MANUALLY CONFIGURE THE DISPLAY
;	MOV 0x40, #0x01
;	MOV 0x41, #0x01
;	MOV 0x42, #0x01
	
;	--------- DEFINE TIMER0 FOR DISPLAY UPDATE --------
	MOV TMOD, #0x21; TIMER 1 8 BIT AUTORELOAD, TIMER 0 IN 16 BIT MODE
	MOV TH1, #0x00
	MOV TL1, #0x00
	
	CLR 0x20.0
	SETB EA
	SETB ET1; TIMER 0 OVERFLOW INTERRUPT
	SETB TR1
	
	
	
	
	;PROGRAM FLOW:
	;		THE PROGRAM WILL STAY IN THE INFINITE IDLE LOOP UNTIL A BUTTON IS CLICKED BY PLAYER 1
	;		THE 'X' IS THEN MARKED ON THE DISPLAY
	;		AFTER THAT THE PROGRAM CHECKS IF THE NEXT PLAYER IS A COMPUTER OR NOT. IF YES, THEN THE ALGORITHM PLAYS THE NEXT STEP, ELSE
	;			IT WAITS FOR THE PLAYER 2 TO CLICK THE VALID BUTTON.
	;		AFTER EACH STEP BY EITHER PLAYER, 8 CHECKS ARE DONE TO SEE IF THE PLAYER WON
	;		WHEN A PLAYER WINS THE GAME, ONLY THE CONSECUTIVE PATTERNS WHICH MATCHED ARE SHOWN ON THE SCREEN AND THE REST OF THE 
	;			BLOCKS ARE MADE IDLE.
	;		THE DISPLAY WILL BLANK WHEN THE PLAYER CLICKS ON START/RESTART BUTTON.
	;		AT ANY MOMENT, THEN THE PLAYER CLICKS ON START/RESTART BUTTON, THE GAME WILL RESET
	
	RESET_JUMP:
	LCALL RESET_GAME; RESET THE GAME
	
	PLAYER_2_STEP_COMPLETE:
	LCALL SHOW_CHANCE_PLAYER_1; PLAYER 1 CHANCE TO PLAY THE GAME
	
	;==================================================
	;HERE CHECK FOR BUTTON STATE TO CHANGE
	WAIT_FOR_PLAYER_1:
	JNB BTN0, BTN_0_STATE_CHANGE
	JNB BTN1, BTN_1_STATE_CHANGE
	
	PLAYER_1_STEP_INVALID:
	SJMP WAIT_FOR_PLAYER_1
	;==================================================
	
	PLAYER_1_STEP_COMPLETE:
	
	LCALL SHOW_CHANCE_PLAYER_2; PLAYER 2 CHANCE TO PLAY THE GAME
	
	JNB PLAY_MODE, COMPUTER_PLAYS; IF CLEAR THEN COMPUTER PLAYS THE NEXT STEP
	
	;==================================================
	;HERE CHECK FOR BUTTON STATE TO CHANGE
	WAIT_FOR_PLAYER_2:
	JNB BTN0, BTN_0_STATE_CHANGE
	JNB BTN1, BTN_1_STATE_CHANGE
	
	PLAYER_2_STEP_INVALID:
	SJMP WAIT_FOR_PLAYER_2
	;==================================================
	
	COMPUTER_PLAYS:
	;CREATE A SMALL DELAY HERE USING TIMER 0
	MOV TH0, #0x00
	MOV TL0, #0x00
	
	MOV R3, #0x05; COUNTER FOR DELAY
	CLR TF0
	SETB TR0
	WAIT_COMP_PLAY:
	JNB TF0, WAIT_COMP_PLAY
	CLR TF0
	DJNZ R3, WAIT_COMP_PLAY
	CLR TR0
	
	LCALL EXEC_COMPUTER_ALGO; CALL THE COMPUTER ALGORITHM TO PLAY THE GAME
	LCALL GAME_WIN_CHECK_VALIDITY
	LJMP VALID_BTN_STATE_GOBACK
	
	;------------------------------------------------------------------------------------------
	
	
	INVALID_BTN_STATE_GOBACK:
		JNB 0x20.1, PLAYER_1_STEP_INVALID; PLAYER 1 INVALID BUTTON STATE
		SJMP PLAYER_2_STEP_INVALID; PLAYER 2 INVALID BUTTON STATE

	VALID_BTN_STATE_GOBACK:
		JNB 0x20.1, PLAYER_1_STEP_COMPLETE; PLAYER 1 ACTION COMPLETED
		SJMP PLAYER_2_STEP_COMPLETE; PLAYER 2 ACTION COMPLETED

	
	BTN_0_STATE_CHANGE:
		CLR 0x20.2; CLEAR VALID BUTTON STATE FLAG
		LCALL READ_BTN0; READ THE STATE OF BTN0 PCF8574A
		JNB 0x20.2, INVALID_BTN_STATE_GOBACK
		
		;VALID BUTTON STATE FOUND. PERFORM THE ACTION
		;0x4D HAS THE BUTTON VALUE
		
		LJMP PERFORM_BTN_ACTION
	
	
	BTN_1_STATE_CHANGE:
		CLR 0x20.2; CLEAR VALID BUTTON STATE FLAG
		LCALL READ_BTN1; READ THE STATE OF BTN0 PCF8574A
		JNB 0x20.2, INVALID_BTN_STATE_GOBACK
		
		;VALID BUTTON STATE FOUND. PERFORM THE ACTION
		;0x4D HAS THE BUTTON VALUE
		
		LJMP PERFORM_BTN_ACTION



PERFORM_BTN_ACTION:
	;CALL THIS FUNCTION TO PERFORM THE ACTION ON THE DISPLAY AFTER THE BUTTON CLICK
	;0x4D SHOULD HAVE THE BUTTON WHICH WAS CLICKED
	;R2 SHOULD HAVE THE VALUE WHICH SHOULD BE UPDATED ON THE DISPLAY
	;THIS ROUTINE DOES NOT CHECK WHICH PLAYER IS PLAYING THE GAME
	
	JB 0x20.1, PLAYER_2_O
	;PLAYER 1 X
	MOV R2, #0x04; STORE THE VALUE X
	SJMP PERFORM_ACTION
	
			
	PLAYER_2_O:
	MOV R2, #0x01; STORE THE VALUE O

	PERFORM_ACTION:
		;CHECK WHICH BUTTON WAS CLICKED AND THEN EXECUTE THE FUNCTION
		MOV A, 0x4D; GET THE BUTTON VALUE
		
		CJNE A, #0x00, CHK_NXT_PERFORM_ACTION0
		;11 CLICKED
		MOV A, 0x40
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x40, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION0:
		CJNE A, #0x01, CHK_NXT_PERFORM_ACTION1
		;12 CLICKED
		MOV A, 0x41
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x41, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION1:
		CJNE A, #0x02, CHK_NXT_PERFORM_ACTION2
		;13 CLICKED
		MOV A, 0x42
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x42, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION2:
		CJNE A, #0x03, CHK_NXT_PERFORM_ACTION3
		;21 CLICKED
		MOV A, 0x43
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x43, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION3:
		CJNE A, #0x04, CHK_NXT_PERFORM_ACTION4
		;22 CLICKED
		MOV A, 0x44
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x44, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION4:
		CJNE A, #0x05, CHK_NXT_PERFORM_ACTION5
		;23 CLICKED
		MOV A, 0x45
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x45, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION5:
		CJNE A, #0x06, CHK_NXT_PERFORM_ACTION6
		;31 CLICKED
		MOV A, 0x46
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x46, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION6:
		CJNE A, #0x07, CHK_NXT_PERFORM_ACTION7
		;32 CLICKED
		MOV A, 0x47
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x47, R2
		LJMP ACTION_PERFORMED
		
		CHK_NXT_PERFORM_ACTION7:
		CJNE A, #0x08, CHK_NXT_PERFORM_ACTION8
		;33 CLICKED
		MOV A, 0x48
		CJNE A, #0x00, ACTION_INVALID
		;VALID
		MOV 0x48, R2
		LJMP ACTION_PERFORMED
		
		ACTION_INVALID:
		LJMP INVALID_BTN_STATE_GOBACK
		
		CHK_NXT_PERFORM_ACTION8:
		;RESET/RESTART CLICKED
		LJMP RESET_JUMP; 
		
		
	ACTION_PERFORMED:
	;NOW PERORM THE VALIDATON CHECK HERE
	LCALL GAME_WIN_CHECK_VALIDITY
	
	LJMP VALID_BTN_STATE_GOBACK
	

;--------------------------------------------	
GAME_WIN_CHECK_VALIDITY:
;				;	-------- HORIZONTAL ----------
;				1. CHECK THE 1ST ROW (40H TO 42H)
;				2. CHECK THE 2ND ROW (43H TO 45H)
;				3. CHECK THE 3RD ROW (46H TO 48H)
;			
;				;	-------- VERTICAL ------------
;				4. CHECK THE 1ST COLUMN (40H, 43H, 46H)
;				5. CHECK THE 1ST COLUMN (41H, 44H, 47H)
;				6. CHECK THE 1ST COLUMN (42H, 45H, 48H)

;				;	-------- DIAGONAL ------------
;				7. CHECK THE BACK-DIAGONAL (40H, 44H, 48H)
;				8. CHECK THE FORWARD-DIAGONAL (42H, 44H, 46H)

	;CHECK IF THE GAME IS WON BY THE PLAYER
	;R2 SHOULD HAVE THE DISPLAY VALUE WHICH IS TO BE CHECKED
	
	;---------------------------------
	;1. CHECK THE 1ST ROW (40H TO 42H)
	MOV A, 0x40
	ADD A, 0x41
	ADD A, 0x42
	CJNE A, #0x03, CHK_1STROW_X
	;MATCH FOUND FOR PATTERN O
	LCALL CLEAR_EXCEPT_1R
	LJMP VALIDATION_PATTER
	
	
	
	CHK_1STROW_X:
	CJNE A, #0x0C, CHK_2NDROW
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_1R
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_2NDROW:
	MOV A, 0x43
	ADD A, 0x44
	ADD A, 0x45
	CJNE A, #0x03, CHK_2NDROW_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_2R
	LJMP VALIDATION_PATTER
	
	
	CHK_2NDROW_X:
	CJNE A, #0x0C, CHK_3RDROW
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_2R
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_3RDROW:
	MOV A, 0x46
	ADD A, 0x47
	ADD A, 0x48
	CJNE A, #0x03, CHK_3RDROW_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_3R
	LJMP VALIDATION_PATTER
	
	
	CHK_3RDROW_X:
	CJNE A, #0x0C, CHK_1STCOL
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_3R
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_1STCOL:
	MOV A, 0x40
	ADD A, 0x43
	ADD A, 0x46
	CJNE A, #0x03, CHK_1STCOL_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_1C
	LJMP VALIDATION_PATTER
	
	
	CHK_1STCOL_X:
	CJNE A, #0x0C, CHK_2NDCOL
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_1C
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_2NDCOL:
	MOV A, 0x41
	ADD A, 0x44
	ADD A, 0x47
	CJNE A, #0x03, CHK_2NDCOL_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_2C
	LJMP VALIDATION_PATTER
	
	
	CHK_2NDCOL_X:
	CJNE A, #0x0C, CHK_3RDCOL
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_2C
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_3RDCOL:
	MOV A, 0x42
	ADD A, 0x45
	ADD A, 0x48
	CJNE A, #0x03, CHK_3RDCOL_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_3C
	LJMP VALIDATION_PATTER
	
	
	CHK_3RDCOL_X:
	CJNE A, #0x0C, CHK_BACKDIAG
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_3C
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_BACKDIAG:
	MOV A, 0x40
	ADD A, 0x44
	ADD A, 0x48
	CJNE A, #0x03, CHK_BACKDIAG_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_BD
	LJMP VALIDATION_PATTER
	
	
	CHK_BACKDIAG_X:
	CJNE A, #0x0C, CHK_FORWARDDIAG
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_BD
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	;---------------------------------
	CHK_FORWARDDIAG:
	MOV A, 0x42
	ADD A, 0x44
	ADD A, 0x46
	CJNE A, #0x03, CHK_FORWARDDIAG_X
	;MATCH FOUND FOR PATTERN 0
	LCALL CLEAR_EXCEPT_FD
	LJMP VALIDATION_PATTER
	
	
	CHK_FORWARDDIAG_X:
	CJNE A, #0x0C, NO_VALIDATION_PATTERN
	;MATCH FOUND FOR PATTERN X
	LCALL CLEAR_EXCEPT_FD
	LJMP VALIDATION_PATTER
	;---------------------------------
	
	
	NO_VALIDATION_PATTERN:
	;NO PATTERN FOUND. PLAYER DID NOT WIN. RETURN TO NORMAL ROUTINE

	RET
	
	
	VALIDATION_PATTER:
	;PLAYER WON. WAIT FOR RESTART/RESET BUTTON CLICK
	
	WAIT_FOR_RESET_AFTER_VALIDATION:
	JNB BTN1, BTN_1_STATE_CHANGE_VALIDATION
	SJMP WAIT_FOR_RESET_AFTER_VALIDATION
	
	
	BTN_1_STATE_CHANGE_VALIDATION:
	;CHECK IF RESET BUTTON WAS CLICKED
		CLR 0x20.2; CLEAR VALID BUTTON FLAG
		LCALL READ_BTN1
		JNB 0x20.2, WAIT_FOR_RESET_AFTER_VALIDATION
		
		;VALID BUTTON CLICK
		MOV A, 0x4D; GET THE BUTTON VALUE
		
		CJNE A, #0x09, WAIT_FOR_RESET_AFTER_VALIDATION
		;RESET BUTTON CLICKED
		LJMP RESET_JUMP
		
	


;-------------- COMPUTER ALGORITHM -------------------
;HERE THE COMPUTER ALGORITHM SUBROUTINES ARE PRESENT
;	ALGORITHM FLOW:
;	A SIMPLE INEFFICIENT ALGORITHM IS USED HERE.
;	MORE MORE EFFICIENT ALGORITHM, MINMAX GAME THEORY CAN BE USED.
;	I HAVE NOT IMPLEMENTED THAT AS IT USES RECURSION, AND IN ASSEMBLY, RECURSION IS DIFFICULT TO EXECUTE
;	REF: https://www.neverstopbuilding.com/blog/minimax

	EXEC_COMPUTER_ALGO:
	;FIRST CHECK IF 2 '0' PATTERN IN A STRAIGHT LINE CAN BE FOUND. IF YES, ADD 'O' TO THE THIRD BLOCK
	;ELSE IF CHECK IF THE MIDDLE BLOCK IS OCCUPIED. IF NO, THEN OCCUPY IT.
	;ELSE IF CHECK IF 2 CONSECUTIVE 'X' CAN BE FOUND IN A STRAIGHT LINE, IF YES THEN ADD THIRD 'O'
	;ELSE IF ADD 'O' TO THE CORNER BLOCK WHICH IS NOT OCCUPIED
	;ELSE IF ADD 'O' TO ANY AVAILABLE BLOCK
	
	
	;==================== ;FIRST CHECK IF 2 '0' PATTERN IN A STRAIGHT LINE CAN BE FOUND. IF YES, ADD 'O' TO THE THIRD BLOCK ============	
	MOV 0x30, #0x02; CHECK FOR 2 'O' PATTERNS
	MOV 0x32, #0x01; VALUE TO BE ADDED WHEN THE PATTERN IS FOUND
	LCALL COMP_ALGO_CHECK_CONSECUTIVES
	JB 0x20.4, COMPLETED_EXEC_COMPUTER_ALGO
	;PATTERN NOT FOUND. MOVE TO NEXT STAGE
	
	
	;==================== ;CHECK IF THE MIDDLE BLOCK IS OCCUPIED. IF NO, THEN OCCUPY IT. ============
	MOV A, 0x44
	JNZ STAGENXT0_JUMP; IF OCCUPIED THEN MOVE TO NEXT STAGE
	;MIDDLE NOT OCCUPIED. OCCUPY IT
	MOV 0x44, #0x01; ADD 0 PATTERN
	SJMP COMPLETED_EXEC_COMPUTER_ALGO
	

	STAGENXT0_JUMP:
	;==================== ;CHECK IF 2 CONSECUTIVE 'X' CAN BE FOUND IN A STRAIGHT LINE, IF YES THEN ADD THIRD 'O' ============
	MOV 0x30, #0x08; CHECK FOR 2 'X' PATTERNS
	MOV 0x32, #0x01; VALUE TO BE ADDED WHEN THE PATTERN IS FOUND
	LCALL COMP_ALGO_CHECK_CONSECUTIVES
	JB 0x20.4, COMPLETED_EXEC_COMPUTER_ALGO
	;PATTERN NOT FOUND. MOVE TO NEXT STAGE
	

	;======== ADD 'O' TO THE CORNER BLOCK WHICH IS NOT OCCUPIED ========
	MOV A, 0x40
	CJNE A, #0x00, CHK_NXT_ADD_O_PATT0
	MOV 0x40, #0x01
	SJMP COMPLETED_EXEC_COMPUTER_ALGO
	
	CHK_NXT_ADD_O_PATT0:
	MOV A, 0x42
	CJNE A, #0x00, CHK_NXT_ADD_0_PATT1
	MOV 0x42, #0x01
	SJMP COMPLETED_EXEC_COMPUTER_ALGO

	CHK_NXT_ADD_0_PATT1:
	MOV A, 0x46
	CJNE A, #0x00, CHK_NXT_ADD_0_PATT2
	MOV 0x46, #0x01
	SJMP COMPLETED_EXEC_COMPUTER_ALGO
	
	CHK_NXT_ADD_0_PATT2:
	MOV A, 0x48
	CJNE A, #0x00, STAGENXT1_JUMP
	MOV 0x48, #0x01
	SJMP COMPLETED_EXEC_COMPUTER_ALGO
	
	
	
	STAGENXT1_JUMP:
	; ========= ;ADD 'O' TO ANY AVAILABLE BLOCK ==========
	MOV R0, #0x3F; START ADD OF MATRIX
	
	REPEAT_TILL_PATT_FOUND:
	INC R0
	MOV A, @R0
	CJNE A, #0x00, REPEAT_TILL_PATT_FOUND
	MOV @R0, #0x01; ADD 0 PATTERN
	

	COMPLETED_EXEC_COMPUTER_ALGO:
	RET
	
	
	
COMP_ALGO_CHECK_CONSECUTIVES:
;CALL THIS ROUTINE TO CHECK ALL THE POSSIBILITY IF A PATTERN CAN BE FOUND CONSECUTIVELY.
	;0x30 HAS THE VALUE TO BE CHECKED FOR CONSECUTIVE POSSIBLITY
	;EG TO CHECK IF THERE ARE TWO CONSECUTIVE 'X' PATTER, 0x30 SHOULD BE 0x08.
	;0x31 HAS THE POSSIBLITY VALUE WHERE THIS PATTERN WAS FOUND.
	;0x31 POSSIBLE VALUES:
	;	0: NOT FOUND THE CONSECUTIVE PATTERNS
;		1. CHECK THE 1ST ROW (40H TO 42H) FOUND HERE
;		2. CHECK THE 2ND ROW (43H TO 45H) FOUND HERE
;		3. CHECK THE 3RD ROW (46H TO 48H) FOUND HERE
;		4. CHECK THE 1ST COLUMN (40H, 43H, 46H) FOUND HERE
;		5. CHECK THE 1ST COLUMN (41H, 44H, 47H) FOUND HERE
;		6. CHECK THE 1ST COLUMN (42H, 45H, 48H) FOUND HERE
;		7. CHECK THE BACK-DIAGONAL (40H, 44H, 48H) FOUND HERE
;		8. CHECK THE FORWARD-DIAGONAL (42H, 44H, 46H) FOUND HERE
;	0x32 SHOULD CONTAIN THE VALUE WHICH WILL BE ADDED TO THE CONSECUTIVE BLOCK IF FOUND
;	0x20.4 WILL BE SET IF THE ROUTINE FOUND PATTERN AND THEN EXECUTED THE TASK

;========= ALGORITHM ==============
	;---------------------------------
	;1. CHECK THE 1ST ROW (40H TO 42H)
	MOV A, 0x40
	ADD A, 0x41
	ADD A, 0x42
	CJNE A, 0x30, CHK_2NDROW_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x01
	
	MOV A, 0x40
	CJNE A, #0x00, CHK_NXT0_1R_S0
	MOV 0x40, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_1R_S0:
	MOV A, 0x41
	CJNE A, #0x00, CHK_NXT1_1R_S0
	MOV 0x41, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_1R_S0:
	MOV 0x42, #0x01; ADD 0
	
	LJMP ALGO_STAGE_COMPLETE
	;---------------------------------
	
	
	;---------------------------------
	CHK_2NDROW_S0:
	MOV A, 0x43
	ADD A, 0x44
	ADD A, 0x45
	CJNE A, 0x30, CHK_3RDROW_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x02
	
	MOV A, 0x43
	CJNE A, #0x00, CHK_NXT0_2R_S0
	MOV 0x43, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_2R_S0:
	MOV A, 0x44
	CJNE A, #0x00, CHK_NXT1_2R_S0
	MOV 0x44, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_2R_S0:
	MOV 0x45, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	
	;---------------------------------
	CHK_3RDROW_S0:
	MOV A, 0x46
	ADD A, 0x47
	ADD A, 0x48
	CJNE A, 0x30, CHK_1STCOL_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x03
	
	MOV A, 0x46
	CJNE A, #0x00, CHK_NXT0_3R_S0
	MOV 0x46, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_3R_S0:
	MOV A, 0x47
	CJNE A, #0x00, CHK_NXT1_3R_S0
	MOV 0x47, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_3R_S0:
	MOV 0x48, #0x01; ADD 0

	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	
	;---------------------------------
	CHK_1STCOL_S0:
	MOV A, 0x40
	ADD A, 0x43
	ADD A, 0x46
	CJNE A, 0x30, CHK_2NDCOL_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x04
	
	MOV A, 0x40
	CJNE A, #0x00, CHK_NXT0_1C_S0
	MOV 0x40, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_1C_S0:
	MOV A, 0x43
	CJNE A, #0x00, CHK_NXT1_1C_S0
	MOV 0x43, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_1C_S0:
	MOV 0x46, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	;---------------------------------
	
	
	;---------------------------------
	CHK_2NDCOL_S0:
	MOV A, 0x41
	ADD A, 0x44
	ADD A, 0x47
	CJNE A, 0x30, CHK_3RDCOL_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x05
	
	MOV A, 0x41
	CJNE A, #0x00, CHK_NXT0_2C_S0
	MOV 0x41, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_2C_S0:
	MOV A, 0x44
	CJNE A, #0x00, CHK_NXT1_2C_S0
	MOV 0x44, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_2C_S0:
	MOV 0x47, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	
	;---------------------------------
	CHK_3RDCOL_S0:
	MOV A, 0x42
	ADD A, 0x45
	ADD A, 0x48
	CJNE A, 0x30, CHK_BACKDIAG_S0
	;MATCH FOUND FOR PATTERN

	MOV 0x31, #0x06
	
	MOV A, 0x42
	CJNE A, #0x00, CHK_NXT0_3C_S0
	MOV 0x42, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_3C_S0:
	MOV A, 0x45
	CJNE A, #0x00, CHK_NXT1_3C_S0
	MOV 0x45, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_3C_S0:
	MOV 0x48, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	
	;---------------------------------
	CHK_BACKDIAG_S0:
	MOV A, 0x40
	ADD A, 0x44
	ADD A, 0x48
	CJNE A, 0x30, CHK_FORWARDDIAG_S0
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x07
	
	MOV A, 0x40
	CJNE A, #0x00, CHK_NXT0_BD_S0
	MOV 0x40, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_BD_S0:
	MOV A, 0x44
	CJNE A, #0x00, CHK_NXT1_BD_S0
	MOV 0x44, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_BD_S0:
	MOV 0x48, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	
	;---------------------------------
	CHK_FORWARDDIAG_S0:
	MOV A, 0x42
	ADD A, 0x44
	ADD A, 0x46
	CJNE A, 0x30, ALGO_STAGE_FAILED
	;MATCH FOUND FOR PATTERN
	
	MOV 0x31, #0x08

	MOV A, 0x42
	CJNE A, #0x00, CHK_NXT0_FD_S0
	MOV 0x42, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT0_FD_S0:
	MOV A, 0x44
	CJNE A, #0x00, CHK_NXT1_FD_S0
	MOV 0x44, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	CHK_NXT1_FD_S0:
	MOV 0x46, #0x01; ADD 0
	LJMP ALGO_STAGE_COMPLETE
	
	;---------------------------------
	
	ALGO_STAGE_FAILED:
	CLR 0x20.4; NO PATTERN FOUND
	RET
	
	ALGO_STAGE_COMPLETE:
	SETB 0x20.4; FLAG STATING THE PATTERN WAS FOUND AND ACTION PERFORMED
	RET
	
	
	
	
	


;-------------------------------------------
READ_BTN0:
	; P7		P6 		P5 		P4 		P3 		P2 		P1 		P0
	;   		31		23		22		21		13		12		11
	;ADDRESS 0x71
	;SEND START CONDITION
	LCALL STARTC
	;SEND SLAVE ADDRESS
	MOV A,#0x71 ;PCF8574A ADDRESS WITH READ MODE
	LCALL SEND
	LCALL RECV
	LCALL ACK
	LCALL STOP
	
	;A HAS THE VALUE
	CPL A
	MOV 0x21, A; MOVE BUTTON STATE TO BIT ADDRESSABLE RAM
	JZ GO_BACK_BTN0
	
	;-------- CHECK WHICH BUTTON WAS CLICKED -------
	JNB 0x21.0, CHK_NXT_PCF0_1
	;11 CLICKED
	MOV 0x4D, #0x00
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_1:
	JNB 0x21.1, CHK_NXT_PCF0_2
	;12 CLICKED
	MOV 0x4D, #0x01
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_2:
	JNB 0x21.2, CHK_NXT_PCF0_3
	;13 CLICKED
	MOV 0x4D, #0x02
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_3:
	JNB 0x21.3, CHK_NXT_PCF0_4
	;21 CLICKED
	MOV 0x4D, #0x03
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_4:
	JNB 0x21.4, CHK_NXT_PCF0_5
	;22 CLICKED
	MOV 0x4D, #0x04
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_5:
	JNB 0x21.5, CHK_NXT_PCF0_6
	;23 CLICKED
	MOV 0x4D, #0x05
	SJMP DONE_GETTING_PCF0
	
	CHK_NXT_PCF0_6:
	JNB 0x21.6, GO_BACK_BTN0
	;31 CLICKED
	MOV 0x4D, #0x06
	SJMP DONE_GETTING_PCF0
	
	DONE_GETTING_PCF0:
	SETB 0x20.2; VALID BUTTON STATE
	
	
	GO_BACK_BTN0:
	RET
	
; ===============================================================================
	
	READ_BTN1:
	; P7		P6 		P5 			P4 			P3 			P2 			P1 		P0
	; 		    										(RE)START		33 		32
	
	;ADDRESS 0x73
	;SEND START CONDITION
	LCALL STARTC
	;SEND SLAVE ADDRESS
	MOV A,#0x73 ;PCF8574A ADDRESS WITH READ MODE
	LCALL SEND
	LCALL RECV
	LCALL ACK
	LCALL STOP
	
	;A HAS THE VALUE
	CPL A
	MOV 0x21, A; MOVE BUTTON STATE TO BIT ADDRESSABLE RAM
	JZ GO_BACK_BTN1
	
	;-------- CHECK WHICH BUTTON WAS CLICKED -------
	JNB 0x21.0, CHK_NXT_PCF1_1
	;32 CLICKED
	MOV 0x4D, #0x07
	SJMP DONE_GETTING_PCF1
	
	CHK_NXT_PCF1_1:
	JNB 0x21.1, CHK_NXT_PCF1_2
	;33 CLICKED
	MOV 0x4D, #0x08
	SJMP DONE_GETTING_PCF1
	
	CHK_NXT_PCF1_2:
	JNB 0x21.2, GO_BACK_BTN1
	;(RE)START CLICKED
	MOV 0x4D, #0x09
	SJMP DONE_GETTING_PCF1

	DONE_GETTING_PCF1:
	SETB 0x20.2; VALID BUTTON STATE
	
	
	GO_BACK_BTN1:	
	RET
	
	
	
	
;======= GAME SUBROUTINES ========
SHOW_CHANCE_PLAYER_1:
	;SHOW '1' ON 7 SEGMENT DISPLAY
	CLR 0x20.1; PLAYER 1 FLAG
	
	CLR EA; DISABLE ISR
	MOV A, #0x60; SHOW 1
	
	MOV R7, #8; INIT A COUNTER
	
	REPEAT_SEND_PLAYER1_DISP:
	CLR CLK2
	RRC A
	MOV DAT, C
	SETB CLK2
	DJNZ R7, REPEAT_SEND_PLAYER1_DISP
	
	SETB EA; ENABLE ISR
	RET
	
	
SHOW_CHANCE_PLAYER_2:
	;SHOW '2' ON 7 SEGMENT DISPLAY
	SETB 0x20.1; PLAYER 2 FLAG
	

	CLR EA; DISABLE ISR
	MOV A, #0xDA; SHOW 2
	
	MOV R7, #8; INIT A COUNTER
	
	REPEAT_SEND_PLAYER2_DISP:
	CLR CLK2
	RRC A
	MOV DAT, C
	SETB CLK2
	DJNZ R7, REPEAT_SEND_PLAYER2_DISP
	
	SETB EA; ENABLE ISR
	RET
	
	
RESET_GAME:
	;CALL THIS SUBROUTINE TO RESET THE GAME
	CLR EA; DISABLE INTERRUPTS
	MOV R0, #0x48; INIT THE POINTER TO DISPLAY REGISTERS
	
	RESET_CLEAR_DISP:
	MOV @R0, #0x00
	DEC R0
	
	CJNE R0, #0x3F, RESET_CLEAR_DISP
	;DONE CLEARING THE REGISTERS
	
	SETB EA
	RET
	
	
CLEAR_EXCEPT_1R:
;---------- DISPLAY CONFIG --------------
;			|   40H	 |	41H	 |	42H	 |
;			|   -	 |	-	 |	-	 |
;			|   -	 |	-	 |	- 	 |
	MOV 0x43, #0x00
	MOV 0x44, #0x00
	MOV 0x45, #0x00
	MOV 0x46, #0x00
	MOV 0x47, #0x00
	MOV 0x48, #0x00
	
	RET
	
	
CLEAR_EXCEPT_2R:
;---------- DISPLAY CONFIG --------------
;			|   -	 |	-	 |	-	 |
;			|   41H	 |	42H	 |	43H	 |
;			|   -	 |	-	 |	- 	 |
	MOV 0x40, #0x00
	MOV 0x41, #0x00
	MOV 0x42, #0x00
	MOV 0x46, #0x00
	MOV 0x47, #0x00
	MOV 0x48, #0x00
	
	RET
	
CLEAR_EXCEPT_3R:
;---------- DISPLAY CONFIG --------------
;			|   -	 |	-	 |	-	 |
;			|   -	 |	-	 |	-	 |
;			|   46H	 |	47H	 |	48H  |
	MOV 0x40, #0x00
	MOV 0x41, #0x00
	MOV 0x42, #0x00
	MOV 0x43, #0x00
	MOV 0x44, #0x00
	MOV 0x45, #0x00
	
	RET
	
	
CLEAR_EXCEPT_1C:
;---------- DISPLAY CONFIG --------------
;			|   40H	 |	-	 |	-	 |
;			|   43H	 |	-	 |	-	 |
;			|   46H	 |	-	 |	-    |
	MOV 0x41, #0x00
	MOV 0x42, #0x00
	MOV 0x44, #0x00
	MOV 0x45, #0x00
	MOV 0x47, #0x00
	MOV 0x48, #0x00
	
	RET
	
CLEAR_EXCEPT_2C:
;---------- DISPLAY CONFIG --------------
;			|   -	 |	41H	 |	-	 |
;			|   -	 |	42H	 |	-	 |
;			|   -	 |	43H	 |	-    |
	MOV 0x40, #0x00
	MOV 0x42, #0x00
	MOV 0x43, #0x00
	MOV 0x45, #0x00
	MOV 0x46, #0x00
	MOV 0x48, #0x00
	
	RET
	
	
CLEAR_EXCEPT_3C:
;---------- DISPLAY CONFIG --------------
;			|   -	 |	-	 |	42H	 |
;			|   -	 |	-	 |	45H	 |
;			|   -	 |	-	 |	48H  |
	MOV 0x40, #0x00
	MOV 0x41, #0x00
	MOV 0x43, #0x00
	MOV 0x44, #0x00
	MOV 0x46, #0x00
	MOV 0x47, #0x00
	
	RET
	
	
CLEAR_EXCEPT_BD:
;---------- DISPLAY CONFIG --------------
;			|   40H	 |	-	 |	-	 |
;			|   -	 |	44H	 |	-	 |
;			|   -	 |	-	 |	48H  |
	MOV 0x41, #0x00
	MOV 0x42, #0x00
	MOV 0x43, #0x00
	MOV 0x45, #0x00
	MOV 0x46, #0x00
	MOV 0x47, #0x00
	
	RET
	
	
CLEAR_EXCEPT_FD:
;---------- DISPLAY CONFIG --------------
;			|   -	 |	-	 |	42H	 |
;			|   -	 |	44H	 |	-	 |
;			|   46H	 |	-	 |	-    |
	MOV 0x40, #0x00
	MOV 0x41, #0x00
	MOV 0x43, #0x00
	MOV 0x45, #0x00
	MOV 0x47, #0x00
	MOV 0x48, #0x00
	
	RET
	
;######################## I2C COMMANDS ###########################

;****************************************
;START CONDITION FOR I2C COMMUNICATION
;****************************************

STARTC:
	SETB SCL
	CLR SDA
	CLR SCL
	RET
 
 
;*****************************************
;STOP CONDITION FOR I2C BUS
;*****************************************

STOP:
	CLR SCL
	CLR SDA
	SETB SCL
	SETB SDA
	RET
	
;*****************************************
;SENDING DATA TO SLAVE ON I2C BUS
;*****************************************

SEND:
	MOV R4,#08
BACK:
	CLR SCL
	RLC A
	MOV SDA,C
	SETB SCL
	DJNZ R4,BACK
	CLR SCL
	SETB SDA
	SETB SCL
	MOV C, SDA
	CLR SCL
	
	RET
 
 
;*****************************************
;ACK AND NAK FOR I2C BUS
;*****************************************

ACK:
	CLR SDA
	SETB SCL
	CLR SCL
	SETB SDA
	RET

NAK:
	SETB SDA
	SETB SCL
	CLR SCL
	SETB SCL
	RET
 
 
;*****************************************
;RECEIVING DATA FROM SLAVE ON I2C BUS
;*****************************************

RECV:
	MOV R4,#08
BACK2:
	CLR SCL
	SETB SCL
	MOV C,SDA
	RLC A
	DJNZ R4,BACK2
	CLR SCL
	
	RET

	
END