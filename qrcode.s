// subroutines for building QR code matrix

            .include "const.s"

            // exports
            .global qr_reserved         // add reserved areas to QR matrix
            @ TODO: .global qr_zigzag           // "zigzag" payload into QR matrix
            @ TODO: .global qr_mask0            // apply mask 0 to QR matrix
            @ TODO: .global qr_fmtbits          // add format bits to QR matrix
            @ TODO: .global qr_normalize        // normalize QR matrix to ['0', '1']
            @ TODO: .global qr_quiet            // add quiet zone to QR matrix
            
            // internal:
            //
            // add_square   - add a square to matrix
            // add_timing   - add horizontal and vertical timing patterns
            // add_finder   - add a finder to matrix

            // constants
            .equ  MOD_DLT, 0x30            // Data light module;     ASCII '0'
            .equ  MOD_DDK, 0x31            // Data dark module;      ASCII '1'
            .equ  MOD_EMP, 0x32            // Empty module;          ASCII '2'
            .equ  MOD_RLT, 0x33            // Reserved light module; ASCII '3'
            .equ  MOD_RDK, 0x34            // Reserved dark module;  ASCII '4'

            .equ MASK_B0, 0x000000ff       // 32-bit mask for byte 0
            .equ MASK_B1, 0x0000ff00       // 32-bit mask for byte 1
            .equ MASK_B2, 0x00ff0000       // 32-bit mask for byte 2
            .equ MASK_B3, 0xff000000       // 32-bit mask for byte 3

            .data

tbl_align:  .byte 0, 18, 22, 26            // alignment pattern; v1-v4

            .text

add_square:                                // ***** Add square to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - sq_args = [x pos, y pos, square width, fill byte]
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            and   r11, r1, #MASK_B0        // get byte 0 from sq_args; fill byte
            and   r4, r1, #MASK_B1         // get byte 1 from sq_args; square width
            lsr   r4, r4, #8               // set square width
            
            and   r8, r1, #MASK_B2         // get byte 2 from sq_args; y position
            lsr   r8, r8, #16              // y position
            and   r7, r1, #MASK_B3         // get byte 3 from sq_args; x position
            lsr   r7, r7, #24              // x position

            mov   r5, #0                   // i = 0
_asq_x_loop:
            mov   r6, #0                   // j = 0
_asq_y_loop:
            push  {r7,r8}                  // save x and y position
            add   r7, r7, r5               // dx = x + i
            add   r8, r8, r6               // dy = y + j

            cmp   r7, r2                   // if
            bge   _asq_y_next              //   (dx >= qr_size)
            cmp   r8, r2                   // &&
            bge   _asq_y_next              //   (dy >= qr_size)
            cmp   r7, #0                   // &&
            blt   _asq_y_next              //   (dx < 0)
            cmp   r8, #0                   // &&
            blt   _asq_y_next              //   (dy < 0)

            umull r9, r10, r8, r2          // dy * qr_size
            add   r9, r9, r7               // (dy * qr_size) + dx
            strb  r11, [r0, r9]            // qr_mat[(dy * qr_size) + dx] = sq_args[0]
_asq_y_next:
            pop   {r7, r8}                 // restore original x and y position
            add   r6, r6, #1               // j++
            cmp   r6, r4                   // check loop condition
            blt   _asq_y_loop              // while (j < sq_args[1])
_asq_x_next:
            add   r5, r5, #1               // i++
            cmp   r5, r4                   // check loop condition
            blt   _asq_x_loop              // while (i < sq_args[1])

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

add_timing:                                // ***** Add timing patterns to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r4, #1                   // is_dark = true
            mov   r5, #0                   // i = 0
            mov   r7, #6                   // timing offset
_at_loop:
            cmp   r4, #1                   // is_dark?
            beq   _at_dark                 // use dark module
            mov   r6, $MOD_RLT             // set light module ASCII
            b     _at_set                  // skip over next 2 lines
_at_dark:
            mov   r6, $MOD_RDK             // set dark module ASCII
_at_set:
            umull r9, r10, r2, r5          // x = i * qr_size
            add   r9, r9, r7               // x = (i * qr_size) + offset
            strb  r6, [r0, r9]             // qr_mat[x] = r6; horizontal timing

            umull r9, r10, r7, r2          // x = offset * qr_size
            add   r9, r9, r5               // x = (offset * qr_size) + i
            strb  r6, [r0, r9]             // qr_mat[x] = r6; vertical timing

            eor   r4, r4, #1               // is_dark = !is_dark
            add   r5, r5, #1               // i++
            cmp   r5, r2                   // check loop condition
            blt   _at_loop                 // while (i < qr_width)

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

add_finder:                                // ***** Add a finder pattern to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused
                                           // r2 - QR width
                                           // r3 - pos = [?, ?, x, y]
            push  {r4-r11, lr}             // save caller's vars + return address

            and   r4, r3, #MASK_B1         // get x position
            lsr   r4, r4, #8               // shift over 1 byte
            and   r5, r3, #MASK_B0         // get y position
            mov   r8, #9                   // init width constant

_af_sep:                                   // add finder's separator square
            eor   r1, r1, r1               // reset sq_args
            sub   r6, r4, #1               // x - 1
            orr   r1, r1, r6, lsl #24      // set x position
            sub   r6, r5, #1               // y - 1
            orr   r1, r1, r6, lsl #16      // set y position
            orr   r1, r1, r8, lsl #8       // set square width
            orr   r1, r1, #MOD_RLT         // set fill character
            bl    add_square               // add square to QR matrix
            
