; this file contains all the procedures for the project
HeartPosition equ 233d
HeartSpace equ 20d
HeartWidth equ 13d
HeartHight equ 11d
HeartY equ 7d

LIGHT_BLUE equ 53d
RED equ 4d
BLACK equ 0
WHITE equ 0fh

Escape equ 1h

distance equ 2d
gameFieldY equ 30d
gameField equ 110d
maxLevel equ 5

videoSeg equ 0a000h
clockSeg equ 40h

; procedure: introduction
; description:
;
; this procedure prints the opening screen at the start of the game and then
; it prints the instructions of the game. In addition, the procedure executes the code
; which needs to run at the beginning of the game.
proc introduction
	push ax dx
	
	mov ax, 13h
	int 10h
	push offset BMPIntro
	call printBMP ; print opening screen
	xor ah, ah
	int 16h
	mov ax, 3h
	int 10h
	lea dx, [intro]
	mov ah, 9h
	int 21h ; print instructions
	xor ah, ah
	int 16h
	mov [colorToggle], RED
	xor [colorToggle], LIGHT_BLUE
	xor ax, ax
	int 33h ; initialize the mouse
	
	pop dx ax
	ret
endp

; procedure: initializeGame
; description:
; This procedure initializes the entire game. It resets the variables to their initial state and
; prints the game screen.
; The variables which will be reset: [currentLevel] - '1', [GameStatus] - 0,
; [lines] - will be set to the value of the first byte in [levels], [Lives] - 3
proc initializeGame
	push bp ax bx cx
	
	mov ax, 13h
	int 10h
	mov [currentLevel], '1'
	mov [GameStatus], 0
	mov al, [levels]
	mov [lines], al
	mov [Lives], 3
	
	; print messages
	mov ax, ds
	mov es, ax
	mov ax, 1300h
	mov bx, 29h
	mov cx, 8d
	mov dx, 103h
	lea bp, [levelMsg]
	int 10h
	push WHITE 72d 16d 20d 5d
	call drawRect
	
	push WHITE 64d 16d HeartPosition - 5 5d
	call drawRect
	mov cl, [Lives]
	xor ch, ch
	mov ax, HeartPosition
@@drawHeart:
	push offset Heart ax HeartY HeartWidth HeartHight 27h
	call DrawHeart
	add ax, HeartSpace
	loop @@drawHeart
	
	xor ah, ah
	mov al, [levels + 1]
	push ax
	mov al, [levels + 2]
	push ax
	mov ax, 1
	int 33h
	call startGame
	
	pop cx bx ax bp
	ret
endp

; procedure: drawRect
; description:
; this procedure draws the outline of a rectangle on the screen according to the parameters
;
; parameters:
; all the parameters are passed to the procedure by the stack
;
; 1. color [bp + 12] - the color of the rectangle
; 2. width [bp + 10] - the width of the rectangle
; 3. hight [bp + 8] - the hight of the rectangle
; 4. X [bp + 6] - the column (x coordinate) of the top left corner of the rectangle
; 5. Y [bp + 4] - the row (y coordinate) of the top left corner of the rectangle
proc drawRect
	push bp
	mov bp, sp
	push ax bx cx si es
	
	mov ax, videoSeg
	mov es, ax
	mov ax, 320d
	mul [word ptr bp + 4]
	add ax, [bp + 6]
	mov si, ax
	mov cx, [bp + 10]
	mov ax, [bp + 12]
@@drawLine1:
	mov [es:si], al
	inc si
	loop @@drawLine1
	sub si, [bp + 10]
	add si, 320d
	mov cx, [bp + 8]
	sub cx, 2
	mov bx, [bp + 10]
	dec bx
@@drawRect:
	mov [es:si], al
	mov [es:si + bx], al
	add si, 320d
	loop @@drawRect
	mov cx, [bp + 10]
@@drawLine2:
	mov [es:si], al
	inc si
	loop @@drawLine2
	
	; restore registers and return
	pop es si cx bx ax bp
	ret 10d
endp

