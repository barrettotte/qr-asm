// Generate a byte-mode QR Code (v1-4)
// 
// Program Summary:
//   - Get message, message length, and error correction level from stdin
//   - Setup QR version, capacities, etc from program arguments
//   - Pad message and split into groups/blocks based on config
//   - Perform Reed-Solomon error correction on each block of data
//   - Interleave data and error correction into a payload block
//   - Build QR code matrix using payload block and QR code specifications
//   - Output QR code matrix to image file

            .include "const.s"

            .global _start

            .data

            // error Messages
err_01:     .asciz "Invalid error correction level.\n"
            .equ err_01_len, (.-err_01)
err_02:     .asciz "Only QR versions 1-4 are supported.\n"
            .equ err_02_len, (.-err_02)

            // lookup tables
tbl_eclvl:                              // error correction level lookup
            .byte 1, 0, 3, 2            // L, M, Q, H

tbl_version: //   L, M, Q, H            // version lookup
            .byte 17, 14, 11, 7         // v1
            .byte 32, 26, 20, 14        // v2
            .byte 53, 42, 32, 24        // v3
            .byte 78, 62, 46, 34        // v4

tbl_ecprops:                            // error correction config lookup
                                        //  0: data capacity in bytes
                                        //  1: error correction words per block
                                        //  2: blocks in group 1
                                        //  3: data words in each group 1 block
                                        //  *********
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

            // variables
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
data_words: .space MAX_DATA_CAP         // all data words
dw_block:   .space MAX_DWB              // data word block
ecw_blocks: .space MAX_ECWB*MAX_G1B     // all error correction blocks
ecw_block:  .space MAX_ECWB             // error correction words block
payload:    .space MAX_DATA_CAP         // payload of message and config
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
            cmp   r0, r4                // check loop condition
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

init_dw:                                // ***** init data words *****
            mov   r1, #MODE             // load mode nibble
            lsl   r1, r1, #4            // shift nibble from low to high
            ldr   r2, =count_ind        // pointer to char count indicator
            ldrb  r3, [r2]              // load char count indicator nibble
            lsr   r4, r3, #4            // shift char indicator high nibble to low nibble
            eor   r0, r1, r4            // combine mode nibble with count indicator high nibble

            mov   r6, #0                // dw_idx = 0
            ldr   r7, =data_words       // pointer to data words array
            strb  r0, [r7, r6]          // data_words[dw_idx] = mode nibble + count_ind[LOW]
            add   r6, r6, #1            // dw_idx++

            ldr   r2, =msg              // pointer to message
            mov   r5, #msg_len          // load msg_len for loop exit
            sub   r5, r5, #1            // msg_len --; null terminator  (TODO: remove ?)
            mov   r8, #0                // msg_idx = 0
msg_loop:                               // ***** load message into data words array *****
            eor   r0, r0, r0            // reset scratch register for low nibble
            eor   r1, r1, r1            // reset scratch register for high nibble

            mov   r1, #0xF              // load bitmask 0b00001111
            and   r1, r3, r1            // mask low nibble out of msg[msg_idx-1]
            lsl   r1, r1, #4            // shift low nibble to high nibble
            
            ldrb  r3, [r2, r8]          // load msg[msg_idx]
            lsr   r4, r3, #4            // shift high nibble to low nibble
            eor   r0, r1, r4            // combine high nibble with low nibble
            strb  r0, [r7, r6]          // store combined byte at data_words[dw_idx]

            add   r8, r8, #1            // msg_idx++
            add   r6, r6, #1            // dw_idx++
            cmp   r8, r5                // check loop condition
            blt   msg_loop              // while (msg_idx < msg_len)

            mov   r1, #0xF              // load bitmask 0b00001111
            and   r1, r3, r1            // mask low nibble out of msg[msg_idx-1]
            lsl   r1, r1, #4            // shift low nibble to high nibble
            strb  r1, [r7, r6]          // store last char low nibble and zero nibble padding
            add   r6, r6, #1            // dw_idx++

            ldr   r2, =data_cap         // pointer to capacity
            ldrb  r0, [r2]              // load max capacity
pad_loop:                               // ***** pad data with alternating bytes *****
            cmp   r6, r0                // check loop condition
            bge   pad_done              // dw_idx >= data capacity, pad finished
            mov   r2, #0xEC             // set pad byte
            strb  r2, [r7, r6]          // data_words[dw_idx] = 0xEC
            add   r6, r6, #1            // dw_idx++

            cmp   r6, r0                // check loop condition
            bge   pad_done              // msg_idx >= data capacity, pad finished
            mov   r2, #0x11             // set pad byte
            strb  r2, [r7, r6]          // data_words[dw_idx] = 0x11
            add   r6, r6, #1            // msg_idx++
            b     pad_loop              // while (msg_idx < capacity)

pad_done:                               // ***** data padding finished *****
            ldr   r5, =g1b_cap          // pointer to group 1 blocks capacity (3Q = 2)
            ldrb  r5, [r5]              // load g1b_cap
            ldr   r6, =g1bw_cap         // pointer to data words per block
            ldrb  r6, [r6]              // load g1bw_cap

            mov   r9, #0                // data word offset
            mov   r10, #0               // ECW offset
            mov   r4, #0                // i = 0
block_loop:                             // ***** loop over data blocks in group *****
            ldr   r0, =data_words       // pointer to data words array
            ldr   r7, =dw_block         // pointer to data block
            mov   r8, #0                // j = 0;
dwb_loop:                               // fill data block with subset of data words
            add   r3, r9, r8            // x = j + dw offset
            ldrb  r2, [r0, r3]          // get byte at offset
            strb  r2, [r7, r8]          // block[j] = data_words[x]
dwb_next:                               // iterate to next word
            add   r8, r8, #1            // j++
            cmp   r8, r6                // check loop condition
            blt   dwb_loop              // while (j < words per block)

            add   r9, r9, r8            // dw offset += data words per block

reed_sol:                               // ***** Reed-Solomon error correction *****
            ldr   r0, =ecw_block        // pointer to error correction words block
            mov   r1, r7                // pointer to data block
            mov   r2, r6                // pointer to data words in each block
            ldr   r3, =ecwb_cap         // pointer to error correction words per block
            ldrb  r3, [r3]              // load ECW per block
            push  {r3}                  // save ECW per block; r3 gets clobbered
            bl    reed_solomon          // perform Reed-Solomon error correction
            pop   {r3}                  // restore ECW per block

            ldr   r7, =ecw_blocks       // pointer to all error correction words
            mov   r8, #0                // j = 0
ecw_loop:                               // copy ECW block to main ECW block
            ldrb  r11, [r0, r8]         // ecw_block[j]
            add   r2, r8, r10           // x = j + ECW offset
            strb  r11, [r7, r2]         // ecw_blocks[x] = ecw_block[j]
ecw_next:                               // iterate to next word
            add   r8, r8, #1            // j++
            cmp   r8, r3                // check loop condition
            blt   ecw_loop              // while (j < ECW block capacity)

            add   r10, r10, r3          // ECW offset += ECW block capacity

block_next:                             // iterate to next data block
            add   r4, r4, #1            // i++
            cmp   r4, r5                // check loop condition
            blt   block_loop            // while (i < blocks in group)

interleave:                             // ***** Interleave data and ECW blocks *****
            nop   // TODO: interleave payload data and error correction data  (3Q - 70 words)
            nop   // TODO: add remainder bits (7 remainder bits)



            nop  // ****************************************************************
            nop  //     END OF PROGRAM !!!!  TODO: remove when finished developing
            nop  // ****************************************************************
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
