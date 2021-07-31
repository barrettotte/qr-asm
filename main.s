// QR Code
//
// Restrictions:
//   - byte mode encoding only
//   - QR version 6 and below

            .data
            .balign 4

            // OS Constants
            .equ STDOUT, 0

            .equ EXIT,   1
            .equ READ,   3
            .equ WRITE,  4
            .equ OPEN,   5
            .equ CLOSE,  6
            .equ CREATE, 8

            // Program Constants
            .equ MODE_BYTE, 0b0100  // byte encoding mode
            .equ MAX_VERSION, 6     // max version supported

            // Error Messages
err_01:     .asciz "Invalid error correction level.\n"
            .equ err_01_len, (.-err_01)

err_02:     .asciz "Only QR versions 1-6 are supported.\n"
            .equ err_02_len, (.-err_02)

            // Variables
msg:        .asciz "https://github.com/barrettotte"
            .equ msg_len, (.-msg)  // TODO: from cmd line args

version:    .space 1  // QR version
eclvl_idx:  .space 1  // error correction level index (L,M,Q,H)
eclvl:      .space 1  // error correction level value (1,0,3,2)

            // Lookup Tables

tbl_eclvl:  .byte 1, 0, 3, 2        // L, M, Q, H

tbl_version: //   L, M, Q, H        // (1-6 supported)
            .byte 17, 14, 11, 7     // v1
            .byte 32, 26, 20, 14    // v2
            .byte 53, 42, 32, 24    // v3
            .byte 78, 62, 46, 34    // v4
            .byte 106, 84, 60, 44   // v5
            .byte 134, 106, 74, 58  // v6

            .text
            .global _start

_start:                           // *** program entry point ***
            mov r0, #0            // i = 0
            mov r1, #msg_len      // length
            ldr r2, =msg          // pointer
/*
msg_loop:                         // *** loop over message (debug) ***
            ldrb r3, [r2, r0]     // msg[i]
            add r0, r0, #1        // i++
            cmp r0, r1            // compare registers
            ble msg_loop          // i <= msg_len
*/

save_args:                        // *** save command line arguments to memory ***
            mov r0, #2            // TODO: get from command line args  offset 2=Q
            ldr r1, =eclvl_idx    // pointer to error correction index
            strb r0, [r1]         // store error correction index

set_eclvl:                        // *** set error correction level ***
            ldr r1, =eclvl_idx    // pointer to error correction index
            ldrb r0, [r1]         // load error correction index

            mov r1, #4            // size of error correction table
            cmp r0, r1            // compare registers
            bhi bad_eclvl         // branch if r0 > r1

            ldr  r1, =tbl_eclvl   // pointer to error correction table
            ldrb r0, [r1, r0]     // lookup error correction value
            ldr  r1, =eclvl       // pointer to error correction level
            strb r0, [r1]         // save error correction level

find_version:                     // *** find QR version ***
            mov r0, #0            // version = 0 (v1)
            ldr r1, =eclvl_idx    // pointer to error correction index
            ldrb r1, [r1]         // i = eclvl
            ldr r2, =tbl_version  // pointer to version table
            mov r3, #msg_len      // load message length
            mov r4, #MAX_VERSION  // load max QR version supported

lookup_version:                   // *** Search version lookup table ***
            ldrb r5, [r2, r1]     // capacity = tbl_version[(i * 4) + eclvl]
            cmp r5, r3            // compare capacity to msg_len
            bgt set_version       // capacity > msg_len

            add r0, r0, #1        // version += 1
            add r1, r1, #4        // i += 4
            cmp r0, r4            // compare version to max version
            blt lookup_version    // version < MAX_VERSION
            b   bad_version       // unsupported version

set_version:                      // *** set QR version (zero indexed) ***
            ldr r1, =version      // pointer to version
            strb r0, [r1]         // save version to memory

tmp_done:                         // TODO: temporary label
            b _end                // TODO: skip over errors

bad_eclvl:                        // *** invalid error correction level ***
            mov r7, #WRITE        // syscall number
            mov r0, #STDOUT       // file descriptor
            ldr r1, =err_01       // pointer to buffer address
            mov r2, #err_01_len   // length
            svc #0                // invoke syscall
            b _end                // exit program

bad_version:                      // *** invalid version ***
            mov r7, #WRITE        // syscall number
            mov r0, #STDOUT       // file descriptor
            ldr r1, =err_02       // pointer to buffer address
            mov r2, #err_02_len   // length
            svc #0                // invoke syscall
            b _end                // exit program

// TODO: generic error subroutine ?

_end:                             // *** terminate program ***
            mov r7, #EXIT         // syscall number
            mov r0, #0            // exit status
            svc #0                // invoke syscall
            .end                  // end of source
