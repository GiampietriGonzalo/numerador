;----------------------------------------------------AUTORES------------------------------------------------------------------------------------------------------------------------
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~[Giampietri Gonzalo Emanuel - Tomás Zárate]------------------------------------------------------------------------------------------------------


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< DATOS NO INICIALIZADOS >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

section .bss
	
	contadorString resb 4		; El contador tendrá 4 dígitos ya que el número máximo de líneas es 9999.
	buffer resb 1			; buffer donde se colocan todos los caracteres a escribir/imprimir.
					
	cantBuffer equ 1		; tamaño del buffer. 

	
	archEntrada resd	1	; ruta del archivo de entrada ingresado por el usuario(1er argumento).
	descriptorArchivo1 resd	1	; File descriptor del archivo archEntrada. 					
	
	archSalida resd	1		; ruta del archivo de salida ingresado por el usuario(2do argumento).
	descriptorArchivo2 resd	1	; File descriptor del archivo archSalida.
	
	entrada dd 1			; File descriptor del archivo de entrada. Establece desde donde se len líneas.
	salida 	dd 1			; File descriptor del archivo de salida. Establece desde donde se escribiran las líneas nuemradas.	




;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< DATOS INICIALIZADOS >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


section .data 

	contador dd 1		;contador lineas.
	

	limite	equ 9999	;Limite de lineas en el archivo de entrada. 
	cantidadDigitos	equ 4	;Se lee hasta 999 líneas de un archivo ~> máximo digitos del contador de líneas = 3
	


	;----------------TEXTO DE AYUDA------------------------------------------------------------------------------------------
	
	mHelp	db " ", 10,
		db "1- Programa para enumerar líneas cada linea de texto de una entrada provista por el usuario.", 10,
		db "2- Sintaxys de invocación: enum [ -h ] | archivo entrada [ archivo salida ]", 10,
		db "3- Los parámetros entre [] refieren a parametros opcionales.", 10,
		db "4- Las opciones separadas por | son alternativas.", 10,
		db "5- El parámetro -h muestra éste mensaje de ayuda.", 10,
		db "6- Si solo se igresa el nombre de un archiv de salida, entonces: ", 10,
		db "	a- Se procede a enumerar las líneas contenidas en el archivo.", 10,
		db "	b- Luego se muestran las líneas enumeras por consola, junto con el total de líneas del archivo.", 10,
		db "7- Si se ingresa los nombres de ambos archivos (entrada y salida), entonces: ", 10,
		db "	a- Se procede a enumerar las líneas contenidas en el archivo de entrada.", 10,
		db "	b- Luego se escriben las líneas enumeradas en el archivo de salida.", 10,
		db " ", 10,
		db "AUTORES: Giampietri Gonzalo Emanuela & Tomás Zárate ", 10,
    
		
	tHelp equ $-mHelp



	;-----------------MENSAJE FIN DE enumerar LINEAS-------------------------------------------------------------------------

	mContadorLineas db "Cantidad de líneas: "
	tContadorLineas equ $-mContadorLineas


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< CUERPO DEL PROGRAMA >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

section .text
	global _start 	
	
_start:
;Inicio del programa

	pop EAX				; EAX contiene la cantidad de argunmentos
	pop EBX				; EBX contiene el nombre del programa.
	dec EAX				; se descarta el nombre del programa. 

	cmp EAX, 0			; Se verifica si no se ingresó argumentos
	je salidaError	
							
	cmp EAX, 1			;Se ingresó un argumento.
	je unArgumento	
	
	cmp EAX, 2			;Se ingresaron dos argumentos.
	je dosArchivos

	
	jmp salidaError			;Se ingresaron demasiados argumentos.

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~< UN ARGUMENTO >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

unArgumento:
; El usuario ha ingreso un solo argumento.

	pop EBX				; Se extrae el argumento ingresado. 
	mov ECX, [EBX]
	cmp CL, '-'
	je posibleAyuda;		; Si se ingreso un "-" como parámetro -> posible argumento de ayuda.
	push EBX			; Push del parámetro.
	jmp mostrarXConsola		; Hay una ruta de archivo.

;--------------------------------------------------------------------------------------------------------------------------------
								
