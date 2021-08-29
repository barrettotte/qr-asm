// Subroutines for performing Reed-Solomon error correction

            // exported subroutines
            .global reed_solomon  // Reed-Solomon error correction
            .global new_msg_poly  // build polynomial from message
            .global new_gen_poly  // build generator polynomial

            .global gf256_mul     // multiplication in Galois Field 2^8
            .global gf256_inv     // inversion in Galois Field 2^8
            .global gf256_div     // division in Galoi field 2^8
            
            .global poly_clr      // reset a polynomial's data
            .global poly_norm     // polynomial normalization
            .global poly_add      // polynomial addition
            .global poly_mul      // polynomial multiplication
            .global poly_rem      // get remainder of polynomial long division

            // constants
            .equ POLY_SIZE, 128   // max terms in a polynomial

            .data

gf256_anti: // Galois field 256 anti-logarithm table
            .byte 1, 2, 4, 8, 16, 32, 64, 128             //   0 -   7
            .byte 29, 58, 116, 232, 205, 135, 19, 38      //   8 -  15
            .byte 76, 152, 45, 90, 180, 117, 234, 201     //  16 -  23
            .byte 143, 3, 6, 12, 24, 48, 96, 192          //  24 -  31
            .byte 157, 39, 78, 156, 37, 74, 148, 53       //  32 -  39
            .byte 106, 212, 181, 119, 238, 193, 159, 35   //  40 -  47
            .byte 70, 140, 5, 10, 20, 40, 80, 160         //  48 -  55
            .byte 93, 186, 105, 210, 185, 111, 222, 161   //  56 -  63
            .byte 95, 190, 97, 194, 153, 47, 94, 188      //  64 -  71
            .byte 101, 202, 137, 15, 30, 60, 120, 240     //  72 -  79
            .byte 253, 231, 211, 187, 107, 214, 177, 127  //  80 -  87
            .byte 254, 225, 223, 163, 91, 182, 113, 226   //  88 -  95
            .byte 217, 175, 67, 134, 17, 34, 68, 136      //  96 - 103
            .byte 13, 26, 52, 104, 208, 189, 103, 206     // 104 - 111
            .byte 129, 31, 62, 124, 248, 237, 199, 147    // 112 - 119
            .byte 59, 118, 236, 197, 151, 51, 102, 204    // 120 - 127
            .byte 133, 23, 46, 92, 184, 109, 218, 169     // 128 - 135
            .byte 79, 158, 33, 66, 132, 21, 42, 84        // 136 - 143
            .byte 168, 77, 154, 41, 82, 164, 85, 170      // 144 - 151
            .byte 73, 146, 57, 114, 228, 213, 183, 115    // 152 - 159
            .byte 230, 209, 191, 99, 198, 145, 63, 126    // 160 - 167
            .byte 252, 229, 215, 179, 123, 246, 241, 255  // 168 - 175
            .byte 227, 219, 171, 75, 150, 49, 98, 196     // 176 - 183
            .byte 149, 55, 110, 220, 165, 87, 174, 65     // 184 - 191
            .byte 130, 25, 50, 100, 200, 141, 7, 14       // 192 - 199
            .byte 28, 56, 112, 224, 221, 167, 83, 166     // 200 - 207
            .byte 81, 162, 89, 178, 121, 242, 249, 239    // 208 - 215
            .byte 195, 155, 43, 86, 172, 69, 138, 9       // 216 - 223
            .byte 18, 36, 72, 144, 61, 122, 244, 245      // 224 - 231
            .byte 247, 243, 251, 235, 203, 139, 11, 22    // 232 - 239
            .byte 44, 88, 176, 125, 250, 233, 207, 131    // 240 - 247
            .byte 27, 54, 108, 216, 173, 71, 142, 1       // 248 - 255

