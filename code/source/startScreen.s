.section .text

.global drawMenu // draws the main menu image
drawMenu:
	push {lr}

	ldr r0, =mainMenuScreenImg
	bl drawImage

	ldr r0, =selectorImgOnPlay //draws a selection arrow on play by default
	bl	drawImage
	
	pop {pc}



.globl menuSelection
menuSelection:
	selection	.req	r4	//current menu item highlighted
	selectAdrs	.req	r5	// menu item value (0 for quit, 1 for play)
	push	{r4-r5, lr}
	
	ldr		selectAdrs, =mainMenuSelected //load 0 or 1
	ldr		selection, [selectAdrs]	//put into register
	cmp		selection, #0	// check if play is selected
	beq		quitGameSelect // if it is, then the only select option is to go to quit
	

startGameSelect: // drawing arrow on play game
	ldr r0, =deleteSelectorImgOnQuit
	bl drawImage
	ldr r0, =selectorImgOnPlay
	bl drawImage
	
	ldr		selectAdrs, =mainMenuSelected //load 0 or 1
	ldr		selection, [selectAdrs]	//put into register
	mov		r0,	#0
	str		r0, [selectAdrs]	// store the selection
	b		doneSelect		// this will quit the game				
	
quitGameSelect: // this is when we select quit game
	ldr r0, =deleteSelectorImgOnPlay 
	bl drawImage
	ldr r0, =selectorImgOnQuit 
	bl drawImage
	
	ldr		selectAdrs, =mainMenuSelected //load 0 or 1
	ldr		selection, [selectAdrs]	//put into register
	mov		r0,	#1
	str		r0, [selectAdrs]	// store the selection
	
doneSelect:	// when selection is done, pass 0 or 1 back 

	.unreq	selection
	.unreq	selectAdrs
	pop		{r4-r5, pc}



.section .data
.global mainMenuSelected 
mainMenuSelected:
	.int		0