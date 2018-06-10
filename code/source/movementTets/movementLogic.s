    //checkLeftXBoundary
    //checkRightXBoundary
    //checkPaddleYHit
    //checkTileYHit


    //if ball hits left boundary, it may travel down right or up right
    //if ball hits right boundary, it may travel down left or up left

    //moveLeftUp
    //moveRightUp
    //moveLeftDown
    //moveRightDown

leftBound = 520
rightBound = 1080
topBound = 120
lowerBound = 900


ballAnimation:

	push {r4-r9, lr}
	ballBase    .req r0
    ballXPos    .req r4
    ballYPos    .req r5

    bl moveRightUp
    bl checkRightBound
 
	@	check for right bound
	ldr	r0, =ball	@ r0 = base address of ball	
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of ball
	ldr	r5, [r0]
	add	r7, r7, r5	@ r7 = x coordinate of right end of ball
	cmp	r7, r6
	blt	launchBall
end2:
	pop {r5, r6, r7, pc}launchBall:

	push {r5, r6, r7, lr}
	
	ldr	r0, =ball	@ r0 = base address of ball
	bl clearObj
	
	ldr	r0, =ball	@ r0 = base address of ball	
	
	@ Increment y- coordinate whenever B is pressed
	ldr	r6, [r0, #4]	@ load y- coordinate of the ball
	sub	r6, #1
	str	r6, [r0, #4]
	
	@ Check if the paddle is already at the right boundary	
	ldr	r5, [r0]
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of ball
	add	r7, r7, r5	@ r7 = x coordinate of right end of ball

	@ If the balls's right end is not at the boundary, move right
	cmp	r7, r6		
	addlt	r5, #1
	str	r5, [r0]
	bllt	drawImage	@ Redraw the moved ball

	mov	r0, #10000		// Slight delay while progressing the ball
	bl	delayMicroseconds
	
	@	check for right bound
	ldr	r0, =ball	@ r0 = base address of ball	
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of ball
	ldr	r5, [r0]
	add	r7, r7, r5	@ r7 = x coordinate of right end of ball
	cmp	r7, r6
	blt	launchBall
end2:
	pop {r5, r6, r7, pc}




.global ballMoveUpRight

ballMoveUpRight:
    push {r4-r9, lr}

    ldr ballBase, =ball
	@ Increment y- coordinate whenever B is pressed
	ldr	ballYPos, [ballBase, #4]	@ load y- coordinate of the ball
	sub	ballYPos, #1
	str	ballYPos, [ballBase, #4]
	
	@ Check if the paddle is already at the right boundary	
	ldr	r5, [ballBase]
	mov	r6, #rightBound
	ldr	r7, [r0, #8]	@ r7 = width of ball
	add	r7, r7, r5	@ r7 = x coordinate of right end of ball

	@ If the balls's right end is not at the boundary, move right
	cmp	r7, r6		
	addlt	r5, #1
	str	r5, [r0]
	bllt	drawImage	@ Redraw the moved ball

    mov	r0, #10000		// Slight delay while progressing the ball
	bl	delayMicroseconds

    pop {r4-r9, lr}


.global checkRightBound

checkRightBound:
    