gf256_log:  // Galois field 256 logarithm table
            .byte -1, 0, 1, 25, 2, 50, 26, 198            //   0 -   7
            .byte 3, 223, 51, 238, 27, 104, 199, 75       //   8 -  15
            .byte 4, 100, 224, 14, 52, 141, 239, 129      //  16 -  23
            .byte 28, 193, 105, 248, 200, 8, 76, 113      //  24 -  31
            .byte 5, 138, 101, 47, 225, 36, 15, 33        //  32 -  39
            .byte 53, 147, 142, 218, 240, 18, 130, 69     //  40 -  47
            .byte 29, 181, 194, 125, 106, 39, 249, 185    //  48 -  55
            .byte 201, 154, 9, 120, 77, 228, 114, 166     //  56 -  63
            .byte 6, 191, 139, 98, 102, 221, 48, 253      //  64 -  71
            .byte 226, 152, 37, 179, 16, 145, 34, 136     //  72 -  79
            .byte 54, 208, 148, 206, 143, 150, 219, 189   //  80 -  87
            .byte 241, 210, 19, 92, 131, 56, 70, 64       //  88 -  95
            .byte 30, 66, 182, 163, 195, 72, 126, 110     //  96 - 103
            .byte 107, 58, 40, 84, 250, 133, 186, 61      // 104 - 111
            .byte 202, 94, 155, 159, 10, 21, 121, 43      // 112 - 119
            .byte 78, 212, 229, 172, 115, 243, 167, 87    // 120 - 127
            .byte 7, 112, 192, 247, 140, 128, 99, 13      // 128 - 135
            .byte 103, 74, 222, 237, 49, 197, 254, 24     // 136 - 143
            .byte 227, 165, 153, 119, 38, 184, 180, 124   // 144 - 151
            .byte 17, 68, 146, 217, 35, 32, 137, 46       // 152 - 159
            .byte 55, 63, 209, 91, 149, 188, 207, 205     // 160 - 167
            .byte 144, 135, 151, 178, 220, 252, 190, 97   // 168 - 175
            .byte 242, 86, 211, 171, 20, 42, 93, 158      // 176 - 183
            .byte 132, 60, 57, 83, 71, 109, 65, 162       // 184 - 191
            .byte 31, 45, 67, 216, 183, 123, 164, 118     // 192 - 199
            .byte 196, 23, 73, 236, 127, 12, 111, 246     // 200 - 207
            .byte 108, 161, 59, 82, 41, 157, 85, 170      // 208 - 215
            .byte 251, 96, 134, 177, 187, 204, 62, 90     // 216 - 223
            .byte 203, 89, 95, 176, 156, 169, 160, 81     // 224 - 231
            .byte 11, 245, 22, 235, 122, 117, 44, 215     // 232 - 239
            .byte 79, 174, 213, 233, 230, 231, 173, 232   // 240 - 247
            .byte 116, 214, 244, 234, 168, 80, 88, 175    // 248 - 255

                                        // polynomials:
msg_poly:   .space POLY_SIZE            //   message polynomial
gen_poly:   .space POLY_SIZE            //   generator polynomial
rem_poly:   .space POLY_SIZE            //   remainder polynomial used in reed-solomon subroutine
tmp_mono:  .space POLY_SIZE             //   scratch monomial
tmpA_poly:  .space POLY_SIZE            //   scratch polynomial
tmpB_poly:  .space POLY_SIZE            //   scratch polynomial
tmpC_poly:  .space POLY_SIZE            //   scratch polynomial
prdA_poly:  .space POLY_SIZE            //   scratch polynomial for polynomial multiplication (operand A)
prdB_poly:  .space POLY_SIZE            //   scratch polynomial for polynomial multiplication (operand B)
                                        //
                                        //   struct polynomial {
                                        //     byte length;   // number of terms
                                        //     byte terms[];  // array of terms;
                                        //   }
                                        //
                                        //   example: [5, 3, 2, 0, 4, 9]
                                        //     = 3x^0 + 2x^1 + 0x^2 + 4x^3 + 9x^4  (5 terms)
                                        //
            .text

gf256_mul:                              // ***** multiplication in GF(256) *****
                                        // r0 - product
                                        // r1 - unused
                                        // r2 - operand A
                                        // r3 - operand B
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r0, #0                // init product
            orr   r4, r2, r3            // if either A or B are zero, then r4 = 0
            cmp   r4, r0                // check if r4 = 0
            beq   _gf256m_done          // leave routine; 0 * n = 0

            ldr   r4, =gf256_log        // pointer to logarithm table
            ldr   r5, =gf256_anti       // pointer to anti-logarithm table
            ldrb  r6, [r4, r2]          // gf256_log[r2]
            ldrb  r7, [r4, r3]          // gf256_log[r3]
            add   r6, r6, r7            // gf256_log[r2] + gf256_log[r3]; modulo operand A

            mov   r7, #255              // load modulo operand B = Galois field size - 1
            udiv  r8, r6, r7            // (a / b)
            umull r10, r9, r8, r7       // (a / b) * b  (throw away rdhi=r9)
            sub   r8, r6, r10           // a - ((a / b) * b)
            ldrb  r0, [r5, r8]          // gf256_anti[r6 % 255]
