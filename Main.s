@  Universidad del Valle de Guatemala
@  Taller de Assembler
@  Marta Ligia
@  Eric Mendoza 15002
@  Oscar Portillo 15502

.global main
.func main
main:
	ldr r0, =mensajeIngreso  @ Mensaje de ingreso
	bl puts

	IngresoSemilla:
		ldr r0, =formatoD  @ Formato entero
		ldr r1, =semilla
		bl scanf
		cmp r0, #0  @ Verificar que se haya ingresado correctamente
		beq ErrorIngreso


	/*Generar los numeros aleatorios*/
	ldr r0, addr_valores  	@ Vector para valores aleatorios
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r2, =semilla  		@ Apuntar a semilla
	ldr r1, [r1]			@ Cargar tamano
	ldr r2, [r2]	  		@ Cargar semilla
	bl lfsr			  		@ Llamar a subrutina

	/*Obtener maximo*/
	ldr r0, addr_valores  	@ Vector para valores aleatorios
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r1, [r1]			@ Cargar tamano
	bl max			  		@ Llamar a subrutina

	ldr r1, =maximo			@ Apuntar a variable maximo
	str r0, [r1]			@ Guardar maximo

	vmov s0, r0				@ Preparar para Imprimir
	vcvt.f64.f32 d5, s0		@ Convertir a doble presicion
	vmov r2, r3, d5			@ Mover a registros para Imprimir
	ldr r0, =mensajeMax
	push {r0-r5}
	bl printf
	pop {r0-r5}

	/*Obtener minimo*/
	ldr r0, addr_valores  	@ Vector para valores aleatorios
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r1, [r1]			@ Cargar tamano
	bl min			  		@ Llamar a subrutina

	ldr r1, =minimo			@ Apuntar a variable minimo
	str r0, [r1]			@ Guardar minimo

	vmov s0, r0				@ Preparar para Imprimir
	vcvt.f64.f32 d5, s0		@ Convertir a doble presicion
	vmov r2, r3, d5			@ Mover a registros para Imprimir
	ldr r0, =mensajeMin
	push {r0-r5}
	bl printf
	pop {r0-r5}

	
	/*Normalizar vector*/
	ldr r0, addr_valores  	@ Vector para valores aleatorios
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r2, =maximo  		@ Apuntar a maximo
	ldr r3, =minimo			@ Apuntar a minimo
	ldr r1, [r1]			@ Cargar tamano
	ldr r2, [r2]	  		@ Cargar maximo
	ldr r3, [r3]			@ Cargar minimo
	bl norm			  		@ Llamar a subrutina


	/*Obtener promedio*/
	ldr r0, addr_valores  	@ Vector para valores aleatorios
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r1, [r1]			@ Cargar tamano
	bl avg			  		@ Llamar a subrutina

	vmov s0, r0				@ Preparar para Imprimir
	vcvt.f64.f32 d5, s0		@ Convertir a doble presicion
	vmov r2, r3, d5			@ Mover a registros para Imprimir
	ldr r0, =mensajeAvg
	push {r0-r5}
	bl printf
	pop {r0-r5}


	/*Imprimir valores del vector*/
	ldr r0, =valores	@ Apuntar a vector
	ldr r1, =tamano  		@ Tamano del Vector
	ldr r1, [r1]			@ Cargar tamano
	bl printVec

	ldr r0, =mensajeSalida  @ Mensaje de salida
	bl puts

end:
	mov R7, #1  @  Salida correcta al sistema
	swi 0

@  Subrutinas Internas
ErrorIngreso:
	ldr r0, =mensajeError
	bl puts
	bl getchar  @ Limpiar buffer
	b IngresoSemilla


@  Redireccion de variables
addr_valores:
	.word valores

.data
	valores:
		.skip 4194304  @ (2^20)*32/8

	semilla:
		.word 0

	maximo:
		.float 0.0

	minimo:
		.float 0.0

	tamano:
		.word 1048576

	formatoF:
		.asciz "%f"

	formatoD:
		.asciz "%d"

	formatoS:
		.asciz "%s"

	mensajeIngreso:	
		.asciz "Bienvenido! \nIngrese una semmilla para generar la secuencia de numeros aleatorios:"

	mensajeSalida:	
		.asciz "\nSaludos!"

	mensajeError:	
		.asciz "Usted ha ingresado un valor incorrecto para la semilla. "

	mensajeMax:	
		.asciz "\n- El valor maximo es: %f \n"

	mensajeMin:	
		.asciz "- El valor minimo es: %f \n"

	mensajeAvg:	
		.asciz "- El valor promedio del vector normalizado es: %f \n\n"

