;Programa "numerar", numera segun se le indica.
;Autor:
;
;compilar:
;	$ yasm -f elf numerar.asm
;enlazar:
;	$ ld -o numerar numerar.o
;ejecutar:
;	$ ./numerar [parametros]
;-----------------------------------------------------------------------

section .data 
	enDec	db	1	;1 indica que se enumera en decimal (por defecto), 0 en hex. 
	cont dd 1		;cont es el contador de lineas. 
	;En caso de extender el programa para mas lineas, solo se modifican limite y digs. 
	limite	equ 999	;Limite de lineas en el archivo de entrada. 
	digs	equ 3	;Dado que el MAX de lineas es 999 (3 digitos). 
	
	auxFile	dd	"temporal.txt", 0	;Si se necesita se crea y luego se elimina.

	ayuda	db "Programa para numerar cada linea de texto de una entrada provista por el usuario.", 10,
			db "Se detallan formato y opciones de invocacion: ", 10,
			db "Sintaxis:	$ numerar [ -h | -d | -x] [ archivo_entrada | archivo_entrada archivo_salida ]", 10,
			db "Los parametros entre corchetes denotan parametros opcionales. Las opciones separadas por ", 10,
			db "una barra vertical denotan posibles alternativas.", 10,
			db "-h muestra un mensaje de ayuda (este mensaje).", 10,
			db "-d y -x indican si se numerara en decimal (por defecto) o hexadecimal respectivamente.", 10,
			db "archivo_entrada sera el archivo cuyo texto sera numerado en archivo_salida.", 10,
			db "Si solo se indica archivo_entrada, se numera en ese mismo archivo.", 10,
			db "Si no se especifica archivo alguno, la entrada estandar sera usada como medio de lectura.", 10,
			db "Esto significa que puede ingresar el texto a numerar por la consola dando fin al ingreso", 10,
			db "de texto al posicionarse en una nueva linea y presionar Ctrl+d, ", 10,
			db "luego se muestra el texto numerado en la misma consola.", 10,
			db "Para mas informacion, consulte la documentacion del programa.", 10,
	lAyuda equ $-ayuda
;-----------------------------------------------------------------------


section .bss
	contString resb	digs	; El string tendra tantos componentes como digitos tenga el limite de lineas.
	buffer	resb	1	; Al leer un caracter, se guarda en buffer.
				; Y al escribir uno, antes se debe guardar en buffer. 
	lBuffer	equ $-buffer	; Longitud del buffer. 
	
	fdAux resd	1	; File descriptor (fd) del archivo auxiliar. 
	
	file1 resd	1	; Path del 1er archivo como parametro.
					; o del unico si solo hay uno.
	fd1 resd	1	; File descriptor del archivo file1. 					
	file2 resd	1	; Path del 2do archivo como parametro.
	fd2 resd	1	; File descriptor del archivo file2.
	
	; input y output indican desde donde se leeran caracteres y donde 
	; se escribiran (con lineas numeradas).
	; Son descriptores de archivos.
	input 		dd	1	
	output 		dd	1
;-----------------------------------------------------------------------
section .text
	global _start 	
	
_start:
	pop eax	; eax=cantidad de argumentos del programa.
	pop ebx	; ebx=nombre del programa, se descarta. 
	dec eax	; Se descuenta 1 para no tener en cuenta el nombre del programa. 
			; Solo se consideran aquellos parametros dados por el usuario.
	cmp eax, 0				; 0 parametros?
	je 	consolaAArchivoAux	; Se pasa a enumerar lo ingresado por pantalla.
							; Siendo esta la unica opcion posible si no se
							; ingresan parametros. 
	; Se pasa a determinar de que se trata para 1, 2 y 3 args.
	cmp eax, 1
	je unArg	
	cmp eax, 2	
	je	dosArgs	
	cmp eax, 3	
	je tresArgs		
	jg tErrorOtro	; El maximo n de argumentos es 3, mas ya es error.
;-----------------------------------------------------------------------
unArg:
	pop ebx	; Se extrae el argumento ingresado. 
	mov ecx, [ebx]
	cmp cl, '-'
	je .continuar
	push ebx					; Se devuelve el parametro a la pila. 
	jne	unArchivoAConsola		; Si no hay un '-' solo puede haber un path
								; de archivo.
	.continuar								
	inc ebx			; Se saltea el '-'.
	mov ecx, [ebx]
	cmp cl, 'h'
	je mostrarAyuda
	cmp cl, 'd'
	je consolaAArchivoAux
	cmp cl, 'x'
	jne tErrorOtro	; Sino es un -x para consola con numeracion hex, ya es error.
	call enHex
	jmp consolaAArchivoAux