posibleAyuda:
; Se ingreso un "-" como parámetro -> posible argumento de ayuda.	

	inc EBX				; Descartamos el '-'.
	mov ECX, [EBX]
	cmp CL, 'h'
	je mostrarAyuda			; Se ha inresado el argumento -h por consola.	
	jmp salidaError

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

mostrarAyuda:
; Muestra el contenido del texto de ayuda.
	
	mov EAX, 4			; Se prepara todo para mostrar la ayuda por consola con sys_write.
	mov EBX, 0			; EBX=0 es la consola.	
	mov ECX, mHelp			; Texto de ayuda
	mov EDX, tHelp		 	; Tamaño del texto de ayuda.
	int 80h				; Llamada al servicio. 
	
	jmp salidaExitosa		; Procede a finalizar correctamente el programa.

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

mostrarXConsola: 
; Se intodujo un solo argumento que corresponde al nombre de un archivo de entrada.
; Se prodecede a procesar el archivo y mostrar el resultado por consola. 

	pop EBX				; Tomo la ruta del archivo. 
	mov [archEntrada], EBX		; Guardo la ruta en archEntrada. 
	
	call abrirArchivo		
	cmp EAX, 0
	jl errorDeArchivoEntrada	; Error al abrir el archivo de entrada.
	
	mov [entrada], EAX		; ArchivoEntrada es la  entrada.
	mov [descriptorArchivo1], EAX	; Se guarda fd.
	mov [salida], byte 0		; Se muestra la salida por consola.
	
	call saltoDeLinea		
	call enumerarLineas		; Se numera lo leido del archivo en pantalla. 
	call saltoDeLinea
	
	call saltoDeLinea		; Salto de línea para que quede mejor visualmente. Se para la última lína con el
					; resutado final.
	
	call escribirResultadoFinal
	call saltoDeLinea		; Salto de línea para separar el resultado final del promt.

	mov EBX, [descriptorArchivo1]	; Se cierra archivoEntrada. 	
	call cerrarArchivo	
	
	cmp EAX, 0
	jl errorDeArchivoSalida		; Se cerró con error.
	
	jmp salidaExitosa	
			


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< DOS ARGUMENTOS >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	  
dosArchivos:
; Se ingresaron dos archivos como argumentos.				
; En la pila están las rutas de los archivos.
	
	pop EBX						; EBX = archivo de entrada. 
	mov [archEntrada], EBX				; archEntrada = archivo de entrada.
	
	pop EBX						; EBX = archivo de salida.
	mov [archSalida], EBX				; archSalida = archivo de salida. 
	
	mov EBX, [archEntrada]				; abrir el archivo de entrada. 
	call abrirArchivo
	
	cmp EAX, 0
	jl errorDeArchivoEntrada			; error al abrir el archivo de entrada. 
	
	mov [entrada], EAX
	mov [descriptorArchivo1], EAX			; se conserva el descriotor del archivo 1.
	
	mov EBX, [archSalida]				; abrir archivo de salida. 
	call abrirArchivo
	
	cmp EAX, 0
	jl errorDeArchivoSalida				; error al abrir el achivo de salida. 
	
	mov [salida], EAX
	mov [descriptorArchivo2], EAX			; se conserva el descriotor del archivo 2.

	call enumerarLineas				; se numera las líneas del archivo de entrada en el archivo de salida.
	
	call saltoDeLinea
	call saltoDeLinea
	call escribirResultadoFinal
	

	mov EBX, [descriptorArchivo1]			; cerrar archivo de entrada. 	
	call cerrarArchivo
	cmp EAX, 0
	jl errorDeArchivoEntrada			; error al cerrar el archivo de entrada.
	
	mov EBX, [descriptorArchivo2]			; cerrar archivo de salida. 	
	call cerrarArchivo	
	cmp EAX, 0
	jl errorDeArchivoSalida				; error al cerrar el archivo de salida.
	
	jmp salidaExitosa


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< AUXILIARES >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pasarNumAChar:
; Mapea el contador de numéro a su código ascci correspondiente.	
; En EAX está el número que se tiene que pasar a EAX.
; ESI registro donde se almacenará el caracter leído del archviodo de entrada.

	mov ECX, cantidadDigitos			; cantidadDigitos=4. 
	mov EBX, 10					; EBX es el divisor.
	
	call obtenerASCII				; Obtiene el codigo ascci del contador.

	ret						; volver a dónde llamaron a pasarNumChar.



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

