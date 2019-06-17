;
; Constant for Linux 64-bit operating system
;
SYS_READ	equ	0			; System call code for system read
SYS_OPEN	equ	2			; System call code for opening file
SYS_CLOSE	equ	3			; System call code for closing file
SYS_EXIT	equ	60			; System call code for exit the program
;
; Uninitialized data
;
section .bss
	filename: resb 8		; reserved 8 bytes for filename
	buffer: resq 1			; reserved one 8-byte for char buffer
	numberbuffer: resq 64	; reserved array of 64 8-byte for number buffer
;
; Macro Region
; Using Asmbly macros for less repeatable code and more organized program

; Check Number Macro
%macro isNum 2				; %1 - value, %2 - function name
    cmp %1, '9'				; compare %1 with char '9'
    ja %2					; if above '9' then not number, got to %2
    cmp %1, '0'				; else, compare with char '1'
    jb %2					; if below '1', then not number, go to %2
%endmacro

; Counter Macro
%macro inc_cnt 1		; %1 - name of the counter to increase
	mov rax, %1			; point to counter
	mov rdi,[rax]		; get number
	inc rdi				; increase value
	mov [rax],rdi		; save
%endmacro

; Printf with 1 arg, for text
%macro print 1				; %1 - name of the text to print
	push    rbp				; set up stack frame
	mov		rdi, %1			; set format for printf
	mov		rax,0			; no xmm registers
	call	printf			; Call C function
	pop	rbp					; restore stack
	mov	rax,0				; normal, no error, return value
%endmacro

; Printf with 2 args
%macro printf_two 2			; %1 - text format name, %2 - parameter name
	push    rbp				; set up stack frame
	mov		rdi, %1			; set format for printf
	mov		rsi, %2			; first parameter for printf
	mov		rax,0			; no xmm registers
	call	printf			; Call C function
	pop	rbp					; restore stack
	mov	rax,0				; normal, no error, return value
%endmacro

; Exit Macro
%macro exit 0				; no arguments
	mov rax, SYS_EXIT		; set call for system exit
	mov rdi, 0				; no error
	syscall					; system call exit without error
%endmacro
;
; Initialized data memory
;
SECTION .data
	; All information messages and error :
	NEWLINE:			db 10, 0
	MSG_OPENFILE:		db "Reading file : ", 0
	MSG_FILENUMBERS:	db "File Numbers : ", 0
	MSG_ERROR_NO_ARG:	db "*** Please enter filename ***",0
	MSG_ERROR_NOFILE:	db "*** File not exists ***",0
	MSG_SUMMARY_HEADER:	db "-----------------", 10, 0
	MSG_SUMMARY_TITLE:	db "-----Summary-----", 10, 0
	MSG_FNDINT:			db "Integer was Found: %llu", 10, 0
	MSG_FNDFLT:			db "Float was Found: %0.10lf", 10, 0
	MSG_NUMSCNT:		db "Total Numbers Found: %ld", 10, 0
	MSG_INTCNT:			db "Integer Counter: %ld", 10, 0
	MSG_FLOATCNT:		db "Float Counter: %ld", 10, 0
	
	fd: dq 0				; file descriptor 
	nums_cnt: dq 0			; numbers counter
	int_cnt: dq 0			; integer counter
	float_cnt: dq 0			; float counter
	float_flag: db 0		; float flag

section .text
	; external function declaration, using standard library functions.
	extern	printf
	extern	atoll
	extern  atof
	; set main
	global  main

main: 
;   Get filename from command line arguments
	mov rax, [rsi+8]			; Get the argument 
	mov	rdx,0					; set rdx for check
	cmp	rdx,rax					; Check if argument exists
	je	error_no_arg			; If not exists go error
    mov [filename], rax			; else, save it to filename
    print MSG_OPENFILE			; print message with that program
    print [filename]			; is opening file name
    print NEWLINE				; using print macro for newline
;
;   Open the file & start reading it.
;
    ; Open File
	mov rax, SYS_OPEN			; set rax value for system open
	mov rdi, [filename]			; set rdi with filename
	mov rsi, SYS_READ			; set rsi for system read permission
	mov rdx, 0					; set rdx to zero
	syscall						; system call for opening file
    ; Check if file exists
	mov	rdx,0					; mov zero to rdx for compare
	cmp	rdx,rax					; compare rdx to rax
	jle	readfile				; if rax > 0(rdx), read file
    jmp error_no_file			; else, error - file not found

