@ Code section
.section .text

brickSize = 24			@ Size of an individual brick in memory

@ Score and lives x coordinates
onesDigX = 750
tensDigX = onesDigX - 40
livesX = 1025

@ Draws the main menu on the screen.
.global drawMenu 
drawMenu:
	push {lr}
	ldr r0, =mainMenuScreenImg //draws main menu screen
	bl drawImage
	ldr r0, =selectorImgOnPlay //draws a selection arrow on play by default
	bl	drawImage
	pop {pc}

@ Draws the quit screen.
.global drawQuitScreen
drawQuitScreen:
	ldr	r0,=quitScreen
	bl drawImage
	b	haltLoop$

@ Draws the game over screen.
.global drawGameOver
drawGameOver:
	push {r7}

	@ Draw the game over screen
	ldr r0, =gameOverScreen
	bl drawImage

	bl getInput		@ Wait for user input
	mov r7, #0		
	cmp	r0, r7
	beq	drawGameOver	@ If no input was received, stay on screen

	mov	r0, #60000	@ Wait after checking for next input
	bl delayMicroseconds

	mov	r0, #60000
	bl delayMicroseconds
	
	b restart			@ Return to restart if the user presses a button

@ Draws the win screen.
.global drawWin
drawWin:
	push {r7}

	@ Draw the win screen
	ldr r0, =winGameScreen
	bl drawImage

	bl getInput		@ Wait for user input
	mov r7, #0		
	cmp	r0, r7
	beq	drawWin		@ If no input was received, stay on screen

	mov	r0, #60000	@ Wait after checking for next input
	bl delayMicroseconds

	mov	r0, #60000
	bl delayMicroseconds
	
	b restart			@ Return to restart if the user presses a button


@ Draws the current number of lives onto the screen.
.global drawLives
drawLives:
	push	{lr}
	numberLives .req  r1
	
	ldr	r0, =lives
	ldr	numberLives, [r0]	@ Load current # of lives
	ldr	r0, =digArray		@ r0 = base address of digit images array
	ldr	r0, [r0, numberLives, lsl #2]	@ r0 = address of correct digit image

	@ Set x coordinate where lives should display
	mov	r2, #livesX
	str	r2, [r0]

	bl	drawImage	@ Draw lives

	pop	{pc}


@ Draws the current score onto the screen.
.global drawScore
drawScore:
	push	{r4, r5, r6, lr}
	curScore 	.req	r4	@ Name current score register
	scoreOverTen	.req	r6

	@ Load current score
	ldr	r0, =score
	ldr	curScore, [r0]
	asr	curScore, #1		@ Draw internal score divided by 2
	
	@ Check the tens digit of the score
	mov	r1, #10
	udiv	scoreOverTen, curScore, r1	@ r6 = score/10

	@ Load address of image for digit
	ldr	r5, =digArray		@ r5 = base address of digit images array
	ldr	r0, [r5, scoreOverTen, lsl #2]	@ r0 = address of correct image

	@ Set x coordinate for digit
	mov	r2, #tensDigX
	str	r2, [r0]

	@ Draw tens digit
	bl	drawImage

	@ Check the ones digit of the score
	mov	r1, #10
	mul	r1, scoreOverTen	@ r1 = score/10 * 10
	sub	curScore, r1
	ldr	r0, [r5, curScore, lsl #2]	@ r0 = address of ones digit image
	mov	r2, #onesDigX		@ r2 = x coordinate for ones digit
	str	r2, [r0]
	bl	drawImage		@ Draw ones digit

	pop	{r4, r5, r6, pc}

@ Loops through the brick array to draw all the bricks on screen.
.global drawBricks
drawBricks:
	push	{r4, r5, lr}
	@ Load base address for bricks
	ldr	r4, =bricks
	ldr	r5, =endBricks

drawtop:
	mov	r0, r4		@ Set r0 to the current brick address
	bl	drawRect		@ Draw the brick
	add	r4, #brickSize		@ Increment address to next brick

	@ Check if current address is past end of array
	cmp	r4, r5
	blt	drawtop		@ Loop while bricks still remain

	pop	{r4, r5, pc}


@ Draws a solid, coloured rectangle.
@ r0 - address of rectangular object to draw
.global drawRect
drawRect:
	push	{r4, r5, r6}
	offset	.req	r6

	ldr	r1, =frameBufferInfo
	ldr	r2, [r0]	@ r2 = x coordinate of object
	ldr	r3, [r0, #4]	@ r3 = y coordinate
	ldr	r4, [r1, #4]	@ r4 = screen width
	ldr	r5, [r0, #16]	@ r5 = object colour

	@ Calculate initial offset
	mul	r3, r4		@ r1 = y * width
	add	offset, r2, r3

	ldr	r1, [r1]	@ r1 = frame buffer pointer
	ldr	r2, [r0, #8]	@ r2 = width of object
	ldr	r3, [r0, #12]	@ r3 = height of object

	@ Outer loop runs <object height> times, drawing
	@ one horizontal line each time
top1:	
	@ Initialize counter for inner loop
	mov	r0, #0

top2:	@ Inner loop runs <object width> times, drawing 1
	
	@ pixel each time
	str	r5, [r1, offset, lsl #2]	@ Store color at physical offset
	add	offset, #1			@ Increment offset

	@ Loop while inner count is < object width
	add	r0, #1
	cmp	r0, r2
	blt	top2

	@ Move offset to next line by adding screen width - object width
	add	offset, r4
	sub	offset, r2

	@ Loop while outer count is not 0
	subs	r3, #1
	bne	top1

	pop	{r4, r5, r6}
	bx	lr


@ Draws an image using bitmap data.
@ r0 - address of image object
.global drawImage
drawImage:
	push	{r4, r5, r6, r7}
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
	add	r5, r0, #16	@ r5 = address of image data

	@ Outer loop runs <object height> times, drawing
	@ one horizontal line each time
top3:	
	@ Initialize counter for inner loop
	mov	r7, #0

top4:	@ Inner loop runs <object width> times, drawing 1
	@ pixel each time
	ldr	r0, [r5], #4			@ Load image data and update address
	str	r0, [r1, offset, lsl #2]	@ Store color at physical offset
	add	offset, #1			@ Increment offset

	@ Loop while inner count is < object width
	add	r7, #1
	cmp	r7, r2
	blt	top4

	@ Move offset to next line by adding screen width - object width
	add	offset, r4
	sub	offset, r2

	@ Loop while outer count is not 0
	subs	r3, #1
	bne	top3

	pop	{r4, r5, r6, r7}
	bx	lr