; procedure: DrawHeart
; description:
; This procedure draws a Width X Hight heart on the screen according to the parameters.
; parameters:
; HeartOffset [bp + 14] - the offset of the heart in DS
; X [bp + 12] - the X position of the top left corner of the Width X Hight square
; Y [bp + 10] - the Y position of the top left corner of the Width X Hight square
; Width [bp + 8] - the width of the heart
; Hight [bp + 6] - the hight of the heart
; color [bp + 4] - the color of the heart
proc DrawHeart
	push bp
	mov bp, sp
	push ax bx cx dx si es
	
	mov ax, videoSeg
	mov es, ax
	mov bx, [bp + 14d]
	mov ax, 320d
	mov dx, [bp + 10d]
	mul dx
	add ax, [bp + 12d]
	mov si, ax
	mov cx, [bp + 6d]
	mov al, [bp + 4d]
@@loop:
	push cx
	mov cx, [bp + 8d]
@@drawHeart:
	cmp [byte ptr bx], 0
	je @@NextPixel
	mov [es:si], al
@@NextPixel:
	inc si
	inc bx
	loop @@drawHeart
	sub si, [bp + 8d]
	add si, 320d
	pop cx
	loop @@loop
	
	pop es si dx cx bx ax bp
	ret 12d
endp

; procedure: startGame
; description:
;
; This procedure starts another round of the game.
; It generates X lines, according to [lines], and in each line there is a random number of balls according to the current level (see [levels]).
; Also, this procedure updates [Radius], [ballSpace], initializes [balls] and [originalBalls], and prints the balls to the screen
; so we can start playing.
proc startGame
	HeartY equ 187d
	min equ bp + 6
	max equ bp + 4
	push bp
	mov bp, sp
	sub sp, 3
	sub sp, [max] ; allocating an array on the stack to hold the random numbers
	add sp, [min]
	push ax bx cx dx si di es
	
	and [GameStatus], 0feh ; clear bit 1 of [GameStatus] because we start a new round
	mov ax, ds
	mov es, ax
	mov si, -1 ; cant do [bp - si], therefore put -1 in SI and use [bp + si] instead
	mov al, [min]
	mov cx, [max]
	sub cx, [min]
	inc cx
	push cx
@@initializeArray:
	mov [bp + si - 2], al
	inc al
	dec si
	loop @@initializeArray
; put all the posible amounts of balls in the array we have created
; then pick a random offset and 
	
	pop bx
	xor ax, ax
	mov cl, [lines]
	xor ch, ch
	dec cl
	lea si, [originalBalls]
	lea di, [balls]
	cld
@@generateLines:
	push 1 bx
	call randomize
	pop dx
	push si
	mov si, dx
	neg si
	mov dl, [bp + si - 2] ; get a random number in the range we wanted
	push si
	mov si, bx
	neg si
	mov dh, [bp + si - 2]
	pop si
	mov [bp + si - 2], dh
; put the number at the end of the array in the generated cell so the number we generated cant be used again
	dec bx
	pop si
	mov [si], dl
	movsb ; put the generated number in [balls] and [originalBalls]
	xor al, dl
	cmp dl, ah
	jbe @@next1
	mov ah, dl ; find the the greatest amount of balls to know what is the maximum size of a ball
@@next1:
	loop @@generateLines
@@lastLine:
	push 1 bx
	call randomize
	pop dx
	
	push si
	mov si, dx
	neg si
	mov dl, [bp + si - 2]
	push si
	mov si, bx
	neg si
	mov dh, [bp + si - 2]
	pop si
	mov [bp + si - 2], dh
	dec bx
	pop si
	
	cmp dl, al
	jne @@next2 ; make sure the generated number for the last line wont cause the user to lose
	push 1 bx
	call randomize
	pop dx
	push si
	mov si, dx
	neg si
	mov dl, [bp + si - 2]
	pop si
@@next2:
	mov [si], dl
	mov [di], dl
	cmp dl, ah
	jbe @@next3
	mov ah, dl
@@next3:
	mov cl, ah
	
	mov ax, 320d
	div cl ; get the horizontal space which one ball takes
	mov [ballSpace], al
	mul [lines]
	cmp ax, gameField
	jbe @@correctField
	mov ax, gameField
	div [lines]
	mov [ballSpace], al ; make sure the balls aren't too big
