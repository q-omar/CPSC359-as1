

@ Code section
.section .text

@ Game board boundaries
leftBound = 520
rightBound = 1080
topBound = 120
lowerBound = 900

@ Window parameters
windowX = 500
windowY = 100
windowWidth = 600
windowHeight = 800

@ Brick parameters
bPerRow = 10			@ # of bricks per row
numRows = 3			@ Number of rows of bricks
brickWidth = 54
brickHeight = 30
brickSize = 24			@ Size of an individual brick in memory
brickSpacing = 2		@ Distance (in pixels) between bricks

brickStartX = leftBound
brickStartY = topBound + 60

@ Paddle starting parameters
padWidth = 100
padHeight = 30
padX = windowX + windowWidth/2 - padWidth/2
padY = lowerBound - 100

@ Ball starting parameters
ballWidth = 15
ballX = padX + padWidth/2 - ballWidth/2
ballY = padY - ballWidth

@ Score and lives x coordinates
onesDigX = 750
tensDigX = onesDigX - 40
livesX = 1025

numLives = 3

.global main
main:
	@ Initialize frame buffer
	ldr	r0, =frameBufferInfo
	bl	initFbInfo

	@ Initialize SNES controller
	bl	initSNES
	
menu:
	bl	drawMenu
	bl 	menuControl

	@ Initialize game
	bl	initGame

looptop:

	@ Check for user input
	bl	getInput
	cmp	r0, #0
	blne	processInput

	bl	moveBall
	
	mov	r0, #5000		// Change to adjust game speed
	bl	delayMicroseconds

	@ Check loss flag
	ldr	r0, =loss
	ldr	r0, [r0]
	cmp	r0, #1
	bleq	loseLife

	b	looptop

.global haltLoop$
	haltLoop$:
		b	haltLoop$

loseLife:
	push	{r4, lr}

	ldr	r0, =lives
	ldr	r4, [r0]
	sub	r4, #1		@ Subtract one life
	str	r4, [r0]

	ldr	r0, =loss	@ Reset loss flag
	mov	r1, #0
	str	r1, [r0]

	@ Reset ball and paddle to initial positions if
	@ the game is still continuing
	cmp	r4, #0	
	blne	resetPaddle

	cmp	r4, #0	
	blne	resetBall

	cmp	r4, #0	
	blne	drawLives

	cmp	r4, #0	
	bleq	initGame	@ Otherwise game over*	

	pop	{r4, pc}

