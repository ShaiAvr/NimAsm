IDEAL
MODEL small
STACK 100h

DATASEG
include 'NimData.asm'

CODESEG
include 'NimProcs.asm'
include 'BmpProcs.asm'

start:
	mov ax, @data
	mov ds, ax
	
	call introduction
Restart:
	call initializeGame
Play:
	call PlayerTurn
	test [GameStatus], 10b
	jz Continue
	and [GameStatus], 0efh
	jmp EndGame
Continue:
	test [GameStatus], 20h
	jz EndTurn
	call clearGameArea
	jmp Defeat
EndTurn:
	call GameEnd
	jnz Computer ; if true - player lost
	jmp Defeat
Computer:
	call ComputerMove
	call GameEnd
	jnz Play
	jmp Victory
Defeat:
	call roundLost
	jz endGame
	jmp Play
Victory:
	call roundWon
	test [GameStatus], 100b
	jz Play
EndGame:
	call playAgain
	test [GameStatus], 1000b
	jz exit
	jmp Restart
	
exit:
	mov ax, 3h
	int 10h
	mov ax, 4c00h
	int 21h
END start