@@correctField:
	mov al, [ballSpace]
	sub al, distance
	shr al, 1
	mov [Radius], al
	mov bl, al
	xor bh, bh
	mov dl, [ballSpace]
	xor dh, dh
	mov [bp - 2], dx
	mov dl, al
	add dl, gameFieldY + distance
	mov cl, [lines]
	xor ch, ch
	lea si, [ballsArray]
	lea di, [originalBalls]
; draw the lines of balls according to the array [originalBalls]
; AX = x coordinate
; BX = Radius
; DX = y coordinate
	mov ax, 2
	int 33h
@@draw:
	push cx
	mov cl, [di]
	xor ch, ch
	mov al, [Radius]
	add al, distance
	xor ah, ah
@@drawLine:
	mov [si], ax
	add si, 2
	mov [si], dx
	add si, 2
	push cx dx
	xor cx, cx
	mov dl, 20d
	call delay
	pop dx cx
	push LIGHT_BLUE bx ax dx ;BX = Radius
	call drawCircle
	add ax, [bp - 2]
	loop @@drawLine
	inc di
	pop cx
	add dx, [bp - 2]
	loop @@draw
	mov ax, 1
	int 33h
	
	pop es di si dx cx bx ax
	sub sp, [min]
	add sp, [max]
	add sp, 3
	pop bp
	ret 4
endp

; procedure: randomize
; description:
; this procedure generates a random number in the range [min, max]
;
; parameters:
; all the parameters are passed to the procedure by the stack
;
; 1. min [bp + 6] - the minimum number that can be generated
; 2. max [bp + 4] - the maximum number that can be generated
;
; RETURN:
; a random number in the range [min, max] will be returned on the stack (and will need to be poped)
proc randomize
	push bp
	mov bp, sp
	push ax bx dx es
	
	mov ax, clockSeg
	mov es, ax
	mov bx, [cs_address]
	mov ax, [cs:bx]
	add bx, 2
	add [cs_address], 2
	xor ax, [es:6ch]
	mov dx, [es:6ch]
	mul [word ptr es:6eh]
	push ax
	xor ax, dx
	mov [es:6eh], ax
	mov ax, [cs:bx]
	xor [es:6ch], ax
	add [cs_address], 2 ; get a different word from the code memory
	pop ax
	xor dx, dx
	mov bx, [bp + 4]
	sub bx, [bp + 6]
	inc bx ; BX = the amount of the numbers which can be generated (including [min] and [max])
	div bx ; DX - a number between 0 and [max] - [min]
	add dx, [bp + 6] ; add the value of [min] to get a number in the correct range
	mov [bp + 6], dx ; return the result on the stack
	
	;return
	pop es dx bx ax bp
	ret 2
endp

; procedure: drawCircle
; description:
; this procedure draws a circle on the screen according to the parameters - the color, the radius and the x, y coordinates of the center
; note that the procedure does not set graphics mode so it must be done manully
; parameter:
color equ bp + 10 ;the color of the circle
r equ bp + 8 ;the radius of the circle (in pixels)
;the radius must be less or equal to half of the width of the screen (100 in graphics mode 320x200) otherwise the circle will be out of the screen (the procedure will not work)
x_center equ bp + 6 ;the x coordinate of the center if the circle
y_center equ bp + 4 ;the y coordinate of the center if the circle

; local variables:
r_squared equ bp - 2 ;radius * radius
; (x_final, y_final) - the x, y coordinates of the bottom right vertex of the square which blocks the circle
x_final equ bp - 4 ;equals to: x_center + radius
y_final equ bp - 6 ;equals to: y_center + radius
x_start equ bp - 8 ;the x coordinate of the most left pixel of the square which blocks the circle (equals to: x_center - radius + 1)
len equ bp - 10
proc drawCircle
	push bp
	mov bp, sp
	sub sp, 0ah
	push ax bx cx dx si es
	
	mov ax, videoSeg
	mov es, ax ; video memory segment
	mov ax, [x_center]
	mov [x_final], ax
	mov cx, ax
	mov ax, [r]
	add [x_final], ax
	sub cx, ax
	inc cx
	mov [x_start], cx
	mov dx, [y_center]
	mov [y_final], dx
	add [y_final], ax
	sub dx, ax
	inc dx
	mul al ;AL = radius -> AX = radius * radius
	mov [r_squared], ax
	push dx
