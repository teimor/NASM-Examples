;
; Constant for Linux 64-bit operating system
;

SYS_EXIT	equ	60			; System call code for exit the program

;
; Macro Region
; Using Assembly macros for less repeatable code and more organized program

; Counter Macro
%macro inc_cnt 1		; %1 - name of the counter to increase
	xor rax, rax
	xor rdi, rdi
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
%macro print_two 2			; %1 - text format name, %2 - parameter name
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
; Uninitialized data
;
section .bss
	MEMORY_LOC :		resq 1		; Pointer for memory calloc
	SUM_1_ARRAY :		resq 64		; Sum array for every thread
	SUM_2_ARRAY :		resq 64		; Sum^2 array for every thread
	THREAD_ID_ARRAY :	resq 64		; Array of opened threads id
	NUMBERBUFFER :		resq 64		; general number buffer

;
; Initialized data memory
;
SECTION .data
	; All information messages and error :
	NEWLINE:                db 10, 0
    MSG_ERROR_MEMORY:       db "Could not allocate memory", 10, 0
    MSG_ERROR_PTHREAD:      db "Thread creation error :  %d", 10, 0
    MSG_ALERT_NO_ARG:       db "No Arguments, defaults values set", 10, 0
    MSG_ALERT_NO_LINES:		db "No Lines arg, default values set", 10, 0	
    MSG_NUMBER_THREADS:     db "Number of threads : %d",10 , 0
    MSG_NUMBER_LINES:       db "Number of Lines : %d",10 , 0
    MSG_RANDOM_CONST:       db "Random Seed Value : %f",10 , 0
    MSG_RANDOM_TIME:    	db "Random Seed Value set for time.",10 , 0
	MSG_SUMMARY_TITLE:		db "-----Summary-----", 10, 0
	MSG_SUMMARY_HEADER:     db "-----------------", 10, 0
	MSG_SUMMARY_AVG:		db "Average : %lf",10 , 0
	MSG_SUMMARY_DEV:		db "Deviation : %lf",10 , 0
	
	N_THREADS:			dq 4				; number of threads, default value
	SIZE_ARRAY:			dq 100000			; size of array, default value
	THREAD_DUTY: 		dq 0				; thread duty, number of memory for every thread
	RAND_SEED:			dq 0				; random function seed, if 0 - time else const
	
	THREAD_CNT: dq 0						; counter for create thread & thread join

	SUM_1: dq 0								; Sum of all values
	SUM_2: dq 0								; Sum^2 of all values
	
	MEMORY_POINTER: dq 0					; General memory pointer
	
	MAX_VAL:	dq 0x7fffffff				; Max value for getting random number between 0 to 1

section .text
	; external function declaration, using standard library functions.
	extern	printf
	extern	rand
	extern	srand
	extern	time
	extern	calloc
	extern	free
	extern	sqrt
	extern	pthread_create
	extern	pthread_join
	extern	atoll
	extern  atof
	; set main
	global  main

;
;	Main function
;
main:	push	rbp						; set up stack frame
		mov		rbp, rsp				; balance the stack

		mov 	r13, [rsi+8]			; get the 1st command line argument
		mov 	r14, [rsi+16]			; get the 2nd command line argument 
		mov 	r15, [rsi+24]			; get the 3rd command line argument 
			
		call set_values					; call function to set N_THREAD, ARRAY_SIZE & RAND_SEED
		call set_thread_duty			; call function to calc the THREAD_DUTY

		call memory_alloc				; calloc memory
		call create_thread				; create threads
		call join_thread				; join thread & calculate all sums & sums^2
		call memory_free				; free memory
		
		print MSG_SUMMARY_HEADER		; print summary header (using macro)
		print MSG_SUMMARY_TITLE			; print summary title (using macro)
		print MSG_SUMMARY_HEADER		; print summary header (using macro)
		
		call get_avg					; get average value and print
		call get_dev					; get deviation value and print

		pop rbp							; clear stack
		exit							; exit macro
		
;
;	Thread function
;	Getting the thread memeory index in RDI and then running of the allocated memeory
;
memory_fill:
				push	rbp						; set up stack frame
				mov		rbp, rsp				; balance the stack
				
				mov		r15, rdi				; set first index in counter
				mov		rax, [THREAD_DUTY]		; get duty of every thread
				add		rax, rdi				; add both value to calculate the end index to rax
				mov		r14, rdi				; save back the start index to r14
				
				cmp 	rdi, 0					; check if this is the first thread
				je first_thread					; handle the first thread
				
				; Calc the thread index
				mov 	rdx, 0						; move zero to rdx for compare
				mov 	rax, r14					; get the end index of thread
				mov 	r12, [THREAD_DUTY]			; get thread duty
				div 	r12							; divide and get the value in rax 
				jmp other_threads