_gf256m_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

gf256_inv:                              // ***** inverse in GF(256) *****
                                        // r0 - inverse of R2
                                        // r1 - error status; error if non-zero
                                        // r2 - number to invert in GF(256)
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r1, #0                // init error status
            cmp   r2, #0                //
            beq   _gf256i_err           // assert r2 != 0
            ldr   r5, =gf256_log        // pointer to logarithm table
            ldr   r6, =gf256_anti       // pointer to anti-logarithm table
            ldrb  r7, [r5, r2]          // gf256_log[r2]

            mov   r4, #255              // Galois field size - 1
            sub   r4, r4, r7            // 255 - gf256_log[r2]
            ldrb  r0, [r6, r4]          // gf256_anti[255 - gf256_log[r2]]
            b     _gf256i_done          // leave subroutine
_gf256i_err:
            mov   r1, #1                // return error code
_gf256i_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

gf256_div:                              // ***** division in GF(256) *****
                                        // r0 - quotient
                                        // r1 - error status; error if non-zero
                                        // r2 - operand A
                                        // r3 - operand B
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r0, #0                // init quotient
            mov   r1, #0                // init error
            cmp   r2, #0                //
            beq   _gf256d_done          // 0 / x = 0

            cmp   r3, #0                // 
            beq   _gf256d_err1          // if r3 == 0, error (div by zero)

            mov   r4, r2                // retain operand A
            mov   r2, r3                // load operand B
            bl    gf256_inv             // invert operand B

            cmp   r1, #0                // 
            bne   _gf256d_err2          // if r0 != 0, then error occurred

            mov   r2, r4                // load operand A
            mov   r3, r0                // load inverted operand B
            bl    gf256_mul             // GF(256) multiply; return product in r0

            b     _gf256d_done          // return quotient
_gf256d_err1:
            mov   r1, #1                // divide by zero error
_gf256d_err2:
            mov   r1, #2                // GF(256) invert error
_gf256d_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_clr:                               // ***** polynomial clear *****
                                        // r0 - pointer to polynomial to clear
                                        // r1 - unused
                                        // r2 - unused
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            ldrb  r4, [r0]              // p.length
            mov   r5, #0                // empty term
            mov   r6, r5                // i = 0
_pclr_loop:
            strb  r5, [r0, r6]          // p.terms[i] = 0
            add   r6, r6, #1            // i++
            cmp   r6, r4                //
            ble   _pclr_loop            // while (i <= p.length)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_norm:                              // ***** polynomial normalization *****
                                        // r0 - (n) pointer to store normalized polynomial
                                        // r1 - unused
                                        // r2 - (p) pointer to polynomial to normalize
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            ldrb  r4, [r2]              // load p.length
            mov   r7, r4                // max_nz = p.length - 1
            mov   r5, r4                // i = p.length - 1
_pnorm_nzloop:
            ldrb  r6, [r2, r4]          // p.terms[i]
            cmp   r6, #0                // if (p.terms[i] != 0):
            bne   _pnorm_maxnz          //   break

            sub   r4, r4, #1            // i--
            mov   r7, r4                // max_nz = i - 1
            cmp   r5, r4                //
            bne   _pnorm_nzloop         // while (i >= 0)
_pnorm_maxnz:
            cmp   r7, #0                // leave if negative, shouldn't happen...
            blt   _pnorm_done           // if (max_nz < 0)

            strb  r7, [r0]              // n.length = max_nz
            add   r7, #1                // max_nz += 1
            mov   r5, #0                // j = 0
_pnorm_norm_loop:
            add   r6, r5, #1            // y = j + 1
            ldrb  r8, [r2, r6]          // r8 = p[y]
            strb  r8, [r0, r6]          // n[y] = p[y]
            add   r5, r5, #1            // j++
            cmp   r5, r7                //
            ble   _pnorm_norm_loop      // while (j < max_nz+1)
            b     _pnorm_done           // return
_pnorm_skip:                            // already normalized
            mov   r0, r2                // move pointers
_pnorm_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_add:                               // ***** polynomial addition *****
                                        // r0 - pointer to store sum polynomial
                                        // r1 - unused
                                        // r2 - pointer to operand A polynomial
                                        // r3 - pointer to operand B polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            ldrb  r5, [r2]              // A.length
            ldrb  r6, [r3]              // B.length
            mov   r4, r5                // default to A.length
            cmp   r6, r4                //
            ble   _padd_len             // if (B.length <= A.length)
            mov   r4, r6                // set to B.Length
