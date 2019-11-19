	; H_INPUT label
	; H_OUTPUT 
	;	--> just positive numbers
	;	--> 0 through 9, and A through F or a through f 
	;	--> read from 2 (before user hits ENTER) until 8 hexas ?

; %include "io.mac"

section .data
	msgIn 		db	'insert a number: ',0
	msgIn_size 	equ	$-msgIn

	warning1 	db	'	  --> UNSIGNED <--  	',0
	size_w1		equ $-warning1
	warning2	db 	'    sum cant be bigger than 0xffffffff    ',0
	size_w2		equ $-warning2

	msg 		db	'second addend for summing: ',0
	msg_size	equ	$-msg

	error		db	'hexa not valid. please enter a valid one: ', 0
	error_size	equ $-error

	msgOut		db	'answer = ',0
	msgOut_size equ  $-msgOut

	Nwln 		db 	0x0d,0x0a
	nwln_size 	equ $-Nwln


section .bss
	; buffer length bigger than 12 (which is the highest acceptable ascii 
	; representation for a singed 32-bit hexa) on purpose
	; the program will tell the user when the hexa in ascii is too large
	; to be represented, although it can be written right
	numberIn 	resb 18 ; reserve 8 hexas for addend plus ENTER
	addend		resb 18 ; reserve 8 hexas for addend plus ENTER
	numberOut 	resb 18 ; reserve 8 hexas for numberOut plus ENTER
section .text
	global _start
_start:

	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgIn
	mov 	edx, msgIn_size
	int 	80h


;-------------------------------------------------------------------------------------------------
	

tryAgain:

	; scan 
	mov 	eax, 3
	mov 	ebx, 0 
	mov 	ecx, addend
	mov 	edx, 18	; 8 possible digits to be inserted plus ENTER
	int 	80h

; ---------------------------------------------

	;  000 000 000 0 0		\
	;						 } 	numero = 0
	;  000 000 000 0 ENTER	/
	;  000 000 000 1 ENTER --> 9 zeros, [buffer+9] = 1 e [buffer+10] = ENTER
	; -000 000 000 1 ENTER --> '-', 9 zeros, [buffer+10] = 1 e [buffer+10] = ENTER

	; if negative, throw error
	cmp 	byte[addend], '-'
	jz 		l_outRange ; sayError	

	; take all the leading zeros off
	mov 	esi, addend ; pass the buffer starting address into esi
	sub 	edi, edi ;  zero-counter
	sub 	edx, edx ; a flag that says whether number is negative or not

nextLeadingZ:
	
	cmp 	byte[esi], '0' ; is zero?
	jz 		isZero ; if so...
	jmp 	notZero ; if no...

isZero: 

	inc 	esi ; get next ascii's address 
	inc 	edi ; increment the zero-counter
	jmp 	nextLeadingZ ; compute next leading zero
	
notZero:
	
	;rewriting buffer with no leading zeros
	sub 	esi, esi ; set index to zero 

newBuffer:

	mov 	bl, [addend+edi] ; moves first character non-zero into bl
	cmp 	bl, 0x0a ; is ENTER?
	jz 		finished ; if so, finish building new buffer
	mov 	byte[addend+esi], bl ; put the non-zero into the new buffer byte
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	jmp 	newBuffer ; build new buffer's next byte

finished:
	
	cmp 	esi, 0 ; if the new buffer's index was not incremented, then the number is zero 
	jz 		NoIsZero
	; if the new buffer's index was incremented one or more times...
	mov 	byte[addend+esi], 0x0a ; now we're good, inserting this ENTER in the new 
	jmp 	nextSetp				 ; buffer last index position
	

NoIsZero:

	; if the number is zero
	mov 	byte[addend], '0' ; insert ascii '0'
	mov 	byte[addend+1], 0x0a ; insert ENTER

nextSetp:

; ---------------------------------------------

	sub 	esi, esi ; set index to zero

scanBuffer:

	; find out how many chars ('-' e/ou digits) there are in the buffer
	cmp 	byte[addend+esi], 0x0a ; stop counting when it reaches ENTER
	jz 		scanCompleted
	inc 	esi
	jmp 	scanBuffer