_af_out:                                   // add finder's outer square
            eor   r1, r1, r1               // reset sq_args
            orr   r1, r1, r4, lsl #24      // set x position
            orr   r1, r1, r5, lsl #16      // set y position
            sub   r8, r8, #2               // width -= 2
            orr   r1, r1, r8, lsl #8       // set square width
            orr   r1, r1, #MOD_RDK         // set fill character
            bl    add_square               // add square to QR matrix

_af_in:                                    // add finder's inner square
            eor   r1, r1, r1               // reset sq_args
            add   r6, r4, #1               // x + 1
            orr   r1, r1, r6, lsl #24      // set x position
            add   r6, r5, #1               // y + 1
            orr   r1, r1, r6, lsl #16      // set y position
            sub   r8, r8, #2               // width -= 2
            orr   r1, r1, r8, lsl #8       // set square width
            orr   r1, r1, #MOD_RLT         // set fill character
            bl    add_square               // add square to QR matrix

_af_ctr:                                   // add finder's center square
            eor   r1, r1, r1               // reset sq_args
            add   r6, r4, #2               // x + 2
            orr   r1, r1, r6, lsl #24      // set x position
            add   r6, r5, #2               // y + 2
            orr   r1, r1, r6, lsl #16      // set y position
            sub   r8, r8, #2               // width -= 2
            orr   r1, r1, r8, lsl #8       // set square width
            orr   r1, r1, #MOD_RDK         // set fill character
            bl    add_square               // add square to QR matrix

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

add_align:                                 // ***** add alignment patterns to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused; clobbered
                                           // r2 - QR width
                                           // r3 - QR version
            push  {r4-r11, lr}             // save caller's vars + return address

            cmp   r3, #0                   // check version
            beq   _aa_done                 // version 1 has no alignment patterns
            ldr   r6, =tbl_align           // pointer to alignment pattern table
            ldrb  r6, [r6, r3]             // load alignment constant

            mov   r5, #1                   // is_dark = true
            mov   r7, #5                   // init width
            sub   r8, r6, #2               // init offset
            mov   r6, #0                   // i = 0
_aa_loop:
            eor   r1, r1, r1               // reset sq_args
            orr   r1, r1, r8, lsl #24      // set x position
            orr   r1, r1, r8, lsl #16      // set y position
            orr   r1, r1, r7, lsl #8       // set square width

            cmp   r5, #1                   // is_dark?
            beq   _aa_dkmod                // use dark module
            orr   r1, r1, #MOD_RLT         // set fill byte to light
            b     _aa_square               // skip next two lines 
_aa_dkmod:
            orr   r1, r1, #MOD_RDK         // set fill byte
_aa_square:
            bl    add_square               // add alignment at x,y
            add   r8, r8, #1               // offset++
            sub   r7, r7, #2               // width -= 2
            eor   r5, r5, #1               // is_dark = !is_dark

            add   r6, r6, #1               // i++
            cmp   r6, #3                   // check loop condition
            blt   _aa_loop                 // while (i < 3)

_aa_done:
            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

qr_reserved:                               // ***** Add reserved areas to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused; clobbered
                                           // r2 - QR width
                                           // r3 - QR version
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r11, r3                  // retain QR version
            mov   r5, #9                   // set square width
            mov   r6, #MOD_RLT             // set fill byte
            mov   r1, #0                   // reset unused arg

_qrr_sq:                                   // add reserved squares to QR matrix
            mov   r4, #0                   // set x,y; sq_args[3] = 0, sq_args[2] = 0
            orr   r1, r1, r5, lsl #8       // set square width; sq_args[1]
            orr   r1, r1, r6               // set fill byte; sq_args[0]
            bl    add_square               // add top left square to QR matrix
            eor   r1, r1, r1               // reset sq_args

            sub   r4, r2, r5               // x = qr_size - 9
            orr   r1, r1, r4, lsl #24      // set x position
            orr   r1, r1, r5, lsl #8       // set square width
            orr   r1, r1, r6               // set fill byte
            bl    add_square               // add top right square to QR matrix
            eor   r1, r1, r1               // reset sq_args

            sub   r4, r2, r5               // y = qr_size - 9
            orr   r1, r1, r4, lsl #16      // set y position
            orr   r1, r1, r5, lsl #8       // set square width
            orr   r1, r1, r6               // set fill byte
            bl    add_square               // add bottom left square to QR matrix

_qrr_time:                                 // add timing patterns to QR matrix
            bl    add_timing               // add horizontal and vertical timing patterns

_qrr_find:                                 // add finding patterns to QR matrix
            mov   r3, #0                   // pos = (0, 0)
            bl    add_finder               // add finder pattern at x,y

            sub   r6, r2, #7               // qr_size - 7
            orr   r3, r3, r6               // pos = (0, qr_size-7)
            bl    add_finder               // add finder pattern at x,y

            eor   r3, r3, r3               // reset pos
            orr   r3, r3, r6, lsl #8       // pos = (qr_size-7, 0)
            bl    add_finder               // add finder pattern at x,y
_qrr_align:
            mov   r3, r11                  // load QR version
            bl    add_align                // add alignment patterns to QR matrix

_qrr_darkmod:                              // add dark module to QR matrix
            nop @ TODO:

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

            .end                           // end of source
