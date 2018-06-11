.section .text
@ Code section
.section .text

export

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
brickWidth = 40
brickHeight = 20
brickSize = 24			@ Size of an individual brick in memory
brickSpacing = 15		@ Distance (in pixels) between bricks

brickStartX = leftBound + 12
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
