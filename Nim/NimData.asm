; this file contains all the data and the variables for the game
Heart	db 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0
		db 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0
		db 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1
		db 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
		db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
		db 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0
		db 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0
		db 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0
		db 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0
		db 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0
		db 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0
		
cs_address dw 0

; Each 3 bytes in this array contain data about a level of the game.
; The first byte tells how many lines of balls will be in this level.
; The second byte is the minimum amount of balls which can be generated in each line.
; The third byte is the maximum amount of balls which can be generated in each line.
levels 	db 2, 7, 12	; level 1, 2 lines
		db 3, 3, 7	; level 2, 3 lines
		db 3, 5, 11	; level 3, 3 lines
		db 4, 6, 13	; level 4, 4 lines
		db 5, 7, 14	; level 5, 5 lines
		
intro	db "Welcome to the game Nim", 13, 10, 13, 10
		db "I'll show you several pearls which are grouped in horizontal rows.", 13, 10
		db "On your turn you may remove as many pearls as you like, from any SINGLE row.", 13, 10
		db "Your goal is to leave the last pearl for me to take.", 13, 10
		db "I'll do what must be done so it won't happen.", 13, 10, 13, 10
		db "When you're ready to make your move press Enter and then I'll make my move", 13, 10
		db "If you've realized that you lost and you want to reset the round,", 13, 10
		db "press R but this round will be lost.", 13, 10
		db "If you're tired of the game and you want to quit, press Escape to exit", 13, 10, 13, 10
		db "Good luck. You'll need it", 13, 10, 13, 10

continueMsg db "Press any key to continue...$"
levelMsg db 'Level: '
currentLevel db '1'
Lives db 3d
lines db 2d
balls db 6 dup(?)
originalBalls db 6 dup(?)
GameStatus db 0 ; some of this bits represent special cases and statuses of the game
; bit 1 - set if there are no more than one line with more than 1 ball in it
; bit 2 - set if the user pressed on exit button - terminate the game
; bit 3 - set if the user reached to the highest level - it's the last round
; bit 4 - set if the user wants to play again (at the end of the game)
; bit 5 - set if the user won the round (mainly used at the end of the game)
; bit 6 - set if the user wants to reset the round
Radius db ?
ballSpace db ?
colorToggle db ?

; BMP data
errorMsg db 'error', 10d, 13d, '$'
BMPVictory db 'Victory.bmp', 0
BMPIntro db 'Intro.bmp', 0
BMPDefeat db 'Defeat.bmp', 0
filehandle dw ?
Palette db 256d*4d dup(0)

ballsArray dw 200 dup(?)