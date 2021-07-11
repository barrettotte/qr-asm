// Classic hello world

.data

hello:    .asciz "hello world\n"
          len = .-hello

.text
    .global main

main:
    push {ip, lr}   // prolog

    // write to console
    mov r0, #1      // STDOUT file descriptor
    ldr r1, =hello  // load address
    mov r2, #len    // length of string
    mov r7, #4      // write
    swi 0           // syscall

exit:
    mov r0, #0      // exit status
    pop {ip, pc}    // epilog
    .end