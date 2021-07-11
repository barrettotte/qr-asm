@ Example of looping through and manipulating arrays
@
@ arm-none-eabi-as array.s -g -o array.o ; arm-none-eabi-ld array.o -o bin/array
@
@ qemu-arm -singlestep -g 1234 bin/array
@
@ arm-none-eabi-gdb
@   file bin/array
@   target remote localhost:1234
@   layout regs

.data

table:  .word 60,45,30,78,100

sum:    .word 0

hello:
    .asciz "hello world\n"
    len = .-hello


.text
    .global _start

_start:
    push {ip, lr} @ prolog

loop:

    @ write to console
    mov r0, #1      @ STDOUT file descriptor
    ldr r1, =hello  @ load address
    mov r2, #len    @ length of string
    mov r7, #4      @ write
    swi 0           @ syscall

exit:
    mov r0, #0       @ exit status
    pop     {ip, pc}    @ epilog
    @ mov     r7, #1      @ exit status
    @ svc     0           @ end
    .end
