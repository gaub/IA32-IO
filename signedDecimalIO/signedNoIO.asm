%include "io.mac"

section .data
	msgIn 		db	'insert a number: ',0
	msgIn_size 	equ	$-msgIn

	warning1 	db	'			--> SIGNED <--			',0
	size_w1		equ $-warning1
	warning2	db 	'  product has to be between −2,147,483,648 and 2,147,483,647  ',0
	size_w2		equ $-warning2

	error		db	'number not valid. please enter a valid one: ', 0
	error_size	equ $-error

	msg 		db	'multiplication factor: ',0
	msg_size	equ	$-msg

	msgOut		db	'answer = ',0
	msgOut_size equ  $-msgOut

	Nwln 		db 	0x0d,0x0a
	nwln_size 	equ $-Nwln

	hello 		db	'hello'


section .bss
	; buffer length bigger than 12 (which is the highest acceptable ascii 
	; representation for a singed 32-bit number) on purpose
	; the program will tell the user when the number in ascii is too large
	; to be represented, although it can be written right
	numberIn 	resb 24 ; reserve 32 bits for numberIn plus '-' and ENTER
	factor		resb 24 ; reserve 32 bits for numberIn plus '-' and ENTER
	numberOut 	resb 24 ; reserve 32 bits for numberOut plus '-' and ENTER

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
	mov 	ecx, numberIn
	mov 	edx, 24	; ten possible digits to be inserted plus '-' and ENTER. throws error, if bigger.
	int 	80h

; ---------------------------------------------

	;  000 000 000 0 0		\
	;						 } 	numero = 0
	;  000 000 000 0 ENTER	/
	;  000 000 000 1 ENTER --> 9 zeros, [buffer+9] = 1 e [buffer+10] = ENTER
	; -000 000 000 1 ENTER --> '-', 9 zeros, [buffer+10] = 1 e [buffer+10] = ENTER	

	; take all the leading zeros off
	mov 	esi, numberIn ; pass the buffer starting address into esi
	sub 	edi, edi ;  zero-counter
	sub 	edx, edx ; a flag that says whether number is negative or not

	; check if it's negative
	cmp 	byte[esi], '-' ; is negative?
	jz 		isNegative
	jmp 	nextLeadingZ

isNegative:
	
	mov 	dl, 1 ; a flag that says whether number is negative or not (TRUE --> negative)
	inc 	esi ; increment index 

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

	mov 	bl, [numberIn+edi] ; moves first character non-zero into bl
	cmp 	bl, 0x0a ; is ENTER?
	jz 		finished ; if so, finish building new buffer
	; if number is negative 
	cmp 	dl, 1 ; if flag is TRUE (points out number is negative)
	jz 		putHyphen ; then put hyphen at the beginning of the buffer
	jmp 	dontPutHyphen ; if no, dont

putHyphen:
	
	mov  	byte[numberIn+esi], '-' ; put hyphen at the beginning of the buffer
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	sub 	edx, edx ; set sign flag to FALSE (not negative)
	jmp 	newBuffer ; build new buffer's next byte

dontPutHyphen:

	mov 	byte[numberIn+esi], bl ; put the non-zero into the new buffer byte
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	jmp 	newBuffer ; build new buffer's next byte

finished:
	
	cmp 	esi, 0 ; if the new buffer's index was not incremented, then the number is zero 
	jz 		NoIsZero
	; if the new buffer's index was incremented one or more times...
	mov 	byte[numberIn+esi], 0x0a ; now we're good, inserting this ENTER in the new 
	jmp 	nextSetp				 ; buffer last index position
	

NoIsZero:

	; if the number is zero
	mov 	byte[numberIn], '0' ; insert ascii '0'
	mov 	byte[numberIn+1], 0x0a ; insert ENTER

nextSetp:

; ---------------------------------------------

	sub 	esi, esi ; set index to zero

scanBuffer:

	; find out how many chars ('-' and/or digits) there are in the buffer
	cmp 	byte[numberIn+esi], 0x0a ; stop counting when it reaches ENTER
	jz 		scanCompleted
	inc 	esi
	jmp 	scanBuffer

scanCompleted:

	cmp 	byte[numberIn], '-'
	jz 		neg_sign
	; positive
	cmp 	esi, 10 ; (0-10): 10 possible digits, plus ENTER
	ja 		sayError	

neg_sign:

	; negative
	cmp 	esi, 11 ; (0-11): '-', 10 possible digits, plus ENTER
	ja 		sayError

; ---------------------------------------------

	; paser (check if it is a valid number)
	sub 	eax, eax ; set counter to zero
	mov 	esi, numberIn ; assigning the label starting address

