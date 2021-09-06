// subroutines for building QR code matrix

            .include "const.inc"

            // exports
            .global qr_reserved            // add reserved areas to QR matrix
            .global qr_normalize           // normalize QR matrix to ['0','1']
            .global qr_zigzag              // "zigzag" payload into QR matrix
            .global qr_fmtbits             // add format bits to QR matrix
            .global qr_mask0               // apply mask 0 to QR matrix
            .global qr_quiet               // add quiet zone to QR matrix

            // internal subroutines
            //   add_square   - add a square to QR matrix
            //   add_timing   - add horizontal and vertical timing patterns to QR matrix
            //   add_finder   - add a finder to QR matrix
            //   add_align    - add alignment pattern to QR matrix

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
fmt_lo:     .space 8+1                     // temp string buffer
fmt_hi:     .space 8+1                     // temp string buffer

tbl_fmt:    // table of format information strings
                                           // {err_lvl}-{mask_idx}
            .hword 0b111011111000100       // L-0
            .hword 0b101010000010010       // M-0
            .hword 0b011010101011111       // Q-0
            .hword 0b001011010001001       // H-0
            .hword 0b111001011110011       // L-1
            .hword 0b101000100100101       // M-1
            .hword 0b011000001101000       // Q-1
            .hword 0b001001110111110       // H-1
            .hword 0b111110110101010       // L-2
            .hword 0b101111001111100       // M-2
            .hword 0b011111100110001       // Q-2
            .hword 0b001110011100111       // H-2
            .hword 0b111100010011101       // L-3
            .hword 0b101101101001011       // M-3
            .hword 0b011101000000110       // Q-3
            .hword 0b001100111010000       // H-3
            .hword 0b110011000101111       // L-4
            .hword 0b100010111111001       // M-4
            .hword 0b010010010110100       // Q-4
            .hword 0b000011101100010       // H-4
            .hword 0b110001100011000       // L-5
            .hword 0b100000011001110       // M-5
            .hword 0b010000110000011       // Q-5
            .hword 0b000001001010101       // H-5
            .hword 0b110110001000001       // L-6
            .hword 0b100111110010111       // M-6
            .hword 0b010111011011010       // Q-6
            .hword 0b000110100001100       // H-6
            .hword 0b110100101110110       // L-7            
            .hword 0b100101010100000       // M-7            
            .hword 0b010101111101101       // Q-7
            .hword 0b000100000111011       // H-7

            .text

add_square:                                // ***** Add square to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - sq_args = [x pos, y pos, square width, fill byte]
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            and   r11, r1, #MASK_B0        // get byte 0 from sq_args; fill byte
            and   r4, r1, #MASK_B1         // get byte 1 from sq_args; square width
            lsr   r4, r4, #8               // shift 1 byte; set square width
            
            and   r8, r1, #MASK_B2         // get byte 2 from sq_args; y position
            lsr   r8, r8, #16              // shift 2 bytes; set y position
            and   r7, r1, #MASK_B3         // get byte 3 from sq_args; x position
            lsr   r7, r7, #24              // shift 3 bytes; set x position

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

            sub   r4, r4, #1               // init x position
            sub   r5, r5, #1               // init y position
            mov   r8, #9                   // init width constant
            mov   r7, #0                   // init is_dark = false
            mov   r6, #0                   // i = 0
_af_loop:
            eor   r1, r1, r1               // reset sq_args
            orr   r1, r1, r4, lsl #24      // set x position
            orr   r1, r1, r5, lsl #16      // set y position
            orr   r1, r1, r8, lsl #8       // set square width

            cmp   r7, #1                   // is_dark?
            beq   _af_dkmod                //
            orr   r1, r1, #MOD_RLT         // set fill character
            b     _af_square               // skip next two lines
_af_dkmod:
            orr   r1, r1, #MOD_RDK         // set fill character