; calculate the byte of the first pixel in the video memory: 320*Y + X
	mov ax, 320d
	mul dx
	add ax, cx
	mov si, ax
	pop dx
	mov ax, [x_final]
	sub ax, [x_start]
	mov [len], ax
; check all the pixels in the square which blocks the wanted circle.
; if the current pixel coordinates (x, y) make the equation (x - x_center)^2 + (y - y_center)^2 < r^2 true this pixel needs to be painted
@@checkPixel:
	mov ax, cx
	sub ax, [x_center]
	push dx
	imul ax ; DX:AX = (x - x_center)^2
	test dx, dx ; if DX != 0 the equation can't be true - the pixel won't be painted
	pop dx
	jnz @@nextPixel
	mov bx, ax ; (x - x_center)^2
	mov ax, dx
	sub ax, [y_center]
	push dx
	imul ax ; DX:AX = (y - y_center)^2
	test dx, dx ; if DX != 0 the equation can't be true - the pixel won't be painted
	pop dx
	jnz @@nextPixel
	add ax, bx ; AX = (x - x_center)^2 + (y - y_center)^2
	jc @@nextPixel ; if we had a carry, the result must be greater than r^2
	cmp ax, [r_squared]
	ja @@nextPixel
@@drawPixel:
; if we got to this label, the current pixel which is checked needs to be painted
	mov al, [byte ptr color]
	mov [es:si], al ; paint the pixel
@@nextPixel:
	inc cx
	inc si
	cmp cx, [x_final]
	jb @@nextLine
	sub si, [len]
	add si, 320d
	mov cx, [x_start]
	inc dx
@@nextLine:
	cmp dx, [y_final]
	jb @@checkPixel
	
	;return
	pop es si dx cx bx ax
	add sp, 0ah
	pop bp
	ret 8d
endp

; procedure: delay
; description:
; this procedure causes the program to wait according to the parameters (seconds and hundreths of second)
; parameters:
;
; CX - seconds - must be less or equal to 3604 (about an hour)
; DL - hundreths of second (1/100 second) - if CX = 3604 then DL must be less or equal to 42 (DL <= 42)
proc delay
	push ax cx dx es
	
	mov ax, 40h
	mov es, ax ;timer segment (the value in 40h:6ch changes every 55 milliseconds (0.055 seconds))
	jcxz @@hundrethSecond
@@seconds:
	mov ax, 1000d
	mul cx
	mov cx, 55d
	div cx
	mov cx, ax ; CX = CX / 0.055
@@hundrethSecond:
	test dl, dl
	jz @@delay
	mov al, 10d
	mul dl
	mov dl, 55d
	div dl
	xor ah, ah ; AL = (DL/100) / 0.055
	add cx, ax
@@delay:
	jcxz @@return
	mov ax, [es:6ch]
@@firstTick:
	cmp ax, [es:6ch]
	je @@firstTick ; wait for first clock tick (less then 55 milliseconds)
@@delayLoop:
	mov ax, [es:6ch]
@@Tick:
	cmp ax, [es:6ch]
	je @@Tick
	loop @@delayLoop ; loop until 0.55 seconds pass CX times
@@return:
	pop es dx cx ax
	ret
endp

; procedure: clearMarks
; description:
; this procedure clears all the balls from a specific line the user marked on his turn (all the red balls) and repaints them in the clearColor
; parameters:
;
; 1. clearColor [word ptr bp + 6]
; 2. line [word ptr bp + 4] - the line to clear the marked balls from (first line is 0)
;
; return:
;
; the number of the balls we cleared will be returned on the stack
proc clearMarks
line equ bp + 4
clearColor equ bp + 6
	push bp
	mov bp, sp
	push ax bx cx dx si
	
	mov bx, [line]
	push bx
	call FindAddress
	mov ax, 2
	int 33h ; hide mouse cursor so it doesnt disturb the drawing
@@clearLine:
	lea bx, [originalBalls]
	add bx, [line]
	mov cl, [bx]
	xor ch, ch
	xor bh, bh
@@clear:
	push cx
	mov cx, [si]
	mov dx, [si + 2]
	mov ah, 0dh
	int 10h
	pop cx
	cmp al, RED ; check if the current ball is red and if it is - paint it with the defined color
	jne @@nextBall
	push [clearColor]
	mov al, [Radius]
	xor ah, ah
	push ax [si] [si + 2]
	call drawCircle ; paint the ball the user pressed on
