ORG 00H

   ; Initialize LCD
   MOV R0, #38H
   CALL LCD_Command
   MOV R0, #0EH
   CALL LCD_Command
   MOV R0, #06H
   CALL LCD_Command
   MOV R0, #80H
   CALL LCD_Command
   MOV R0, #01H
   CALL LCD_Command

   ; Initialize variables and ports
   MOV R4, #00H
   MOV P2, #00H
   MOV P3, #0FEH
   MOV R3, #00H
   MOV R1, #00H
   MOV R2, #'+'
   
MainLoop:
   JNB P3.0, CheckColumn1
   JNB P3.1, CheckColumn2
   JNB P3.2, CheckColumn3
   JNB P3.3, CheckColumn4
   SJMP MainLoop

CheckColumn1:
   JNB P3.4, JumpToButtonON
   JNB P3.5, JumpToButton0
   JNB P3.6, JumpToButtonEqual
   JNB P3.7, JumpToButtonPlus
   SETB P3.0
   CLR P3.1
   SJMP MainLoop

CheckColumn2:
   JNB P3.4, JumpToButton1
   JNB P3.5, JumpToButton2
   JNB P3.6, JumpToButton3
   JNB P3.7, JumpToButtonMinus
   SETB P3.1
   CLR P3.2
   SJMP MainLoop

CheckColumn3:
   JNB P3.4, JumpToButton4
   JNB P3.5, JumpToButton5
   JNB P3.6, JumpToButton6
   JNB P3.7, JumpToButtonMultiply
   SETB P3.2
   CLR P3.3
   SJMP MainLoop

CheckColumn4:
   JNB P3.4, JumpToButton7
   JNB P3.5, JumpToButton8
   JNB P3.6, JumpToButton9
   JNB P3.7, JumpToButtonDivide
   SETB P3.3
   CLR P3.0
   LJMP MainLoop

; Button jump labels
JumpToButtonON: LJMP ButtonON
JumpToButton0: LJMP Button0
JumpToButton1: LJMP Button1
JumpToButton2: LJMP Button2
JumpToButton3: LJMP Button3
JumpToButton4: LJMP Button4
JumpToButton5: LJMP Button5
JumpToButton6: LJMP Button6
JumpToButton7: LJMP Button7
JumpToButton8: LJMP Button8
JumpToButton9: LJMP Button9
JumpToButtonPlus: LJMP ButtonPlus
JumpToButtonMinus: LJMP ButtonMinus
JumpToButtonMultiply: LJMP ButtonMultiply
JumpToButtonDivide: LJMP ButtonDivide
JumpToButtonEqual: LJMP ButtonEqual

; Button handlers
ButtonON:
   SETB P2.0
   LJMP MainLoop

ButtonEqual:
   MOV R0, #'='
   CALL LCD_Display
   CALL CalculateResult
   JMP MainLoop

ButtonPlus:
   MOV R0, #'+'
   CALL HandleOperation
   CALL LCD_Display
   JMP MainLoop

ButtonMinus:
   MOV R0, #'-'
   CALL HandleOperation
   CALL LCD_Display
   JMP MainLoop

ButtonMultiply:
   MOV R0, #'*'
   CALL HandleOperation
   CALL LCD_Display
   JMP MainLoop

ButtonDivide:
   MOV R0, #'/'
   CALL HandleOperation
   CALL LCD_Display
   JMP MainLoop

Button0:
   MOV R0, #'0'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button1:
   MOV R0, #'1'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button2:
   MOV R0, #'2'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button3:
   MOV R0, #'3'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button4:
   MOV R0, #'4'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button5:
   MOV R0, #'5'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button6:
   MOV R0, #'6'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button7:
   MOV R0, #'7'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button8:
   MOV R0, #'8'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

Button9:
   MOV R0, #'9'
   CALL HandleNumber
   CALL LCD_Display
   JMP MainLoop

; LCD functions
LCD_Display:   
   MOV P1, R0
   SETB P2.1  
   SETB P2.2
   CLR P2.2
   CALL Delay
   RET

LCD_Command:
   MOV P1, R0
   CLR P2.1
   SETB P2.2
   CLR P2.2
   CALL Delay
   RET

; Number handling
HandleNumber: 
   JB P2.7, SecondNumber
   JB P2.6, NewDigit
   MOV A, R0
   SUBB A, #30H
   MOV R1, A
   SETB P2.6
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
   SETB P2.6
   RET

SecondNumber:
   JB P2.6, NewDigit2
   MOV A, R0
   SUBB A, #30H
   MOV R3, A
   SETB P2.6
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
   SETB P2.6
   RET

; Operation handling
HandleOperation:
   SETB P2.7
   CLR P2.6
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
   CALL LCD_Command
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
   CALL LCD_Command
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
   MOV A, R5
   MOV B, #10D
   MUL AB	
   MOV B, R3
   DIV AB	
   ADD A, #30H		
   MOV R0, A	
   CALL LCD_Display		
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

ErrorMsg: DB 'ERROR: DIV BY 0'
OverflowMsg: DB 'OVERFLOW!'

END
