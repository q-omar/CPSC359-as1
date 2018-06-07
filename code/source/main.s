

@ Code section
.section .text

@ Brick parameters
bPerRow = 10			@ # of bricks per row
numRows = 3			@ Number of rows of bricks
brickWidth = 30
brickHeight = 10
brickSize = 24			@ Size of an individual brick in memory
brickSpacing = 20		@ Distance (in pixels) between bricks

@ Game board boundaries
leftBound = 520
rightBound = 1080
topBound = 120

@ Window parameters
windowX = 500
windowY = 100
windowWidth = 600
windowHeight = 800

.global main
main:
	@ Initialize frame buffer
	ldr	r0, =frameBufferInfo
	bl	initFbInfo

	@ Initialize SNES controller
	bl	initSNES

	@ Draws a black screen for the background
	ldr	r0, =window
	bl	drawRect

	bl	initBricks
	bl	drawBricks

looptop:
	@ Draw paddle
	ldr	r0, =paddle
	bl	drawImage

	@ Check for user input
	bl	getInput
	cmp	r0, #0
	blne	processInput

	b	looptop

	haltLoop$:
		b	haltLoop$

@ Loops through the brick array to draw all the bricks on screen.
drawBricks:
	push	{r4, r5, lr}

	@ Load base address for bricks
	ldr	r4, =bricks
	ldr	r5, =endBricks

drawtop:
	mov	r0, r4
	bl	drawRect
	add	r4, #brickSize
	
	@ Check if current address is past end of array
	cmp	r4, r5
	blt	drawtop

	pop	{r4, r5, pc}

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
	mov	xcoord, #leftBound
	add	xcoord, #brickSpacing		@ Adjust to change distance around edges
	mov	ycoord, #topBound
	add	ycoord, #brickSpacing

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

	add	ycoord, height	@ Increment y coordinate to new row
	mov	xcoord, #leftBound
	add	xcoord, #20

	subs	r2, #1		@ Loop for each row of bricks
	bne	outer1

	pop	{r4, r5, r6, r7}
	mov	pc, lr

@ Receives pressed button from SNES controller and updates the game state appropriately.
@ r0 - number of the button pressed
processInput:
	push	{lr}

	@ If user presses right (7) or left (8) on joypad, move paddle accordingly
	cmp	r0, #7
	bleq	movePaddle
	cmp	r0, #8
	bleq	movePaddle

	pop	{pc}

@ Moves paddle left or right based on the joypad button pressed
@ * Update later to support holding down A to speed up
@ r0 - number of button pressed (7 for left, 8 for right)
movePaddle:
	push	{r4, r5, r6, r7, lr}

	mov	r4, r0		@ r4 = button pressed
	ldr	r0, =paddle	@ r0 = base address of paddle
	ldr	r5, [r0]	@ r5 = original x-coordinate of paddle

	bl	clearObj	@ Clear paddle from original location

	ldr	r0, =paddle	@ r0 = base address of paddle

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
	addne	r5, #1
	strne	r5, [r0]
	bl	drawImage	@ Redraw the moved paddle
	b	end1

leftmov:
	@ Check if new coordinate is out of bounds on left
	mov	r6, #leftBound
	cmp	r5, r6	
	subne	r5, #1		@ If not out of bounds, move left
	strne	r5, [r0]	@ Store new x-coordinate
	bl	drawImage	@ Redraw the moved paddle
end1:
	pop	{r4, r5, r6, r7, pc}
	

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


@ Draws a solid, coloured rectangle.
@ r0 - address of rectangular object to draw
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
	add	r5, r0, #20	@ r5 = address of image data

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

@ Data section
.section .data

.align
.global frameBufferInfo
frameBufferInfo:
	.int	0		@ frame buffer pointer
	.int	0		@ screen width
	.int	0		@ screen height

@ window object
@ ** Would be better to center based on screen width and height later
window:
	.int	500		@ x coordinate
	.int	100		@ y coordinate
	.int	600		@ width
	.int	800		@ height
	.int	0		@ Color (black)

@ not done yet
ball:
	.int	800		@ x coordinate
	.int	680		@ y coordinate
	.int	20		@ width
	.int	20		@ height


paddle:
	.int	700		@ x coordinate
	.int	700		@ y coordinate
	.int	16		@ width
	.int	16		@ height
	.int	10		@ speed			** Currently not used
	@ image data
.ascii "\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\0008\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\0008\230\374\3778\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\377\377\377\377\000\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\0008\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "\000(\330\377\000(\330\377\000(\330\377\000(\330\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\0008\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\377\000(\330\377\000(\330\377"
.ascii "\000(\330\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\0008\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "8\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\377\000(\330\3778\230\374\3778\230\374\377\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\0008\230\374\3778\230\374\377\000(\330\377\000(\330\377\000(\330\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "8\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377\377\377\377\000\377\377\377\0008\230\374\377\000(\330\377\000(\330\377"
.ascii "\000(\330\377\000(\330\377\000(\330\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "8\230\374\377\377\377\377\0008\230\374\3778\230\374\377\000(\330\377\000(\330\377\000(\330\377\000(\330\377\000(\330\3778\230\374\377"
.ascii "8\230\374\3778\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "\000(\330\377\000(\330\377\000(\330\377\000(\330\377\000(\330\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "\000(\330\377\000(\330\377\000(\330\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\377\000(\330\377"
.ascii "8\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377\000(\330\377\000(\330\3778\230\374\377"
.ascii "8\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377"
.ascii "8\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\3778\230\374\377\377\377\377\0008\230\374\377\000(\330\377\000(\330\377"
.ascii "\000(\330\377\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\000(\330\377\000(\330\377\000(\330\377"
.ascii "8\230\374\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377"
.ascii "\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\000\377\377\377\000\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\3778\230\374\377\374\374\374\377"
.ascii "\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\374\374\374\377\374\374\374\377"
.ascii "\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\3778\230\374\377\374\374\374\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000"
.ascii "\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\374\374\374\377\374\374\374\377\374\374\374\377\374\374\374\3778\230\374\377"
.ascii "\374\374\374\377\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000\377\377\377\000"


@ Array of bricks
bricks:	.rept	10		
	.int	0		@ x coordinate
	.int	0		@ y coordinate
	.int	brickWidth	@ width
	.int	brickHeight	@ height
	.int	0xFF5733	@ Color (red)
	.int	3		@ Health
	.endr

	.rept	10	
	.int	0		@ x coordinate
	.int	0		@ y coordinate
	.int	brickWidth	@ width
	.int	brickHeight	@ height
	.int	0x3EF2F7	@ Color (blue)
	.int	2		@ Health
	.endr

	.rept	10		
	.int	0		@ x coordinate
	.int	0		@ y coordinate
	.int	brickWidth	@ width
	.int	brickHeight	@ height
	.int	0x87F36D	@ Color (green)
	.int	1		@ Health
	.endr
endBricks:













	