;-----------------------------------------------------------------------
dosArgs:
	pop ebx			; Se extrae 1er argumento ingresado. 
	mov ecx, [ebx]
	cmp cl, '-'
	je .continuar
	push ebx		; Se devuelve el parametro a la pila. 
	jne dosArchivos	; Sino hay un '-' tienen que ser dos path de archivos.
	
	.continuar
	inc ebx	; Se saltea el '-'.
	mov ecx, [ebx]
	cmp cl, 'd'
	je unArchivoAConsola	; Si el 1ero es una 'd' el segundo tienen que
							; ser un path de archivo.
	cmp cl, 'x'
	jne tErrorOtro			; Sino es un -x, ya es error. 
	call enHex
	jmp unArchivoAConsola	; Si el 1ero es una 'x' el segundo tienen que
							; ser un path de archivo.
;-----------------------------------------------------------------------
tresArgs:
	pop ebx	; Se extrae 1er argumento ingresado. 
	mov ecx, [ebx]
	cmp cl, '-'
	jne tErrorOtro	; Al ser 3 args, el 1ero debe tener un '-'.
	
	inc ebx	; Se saltea el '-'.
	mov ecx, [ebx]
	cmp cl, 'd'
	je dosArchivos	; Los otros dos tienen que ser path de archivos.
	
	cmp cl, 'x'
	jne tErrorOtro	; Sino es un -x, ya es error. 
	call enHex
	jmp dosArchivos	; Los otros dos tienen que ser path de archivos.
;-----------------------------------------------------------------------
mostrarAyuda:
	mov eax, 4		; sys_write
	mov ebx, 0		; La consola.	
	mov ecx, ayuda	; Puntero a el texto a mostrar
	mov edx, lAyuda	; su tamaño. 
	int 80h			; llamada al servicio. 
	jmp tNormal
;-----------------------------------------------------------------------
consolaAArchivoAux:		
	mov [input], dword 0; Se lee de consola.
	mov ebx, auxFile	; guarda en ebx el path del archivo auxiliar.
	call createFile		; Se crea archivo auxiliar, se crea "abierto".
	cmp eax, 0
	jl tErrorOtro		; Se chequea por error al crear. eax<0 implica error. 
	mov [output], eax	; El archivo auxiliar es designado como output. 
	mov [fdAux], eax	; Se guarda fd de auxiliar.
	
	call copiar			; Se guarda desde consola al archivo aux. 
	
	mov ebx, [fdAux]	; ebx=file descriptor del archivo auxiliar.
	call closeFile		; cierra el archivo auxiliar
	cmp eax, 0
	jl tErrorOtro		; Se chequea por error al cerrar. eax<0 implica error. 

	mov [output], dword 1	; salida por consola
	call printEnter			; Se imprime un enter para separar un poco
							; entrada de salida. 
	mov ebx, auxFile		; Se abre archivo auxiliar. 
	call openFile			
	cmp eax, 0
	jl tErrorOtro			; Se chequea por error al abrir.
	mov [input], eax		; El archivo aux es entrada ahora. 
	mov [fdAux], eax		; Se guarda fd de auxiliar.
	
	call numerar			; Se numera lo leido del archivo auxliliar en pantalla. 
	call printEnter			; Se imprime un enter para separar un poco
							; entrada de salida. 
	mov ebx, [fdAux]	; ebx=file descriptor del archivo auxiliar.
	call closeFile		; Cierra el archivo auxiliar
	cmp eax, 0
	jl tErrorOtro		; Se chequea por error al cerrar.
	mov ebx, auxFile	; Se elimina archivo auxiliar.
	call deleteFile
	cmp eax, 0
	jl tErrorOtro		; Se chequea por error al eliminar.
	jmp tNormal
;-----------------------------------------------------------------------
;En la pila espera el path del archivo.
unArchivoAConsola: 
	pop ebx				; Se extrae path del archivo a numerar en pantalla. 
	mov [file1], ebx	; Se guarda el path del archivo. 
	call openFile		; Se abre archivo origen.
	cmp eax, 0
	jl tErrorArchivoEntrada	; Se chequea por error al abrir. 
	mov [input], eax		; Se designa al archivo entrada como entrada.
	mov [fd1], eax			; Se guarda fd.
	mov [output], dword 1	; Salida por consola
	call printEnter			; Se imprime un enter para separar un poco
							; entrada de salida. 
	call numerar			; Se numera lo leido del archivo en pantalla. 
	call printEnter			; Se imprime un enter para separar un poco
							; entrada de salida. 
	mov ebx, [fd1]		; Se cierra el archivo de entrada. 	
	call closeFile	
	cmp eax, 0
	jl tErrorArchivoEntrada		; Se chequea por error al cerrar.
	jmp tNormal					
