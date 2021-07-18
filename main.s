// QR Code
//
// Restrictions
//   - byte mode only (0100)
//
// arm-none-eabi-as main.s -g -o qrcode.o ; arm-none-eabi-ld qrcode.o -o bin/qrcode
// qemu-arm -singlestep -g 1234 bin/qrcode
// arm-none-eabi-gdb
//   file bin/qrcode
//   target remote localhost:1234
//   layout regs

        .data
            .balign 4
            .equ MODE_BYTE, 0b0100

msg:        .asciz "https://github.com/barrettotte"
            .equ msg_len, (.-msg)

            .text
            .global _start

_start:
            mov r0, #0          // i = 0
            mov r1, #msg_len    // length
            ldr r2, =msg        // pointer

msg_loop:
            ldrb r3, [r2, r0]   // msg[i]
            add r0, r0, #1      // i++
            cmp r0, r1          // 
            ble msg_loop        // i <= msg_len

_end:       // ******************* terminate program
            mov r7, #1          // exit
            mov r0, #0          // exit status
            svc #0              // invoke syscall
            .end
