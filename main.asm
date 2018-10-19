	List p=16f887
	#include <p16f887.inc>
	
	__CONFIG H'2007', H'3FFC' & H'3FF7' & H'3FFF' & H'3FFF' & H'3FFF' & H'3FFF' & H'3CFF' & H'3BFF' & H'37FF' & H'2FFF' & H'3FFF'
	__CONFIG H'2008', H'3EFF' & H'3FFF'	

;ver 01.1
;===============================================================================
;             Definicion de las macros para cambiar de bancos
;===============================================================================

BANK0	MACRO
	BCF STATUS,5
	BCF STATUS,6
	ENDM
	
BANK1	MACRO
	BSF STATUS,5
	BCF STATUS,6
	ENDM
	
BANK2	MACRO
	BCF STATUS,5
	BSF STATUS,6
	ENDM
	
BANK3	MACRO
	BSF STATUS,5
	BSF STATUS,6
	ENDM
	
ClSPort MACRO
	BCF STATUS,5
	BCF STATUS,6
	CLRF PORTB
	CLRF PORTC
	CLRF PORTA
	CLRF PORTD
	CLRF PORTE
	ENDM
	
DigPort MACRO
	BSF STATUS,5
	BSF STATUS,6
	CLRF ANSEL
	CLRF ANSELH
	ENDM
	
	
CONTA_2	    EQU 0x20
CONTA_1	    EQU 0x21
BIT	    EQU 0x22
TECLA	    EQU 0x23
LAST_TECLA  EQU 0x24
RESPUESTA   EQU 0x25
CORRECTO    EQU 0x26
CONT_WIN    EQU 0x27
 
	
	ORG H'01'
	GOTO INICIO
	
	ORG 04H
	;HACER INT de reinicio o WD funcione....
	
CONVERT_HEX
	ADDWF PCL,F
	DT .1,  .2, .3, .4, .5
	DT .6,  .7, .8, .9,.10
	DT .11,.12,.13,.14,.15
	DT .16,.17,.18,.19,.20
	DT .21,.22,.23,.24,.25
END_CONVERT_HEX
	
RESPUESTAS_1 
	ADDWF PCL,F
	DT .1,.7,.23,.14,.25
	DT .21,.17,.3,.24,.10
	DT .16,.22,.3,.9,.5
	DT .16,.22,.3,.9,.5
	DT .16,.22,.3,.9,.5
END_RESPUESTAS_1
	
RETARDO_20MS
	BANK0
	MOVLW .20
	MOVWF CONTA_2
	MOVLW .250
	MOVWF CONTA_1
	NOP
	DECFSZ CONTA_1,F
	GOTO $-.2
	DECFSZ CONTA_2,F
	GOTO $-.6
	RETURN 
	
INICIO
	
	DigPort
	BANK1
	CLRF TRISD
	BANK0
	CLRF CONT_WIN
	ClSPort
	
	CALL TecladoInicializa
	
LOOP	
	; Fila 1
	BTFSC PORTC,0
	GOTO LOOP
	CALL VALIDATE_ANSWER
	BCF STATUS,Z
	MOVLW .1
	SUBWF CORRECTO
	BTFSS STATUS,Z
	GOTO LOOP
	CLRF CORRECTO
	INCF CONT_WIN
	MOVLW B'00000001'
	MOVWF PORTD
LOOP2
	; Fila 2
	BTFSC PORTC,1
	GOTO LOOP2
	CALL VALIDATE_ANSWER
	BCF STATUS,Z
	MOVLW .1
	SUBWF CORRECTO
	BTFSS STATUS,Z
	GOTO LOOP2
	CLRF CORRECTO
	INCF CONT_WIN
	MOVLW B'00000011'
	MOVWF PORTD
	
LOOP3
	; Fila 3
	BTFSC PORTC,2
	GOTO LOOP3
	CALL VALIDATE_ANSWER
	BCF STATUS,Z
	MOVLW .1
	SUBWF CORRECTO
	BTFSS STATUS,Z
	GOTO LOOP3
	CLRF CORRECTO
	INCF CONT_WIN
	MOVLW B'00000111'
	MOVWF PORTD