;-----------------------------------------------------------------------
;Espera las rutas del archivo entrada y el archivo salida en la pila.  
dosArchivos:
	pop ebx				; el 1er parametro es el archivo a usarse como fuente. 
	mov [file1], ebx	; Se guarda el archivo origen.
	pop ebx				; Se extrae 2do archivo.
	mov [file2], ebx	; Se guarda el archivo destino. 
	
	mov ebx, [file1]		; Se abre 1er archivo, entrada. 
	call openFile
	cmp eax, 0
	jl tErrorArchivoEntrada	; Se chequea por error al abrir. 
	mov [input], eax
	mov [fd1], eax			; Se guarda fd.
	
	mov ebx, [file2]		; Se abre 2do archivo, salida. 
	call openFile
	cmp eax, 0
	jl tErrorArchivoSalida	; Se chequea por error al abrir. 
	mov [output], eax
	mov [fd2], eax			; Se guarda fd.

	call numerar			; Se numera el contenido del archivo entrada
							; en el archivo salida. 
	
	mov ebx, [fd1]			; Se cierra el archivo de entrada. 	
	call closeFile
	cmp eax, 0
	jl tErrorArchivoEntrada	; Se chequea por error al cerrar.
	mov ebx, [fd2]			; Se cierra el archivo de salida. 	
	call closeFile	
	cmp eax, 0
	jl tErrorArchivoSalida	; Se chequea por error al cerrar.
	jmp tNormal
;-----------------------------------------------------------------------
; Numera el contenido de input en output.
; Si input y/o output son archivos estos tienen que estar ya abiertos.
; Esto es que input/output son en realidad descriptores de archivos. 
; numerar NO cierra archivos.
numerar:
	call readChar
	whileNotEOF2:
		cmp eax,  0		; Se chequea fin de archivo.
		je EOF2		
		mov ebx, [buffer]
		push ebx 		; Se salva el buffer, writeCont lo modifica.
		call writeCont	; Se escribe el contador.
		pop ebx			; Se recupera el buffer.
		mov [buffer], bl
		call incCont	; Se incrementa el contador.
		whileNotEnter:
			mov eax, [buffer]
			cmp al,  10		; Se chequea por fin de linea. 
			je unEnter	 
			call writeChar	; Se pasa todo de input a output. 
			call readChar

			cmp al,  0		; Para el caso en que el archivo no termine en enter. 
			je EOF2			; Tambien para cuando el usuario ingresa Ctrl+d 
							; no estando en una nueva linea (se evita potencial bucle infinito).
		jmp whileNotEnter
		unEnter: 
		call writeChar	; Escribe el enter que faltaría. 
		call readChar	
	jmp whileNotEOF2
	EOF2:
	ret
;-----------------------------------------------------------------------
; Copia el contenido de input a output.
; Se esperan archivos abiertos, y no se cierran. 
; Detecta que se terminó de leer input al comparar con 0.
; Esto coincide con lo que retorna sys_read en eax al leer EOF y tambien
; con Ctrl+D=end-of-transmission character (EOT), por lo que input puede
; ser la pantalla. 
copiar:
	call readChar
	whileNotEOF1:
		cmp eax,  0		; Se chequea fin de archivo. 
		je EOF1		
		call writeChar
		call readChar
	jmp whileNotEOF1
	EOF1:
	ret
;-----------------------------------------------------------------------
; Rutinas relativas al contador.
; Esta rutina incrementa el contador.
incCont:
	mov eax, [cont]
	inc eax
	cmp eax, limite
	jg tErrorArchivoEntrada	; El archivo de entrada excede limite de lineas.
	mov [cont], eax
	ret
	