scanCompleted:

	; positive
	cmp 	esi, 8 ; (0-8): 8 possible alfanumeric chars, plus ENTER
	ja 		l_outRange	

; ---------------------------------------------

	; paser (check if it is a valid number)
	mov 	esi, addend ; assigning the label starting address
	
nextByte:

	; ; 1 --> Not a hexa / 0 --> hexa!
	; mov 	al, 1 ; flag to point out whether char is permitted

	cmp 	byte[esi], 0x0a ; is ENTER?
	jz 		validNo ; if so, exit loop (it's a valid number)
	
	; is it a number in the range 0-9
	cmp 	byte[esi], '0' 
	jge 	ge_zero
	jmp 	n_outRange
ge_zero:
	cmp 	byte[esi], '9'
	jbe 	be_nine 
	jmp 	n_outRange
be_nine: 
	inc 	esi ; increment label address
	jmp 	nextByte

n_outRange:

	; is it a letter in the range A-F
	cmp 	byte[esi], 'A' 
	jge 	ge_A
	jmp 	L_outRange
ge_A:
	cmp 	byte[esi], 'F'
	jbe 	be_F 
	jmp 	L_outRange
be_F:
	inc 	esi ; increment label address
	jmp 	nextByte

L_outRange:

	; is it a letter in the range a-f
	cmp 	byte[esi], 'a' 
	jge 	ge_a
	jmp 	l_outRange
ge_a:
	cmp 	byte[esi], 'f'
	jbe 	be_f
	jmp 	l_outRange
be_f:
	inc 	esi ; increment label address
	jmp 	nextByte

l_outRange:


	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, error
	mov 	edx, error_size
	int 	80h

	jmp 	tryAgain

validNo:


;-------------------------------------------------------------------------------------------------


	; ----> ASCII (HEXA) INTO INTEGER <----

    sub 	esi, esi ; assign zero to the source index
    sub 	eax, eax ; assign zero to the value accumulator

next_char:

	; char extraction
	movzx 	ebx, byte [addend+esi] ; extract char from the input buffer
	inc 	esi ; increment souce index
	cmp 	ebx, 0x0a ; compare if the current char is carriage return
	jz 		next ; if so, exit loop

	; subtraction
	cmp 	ebx, '0'
	jge 	min_number 
	jmp 	n_done
min_number:
	cmp 	ebx, '9'
	jle 	max_number
	jmp 	n_done
max_number:
	sub 	ebx, 0x30 ; transform ascii (hexa) into integer
n_done: 

	cmp 	ebx, 'A'
	jge 	min_Letter 
	jmp 	L_done
min_Letter:
	cmp 	ebx, 'F'
	jle 	max_Letter
	jmp 	L_done
max_Letter:
	sub 	ebx, 55 ; transform ascii (hexa) into integer
L_done:

	cmp 	ebx, 'a'
	jge 	min_letter 
	jmp 	l_done
min_letter:
	cmp 	ebx, 'f'
	jle 	max_letter
	jmp 	l_done
max_letter:
	sub 	ebx, 87 ; transform ascii (hexa) into integer
l_done:

	; product
	mov 	ecx, 16 ; factor 2 = 16 ( factor 1 = eax )
	mul 	ecx	; product  = factor 1 x factor 2

	; product + subtraction
	add 	eax, ebx ; passing this char to eax
	
	jne 	next_char ; compute next char

next: 


;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------	


	push 	eax


	; **********************************************
	; * SUM CAN'T BE BIGGER THAN 0XFFFFFFFF		   *
	; **********************************************

	; print 
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, warning1
	mov 	edx, size_w1
	int 	80h

	; CR LF
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, Nwln
	mov 	edx, nwln_size
	int 	80h

	; print 
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, warning2
	mov 	edx, size_w2
	int 	80h

	; CR LF
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, Nwln
	mov 	edx, nwln_size
	int 	80h

	; print 
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msg
	mov 	edx, msg_size
	int 	80h


;-------------------------------------------------------------------------------------------------


tryAgain2:

	; scan 
	mov 	eax, 3
	mov 	ebx, 0 
	mov 	ecx, addend
	mov 	edx, 18	; 8 possible digits to be inserted plus ENTER
	int 	80h

; ---------------------------------------------

	;  000 000 000 0 0		\
	;						 } 	numero = 0
	;  000 000 000 0 ENTER	/
	;  000 000 000 1 ENTER --> 9 zeros, [buffer+9] = 1 e [buffer+10] = ENTER
	; -000 000 000 1 ENTER --> '-', 9 zeros, [buffer+10] = 1 e [buffer+10] = ENTER

	; if negative, throw error
	cmp 	byte[addend], '-'
	jz 		l_outRange2 ; sayError	

	; take all the leading zeros off
	mov 	esi, addend ; pass the buffer starting address into esi
	sub 	edi, edi ;  zero-counter
	sub 	edx, edx ; a flag that says whether number is negative or not

