// subroutines needed for Reed-Solomon error correction

            .include "const.inc"

            // exported subroutines
            .global new_mpoly
            .global new_gpoly

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

gtmpA_poly: .space MAX_DATA_CAP+1       // scratch polynomial for generator polynomial create
gtmpB_poly: .space MAX_DATA_CAP+1       // scratch polynomial for generator polynomial create
sum_poly:   .space (MAX_DATA_CAP+1)     // scratch polynomial for polynomial addition
prdA_poly:  .space (MAX_DATA_CAP+1)*2   // scratch polynomial for polynomial multiplication
prdB_poly:  .space (MAX_DATA_CAP+1)*2   // scratch polynomial for polynomial multiplication
                                        //
                                        // polynomial_struct = {
                                        //   byte length,
                                        //   byte[] terms  // looped via one-indexing
                                        // }
            .text

gf256_mul:                              // ***** multiplication in GF(256) *****
                                        // r0 - product
                                        // r1 - unused
                                        // r2 - operand A
                                        // r3 - operand B
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r0, #0                // init product
            and   r4, r2, r3            // if either A or B are zero, then r4 = 0
            cmp   r4, r0                // check if r4 = 0
            beq   _gf256m_done          // leave routine; 0 * n = 0

            ldr   r4, =gf256_log        // pointer to logarithm table
            ldr   r5, =gf256_anti       // pointer to anti-logarithm table
            ldrb  r6, [r4, r2]          // gf256_log[r2]
            ldrb  r7, [r4, r3]          // gf256_log[r3]
            add   r6, r6, r7            // gf256_log[r2] + gf256_log[r3]; modulo operand A
            //ldrb  r6, [r5, r6]          // r6 = gf256_anti[r6]; 

            mov   r7, #255              // load modulo operand B
            udiv  r8, r6, r7            // (a / b)
            umull r10, r9, r8, r7       // (a / b) * b  (throw away r10 = rdhi)
            sub   r8, r6, r9            // a - ((a / b) * b)

            ldrb  r0, [r5, r8]          // gf256_anti[r6 % 255]

_gf256m_done:                           // leave subroutine
            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

gf256_inv:                              // ***** inverse in GF(256) *****
                                        // r0 - unused
                                        // r1 - error if non-zero
                                        // r2 - unused
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address
            mov   r1, #0                // init error

            // TODO: if r2 == 0 raise exception zero has no inverse
            // TODO: else r0 = gf256_anti[255 - gf256_log[r2]]

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

gf256_div:                              // ***** division in GF(256) *****
                                        // r0 - unused
                                        // r1 - error if non-zero
                                        // r2 - unused
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address
            mov   r1, #0                // init error

            // TODO: if a == 0 then r0 = 0
            // TODO: elif b == 0 then raise exception div by zero
            // TODO: else gf256_mul (r2, gf256_inv(r3))

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_clr:                               // ***** polynomial clear *****
                                        // r0 - pointer to polynomial to clear
                                        // r1 - unused
                                        // r2 - unused
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            ldrb  r4, [r0]              // p.length
            mov   r5, #0                //
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
            sub   r4, r4, #1            // 
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
            //cmp   r7, r4                //
            //bge   _pnorm_skip           // elif (max_nz >= p.length - 1)

            strb  r7, [r0]              // n.length = max_nz
            add   r7, #1                // max_nz += 1
            mov   r5, #1                // j = 1
_pnorm_norm_loop:
            ldrb  r8, [r2, r5]          // r8 = p[j]
            strb  r8, [r0, r5]          // n[j] = p[j]
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

            nop   // TODO: use temp polynomial?

            nop   // TODO: there might be an issue with iterating  
            nop   //       incrementally...not confirmed yet...keep it in mind.

            ldrb  r5, [r2]              // A.length
            ldrb  r6, [r3]              // B.length
            mov   r4, r5                // default to A.length
            cmp   r6, r4                //
            ble   _padd_len             // if (B.length <= A.length)
            mov   r4, r6                // set to B.Length
_padd_len:
            strb  r4, [r0]              // store sum length

            nop   // TODO: I think we HAVE to zero-index here

            @ add   r4, #1                // zero indexing adjust
            mov   r7, #1                // i = 1
_padd_loop:
            sub   r1, r7, #1            // zero index
            ldrb  r10, [r2, r7]         // A.terms[i]
            ldrb  r11, [r3, r7]         // B.terms[i]

            cmp   r5, r1                //
            ble   _padd_A               // if (A.length <= (i-1))
            cmp   r6, r1                // || (B.length <= (i-1))
            ble   _padd_A               // 
_padd_AB:
            eor   r9, r10, r11          // use GF(256) addition its just XOR
            b     _padd_next            // iterate
_padd_A:
            cmp   r5, r1                //
            ble   _padd_B               // elif (A.length <= (i-1))
            ldrb  r9, [r2, r7]          // use A.terms[i]
            b     _padd_next            // iterate
_padd_B:
            ldrb  r9, [r3, r7]          // else; use B.terms[i]
_padd_next:
            strb  r9, [r0, r7]          // set sum.terms[i]

            add   r7, r7, #1            // i++
            cmp   r7, r4                //
            ble   _padd_loop            // while (i <= sum.length)

            mov   r2, r0                // destination and target are same
            bl    poly_norm             // normalize polynomial

            nop   // TODO: if temp polynomial used, copy it to output pointer?

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_mul:                               // ***** polynomial multiplication *****
                                        // r0 - pointer to product polynomial
                                        // r1 - unused
                                        // r2 - pointer to operand A polynomial
                                        // r3 - pointer to operand B polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            nop   // TODO: there might be an issue with iterating  
            nop   //       incrementally...not confirmed yet...keep it in mind.

            ldr   r4, =prdA_poly        // pointer to temp A polynomial
            ldrb  r5, [r2]              // A.length
            ldrb  r6, [r3]              // B.length
            add   r7, r5, r6            //
            strb  r7, [r4]              // tempA.length = A.length + B.length
            push  {r0}                  // save output pointer for later

            mov   r8, #1                // i = 1