nextByte:
	cmp 	eax, 1 ; counter equals to 1?
	jz 		notHyphen ; if so, the byte is not a hyphen
	cmp 	byte[numberIn], '-' ; is a hyphen?
	jnz 	notHyphen ; if no, go to notHyphen
	inc 	eax ; increment counter
	inc 	esi ; incremente label address (point to the ascii)
	cmp 	byte[numberIn], '-' ; redoing it, because inc reset flags 
	jz 		nextByte

notHyphen:

	cmp 	byte[esi], 0x0a ; is ENTER?
	jz 		validNo ; if so, exit loop (it's a valid number)
	; is it a number in the range 0-9
	cmp 	byte[esi], '0' 
	jb 		sayError
	cmp 	byte[esi], '9'
	ja 		sayError 
	inc 	esi ; increment label address
	jmp 	nextByte

sayError:

	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, error
	mov 	edx, error_size
	int 	80h

	jmp 	tryAgain

validNo:


;-------------------------------------------------------------------------------------------------


	; ----> ASCII INTO INTEGER <----

    sub 	esi, esi ; assign zero to the source index
    sub 	eax, eax ; assign zero to the value accumulator

next_char:

	; char extraction
	movzx 	ebx, byte [numberIn+esi] ; extract char from the input buffer
	inc 	esi ; increment souce index
	cmp 	ebx, '-' ; negative signed?
	jz 		next_char ; if so, skip turn
	cmp 	ebx, 0x0a ; compare if the current char is carriage return
	jz 		next ; if so, exit loop

	; subtraction
	sub 	ebx, 0x30 ; transform ascii into integer

	; product
	mov 	ecx, 10 ; factor 2 = 10 ( factor 1 = eax )
	mul 	ecx	; product  = factor 1 x factor 2

	; product + subtraction
	add 	eax, ebx ; passing this char to eax
	
	jne 	next_char ; compute next char

next: 

	; multiply by -1 if there's a negative sign in the buffer
	cmp 	byte [numberIn], '-' ; 
	jnz 	positive
	neg 	eax

positive:


;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------
	

	push 	eax


	; **********************************************
	; * PRODUCT HAS TO BE BETWEEN −2,147,483,648   *
	; * AND 2,147,483,647 						   *
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


; --------------------------------------------------------------------------------------------------------
 

tryAgain2:

	; scan 
	mov 	eax, 3
	mov 	ebx, 0 
	mov 	ecx, factor
	mov 	edx, 24	; ten possible digits to be inserted plus '-' and ENTER. throws error, if bigger.
	int 	80h

; ---------------------------------------------

	;  000 000 000 0 0		\
	;						 } 	numero = 0
	;  000 000 000 0 ENTER	/
	;  000 000 000 1 ENTER --> 9 zeros, [buffer+9] = 1 e [buffer+10] = ENTER
	; -000 000 000 1 ENTER --> '-', 9 zeros, [buffer+10] = 1 e [buffer+10] = ENTER	

	; take all the leading zeros off
	mov 	esi, factor ; pass the buffer starting address into esi
	sub 	edi, edi ;  zero-counter
	sub 	edx, edx ; a flag that says whether number is negative or not

	; check if it's negative
	cmp 	byte[esi], '-' ; is negative?
	jz 		isNegative2
	jmp 	nextLeadingZ2

isNegative2:
	
	mov 	dl, 1 ; a flag that says whether number is negative or not (TRUE --> negative)
	inc 	esi ; increment index 

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

	mov 	bl, [factor+edi] ; moves first character non-zero into bl
	cmp 	bl, 0x0a ; is ENTER?
	jz 		finished2 ; if so, finish building new buffer
	; if number is negative 
	cmp 	dl, 1 ; if flag is TRUE (points out number is negative)
	jz 		putHyphen2 ; then put hyphen at the beginning of the buffer
	jmp 	dontPutHyphen2 ; if no, dont

putHyphen2:
	
	mov  	byte[factor+esi], '-' ; put hyphen at the beginning of the buffer
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	sub 	edx, edx ; set sign flag to FALSE (not negative)
	jmp 	newBuffer2 ; build new buffer's next byte

dontPutHyphen2:

	mov 	byte[factor+esi], bl ; put the non-zero into the new buffer byte
	inc 	esi ; increment the new buffer index
	inc 	edi ; increment the old buffer index
	jmp 	newBuffer2 ; build new buffer's next byte

finished2:
	
	cmp 	esi, 0 ; if the new buffer's index was not incremented, then the number is zero 
	jz 		NoIsZero2
	; if the new buffer's index was incremented one or more times...
	mov 	byte[factor+esi], 0x0a ; now we're good, inserting this ENTER in the new 
	jmp 	nextSetp2				 ; buffer last index position
	

NoIsZero2:

	; if the number is zero
	mov 	byte[factor], '0' ; insert ascii '0'
	mov 	byte[factor+1], 0x0a ; insert ENTER

nextSetp2:

; ---------------------------------------------

	sub 	esi, esi ; set index to zero

