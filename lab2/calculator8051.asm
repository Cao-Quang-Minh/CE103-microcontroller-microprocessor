$NOMOD51
$INCLUDE (8051.MCU)

   
ORG 000H
   
   MOV TMOD, #21h      ; Timer 1 in Mode 2 (8-bit auto-reload)
   MOV TH1, #0FDh      ; 9600 baud rate with 11.0592 MHz crystal
   ;MOV TL1, #0FDh
   SETB TR1            ; Start Timer 1
   MOV SCON, #50h      ; Mode 1, 8-bit UART, REN enabled
   ; Initialize variables and ports
   MOV R4, #00H
   MOV P3, #00H
   MOV P2, #0FEH
   MOV R3, #00H
   MOV R1, #00H
   MOV R2, #'+'

MainLoop:
   JNB P2.0, CheckColumn1
   JNB P2.1, CheckColumn2
   JNB P2.2, CheckColumn3
   JNB P2.3, CheckColumn4
   JMP MainLoop

CheckColumn1:
   JNB P2.4, ButtonON
   JNB P2.5, Button0
   JNB P2.6, ButtonEqual
   JNB P2.7, ButtonPlus
   SETB P2.0
   CLR P2.1
   SJMP MainLoop

CheckColumn2:
   JNB P2.4, Button1
   JNB P2.5, Button2
   JNB P2.6, Button3
   JNB P2.7, ButtonMinus
   SETB P2.1
   CLR P2.2
   SJMP MainLoop

CheckColumn3:
   JNB P2.4, Button4
   JNB P2.5, Button5
   JNB P2.6, Button6
   JNB P2.7, ButtonMultiply
   SETB P2.2
   CLR P2.3
   SJMP MainLoop

CheckColumn4:
   JNB P2.4, Button7
   JNB P2.5, Button8
   JNB P2.6, Button9
   JNB P2.7, ButtonDivide
   SETB P2.3
   CLR P2.0
   LJMP MainLoop

; Button jump labels
ButtonON: 
   CALL ClearScreen
   JMP MainLoop

ButtonPlus:
   MOV R0, #'+'
   CALL Readoperator

ButtonMinus:
   MOV R0, #'-'
   CALL Readoperator

ButtonMultiply:
   MOV R0, #'*'
   CALL Readoperator

ButtonDivide:
   MOV R0, #'/'
   CALL Readoperator

ButtonEqual:
   MOV R0, #'='
   CALL LCD_Display
   CALL CalculateResult
   JMP MainLoop

Button0:
   MOV R0, #'0'
   CALL Readnum
   
Button1:
   MOV R0, #'1'
   CALL Readnum
   
Button2:
   MOV R0, #'2'
   CALL Readnum
   
Button3:
   MOV R0, #'3'
   CALL Readnum
   
Button4:
   MOV R0, #'4'
   CALL Readnum
   
Button5:
   MOV R0, #'5'
   CALL Readnum
   
Button6:
   MOV R0, #'6'
   CALL Readnum
   
Button7:
   MOV R0, #'7'
   CALL Readnum
   
Button8:
   MOV R0, #'8'
   CALL Readnum
   
Button9:
   MOV R0, #'9'
   CALL Readnum

Readoperator:
   CALL HandleOperation
   CALL LCD_Display
   JMP MainLoop

Readnum:
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop
; LCD functions
LCD_Display:   
   MOV SBUF,R0
   SETB P3.1
   CLR TI
   JNB TI, $
   CALL Delay
   RET

; Number handling
HandleNumber: 
   JB P3.7, SecondNumber
   JB P3.6, NewDigit
   MOV A, R0
   SUBB A, #30H
   MOV R1, A
   SETB P3.6
   RET

NewDigit: 
   MOV A, R0
   MOV B, #10D
   SUBB A, #30H
   MOV R7, A
   MOV A, R1
   MUL AB
   MOV R6, B
   CJNE R6, #00H, JumpOverflow
   ADD A, R7
   JC JumpOverflow
   MOV R1, A
   SETB P3.6
   RET

SecondNumber:
   JB P3.6, NewDigit2
   MOV A, R0
   SUBB A, #30H
   MOV R3, A
   SETB P3.6
   RET