_padd_len:
            strb  r4, [r0]              // store sum length
            mov   r7, #0                // i = 0
_padd_loop:
            add   r1, r7, #1            // x = i + 1
            ldrb  r10, [r2, r1]         // A.terms[x]
            ldrb  r11, [r3, r1]         // B.terms[x]
            cmp   r5, r7                // if (
            ble   _padd_A               //   A.length <= i or
            cmp   r6, r7                //   B.length <= i
            ble   _padd_A               // )
_padd_AB:
            eor   r9, r10, r11          // use GF(256) addition its just XOR
            b     _padd_next            // iterate
_padd_A:
            cmp   r5, r7                //
            ble   _padd_B               // elif (A.length <= i)
            ldrb  r9, [r2, r1]          // use A.terms[x]
            b     _padd_next            // iterate
_padd_B:
            ldrb  r9, [r3, r1]          // else, use B.terms[x]
_padd_next:
            strb  r9, [r0, r1]          // set sum.terms[x]
            add   r7, r7, #1            // i++
            cmp   r7, r4                //
            blt   _padd_loop            // while (i < sum.length)
_padd_done:
            mov   r2, r0                // destination and target are same
            bl    poly_norm             // normalize polynomial

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_mul:                               // ***** polynomial multiplication *****
                                        // r0 - pointer to product polynomial
                                        // r1 - unused
                                        // r2 - pointer to operand A polynomial
                                        // r3 - pointer to operand B polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            push  {r0}                  // save output pointer for later
            ldr   r0, =prdA_poly        // pointer to temp A polynomial
            bl    poly_clr              // clear temp A polynomial
            ldrb  r5, [r2]              // A.length
            ldrb  r6, [r3]              // B.length
            add   r7, r5, r6            //
            strb  r7, [r0]              // tempA.length = A.length + B.length

            mov   r8, #0                // i = 0
_pmul_loop_a:
            mov   r9, #0                // j = 0
_pmul_loop_b:
            add   r0, r8, #1            // x = i + 1
            add   r1, r9, #1            // y = j + 1
            ldrb  r10, [r2, r0]         // A.terms[x]
            ldrb  r11, [r3, r1]         // B.terms[y]

            cmp   r10, #0               // if (
            beq   _pmul_next_b          //   A.terms[x] == 0 or
            cmp   r11, #0               //   B.terms[y] == 0
            beq   _pmul_next_b          // ) then skip this iteration

            push  {r2, r3}              // store pointers to polynomial operands
            add   r4, r0, r1            // x + y

            mov   r2, r10               // operand A = A.terms[x]
            mov   r3, r11               // operand B = B.terms[y]
            bl    gf256_mul             // perform GF(256) multiplication
            push  {r0}                  // store GF(256) product

            ldr   r0, =prdB_poly        // pointer to tempB polynomial
            bl    poly_clr              // clear tempB polynomial for current iteration
            mov   r3, r0                // use tempB polynomial as operand B in polynomial addition
            add   r7, r8, r9            // i + j
            add   r7, r7, #1            // 
            strb  r7, [r3]              // tempB.length = i + j + 1
            pop   {r0}                  // restore GF(256) product
            sub   r4, r4, #1            // adjust indexing to (x+y)-1
            strb  r0, [r3, r4]          // tempB.terms[x+y] = GF(256) product of A[x] & B[y]

            ldr   r0, =prdA_poly        // pointer to tempA polynomial
            mov   r2, r0                // use tempA polynomial as operand and output
            bl    poly_add              // perform polynomial addition

            pop   {r2, r3}              // restore polynomial operand pointers
_pmul_next_b:
            add   r9, r9, #1            // j++
            cmp   r9, r6                //
            blt   _pmul_loop_b          // while (j < B.length)
_pmul_next_a:
            add   r8, r8, #1            // i++
            cmp   r8, r5                //
            blt   _pmul_loop_a          // while (i < A.length)

            pop   {r0}                  // restore output pointer
            ldr   r2, =prdA_poly        // pointer to tempA polynomial
            bl    poly_norm             // normalize polynomial

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_rem:                               // ***** Remainder of Polynomial Long Division *****
                                        // r0 - pointer to remainder polynomial
                                        // r1 - error status; error if non-zero
                                        // r2 - pointer to numerator polynomial
                                        // r3 - pointer denominator polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r1, #0                // init error
            mov   r10, r3               // retain pointer to denominator
            mov   r11, r0               // retain pointer to remainder polynomial
            ldrb  r4, [r2]              // numerator terms
            ldrb  r5, [r10]             // denominator terms
            mov   r6, #0                // i = 0
