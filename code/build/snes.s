

@ Code section
.section .text

.global initSNES
initSNES:
	push	{lr}

	@ Initialize GPIO base address
	ldr	r0, =GpioPtr
	bl	initGpioPtr

	@ Set SNES Clock line (pin 11) to output
	mov	r0, #11
	mov	r1, #1
	bl	Init_GPIO

	@ Set SNES Latch line (pin 9) to output
	mov	r0, #9
	mov	r1, #1
	bl	Init_GPIO

	@ Set SNES Data line (pin 10) to input
	mov	r0, #10
	mov	r1, #0
	bl	Init_GPIO

	pop	{pc}

@ Reads buttons from the SNES controller and returns the
@ number of any pressed button (1-12). Returns 0 if 
@ no buttons were pressed.
.global getInput
getInput:
	push	{r4, lr}

	bl	Read_SNES

	@ If no buttons were pressed (r0 = 0xFFFF), return 0
	ldr	r1, =0xFFFF
	cmp	r0, r1
	moveq	r0, #0

	pop	{r4, pc}

@ Initializes a GPIO line with a function.
@ r0 - line number
@ r1 - function code
Init_GPIO:
	push	{r4, r5, r6}

	lineNum	.req	r4	@ Number of pin to be initialized
	code	.req	r5	@ Function code
	copy	.req	r6	@ Copy of the pin's GPFSEL register

	@ Save line number and function code
	mov	lineNum, r0
	mov	code, r1

	@ Load GPIO base address to r0
	ldr	r0, =GpioPtr
	ldr	r0, [r0]

	@ Determine address of Function Select Register
	mov	r1, #10
	udiv	r3, lineNum, r1		@ r3 = lineNum/10

	@ Make copy of Function Select Register and update address
	ldr	copy, [r0, r3, lsl #2]!
	
	@ Clear bits corresponding to line
	mul	r3, r1           		@ r3 = lineNum/10 * 10
	sub	lineNum, r3			@ Get least significant bit of lineNum
	add	lineNum, lineNum, lsl #1	@ lineNum *= 3

	mov	r2, #7
	bic	copy, r2, lsl lineNum

	@ Set line bits to function
	orr	copy, code, lsl lineNum

	@ Write back to Function Select Register
	str	copy, [r0]

	@ Unname registers
	.unreq	lineNum
	.unreq	code
	.unreq	copy
	
	pop	{r4, r5, r6}
	bx	lr

@ Writes a bit to the SNES clock line (pin 11)
Write_Clock:

	@ Initialize Gpio base address
	ldr	r1, =GpioPtr
	ldr	r1, [r1]
	
	@ Position pin to write to
	mov	r2,#1
	lsl	r2, #11

	@ Determine whether to clear or set bit
	teq	r0, #0
	streq	r2, [r1, #40]
	strne	r2, [r1, #28]

	mov	pc, lr

@ Writes a bit to the SNES latch line (pin 9)
Write_Latch:
	@ Initialize Gpio base address
	ldr	r1, =GpioPtr
	ldr	r1, [r1]
	
	@ Position pin to write to
	mov	r2,#1
	lsl	r2, #9

	@ Determine whether to clear or set bit
	teq	r0, #0
	streq	r2, [r1, #40]
	strne	r2, [r1, #28]

	mov	pc, lr

@ Reads a bit from the SNES data line (pin 10)
@ Returns the value of the bit read.
Read_Data:

	@ Initialize Gpio base address
	ldr	r1, =GpioPtr
	ldr	r1, [r1]

	ldr	r2, [r1, #52]  // Load from GPLEV0
	mov	r3, #1
	lsl	r3, #10		// Align pin 10's bit

	and	r2, r3		// Mask all other bits
	teq	r2, #0		// Check if bit is 0 or 1

	@ Return result
	moveq	r0, #0
	movne	r0, #1
	
	mov	pc, lr

@ Reads buttons pressed from a SNES controller. Returns
@ sequence of pressed buttons in r0.
Read_SNES:
	push	{r4, r5, lr}

	@ Initialize buttons register to 0
	buttons	.req	r4
	mov	buttons, #0

	@ Write 1 to the clock and latch lines
	mov	r0, #1
	bl	Write_Clock
	mov	r0, #1
	bl	Write_Latch

	@ Signal SNES to sample buttons
	mov	r0, #12
	bl	delayMicroseconds

	@ Write 0 to the latch line
	mov	r0, #0
	bl	Write_Latch

	@ Initialize loop counter
	count	.req	r5
	mov	count, #0

pulseLoop:
	
	@ Wait 6 microseconds
	mov	r0, #6
	bl	delayMicroseconds

	@ Write 0 to clock line
	mov	r0, #0
	bl	Write_Clock

	@ Wait 6 microseconds
	mov	r0, #6
	bl	delayMicroseconds

	bl	Read_Data	// Read current iteration's bit

	lsl	r0, count	// Position result to correct bit
	orr	buttons, r0	// Record result to buttons

	mov	r0, #1		// Rising edge
	bl	Write_Clock

	add	count, #1	// Check next button
	cmp	count, #16	// Loop 16 times
	blt	pulseLoop

	mov	r0, buttons	// Return buttons
	.unreq	buttons
	.unreq	count

	pop	{r4, r5, pc}


@ Waits for a pressed button to be released on the SNES controller
@ r0 - number code of the button pressed
Release_Button:
	
	push	{r4, lr}
	mov	r4, r0		// Store pressed button to r4

top:
	@ Check if pressed button has been released (bit is 1)
	bl	Read_SNES
	mov	r3, #1		// Set r3 to 1 and shift to button's position
	lsl	r3, r4
	ands	r0, r3		// Mask all bits except button of interest
	
test:
	beq	top		// Loop while button is still pressed

	mov	r0, #30000		// Slight delay before next reading attempt
	bl	delayMicroseconds

	pop	{r4, pc}


@ Data section
.section .data

.align

.global GpioPtr
GpioPtr:
	.int	0	@ GPIO base address




