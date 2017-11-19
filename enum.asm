;Programa "enum".
;
;Objetivo: Enumera y muestra (o graba en un nuevo archivo)
;las palabras contenidas en un archivo de texto. 
;
;Autor:Giampietri Gonzalo, Tomás Zárate.
;
;compilar:
;	$ yasm -f elf numerar.asm
;enlazar:
;	$ ld -o numerar numerar.o
;ejecutar:
;	$ ./numerar [parametros]
;-----------------------------------------------------------------------
section .data 

help	db 10
	db "Aplicación que permite enumerar cada linea de texto de un archivo de texto", 10,
	db "<Mostrar ayuda>", 10
	db 10
	db 10
	
mHelp equ 95 ;BUSCAR


;-----------------------------------------------------------------------

section .text
	global _start 	
	
_start:	;Hacer push de eax y ebx, luego descartar en pila +3 o +4
	
	pop eax			; eax: cantidad de argumentos.
	pop ebx			; ebx: nombre del programa. Lo descartamos.
	dec eax			; Se descarta el nombre del programa.
	cmp eax,0		; Se verifica si no se ingresó argumentos
	je salidaError		
	cmp eax,1
	je unArg
	jmp salidaError

unArg:
	pop ebx			; Tomo el argumento .
	mov edx, [ebx]
	cmp cl, '-'
	je posibleAyuda 	; Se ha leído "-", posible argumento de -h.
	;jmp unArchivo		; Se ha ingreaso(al parecer) el nombre de un solo archivo.

posibleAyuda: 
	
	inc ebx			; Se saltea el '-'.
	mov ecx, [ebx]
	cmp cl, 'h'
	je ayuda 		; Se ha inresado el argumento -h por consola.	
	jmp salidaError

ayuda:
	mov eax, 4		; Se llama al servicio sys_write para mostrar
	mov ebx, 0		; por consola la ayuda de la aplicación.	
	mov ecx, help		
	mov edx, mHelp		
	int 80h	
	jmp salidaExitosa		 

salidaExitosa: 
    	mov     eax, 1		; Se llama al servicio sys_exit.
    	xor     ebx, ebx 	; Setea ebx en cero, no se produce error.
    	int     80h

salidaError:			; 0 argumentos ingresados o más de 2 argumentos ingresados.
	mov eax,1
	xor ebx,ebx
	inc ebx	
	int 80h