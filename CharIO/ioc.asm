%include "io.mac"

section .data
	msgIn		db	"insert a character: ",0
	msgIn_size	equ	$-msgIn

	msgOut		db	"the character is: ",0
	msgOut_size	equ	$-msgOut

	Nwln		db 	0x0d,0x0a
	Nwln_size	equ	$-Nwln

	hello		db	"hello",0

section .bss
	inCh		resb 1 ; input character
	outCh		resb 1 ; output character

section .text
	global _start
_start:
	
	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov		ecx, msgIn	
	mov 	edx, msgIn_size 
	int 	80h

	; scan
	mov 	eax, 3
	mov 	ebx, 0
	mov 	ecx, inCh		
	mov 	edx, 2 ; read the character and ENTER
	int 	80h

; ------------------------------------------------------------------
	
	mov 	dl, [inCh]
	mov 	byte[outCh], dl

; ------------------------------------------------------------------

	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgOut	
	mov 	edx, msgOut_size 
	int 	80h

	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, outCh		
	mov 	edx, 1 ; read the character and ENTER
	int 	80h

	; enter
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, Nwln
	mov 	edx, Nwln_size
	int 	80h

	; exit program
	mov 	eax, 1
	mov 	ebx, 0
	int 	80h