_pmul_loop_a:
            mov   r9, #1                // j = 1
            ldrb  r10, [r2, r8]         // A.terms[i]
_pmul_loop_b:
            ldrb  r11, [r3, r9]         // B.terms[j]
            orr   r7, r10, r11          //
            cmp   r7, #0                //
            beq   _pmul_next_b          // if (A.terms[i] == 0 || B.terms[j] == 0)

            push  {r2, r3}              // store pointers to polynomial operands
            mov   r2, r10               // operand A = A.terms[i]
            mov   r3, r11               // operand B = B.terms[j]
            bl    gf256_mul             // perform GF(256) multiplication

            ldr   r3, =prdB_poly        // pointer to tempB polynomial
            add   r7, r8, r9            // i + j
            sub   r7, r7, #1            //
            strb  r0, [r3, r7]          // tempB.terms[i+j] = GF(256) product
            strb  r7, [r3]              // tempB.length = i + j + 1

            mov   r0, r4                // output sum to tempA polynomial
            mov   r2, r4                // operand A = tempA polynomial, operand B = tempB polynomial
            bl    poly_add              // perform polynomial addition
_pmul_next_b:
            mov   r2, r3                // pointer to tempB polynomial
            bl    poly_clr              // clear tempB polynomial
            pop   {r2, r3}              // restore polynomial operand pointers

            add   r9, r9, #1            // j++
            cmp   r9, r6                //
            ble   _pmul_loop_b          // while (j <= B.length)
_pmul_next_a:
            add   r8, r8, #1            // i++
            cmp   r8, r5                //
            ble   _pmul_loop_a          // while (i <= A.length)

            pop   {r0}                  // restore output pointer
            mov   r2, r4                // normalize temp polynomial
            bl    poly_norm             // normalize polynomial

            push  {r0}                  // save output pointer
            mov   r0, r4                // pointer to tempA polynomial
            bl    poly_clr              // clear tempA polynomial
            pop   {r0}                  // restore output pointer

@             mov   r7, #0                // zero for clearing temp polynomial
@             mov   r8, #0                // i = 0
@             ldrb  r9, [r0]              // load product.length
@ _pmul_copy:
@             ldrb  r6, [r4, r8]          // tempA.terms[i]
@             strb  r6, [r0, r8]          // product.terms[i] = tempA.terms[i]
@             strb  r7, [r4, r8]          // tempA.terms[i] = 0
@             add   r7, r7, #1            // i++
@             cmp   r7, r9                //
@             ble   _pmul_copy            // while (i <= product.length)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_gpoly:                              // ***** create generator polynomial *****
                                        // r0 - pointer to store generator polynomial
                                        // r1 - unused
                                        // r2 - ECW per block = polynomial length
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, #1                // init g_poly to 1x^0
            strb  r4, [r0]              // g_poly[0] = length
            strb  r4, [r0, #1]          // g_poly[1] = 1

            ldr   r10, =gtmpA_poly      // pointer to scratch polynomial A
            ldr   r5, =gtmpB_poly       // pointer to scratch polynomial B
            ldr   r7, =gf256_anti       // pointer to gf256_anti table
            mov   r9, r2                // retain ECW per block

            nop   // SANITY CHECK - g_poly (byte order)
            nop   // idx 0:  1x^0 + 1x^1
            nop   // idx 1:  2x^0 + 3x^1 + 1x^2
            nop   // idx 2:  8x^0 + 14x^1 + 7x^2 + 1x^3
            nop   // idx 3:  64x^0 + 120x^1 + 54x^2 + 15x^3 + 1x^4
            nop   // idx 4:  116x^0 + 147x^1 + 63x^2 + 198x^3 + 31x^4 + 1x^5

            mov   r8, #0                // i = 0
_gpoly_loop:                            // build generator polynomial
            mov   r6, #2                // load gtmp_poly length
            strb  r6, [r5]              // gtmpB_poly[0] = length
            
            ldrb  r6, [r7, r8]          // load first term from anti-logarithm table
            strb  r6, [r5, #1]          // gtmpB_poly[1] = (gf256_anti[i])x^0
            mov   r6, #1                // load second term
            strb  r6, [r5, #2]          // gtmpB_poly[2] = 1x^1

            mov   r6, #0                // j = 0
_gpoly_copy:                            // copy current generator polynomial to scratch poly A
            ldrb  r4, [r0, r6]          // r4 = g_poly[j]
            strb  r4, [r10, r6]         // gtmpA_poly[j] = g_poly[j]
            add   r6, r6, #1            // j++
            cmp   r6, r9                // compare index and ECW per block
            ble   _gpoly_copy           // while (j <= g_poly.length)
_gpoly_iter:
            nop                         // r0; pointer to generator polynomial
            mov   r2, r10               // pointer to scratch polynomial A; operand A
            mov   r3, r5                // pointer to scratch polynomial B; operand B
            bl    poly_mul              // call subroutine for polynomial multiplication

            add   r8, r8, #1            // i++
            cmp   r8, r9                // compare i and ECW per block
            ble   _gpoly_loop           // while (i <= g_poly.length)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_mpoly:                              // ***** create message polynomial *****
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
