TITLE String/Int Converter   (StringToInt.asm)

; Author: Amar Jilani
; Last Modified: 06-02-2022
; Description: Program with procedures that can convert an integer string into an integer value and vice versa. 
;			   Contains a test program that takes 10 numbers from the user, and displays the numbers, sum and truncated average. 

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts user for input and stores input string. 
;
; Preconditions: userInput must have length >= maxLength. 
;				 EAX, ECX and EDX should not be used as arguments. 
;
; Postconditions: Preserves, modifies and restores EAX, ECX and EDX. 
;
; Receives:
;			promptAddress	=	address of prompt string 
;			maxLength		=	maximum accepted input length 
;			userInput		=	address of where to store user input string 
;			inputLength		=	length of user input string
;
; Returns: userInput = user inputted string 
;		   inputLength = number of bytes read 
; ---------------------------------------------------------------------------------
mGetString	MACRO promptAddress:REQ, maxLength:REQ, userInput:REQ, inputLength:REQ 
	; preserve registers
	push	EDX
	push	ECX
	push	EAX

	; print prompt 
	mov		EDX, promptAddress
	call	WriteString
	; read user input 
	mov		ECX, maxLength
	mov		EDX, userInput
	call	ReadString 
	mov		inputLength, EAX		; store length of inputted string

	; restore registers 
	pop		EAX
	pop		ECX
	pop		EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays passed string to console. 
;
; Preconditions: None
;
; Postconditions: Modifies EDX. 
;
; Receives:
;			stringAddress: address of string to be printed 
;
; Returns: None
; ---------------------------------------------------------------------------------
mDisplayString	MACRO stringAddress:REQ
	; preserve registers
	push	EDX

	; print string
	mov		EDX, stringAddress
	call	WriteString

	; restore registers 
	pop		EDX
ENDM

