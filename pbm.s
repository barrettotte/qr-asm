// subroutines for creating a Portable Bitmap File (PBM)

            .include "const.s"

            // exports
            .global pbm_write           // write array to a new PBM file

            // constants
            .equ  FILE_MODE, 0666       // file permissions; R/W everyone
            .equ  MAX_PBM_WIDTH, 128    // max line width of PBM file

            .equ  ASCII_LF,    0x0A     // '\n' in ASCII
            .equ  ASCII_SPACE, 0x20     // ' '  in ASCII
            .equ  ASCII_ZERO,  0x30     // '0'  in ASCII

            .data


magic_num:  .byte   0x50, 0x31, 0x0A    // PBM header; P1\n
line_buff:  .space  MAX_PBM_WIDTH       // line buffer for PBM output
ascii_buff: .space  10+1                // 2^32 capacity; 10 digits (+1 for terminator)
one_tenth:  .word   0x1999999A          // ~((2^32)/10)+1; for quick div by 10

            .text

uint_to_ascii:                          // ***** Convert uint to ASCII decimal number *****
                                        // r0 - pointer to ASCII conversion
                                        // r1 - length of ASCII conversion (output only)
                                        // r2 - unsigned integer input
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            ldr   r0, =ascii_buff       // pointer to ASCII convert buffer
            ldr   r4, =one_tenth        // pointer to magic constant
            ldr   r4, [r4]              // load 1/10
            mov   r9, #10               // 2^32 has up to ten digits
            mov   r11, #ASCII_ZERO      // offset in ASCII table for digits
            mov   r8, #0                // i = 1
_ascii_digit:
            umull r7, r5, r2, r4        // a = r5 = r3 / 10
            cmp   r5, #0                // check loop condition
            beq   _ascii_done           // while ((r3 / 10) != 0)
            
            umull r6, r10, r5, r9       // (a / b) * 10
            sub   r6, r2, r6            // r6 = r3 % 10 = a - ((a / 10) * 10))
            orr   r10, r11, r6          // convert digit to ASCII; c
            
            strb  r10, [r0, r8]         // s[i] = c
            mov   r2, r5                // go to next digit
            add   r8, r8, #1            // i++
            b     _ascii_digit          // while(1)
_ascii_done:
            orr   r10, r11, r2          // convert digit to ASCII; c
            strb  r10, [r0, r8]         // s[i] = c; highest digit
            add   r8, r8, #1            // i++
    
            mov   r7, #0                // i = 0
_reverse_loop:                          // reverse byte order of ASCII buffer
            ldrb  r10, [r0, r7]         // ascii[i]
            cmp   r7, r8                // compare i with digits
            blt   _reverse_next         // 
            mov   r10, #ASCII_ZERO      // set to ASCII zero if not set already
_reverse_next:
            sub   r11, r9, r7           // x = 10-i
            sub   r11, r11, #1          // x= 10-i-1
            strb  r10, [r0, r11]        // ascii[x] = ascii[i]

            add   r7, r7, #1            // i++
            cmp   r7, r9                // check loop condition
            blt   _reverse_loop         // while (i < 10)

            mov   r10, #0x00            // null terminator
            strb  r10, [r0, #10]        // ascii[-1] = '\0'
            mov   r1, r8                // return ASCII conversion length

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

pbm_write:                              // ***** Write memory to new PBM file *****
                                        // r0 - pointer to memory block
                                        // r1 - pointer to output file name
                                        // r2 - width
                                        // r3 - height
                                        // r4 - output file name length (pass via stack)
                                        // r5 - memory block length 
            push  {r4-r11, lr}          // save caller's vars + return address
            ldr   r4, [sp, #(0+36)]     // load 5th arg from stack; (9 regs * 4 = 36 bytes)
            @ ldr   r5, [sp, #(4+36)]     // load 6th arg from stack

            push  {r1}                  // save output file name pointer
            push  {r0}                  // save memory block pointer
            mov   r10, r2               // retain width
            mov   r11, r3               // retain length

            mov   r7, #CREATE           // load syscall number
            mov   r0, r1                // load file name
            mov   r1, #FILE_MODE        // load file mode
            svc   #0                    // invoke syscall

            mov   r6, r0                // retain file descriptor
            ldr   r8, =line_buff        // pointer to line buffer
            mov   r5, #0                // line_idx = 0
_pbm_header:
            mov   r7, #WRITE            // load syscall number
            mov   r0, r6                // load file descriptor
            ldr   r1, =magic_num        // pointer to PBM header line 1
            mov   r2, #3                // length of buffer
            svc   #0                    // invoke syscall
_pbm_h_width:
            mov   r1, #0                // output only
            mov   r2, r10               // PBM width
            bl    uint_to_ascii         // convert unsigned int to ASCII. r0,r1 output

            mov   r7, #0                // j = 0
            mov   r9, #10               // i = 10
            sub   r9, r9, r1            // i = 10 - ASCII length
_pbm_hw_loop:
            add   r2, r9, r7            // x = (10 - ASCII length) + j
            ldrb  r2, [r0, r2]          // ascii[x]
            strb  r2, [r8, r5]          // line[line_idx] = ascii[x]
            add   r5, r5, #1            // line_idx++

            add   r7, r7, #1            // i++
            cmp   r7, r1                // check loop condition
            blt   _pbm_hw_loop          // while (j < ascii digits)

            mov   r2, #ASCII_SPACE      // load space
            strb  r2, [r8, r5]          // line[line_idx] = ' '
            add   r5, r5, #1            // line_idx++

_pbm_h_length:
            mov   r1, #0                // output only
            mov   r2, r11               // PBM length
            bl    uint_to_ascii         // convert unsigned int to ASCII. r0,r1 output

            mov   r7, #0                // j = 0
            mov   r9, #10               // i = 10
            sub   r9, r9, r1            // i = 10 - ASCII length
_pbm_hl_loop:
            add   r2, r9, r7            // x = (10 - ASCII length) + j
            ldrb  r2, [r0, r2]          // ascii[x]
            strb  r2, [r8, r5]          // line[line_idx] = ascii[x]
            add   r5, r5, #1            // line_idx++

            add   r7, r7, #1            // i++
            cmp   r7, r1                // check loop condition
            blt   _pbm_hl_loop          // while (j < ascii digits)
_pbm_header_done:
            mov   r2, #ASCII_LF         // load line feed
            strb  r2, [r8, r5]          // line[line_idx] = '\n'
            add   r5, r5, #1            // line_idx++

            mov   r7, #WRITE            // load syscall number 
            mov   r0, r6                // load file descriptor
            mov   r1, r8                // load pointer to line buffer
            mov   r2, r5                // load line buffer length
            svc   #0                    // invoke syscall

_pbm_body:
            nop

_pbm_done:
            mov   r7, #CLOSE            // load syscall number
            mov   r0, r6                // load file descriptor
            svc   #0                    // invoke syscall

            pop   {r0}                  // restore memory block pointer
            pop   {r1}                  // restore file name pointer

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine
