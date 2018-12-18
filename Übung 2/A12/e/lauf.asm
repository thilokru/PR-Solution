
	processor	PIC16F84A
	include		p16f84a.inc
	
;Configurationword*******************************************************
	__CONFIG _CP_OFF & _XT_OSC & _WDT_OFF & _PWRTE_ON ;config: 0x3ff1


;INITIALISIERUNG*********************************************************
 org 0x000	;schreibe den n�chsten Befehl an die Speicherstelle 0x000
 
	bsf	STATUS,RP0		;BANK1
	movlw 	0xFF
	movwf 	TRISA			;PORTA als EINGANG
	clrf	TRISB			;PORTB als AUSGANG
	bcf	STATUS,RP0		;BANK0
	
	clrf	PORTA			;PORTA l�schen
	clrf	PORTB			;PORTB l�schen
	movlw	0x00			;00000001 in W
	movwf	0x0C			;lade W in Register 0x0C
							;0x0C ist die erste Speicherzelle
							;im RAM, die nicht von einem SFR
							;verwendet wird
	bcf	STATUS, C			;l�sche das Carry-Bit

;HAUPTPROGRAMM***********************************************************

MAIN
	movlw	0x00			;L�sche PORTA und PORTB
	movwf	0x0C

MAINLOOP
	call delay
	bcf STATUS, C
	incf 	0x0C, f			;Inkrementiere PORTA.
	movfw 	0x0C
	movwf	PORTB
	btfss	STATUS, C			;Falls Overflow, setze zur�ck.
	goto MAINLOOP
	bcf STATUS, C
	goto MAIN


;Delayschleife***********************************************************
delay
	bcf	INTCON, INTF		;INTF external interrupt flag
							;l�schen
delay_loop
	btfss	INTCON, INTF	;springe wenn INTF gesetzt
	goto	delay_loop			
	return
	
 end

;Beschreibung: In den gr�nen und gelben LEDs wird ein "Lauflicht" erzeugt, d.h.
;Takt f�r Takt leuchtet eine andere LED auf. 