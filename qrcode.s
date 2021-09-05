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
            // add_time_h   - add horizontal timing to matrix
            // add_time_v   - add vertical timing to matrix
            // add_finder   - add a finder to matrix
            // add_aligns   - add alignment patterns and dark module to matrix

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

qr_reserved:                               // ***** Add reserved areas to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused; clobbered
                                           // r2 - QR width
                                           // r3 - QR version
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r5, #9                   // set square width
            mov   r6, #MOD_RLT             // set fill byte
            mov   r1, #0                   // reset unused arg
_rsquare_tl:                               // set top left reserved square
            mov   r4, #0                   // set x,y; sq_args[3] = 0, sq_args[2] = 0
            orr   r1, r1, r5, lsl #8       // set square width; sq_args[1]
            orr   r1, r1, r6               // set fill byte; sq_args[0]
            bl    add_square               // add top left square to QR matrix
            eor   r1, r1, r1               // reset sq_args

_rsquare_tr:                               // set top right reserved square
            sub   r4, r2, r5               // x = qr_size - 9
            orr   r1, r1, r4, lsl #24      // set x position
            orr   r1, r1, r5, lsl #8       // set square width
            orr   r1, r1, r6               // set fill byte
            bl    add_square               // add top right square to QR matrix
            eor   r1, r1, r1               // reset sq_args

_rsquare_bl:                               // set bottom left reserved square
            sub   r4, r2, r5               // y = qr_size - 9
            orr   r1, r1, r4, lsl #16      // set y position
            orr   r1, r1, r5, lsl #8       // set square width
            orr   r1, r1, r6               // set fill byte
            bl    add_square               // add bottom left square to QR matrix

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

            .end                           // end of source
