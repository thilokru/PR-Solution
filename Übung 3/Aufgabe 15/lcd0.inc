;Version 1.1
;Umlaute ersetzt, Kommentar zu Macros.
;Includedatei fuer die Ansteuerung eines LCD-Dot-Matrix Displays.
;
;Timing ist gedacht fuer einen 4MHz Oszillatortakt
;
;Verwendung: Siehe LCD_inc.pdf
;

;Variablen***************************************************************
 
 cblock
  LCD_out, LCD_in, LCD_flags
   BIN0, BIN1, BIN2, BCD0, BCD1, BCD2, BCD3
   w_temp, counter   
 endc
 
 #define LCD_RS_temp		LCD_flags,0


;Makros******************************************************************
		
LCD_line_1	macro
	movlw	b'10000000'		;h'80'+h'00'
	call	LCD_control_send
	endm


LCD_line_2	macro
	movlw	b'11000000'		;h'80'+h'40'
	call	LCD_control_send
	endm


LCD_clear_display	macro
	movlw	b'00000001'
	call	LCD_control_send
	endm
	
	
LCD_send_char	macro char
	movlw	char
	call	LCD_data_send
	endm

;Routinen*****************************************************************
;Benoetigen Register LCD_out, LCD_in
;Benoetigen Bits LCD_RS_temp
;*************************************************************************

;*************************************************************************
;Stacklevel 2
LCD_data_send
	bsf	LCD_RS_temp		
	
LCD_control_send			
	movwf	LCD_out				;w sichern

LCD_ready						;Warte bis LCD bereit
	call	LCD_read_status		;
	btfsc	LCD_in, 7			;
	goto	LCD_ready			;

LCD_write
	call	LCD_output			;Set IO ports for send operation

	bcf	LCD_RS			;
	btfsc	LCD_RS_temp			;Daten oder Kontroll-Komando
	bsf	LCD_RS			;
	
	call	LCD_write_nibble_H	;schreibe oberes Nibble
	swapf	LCD_out,f
	call	LCD_write_nibble_H	;schreibe unteres Nibble

	call	LCD_reset_output	;Ausgang zuruecksetzen
	bcf	LCD_RS_temp				;LCD_RS zuruecksetzen fuer naechsten Aufruf
	bcf	LCD_RS	
	
	return


;************************************************************************
;Stacklevel 2
LCD_function_send			;sendet nur das High Nibble
	movwf	LCD_out			;w sichern

	bcf		LCD_RS		    ; Kontroll-Komando
	
	call	LCD_output		;Set IO ports for send operation

	call	LCD_write_nibble_H
	call	LCD_reset_output	;Ausgang zuruecksetzen
	bcf	LCD_RS_temp
		
	return
	
	
;************************************************************************
;Stacklevel 1
LCD_read_status
	call	LCD_input
	bcf 	LCD_RS		;
	
	clrf	LCD_in	
	call	LCD_read_nibble_H	;read Hi nibble
	swapf	LCD_in,f
	call	LCD_read_nibble_H	;read Lo nibble
	swapf	LCD_in,f		
	
	movf	LCD_in,W
	return


;************************************************************************
;Stacklevel 0
LCD_read_nibble_H
	bsf	LCD_RW		;Initiate read operation 
	bsf	LCD_E	
	nop
	
	btfsc	LCD_D7		;Read 4 databits
	bsf	LCD_in,7
	btfsc	LCD_D6
	bsf	LCD_in,6
	btfsc	LCD_D5
	bsf	LCD_in,5
	btfsc	LCD_D4
	bsf	LCD_in,4

	bcf 	LCD_E		;End read operation
	
	return


;************************************************************************
;Stacklevel 1
LCD_write_nibble_H
	bsf	LCD_E		;enable	
	
	call	LCD_reset_output	;Ausgang zuruecksetzen
	
	btfsc	LCD_out,7
	bsf	LCD_D7
	btfsc	LCD_out,6
	bsf	LCD_D6
	btfsc	LCD_out,5
	bsf	LCD_D5
	btfsc	LCD_out,4
	bsf	LCD_D4
	nop
	nop
	nop
	bcf	LCD_E		;LCD-Enable-Bit ausschalten -> Daten werden von LCD uebernommen

	return
	