readfile:   mov [fd], rax				; set file descriptor
            mov rdi, rax				; mov to rdi 
            print MSG_FILENUMBERS		; using print macro for file number title
    		print NEWLINE				; using print macro for newline 
    		
read_loop: ; If exists - start reading the file 
			call read_char
			
			; Reset all counters, buffers and flags
			xor r12, r12					; char counter set to zero
			xor r13, r13					; tmp value set to zero
			mov dword [numberbuffer], 0		; number buffer set empty
			mov byte [float_flag], 0		; float number flag set to zero

            isNum byte [buffer], read_loop	; check if char buffer is number
            
num_loop:   mov r13, [buffer]				; move before save
            mov [numberbuffer+r12], r13		; save char number into number buffer
            inc r12							; increase counter
        	call read_char					; read next char
		    
		    cmp byte [float_flag], 1		; check for float flag
	        je	read_n						; if float flag is true, '.' will end the number
	        
	        cmp byte [buffer], '.'			; when float flag is false, check if float
            je fnd_float					; float found
read_n:		isNum byte [buffer], print_cnum	; if not '.', check if number, if not number go to print_num due that number ended
            jmp num_loop					; if number, check next char

fnd_float:	mov byte [float_flag], 1		; set float flag true
			jmp num_loop					; save the '.' and go check next char

print_cnum:	call print_num					; call print number
			jmp read_loop					; jump back to read loop
; Print number, check if float or int, then convert it to float/int and print it.			
print_num:	inc_cnt nums_cnt				; inc numbers counter
			cmp byte [float_flag], 1		; check float flag
			je print_flt					; if float flag is 1 (true), go print float
			call conv_int					; else, print int, call convert function from char array to int
			inc_cnt int_cnt					; increase integer counter
			ret								; return
print_flt:	call conv_flt					; call convert function from char array to float
			inc_cnt float_cnt				; increase float counter
			ret								;return
			
; Read one char
read_char:	mov rax, SYS_READ				; set RAX with system read value
			mov rdi, [fd]					; move file descriptor to rdi
			mov rsi, buffer 				; set buffer
			mov rdx, 1						; rdx - reading length (read one char)
			syscall							; system call for reading one char to buffer
			
			cmp rax, 0						; Check if EOF  
		    je check_last					; if true, go to check if last number in buffer
			ret								; return
;
;	Convert number and print out report
;
conv_int:	mov rdi, numberbuffer			; move number buffer(char array) to rdi
			call atoll						; call atoll function(input in rdi)
			mov r10, rax					; result in rax, save result to r10
			printf_two MSG_FNDINT, r10		; print the result
			ret								; return

conv_flt:	mov rdi, numberbuffer			; move number buffer(char array) to rdi
			call atof						; call atof, result is rsi & xmm0
			push rbp						; set up stack frame
			mov     rax, 1					; use input from the first memory (xmm0)
		    mov     rdi, MSG_FNDFLT			; first parameter for printf(format)
		    call    printf					; call printf
		    pop rbp							; restore stack
			ret								; return
;
; EOF handling
;
check_last:	cmp r12, 0						; check for last number
			je	eof							; no last number, go eof
			pop rbp							; if there is last number, restore stack
			call print_num					; if their is number, print it
eof:    	mov rax, SYS_CLOSE				; set rax for close file
        	pop rdi							; pop rdi from stack frame
        	syscall							; call close file

			; Print summary title	    
			print_summary:	    print NEWLINE							; using print macro for newline
	    	print MSG_SUMMARY_HEADER				; using print macro for summary header
	    	print MSG_SUMMARY_TITLE					; using print macro for summary title
			print MSG_SUMMARY_HEADER				; using print macro for summary header
			print NEWLINE							; using print macro for newline
			printf_two MSG_NUMSCNT, [nums_cnt]		; using print_two macro for total numbers count
			printf_two MSG_INTCNT, [int_cnt]		; using print_two macro for integer numbers count
			printf_two MSG_FLOATCNT, [float_cnt]	; using print_two macro for float numbers count
        	exit
;
; Error handling
;
; Error : When no argument or too many arguments
error_no_arg:	print MSG_ERROR_NO_ARG			; using print macro for no argument error
        		print NEWLINE					; using print macro for newline
        		exit
; Error : File not exists
error_no_file:	print MSG_ERROR_NOFILE			; using print macro for file not found error
                print NEWLINE					; using print macro for newline
                exit