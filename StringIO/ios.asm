%include "io.mac"

	; exception handling
	; numbert (size): 
	; --> -000000000000000001 --> ERROR							OK!
	; --> 000000000000000001 --> 1								OK!
	; --> don' t accept negative string size					OK!
	; --> don't accpet size bigger than the input buffer, 
	;	  which can hold up to 100 chars, plus NULL and ENTER	OK!
	; --> can't be a letter 									OK!
	; string:
	; --> don't accept void strings								OK!
	; --> don't accpet input string bigger than the input buffer, 		
	; 	  which can hold up to 100 chars, plus NULL and ENTER   OK!

section .data
	msgIn1		db	"insert a string: ",0
	msgIn1_size	equ	$-msgIn1

	msgIn2		db	"insert the string size: ",0
	msgIn2_size	equ	$-msgIn2

	msgIn3		db	"S_INPUT / S_OUTPUT: ",0
	msgIn3_size	equ	$-msgIn3

	strError	db	'string not valid. please enter a valid one: ', 0
	strEr_size	equ $-strError

	numError	db	'size not valid. please enter a valid one: ', 0
	numEr_size	equ $-numError

	Nwln		db 	0x0d,0x0a
	Nwln_size	equ	$-Nwln

section .bss
	inStr		resb 102 ; input string (100 chars + NULL + ENTER)
	strSize		resb 24 ; ascii buffer to define the size of the string
	digStrSize	resd 1 ; digit string size 
	tmp			resb 102 ; temporary string
	outStr		resb 102 ; output string (100 chars + NULL + ENTER)

	; S_INPUT label qtdChar 
	; S_OUTPUT label qtdChar
	; read until it reachs qtdChar or ENTER

section .text
	global _start
_start:
	
	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgIn2	
	mov 	edx, msgIn2_size 
	int 	80h

num_tryAgain:

	mov	 	esi, strSize ; asssign the the buffer's starting address to the source index register
	sub 	edi, edi ; index counter

dontInsertZ:

num_fillBuffer:

	; scan number by number
	mov 	eax, 3
	mov 	ebx, 0
	mov 	ecx, esi	
	mov 	edx, 1 
	int 	80h	

	; don't insert zeros
	cmp 	byte[esi], '0'
	jz 		dontInsertZ

	; throw error if it's a void size
	cmp 	byte[strSize], 0x0a
	jz 		sayNumError

	; exit filling buffer, if it's ENTER 
	cmp 	byte[esi], 0x0a
	jz 		num_bufferFilled

	inc 	esi ; increment label address
	inc 	edi ; index counter

	jmp 	num_fillBuffer

num_bufferFilled:

	dec 	edi ; putting ENTER aside

num_checkBuffer:

	; if the first char is '-', throw error already
	cmp 	byte[strSize+edi], '-'
	jz 		sayNumError

	; make sure it's a number in a range from 0 to 9
	cmp 	byte[strSize+edi], '0' 
	jb 		sayNumError
	cmp 	byte[strSize+edi], '9'
	ja 		sayNumError 

	dec 	edi ; decrease buffer's index

	; stop when buffer's index is zero
	cmp 	edi, -1
	jg 		num_checkBuffer

	jmp 	inputStr

sayNumError:

	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, numError
	mov 	edx, numEr_size
	int 	80h

	jmp 	num_tryAgain

inputStr:


; ------------------------------------------------------------------


	; trasform strSize into digit	

	sub 	esi, esi ; assign zero to the source index
    sub 	eax, eax ; assign zero to the value accumulator

next_char0:

	; char extraction
	movzx 	ebx, byte [strSize+esi] ; extract char from the input buffer
	inc 	esi ; increment souce index
	cmp 	ebx, '-' ; negative signed?
	jz 		next_char0 ; if so, skip turn
	cmp 	ebx, 0x0a ; compare if the current char is carriage return
	jz 		next0 ; if so, exit loop

	; subtraction
	sub 	ebx, 0x30 ; transform ascii into integer

	; product
	mov 	ecx, 10 ; factor 2 = 10 ( factor 1 = eax )
	imul 	ecx	; product  = factor 1 x factor

	; product + subtraction
	add 	eax, ebx ; passing this char to eax
	
	jne 	next_char0 ; compute next char

next0: 

	mov 	dword[digStrSize], eax

	cmp 	eax, 102 ; include NULL and ENTER, besides 100 chars
	ja 		sayNumError ; if the number is above 102, throw error


; ------------------------------------------------------------------


	; making my own string for testing
	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgIn1	
	mov 	edx, msgIn1_size 
	int 	80h

str_tryAgain:

	mov 	esi, inStr ; assign the input string buffer's starting address to the source index
	sub 	edi, edi ; set index counter to zero

str_fillBuffer:

	; scan letter by letter
	mov 	eax, 3
	mov 	ebx, 0
	mov 	ecx, esi 		
	mov 	edx, 1 ; read the string according to its size
	int 	80h

	; throw error if it's a void string
	cmp 	byte[inStr], 0x0a
	jz 		sayStrError

	; exit filling buffer, if it's ENTER
	cmp 	byte[esi], 0x0a
	jz 		str_bufferFilled

	inc 	esi ; incremente input string buffer's address
	inc 	edi ; increment index counter
	jmp 	str_fillBuffer

str_bufferFilled:

	; throw error if qtd of chars is bigger then the buffer's size
	cmp 	edi, 101 ; (0-101 size of the buffer)
	ja 		sayStrError

	jmp 	outputStr

sayStrError:

	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, strError
	mov 	edx, strEr_size
	int 	80h

	jmp 	str_tryAgain

outputStr:


; ------------------------------------------------------------------


	; reading string until max size or ENTER
	mov 	esi, inStr
	sub 	edi, edi

next_char1:

	cmp 	byte[esi], 0x0a ; is ENTER?
	jz 		exit1
	cmp 	edi, dword[digStrSize] ; is max size yet?
	jz 		exit1
	mov 	dl, [esi] ; get ascii
	mov 	byte[tmp+edi], dl ; put it into temp
	inc 	esi
	inc 	edi
	jmp 	next_char1

exit1:

	mov 	byte[tmp+edi], 0 ; put NULL at the end of the string


; ------------------------------------------------------------------


	; printing string 

	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgIn3	
	mov 	edx, msgIn3_size 
	int 	80h


	mov 	esi, tmp

next_char2:

	cmp 	byte[esi], 0 ; is NULL yet?
	jz 		exit2

	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, esi ; print current char
	mov 	edx, 1
	int 	80h

	inc 	esi
	jmp 	next_char2

exit2:


; ------------------------------------------------------------------


	; print
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, Nwln
	mov 	edx, Nwln_size
	int		80h

	; exit program
	mov 	eax, 1
	mov 	ebx, 0
	int 	80h