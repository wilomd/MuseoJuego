
	CBLOCK
	DataOutput
	ENDC
	
;===============================================================================
;			CONFIGURA EL PIC COMO MAESTRO I2C 
;===============================================================================
I2C_INIT_MASTER
	BANK1

	BSF TRISC,3	    ;SDA COMO ENTRADA
	BSF TRISC,4	    ;SCL COMO ENTRADA
	    
	MOVLW 0x09	    ;(FOSC/(4*BAUD_RATE))-1 -> (4000000/(4*100000))-1	
	MOVWF SSPADD	    ;BAUD_RATE 100 Khz para 4Mhz
	
	MOVLW B'10000000'   
	MOVWF SSPSTAT	    ;DESHABILITA CONTROL DE VARIACIONES PARA VELOCIDAD EST�NDAR (100kHz).
	
	CLRF SSPCON2	    ;CONDICIONES INICIALES EN CERO, LLAMADA GENERAL DESHABILITADA
	
	BANK0
	MOVLW B'00101000'   
	MOVWF SSPCON	    ;SELECCIONA Y HABILITA I2C EN MODO MAESTRO
	
	BCF PIR1,SSPIF	    
	BCF PIR1,BCLIF
	
	RETURN
;===============================================================================
;			CONFIGURA EL PIC COMO ESCLAVO I2C 
;===============================================================================
I2C_INIT_SLAVE
	BANK1
	BSF TRISC,3
	BSF TRISC,4
	
	;MOVLW B'11000000'
	MOVWF SSPADD	;SE CARGA LA DIRECCI�N EN W AL HACER EL LLAMADO
	
	MOVLW B'10000000'
	MOVWF SSPSTAT
	
	CLRF SSPCON2
	
	BANK0
	MOVLW B'00100110'
	MOVWF SSPCON
	
	BCF PIR1,SSPIF
	BCF PIR1,BCLIF
		
	RETURN
;===============================================================================
;			INICIA LA COMUNICACI�N I2C
;===============================================================================	
I2C_START_MASTER
	BANK0
	BCF PIR1,SSPIF
	BANK1
	BSF SSPCON2,SEN	    ;ENV�A LA CONDICI�N DE INICIO
	BANK0
i2c_start_wait
	BTFSC SSPCON2,SEN   ;TERMIN� DE ESTABLECER LA CONDICI�N DE INICIO?
	GOTO i2c_start_wait
	
	RETURN
;===============================================================================
;			TRANSMITE MENSAJE I2C
;===============================================================================
TX
	BANK0
	BCF PIR1,SSPIF
	
	MOVF DataOutput,W   
	MOVWF SSPBUF		;CARGA MENSAJE PARA SER ENVIADO
	
tx_wait
	BTFSS PIR1,SSPIF	;YA SE ENV�O EL MENSAJE?
	GOTO tx_wait	    
	
	BANK1
	BTFSC SSPCON2,ACKSTAT	;FUE RECONOCIDO EL ESCLAVO?
	GOTO $-1
	
	RETURN

;===============================================================================
;	    ESTABLECE LA CONDICI�N DE PARADA DE LA TRANSMISI�N
;===============================================================================
BSTOP
	BANK0
	BCF PIR1,SSPIF
	BANK1
	BSF SSPCON2,PEN
	BANK0
bstop_wait
	BTFSS PIR1,SSPIF
	GOTO bstop_wait
	
	RETURN

;===============================================================================
;			ENV�A UN BYTE POR EL BUS I2C
;===============================================================================
BYTE_WRITE
	CALL I2C_START_MASTER	;INICIA LA COMUNIACI�N
	BANK0
	MOVWF DataOutput	;DATO CARGADO EN W ANTES DE LLAMAR LA RUTINA
	CALL TX			;TRANSMITE
	BANK0
	RETURN
	