; Escribe el contador, los dos puntos y el espacio.   
writeCont:
	mov edi, contString ; edi es parametro para dec/hex2String
	;En dec o hex?
	mov eax, [enDec]
	cmp al, 1		; 1 Indica en decimal. 
	je enDecimal
	mov eax, [cont]	; eax parametro hex2String.
	call hex2String
	jmp contStringListo
	enDecimal:
	mov eax, [cont] ; eax parametro dec2String.
	call dec2String
	contStringListo:
	; Se escribe el contador completo. 
	mov eax, 4	; sys_write
	mov ebx, [output]	
	mov ecx, contString	
	mov edx, digs	; digs denota la cantidad de digitos. 
	int 80h			; Invocacion al servicio. 
	mov [buffer], byte 58	; Se pone ":" (los dos puntos).
	call writeChar
	mov [buffer], byte 32	; Se pone " " (espacio).
	call writeChar
	ret
	
; Dado un número en eax se coloca el string correspondiente en 
; la locación dada cuyo tamaño en bytes debe ser igual a la cant de 
; digitos del número( no se agrega caracter terminador). 
; String de salida con representacion en dec.
; Modifica: eax, ebx, ecx. 
; Parámetros:
;	eax: número a pasar a string.
;	edi: locación de memoria.
dec2String:
	mov ecx, digs	; cant de digitos. 
	mov ebx, 10		; ebx=divisor en div.
	repeat_descomponer:
		xor edx, edx	; edx=0
		div ebx			; div op->eax=edx:eax/op, edx=resto.
		add edx, 48		; Para obtener valor ascii.
		mov [edi + ecx -1], dl	; Se agregan desde los menos significativos.
		dec ecx
	cmp ecx, 0
	jne repeat_descomponer
	ret

; Dado un número en eax se coloca el string correspondiente en 
; la locación dada cuyo tamaño en bytes debe ser igual a la cant de 
; digitos del número( no se agrega caracter terminador). 
; String de salida con representacion en hex.
; Modifica: eax, ebx, ecx. 
; Parámetros:
;	eax: número que se interprará en hexadecimal.
;	edi: locación de memoria.
hex2String:
	mov ecx, digs	; cant de digitos. 
	repeatShift:	; Al menos tiene un digito. 
		mov ebx, eax
		and	ebx, 0Fh	; Para obtener 4 bit menos significativos.
						; Estos representan un digito en hex. 
						; ebx tiene un digito.
		cmp ebx, 9
		jg letra
		add ebx, 48	; Para obtener valor ascii.
		jmp yaSume
		letra:
		add ebx, 55	; 65=A en ascii. 
		yaSume:
		mov [edi + ecx -1], bl	; Se agregan desde los menos significativos.
		shr	eax, 4	; Se avanza al siguiente digito hex. 
		dec ecx
	cmp ecx, 0
	jne repeatShift
	ret	

; Setea la variable enDec en 0, que significa se numera en hex. 	
enHex:
	xor eax, eax	; eax=0
	mov [enDec], al	; En enDec hay un 0, por lo que se indica se numera
					; en hex. 
	ret					
;-----------------------------------------------------------------------	
; Las rutinas que incluyen "File" en su nombre, reciben en ebx el archivo.				
openFile:
	mov eax, 5	; sys_open
	mov ecx, 2 		 
	int 80h
	ret

closeFile:
	mov eax, 6	; sys_close
	int 80h
	ret

createFile:	
	mov	eax, 8  	; sys_create
	mov	ecx, 644q	; Relativo a los permisos con los que se crea el archivo.		   
	int	80h
	ret

; Usado para borrar archivo auxiliar. 	
deleteFile:
	mov eax, 10	; sys_unlink
	int 80h
	ret

printEnter:
	mov [buffer], byte 10
	call writeChar
	ret
	
; Lee de input y deposita en buffer lo leido.
readChar:
	mov eax, 3		; sys_read
	mov ebx, [input]	
	mov ecx, buffer		
	mov edx, lBuffer
	int 80h
	ret

; Escribe el buffer en output.
writeChar:
	mov eax, 4	;sys_write
	mov ebx, [output]	
	mov ecx, buffer
	mov edx, lBuffer
	int 80h
	ret
;-----------------------------------------------------------------------
; Terminaciones, en ebx se guarda el modo (indicadas en el enunciado).
tNormal: 
    mov     eax, 1	; sys_exit
    xor     ebx, ebx 	; ebx=0, sin errores. 
    int     80h
    
tErrorArchivoEntrada: 
    mov     eax, 1	;sys_exit
    mov     ebx, 1 
    int     80h

tErrorArchivoSalida: 
    mov     eax, 1	;sys_exit
    mov     ebx, 2 
    int     80h

tErrorOtro: 
    mov     eax, 1	;sys_exit
    mov     ebx, 3 
    int     80h
	
    
