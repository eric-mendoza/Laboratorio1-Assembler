.data
.align 2
	formatoF:	.asciz " %f\n"
	deno:	.float 4.0

.text
.align 2
@ Parametros:
@	- r0: Direccion vector
@   - r1: Tamano del vector
@   - r2: Semilla
@ Retorno:
@   - Nulo
@ Uso de registros: 
@   - r3: lfsr
@   - r4: Bit menos significativo de estado inicial
@   - r5: Numero con los bits para el shift
@   - r6: Contador
@	- r7: 0x80200003
@   - s0: Convertir numero a flotante
.global lfsr
lfsr:
	push {lr}
		mov r3, r2					@ Copiar semilla como estado inicial de lfsr
		mov r6, #0 					@ Iniciar contador en 0
		ldr r7, =0x80200003			@ Cargar valor para eor
		InicioLfsr:
			and r4, r3, #0b1  		@ Almacenar ultimo bit de estado anterior
			lsr r3, r3, #1			@ Correr los bits a la derecha SIEMPRE
			cmp r4, #1				@ Verificar si el ultimo bit es 0 o 1
			eoreq r3, r3, r7		@ Cambiar los valores de los bits taps si es 1
			
			vmov s0, r3				@ Preparar para convertir
			vcvt.f32.s32 s0, s0		@ Convertir entero a flotante

			vstr s0, [r0]			@ Almacenar y correrse
			add r0, #4				@ Correrse a la siguiente posicion

			add r6, r6, #1			@ Aumentar contador
			cmp r6, r1				@ Verificar si ya se crearon todos los numeros
			bne InicioLfsr
	pop {pc}

@ Parametros:
@	- r0: Direccion vector
@   - r1: Tamano del vector
@ Retorno:
@   - Nulo
@ Uso de registros: 
@   - r4: Direccion de vector
@   - r5: Tamano del vector
@   - r6: Contador
@   - r9: Copia tamano vector
@	- s0: Cargar valor
@   - d5: Para imprimir
.global printVec
printVec:
		mov r7, lr
		mov r6, #0
		mov r4, r0
		mov r9, r1
		InicioPrint:
			vldr s0, [r4]  			@ Cargar y correrse
			add r4, #4

			vcvt.f64.f32 d1, s0		@ Convertir a doble precision
			vmov r2, r3, d1			@ Mover a registros para imprimir
			ldr r0, =formatoF		@ Cargar formato de flotante

			push {r0-r5}
			bl printf
			pop {r0-r5}

			add r6, r6, #1			@ Aumentar contador
			cmp r6, r9
			bne InicioPrint
		mov pc, r7

@ Parametros:
@	- r0: Direccion vector
@   - r1: Tamano del vector
@	- r2: ValorMaximo
@   - r3: ValorMinimo
@ Retorno:
@   - Nulo
@ Uso de registros: 
@   - r4: Direccion de vector
@   - r5: Temporal
@   - r6: Contador
@   - r7: Temporal
@   - r9: link register
@   - s0: Maximo y cargador temporal
@   - s1: Minimo
@   - s3: Maximo absoluto
@ Formula para normalizar obtenida de: http://www.unizar.es/aeipro/finder/ORGANIZACION%20Y%20DIRECCION/DD18.htm
@ V = a/(max)
.global norm
norm:
		mov r9, lr 					@ Guardar link register para volver
		mov r6, #0 					@ reiniciar contador

		vmov s0, r2 				@ Cargar y obtener valor absoluto de maximo
		vabs.f32 s0, s0 

		vmov s1, r3 				@ Cargar y obtener valor absoluto de minimo
		vabs.f32 s1, s1

		vcmp.f32 s0, s1 			@ Verificar cual es el maximo absoluto
		vmrs apsr_nzcv, fpscr		@ Copiar bandera de comparacion
		vmovgt s3, s0 				@ Mover como maximo absoluto el maximo
		vmovlt s3, s1 				@ Mover como maximo absoluto el minimo
		vmoveq s3, s1 				@ Mover cualquiera si son iguales

		/*Preparar para aritmetica vectorial*/	
		vmrs r7, fpscr 				@ Copiar el registro de banderas actual
		mov r5, #0b000111 			@ Fijar len: 8 y stride: 1
		mov r5, r5, lsl #16 		@ Correr los bits para afectar los correctos
		orr r7, r5, r7 				@ Aplicar cambios a registro con fpscr 
		vmsr fpscr, r7				@ Guardar fpscr


		InicioNorm:
			/*Cargar 8 valores en vector*/
			vldr s8, [r0]
			add r0, #4
			vldr s9, [r0]
			add r0, #4
			vldr s10, [r0]
			add r0, #4
			vldr s11, [r0]
			add r0, #4
			vldr s12, [r0]
			add r0, #4
			vldr s13, [r0]
			add r0, #4
			vldr s14, [r0]
			add r0, #4
			vldr s15, [r0]
			add r0, #4

			/*Normalizacion*/
			vabs.f32 s8, s8				@ Eliminar los numeros negativos
			vdiv.f32 s8, s8, s3 		@ Dividir dentro del maximo absoluto
			sub r0, r0, #32			@ Restaurar direccion de vector para almacenar

			/*Almacenar el resultado de normalizacion*/
			vstr s8, [r0]
			add r0, #4
			vstr s9, [r0]
			add r0, #4
			vstr s10, [r0]
			add r0, #4
			vstr s11, [r0]
			add r0, #4
			vstr s12, [r0]
			add r0, #4
			vstr s13, [r0]
			add r0, #4
			vstr s14, [r0]
			add r0, #4
			vstr s15, [r0]
			add r0, #4

			add r6, r6, #8			@ Aumentar contador
			cmp r6, r1				@ Verificar si se termino
			blt InicioNorm

		/*Retornar a escalares*/
		vmrs r7, fpscr
		mov r5, #0b000000
		mov r5, r5, lsl #16
		orr r7, r7, r5
		vmsr fpscr, r7
		mov pc, r9


