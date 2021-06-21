/* Example of looping through an array */

.arch       armv8-a
.syntax     unified

.text
    .global main
    .align  4

    main:
        push {ip, lr}
        
        ldr r0, =hello
        bl printf

        mov r0, #41
        add r0, r0, #1

        pop {ip, lr}
        bx lr

.data
    my_array:
        .byte 0x08
        .byte 0x05
        .byte 0x03
        .byte 0x02
        .byte 0x07
        .byte 0x01
        .byte 0x06
        .byte 0x04