nextLeadingZ2:
	
	cmp 	byte[esi], '0' ; is zero?
	jz 		isZero2 ; if so...
	jmp 	notZero2 ; if no...

isZero2: 

	inc 	esi ; get next ascii's address 
	inc 	edi ; increment the zero-counter
	jmp 	nextLeadingZ2 ; compute next leading zero
	
notZero2:
	
	;rewriting buffer with no leading zeros
	sub 	esi, esi ; set index to zero 

newBuffer2:

	mov 	bl, [addend+edi] ; moves first character non-zero into bl
	cmp 	bl, 0x0a ; is ENTER?
	jz 		finished2 ; if so, finish building new buffer
	mov 	byte[addend+esi], bl ; put the non-zero into the new buffer byte
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	jmp 	newBuffer2 ; build new buffer's next byte

finished2:
	
	cmp 	esi, 0 ; if the new buffer's index was not incremented, then the number is zero 
	jz 		NoIsZero2
	; if the new buffer's index was incremented one or more times...
	mov 	byte[addend+esi], 0x0a ; now we're good, inserting this ENTER in the new 
	jmp 	nextSetp2				 ; buffer last index position
	

NoIsZero2:

	; if the number is zero
	mov 	byte[addend], '0' ; insert ascii '0'
	mov 	byte[addend+1], 0x0a ; insert ENTER

nextSetp2:

; ---------------------------------------------


	sub 	esi, esi ; set index to zero

scanBuffer2:

	; find out how many chars ('-' e/ou digits) there are in the buffer
	cmp 	byte[addend+esi], 0x0a ; stop counting when it reaches ENTER
	jz 		scanCompleted2
	inc 	esi
	jmp 	scanBuffer2

scanCompleted2:

	; positive
	cmp 	esi, 8 ; (0-8): 8 possible alfanumeric chars, plus ENTER
	ja 		l_outRange2	

; ---------------------------------------------

	; paser (check if it is a valid number)
	mov 	esi, addend ; assigning the label starting address
	
