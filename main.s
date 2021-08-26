// Generate a byte-mode QR Code (v1-4)

            .include "const.inc"

            .global _start

            .data

            // Error Messages
err_01:     .asciz "Invalid error correction level.\n"
            .equ err_01_len, (.-err_01)

err_02:     .asciz "Only QR versions 1-4 are supported.\n"
            .equ err_02_len, (.-err_02)

            // Variables
msg:        .asciz "https://github.com/barrettotte"
            .equ msg_len, (.-msg)       // (30 chars) TODO: from cmd line args

version:    .space 1                    // QR code version
eclvl_idx:  .space 1                    // error correction level index (L,M,Q,H)
eclvl:      .space 1                    // error correction level value (1,0,3,2)
ecprop_idx: .space 1                    // error correction properties index

data_cap:   .space 1                    // max capacity for data words
ecwb_cap:   .space 1                    // error correction words per block
g1b_cap:    .space 1                    // number of blocks in group 1
g1bw_cap:   .space 1                    // data words in each group 1 block

count_ind:  .space 1                    // character count indicator byte
payload:    .space MAX_DATA_CAP         // payload of message and config

                                        // polynomials = [degree byte, term bytes]
m_poly:      .space MAX_DATA_CAP+1      // message polynomial
g_poly:      .space MAX_ECWB+2          // generator polynomial

            // Lookup Tables
tbl_eclvl:                              // error correction level lookup
            .byte 1, 0, 3, 2            // L, M, Q, H

tbl_version: //   L, M, Q, H            // version lookup
            .byte 17, 14, 11, 7         // v1
            .byte 32, 26, 20, 14        // v2
            .byte 53, 42, 32, 24        // v3
            .byte 78, 62, 46, 34        // v4

tbl_ecprops:                            // error correction config lookup
            //    0: data capacity in bytes
            //    1: error correction words per block
            //    2: blocks in group 1
            //    3: data words in each group 1 block
            .byte 19, 7, 1, 19          //  0: v1-L
            .byte 16, 10, 1, 16         //  1: v1-M
            .byte 13, 13, 1, 13         //  2: v1-Q
            .byte 9, 17, 1, 9           //  3: v1-H
            .byte 34, 10, 1, 34         //  4: v2-L
            .byte 28, 16, 1, 28         //  5: v2-M
            .byte 22, 22, 1, 22         //  6: v2-Q
            .byte 16, 28, 1, 16         //  7: v2-H
            .byte 55, 15, 1, 55         //  8: v3-L
            .byte 44, 26, 1, 44         //  9: v3-M
            .byte 34, 18, 2, 17         // 10: v3-Q
            .byte 26, 22, 2, 13         // 11: v3-H
            .byte 80, 20, 1, 80         // 12: v4-L
            .byte 64, 18, 2, 32         // 13: v4-M
            .byte 48, 26, 2, 24         // 14: v4-Q
            .byte 36, 16, 4, 9          // 15: v4-H

tbl_rem:    .byte 0, 7, 7, 7            // remainder lookup (v1-4)

            .text

_start:                                 // ***** program entry point *****
            mov   r0, #0                // i = 0
            mov   r1, #msg_len          // length;  TODO: get from command line args
            ldr   r2, =msg              // pointer; TODO: get from command line args

save_args:                              // ***** save command line arguments to memory *****
            mov   r0, #2                // TODO: get from command line args  offset 2=Q
            ldr   r1, =eclvl_idx        // pointer to error correction index
            strb  r0, [r1]              // store error correction index

set_eclvl:                              // ***** set error correction level *****
            ldr   r1, =eclvl_idx        // pointer to error correction index
            ldrb  r0, [r1]              // load error correction index
            mov   r1, #4                // size of error correction table
            cmp   r0, r1                // check error correction
            bhi   bad_eclvl             // branch if error correction invalid

            ldr   r1, =tbl_eclvl        // pointer to error correction table
            ldrb  r0, [r1, r0]          // lookup error correction value
            ldr   r1, =eclvl            // pointer to error correction level
            strb  r0, [r1]              // save error correction level

