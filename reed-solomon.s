// subroutines needed for Reed-Solomon error correction

            .include "const.inc"

            // exported subroutines
            .global gf256_mul
            .global gf256_inv
            .global gf256_div
            .global new_mono
            .global poly_add
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
gtmpA_poly: .space MAX_DATA_CAP+1       // scratch polynomial for generator polynomial create
gtmpB_poly: .space MAX_DATA_CAP+1       // scratch polynomial for generator polynomial create
sum_poly:   .space (MAX_DATA_CAP+1)     // scratch polynomial for polynomial addition
prd_poly:   .space (MAX_DATA_CAP+1)*2   // scratch polynomial for polynomial multiplication
prd_mono:   .space (MAX_DATA_CAP+1)*2   // scratch monomial for polynomial multiplication

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

new_mono:                               // ***** create new monomial *****
                                        // r0 - pointer to store new monomial
                                        // r1 - unused
                                        // r2 - degree
                                        // r3 - term coefficient
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, #1                // i = 1
            mov   r5, #0                //
_mono_loop:                             // clear out monomial terms
            strb  r5, [r0, r4]          // mono[i] = 0
            add   r4, r4, #1            // i++
            cmp   r4, r2                // compare idx with monomial degree
            ble   _mono_loop            // while (i < degree)


            strb  r2, [r0]              // mono[0] = degree
            add   r2, r2, #1            // polynomial one-indexing
            strb  r3, [r0, r2]          // mono[degree] = r3

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine       

poly_norm:                              // ***** polynomial normalization *****
                                        // r0 - pointer to normalized polynomial
                                        // r1 - unused
                                        // r2 - pointer to polynomial to normalize
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            nop   // TODO:  max_nz = r0.degree - 1

            nop   // TODO:  i = r0.degree + 1 (?)
            nop   // TODO:  while (i > 0):
            nop   // TODO:    if r0[i] != 0
            nop   // TODO:      break
            nop   // TODO:    max_nz = i - 1
            nop   // TODO:    i--

            nop   // TODO:  if max_nz < 0:
            nop   // TODO:    return monomial 0x^0
            nop   // TODO:  elif max_nz < (r0.degree - 1)
            nop   // TODO:    r0
            
            nop   // TODO:  return r0

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine   

poly_add:                               // ***** polynomial addition *****
                                        // r0 - pointer to store sum polynomial
                                        // r1 - unused
                                        // r2 - pointer to operand A polynomial
                                        // r3 - pointer to operand B polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            ldrb  r5, [r2]              // load degree of A
            ldrb  r6, [r3]              // load degree of B
            add   r5, r5, #1            // r5 = terms in polynomial A
            add   r6, r6, #1            // r6 = terms in polynomial B
            
            mov   r7, r5                // set sum polynomial terms to A.terms
            cmp   r6, r5                // compare terms of B to terms of A
            ble   _padd_deg             // if (B.terms <= A.terms)
_padd_degB:                             // else
            mov   r7, r6                // set sum polynomial terms to B.terms
_padd_deg:                              // done setting sum polynomial terms
            sub   r7, r7, #1            // degree = terms - 1
            strb  r7, [r0]              // store sum polynomial degree
            add   r7, r7, #1            // r7 = terms in sum polynomial
            mov   r8, #0                // i = 1
_padd_loop:                             // while (i <= terms)
            add   r11, r8, #1           // 
            cmp   r5, r8                // compare A.terms with index
            bgt   _padd_a               // if (A.terms > i)
_padd_b:                                // use B[i+1] as sum polynomial term
            ldrb  r9, [r3, r11]         // sum[i+1] = B[i+1]
            b     _padd_next            // next iteration
_padd_a:                                // use A[i+1] as sum polynomial term
            cmp   r6, r8                // compare B.terms with index
            bgt   _padd_gf              // if (A.terms > i && B.terms > i)
            ldrb  r9, [r2, r11]         // sum[i] = A[i+1]
            b     _padd_next            // go to next iteration of loop
_padd_gf:                               // use GF(256) addition
            ldrb  r9, [r2, r11]         // r9 = A[i+1]
            ldrb  r10, [r3, r11]        // r10 = B[i+1]
            eor   r9, r9, r10           // sum[i] = A[i+1] XOR B[i+1]; GF(256) addition
            b     _padd_next            // go to next iteration of loop

_padd_next:                             // set sum polynomial term and iterate
            strb  r9, [r0, r11]         // sum[i+1] = r9
            add   r8, r8, #1            // i++
            cmp   r8, r7                // compare index to sum polynomial terms
            blt   _padd_loop            // while (i < sum_poly.terms)

            nop   // TODO: normalization

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

poly_mul:                               // ***** polynomial multiplication *****
                                        // r0 - pointer to product polynomial
                                        // r1 - clobbered
                                        // r2 - pointer to operand A polynomial
                                        // r3 - pointer to operand B polynomial
            push  {r4-r11, lr}          // save caller's vars + return address

            ldr   r1, =prd_poly         // pointer to product polynomial
            ldrb  r4, [r2]              // load operand A degree
            add   r4, r4, #1
            ldrb  r5, [r3]              // load operand B degree
            add   r5, r5, #1

            @ add   r10, r5, r4           // get size of polynomial product
            @ add   r10, r10, #2          // degree = (A.degree + 1 + B.degree + 1)
            mov   r10, #0               // init product degree
            strb  r10, [r1]             // product[0] = degree

            push  {r0}                  // save product polynomial pointer for later
            mov   r6, #1                // i = 1