_af_square:
            bl    add_square               // add square to QR matrix
            add   r4, r4, #1               // x++
            add   r5, r5, #1               // y++
            sub   r8, r8, #2               // width -= 2
            eor   r7, r7, #1               // is_dark = !is_dark

            add   r6, r6, #1               // i++
            cmp   r6, #4                   // check loop condition
            blt   _af_loop                 // while (i < 4)

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
            add   r4, r4, #1               // x += 1
            orr   r1, r1, r4, lsl #24      // set x position
            orr   r1, r1, r5, lsl #8       // set square width
            orr   r1, r1, r6               // set fill byte
            bl    add_square               // add top right square to QR matrix
            eor   r1, r1, r1               // reset sq_args

            sub   r4, r2, r5               // y = qr_size - 9
            add   r4, r4, #1               // y += 1
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
            mov   r4, #4                   //
            add   r5, r11, #1              // version + 1
            umull r8, r7, r4, r5           // 4 * (version + 1)
            add   r8, r8, #9               // (4 * (v + 1)) + 9
            umull r4, r7, r8, r2           // ((4 * (v + 1)) + 9) * qr_width
            add   r4, r4, #8               // (((4 * (v + 1)) + 9) * qr_width) + 8
            mov   r5, #MOD_RDK             // load dark module
            strb  r5, [r0, r4]             // set dark module at calculated index

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

qr_normalize:                              // ***** Normalize QR matrix to ['0','1'] *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r9, #0                   // qr_idx = 0
            mov   r4, #0                   // i = 0
_qrn_x_loop:
            mov   r5, #0                   // j = 0
_qrn_y_loop:
            ldrb  r6, [r0, r9]             // qr_mat[qr_idx]

            cmp   r6, #MOD_EMP             // check if empty module
            beq   _qrn_ltmod               // normalize to data light module
            cmp   r6, #MOD_RLT             // check if reserved light module
            beq   _qrn_ltmod               // normalize to data light module
            cmp   r6, #MOD_RDK             // check if reserved dark module
            beq   _qrn_dkmod               // normalize to data dark module

            b     _qrn_y_next              // already normalized; iterate
_qrn_dkmod:
            mov   r6, #MOD_DDK             // dark module
            strb  r6, [r0, r9]             // store normalized module
            b     _qrn_y_next              // iterate
_qrn_ltmod:
            mov   r6, #MOD_DLT             // light module
            strb  r6, [r0, r9]             // store normalized module
_qrn_y_next:
            add   r9, r9, #1               // qr_idx++
            add   r5, r5, #1               // j++
            cmp   r5, r2                   // check loop condition
            blt   _qrn_y_loop              // while (j < qr_width)
_qrn_x_next:
            add   r4, r4, #1               // i++
            cmp   r4, r2                   // check loop condition
            blt   _qrn_x_loop              // while (i < qr_width)

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

qr_zigzag:                                 // ***** "zigzag" payload into QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - pointer to payload
                                           // r2 - QR matrix width
                                           // r3 - payload size in bits
            push  {r4-r11, lr}             // save caller's vars + return address

            sub   r10, r2, #1              // x = qr_width - 1
            mov   r11, r10                 // y = qr_width - 1
            mov   r8, #0b11                // flags = [is_zig, is_up]
            mov   r9, #0                   // i = 0
_qrz_loop:
            cmp   r11, r2                  // check if at bottom edge
            beq   _qrz_edge_b              // if (y == qr_width)
            cmp   r11, #0                  // check if at upper edge
            blt   _qrz_edge_t              // if (y < 0)
            b     _qrz_edge_no             // not at edge

_qrz_edge_b:                               // at bottom edge; bounce off
            eor   r8, r8, #0b01            // is_up = !is_up
            sub   r10, r10, #2             // x -= 2
            orr   r8, r8, #0b10            // is_zig = true
            sub   r11, r2, #1              // y = qr_width - 1
            b     _qrz_edge_no             // not at edge, anymore

_qrz_edge_t:                               // at top edge; bounce off
            eor   r8, r8, #0b01            // is_up = !is_up
            sub   r10, r10, #2             // x -= 2
            orr   r8, r8, #0b10            // is_zig = true
            mov   r11, #0                  // y = 0

_qrz_edge_no:                              // not at edge
            umull r4, r5, r11, r2          // y * qr_width
            add   r4, r4, r10              // (y * qr_width) + x
            ldrb  r5, [r0, r4]             // next_mod = qr_mat[((y * qr_width) + x)]
            cmp   r5, #MOD_EMP             // check if next_mod is empty
            bne   _qrz_no_set              // skip module set

            ldrb  r5, [r1, r9]             // payload[i]
            strb  r5, [r0, r4]             // qr_mat[((y * qr_width) + x)] = payload[i]
            add   r9, r9, #1               // i++
_qrz_no_set:
            and   r5, r8, #0b10            // get is_zig flag
            cmp   r5, #0b10                // check is_zig flag
            bne   _qrz_zag                 // if (!is_zig)
            sub   r10, r10, #1             // x--; zig
            b     _qrz_znext               // skip rest of zigzag branches