scanBuffer2:

	; find out how many chars ('-' and/or digits) there are in the buffer
	cmp 	byte[factor+esi], 0x0a ; stop counting when it reaches ENTER
	jz 		scanCompleted2
	inc 	esi
	jmp 	scanBuffer2

scanCompleted2:

	cmp 	byte[factor], '-'
	jz 		neg_sign2
	; positive
	cmp 	esi, 10 ; (0-10): 10 possible digits, plus ENTER
	ja 		sayError2	

neg_sign2:

	; negative
	cmp 	esi, 11 ; (0-11): '-', 10 possible digits, plus ENTER
	ja 		sayError2

; ---------------------------------------------

	; paser (check if it is a valid number)
	sub 	eax, eax ; set counter to zero
	mov 	esi, factor ; assigning the label starting address

nextByte2:
	cmp 	eax, 1 ; counter equals to 1?
	jz 		notHyphen2 ; if so, the byte is not a hyphen
	cmp 	byte[factor], '-' ; is a hyphen?
	jnz 	notHyphen2 ; if no, go to notHyphen
	inc 	eax ; increment counter
	inc 	esi ; incremente label address (point to the ascii)
	cmp 	byte[factor], '-' ; redoing it, because inc reset flags 
	jz 		nextByte2

notHyphen2:

	cmp 	byte[esi], 0x0a ; is ENTER?
	jz 		validNo2 ; if so, exit loop (it's a valid number)
	; is it a number in the range 0-9
	cmp 	byte[esi], '0' 
	jb 		sayError2
	cmp 	byte[esi], '9'
	ja 		sayError2 
	inc 	esi ; increment label address
	jmp 	nextByte2

sayError2:

	; print message
	mov 	eax, 4
	mov 	ebx, 1
	mov 	ecx, error
	mov 	edx, error_size
	int 	80h

	jmp 	tryAgain2

validNo2:


;-------------------------------------------------------------------------------------------------


	; ----> ASCII INTO INTEGER <----

    sub 	esi, esi ; assign zero to the source index
    sub 	eax, eax ; assign zero to the value accumulator

next_char2:

	; char extraction
	movzx 	ebx, byte [factor+esi] ; extract char from the input buffer
	inc 	esi ; increment souce index
	cmp 	ebx, '-' ; negative signed?
	jz 		next_char2 ; if so, skip turn
	cmp 	ebx, 0x0a ; compare if the current char is carriage return
	jz 		next2 ; if so, exit loop

	; subtraction
	sub 	ebx, 0x30 ; transform ascii into integer

	; product
	mov 	ecx, 10 ; factor 2 = 10 ( factor 1 = eax )
	mul 	ecx	; product  = factor 1 x factor 2

	; product + subtraction
	add 	eax, ebx ; passing this char to eax
	
	jne 	next_char2 ; compute next char

next2: 

	; multiply by -1 if there's a negative sign in the buffer
	cmp 	byte [factor], '-' ; 
	jnz 	positive2
	neg 	eax

positive2:

	mov 	ecx, eax ; factor 2 ( factor 1 = eax)
	pop 	eax
	imul 	ecx ; product = factor 1 x factor 2


;-------------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------------


	; ----> INTEGER INTO ASCII <----

    sub 	esi, esi ; assign zero to the source index

    add 	eax, 0 ; set flags regarding to eax
    jge 	AnotNegative ; skip next two lines if the number is positive
    mov 	byte [numberOut], '-' ; put negative sign at the first position of the output buffer
    neg 	eax ; turn it into positive 

AnotNegative:

	cmp 	edx, 0xffffffff ; if sign is negative...
	jnz 	DnotNegative ; skip the next line if the number is positive
	mov 	byte [numberOut], '-' ; put negative sign at the first position of the output buffer
	
DnotNegative:

next_dig:

	sub 	edx, edx ; make sure edx is zero for division to occur properly
	mov 	ecx, 10 ; set up divisor
	idiv 	ecx ; (edx:eax / 10)	edx = mod / eax = quotient

	add 	edx, 0x30 ; get ascii value out of the mod digit
	inc 	esi ; increment source index

	push 	edx ; pile ascii

	or 		eax, eax ; check if input number was reduced to zero ( if so, set flag ZF )
	jz 		exit ; if so, exit loop

  	jnz	 next_dig ; if no, discover next digit

exit:

	mov 	byte [numberOut+esi], 0x0a; put ENTER at the end

	sub 	edi, edi ; set destination inex to zero
	
	;if output number is negative, increment destination index	
	cmp 	byte [numberOut], '-' ; 
    jnz 	Index0
    inc 	edi	

Index0:

	mov 	ecx, esi ; take advantage of the source index to count it down

unpiling:

	; put ascii's into output buffer to genearte the right number
	pop 	edx
	and 	edx, 0xff
	mov 	byte[numberOut+edi], dl 
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
	mov 	edx, 24 ; ten possible digits of a dword to be inserted plus '-' and ENTER
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