;************************************************************************
;Stacklevel 0
LCD_reset_output
	bcf	LCD_D7	;Ausgang zuruecksetzen
	bcf	LCD_D6
	bcf	LCD_D5
	bcf	LCD_D4
	return
	

;************************************************************************
;Stacklevel 0
LCD_input
	bsf	LCD_RW		;LCD_RW=Hi configures LCD to talk
	banksel TRISA
	bsf 	LCD_D4		;D4..D7 als Eingang
	bsf 	LCD_D5
	bsf 	LCD_D6
	bsf 	LCD_D7
	bcf	LCD_RS		;RS, RW als Ausgang
	bcf	LCD_RW
	banksel PORTA
	return


;************************************************************************
;Stacklevel 0
LCD_output
	bcf	LCD_RW		;LCD_RW=LO configures LCD to listen
	banksel TRISA
	bcf 	LCD_D4		;D4..D7 als Ausgang
	bcf 	LCD_D5
	bcf 	LCD_D6
	bcf 	LCD_D7
	bcf	LCD_RS		;RS, RW als Ausgang
	bcf	LCD_RW
	banksel PORTA
	return
	

;************************************************************************
;Initialisierung 4Bit fuer LCD***********************************************
;Stacklevel 3
LCD_init_4bit
	;Reset ports:
	call 	LCD_reset_output
	bcf	LCD_E
	bcf	LCD_RS
	bcf	LCD_RW
	bcf	LCD_RS_temp

	;Initialization procedure
	call	LCD_delay_20ms

	call	LCD_delay_20ms
	movlw	b'00110000'
	call	LCD_function_send		;
	
	call	LCD_delay_20ms
	movlw	b'00110000'
	call	LCD_function_send		;
	
	call	LCD_delay_20ms
	movlw	b'00110000'
	call	LCD_function_send		;
	
	call	LCD_delay_20ms
	movlw	b'00100000'
	call	LCD_function_send		;
	
	call	LCD_delay_20ms
	movlw	b'00101001'
	call	LCD_control_send		;ok
	
	call	LCD_delay_20ms
	movlw	b'00011100'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'01010010'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'01101001'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'01110111'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'00101000'
	call	LCD_control_send		;ok
	
	call	LCD_delay_20ms
	movlw	b'00001100'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'00000001'
	call	LCD_control_send		;
	
	call	LCD_delay_20ms
	movlw	b'00000110'
	call	LCD_control_send		;

	return				;


;************************************************************************
;Diese Routine wartet 20ms und wird waehrend der Initialisierung des Displays
;aufgerufen
LCD_delay_20ms

cblock
 dcnt1, dcnt2
endc
	;initalize loop counters
	movlw 	0x1A
	movwf 	dcnt2
	movlw 	0xEF
	movwf 	dcnt1
	
	;delay loops
	decfsz 	dcnt1,f
	goto 	$-1
	decfsz 	dcnt2,f
	goto 	$-3
	
	return
				

;************************************************************************
;Interpretiert W als 2*Hex-Zahl und schreibt beide "Ziffern" auf LCD*******
;Stacklevel 3
W_2HEX_to_LCD
	movwf	w_temp
	swapf	w_temp,W		;First Number				
	andlw	0x0f
	sublw	0x09
	btfss	STATUS,C		;carry geloescht, wenn Buchstabe A-F
	addlw	0xF9			;=-7
	sublw	0x39			;=0x30+d'9'
	call	LCD_data_send
	
	movf	w_temp,W		;second_number				
	andlw	0x0f
	sublw	0x09
	btfss	STATUS,C		;carry geloescht, wenn Buchstabe A-F
	addlw	0xF9			;=-7
	sublw	0x39			;=0x30+d'9'
	call	LCD_data_send
	
	return


;************************************************************************
;Interpretiert das untere Nibble als eine HEX stelle->LCD 
;Stacklevel 3
W_1HEX_to_LCD				
	andlw	0x0f
	sublw	0x09
	btfss	STATUS,C		;carry geloescht, wenn Buchstabe A-F
	addlw	0xF9			;=-7
	sublw	0x39			;=0x30+d'9'
	call	LCD_data_send
	return
	

;************************************************************************
;Schreibt W als dreistellige Dezimalzahl auf das Display
;Stacklevel 3
W_dez_to_LCD

	return
	
;************************************************************************