first_thread:	mov		rax, 0						; set rax as zero
				jmp other_threads

other_threads:
				mov		r13, rax					; save thread index in r13
				
				; save pointer to r12 of this thread sum 
				mov 	r10, 8						; size of value(double size)
				mul 	r10							; mul index by size
				mov 	r10, rax					; save answer
				mov 	rax, SUM_1_ARRAY			; move sum_1_array
				add 	rax, r10					; add the location(index)
				mov 	r12, rax					; the total location to r12
				
				; save pointer to r12 of this thread sum^2 
				mov 	rax, r13					; mov thread index to rax
				mov 	r10, 8						; size of value(double size)
				mul 	r10							; mul by index size
				mov 	r10, rax					; save answer
				mov 	rax, SUM_2_ARRAY			; move sum_2_array
				add 	rax, r10					; add the location(index)
				mov 	r13, rax					; the total location to r13
				
				; save end index to r14
				mov 	rax, r14					; thread start value
				mov 	rdi, [THREAD_DUTY]			; thread duty
				add 	rax, rdi					; add both and get the end index
				mov 	r14, rax					; save to r14

; fill loop						
memory_fill_lp: 
				; Get random number
				xor 	rax, rax					; set rax to zero
				call	rand						; call random
				
				; Calc number between 0 to 1
				CVTSI2SD	xmm0, rax				; convert int to float and save to memory(random value)
				CVTSI2SD	xmm1, [MAX_VAL]			; convert int to float and save to memory(max value)
				divsd		xmm0, xmm1				; divide between random to max and get number between 0 to 1

				; Save random number into allocated memory
				mov		rax, r15					; get the memory counter index
				mov		r10, 8						; size of value(double size)
				mul 	r10							; multiply
				mov 	r10, rax					; save answer
				mov 	rax, [MEMORY_LOC]			; mov memory pointer
				add 	rax, r10					; add the index for the location
				movlps	qword [rax], xmm0			; save value in the location
				
				; Calc the sum & sum^2
				movq	xmm1, xmm0					; save random value for sum
				movq	xmm2, xmm0					; save random value for sum^2
				
				movq	xmm1, [r12]					; get the sum current value
				addsd	xmm0, xmm1					; add to current value
				movq	[r12], xmm0					; save to sum
				
				pxor	xmm0, xmm0					; clear xmm0
				mulsd	xmm2, xmm2					; ^2
				movq	xmm0, [r13]					; get the sum^2 current value
				addsd	xmm0, xmm2					; add current value to sum^2
				movq	[r13], xmm0					; save to sum^2
				pxor	xmm0, xmm0					; clear xmm0
				
				; counter
				inc		r15							; increase counter				
				cmp 	r15, r14					; compare to last index for the thread
				jb memory_fill_lp					; if below, do continue
				
				pop rbp								; clear stack
				ret									; return


; Set THREAD_DUTY = SIZE_ARRAY/N_THREADS
set_thread_duty:
				mov 	rdx, 0					; set zero to rax
				mov 	rax, [SIZE_ARRAY]		; mov size of array to rax
				mov 	r10, [N_THREADS]		; mov number of threads to r10
				div 	r10						; div -> rax/r10 = size_array/n_thread
				mov 	[THREAD_DUTY], rax		; save answer to THREAD_DUTY
				ret								; return

; Set value of N_THREADS, SIZE_ARRAY, RAND_SEED 
set_values:
			push	rbp							; set up stack frame
			mov		rdx,0						; set rdx for check
			cmp		rdx,r13						; check if argument exists
			je	no_arg							; if not exist - no args
			
			mov		dword [NUMBERBUFFER], 0		; number buffer set empty
			mov 	[NUMBERBUFFER], r13			; save 1st arg to numbuffer
			call conv_int						; convert "string" to int
			mov 	[N_THREADS], rax			; save to N_THREADS
			
			cmp		r14, 0						; check if argument exists
			je	no_lines_arg					; if not - no line args
			
			mov		[NUMBERBUFFER], r14			; save 2nd arg to numbuffer
			call conv_int						; convert "string" to int
			mov		[SIZE_ARRAY], rax			; save to SIZE_ARRAY
			
			cmp		r15, 0						; check if argument exists
			je	print_start						; if not exists - no rand seed
			
			mov 	[NUMBERBUFFER], r15			; save 3rd arg to numbuffer
			call conv_flt						; convert "string" to float(saves to RAND_SEED)
			jmp print_start						; go to print string