@@nextBall:
	add si, 4
	loop @@clear
	mov ax, 1
	int 33h ; restore mouse cursor
@@return:
	pop si dx cx bx ax bp
	ret 4
endp

; procedure: GameEnd
; description:
; This procedure checkes if the game has ended
; In other words, the procedure checkes if there are no more ball on the screen
;
; return:
;
; ZF - set if the game has ended and clear otherwise
proc GameEnd
	push ax bx cx
	
	mov cl, [lines]
	xor ch, ch
	lea bx, [balls]
	xor al, al
@@end:
	or al, [bx]
	inc bx
	loop @@end
	test al, al ; no balls -> AL = 0
; return
	pop cx bx ax
	ret
endp

; procedure: FindAddress
; description:
; this procedure makes SI to point to the coordinates of the first ball in the array [ballsArray]
; parameters:
;
; line [bp + 4] - the line of balls (starting from 0) we want to point in the array
;
; return:
;
; SI - the address of the first ball of the defined line in [ballsArray]
proc FindAddress
	push bp
	mov bp, sp
	push ax bx
	
	mov bx, [bp + 4]
	xor ah, ah
	lea si, [ballsArray]
	test bx, bx
	jz @@return
@@FindAddress:
	dec bx
	mov al, [originalBalls + bx]
	shl al, 2
	add si, ax
	test bx, bx
	jnz @@FindAddress
@@return:
	pop bx ax
	pop bp
	ret 2
endp

; procedure: ExecuteComputerMove
; description:
; this procedure executes the computer move on the screen
; parameters:

; line [bp + 6] - the line that the computer plays in
; balls [bp + 4] - the amount of balls to remove
proc ExecuteComputerMove
	push bp
	mov bp, sp
	push ax bx cx dx si
	
	mov ax, 2
	int 33h
	mov ax, [bp + 6]
	inc ax
	push ax
	call FindAddress
	sub si, 4
	mov cx, [bp + 4]
	xor bh, bh
	mov bl, [Radius]
@@removeBalls:
	push cx
@@checkBall:
	mov cx, [si]
	mov dx, [si + 2]
	mov ah, 0dh
	int 10h
	test al, al
	jnz @@remove
	sub si, 4
	jmp @@checkBall
@@remove:
	push BLACK bx [si] [si + 2]
	xor cx, cx
	mov dl, 50d
	call delay
	call drawCircle
	sub si, 4
	pop cx
	loop @@removeBalls
	mov ax, 1
	int 33h
@@return:
	pop si dx cx bx ax bp
	ret 4
endp

; procedure: roundLost
; description:
; This procedure executes the code which needs to run when the user loses a round.
; The procedure decreases [lives], clear one heart, sets [GameStatus]
; and starts a new round at the same level if he didn't lose all his lives
; return:
; ZF - set if the user lost all his lives
proc roundLost
	push ax
HeartY equ 7d
	and [GameStatus], 0efh ; clear bit 5 - the user lost
	mov al, HeartSpace
	mov ah, [Lives]
	dec ah
	mul ah
	add ax, HeartPosition
	push offset Heart ax
	push HeartY
	push HeartWidth HeartHight BLACK
	call DrawHeart ; clear the most right heart because the user lost a life
	dec [Lives]
	pushf
	jz @@endGame
	mov al, [currentLevel]
	dec al
	sub al, '0'
	mov ah, al
	shl al, 1
	add al, ah ; multiply AL by 3
	xor ah, ah
	lea bx, [levels]
	add bx, ax
	mov al, [bx + 1]
	push ax
	mov al, [bx + 2]
	push ax
	call startGame
@@endGame:
	popf
	pop ax
	ret
endp

; procedure: roundWon
; description:
; This procedure executes the code which needs to run when the user wins a round.
; The procedure increases [currentLevel], prints the new level to the screen (see [levelMsg]),
; checks if the user reached the highest level, sets [GameStatus] accordingly and starts a new round if the user
; didn't reach the highest level.
proc roundWon
	push ax bx cx dx bp es
	
	or [GameStatus], 10000b ; set bit 5 - the user won
	mov al, [currentLevel]
	sub al, '0'
	cmp al, maxLevel
	jne @@levelUp
	or [GameStatus], 100b ; the user beat the highest level - set [GameStatus] and return
	jmp @@return
