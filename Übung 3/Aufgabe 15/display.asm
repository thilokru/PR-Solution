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

; Wir schalten die internen PullUps aus!				      |
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
 endc
;******************************************************************************	

; INCLUDE-DATEIEN
;*****************************************************************************|
	include	lcd0.inc
;******************************************************************************

; HAUPTPROGRAMM
;*****************************************************************************|
 cblock				; Variablen-namen fuer das MAIN-Programm       |
    IN_VAL
	INDEX
	HELPER
 endc				; 					      |
	movlw 0x00
	movwf IN_VAL
MAIN

	movlw	b'00000001'		;loesche das Display
	call	LCD_control_send

	LCD_line_1	

	LCD_send_char 'H'
	LCD_send_char 'e'
	LCD_send_char 'x'
	LCD_send_char ':'
	LCD_send_char ' '
	
	movfw IN_VAL
	call W_2HEX_to_LCD

	LCD_line_2
	
	LCD_send_char 'B'
	LCD_send_char 'i'
	LCD_send_char 'n'
	LCD_send_char ':'
	LCD_send_char ' '
	
	movlw 0x08
	movwf INDEX
	movlw 0x80
	movwf HELPER
BIN_LOOP
	movfw IN_VAL
	ANDWF HELPER, w
	btfss STATUS, Z
	goto PRINT_1
	LCD_send_char '0'
	goto POST_IF

PRINT_1
	LCD_send_char '1'
POST_IF
	bcf STATUS, C
	rrf HELPER
	decfsz INDEX
	goto BIN_LOOP

	incf IN_VAL
	call DELAY
	goto MAIN
ENDE
	goto	ENDE

;									      |
;******************************************************************************
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

; FUNKTIONEN
;*****************************************************************************|

 end
