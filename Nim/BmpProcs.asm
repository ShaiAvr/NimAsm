; parameters:
; file name [bp + 4]
proc openFile
	push bp
	mov bp, sp
	push ax dx
	
	mov ah, 3Dh
	xor al, al
	mov dx, [bp + 4]
	int 21h
	jc @@openerror
	mov [bp + 4], ax
	jmp @@return
@@openerror:
	lea dx, [errorMsg]
	mov ah, 9h
	int 21h
@@return:
	pop dx ax bp
	ret
endp

; parameters:
; filehandle [bp + 4]
proc skipHeader
	HeaderLength equ 54d
	push bp
	mov bp, sp
	push ax bx cx dx
	
	mov ax, 4200h
	mov bx, [bp + 4]
	xor cx, cx
	mov dx, HeaderLength
	int 21h
	
	pop dx cx bx ax bp
	ret 2
endp

; parameters:
; filehandle [bp + 6]
; offset palette [bp + 4]
proc readAndCopyPal
	push bp
	mov bp, sp
	push ax bx cx dx si
	
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah, 3fh
	mov bx, [bp + 6]
	mov cx, 400h
	mov dx, [bp + 4]
	int 21h
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si, [bp + 4]
	mov cx, 100h
	mov dx, 3C8h
	xor al, al
	; Copy starting color to port 3C8h
	out dx, al
	; Copy palette itself to port 3C9h
	inc dx
@@PalLoop:
	mov bx, 3
	; Note: Colors in a BMP file are saved as BGR values rather than RGB.
@@sendColors:
	mov al, [si + bx - 1] ; Get color value (RGB).
	shr al, 2 ; Max. is 255, but video palette maximal value is 63. Therefore dividing by 4.
	out dx, al ; Send it.
	dec bx
	jnz @@sendColors
	add si, 4 ; Point to next color (There is a null chr. after every color.)
	loop @@PalLoop
	
	pop si dx cx bx ax bp
	ret 4
endp

; parameters:
; filehandle [bp + 4]
proc CopyBitmap
	push bp
	mov bp, sp
	push ax bx cx dx ds

	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, videoSeg
	mov ds, ax
	mov dx, 320d*199d
	mov cx, 200d
@@PrintBMPLoop:
	push cx
	; Copy one line into video memory
	mov bx, [bp + 4]
	mov ah, 3fh
	mov cx, 320d
	int 21h
	sub dx, 320d	
	pop cx
	loop @@PrintBMPLoop
	
	pop ds dx cx bx ax bp
	ret 2
endp

; parameters:
; file handle [bp + 4]
proc CloseFile
	push bp
	mov bp, sp
	push ax bx 

	mov ah, 3eh
	mov bx, [bp + 4]
	int 21h
	
	pop bx ax bp
	ret 2
endp

; parameters:
; BMP name [bp + 4]
proc printBMP
	push bp
	mov bp, sp
	push ax
	
	mov ax, 2
	int 33h
	push [bp + 4]
	call openFile
	pop [filehandle]
	push [filehandle]
	call skipHeader
	push [filehandle] offset Palette
	call readAndCopyPal
	push [filehandle]
	call CopyBitmap
	push [filehandle]
	call CloseFile
	
	pop ax bp
	ret 2
endp