@@levelUp:
	mov ah, al
	shl al, 1
	add al, ah
	xor ah, ah
	lea bx, [levels]
	add bx, ax ; make BX point to the new level the user reached to in [levels]
	mov al, [bx]
	mov [lines], al
	inc bx
	push bx
	inc [currentLevel]
	mov ax, ds
	mov es, ax
	mov ax, 1300h
	mov bx, 29h
	mov cx, 1
	mov dx, 10ah
	lea bp, [currentLevel]
	int 10h
	pop bx
	xor ah, ah
	mov al, [bx] ; get the range of the numbers which can be generated (see [levels]) to start another round
	push ax
	mov al, [bx + 1]
	push ax
	call startGame
@@return:
	pop es bp dx cx bx ax
	ret
endp

; this procedure simply delays the game until the user releases the left button of the mouse
proc WaitForMouseRelease
	push ax bx cx dx
	
@@WaitForMouseRelease:
	mov ax, 3h
	int 33h
	test bx, 1b
	jnz @@WaitForMouseRelease
	
	pop dx cx bx ax
	ret
endp

; procedure: playAgain
;
; description:
; this procedure executes the code which needs to run at the end of the game
; it prints victory/defeat picture and asks the user to play again.
; the procedure sets bit 4 of [GameStatus] if the user wants to play again
proc playAgain
YKey equ 15h
NKey equ 31h
	push ax
	
	and [GameStatus], 0f7h ; clear bit 4 of [GameStatus]
	test [GameStatus], 10000b ; check if the user won or lost to know which picture to print (Victory.bmp/Defeat.bmp)
	jnz @@victory
	push offset BMPDefeat
	jmp @@continue
@@victory:
	push offset BMPVictory
@@continue:
	call printBMP
	mov ax, 0c00h
	int 21h ; clear keyboard buffer so previous input doesn't count
@@WaitForInput:
	xor ah, ah
	int 16h
; wait for keyboard input:
; if Y - play the game again
; if N - exit the game
; otherwise - keep waiting for input
	cmp ah, YKey
	je @@PlayAgain
	cmp ah, NKey
	je @@return
	jmp @@WaitForInput
@@PlayAgain:
	or [GameStatus], 1000b
@@return:
	pop ax
	ret
endp

proc clearGameArea
	push ax cx dx di es
	
	mov ax, videoSeg
	mov es, ax
	mov ax, 320d
	mov dx, gameFieldY
	mul dx
	mov di, ax
	mov cx, 320d*gameField
	cld
	mov ax, 2
	int 33h
	xor al, al
	rep stosb
	mov ax, 1
	int 33h
	
	pop es di dx cx ax
	ret
endp

proc PlayerTurn
enter_key equ 1ch
r_key equ 13h
ballColor equ bp - 1
currentLine equ bp - 2
markedBalls equ bp - 3
flags equ bp + 2
	push bp
	mov bp, sp
	sub sp, 3
	push ax bx cx dx si
	
	mov [byte ptr markedBalls], 0
	and [GameStatus], 0ddh ; turn off bit 2 and bit 6 of [GameStatus]
	mov [byte ptr currentLine], 0ffh ; initialize [currentLine]
	call WaitForMouseRelease
	mov ax, 0c00h
	int 21h ; clear keyboard buffer so previous input doesn't count
@@getInput:
	mov ah, 1h
	int 16h
	jz @@MouseInput
	xor ah, ah
	int 16h
	cmp ah, enter_key
	jne @@checkEscape
	jmp @@endOfTurn
@@checkEscape:
	cmp ah, Escape
	jne @@checkR
	or [GameStatus], 10b ; user pressed Escape - set second bit of [GameStatus]
	jmp @@return
@@checkR:
	cmp ah, r_key
	jne @@MouseInput
	or [GameStatus], 20h
	jmp @@return