obtenerASCII:
 ;ECX: cantidad de dígitos (4).
	xor EDX, EDX					; En EDX se almacenará el resto de la división de abajo
	div EBX						; Divide a EAX por EBX(10). En EDX está el resto.
	add EDX, 48					; Para obtener valor ascii.
	mov [ESI + ECX-1], DL				; se coloca el número de derecha a izquierda (en posiciones).
	dec ECX

	cmp ECX, 0					; ¿Se procesaron los 4 dígitos?
	jne obtenerASCII				; ECX!=0

	ret

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

enumerarLineas:		

; lee el archivo de entrada, numera las líneas y las rescribe (con su respecivo número de línea).
; archivoEntrada y archivoSalida ya están abiertos.
; entrada/salida son sus respectivos descriptores.

	call leer					; Lee primer caracter del archivo.
	call loopArchivo					
	ret						 
	
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------				

loopArchivo:

; Ciclo que permite leer el archivo de entrada y numerar sus líneas.
; Primero se agrega el contador en la "salida" (sea consola u otro archivo) y lo suma.
; Luego, se procede a leer la siguiente línea del archivo y a copiar sus caracteres en "salida". 
		
	cmp EAX,  0				; Si EAX=0 ~> fin de arhivo.
	je finArchivo1		
		
	mov EBX, [buffer]
	push EBX 				; Push para guardarlo, en agregarContador se va a utilizar.
	call agregarContador			; Agrega el contador al principio de la línea.
		
	pop EBX					; Tomo el buffer.
	mov [buffer], bl

	mov EAX, [contador]			; contador++
	inc EAX			
	mov [contador], EAX

	call loopEnter				; Se lee y se imprime/escribe una línea caracter por caracter hasta leer un 
						; salto de línea (enter).
		
	
	jmp loopArchivo				; Seguir leyendo el archivo de entrada.	
	
	finArchivo1:	
	     ret				; Vuelve hasta a donde llamaron enumerarLineas.

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

loopEnter:				

; Ciclo que lee una línea caracter por caracter hasta leer salto de línea (enter).
; Luego agrega un salto de línea.
	
	mov EAX, [buffer]
	cmp AL,  10			; si al=10(enter/finDeLínea) ~> escribir un enter en el archivo.
	je leerEnter	 
			
	call escribir			; escribir el caracter en el archivo de salida. 
	call leer			; lee el proximo caracter.

	cmp AL,  0			; 0=null. Si el archivo no termina en enter, terminaría en un null. 
	je finArchivo1		
		
	jmp loopEnter
			
	ret

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

leerEnter: 
	
; Se leyó un salto de línea, se agrega otro a los procesado para compensar el salto de línea leido.

	call escribir			; Escribe el enter que faltaría. 
	call leer			; Lee el siguiente caracter del archivo (El primero de la nueva línea).
	ret

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

escribirResultadoFinal:
; Escribe la cantidad de líneas enumeradas.
; Si salida=0 entonces se escribe por consola, caso contrario se escribe por el archivo de salida.
		
	mov EAX, 4			; Se prepara todo para mostrar el resultado final por consola con sys_write.
	mov EBX, [salida]		; EBX=0 es la consola.	
	mov ECX, mContadorLineas	; Texto del resultado final.
	mov EDX, tContadorLineas	; Tamaño del texto del resultado final.
	int 80h				; Llamada al servicio.
		
	call agregarContadorSolo	; Imprime el contador sin dos puntos y espaciado.	
	
	cmp [salida],byte 0		; Si se imprime por consola, se agregar un salto extra mejorar la lectura del programa.
	je saltoDeLinea
	
	ret	

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< MANIPULACION DE ARCHIVOS >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					

abrirArchivo:	
; Abre el archivo (de entrada o de salida) especificado en EBX.	
; El archivo se encuentra en EBX	

	mov EAX, 5					; Se procede a hacer sys_open.
	mov ECX, 2 					; Modo de acceso read-write.	 
	int 80h
	
	ret						; Vuelve a donde llamaron abrirArchivo

;----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