NewDigit2: 
   MOV A, R0
   MOV B, #10D
   SUBB A, #30H
   MOV R7, A
   MOV A, R3
   MUL AB
   MOV R6, B
   CJNE R6, #00H, JumpOverflow
   ADD A, R7
   JC JumpOverflow
   MOV R3, A
   SETB P3.6
   RET

; Operation handling
HandleOperation:
   SETB P3.7
   CLR P3.6
   MOV A, R0
   MOV R2, A
   RET

CalculateResult:
   CJNE R2, #'+', Subtract
   MOV A, R1
   CLR C
   ADD A, R3
   JC JumpOverflow
   MOV R5, #0H
   MOV R4, A
   LJMP PrintResult

Subtract:
   CJNE R2, #'-', Multiply
   MOV A, R1
   CLR C
   SUBB A, R3
   JC JumpOverflow
   MOV R5, #0H
   MOV R4, A
   LJMP PrintResult

Multiply:
   CJNE R2, #'*', Divide
   MOV A, R1
   MOV B, R3
   MUL AB
   MOV R7, B
   CJNE R7, #0H, Overflow
   MOV R5, #0H
   MOV R4, A
   LJMP PrintResult

Divide:
   MOV A, R1
   MOV B, R3
   DIV AB
   MOV R4, A
   MOV R5, B
   LJMP PrintResult

JumpOverflow: 	
   LJMP Overflow
PrintResult:
   CJNE R3, #0D, NormalResult
   CJNE R2, #'/', NormalResult
   MOV R0, #0C0H
   MOV DPTR, #ErrorMsg
   CLR C
   MOV R7, #0D

PrintLoop:	
   MOV A, R7
   MOVC A, @A+DPTR
   MOV R0, A
   CALL LCD_Display
   INC R7
   JNZ PrintLoop
   RET

NormalResult:
   MOV R7, #100D
   CLR C
   SUBB A, R7
   JC LessThan100
   MOV A, R4
   MOV B, R7
   DIV AB
   ADD A, #30H
   MOV R0, A
   CALL LCD_Display
   MOV R4, B
   MOV A, B
   MOV R7, #10D
   MOV B, R7
   DIV AB
   ADD A, #30H
   MOV R0, A
   CALL LCD_Display
   MOV A, B
   ADD A, #30H
   MOV R0, A
   CALL LCD_Display
   CJNE R5, #00H, PrintDecimal
   RET
	
LessThan100: 
   MOV R7, #10D
   CLR C
   MOV A, R4
   SUBB A, R7
   JC LessThan10
   MOV A, R4
   MOV B, R7
   DIV AB
   ADD A, #30H
   MOV R0, A
   CALL LCD_Display	
   MOV A, B 
   ADD A, #30H	
   MOV R0, A
   CALL LCD_Display
   CJNE R5, #00H, PrintDecimal	
   RET				

LessThan10:
   MOV A, R4
   ADD A, #30H
   MOV R0, A
   CALL LCD_Display	
   CJNE R5, #00H, PrintDecimal	
   RET				

Overflow:
   MOV R0, #0C0H
   MOV DPTR, #OverflowMsg
   CLR C	
   MOV R7, #0D
   
Next2:	
   MOV A, R7
   MOVC A, @A+DPTR	
   MOV R0, A
   CALL LCD_Display
   JZ EndNext	
   INC R7	
   JMP Next2
EndNext:	
   RET			

PrintDecimal:
   MOV R0, #'.'	
   CALL LCD_Display
   MOV R6,#1
LOOPD:
   MOV A, R5
   MOV B, #10D
   MUL AB	
   MOV B, R3
   DIV AB	
   ADD A, #30H		
   MOV R0, A	
   CALL LCD_Display
   MOV R5,B
   MOV A,#5
   SUBB A,R6
   JZ NEXTD
   INC R6
   CJNE R5,#0,LOOPD
NEXTD:
   RET		

Delay:
   MOV 62, #2	
Delay1:
   MOV 61, #250
Delay2:
   MOV 60, #250	
   DJNZ 60, $
   DJNZ 61, Delay2
   DJNZ 62, Delay1
   RET

ErrorMsg: DB 'ERROR: DIV BY 0',0

OverflowMsg: DB 'OVERFLOW!',0

ClearScreen:
   MOV SBUF, #254
   CLR TI
   JNB TI, $
   MOV SBUF, #1
   CLR TI
   JNB TI, $
   JNB P2.4, $
   RET
   
END