_qrz_zag:
            add   r10, r10, #1             // x++; zag
            and   r5, r8, #0b01            // get is_up flag
            cmp   r5, #0b01                // check is_up flag
            beq   _qrz_zag_up              // if (is_up)
            add   r11, r11, #1             // y++; zag down
            b     _qrz_znext               // skip rest of zigzag branches
_qrz_zag_up:
            sub   r11, r11, #1             // y--; zag up
_qrz_znext:
            eor   r8, r8, #0b10            // is_zig = !is_zig
            cmp   r10, #6                  // check timing pattern position
            bne   _qrz_next                // don't skip anything  

_qrz_skip_time:                            // skip over timing patterns
            sub   r10, r10, #1             // x--
            sub   r11, r11, #1             // y--
_qrz_next:
            cmp   r9, r3                   // check loop condition
            blt   _qrz_loop                // while (i < payload_bits)

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

qr_fmtbits:                                // ***** Add format bits to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - mask index
                                           // r2 - QR matrix width
                                           // r3 - error level index
            push  {r4-r11, lr}             // save caller's vars + return address       

            ldr   r4, =tbl_fmt             // pointer to table format table
            lsl   r6, r3, #1               // err_offset = err_lvl * 2
            lsl   r7, r1, #3               // mask_offset = mask_idx * (2^3)
            add   r6, r6, r7               // fmt_idx = err_offset + mask_offset
            ldrh  r5, [r4, r6]             // tbl_fmt[fmt_idx]

            push  {r0,r2}                  // save args
            ldr   r9, =fmt_hi              // pointer to temp string buffer
            mov   r0, r9                   // use high byte buffer
            and   r2, r5, #0xFF00          // mask high byte
            lsr   r2, r2, #7               // shift one byte over; only 7 fmt bits
            bl    ascii_ubyte2bin          // convert byte to bit string
            
            ldr   r10, =fmt_lo             // pointer to temp string buffer
            mov   r0, r10                  // use low byte buffer
            and   r2, r5, #0x00FF          // mask low byte
            lsl   r2, r2, #1               // only 7 fmt bits
            bl    ascii_ubyte2bin          // convert byte to bit string
            pop   {r0,r2}                  // restore args

            mov   r4, #0                   // x = 0
            mov   r5, #8                   // y = 8
            mov   r6, #0                   // i = 0
_qrf_tlh_loop:                             // top left 7 format bits (high byte)
            cmp   r6, #6                   // check for timing index
            bne   _qrf_tlh_next            // if (i != 6)
            add   r4, r4, #1               // x++; skip vertical timing
_qrf_tlh_next:
            umull r7, r8, r5, r2           // q = y * qr_width
            add   r7, r7, r4               // q += x
            ldrb  r8, [r9, r6]             // hi_bits[i]
            add   r8, r8, #3               // convert data to reserved
            strb  r8, [r0, r7]             // qr_mat[q] = hi_bits[i]
            add   r4, r4, #1               // x++

            add   r6, r6, #1               // i++
            cmp   r6, #7                   // check loop condition
            blt   _qrf_tlh_loop            // while (i < 7)

            mov   r4, #8                   // x = 8
            mov   r5, #7                   // y = 7
            mov   r6, #0                   // i = 0
_qrf_tll_loop:                             // top left 7 format bits (low byte)
            cmp   r6, #1                   // check for timing index
            bne   _qrf_tll_next            // if (i != 1)
            sub   r5, r5, #1               // y--; skip horizontal timing
_qrf_tll_next:
            umull r7, r8, r5, r2           // q = y * qr_width
            add   r7, r7, r4               // q += x
            ldrb  r8, [r10, r6]            // lo_bits[i]
            add   r8, r8, #3               // convert data to reserved
            strb  r8, [r0, r7]             // qr_mat[q] = lo_bits[i]
            sub   r5, r5, #1               // y--

            add   r6, r6, #1               // i++
            cmp   r6, #7                   // check loop condition
            blt   _qrf_tll_loop            // while (i < 7)

            sub   r4, r2, #7               // x = qr_width - 7
            mov   r5, #8                   // y = 8
            mov   r6, #0                   // i = 0
_qrf_trl_loop:                             // top right 7 format bits (low byte)
            umull r7, r8, r5, r2           // q = y * qr_width
            add   r7, r7, r4               // q += x
            add   r7, r7, r6               // q += i
            ldrb  r8, [r10, r6]            // lo_bits[i]
            add   r8, r8, #3               // convert data to reserved
            strb  r8, [r0, r7]             // qr_mat[q] = lo_bits[i]

            add   r6, r6, #1               // i++
            cmp   r6, #7                   // check loop condition
            blt   _qrf_trl_loop            // while (i < 7)

            mov   r4, #8                   // x = 8
            sub   r5, r2, #1               // y = qr_width - 1
            mov   r6, #0                   // i = 0; skip 8th bit