; when no line args(size_array)
no_lines_arg:
				print MSG_ALERT_NO_LINES		; print alert to user
				jmp print_start					; go to print values and set default lines & rand_seed
				
; when no any args
no_arg:
				print MSG_ALERT_NO_ARG			; print alert to user

; print the set valuse
print_start:
				print_two MSG_NUMBER_THREADS, [N_THREADS]	; print number of threads, using macro
				print_two MSG_NUMBER_LINES, [SIZE_ARRAY]	; print number of lines, using macro
				
				; check RAND_SEED value
				mov 	rax, [RAND_SEED]					; mov RAND_SEED value to rax
				cmp 	rax, 0								; check if zero
				je ran_t									; when zero, set time
				
				call seed_random_const						; else, set const
				jmp exit_val								; exist from function
ran_t:	
				call seed_random_time						; set time in srand
exit_val:		
				pop rbp										; clear stack
				ret											; return

; calc the deviation
get_dev:
		push		rbp							; set up stack frame
		movlps		xmm0, [SUM_2]				; get sum^2 value to xmm0
		movlps		xmm3, [SUM_1]				; get sum value to xmm1
		CVTSI2SD	xmm1, [SIZE_ARRAY]			; convert size array to float
		divsd		xmm0, xmm1					; divide xmm0/xmm1 = sum^2/n
		mulsd		xmm3, xmm3					; sum*sum
		subsd		xmm0, xmm3					; sum^2/n - sum*sum
		call sqrt								; call sqrt
		
		mov 		rax, 1						; using 1 memory value
		mov			rdi, MSG_SUMMARY_DEV		; set message
		call printf								; call printf
		pop 		rbp							; clear stack
		ret										; return

; calc the average		
get_avg:
		push		rbp							; set up stack frame
		movlps		xmm0, [SUM_1]				; set sum
		CVTSI2SD	xmm1, [SIZE_ARRAY]			; set array size
		divsd		xmm0, xmm1					; divide xmm0/xmm1 = sum/n
		movlps		[SUM_1], xmm0				; save answer to SUM_1
		mov 		rax, 1						; using 1 memory, xmm0
		mov 		rdi, MSG_SUMMARY_AVG		; set print format
		call printf								; call printf
		pop 		rbp							; clear stack
		ret										; return

; free memory
memory_free:
			mov		rdi, [MEMORY_LOC]			; set memory pointer location
			call free							; call free
			ret									; return

; allocated memory
memory_alloc:	
				xor 	rax, rax				; clear rax
				mov 	rdi, [SIZE_ARRAY]		; set rdi with array size
				mov 	rsi, 8					; set size of every value in array
				call calloc						; call calloc
				
				cmp 	rax, 0					; check for error
				je error_memory					; if 0, memory alloc error
				
				mov 	[MEMORY_LOC], rax		; else, save return memory pointer
				ret								; return

; Join threads
join_thread:
				push	rbp						; set up stack frame
				xor		rax, rax				; clear rax
				mov 	[THREAD_CNT], rax		; clear counter
join_thread_lp:
				
				mov 	rax, [THREAD_CNT]		; get current counter value
				mov 	r10, 8					; size of value(double size)
				mul 	r10						; multiple counter by size
				mov 	r10, rax				; save answer
				mov 	rax, THREAD_ID_ARRAY	; get thread id array location
				add 	rax, r10				; add index to pointer location
				
				xor 	rsi, rsi				; clear rsi
				mov 	rdi, [rax]				; set rdi with current index thread id
				call pthread_join				; call pthread_join
				
				mov 	rax, [THREAD_CNT]		; save current counter index to rax
				mov 	r10, 8					; size of value(double size)
				mul 	r10						; multiple counter by size
				mov 	r10, rax				; save answer
				mov 	rax, SUM_1_ARRAY		; get sum_1_array location
				add 	rax, r10				; add index to location
				mov 	r13, rax				; save the location to r13
				
				movlps	xmm0, [r13]				; mov value to xmm0
				movlps	xmm1, [SUM_1]			; mov current sum1 to xmm1
				addsd	xmm0, xmm1				; add both values and save to xmm0
				movq	[SUM_1], xmm0			; save to sum1
				pxor	xmm0, xmm0				; clear xmm0
				
				mov 	rax, [THREAD_CNT]		; save current counter index to rax
				mov 	r10, 8					; size of value(double size)
				mul 	r10						; multiple counter by size
				mov 	r10, rax				; save answer
				mov 	rax, SUM_2_ARRAY		; get sum_2_array location
				add 	rax, r10				; add index to location
				mov 	r13, rax				; save the location to r13
				
				movlps	xmm0, [r13]				; mov value to xmm0
				movlps	xmm1, [SUM_2]			; mov current sum2 to xmm1
				addsd	xmm0, xmm1				; add both values and save to xmm0
				movq	[SUM_2], xmm0			; save to sum2 (sum^2)
				pxor	xmm0, xmm0				; clear xmm0
				
				inc_cnt THREAD_CNT				; increase counter (using macro)
				mov 	r10, [THREAD_CNT]		; mov to r10 for compare
				cmp 	r10, [N_THREADS]		; mov number of threads for compare
				jne join_thread_lp				; if equal return, else continue
				pop		rbp						; clear stack
				ret								; return