nextByte2:

	; ; 1 --> Not a hexa / 0 --> hexa!
	; mov 	al, 1 ; flag to point out whether char is permitted

	cmp 	byte[esi], 0x0a ; is ENTER?
	jz 		validNo2 ; if so, exit loop (it's a valid number)
	
	; is it a number in the range 0-9
	cmp 	byte[esi], '0' 
	jge 	ge_zero2
	jmp 	n_outRange2
ge_zero2:
	cmp 	byte[esi], '9'
	jbe 	be_nine2 
	jmp 	n_outRange2
be_nine2: 
	inc 	esi ; increment label address
	jmp 	nextByte2

n_outRange2:

	; is it a letter in the range A-F
	cmp 	byte[esi], 'A' 
	jge 	ge_A2
	jmp 	L_outRange2
ge_A2:
	cmp 	byte[esi], 'F'
	jbe 	be_F2 
	jmp 	L_outRange2
be_F2:
	inc 	esi ; increment label address
	jmp 	nextByte2

L_outRange2:

	; is it a letter in the range a-f
	cmp 	byte[esi], 'a' 
	jge 	ge_a2
	jmp 	l_outRange2
ge_a2:
	cmp 	byte[esi], 'f'
	jbe 	be_f2
	jmp 	l_outRange2
be_f2:
	inc 	esi ; increment label address
	jmp 	nextByte2

l_outRange2:


	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, error
	mov 	edx, error_size
	int 	80h

	jmp 	tryAgain2

validNo2:


;-------------------------------------------------------------------------------------------------


	sub 	esi, esi ; assign zero to the source index
    sub 	eax, eax ; assign zero to the value accumulator

next_char2:

	; char extraction
	movzx 	ebx, byte [addend+esi] ; extract char from the input buffer
	inc 	esi ; increment souce index
	cmp 	ebx, 0x0a ; compare if the current char is carriage return
	jz 		next2 ; if so, exit loop

	; subtraction
	cmp 	ebx, '0'
	jge 	min_number2 
	jmp 	n_done2
min_number2:
	cmp 	ebx, '9'
	jle 	max_number2
	jmp 	n_done2
max_number2:
	sub 	ebx, 0x30 ; transform ascii (hexa) into integer
n_done2: 

	cmp 	ebx, 'A'
	jge 	min_Letter2 
	jmp 	L_done2
min_Letter2:
	cmp 	ebx, 'F'
	jle 	max_Letter2
	jmp 	L_done2
max_Letter2:
	sub 	ebx, 55 ; transform ascii (hexa) into integer
L_done2:

	cmp 	ebx, 'a'
	jge 	min_letter2 
	jmp 	l_done2
min_letter2:
	cmp 	ebx, 'f'
	jle 	max_letter2
	jmp 	l_done2
max_letter2:
	sub 	ebx, 87 ; transform ascii (hexa) into integer
l_done2:

	; product
	mov 	ecx, 16 ; factor 2 = 16 ( factor 1 = eax )
	mul 	ecx	; product  = factor 1 x factor 2

	; product + subtraction
	add 	eax, ebx ; passing this char to eax
	
	jne 	next_char2 ; compute next char

next2: 

	mov 	ecx, eax ; addend 2 ( addend 1 = eax)
	pop 	eax
	add 	eax, ecx ; sum = addend 1 x addend 2


;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------


	; ----> INTEGER INTO ASCII (HEXA) <----

    sub 	esi, esi ; assign zero to the source index

next_dig:

	sub 	edx, edx ; make sure edx is zero for division to occur properly
	mov 	ecx, 16 ; set up divisor
	div 	ecx ; (edx:eax / 10)	edx = mod / eax = quotient

	cmp 	edx, 0
	jge 	min_number3 
	jmp 	n_done3
min_number3:
	cmp 	edx, 9
	jle 	max_number3
	jmp 	n_done3
max_number3:
	add 	edx, 0x30 ; transform integer into ascii (hexa)
n_done3: 

; -----------------------------------
	; upper case
	cmp 	edx, 10
	jge 	min_Letter3
	jmp 	L_done3
min_Letter3:
	cmp 	edx, 15
	jle 	max_Letter3
	jmp 	L_done3
max_Letter3:
	add 	edx, 55 ; transform integer into ascii (hexa)
L_done3:

; -----------------------------------
	; lower case (put it above upper to compute it)
	cmp 	edx, 10
	jge 	min_letter3 
	jmp 	l_done3
min_letter3:
	cmp 	edx, 15
	jle 	max_letter3
	jmp 	l_done3
max_letter3:
	add 	edx, 87 ; transform integer into ascii (hexa)
l_done3:
; -----------------------------------

	inc 	esi ; increment source index

	push 	edx ; pile ascii

	or 		eax, eax ; check if input number was reduced to zero ( if so, set flag ZF )
	jz 		exit ; if so, exit loop

  	jnz	 next_dig ; if no, discover next digit

exit:

	mov 	byte [numberOut+esi], 0x0a ; put ENTER at the end

	sub 	edi, edi ; set destination inex to zero

Index0:

	mov 	ecx, esi ; take advantage of the source index to count it down

unpiling:

	; put ascii's into output buffer to genearte the right number
	pop 	edx	
	mov 	byte [numberOut+edi], dl 
	inc 	edi
	loop 	unpiling


	; print 
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, msgOut
	mov 	edx, msgOut_size
	int 	80h

	; print 
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, numberOut
	mov 	edx, 18 ; ten possible digits of a dword to be inserted plus '-' and ENTER
	int 	80h

	; CR LF
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, Nwln
	mov 	edx, nwln_size
	int 	80h

	; exit program
	mov 	eax, 1
	mov 	ebx, 0 
	int 	80h