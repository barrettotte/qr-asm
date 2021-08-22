// subroutines needed for Reed-Solomon error correction

            .include "const.inc"

            // exported subroutines
            .global gf256_mul
            .global gf256_inv
            .global gf256_div
            .global new_mono
            .global poly_mul
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

                                        // polynomials = [degree byte, term bytes]
gtmp_poly:  .space MAX_DATA_CAP+1       // scratch polynomial for generator polynomial create
prd_poly:   .space (MAX_DATA_CAP+1)*2   // scratch polynomial for polynomial multiplication
prd_mono:   .space (MAX_DATA_CAP+1)*2   // scratch monomial for polynomial multiplication

            .text

gf256_mul:                             // ***** multiplication in GF(256) *****
                                       // r0 - unused
                                       // r1 - unused
                                       // r2 - unused
                                       // r3 - unused
            push {r4-r11,r14}          // save caller's vars + return address
            
            nop
            // TODO: if r2 == 0 || r3 == 0 then r0 = 0
            // TODO: else r0 = gf256_anti[gf256_log[r2] + gf256_log[r3]] % 255

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine

gf256_inv:                             // ***** inverse in GF(256) *****
                                       // r0 - unused
                                       // r1 - error if non-zero
                                       // r2 - unused
                                       // r3 - unused
            push {r4-r11,r14}          // save caller's vars + return address
            mov  r1, #0                // init error

            // TODO: if r2 == 0 raise exception zero has no inverse
            // TODO: else r0 = gf256_anti[255 - gf256_log[r2]]

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine

gf256_div:                             // ***** division in GF(256) *****
                                       // r0 - unused
                                       // r1 - error if non-zero
                                       // r2 - unused
                                       // r3 - unused
            push {r4-r11,r14}          // save caller's vars + return address
            mov  r1, #0                // init error

            // TODO: if a == 0 then r0 = 0
            // TODO: elif b == 0 then raise exception div by zero
            // TODO: else gf256_mul (r2, gf256_inv(r3))

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine

new_mono:                              // ***** create new monomial *****
                                       // r0 - pointer to store new monomial
                                       // r1 - unused
                                       // r2 - degree
                                       // r3 - unused
            push {r4-r11,r14}          // save caller's vars + return address

            mov  r4, #1                // i = 1
            strb r2, [r0]              // mono[0] = degree
            strb r4, [r0, r2]          // mono[degree] = 1
_mono_loop:                            // clear out rest of monomial terms
            strb r1, [r0, r1]          // mono[i] = 0
            add  r4, r4, #1            // i++
            cmp  r4, r2                // compare idx with monomial degree
            blt  _mono_loop            // while (i < degree)

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine       

poly_mul:                              // ***** polynomial multiplication *****
                                       // r0 - pointer to product polynomial
                                       // r1 - unused
                                       // r2 - pointer to operand A polynomial
                                       // r3 - pointer to operand B polynomial
            push {r4-r11,r14}          // save caller's vars + return address

            ldr  r4, =prd_poly         // pointer to prd_poly
            ldrb r5, [r2]              // load operand A degree
            ldrb r6, [r3]              // load operand B degree
            add  r5, r5, r6            // get size of polynomial product
            strb r5, [r4]              // prd_poly[0] = degree
            push {r0}                  // store product polynomial pointer for later

            mov  r6, #1                // i = 1
_pmul_a:                               // loop over all operand A terms
            mov  r7, #1                // j = 1
_pmul_b:                               // loop over all operand B terms
            ldrb r8, [r2, r6]          // r8 = A[i]
            ldrb r9, [r3, r7]          // r9 = B[j]

            orr  r10, r8, r9           // OR each term, looking for nonzero for both
            cmp  r10, #0               // compare with zero
            beq  _pmul_iter            // if a[i] == b[i] == 0 then skip iteration

            push {r2, lr}              // save operand A pointer and link register

            add  r2, r6, r7           // monomial degree = i + j
            bl   new_mono             // call subroutine to create new monomial

            nop  // TODO: prd_mono = [(i+j), gf256_mul(a[i], b[j])]
            nop  // TODO: prd_poly = poly_add(prd_pol, prd_mono)

            pop  {r2, lr}             // restore operand A pointer and link register

_pmul_iter:                            // iterate to next B term
            add  r7, r7, #1            // j++
            ble  _pmul_b               // while (j <= degree(B))
            add  r6, r6, #1            // i++
            ble  _pmul_a               // while (i <= degree(A))

            nop // TODO: prd_poly = poly_normalize(prd_poly)
            
            pop  {r0}                  // restore product polynomial pointer
            nop // TODO: copy prd_poly terms to polynomial in r0

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine

new_gpoly:                             // ***** create generator polynomial *****
                                       // r0 - pointer to store generator polynomial
                                       // r1 - unused
                                       // r2 - ECW per block = polynomial degree
                                       // r3 - unused
            push {r4-r11,r14}          // save caller's vars + return address

            strb r2, [r0]              // g_poly[0] = degree
            mov  r4, #1                // i = 1
            strb r4, [r0, #1]          // g_poly[1] = r4; g_poly = 1x^0
            add  r4, r4, #1            // i++

            ldr  r5, =gtmp_poly        // pointer to gtmp_poly
            ldr  r7, =gf256_anti       // pointer to gf256_anti table

_gpoly_loop:                           // build generator polynomial
            mov  r6, #2                // load gtmp_poly degree
            strb r6, [r5]              // gtmp_poly[0] = 2
            mov  r6, #1                // load first term
            strb r6, [r5, #1]          // gtmp_poly[1] = 1x^0
            ldrb r6, [r7, r4]          // load second term
            strb r6, [r5, #2]          // gtmp_poly[2] = (gf256_anti[i])x^1

            push {r2, lr}              // stash ECW per block and link register
            nop                        // r0; pointer to g_poly; polynomial product
            mov  r2, r0                // pointer to g_poly; operand A
            mov  r3, r5                // pointer to gtmp_poly; operand B
            bl   poly_mul              // call subroutine for polynomial multiplication
            pop  {r2, lr}              // restore ECW per block and link register

            add  r4, r4, #1            // i++
            cmp  r4, r2                // compare i and polynomial degree
            ble  _gpoly_loop           // while (i <= degree)

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine

new_mpoly:                             // ***** create message polynomial *****
                                       // r0 - pointer to store message polynomial
                                       // r1 - unused
                                       // r2 - pointer to message
                                       // r3 - message length = polynomial degree
            push {r4-r11,r14}          // save caller's vars + return address

            strb r3, [r0]              // m_poly[0] = degree
            mov  r4, r3                // i = msg_len
            sub  r4, r4, #1            // i-- (zero index)
            mov  r5, #1                // j = 1 ; m_poly idx
_mpoly_loop:                           // loop over message
            ldrb r6, [r2, r4]          // r5 = msg[i]
            strb r6, [r0, r5]          // m_poly[j] = msg[i]
            sub  r4, r4, #1            // i--
            add  r5, r5, #1            // j++
            cmp  r5, r3                // compare m_poly index with message length
            ble  _mpoly_loop           // while (j <= msg_len)

            pop  {r4-r11,r14}          // restore caller's vars + return address
            bx   lr                    // return from subroutine