LOOP4
	; Fila 4
	BTFSC PORTC,3
	GOTO LOOP4
	CALL VALIDATE_ANSWER
	BCF STATUS,Z
	MOVLW .1
	SUBWF CORRECTO
	BTFSS STATUS,Z
	GOTO LOOP4
	CLRF CORRECTO
	INCF CONT_WIN
	MOVLW B'00001111'
	MOVWF PORTD	
LOOP5
	; Fila 5
	BTFSC PORTC,4
	GOTO LOOP5
	CALL VALIDATE_ANSWER
	BCF STATUS,Z
	MOVLW .1
	SUBWF CORRECTO
	BTFSS STATUS,Z
	GOTO LOOP5
	CLRF CORRECTO
	INCF CONT_WIN
	MOVLW B'00011111'
	MOVWF PORTD

CLEAR
	CLRF PORTD
	GOTO LOOP
	
;==============================================================================
;VALIDA SI LA RESPUESTA ES CORRECTA
;==============================================================================

VALIDATE_ANSWER	
	CALL READ_HEX
	MOVWF RESPUESTA
	CALL Teclado_EsperaDejePulsar
	MOVF CONT_WIN,W
	CALL RESPUESTAS_1
	SUBWF RESPUESTA
	BTFSS STATUS,Z
	RETURN
	MOVLW .1
	MOVWF CORRECTO
	RETURN
;==============================================================================
;LEER EL VALOR EN TECLADO 5x5
;==============================================================================

READ_HEX
	CALL Teclado_LeeOrdenTecla
	BTFSS STATUS,C
	GOTO READ_HEX_END
	CALL CONVERT_HEX
	BSF STATUS,C
READ_HEX_END
	RETURN
;===============================================================================
;INICIALIZAR EL TECLADO 5x5
;===============================================================================
TecladoInicializa
	BANK1
	MOVLW B'00000000'
	MOVWF TRISB
	MOVLW 0x1F
	MOVWF TRISC
	BANK0
	MOVLW .25
	MOVWF LAST_TECLA
	RETURN
;===============================================================================
;ANTIREBOTE PARA LOS PULSADORES
;===============================================================================
Teclado_EsperaDejePulsar
	BANK0
	MOVLW 0x1F
	MOVWF PORTC
Teclado_SigueEsperando
	CALL RETARDO_20MS
	MOVF PORTC,W
	SUBLW 0x1F
	BTFSS STATUS,Z
	GOTO Teclado_SigueEsperando
	CLRF PORTB
	RETURN
;===============================================================================
; SCAN TECLAS PARA SELECION DE LA RESPUESTA
;===============================================================================

Teclado_LeeOrdenTecla
	BANK0
	CLRF TECLA
	MOVLW B'11111110'
CHECK_ROW
	MOVWF PORTB
CHECK_COL_1
	BTFSS PORTC,0
	GOTO SAVE_VALUE
	INCF TECLA,F
CHECK_COL_2
	BTFSS PORTC,1
	GOTO SAVE_VALUE
	INCF TECLA,F
CHECK_COL_3
	BTFSS PORTC,2
	GOTO SAVE_VALUE
	INCF TECLA,F
CHECK_COL_4
	BTFSS PORTC,3
	GOTO SAVE_VALUE
	INCF TECLA,F
CHECK_COL_5
	BTFSS PORTC,4
	GOTO SAVE_VALUE
	INCF TECLA,F	
END_COL
	MOVLW LAST_TECLA
	SUBWF TECLA,W
	BTFSC STATUS,C
	GOTO TECLA_NO_PULSE
	BSF STATUS,C
	RLF PORTB,W
	GOTO CHECK_ROW
	
TECLA_NO_PULSE
	BCF STATUS,C
	GOTO KEYBOARD_END
SAVE_VALUE
	MOVF TECLA,W
	BSF STATUS,C
KEYBOARD_END
	RETURN
		
	
	END