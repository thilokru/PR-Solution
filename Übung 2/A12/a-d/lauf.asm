
	processor	PIC16F84A
	include		p16f84a.inc
	
;Configurationword*******************************************************
	__CONFIG _CP_OFF & _XT_OSC & _WDT_OFF & _PWRTE_ON ;config: 0x3ff1


;INITIALISIERUNG*********************************************************
 org 0x000	;schreibe den nächsten Befehl an die Speicherstelle 0x000
 
	bsf	STATUS,RP0		;BANK1
	clrf	TRISA			;PORTA als AUSGANG
	clrf	TRISB			;PORTB als AUSGANG
	bcf	OPTION_REG,PSA		;Prescaler auf TMR0
	bcf	OPTION_REG,PS0		;
	bsf	OPTION_REG,PS1		;Prescaler auf 1:256
	bcf	OPTION_REG,PS2		;
	bcf	OPTION_REG,T0CS		;Internal Clock
	bcf	STATUS,RP0		;BANK0
	
	clrf	PORTA			;PORTA löschen
	clrf	PORTB			;PORTB löschen
	movlw	0x00			;00000001 in W
	movwf	0x0C			;lade W in Register 0x0C
							;0x0C ist die erste Speicherzelle
							;im RAM, die nicht von einem SFR
							;verwendet wird
	movwf 0x0D
	bcf	STATUS, C			;lösche das Carry-Bit

;HAUPTPROGRAMM***********************************************************

MAIN
	movlw	0x00			;Lösche PORTA und PORTB
	movwf	0x0C
	movwf 	0x0D

MAINLOOP
	call delay
	incf 	0x0C, f			;Inkrementiere PORTB.
	movfw 	0x0C
	movwf 	PORTA
	btfss	0x0C, 5		;Falls Overflow, bearbeite PORTA
	goto MAINLOOP
	clrf 0x0C
	bcf STATUS, C
	incf 	0x0D, f			;Inkrementiere PORTA.
	movfw 	0x0D
	movwf	PORTB
	btfss	STATUS, C			;Falls Overflow, setze zurück.
	goto MAINLOOP
	bcf STATUS, C
	goto MAIN


;Delayschleife***********************************************************
delay
	clrf	TMR0			;lösche TMR0
	bcf	INTCON,T0IF			;TMR0 overflow interrupt flag
							;löschen
delay_loop
	btfss	INTCON,T0IF		;springe wenn T0IF gesetzt
	goto	delay_loop			
	return
	
 end

;Beschreibung: In den grünen und gelben LEDs wird ein "Lauflicht" erzeugt, d.h.
;Takt für Takt leuchtet eine andere LED auf. 