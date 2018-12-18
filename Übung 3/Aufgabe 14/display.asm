	processor 16f84a
	#include  <p16f84a.inc>
	include	defines.inc

; Compileroptionen
;*****************************************************************************|
	errorlevel	0

; CONFIG
;*****************************************************************************|
	__CONFIG _CP_OFF & _XT_OSC & _WDT_OFF & _PWRTE_ON		;     |
;									      |
;******************************************************************************

; VEKTOREN
;*****************************************************************************|
; reset-vector								      |
  org 0x000 		;						      |
	goto	INIT	;						      |
;******************************************************************************

; INITIALISIERUNG
;*****************************************************************************|
INIT				; Label der Initalisierung		      |
	banksel	OPTION_REG	; kleine Hilfe des Editors, um die richtige   |
				; Bank des Registers OPTION_REG einzustellen, |
				; erspart hier z.B. bsf STATUS,RP0	      |

; Wir schalten die internen PullUps aus! (und Prescaler auf 256)
	movlw	b'10000111'	; 					      |
	movwf	OPTION_REG	; |RBPU|INTEDG|T0CS|T0SE|PSA|PS<2:0>|	      |
				; RBPU 		1 PortB - Pullups disabled    |
				; INTEDG	1 rising edge		      |
				; T0CS		1 internal 0 RA4	      |
				; T0SE		1 falling edge		      |
				; PSA		1 on WDT 0 on Timer0	      |
				; PS<2:0>	<2:0>	TMR0	WDT	      |
				;		000	1:2	1:1	      |
				;		...	...	...	      |
				;		111	1:256	1:128	      |
				; OPTION_REG is 0xFF after a reset	      |
;									      |
	banksel	PORTA		;IO's initialisieren			      |
	clrf	PORTA		;					      |
	clrf	PORTB		;					      |
;									      |
	banksel	INTCON		;					      |
	movlw	b'00000000'	;					      |
	movwf	INTCON		; |GIE|EEIE|T0IE|INTE|RBIE|TOIF|INTF|RBIF|    |
				; GIE		General Interrupt Enable      |
				; EEIE		EEPROM Interrupt Enable       |
				; TMR0IE	Timer0 Interrupt Enable       |
				; INTE		INT-(RA4) Interrupt Enable    |
				; RBIE		PORTB Interrupt Enable        |
				; T0IF		Timer0 Interrupt Flag         |
				; INTF		INT-(RA4) Interrupt Flag      |
				; RBIF		PORTB Interrupt Flag          |
;									      |
	banksel	TRISA		;Datenrichtung einstellen
	bcf	LCD_E		;PORTA,1 auf 0 -> output
	bcf	ADC_CS		;PORTA,0 auf 0 -> output
	bcf	SW_E		;PORTA,2 auf 0 -> output
	bcf	SPK			;PORTA,3 auf 0 -> output
	bcf	TxD			;PORTB,1 auf 0 -> output
	bsf	RxD	        ;PORTB,0 auf 1 -> input   !!!
	bcf	LCD_RS		;PORTB,6 auf 0 -> output
	bcf	LCD_RW		;PORTB,7 auf 0 -> output
	bcf	LCD_D4		;PORTB,2 auf 0 -> output
	bcf	LCD_D5		;PORTB,3 auf 0 -> output
	bcf	LCD_D6		;PORTB,4 auf 0 -> output
	bcf	LCD_D7		;PORTB,5 auf 0 -> output
	
	banksel PORTA
	bsf	ADC_CS		;Peripherie abschalten
	bcf	LCD_E		
	bcf	SW_E
	bcf	SPK
	bcf	TxD

	call	LCD_init_4bit	;Initialisiere Display

;									      |
	goto	MAIN		; auf zum eigentlichen Programm!	      |
;******************************************************************************

; VARIABLEN Block (Cblock) und Definitionen
;*****************************************************************************|
;	Die folgende Compileranweisung generiert einen Block 		      |
;	von Variablen beginnend an Adresse 0x0C (hier liegen die	      |
;	64 Arbeitsspeicher register)					      |
 cblock	0x0C
	DEPTH
	DIRECTION
	HELPER
 endc
;******************************************************************************	

; INCLUDE-DATEIEN
;*****************************************************************************|
	include	lcd0.inc
;******************************************************************************

; HAUPTPROGRAMM
;*****************************************************************************|
 cblock				; Variablen-namen fuer das MAIN-Programm       |
    FAKTOR
 endc				; 					      |

	movlw 0x00
	movwf DIRECTION
	movwf DEPTH
MAIN

	movlw	b'00000001'		;loesche das Display
	call	LCD_control_send

	btfss DIRECTION, 0		;if(val(0x0D) & 0x01 == 1) {LCD_line2}
	goto POST_MAKRO_1	
	LCD_line_2
POST_MAKRO_1
	
	btfsc DIRECTION, 0		;if(val(0x0D) & 0x01 == 0) {LCD_line1}
	goto POST_MAKRO_2
	LCD_line_1
POST_MAKRO_2
	
	movfw DEPTH				;HELPER = DEPTH
	movwf HELPER
	sublw 0x00
	btfsc STATUS, Z
	goto POST_INDENT
BLANK_LOOP
	LCD_send_char ' '		;Einrücken
	decf HELPER				;Dekrementiere Helper
	btfss STATUS, Z			;Bis Helper 0 ist. Dies ist der Fall, wenn DEPTH Einrückungen geschehen sind.
	goto BLANK_LOOP

POST_INDENT
	LCD_send_char b'00011001' ;Schreib das Pi
	
	call DELAY				;Warte ein bischen
	
	btfss DIRECTION, 0		;DIRECTION == 0, wir gehen vorwärts. Wir inkrementieren
	goto INCREMENT

	btfsc DIRECTION, 0		;DIRECTION == 1, wir gehen rückwärts. Wir dekrementieren.
	goto DECREMENT

	goto MAIN

ENDE
	goto	ENDE

INCREMENT
	incf DEPTH
	movfw DEPTH
	sublw 0x10
	btfsc STATUS, Z
	call RET_INC
	goto MAIN

RET_INC
	movlw 0x01				;Wir werden beim nächsten Schritt wieder zurückgehen.
	movwf DIRECTION
	movlw 0x0F				;Wir müssen beim Rückweg in der letzten Stelle anfangen
	movwf DEPTH
	return

DECREMENT
	decf DEPTH
	movfw DEPTH
	movwf HELPER
	incfsz HELPER
	goto MAIN
	call RET_DEC
	goto MAIN

RET_DEC
	movlw 0x00				;Wir setzen direction und depth auf 0
	movwf DIRECTION
	movwf DEPTH
	return

DELAY
	movlw 0x05
	movwf HELPER
DELAY_SETUP
	clrf TMR0
	bcf INTCON, T0IF	
DELAY_LOOP
	btfss INTCON, T0IF
	goto DELAY_LOOP
	decfsz HELPER
	goto DELAY_SETUP
	return

;									      |
;******************************************************************************


; FUNKTIONEN
;*****************************************************************************|

 end