_qrf_blh_loop:                             // bottom left 7 format bits (high byte)
            sub   r11, r5, r6              // q = (y - i)
            umull r7, r8, r11, r2          // q *= qr_width
            add   r7, r7, r4               // q += x
            ldrb  r8, [r9, r6]             // hi_bits[i]
            add   r8, r8, #3               // convert data to reserved
            strb  r8, [r0, r7]             // qr_mat[q] = hi_bits[i]

            add   r6, r6, #1               // i++
            cmp   r6, #7                   // check loop condition
            blt   _qrf_blh_loop            // while (i < 7) 

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine

qr_mask0:                                  // ***** Apply mask 0 to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r4, #0                   // y = 0
_qrm0_y_loop:
            mov   r5, #0                   // x = 0
_qrm0_x_loop:
            add   r10, r5, r4              // x + y
            and   r10, r10, #0b01          // check if odd
            eor   r10, r10, #0b01          // flip bit; is even

            umull r6, r7, r4, r2           // q = y * qr_width
            add   r6, r6, r5               // q += x
            ldrb  r8, [r0, r6]             // mod = qr_mat[q]

            cmp   r8, #MOD_RLT             // check for reserved light module
            beq   _qrm0_rlt                // if (mod == '3')
            cmp   r8, #MOD_RDK             // check for reserved dark module
            beq   _qrm0_rdk                // if (mod == '4')
            
            sub   r9, r8, #48              // convert ASCII to bit
            eor   r9, r9, r10              // qr_mat[q] XOR mask
            add   r9, r9, #48              // convert bit back to ASCII
            strb  r9, [r0, r6]             // apply mask
            b     _qrm0_x_next             // iterate
_qrm0_rlt:
            mov   r9, #MOD_DLT             // convert reserved to data
            strb  r9, [r0, r6]             // qr_mat[q] = '0'
            b     _qrm0_x_next             // iterate
_qrm0_rdk:
            mov   r9, #MOD_DDK             // convert reserved to data
            strb  r9, [r0, r6]             // qr_mat[q] = '1'
_qrm0_x_next:
            add   r5, r5, #1               // x++
            cmp   r5, r2                   // check loop condition
            blt   _qrm0_x_loop             // while (x < qr_width)

_qrm0_y_next:
            add   r4, r4, #1               // y++
            cmp   r4, r2                   // check loop condition
            blt   _qrm0_y_loop             // while (y < qr_width)

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine            

qr_quiet:                                  // ***** Add quiet zone to QR matrix *****
                                           // r0 - pointer to QR matrix
                                           // r1 - unused
                                           // r2 - QR width
                                           // r3 - unused
            push  {r4-r11, lr}             // save caller's vars + return address

            mov   r4, r2                   // y = qr_width
            sub   r4, r4, #1
_qrq_y_loop:
            mov   r5, r2                   // x = qr_width
            sub   r5, r5, #1
_qrq_x_loop:
            umull r6, r7, r4, r2           // q = y * qr_width
            add   r6, r6, r5               // q += x
            ldrb  r10, [r0, r6]            // mod = qr_mat[q]
_qrq_transform:
            push  {r10}                    // save original module
            add   r7, r2, #8               // qr_width + 8
            add   r8, r4, #4               // y + (8/2)
            umull r10, r11, r8, r7         // t = (y + (8/2)) * (qr_width + 8)
            add   r11, r10, r5             // t += x
            add   r11, r11, #4             // t += (8/2)
            pop   {r10}                    // restore original module
            strb  r10, [r0, r11]           // qr_mat[t] = qr_mat[q]
_qrq_reset:
            mov   r10, #MOD_DLT            // light module '0'
            strb  r10, [r0, r6]            // reset moved module

_qrq_x_next:
            sub   r5, r5, #1               // x--
            cmp   r5, #0                   // check loop condition
            bge   _qrq_x_loop              // while (x > 0)
_qrq_y_next:
            sub   r4, r4, #1               // y--
            cmp   r4, #0                   // check loop condition
            bge   _qrq_y_loop              // while (y > 0)

            pop   {r4-r11, lr}             // restore caller's vars + return address
            bx    lr                       // return from subroutine   

            .end                           // end of source
