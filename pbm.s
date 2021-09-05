// subroutines for creating a Portable Bitmap File (PBM)

            .include "const.s"

            // exports
            .global pbm_write              // write array to a new PBM file

            // constants
            .equ  FILE_MODE, 0666          // file permissions; R/W everyone
            .equ  MAX_PBM_WIDTH, 70        // max line width of PBM file

            .data

magic_num:  .byte   0x50, 0x31, 0x0A       // PBM header; P1\n
line_buff:  .space  MAX_PBM_WIDTH          // line buffer for PBM output

            .text

pbm_write:                                 // ***** Write memory to new PBM file *****
                                           // r0 - pointer to memory block (of ASCII bytes)
                                           // r1 - pointer to output file name
                                           // r2 - width
                                           // r3 - height
            push  {r4-r11, lr}             // save caller's vars + return address

            push  {r1}                     // save output file name pointer
            push  {r0}                     // save memory block pointer
            mov   r10, r2                  // retain width
            mov   r11, r3                  // retain length

            mov   r7, #CREATE              // load syscall number
            mov   r0, r1                   // load file name
            mov   r1, #FILE_MODE           // load file mode
            svc   #0                       // invoke syscall

            mov   r6, r0                   // retain file descriptor
            ldr   r8, =line_buff           // pointer to line buffer
            mov   r5, #0                   // line_idx = 0
_pbm_header:
            mov   r7, #WRITE               // load syscall number
            mov   r0, r6                   // load file descriptor
            ldr   r1, =magic_num           // pointer to PBM header line 1
            mov   r2, #3                   // length of buffer
            svc   #0                       // invoke syscall
_pbm_h_width:
            mov   r1, #0                   // output only
            mov   r2, r10                  // PBM width
            bl    ascii_uint2dec           // convert uint to ASCII string. r0,r1 output

            mov   r7, #0                   // j = 0
            mov   r9, #10                  // i = 10
            sub   r9, r9, r1               // i = 10 - ASCII length
_pbm_hw_loop:
            add   r2, r9, r7               // x = (10 - ASCII length) + j
            ldrb  r2, [r0, r2]             // ascii[x]
            strb  r2, [r8, r5]             // line[line_idx] = ascii[x]
            add   r5, r5, #1               // line_idx++

            add   r7, r7, #1               // i++
            cmp   r7, r1                   // check loop condition
            blt   _pbm_hw_loop             // while (j < ascii digits)

            mov   r2, #ASCII_SPACE         // load space
            strb  r2, [r8, r5]             // line[line_idx] = ' '
            add   r5, r5, #1               // line_idx++

_pbm_h_length:
            mov   r1, #0                   // output only
            mov   r2, r11                  // PBM length
            bl    ascii_uint2dec           // convert unsigned int to ASCII. r0,r1 output

            mov   r7, #0                   // j = 0
            mov   r9, #10                  // i = 10
            sub   r9, r9, r1               // i = 10 - ASCII length
_pbm_hl_loop:
            add   r2, r9, r7               // x = (10 - ASCII length) + j
            ldrb  r2, [r0, r2]             // ascii[x]
            strb  r2, [r8, r5]             // line[line_idx] = ascii[x]
            add   r5, r5, #1               // line_idx++

            add   r7, r7, #1               // i++
            cmp   r7, r1                   // check loop condition
            blt   _pbm_hl_loop             // while (j < ascii digits)
_pbm_header_done:
            mov   r2, #ASCII_LF            // load line feed
            strb  r2, [r8, r5]             // line[line_idx] = '\n'
            add   r5, r5, #1               // line_idx++

            mov   r7, #WRITE               // load syscall number 
            mov   r0, r6                   // load file descriptor
            mov   r1, r8                   // load pointer to line buffer
            mov   r2, r5                   // load line buffer length
            svc   #0                       // invoke syscall
_pbm_body:
            pop   {r0}                     // restore memory block pointer
            mov   r9, r0                   // retain pointer
            push  {r0}                     // save memory block pointer again
            mov   r1, #0                   // block_idx = 0
            mov   r2, #0                   // i = 0
_pbm_loop_x:                               // loop over rows
            mov   r4, #0                   // line_idx = 0
            mov   r3, #0                   // j = 0
_pbm_loop_y:                               // loop over cols
            
            ldrb  r5, [r9, r1]             // block[block_idx]
        
            strb  r5, [r8, r4]             // line[line_idx] = block[block_idx]
            add   r4, r4, #1               // line_idx++
            add   r1, r1, #1               // block_idx++
            
            mov   r5, #ASCII_SPACE         // load space
            strb  r5, [r8, r4]             // line[line_idx] = ' '
            add   r4, r4, #1               // line_idx++
_pbm_next_y:                               // next col
            add   r3, r3, #1               // j++
            cmp   r3, r10                  // check loop condition
            blt   _pbm_loop_y              // while (j < width)
_pbm_next_x:                               // next row
            mov   r5, #ASCII_LF            // load line feed
            strb  r5, [r8, r4]             // line[line_idx] = '\n'
            add   r4, r4, #1               // line_idx++

            push  {r1-r2}                  // save indices
            mov   r7, #WRITE               // load syscall number
            mov   r0, r6                   // load file descriptor
            mov   r1, r8                   // load pointer to line buffer
            mov   r2, r4                   // load buffer size
            svc   #0                       // invoke syscall
            pop   {r1-r2}                  // restore indices

            add   r2, r2, #1               // i++
            cmp   r2, r11                  // check loop condition
            blt   _pbm_loop_x              // while (i < length)
_pbm_done:
            mov   r7, #CLOSE               // load syscall number
            mov   r0, r6                   // load file descriptor
            svc   #0                       // invoke syscall

            pop   {r0}                     // restore memory block pointer
            pop   {r1}                     // restore file name pointer

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

            .end                           // end of source