_prem_eq_loop:                          // check equality of operands
            ldrb  r7, [r2]              // numerator[i]
            ldrb  r8, [r10]             // denominator[i]
            cmp   r8, r7                //
            bne   _prem_neq             // numerator[i] != denominator[i]

            add   r6, r6, #1            // i++
            cmp   r6, r4                //
            ble   _prem_eq_loop         // while (i <= numerator.length)
            
            b     _prem_err1            // error: numerator and denominator are equal

_prem_neq:                              // numerator != denominator, all good
            mov   r6, #0                // i = 0

_prem_init_loop:                        // initialize remainder to numerator
            ldrb  r7, [r2, r6]          // numerator[i]
            strb  r7, [r11, r6]         // remainder[i] = numerator[i]
            add   r6, r6, #1            // i++
            cmp   r6, r4                //
            ble   _prem_init_loop       // while (i <= numerator.length)

            ldrb  r7, [r10]             // denominator.length
            ldr   r5, =tmp_mono         // pointer to temporary monomial
_prem_loop:
            ldrb  r6, [r11]             // remainder.length
            ldrb  r2, [r11, r6]         // remainder.terms[-1]; operand A
            ldrb  r3, [r10, r7]         // denominator.terms[-1]; operand B
            bl    gf256_div             // GF(256) divide; A / B

            mov   r9, r0                // retain GF(256) quotient
            cmp   r1, #0                //
            bne   _prem_err2            // if (r1 != 0) then error occurred

            mov   r0, r5                // pointer to tmp_mono
            bl    poly_clr              // reset tmp_mono data
            sub   r8, r6, r7            //
            strb  r8, [r5]              // tmp_mono.length = rem.length - denom.length
            add   r8, r8, #1            //
            strb  r9, [r5, r8]          // set tmp_mono coefficient as GF(256) quotient

            ldr   r8, =tmpC_poly        // pointer to temporary polynomial; divisor
            mov   r0, r8                // store product in temporary polynomial
            bl    poly_clr              // reset tmpC_poly
            mov   r2, r10               // pointer to denominator; operand A
            mov   r3, r5                // pointer to temp monomial; operand B
            bl    poly_mul              // polynomial multiply; A * B

            mov   r0, r11               // pointer to remainder polynomial; sum
            mov   r2, r11               // pointer to remainder polynomial; operand A
            mov   r3, r8                // pointer to temporary polynomial; operand B
            bl    poly_add              // polynomial add; A + B

            cmp   r6, r7                //
            bge   _prem_loop            // while (remainder.length >= denominator.length)

            bl    poly_norm             // normalize remainder polynomial
            b     _prem_done            // return
_prem_err1:
            mov   r1, #1                // numerator == denominator
_prem_err2:
            mov   r1, #2                // error in gf256_div