find_version:                           // ***** find QR version *****
            mov   r0, #0                // version = 0 (v1)
            ldr   r1, =eclvl_idx        // pointer to error correction index
            ldrb  r1, [r1]              // i = eclvl
            ldr   r2, =tbl_version      // pointer to version table
            mov   r3, #msg_len          // load message length
            sub   r3, r3, #1            // msg_len --; null terminator  (TODO: remove ?)
            ldr   r4, =count_ind        // pointer to char count indicator
            strb  r3, [r4]              // save msg_len-1 as char count indicator byte
            mov   r4, #MAX_VERSION      // load max QR version supported

version_loop:                           // ***** search version lookup table *****
            ldrb  r5, [r2, r1]          // msg capacity = tbl_version[(i * 4) + eclvl]
            cmp   r5, r3                // compare msg capacity to msg_len
            bgt   set_version           // if (msg capacity > msg_len)

            add   r0, r0, #1            // version += 1
            add   r1, r1, #4            // i += 4
            cmp   r0, r4                // compare version to max version
            blt   version_loop          // while (version < MAX_VERSION)
            b     bad_version           // unsupported version encountered

set_version:                            // ***** set QR version (zero indexed) *****
            ldr   r1, =version          // pointer to version
            strb  r0, [r1]              // save version to memory

set_ec_props:                           // ***** set error correction properties *****
            lsl   r0, #4                // i = version * 16
            ldr   r1, =eclvl_idx        // pointer to error correction level index
            ldrb  r1, [r1]              // load error correction level index
            lsl   r1, #2                // j = eclvl_idx * 4
            add   r0, r0, r1            // i += j == (version * 16) + (eclvl_idx * 4)

            ldr   r1, =ecprop_idx       // pointer to error correction properties index
            strb  r0, [r1]              // save error correction properties index
            ldr   r1, =tbl_ecprops      // pointer to error correction properties
            ldrb  r2, [r1, r0]          // load data word capacity from EC properties
            ldr   r3, =data_cap         // pointer to data word capacity
            strb  r2, [r3]              // save data word capacity

            add   r0, r0, #1            // increment index to ECW per block
            ldr   r3, =ecwb_cap         // pointer to max ECWs per block
            ldrb  r2, [r1, r0]          // load ECW per block from EC properties
            strb  r2, [r3]              // save ECW per block

            add   r0, r0, #1            // increment index to group 1 blocks
            ldr   r3, =g1b_cap          // pointer to max blocks in group 1
            ldrb  r2, [r1, r0]          // load group 1 blocks from EC properties
            strb  r2, [r3]              // save group 1 blocks

            add   r0, r0, #1            // increment index to group 1 words per block
            ldr   r3, =g1bw_cap         // pointer to max data words in each group 1 block
            ldrb  r2, [r1, r0]          // load group 1 words per block from EC properties
            strb  r2, [r3]              // save group 1 words per block

init_payload:                           // ***** init QR code payload *****
            mov   r1, #MODE             // load mode nibble
            lsl   r1, r1, #4            // shift nibble from low to high
            ldr   r2, =count_ind        // pointer to char count indicator
            ldrb  r3, [r2]              // load char count indicator nibble
            lsr   r4, r3, #4            // shift char indicator high nibble to low nibble
            eor   r0, r1, r4            // combine mode nibble with count indicator high nibble

            mov   r6, #0                // payload_idx = 0
            ldr   r7, =payload          // pointer to payload
            strb  r0, [r7, r6]          // payload[payload_idx] = mode nibble + count_ind[LOW]
            add   r6, r6, #1            // payload_idx++

            ldr   r2, =msg              // pointer to message
            mov   r5, #msg_len          // load msg_len for loop exit
            sub   r5, r5, #1            // msg_len --; null terminator  (TODO: remove ?)
            mov   r8, #0                // msg_idx = 0