@@MouseInput:
	mov ax, 3h
	int 33h
	test bx, 1b
	jz @@getInput
	shr cx, 1 ; adjust CX to fit the screen
	dec dx ; decrease DX so the mouse doesn't disturb
	cmp dx, gameFieldY
	jb @@getInput
	cmp dx, gameField + gameFieldY ; check if the mouse is in the game area
	ja @@getInput
	xor bh, bh
	mov ah, 0dh
	int 10h
	test al, al ; cmp al, BLACK
	jnz @@toggleColor
	call WaitForMouseRelease
	mov ax, 0c00h
	int 21h ; clear the keyboard buffer
	jmp @@getInput
@@toggleColor:
	mov [ballColor], al
	mov ax, dx
	sub ax, gameFieldY
	div [ballSpace] ; get the line where the user pressed (from top to bottom, starts with 0)
	cmp [byte ptr currentLine], 0ffh
	jne @@continue1
	mov [currentLine], al
@@continue1:
	mov bl, al
	xor bh, bh
	xor ah, ah
	cmp al, [currentLine]
	je @@continue2
	mov al, [currentLine] ; if the user marked a ball in another line, we clear the last line marks
	mov [byte ptr markedBalls], 0
	push LIGHT_BLUE ax
	call clearMarks
	mov [currentLine], bl
@@continue2:
	push bx
	call FindAddress
	mov ax, cx
	div [ballSpace] ; get the ball the user pressed on (from left to right, starts with 0)
	xor bh, bh
	mov bl, al
	shl bx, 2 ; make BX point to the correct circle the user chose in [ballsArray]
	mov al, [ballColor]
	cmp al, LIGHT_BLUE
	jne @@redBall
	inc [byte ptr markedBalls]
	jmp @@continue3
@@redBall:
	dec [byte ptr markedBalls]
@@continue3:
	xor al, [colorToggle]
	xor ah, ah
; pass parameters to the procedure drawCircle
	push ax
	mov al, [Radius]
	xor ah, ah
	push ax [si + bx] [si + bx + 2]
	mov ax, 2
	int 33h ; hide mouse cursor so it doesnt disturb the drawing
	call drawCircle ; paint the ball the user pressed on
	mov ax, 1
	int 33h ; restore mouse cursor
	call WaitForMouseRelease
	jmp @@getInput
@@endOfTurn:
	cmp [byte ptr currentLine], 0ffh
	jne @@clear
	jmp @@getInput
@@clear:
	cmp [byte ptr markedBalls], 0
	jne @@next
	jmp @@getInput
@@next:
	push BLACK
	xor ah, ah
	mov al, [currentLine]
	push ax
	call clearMarks
	lea bx, [balls]
	add bx, ax
	mov al, [markedBalls]
	sub [bx], al
@@return:
	pop si dx cx bx ax
	add sp, 3
	pop bp
	ret
endp

proc ComputerMove
	push ax bx cx
	
	test [GameStatus], 1b
	jnz @@start
	xor al, al
	xor ch, ch
	mov cl, [lines]
	lea bx, [balls]
@@checkSpecialCase:
	cmp [byte ptr bx], 1
	jbe @@moreThanOne
	inc al
@@moreThanOne:
	inc bx
	cmp al, 1
	ja @@start
	loop @@checkSpecialCase
	or [GameStatus], 1b
@@start:
	xor ah, ah
	mov al, [GameStatus]
	and al, 1b
	xor ch, ch
	mov cl, [lines]
	lea bx, [balls]
@@loop:
	xor al, [bx]
	inc bx
	loop @@loop
	test al, al
	jz @@defeat ; random move if losing
	mov ah, 80h
@@checkBit:
	test al, ah
	jnz @@end
	shr ah, 1
	jmp @@checkBit
@@end:
	xor bx, bx
@@findLine:
	test [balls + bx], ah
	jnz @@lineFound
	inc bx
	jmp @@findLine
@@lineFound:
	xor al, [balls + bx]
	mov ah, [balls + bx]
	sub ah, al
	mov [balls + bx], al
	shr ax, 8
	jmp @@execute
@@defeat:
	mov al, [lines]
	xor ah, ah
	dec al
@@randomLine:
	push 0 ax
	call randomize
	pop bx
	cmp [balls + bx], 0
	je @@randomLine
	mov al, [balls + bx]
	push 1 ax
	call randomize
	pop ax
	sub [balls + bx], al
@@execute:
	push bx ax
	call ExecuteComputerMove
@@return:
	pop cx bx ax
	ret
endp