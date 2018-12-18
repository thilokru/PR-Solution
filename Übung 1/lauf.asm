
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
	bsf	OPTION_REG,PS0		;
	bsf	OPTION_REG,PS1		;Prescaler auf 1:256
	bsf	OPTION_REG,PS2		;
	bcf	OPTION_REG,T0CS		;Internal Clock
	bcf	STATUS,RP0		;BANK0
	
	movlw 0xFF
	movwf PORTB
	
 end

;Beschreibung: In den grünen und gelben LEDs wird ein "Lauflicht" erzeugt, d.h.
;Takt für Takt leuchtet eine andere LED auf. 