resetPaddle:
	push	{lr}

	@ Clear paddle
	ldr	r0, =paddle
	bl	clearObj

	@ Center paddle in middle of window
	ldr	r0, =paddle
	mov	r1, #padX
	str	r1, [r0]	// Store X coordinate

	mov	r1, #padY
	str	r1, [r0, #4]	// Store Y coordinate

	bl	drawRect	// Draw paddle at initial coordinates

	pop	{pc}

resetBall:
	push	{lr}

	@ Clear ball
	ldr	r0, =ball
	bl	clearObj

	ldr	r0, =ball
	mov	r1, #ballX
	str	r1, [r0]	// Store X coord

	mov	r1, #ballY
	str	r1, [r0, #4]	// Store Y coordinate
	bl	drawImage

	@ Reset direction of ball
	ldr	r0, =ballDir
	mov	r1, #1
	str	r1, [r0]

	pop	{pc}

@ Sets the game to initial conditions (position of objects, # of lives, etc.)
initGame:
	push	{lr}

	@ Draws a black screen for the background
	ldr	r0, =background
	bl	drawImage

	@ Reset score to 0 and redraw
	ldr	r0, =score
	mov	r1, #0
	str	r1, [r0]
	bl	drawScore

	@ Restore all lives and redraw
	ldr	r0, =lives
	mov	r1, #numLives
	str	r1, [r0]
	bl	drawLives

	@ Initializes and draws bricks
	bl	initBricks
	bl	resetBricks
	bl	drawBricks

	@ Reset paddle to initial location
	bl	resetPaddle

	@ Reset ball to initial location
	bl	resetBall

	pop	{pc}
	

//----------------------------------------------------------------------------
//Returns the bit at a given index of a 16-bit integer
//Args:
//r0 - the number
//r1 - index of bit to get value of
//Return:
//r1 - the desired bit

.global      getBit
getBit:

    mov     r2, #1          // r2 = b(...00001)
    sub r1, #1
    mov     r2, r2, lsl r1  // left shift r2 by r1
    and     r1, r0, r2      // r1: AND r0 with r2 to select only desired bit
    bx      lr              // return

@ Receives pressed button from SNES controller and updates the game state appropriately.
@ r0 - number of the button pressedbleq
processInput:
	push	{r4, r5, lr}

	mov	r4, r0		// Save pressed buttons to r4

	@ Check if A is pressed
	mov		r0, r4
	mov		r1, #9
	bl		getBit

	cmp		r1, #0
	moveq	r5, #1		// Set speed flag if A is pressed
	movne	r5, #0

	@ Check if left joypad is pressed
	mov	r0, r4
	mov	r1, #7
	bl	getBit

	cmp		r1, #0
	moveq	r0, #7
	moveq	r1, r5
	bleq	movePaddle

	@ Check if right joypad is pressed
	mov		r0, r4
	mov		r1, #8
	bl		getBit

	cmp		r1, #0
	moveq	r0, #8
	moveq	r1, r5
	bleq	movePaddle

	@ Check if Start is pressed
	mov		r0, r4
	mov		r1, #4
	bl		getBit
	cmp		r1, #0		// If Start is pressed, reset game
	bleq	initGame

	@ Check if Select is pressed
	mov		r0, r4
	mov		r1, #3
	bl		getBit
	cmp		r1, #0		// If select is pressed, go back to main menu 
	beq		main

	@ Check if B is pressed
	mov		r0, r4
	mov 	r1, #1
	bl 		getBit

	cmp 	r1, #0
	bleq	checkLaunch
	
// Return to menu if so


	pop	{r4, r5, pc}

@ Moves paddle left or right based on the joypad button pressed
@ * Update later to support holding down A to speed up
@ r0 - number of button pressed (7 for left, 8 for right)
@ r1 - flag if A is pressed (1 if pressed, 0 if not)
movePaddle:
	push	{r4, r5, r6, r7, r8, lr}

	cmp	r1, #1		@ Check if A button was pressed
	moveq	r8, #4		@ If A was pressed, set speed higher
	movne	r8, #1

	mov	r4, r0		@ r4 = button pressed
	ldr	r0, =paddle	@ r0 = base address of paddle
	ldr	r5, [r0]	@ r5 = original x-coordinate of paddle

	bl	clearObj	@ Clear paddle from original location

	ldr	r0, =paddle	@ r0 = base address of paddle+

	@ Check if moving left (left pad pressed)
	cmp	r4, #7
	beq	leftmov

	@ Otherwise the paddle is moving right
	@ Check if the paddle is already at the right boundary	
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of paddle
	add	r7, r5		@ r7 = x coordinate of right end of paddle

	@ If the paddle's right end is not at the boundary, move right
	cmp	r7, r6		
	addlt	r5, r8
	strlt	r5, [r0]
	bl	drawRect	@ Redraw the moved paddle
	b	end1

leftmov:
	@ Check if new coordinate is out of bounds on left
	mov	r6, #leftBound
	cmp	r5, r6	
	subgt	r5, r8		@ If not out of bounds, move left
	strgt	r5, [r0]	@ Store new x-coordinate
	bl	drawRect	@ Redraw the moved paddle
	
end1:
	pop	{r4, r5, r6, r7, r8, pc}

checkLaunch:

	ldr		r0, =ball	@ r0 = base address of ball	
	mov 	r6, #ballX
	ldr		r5, [r0]
	cmp 	r5, r6
	bxne	lr

	mov 	r6, #ballY
	ldr		r5, [r0, #4]
	cmp 	r5, r6
	bxne	lr

bottomWall:

	push	{r5, r6, r7, lr}

	ldr	r0, =ball	@ r0 = base address of ball	

	@ Check if the paddle is at bottom bound	
	ldr	r5, [r0, #4]	@ r5 = y coordinate of ball
	mov	r6, #lowerBound
	ldr	r7, [r0, #12]	@ r7 = height of ball
	add	r7, r7, r5	@ r7 = y coordinate of bottom of ball

	@ Set loss flag if ball is past bottom boundary
	cmp	r7, r6
	ldrge	r0, =loss
	movge	r1, #1
	strge	r1, [r0]

	pop	{r5, r6, r7, pc}

rightWall:
	push	{r5, r6, r7, lr}

	ldr	r0, =ball	@ r0 = base address of ball	
	
	@ Check if the paddle is already at the right boundary	
	ldr	r5, [r0]
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of ball
	add	r7, r7, r5	@ r7 = x coordinate of right end of ball

	cmp	r7, r6
	blt	dirElse1

	ldr	r1, =ballDir
	ldr	r3, [r1]
	cmp	r3, #1
	moveq	r2, #4

	movne	r2, #3
	str	r2, [r1]

dirElse1:

	pop	{r5, r6, r7, pc}

leftWall:
	push	{r5, r6, r7, lr}

	ldr	r0, =ball	@ r0 = base address of ball	
	
	@ Check if the paddle is already at the left boundary	
	ldr	r5, [r0]		@ r5 = x coordinate
	mov	r6, #leftBound

	cmp	r5, r6

	bge	dirElse2

	ldr	r1, =ballDir
	ldr	r3, [r1]
	cmp	r3, #3
	moveq	r2, #2

	movne	r2, #1
	str	r2, [r1]

dirElse2:
	pop	{r5, r6, r7, pc}

topWall:
	push	{r5, r6, r7, lr}

	ldr	r0, =ball	@ r0 = base address of ball	
	
	@ Check if the paddle is already at the right boundary	
	ldr	r5, [r0, #4]	@ r5 = y coordinate of top of ball
	mov	r6, #topBound

	cmp	r5, r6

	bge	dirElse3

	ldr	r1, =ballDir
	ldr	r3, [r1]
	cmp	r3, #4
	moveq	r2, #3

	movne	r2, #2
	str	r2, [r1]

dirElse3:

	pop	{r5, r6, r7, pc}

moveBall:
	push {r5, r6, r7, r8, r9, lr}

	xSpeed	.req	r8
	ySpeed	.req	r9

	ldr	r5, =ballDir	@ Load direction of the ball
	ldr	r5, [r5]	

	@ Determine which direction to move the ball
	cmp	r5, #1
	moveq	xSpeed, #1
	moveq	ySpeed, #-1

	cmp	r5, #2
	moveq	xSpeed, #1
	moveq	ySpeed, #1

	cmp	r5, #3
	moveq	xSpeed, #-1
	moveq	ySpeed, #1

	cmp	r5, #4
	moveq	xSpeed, #-1
	moveq	ySpeed, #-1

	@ If the balls's right end is not at the boundary, move right
	ldr	r0, =ball	@ r0 = base address of ball
	bl	clearObj

	ldr	r0, =ball	@ r0 = base address of ball
	ldr	r5, [r0]
	add	r5, xSpeed
	str	r5, [r0]

	@ Increment y- coordinate whenever B is pressed
	ldr	r6, [r0, #4]	@ load y- coordinate of the ball
	add	r6, ySpeed
	str	r6, [r0, #4]

	ldr	r0, =ball
	bl	drawImage	@ Redraw the moved ball

	@ Check boundaries
	bl	rightWall
	bl	leftWall
	bl	topWall
	bl	bottomWall

//	mov	r0, #10000		// Slight delay while progressing the ball
//	bl	delayMicroseconds
	
//	@	check for right bound
//	ldr	r0, =ball	@ r0 = base address of ball	
//	mov	r6, #rightBound
//	ldr	r7, [r0, #8]	@ r7 = width of ball
//	ldr	r5, [r0]
//	add	r7, r7, r5	@ r7 = x coordinate of right end of ball
//	cmp	r7, r6
//	blt	launchBall
end2:
	pop {r5, r6, r7, r8, r9, pc}
	


@ Sets the health of all the bricks to full.
resetBricks:
	ldr	r0, =bricks
	mov	r1, #3		// Health counter
	mov	r2, #bPerRow	// Counter for # of bricks in a row

outer2:	@ Outer loop runs once for each row of breaks

inner2: @ Inner loop runs once for each brick in a row
	str	r1, [r0, #20]	// Store health for single brick
	add	r0, #brickSize	// Update r0 to address of next brick

	sub	r2, #1		// Loop for each brick in the row
	bne	inner2

	sub	r1, #1		// Decrease health of bricks in next row
	bne	outer2

	bx	lr




@ Sets the coordinates for all the bricks.
initBricks:
	push	{r4, r5, r6, r7}

	@ Load base address for bricks
	ldr	r0, =bricks

	@ Get # of bricks per row and # of rows
	mov	r1, #bPerRow
	mov	r2, #numRows

	xcoord	.req	r3
	ycoord	.req	r4

	@ Initialize x and y to top left part of screen
	mov	xcoord, #brickStartX
	mov	ycoord, #brickStartY
	width	.req	r6
	height	.req	r7

	mov	width, #brickWidth
	add	width, #brickSpacing

	mov	height, #brickHeight
	add	height, #brickSpacing		// Increase spacing between bricks

outer1:	@ Outer loop runs once for each row of bricks

	mov	r5, #0		@ Initialize inner counter to 0

inner1:	@ Inner loop runs once for every brick in a row

	@ Store coordinates to brick
	str	xcoord, [r0]
	str	ycoord, [r0, #4]

	@ Increment brick address and x coordinate
	add	r0, #brickSize			@ 24 bytes = size of each brick in memory		
	add	xcoord, width

	add	r5, #1
	cmp	r5, r1		@ Compare counter to # bricks per row
	blt	inner1

	add	ycoord, height		@ Increment y coordinate to new row
	mov	xcoord, #brickStartX

	subs	r2, #1		@ Loop for each row of bricks
	bne	outer1

	pop	{r4, r5, r6, r7}
	mov	pc, lr
	

@ Clears an object by drawing a black rectangle over it
@ r0 - address of the object to clear
clearObj:
	push	{r4, r5, r6}
	offset	.req	r6

	ldr	r1, =frameBufferInfo
	ldr	r2, [r0]	@ r2 = x coordinate of object
	ldr	r3, [r0, #4]	@ r3 = y coordinate
	ldr	r4, [r1, #4]	@ r4 = screen width

	@ Calculate initial offset
	mul	r3, r4		@ r1 = y * width
	add	offset, r2, r3

	ldr	r1, [r1]	@ r1 = frame buffer pointer
	ldr	r2, [r0, #8]	@ r2 = width of object
	ldr	r3, [r0, #12]	@ r3 = height of object
	mov	r5, #0		@ r5 = black color

	@ Outer loop runs <object height> times, drawing
	@ one horizontal line each time
top5:	
	@ Initialize counter for inner loop
	mov	r0, #0

top6:	@ Inner loop runs <object width> times, drawing 1
	@ pixel each time

	str	r5, [r1, offset, lsl #2]	@ Store color at physical offset
	add	offset, #1			@ Increment offset

	@ Loop while inner count is < object width
	add	r0, #1
	cmp	r0, r2
	blt	top6

	@ Move offset to next line by adding screen width - object width
	add	offset, r4
	sub	offset, r2

	@ Loop while outer count is not 0
	subs	r3, #1
	bne	top5

	pop	{r4, r5, r6}
	bx	lr