; Create threads
create_thread:
				push	rbp								; set up stack frame
				xor		rax, rax						; clear rax
				mov		[THREAD_CNT], rax				; clear counter

;thread creation loop
create_thread_lp:
					mov 	rax, [THREAD_DUTY]			; save thread duty to rax
					mov 	r10, [THREAD_CNT]			; save current counter index to r10
					mul 	r10 						; multiple and get start memory for this thread
					mov 	r11, rax					; save answer
					
					mov 	rax, [THREAD_CNT]			; save current counter index to rax
					mov 	r10, 8						; size of value(double size)
					mul 	r10							; multiple counter by size
					mov 	r10, rax					; save answer
					mov 	rax, THREAD_ID_ARRAY		; mov thread_id_array location
					add 	rax, r10					; add index to location 
					
					mov 	rdi, rax					; pass memory index for this thread
					xor 	rsi, rsi					; clear rsi
					mov 	rdx, memory_fill			; set function to run in thread
					mov 	rcx, r11					; set pointer to save thread_id in array
					call pthread_create					; call pthread_create
					
					cmp 	rax, 0						; check for error
					jne error_thread					; if value different from zero, thread creation error
					
					inc_cnt	THREAD_CNT					; increase counter (using macro)
					mov 	r10, [THREAD_CNT]			; mov to r10 for compare
					cmp 	r10, [N_THREADS]			; mov number of threads for compare
					jb create_thread_lp					; if equal return, else continue
					pop rbp								; clear stock
					ret									; return

;
;	Convert number and print out report
;
conv_int:	mov rdi, [NUMBERBUFFER]			; move number buffer(char array) to rdi
			call atoll						; call atoll function(input in rdi)
			ret								; return

conv_flt:	mov rdi, [NUMBERBUFFER]			; move number buffer(char array) to rdi
			call atof						; call atof, result is rsi & xmm0
			movlps [RAND_SEED], xmm0		; save value to RAND_SEED
			ret								; return

;
; Seed Random
;

; Seed random with const
seed_random_const:	
					push	rbp						; set up stack frame
					movlps	xmm0, [RAND_SEED]		; save RAND_SEED value to xmm0
					mov 	rax, 1					; set 1 memory, xmm0
					mov 	rdi, MSG_RANDOM_CONST	; set print format
					xor 	rsi, rsi				; clear rsi
					call	printf					; call printf
					pop 	rbp						; clear stack
					mov 	rdi, [RAND_SEED]		; mov RAND_SEED value to rdi for call
					call	srand					; call srand and seed the random function
					ret								; return

; Seed random with time, semi-ture-random
seed_random_time:	print MSG_RANDOM_TIME			; print alert to user (using macro)
					xor		rax, rax				; clear rax
					xor 	rdi, rdi				; clear rdi
					call time						; call time, return value in rax
					mov 	rdi, rax				; set in rdi
					call	srand					; call srand and seed the random function with time
					ret								; return

;
; Error handling
;
; Memory alloc error
error_memory:		mov		rdi, MSG_ERROR_MEMORY		; set format for printf
					mov		rax,0						; no xmm registers
					call	printf						; call printf
					mov		rax,0						; no xmm registers
					call	printf						; Call C function
					exit

; Thread creation error					
error_thread:		mov rsi, rax
					mov		rdi, MSG_ERROR_PTHREAD		; set format for printf
					mov		rax,0						; no xmm registers
					call	printf						; call printf
					mov		rax,0						; no xmm registers
					call	printf						; Call C function
					exit
				
				