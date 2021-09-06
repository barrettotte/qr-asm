// subroutines for various ASCII utilities

            .include "const.inc"

            // exports
            .global ascii_uint2dec         // convert uint to ASCII decimal string
            .global ascii_ubyte2bin        // convert ubyte to ASCII binary string

            .data

aui2d_buf:  .space  10+1                   // 2^32 capacity; 10 digits (+1 for terminator)
one_tenth:  .word   0x1999999A             // ~((2^32)/10)+1; for quick div by 10

            .text

ascii_ubyte2bin:                           // ***** Convert ubyte to ASCII binary string *****
                                           // r0 - pointer to ASCII conversion
                                           // r1 - unused
                                           // r2 - ubyte input
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r4, #8                   // size = 8
            mov   r5, #1                   // mask = 1
            mov   r8, #0                   // i = 0
_aub2b_digit:                              // loop over each binary digit
            and   r6, r2, r5               // mask ubyte to get single digit
            cmp   r6, r5                   // compare mask with
            beq   _aub2b_one               // if bit is set, skip over next 2 lines
            mov   r7, #ASCII_ZERO          // c = '0'
            b     _aub2b_next              // iterate
_aub2b_one:
            mov   r7, #ASCII_ONE           // c = '1'
_aub2b_next:
            sub   r6, r4, r8               // x = 8 - i
            sub   r6, r6, #1               // offset 1 (null terminator)
            strb  r7, [r0, r6]             // ascii[8-i-1] = c
            lsl   r5, r5, #1               // shift mask bit

            add   r8, r8, #1               // i++
            cmp   r8, r4                   // check loop condition
            blt   _aub2b_digit             // while (i < 8)

_aub2b_done:
            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

ascii_uint2dec:                            // ***** Convert uint to ASCII decimal string *****
                                           // r0 - pointer to ASCII conversion
                                           // r1 - length of ASCII conversion (output only)
                                           // r2 - unsigned integer input
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            ldr   r0, =aui2d_buf           // pointer to ASCII convert buffer
            ldr   r4, =one_tenth           // pointer to magic constant
            ldr   r4, [r4]                 // load 1/10
            mov   r9, #10                  // 2^32 has up to ten digits
            mov   r11, #ASCII_ZERO         // offset in ASCII table for digits
            mov   r8, #0                   // i = 1
_aui2d_digit:                              // loop over each decimal digit
            umull r7, r5, r2, r4           // a = r5 = r2 / 10
            cmp   r5, #0                   // check loop condition
            beq   _aui2d_done              // while ((r2 / 10) != 0)
            
            umull r6, r10, r5, r9          // (a / b) * 10
            sub   r6, r2, r6               // r6 = r2 % 10 = a - ((a / 10) * 10))
            orr   r10, r11, r6             // convert digit to ASCII; c
            
            strb  r10, [r0, r8]            // s[i] = c
            mov   r2, r5                   // go to next digit
            add   r8, r8, #1               // i++
            b     _aui2d_digit             // while(1)
_aui2d_done:
            orr   r10, r11, r2             // convert digit to ASCII; c
            strb  r10, [r0, r8]            // s[i] = c; highest digit
            add   r8, r8, #1               // i++
    
            mov   r7, #0                   // i = 0
_aui2d_rev_loop:                           // reverse byte order of ASCII buffer
            ldrb  r10, [r0, r7]            // ascii[i]
            cmp   r7, r8                   // compare i with digits
            blt   _aui2d_rev_next          // 
            mov   r10, #ASCII_ZERO         // set to ASCII zero if not set already
_aui2d_rev_next:
            sub   r11, r9, r7              // x = 10-i
            sub   r11, r11, #1             // x= 10-i-1
            strb  r10, [r0, r11]           // ascii[x] = ascii[i]

            add   r7, r7, #1               // i++
            cmp   r7, r9                   // check loop condition
            blt   _aui2d_rev_loop          // while (i < 10)

            mov   r10, #0x00               // null terminator
            strb  r10, [r0, #10]           // ascii[-1] = '\0'
            mov   r1, r8                   // return ASCII conversion length

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

            .end                           // end of source
