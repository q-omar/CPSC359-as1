.section .text
.global menuControl

menuControl:
	push	{lr}
	
menuControlLoop:	
	mov r0, #9999
	bl	delayMicroseconds
	bl	getInput		@read SNES input
	mov r1, #0
	teq	r0, r1			@no buttons pressed

	beq	menuControlLoop	@read controller again 
	
    ldr	r1, =0xFEFF		
	teq	r0, r1			@ A press
	beq	buttonEventA
	
    ldr	r1, =0xFFEF		
	teq	r0, r1			@up or down keep looping the menu selection
	beq	selectionChanged

	ldr	r1, =0xFFDF		
	teq	r0, r1		
	beq	selectionChanged

	b	menuControlLoop	@ loop again if multiple buttons being pressed
		

buttonEventA:

	ldr		r0, =mainMenuSelected	@mainmenuselected is whats currently at main menu
	ldr		r1, [r0]		
	cmp		r1, #0					
	bne		mainMenuQuitGame		@quit game if 0


mainMenuStartGame:
	mov		r0, #0				
	b		menuComplete


mainMenuQuitGame:		
	b	drawQuitScreen


selectionChanged:
	bl		menuSelection
	b		menuConfirm
		

menuConfirm:
	mov	r0, #9999
	bl delayMicroseconds
	bl	getInput	@ read from the controller
	mov r1, #0
	teq	r0, r1			@compare value when no buttons pressed to what we got from controller
	bne	menuConfirm	// until no buttons pressed loop back up
	b	menuControlLoop @ after no buttons are pressed check for next button


menuComplete:	
	pop		{pc}


menuSelection:
	highlighted	.req	r4	@current menu item highlighted
	highlightBase	.req	r5	@ menu item value (0 for quit, 1 for play)
	push	{r4-r5, lr}
	
	ldr		highlightBase, =mainMenuSelected @load 0 or 1
	ldr		highlighted, [highlightBase]	@put into register
	cmp		highlighted, #0	@ check if play is selected
	beq		quitGameSelect @if it is, then the only select option is to go to quit
	

startGameSelect: @drawing arrow on play game
	ldr r0, =deleteSelectorImgOnQuit
	bl drawImage
	ldr r0, =selectorImgOnPlay
	bl drawImage
	
	ldr		highlightBase, =mainMenuSelected @load 0 or 1
	ldr		highlighted, [highlightBase]	@put into register
	mov		r0,	#0
	str		r0, [highlightBase]	@ store the highlighted value
	b		doneSelect		@ this will quit the game				
	

quitGameSelect: // this is when we select quit game
	ldr r0, =deleteSelectorImgOnPlay 
	bl drawImage
	ldr r0, =selectorImgOnQuit 
	bl drawImage
	
	ldr		highlightBase, =mainMenuSelected @load 0 or 1
	ldr		highlighted, [highlightBase] @put into register
	mov		r0,	#1
	str		r0, [highlightBase]	@ store the highlighrted value
	
	
doneSelect:	@when selection is done, pass 0 or 1 back 

	.unreq	highlighted
	.unreq	highlightBase
	pop		{r4-r5, pc}
