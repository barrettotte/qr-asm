// subroutines needed for Reed-Solomon error correction

            .global get_mpoly
            .global get_gpoly

            .text

get_gpoly:                          // ***** build generator polynomial *****
                                    // r0 - unused
                                    // r1 - unused
                                    // r2 - unused
                                    // r3 - unused
            push {r4-r11,r14}       // save caller's vars + return address

            nop
            // TODO: 

            pop  {r4-r11,r14}       // restore caller's vars + return address
            bx   lr                 // return from subroutine

get_mpoly:                          // ***** build message polynomial *****
                                    // r0 - pointer to store message polynomial
                                    // r1 - unused
                                    // r2 - pointer to message
                                    // r3 - message length
            push {r4-r11,r14}       // save caller's vars + return address

            mov  r4, #0             // i = 0
_gmp_loop:                          // loop over message
            ldrb r5, [r2, r4]       // r5 = msg[i]
            add  r4, r4, #1         // i++
            cmp  r4, r3             // compare index with message length
            blt  _gmp_loop          // while (i < msg_len)

            pop  {r4-r11,r14}       // restore caller's vars + return address
            bx   lr                 // return from subroutine