@ Parametros: 
@	- r0: Direccion de vector con valores
@	- r1: Tamano de vector 
@ Retorno: 
@	- r0: Valor del numero maximo 
@ Uso de registros
@	- s0: Cargar valor actual de comparacion del vector
@	- s1: Valor maximo momentaneo (inicia en 0)
@	- r5: Contador (inicia en 0)
.global max
max:
	mov r9, lr
	mov r5, #0
	vldr s1, [r0]				@ Iniciar s1 con el primer valor
	InicioComparacion:
		vldr s0, [r0]			@ Cargar primer valor
		add r0, #4				@ Correrse a la siguiente posicion

		vcmp.f32 s0, s1  		@ Comparar maximo actual con valor actual
		vmrs apsr_nzcv, fpscr	@ Copiar bandera de comparacion
		vmovgt s1, s0  			@ Intercambiar si es mayor

		add r5, r5, #1 			@ Aumentar contador
		cmp r5, r1
		blt InicioComparacion

		vmov r0, s1 			@ Mover maximo a r0
	mov pc, r9

@ Parametros: 
@	- r0: Direccion de vector con valores
@	- r1: Tamano de vector 
@ Retorno: 
@	- r0: Valor del numero maximo 
@ Uso de registros
@	- s0: Cargar valor actual de comparacion del vector
@	- s1: Valor minimo momentaneo (inicia en 0)
@	- r5: Contador (inicia en 0)
.global min
min:
	mov r9, lr 					@ Guardar link register para volver
	mov r5, #0
	vldr s1, [r0]				@ Iniciar s1 con el primer valor
	InicioComparacion2:
		vldr s0, [r0]			@ Cargar primer valor
		add r0, #4				@ Correrse a la siguiente posicion

		vcmp.f32 s0, s1  		@ Comparar minimo actual con valor actual
		vmrs apsr_nzcv, fpscr	@ Copiar bandera de comparacion
		vmovlt s1, s0  			@ Intercambiar si es menor

		add r5, r5, #1 			@ Aumentar contador
		cmp r5, r1
		blt InicioComparacion2

	vmov r0, s1 			@ Mover minimo a r0
	mov pc, r9 					@ Volver a programa principal



@ Parametros:
@	- r0: Direccion de vector con valores
@	- r1: Tamano
@ Retorno:
@	- r0: Promedio
@ Uso de registros:
@	- r5: Contador
@   - s8, d9: Sumatoria
@   - s6, d10: #4.0
@   - s10: Cargar valores
@   - d8, s4: resultado promedio
.global avg
avg:
	push {lr}
	mov r5, #0
	vmov s8, r5
	InicioSuma:
		vldr s10,[r0]			@ Cargar primer nota
		vadd.f32 s8, s8, s10	@ Sumar a valor anterior
		add r0, r0, #4			@ Correrse a siguiente valor

		add r5, r5, #1			@ Aumentar contador
		cmp r5, r1				@ Verificar si ya termino
		bne InicioSuma

	vmov s0, r1					@ Cargar divisor (tamano de vector)
	vcvt.f32.u32 s0,s0 			@ Convertir divisor en float
	vdiv.f32 s4, s8, s0 		@ Dividir: sumatoria/longitud vector

	vmov r0, s4
	pop {pc}