MAX_LENGTH = 13		; 32-bit signed integer max length + 2 (so larger numbers aren't truncated and accidentally validated) 
ASCII_UPPER = 57	; ASCII for 9 
ASCII_LOWER = 48	; ASCII for 0 

.data

program_title		BYTE	"Project 6: Designing low-level I/O procedures",13,10
programmer_name		BYTE	"Written by: Amar Jilani",13,10,0 
instructions		BYTE	"Please provide 10 signed decimal integers.",13,10
					BYTE	"Each number needs to fit within a 32 bit register.",13,10
					BYTE	"This program will then display the list of numbers, their sum and their average.",13,10,0
prompt				BYTE	"Please enter a signed number: ",0 
user_input			BYTE	MAX_LENGTH DUP(0)
int_value			SDWORD	?	; output of ReadVal
invalid_num			BYTE	"ERROR: You did not enter a valid signed number or your number was too big.",13,10,0
arrayHeader			BYTE	"You entered the following numbers:",13,10,0
inputArray			SDWORD	10 DUP(?)
sumHeader			BYTE	"The sum of these numbers is: ",0
sum					SDWORD	0
avgHeader			BYTE	"The truncated average is: ",0
average				SDWORD	?
goodbye				BYTE    "Here are your results! Goodbye.",0


.code
main PROC
	
	; prints title and program description 
	push	OFFSET program_title
	push	OFFSET instructions
	call	introduction 

	; initilization for filling array of numbers 
	mov		EDI, OFFSET inputArray
	mov		ECX, LENGTHOF inputArray

_GetTenNumbers:
	; gets an integer from the user 
	push	OFFSET int_value
	push	OFFSET invalid_num
	push	OFFSET prompt
	push	OFFSET user_input
	call	ReadVal

	; store the input in the array 
	mov		EAX, int_value
	mov		[EDI], EAX					; store value in array 
	add		sum, EAX					; add each user input to sum 
	add		EDI, TYPE inputArray		; move to next index
	loop	_GetTenNumbers				; loop 10 times 

_CalculateAverage:
	; divide the sum by the length of the array to get the average 
	mov		EAX, sum
	mov		EBX, LENGTHOF inputArray
	cdq
	idiv	EBX
	mov		average, EAX				; only store truncated average 

	; initialize for array printing and print the array header 
	mov		ESI, OFFSET inputArray
	mov		ECX, LENGTHOF inputArray
	call	CrLf
	mDisplayString	OFFSET arrayHeader

_PrintArray:
	; prints all the values in an array, separated by commas and a space
	push	[ESI]
	call	WriteVal
	add		ESI, TYPE inputArray		; move to next element in array using Register Indirect 
	
	; prints comma and space between each number, unless its the last number 
	cmp		ECX, 1
	je		_endLoop
	mov		AL, 2Ch
	call	WriteChar
	mov		AL, 20h
	call	WriteChar

_endLoop:
	loop	_PrintArray

	call	CrLf
	call	CrLf

_PrintSum:
	; print header for sum and sum value 
	mDisplayString	OFFSET sumHeader

	; prints sum 
	push	sum
	call	WriteVal

	call	CrLf
	call	CrLf

_PrintAverage:
	; print header for average and average value 
	mDisplayString	OFFSET avgHeader

	; prints average
	push	average
	call	WriteVal

	call	CrLf
	call	CrLf
	
_Farewell:
	push	OFFSET goodbye
	call	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP
; ---------------------------------------------------------------------------------
; Name: introduction
;
; Procedures that prints out the program title and program description.
;
; Preconditions: All received parameters are byte strings. 
;
; Postconditions: Introductory messages passed parameters displayed to console.
;				  EDX is preserved, modified and restored. 
;
; Receives: 
;			Parameters should be pushed in order to be printed. 
;			[EBP + 12]  = reference to string for program title and author 
;			[EBP + 8]   = reference to string for program description 
;
; Returns: None
; ---------------------------------------------------------------------------------
introduction	PROC
	push	EBP
	mov		EBP, ESP
	push	EDX

	mDisplayString	[EBP+12]

	call	CrLf

	mDisplayString	[EBP + 8]

	call	CrLf

	pop		EDX
	pop		EBP
	ret		8
introduction	ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Uses a macro to ask the user to input a 32-bit signed integer, receives string representation 
; and then converts the string into the actual 32-bit signed integer value, stores in variable.
;
; Preconditions: Output parameter must be type SDWORD. 
;				 Reference to macro output (byte string) must have length 13. 
;
; Postconditions: EAX, EBX, ECX, EDX, ESI, EDI preserved, modified and restored. 
;
; Receives: 
;			[EBP + 20]  = reference to integer output variable 
;			[EBP + 16]	= reference to string for invalid input 
;			[EBP + 12]  = reference to string for prompt 
;			[EBP + 8]	= reference for macro output (string representation of integer) 
;			Constants: ASCII_LOWER, ASCII_UPPER, MAX_LENGTH 
;
; Returns: Inputted number stored as 32-bit signed integer in variable passed at 
;		   [EBP + 20]. String representation stored in [EBP + 8]. 
; ---------------------------------------------------------------------------------
ReadVal			PROC	
	
	; local variable current is used to hold the currently calculated integer temporarily when calculating, sign keeps track of positive/negative value
	; stringLength keeps track of length of user input 
	LOCAL	current:SDWORD, sign:SDWORD, stringLength:DWORD

	pushad							; preserve registers

	; initialize values of sign and temp 
	mov		sign, 1
	mov		current, 0

_GetNum:
	; call macro to get integer from user and store in string referenced at [EBP + 8]
	mGetString	[EBP + 12], MAX_LENGTH, [EBP + 8], stringLength
	
	; make sure length is not greater than 11 (largest possible length for a signed number) 
	cmp		stringLength, 11
	jg		_Invalid

	; use length of string (stored in EAX) as counter for loop 
	mov		ECX, stringLength
	mov		ESI, [EBP + 8]			; stores reference to integer string in ESI 

_Parse:
	xor		EAX, EAX				; clear EAX register so previous values don't affect calculations 
	LODSB							; loads leftmost digit of integer string
	cmp		AL, ASCII_UPPER			; ensures that ASCII value within range of digits 
	jg		_Invalid
	cmp		AL, ASCII_LOWER			; if lower, check if its a sign 
	jl		_SignCheck
	jmp		_Calculate
	
_Calculate:
	; calculate the integer value from its string representation 
	sub		EAX, ASCII_LOWER		; gets the actual digit
	mov		EBX, sign
	imul	EBX						; multiplies by sign to keep it positive/negative 
	push	EAX
	mov		EAX, current				
	mov		EBX, 10
	imul	EBX						; multiplies previous value by 10 
	jo		_InvalidStackBalance	; if overflow flag raised, the number was too big, need to balance the earlier push EAX 
	pop		EBX
	add		EAX, EBX				; add previous value * 10 and new digit 
	jo		_Invalid				; number too big 
	mov		current, EAX				
	xor		EAX, EAX
	xor		EDX, EDX				; clear registers 
	loop	_Parse
	jmp		_End

_SignCheck:
	mov		EDI, [EBP + 8]		
	inc		EDI						; this should be address of ESI after loading the FIRST character
	cmp		ESI, EDI				; check if we are comparing the first character, otherwise it would be invalid  
	jne		_Invalid				; if its not, then it can't be a valid sign, as signs are at the front  
	cmp		AL, 43					; check if its a plus 
	je		_PlusSign
	cmp		AL, 45					; check if its a minus 
	je		_MinusSign
	jmp		_Invalid				; otherwise error 

_PlusSign:
	; if the number is positive, sign should be 1 
	mov		sign, 1
	loop	_Parse

_MinusSign:
	; if the number is negative, set the sign local var to -1 
	mov		sign, -1
	loop	_Parse

_Invalid:
	; if the user input is invalid, either non-digit, too big or too small, print error message and ask for input again 
	mDisplayString [EBP + 16]
	mov		current, 0
	jmp		_GetNum

_InvalidStackBalance:
	; specific case for when overflow flag detected before the stack is balanced, then we need to pop top of the stack 
	mDisplayString [EBP + 16]
	pop		EAX
	mov		current, 0
	jmp		_GetNum

_End:
	; store resulting integer value in output parameter 
	mov		EDX, [EBP + 20]
	mov		EAX, current
	mov		[EDX], EAX

	popad							; restore registers 
	ret		16
	
ReadVal			ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Takes a 32-bit signed integer and converts it to its string equivalent, and then
; prints it to the console using a macro. 
;
; Preconditions: Parameter passed as input must be 32-bit signed integer.
;
; Postconditions: Integer passed as input displayed on console. 
;				  EAX, EBX, EDX, EDI preserved, modified and restored. 
;
; Receives: 
;			[EBP + 8]	= integer value to be displayed
;			Constants: ASCII_LOWER
;
; Returns: None 
; ---------------------------------------------------------------------------------
WriteVal		PROC

	LOCAL	current:SDWORD, sign:SDWORD, intString[12]:BYTE		; length is 12 to account for null terminator 
	
	; preserve registers 
	push	EAX
	push	EDI
	push	EBX
	push	EDX

	; initializes the sign as 1 (positive) 
	mov		sign, 1
	
	; gets the int value that is to be converted and store in EAX 
	mov		EAX, [EBP + 8]
	cmp		EAX, 0			
	jns		_Start				; if the value is negative, set local var sign to -1 
	mov		sign, -1 

_Start:
	; stores the int value in a local variable current, moves the temporary string address into EDI 
	mov		current, EAX
	mov		EDI, EBP
	sub		EDI, 12				; gets address of end of string local variable 
	mov		AL, 0				
	STD							; since its the end of the string, we must move backwards to fill out the string 
	STOSB						; start by storing the null terminator at the end 

_GetDigit:
	; divides the number by 10, the remainder would be the right-most digit
	mov		EAX, current
	mov		EBX, 10
	cdq	
	idiv	EBX
	mov		current, EAX
	mov		EAX,  EDX
	imul	sign				; multiply the remainder by sign value to convert it to a positive number for accurate ASCII conversion 
	jmp		_CalculateAscii

_CalculateAscii:
	; converts the digit into its ASCII equivalent, and stores it in the string 
	add		EAX, ASCII_LOWER
	STOSB						; stores each digit (starting from the rightmost) in string 
								
	cmp		current, 0			; if the current quotient = 0, then every digit has been loaded
	jne		_GetDigit

	; if number was negative, load a minus sign at the front first
	cmp		sign, -1
	jne		_Display
	mov		AL, 45				; ASCII value for minus sign 
	STOSB						

_Display:
	; uses macro to display string 
	add		EDI, 1				; since EDI is now pointing at one BYTE before the string, we must move it back to the start of the string 
	mDisplayString EDI			
	
	; restore registers 
	pop		EDX
	pop		EBX
	pop		EDI
	pop		EAX

	ret		4
WriteVal		ENDP
; ---------------------------------------------------------------------------------
; Name: farewell
;
; Prints farewell message.
;
; Receives: 
;			[EBP + 8]   =  reference to message 
; ---------------------------------------------------------------------------------
farewell		PROC
	; set base pointer and store registers 
	push	EBP
	mov		EBP, ESP
	push	EDX

	; retrieve reference to farewell string and print 
	mDisplayString	[EBP + 8]
	
	; restore registers 
	pop		EDX
	pop		EBP

	ret		4
farewell		ENDP
END main