_prem_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_gen_poly:                           // ***** create generator polynomial *****
                                        // r0 - pointer to store generator polynomial
                                        // r1 - unused
                                        // r2 - ECW per block = polynomial length
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, #1                // init g_poly to 1x^0
            strb  r4, [r0]              // g_poly[0] = length
            strb  r4, [r0, #1]          // g_poly[1] = 1

            ldr   r10, =tmpA_poly       // pointer to scratch polynomial A
            ldr   r5, =tmpB_poly        // pointer to scratch polynomial B
            ldr   r7, =gf256_anti       // pointer to gf256_anti table
            mov   r9, r2                // retain ECW per block

            mov   r8, #0                // i = 0
_gpoly_loop:                            // build generator polynomial
            mov   r6, #2                // load tmp_poly length
            strb  r6, [r5]              // tmpB_poly[0] = length
            
            ldrb  r6, [r7, r8]          // load first term from anti-logarithm table
            strb  r6, [r5, #1]          // tmpB_poly[1] = (gf256_anti[i])x^0
            mov   r6, #1                // load second term
            strb  r6, [r5, #2]          // tmpB_poly[2] = 1x^1

            mov   r6, #0                // j = 0
_gpoly_copy:                            // copy current generator polynomial to scratch poly A
            ldrb  r4, [r0, r6]          // r4 = g_poly[j]
            strb  r4, [r10, r6]         // tmpA_poly[j] = g_poly[j]
            add   r6, r6, #1            // j++
            cmp   r6, r9                // compare index and ECW per block
            ble   _gpoly_copy           // while (j <= g_poly.length)
_gpoly_iter:
            mov   r2, r10               // pointer to scratch polynomial A; operand A
            mov   r3, r5                // pointer to scratch polynomial B; operand B
            bl    poly_mul              // polynomial multiply; r0 = generator polynomial

            add   r8, r8, #1            // i++
            cmp   r8, r9                // compare i and ECW per block
            blt   _gpoly_loop           // while (i < g_poly.length)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_msg_poly:                           // ***** create message polynomial *****
                                        // r0 - pointer to store message polynomial
                                        // r1 - unused
                                        // r2 - pointer to message
                                        // r3 - message length = polynomial length
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, r3                // i = msg_len
            strb  r4, [r0]              // m_poly[0] = length
            sub   r4, r4, #1            // i-- (zero index)
            mov   r5, #1                // j = 1 ; m_poly idx
_mpoly_loop:                            // loop over message
            ldrb  r6, [r2, r4]          // r5 = msg[i]
            strb  r6, [r0, r5]          // m_poly[j] = msg[i]
            sub   r4, r4, #1            // i--
            add   r5, r5, #1            // j++
            cmp   r5, r3                // compare m_poly index with message length
            ble   _mpoly_loop           // while (j <= msg_len)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

reed_solomon:                           // ***** Reed-Solomon Error Correction *****
                                        // r0 - pointer to error correction block
                                        // r1 - pointer to data block
                                        // r2 - data block capacity
                                        // r3 - error correction words (ECW) capacity
            push  {r4-r11, lr}          // save caller's vars + return address

            ldr   r4, =msg_poly         // pointer to message polynomial
            ldr   r5, =gen_poly         // pointer to generator polynomial
            mov   r6, r2                // retain block capacity
            mov   r7, r3                // retain ECW capacity
            push  {r0}                  // store output/input pointers for later

            mov   r0, r4                // pointer to message polynomial
            bl    poly_clr              // reset message polynomial data
            mov   r0, r5                // pointer to generator polynomial
            bl    poly_clr              // reset generator polynomial data

            mov   r0, r4                // pointer to message polynomial
            mov   r2, r1                // pointer to data block
            mov   r3, r6                // block capacity
            bl    new_msg_poly          // create message polynomial

            mov   r0, r5                // pointer to generator polynomial
            mov   r2, r7                // use ECW capacity
            bl    new_gen_poly          // create generator polynomial
            push  {r1}                  // don't clobber pointer to data block

            ldr   r8, =tmpB_poly        // pointer to temporary polynomial
            mov   r0, r8                //
            bl    poly_clr              // reset temp monomial data
            add   r9, r7, #1            // terms = degree + 1
            strb  r9, [r8]              // tmpB_poly = ECW capacity + 1
            mov   r10, #1               // coefficient
            strb  r10, [r8, r9]         // tmpB_poly = 1x^(ECW capacity)

            ldr   r9, =tmpA_poly        // pointer to temp polynomial
            mov   r0, r9                //
            bl    poly_clr              // reset temp polynomial data
            mov   r0, r9                // output to temp polynomial
            mov   r2, r4                // pointer to message polynomial
            mov   r3, r8                // pointer to temp monomial
            bl    poly_mul              // perform polynomial multiplication
            mov   r0, r8                // retain polynomial product

            ldr   r10, =rem_poly        // pointer to remainder polynomial
            mov   r0, r10               // 
            bl    poly_clr              // reset remainder polynomial data
            mov   r2, r9                // operand A; pointer to message polynomial
            mov   r3, r5                // operand B; pointer to generator polynomial
            bl    poly_rem              // find remainder polynomial of A / B

            mov   r5, r0                // retain pointer to remainder polynomial
            mov   r4, r1                // retain error status of poly_rem
            pop   {r1}                  // restore data block pointer
            pop   {r0}                  // restore output pointer
            cmp   r4, #0                //
            bne   _rs_err1              // if (r4 != 0) then error occurred in poly_rem

            ldrb  r4, [r5]              // poly_rem.length
            mov   r6, #0                // i = 0
_rs_copy:                               // copy remainder polynomial terms to ECW block
            add   r7, r6, #1            // x = i + 1
            ldrb  r8, [r5, r7]          // rem_poly[x]
            strb  r8, [r0, r6]          // ECW[i] = rem_poly[x]

            add   r6, r6, #1            // i++
            cmp   r6, r4                //
            blt   _rs_copy              // while (i < poly_rem.length)

            b     _rs_done              // return
_rs_err1:
            nop                         // error occurred: don't write to ECW block
_rs_done:
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine
