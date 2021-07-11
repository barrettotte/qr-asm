// Classic hello world
//
//
// using ARM machine:
//
// arm-none-eabi-as hello.s -g -o hello.o ; arm-none-eabi-ld hello.o -o bin/hello
// qemu-arm -singlestep -g 1234 bin/hello
// arm-none-eabi-gdb
//   file bin/hello
//   target remote localhost:1234
//   layout regs
//
//
// or cross compilation:
//
// arm-linux-gnueabihf-gcc -g -static hello.s -o bin/hello

        .data

hello:      .asciz "hello world\n"
            .equ msg_len, (.-hello)

            .text
            .global _start

_start:
            // ******************* write to file
            mov r7, #4          // write
            mov r0, #1          // file descriptor (STDOUT)
            ldr r1, =hello      // buffer address
            mov r2, #msg_len    // length
            svc #0              // invoke syscall

_end:       // ******************* terminate program
            mov r7, #1          // exit
            mov r0, #0          // exit status
            svc #0              // invoke syscall
            .end