_pmul_a:                                // loop over all operand A terms
            mov   r7, #1                // j = 1
_pmul_b:                                // loop over all operand B terms
            ldrb  r8, [r2, r6]          // r8 = A[i]
            ldrb  r9, [r3, r7]          // r9 = B[j]

            cmp   r8, #0                // compare with zero
            beq   _pmul_next            // if A[i] == 0 then skip iteration
            cmp   r9, #0                // compare with zero
            beq   _pmul_next            // if B[i] == 0 then skip iteration
            
            push  {r2, r3}              // save operand pointers
            mov   r2, r8                // pass A[i] as operand A
            mov   r3, r9                // pass B[j] as operand B
            bl    gf256_mul             // GF(256) multiplication; r0 = r2 * r3
            
            mov   r3, r0                // GF(256) product is a term coefficient
            ldr   r0, =prd_mono         // pass pointer to temp monomial
            add   r2, r6, r7            // monomial degree = i + j
            sub   r2, r2, #2            // re-establish index (i-1)+(j-1)
            bl    new_mono              // call subroutine to create temp monomial

            mov   r3, r0                // operand B = temp monomial (prd_mono)
            mov   r0, r1                // product = temp polynomial
            mov   r2, r1                // operand A = temp polynomial
            bl    poly_add              // call subroutine to perform polynomial addition
            pop   {r2, r3}              // restore operand pointers

_pmul_next:                             // iterate to next B term
            add   r7, r7, #1            // j++
            cmp   r7, r5                // compare index with B.degree
            ble   _pmul_b               // while (j <= B.degree)

            add   r6, r6, #1            // i++
            cmp   r6, r4                // compare index with A degree
            ble   _pmul_a               // while (i <= A.degree)

            nop   // TODO: normalization?

            pop   {r0}                  // restore product polynomial pointer
            mov   r6, #0                // i = 0
            ldrb  r7, [r1]              // product polynomial degree
            add   r7, r7, #1            // degree + number of terms
_pmul_copy:                             // copying temp polynomial to result
            ldrb  r8, [r1, r6]          // r8 = temp[i] 
            strb  r8, [r0, r6]          // product[i] = temp[i]
            add   r6, r6, #1            // i++
            cmp   r6, r7                // compare index to temp polynomial degree
            ble   _pmul_copy            // while (i < temp.degree)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_gpoly:                              // ***** create generator polynomial *****
                                        // r0 - pointer to store generator polynomial
                                        // r1 - unused
                                        // r2 - ECW per block = polynomial degree
                                        // r3 - unused
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, #1                // init g_poly to 1x^0
            strb  r4, [r0, #1]          // g_poly[1] = 1
            mov   r8, #0                // i = 0
            strb  r8, [r0]              // init generator polynomial degree to zero

            ldr   r10, =gtmpA_poly      // pointer to scratch polynomial A
            ldr   r5, =gtmpB_poly       // pointer to scratch polynomial B
            ldr   r7, =gf256_anti       // pointer to gf256_anti table
            mov   r9, r2                // retain ECW per block

            nop   // TODO: it looks like gtmpB_poly is in the wrong order
            nop   // TODO: idx 1: 1x^1 + 1x^0  @ worked here obviously
            nop   // TODO: idx 2: 1x^1 + 2x^0  @ failed !
            nop   // TODO: idx 3: 1x^1 + 4x^0

_gpoly_loop:                            // build generator polynomial
            mov   r6, #1                // load gtmp_poly degree
            strb  r6, [r5]              // gtmpB_poly[0] = degree
            strb  r6, [r5, #1]          // gtmpB_poly[1] = 1x^0
            ldrb  r6, [r7, r8]          // load second term
            strb  r6, [r5, #2]          // gtmpB_poly[2] = (gf256_anti[i])x^1
            
            mov   r6, #0                // j = 0
_gpoly_copy:                            // copy current generator polynomial to scratch poly A
            ldrb  r4, [r0, r6]          // r4 = g_poly[j]
            strb  r4, [r10, r6]         // gtmpA_poly[j] = g_poly[j]
            add   r6, r6, #1            // j++
            cmp   r6, r9                // compare index and ECW per block
            ble   _gpoly_copy           // while (j <= g_poly.degree)
_gpoly_iter:
            nop                         // r0; pointer to generator polynomial
            mov   r2, r10               // pointer to scratch polynomial A; operand A
            mov   r3, r5                // pointer to scratch polynomial B; operand B
            bl    poly_mul              // call subroutine for polynomial multiplication

            add   r8, r8, #1            // i++
            cmp   r8, r9                // compare i and ECW per block
            ble   _gpoly_loop           // while (i <= degree)

            pop   {r4-r11, lr}          // restore caller's vars + return address
            bx    lr                    // return from subroutine

new_mpoly:                              // ***** create message polynomial *****
                                        // r0 - pointer to store message polynomial
                                        // r1 - unused
                                        // r2 - pointer to message
                                        // r3 - message length = polynomial degree
            push  {r4-r11, lr}          // save caller's vars + return address

            mov   r4, r3                // i = msg_len
            sub   r4, r4, #1            // i-- (zero index)
            strb  r4, [r0]              // m_poly[0] = degree
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
