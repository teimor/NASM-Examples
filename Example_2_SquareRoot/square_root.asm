; For compile, link and run use:
; nasm -f elf64 q1.asm -o q1.o && gcc -no-pie -m64 q1.o -o q1 -lm && ./q1

;
; Constant for Linux 64-bit operating system
;

SYS_EXIT	equ	60			; System call code for exit the program

;
; Macro Region
; Using Assembly macros for less repeatable code and more organized program

; Printf with 1 arg, for text
%macro print 1				; %1 - name of the text to print
	mov		rdi, %1			; set format for printf
	mov		rax,0			; no xmm registers
	call	printf			; Call C function
	mov	rax,0				; normal, no error, return value
%endmacro

; Printf with 1 arg, for text
%macro print_mm 1				; %1 - name of the text to print
	mov		rdi, %1			; set format for printf
	mov		rax,1			; set one xmm registers
	call	printf			; Call C function
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
section .data
    MSG_START:        db "Start calculation of sqrt(x^2+y^2+z^2)", 10, 0
	MSG_RESULT:     db "sqrt(x^2+y^2+z^2) = %0.10lf", 10, 0
	MSG_END:        db "The answer to life the universe and everything.", 10, 0
	
	; temporary values just for development and example propose
	x_num:  dq 39.80982     ; 1st temporary value to enter the stack
	y_num: dq 11.34871     ; 2nd temporary value to enter the stack
	z_num:  dq 7.103896	    ; 3rd temporary value to enter the stack
	
section .text
	; external function declaration, using standard library functions.
	extern printf
	extern sqrt
	; set main
    global main
main:
	push rbp                    ; set up stack frame
    mov rbp, rsp                ; to avoid an error inside local call
    
    ; Enter the temporary values to stack (just for development and example propose)
	push qword [x_num]			; push first value to stack
	push qword [y_num]			; push second value to stack
	push qword [z_num]			; push third value to stack
	
	call stack_sqrt				; call the function
    
	pop rbp                     ; restore stack
	exit                        ; using exit macro to exit without errors

	; the function for the quiz
stack_sqrt:
			print MSG_START				; start message
			; Get the values from stack
			pop		rbp					; set up stack frame
			pop		r11                 ; pop third value from stack (z)
			pop		r12                 ; pop second value from stack (y)
			pop		r13                 ; pop first value from stack (x)

			; Save the vales to memory
			movq	xmm0, r13           ; save first value to memory (x)
			movq	xmm1, r12           ; save second value to memory (y)
			movq	xmm2, r11           ; save third value to memory (z)
			; Power every value by multiply it by itself
			mulsd	xmm0, xmm0          ; x * x -> xmm0
			mulsd	xmm1, xmm1          ; y * y -> xmm1
			mulsd	xmm2, xmm2          ; z * z -> xmm2
			; Add all values to the first memory before using sqrt function
			addsd 	xmm0,xmm1           ; x^2 + y^2
			addsd 	xmm0,xmm2           ; x^2 + y^2 + z^2
			call	sqrt                ; call to sqrt function, the answer saved to xmm0

			print_mm MSG_RESULT         ; using print macro with memory so takes the xmm0 value
			print MSG_END               ; using print macro to print end message
			pop rbp						; restore stack
			ret							; return