inject_msg:                             // ***** inject message into payload *****
            eor   r0, r0, r0            // reset scratch register for low nibble   TODO: needed?
            eor   r1, r1, r1            // reset scratch register for high nibble  TODO: needed?

            mov   r1, #0xF              // load bitmask 0b00001111
            and   r1, r3, r1            // mask low nibble out of msg[msg_idx-1]
            lsl   r1, r1, #4            // shift low nibble to high nibble
            
            ldrb  r3, [r2, r8]          // load msg[msg_idx]
            lsr   r4, r3, #4            // shift high nibble to low nibble
            eor   r0, r1, r4            // combine high nibble with low nibble
            strb  r0, [r7, r6]          // store combined byte at payload[payload_idx]

            add   r8, r8, #1            // msg_idx++
            add   r6, r6, #1            // payload_idx++
            cmp   r8, r5                // compare msg_idx with msg_len
            blt   inject_msg            // while (msg_idx < msg_len)

inject_done:                            // ***** finish message injection *****
            mov   r1, #0xF              // load bitmask 0b00001111
            and   r1, r3, r1            // mask low nibble out of msg[msg_idx-1]
            lsl   r1, r1, #4            // shift low nibble to high nibble
            strb  r1, [r7, r6]          // store last char low nibble and zero nibble padding
            add   r6, r6, #1            // payload_idx++

            ldr   r2, =data_cap         // pointer to capacity
            ldrb  r0, [r2]              // load max capacity

pad_loop:                               // ***** pad payload with alternating bytes *****
            cmp   r6, r0                // compare payload size with data capacity
            bge   reed_sol              // msg_idx >= data capacity, pad finished
            mov   r2, #0xEC             // set pad byte
            strb  r2, [r7, r6]          // payload[msg_idx] = 0xEC
            add   r6, r6, #1            // msg_idx++

            cmp   r6, r0                // compare payload size with data capacity
            bge   reed_sol              // msg_idx >= data capacity, pad finished
            mov   r2, #0x11             // set pad byte
            strb  r2, [r7, r6]          // payload[msg_idx] = 0x11
            add   r6, r6, #1            // msg_idx++
            b     pad_loop              // while (msg_idx < capacity)

reed_sol:                               // ***** Reed-Solomon error correction *****
            mov   r4, #0                // i = 0
            ldr   r5, =g1b_cap          // pointer to group 1 blocks capacity (3Q = 2)
            ldrb  r5, [r5]              // load g1b_cap

            nop   // TODO: do i need a chunk of memory for blocks?  blocks: .space MAX_DATA_CAP
            nop   // ---begin loop over g1b_cap ... while(i < g1b_cap)

            ldr   r0, =m_poly           // pointer to message polynomial
            ldr   r2, =payload          // pointer to payload
            ldr   r3, =g1bw_cap         // pointer to block data word size (3Q = 17)
            ldrb  r3, [r3]              // load block data word size
            bl    new_mpoly             // call subroutine to create message polynomial

            ldr   r0, =g_poly           // pointer to generator polynomial
            ldr   r2, =ecwb_cap         // pointer to ECW capacity
            ldrb  r2, [r2]              // load error correction word capacity
            bl    new_gpoly             // call subroutine to create generator polynomial

            nop   // ---end loop over g1b_cap

            nop   // TODO: interleave payload data and error correction data  (3Q - 70 words)
            nop   // TODO: add remainder bits (7 remainder bits)

            nop   // I
            nop   // want
            nop   // to
            nop   // die
            nop   //
            b     _end

bad_eclvl:                              // ***** invalid error correction level *****
            ldr   r1, =err_01           // pointer to buffer address
            mov   r2, #err_01_len       // length
            b     error_exit            // exit program with error

bad_version:                            // ***** invalid version *****
            ldr   r1, =err_02           // pointer to buffer address
            mov   r2, #err_02_len       // length
            b     error_exit            // exit program with error

error_exit:                             // ***** exit with error *****
            mov   r7, #WRITE            // syscall number
            mov   r0, #STDOUT           // file descriptor
            svc   #0                    // invoke syscall (r1,r2 = msg,len)
            mov   r0, #1                // set status code as error
            mov   r7, #EXIT             // syscall number
            mov   r1, #1                // error status
            svc   #0                    // invoke syscall

_end:                                   // ***** terminate program *****
            mov   r7, #EXIT             // syscall number
            mov   r0, #0                // successful exit
            svc   #0                    // invoke syscall

            .end                        // end of source
