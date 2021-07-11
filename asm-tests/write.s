// example of writing to a file
//
// arm-none-eabi-as write.s -g -o write.o && arm-none-eabi-ld write.o -o bin/write
// qemu-arm -singlestep -g 1234 bin/write
// arm-none-eabi-gdb -ex 'target remote localhost:1234' -ex 'layout regs' bin/write

            .data

file_name:  .string "test.txt"          // output file name
message:    .string "hello world"       // output buffer
            .equ msg_len, (.-message)   // output buffer length

            .text
            .global _start
_start:
            // ******************* create file
            mov r7, #8          // create
            ldr r0, =file_name  // file name
            mov r1, #0777       // file mode
            svc #0              // invoke syscall
            mov r5, r0          // prevent fd loss

            // ******************* write to file
            mov r7, #4          // write
            mov r0, r5          // file descriptor
            ldr r1, =message    // buffer address
            mov r2, #msg_len    // length
            svc #0              // invoke syscall

            // ******************* close file
            mov r7, #6          // close
            mov r0, r5          // file descriptor
            svc #0              // invoke syscall

_end:       // ******************* terminate program
            mov r7, #1          // exit
            mov r0, #0          // exit status
            svc #0              // invoke syscall
            .end