cerrarArchivo:
; Cierra el archivo (de entrada o de salida) especificado en EBX.		
; En EBX está el archivo a cerrar.

	mov EAX, 6					; Se llama al servicio sys_Close
	int 80h
	

	ret						; volver a dónde llamaron a cerrarArchivo.

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< ESCRITURA Y LECTURA DE CARACTERES >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

saltoDeLinea:			

; Se imprime un salto de línea.
	
	mov [buffer], byte 10
	call escribir
	ret
	
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

leer:				
; Lee un caracter y lo mueve al buffer.
	
	mov EAX, 3					; se prepara todo para sys_read.
	mov EBX, [entrada]	
	mov ECX, buffer					; En el buffer se almcenará el caracter.	
	mov EDX, cantBuffer				; Especifica el tamaño del buffer.
	int 80h						; Llamada al  Servicio sys_read
	
	ret						; Vuelve a donde llamaron a leer.

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
escribir:						
; Escribe lo que hay en el buffer en el archivo de salida o en la consola.	
	
	mov EAX, 4					; Se prepara todo para utlizar sys_write.
	mov EBX, [salida]				; Si [Salida] = 0 -> se imprime por consola 				
	mov ECX, buffer					;	else -> Se escribe en el archivo de salida.
	mov EDX, cantBuffer
	int 80h						; Llamada al  Servicio sys_write
	
	ret

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

agregarContador:
; Escribe el contador de la línea. Con dos puntos y espacio.		
	
	mov ESI, contadorString				
	mov EAX, [contador] 				; Para pasarNumAChar.
	call pasarNumAChar

	mov EAX, 4					; Usar sys_write para escribir el contador.
	mov EBX, [salida]	
	mov ECX, contadorString				; Límite de líneas 500
	mov EDX, cantidadDigitos			; 4 digitos. 
	int 80h						; Servicio
 
	mov [buffer], byte 58				; ascci(58)=dos puntos.
	call escribir					; Escribe los dos puntos.
	
	mov [buffer], byte 32				; ascci(32)= espaciado.
	call escribir					; Escribe el espaciado.		
	
	ret						; Vuelve a dónde llamaron a agregarContador;


agregarContadorSolo:
; Agrega el contrador de línea sin dos puntos y espacio.
	mov EAX, [contador]				; contador--
	dec EAX			
	mov [contador], EAX

	mov ESI, contadorString				
	mov EAX, [contador] 				; Para pasarNumAChar.
	call pasarNumAChar

	mov EAX, 4					; Usar sys_write para escribir el contador.
	mov EBX, [salida]				; Si salida = 0 -> se escribe en consola, else se escribe en archSalida.
	mov ECX, contadorString				; Límite de líneas 9999
	mov EDX, cantidadDigitos			; 4 digitos. 
	int 80h						; Llamada al  Servicio sys_write

	ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< ERRORES Y SALIDAS >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
errorDeArchivoEntrada: 
; Terminación anormal del programa producida por algún error en el archivo de entrada.
; Error al abrir/cerrar el archivo de entrada.
		
    mov     EAX, 1					; Para usar sys_exit y salir del programa
    mov     EBX, 1 					; eb=1 error en el archivo de entrada
    int     80h						; Llamada al  Servicio sys_exit

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

errorDeArchivoSalida: 
; Terminación anormal producida por algún error en el archivo de salida.
; Error al abrir/cerrar el archivo de salida.

    mov     EAX, 1					; Para usar sys_exit y salir del programa
    mov     EBX, 2 					; EBX=2 error en el archivo de salida
    int     80h						; Llamada al  Servicio sys_exit

;------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

salidaExitosa:
;Terminación normal del programa. 
    	
	mov     EAX, 1			; Se llama al servicio sys_exit.
    	xor     EBX, EBX 		; Setea EBX en cero, no se produce error.
    	int     80h			; Llamada al  Servicio sys_exit

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

salidaError:			
; Terminación anormal correspondiente a otros tipos de errores.
; 0 argumentos ingresados o más de 2 argumentos ingresados.
	
	mov EAX,1			; Se llama al servicio sys_exit.
	mov EBX,3			; EBX=3 ~> Error por ots causas
	int 80h				; Llamada al  Servicio sys_exit

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~< FIN DEL PROGRAMA >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
    
