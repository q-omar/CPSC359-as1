.section .text
.global menuControl

menuControl:
	push	{lr}
	
menuControllerInput:	
	
    mov	r0, #9999		//control sensitivity
	bl	delayMicroseconds

	bl	getInput		// read SNES input
	mov r1, #0
	teq	r0, r1			//no buttons pressed

	beq	menuControllerInput	// read controller again 
	
    ldr	r1, =0xFEFF		
	teq	r0, r1			// a press
	beq	buttonEventA
	
    ldr	r1, =0xFFEF		
	teq	r0, r1			//up or down keep looping the menu selection
	beq	mainMenuChangeSelection

	ldr	r1, =0xFFDF		
	teq	r0, r1			// down
	beq	mainMenuChangeSelection

	b	menuControllerInput	// loop again if multiple buttons being pressed
		

buttonEventA:
	ldr		r0, =mainMenuSelected	//mainmenuselected is whats currently at main menu
	ldr		r1, [r0]		
	cmp		r1, #0					
	bne		mainMenuQuitGame		// quit game if 0

mainMenuStartGame:
	mov		r0, #0				
	b		mainMenuDone

mainMenuQuitGame:	
	    mov    r4, #0           //init counter to 0


mainMenuChangeSelection:
	bl		menuSelection
	b		mainMenuLetGo
		
mainMenuLetGo:
	mov	r0, #9999		
	bl	delayMicroseconds 

	bl	getInput	// read from the controller
	mov r1, #0
	teq	r0, r1			// compare value when no buttons pressed to what we got from controller
	bne	mainMenuLetGo	// until no buttons pressed loop back up
	b	menuControllerInput // after no buttons are pressed check for next button


mainMenuDone:	
	pop		{pc}
