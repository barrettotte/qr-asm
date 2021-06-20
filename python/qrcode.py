# scratchpad program to make a QR code from scratch.
#
# this looks really bad because I'm trying to keep it simple
# for when I port this to ARM assembly.
#
# reference:
#   - https://www.thonky.com/qr-code-tutorial/
#   - Reed Solomon Encoding (Computerphile) https://www.youtube.com/watch?v=fBRMaEAFLE0
#   - https://www.youtube.com/watch?v=Ct2fyigNgPY

import galois

# mode indicators
MODE_NUMERIC = 1   # 0001
MODE_ALPHANUM = 2  # 0010
MODE_BYTE = 4      # 0100
MODE_KANJI = 8     # 1000
MODE_ECI = 7       # 0111

# error correction level bits
ERROR_L = 1  # 01; low
ERROR_M = 0  # 00; medium
ERROR_Q = 3  # 11; quartile
ERROR_H = 2  # 10; high

# https://www.thonky.com/qr-code-tutorial/character-capacities
BYTE_MODE_CAPACITY_LOOKUP = [
    # L, M, Q, H
    [0, 0, 0, 0],       # (one-indexing)
    [17, 14, 11, 7],    # 1
    [32, 26, 20, 14],   # 2
    [53, 42, 32, 24],   # 3
    [78, 62, 46, 34],   # 4
    [106, 84, 60, 44],  # 5
    # and so on...to 40
]

# https://www.thonky.com/qr-code-tutorial/error-correction-table
EC_CONFIG_LOOKUP = [
    [],  # L                      M                       Q                    H
    [[19, 7, 1, 19, 0, 0], [16, 10, 1, 16, 0, 0], [13, 13, 1, 13, 0, 0], [9, 17, 1, 9, 0, 0]],         # 1
    [[34, 10, 1, 34, 0, 0], [28, 16, 1, 28, 0, 0], [22, 22, 1, 22, 0, 0], [16, 28, 1, 16, 0, 0]],      # 2
    [[55, 15, 1, 55, 0, 0], [44, 26, 1, 44, 0, 0], [34, 18, 2, 17, 0, 0], [26, 22, 2, 13, 0, 0]],      # 3
    [[80, 20, 1, 80, 0, 0], [64, 18, 2, 32, 0, 0], [48, 26, 2, 24, 0, 0], [36, 16, 4, 9, 0, 0]],       # 4
    [[108, 26, 1, 108, 0, 0], [86, 24, 2, 43, 0, 0], [62, 18, 2, 15, 2, 16], [46, 22, 2, 11, 2, 12]],  # 5
    # and so on...to 40
]

REMAINDER_LOOKUP = [
    0,  # one indexing
    0, 7, 7, 7, 7, 7, 0, 0, 0, 0,
    0, 0, 0, 3, 3, 3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4, 4, 3, 3, 3,
    3, 3, 3, 3, 0, 0, 0, 0, 0, 0
]

# https://www.thonky.com/qr-code-tutorial/alignment-pattern-locations
ALIGNMENT_PATTERN_LOOK = [
    [],  # one indexing
    [],  # version 1 has no alignment
    [6, 18, 0, 0, 0, 0, 0], [6, 22, 0, 0, 0, 0, 0],      # 2, 3
    [6, 26, 0, 0, 0, 0, 0], [6, 30, 0, 0, 0, 0, 0],      # 4, 5
    [6, 34, 0, 0, 0, 0, 0], [6, 22, 38, 0, 0, 0, 0],     # 6, 7
    [6, 24, 42, 0, 0, 0, 0], [6, 26, 46, 0, 0, 0, 0],    # 8, 9
    [6, 28, 50, 0, 0, 0, 0], [6, 30, 54, 0, 0, 0, 0],    # 10, 11
    [6, 32, 58, 0, 0, 0, 0], [6, 34, 62, 0, 0, 0, 0],    # 12, 13
    [6, 26, 46, 66, 0, 0, 0], [6, 26, 48, 70, 0, 0, 0],  # 14, 15
    # and so on to 40...
]

# adjust indices for lookup tables based on error level
ERROR_IDX_TO_LOOKUP = [1, 0, 3, 2]


# utility to build string of byte/bit size
def byte_size_str(d):
    size = len(d)
    return f"{size} bit(s) => {size // 8} byte(s), {size % 8} bit(s)"


# is test between low and high (inclusive)?
def is_between(low, high, test):
    return test >= low and test <= high


# get error correction config from lookup table
def get_ec_config(version, err_lvl):
    return EC_CONFIG_LOOKUP[version][ERROR_IDX_TO_LOOKUP[err_lvl]]


# find version to use based on payload size and error correction
def get_version(size, err_lvl):
    err_idx = ERROR_IDX_TO_LOOKUP[err_lvl]
    for col, row in enumerate(BYTE_MODE_CAPACITY_LOOKUP):
        if row[err_idx] > size:
            return col
    raise Exception("couldn't find version")


# determine character count indicator
def get_count(size, version, mode):
    if int(mode, 2) == MODE_BYTE:
        if is_between(1, 9, version):
            word_size = 8
        elif is_between(10, 26, version):
            word_size = 16
        elif is_between(27, 40, version):
            word_size = 16
        else:
            raise Exception("Invalid version")
    else:
        raise Exception("Only byte mode implemented!")
    return int_to_bits(size, word_size)


# convert integer to bits
def int_to_bits(i, word_size):
    return bin(int(hex(i), 16))[2:].zfill(word_size)


# encode string to byte mode format - https://www.thonky.com/qr-code-tutorial/byte-mode-encoding
# UTF-8 encode -> hex bytes -> 8-bit binary
def encode_byte_mode(s):
    as_hex = [c.encode('utf-8').hex() for c in s]
    return [bin(int(byte, 16))[2:].zfill(8) for byte in as_hex]


# draw square in qr matrix
def draw_square(qr_mat, qr_size, x, y, n, c):
    for i in range(n):
        for j in range(n):
            dx = (x + i)
            dy = (y + j)
            if dx < qr_size and dy < qr_size and dx >= 0 and dy >= 0:
                qr_mat[(dy * qr_size) + dx] = c
    return qr_mat


# place finder pattern in QR code matrix with left corner at (x,y)
def place_finder(qr_mat, qr_size, x, y):
    qr_mat = draw_square(qr_mat, qr_size, x - 1, y - 1, 9, 0)  # separator
    qr_mat = draw_square(qr_mat, qr_size, x, y, 7, 1)          # outer
    qr_mat = draw_square(qr_mat, qr_size, x + 1, y + 1, 5, 0)  # inner
    qr_mat = draw_square(qr_mat, qr_size, x + 2, y + 2, 3, 1)  # center
    return qr_mat


# print matrix to console
def print_matrix(qr_mat, qr_size):
    icons = ['⬜', '⬛', '❓', '⬜']
    for i in range(qr_size):
        for j in range(qr_size):
            module = abs(qr_mat[i * qr_size + j])
            if module >= 0 and module <= len(icons) - 1:
                print(icons[module], end='')
            else:
                raise Exception(f"Unknown value '{module}'")
        print('')
    print('')


# generate a matrix for each mask
# https://www.thonky.com/qr-code-tutorial/mask-patterns
def get_masks(qr_size):
    masks = []

    # mask 0 - (x + y) % 2
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if ((x + y) % 2) == 0 else 0
    masks.append(mask)

    # mask 1 - (y % 2)
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if (y % 2) == 0 else 0
    masks.append(mask)

    # mask 2 - (x % 3)
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if (x % 3) == 0 else 0
    masks.append(mask)

    # mask 3 - (x + y) % 3
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if ((x + y) % 3) == 0 else 0
    masks.append(mask)

    # mask 4 - (x // 3 + y // 2) % 2
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if ((x // 3 + y // 2) % 2) == 0 else 0
    masks.append(mask)

    # mask 5 - (x * y % 2) + (x * y % 3)
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if ((x * y % 2) + (x * y % 3)) == 0 else 0
    masks.append(mask)

    # mask 6 - ((x * y) % 2 + x * y % 3) % 2
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if (((x * y) % 2 + x * y % 3) % 2) == 0 else 0
    masks.append(mask)

    # mask 7 - ((x + y) % 2 + x * y % 3) % 2)
    mask = [0] * (qr_size ** 2)
    for y in range(qr_size):
        for x in range(qr_size):
            mask[(y * qr_size) + x] = 1 if (((x + y) % 2 + x * y % 3) % 2) == 0 else 0
    masks.append(mask)

    return masks


# apply mask to QR matrix (not affecting non-function modules)
def apply_mask(mask, qr_mat, qr_size):
    masked = [0] * (qr_size ** 2)

    for y in range(qr_size):
        for x in range(qr_size):
            idx = (y * qr_size) + x
            module = qr_mat[idx]

            # negative is data/err correction
            if module < 0:
                masked[idx] = abs(module) ^ mask[idx]
            else:
                if module == 3:
                    module = 0  # reserved
                masked[idx] = abs(module)
    return masked


# Evaluate penalty for rule 1: each group of 5 or more same-colored modules in a row or col
def eval_rule_1(masked, qr_size):
    row_count = 0
    col_count = 0
    prev_row = 0
    prev_col = 0
    penalty_horizontal = 0
    penalty_vertical = 0
    module = -1

    for y in range(qr_size):
        if module == prev_col:
            col_count += 1
        else:
            col_count = 0

        if col_count == 5:
            penalty_vertical += 3
        elif col_count > 5:
            penalty_vertical += 1

        for x in range(qr_size):
            module = abs(masked[(y * qr_size) + x])
            if module == prev_row:
                row_count += 1
            else:
                row_count = 0

            if row_count == 5:
                penalty_horizontal += 3
            elif row_count > 5:
                penalty_horizontal += 1
            prev_row = module
        row_count = 0
        prev_col = 0

    return penalty_horizontal + penalty_vertical


# Evaluate penalty for rule 2: penalty for each 2x2 area of same colored modules
def eval_rule_2(masked, qr_size):
    return 0


def main():
    # encode payload
    payload = 'https://github.com/barrettotte'
    print(f"encoding payload '{payload}'")
    encoded = encode_byte_mode(payload)
    encoded_len = len(encoded)

    # build segment 0
    err_lvl = ERROR_Q
    version = get_version(encoded_len, err_lvl)
    ec_config = get_ec_config(version, err_lvl)

    mode = int_to_bits(MODE_BYTE, 4)
    count = get_count(encoded_len, version, mode)
    capacity = ec_config[0]
    capacity_bits = capacity * 8

    print(f"size: {encoded_len} byte(s) - char count: {count}")
    print(f"version {version} with max capacity of {capacity} byte(s)", end='')
    print(f" or {capacity_bits} bit(s)")

    # raw with no padding
    seg_0 = mode + count + ''.join(encoded)
    print("before padding: " + byte_size_str(seg_0))

    # add terminator of 0's up to four bits if there's room
    terminal_bits = 0
    while terminal_bits < 4 and len(seg_0) < capacity_bits:
        seg_0 += '0'
        terminal_bits += 1

    # pad bits to nearest byte
    while len(seg_0) % 8 != 0 and len(seg_0 < capacity_bits):
        seg_0 += '0'

    # pad bytes to full capacity (alternating 0xEC and 0x11)
    use_EC = True
    while len(seg_0) < capacity_bits:
        seg_0 += int_to_bits(int(0xEC), 8) if use_EC else int_to_bits(int(0x11), 8)
        use_EC = not use_EC

    print(f'after padding:  {byte_size_str(seg_0)}')
    print("seg_0: {0:0>4X}".format(int(seg_0, 2)))

    # https://www.thonky.com/qr-code-tutorial/error-correction-coding
    code_words = [seg_0[i: i + 8] for i in range(0, len(seg_0), 8)]  # (bytes)
    print(f'total word(s) = {len(code_words)}')

    # split into up to two groups with various blocks of EC words
    # https://www.thonky.com/qr-code-tutorial/error-correction-table
    g1_blocks = []  # only two groups
    g2_blocks = []  # so we can be lazy

    # map error correction confi
    ecw_per_block = ec_config[1]
    g1_block_count = ec_config[2]
    g1_data_block_size = ec_config[3]
    g2_block_count = ec_config[4]
    g2_data_block_size = ec_config[5]

    print(ec_config)
    print(f"error correction code words per block: {ecw_per_block}")
    print(f"data code words per group 1 block: {g1_data_block_size}")
    print(f"data code words per group 2 block: {g2_data_block_size}")

    # build group 1
    cw_idx = 0
    while len(g1_blocks) < g1_block_count:
        to_idx = g1_data_block_size * (len(g1_blocks) + 1)
        g1_blocks.append(code_words[cw_idx: to_idx])
        cw_idx += g1_data_block_size
    assert len(g1_blocks) == g1_block_count

    # build group 2
    g2_offset = cw_idx
    while len(g2_blocks) < g2_block_count:
        to_idx = (g2_data_block_size * (len(g2_blocks) + 1)) + g2_offset
        g2_blocks.append(code_words[cw_idx:to_idx])
        cw_idx += g2_data_block_size
    assert len(g2_blocks) == g2_block_count

    # error correction
    #
    # bit-wise modulo 2 arithmetic
    # byte-wise 100011101 (285) arithmetic
    #    -> Galois field 2^8 == GF(256)
    #    -> x^8 + x^4 + x^3 + x^2 + 1
    #
    # log/antilog and GF(256)
    # 2**2 * 2**8 = 2**(2+8) = 2**10
    # if exponent > 256 add modulo 255
    #   ->  2**170 * 2**164 = 2**(170+164) = 2**334 == 2**(334%255)=2**79
    #
    # message polynomial   - data codewords made in encoding step
    #   used as coefficients. Ex: 25,218,35 => $25x^2+218x+35$
    #
    # generator polynomial - $(x-\alpha^0)\ldots(x-\alpha^{n-1})$
    #   where n is the number of error correction keywords that must be generated
    #
    # https://www.thonky.com/qr-code-tutorial/error-correction-table
    # https://www.thonky.com/qr-code-tutorial/show-division-steps
    # https://www.thonky.com/qr-code-tutorial/generator-polynomial-tool?degree=18

    print('')
    ec_blocks = []

    # group 1 error correction
    for i, block in enumerate(g1_blocks):
        print(f'block {i}')
        print([int(word, 2) for word in block])

        # translate block of data to message polynomial
        msg_poly = galois.block_to_poly(block)
        print(f"\nmsg = {msg_poly}\n")

        # build generator polynomial
        gen_poly = galois.get_gen_poly(ecw_per_block)
        print(f"gen = {gen_poly}\n")

        # ensure lead term doesn't become too small during division
        mono = galois.new_monomial(1, ecw_per_block)
        msg_poly = galois.poly_mul(msg_poly, mono)
        print(f"msg * {mono} = {msg_poly}\n")

        # find error correction words via polynomial long division
        rem_poly = galois.poly_remainder(msg_poly, gen_poly)
        print(f"msg / gen = {rem_poly}\n")
        ec_block = [int_to_bits(word, 8) for word in rem_poly.terms[::-1]]
        print(f"{len(ec_block)} error correction words:\n{[hex(int(word, 2)) for word in ec_block]}")
        assert len(ec_block) == ecw_per_block
        ec_blocks.append(ec_block)
        print('')

    # TODO: group 2

    # interleave data and error correction blocks
    data = []
    for i in range(g1_data_block_size):
        for j in range(len(g1_blocks)):
            data.append(g1_blocks[j][i])
    for i in range(ecw_per_block):
        for j in range(len(ec_blocks)):
            data.append(ec_blocks[j][i])
    print(f"interleaved data - {len(data)} word(s):\n{[hex(int(x, 2)) for x in data]}")

    # add remainder bits
    remainder_bits = REMAINDER_LOOKUP[version]
    print(f"Adding {remainder_bits} remainder bit(s)")
    data = ''.join([x for x in data]) + ('0' * remainder_bits)
    print(f"data - ({len(data)}) bit(s)")
    print(data + '\n\n')

    # populate QR matrix
    qr_size = ((version - 1) * 4) + 21
    qr_mat = [2] * (qr_size ** 2)  # flat list (so asm port is easier)
    print(f"QR matrix : {qr_size} x {qr_size} - {len(qr_mat)} module(s)\n")

    # place reserved areas - finders overlay on top of these
    if version > 7:
        # v > 7 requires more reserved area...lets just skip it
        raise Exception("QR versions greater than 6 are not supported")

    qr_mat = draw_square(qr_mat, qr_size, 0, 0, 9, 3)                  # top left
    qr_mat = draw_square(qr_mat, qr_size, (qr_size - 7) - 1, 0, 9, 3)  # top right
    qr_mat = draw_square(qr_mat, qr_size, 0, (qr_size - 7), 9, 3)      # bottom left

    # place timing patterns
    is_fill = True
    for i in range(qr_size):
        c = 1 if is_fill else 0
        qr_mat[(i) * qr_size + (6)] = c
        is_fill = not is_fill
    is_fill = True
    for j in range(qr_size):
        c = 1 if is_fill else 0
        qr_mat[(6) * qr_size + (j)] = c
        is_fill = not is_fill
    # (x + i + offset) * qr_size + (y + j + offset)

    # place finders
    qr_mat = place_finder(qr_mat, qr_size, 0, 0)              # top left
    qr_mat = place_finder(qr_mat, qr_size, 0, (qr_size - 7))  # top right
    qr_mat = place_finder(qr_mat, qr_size, (qr_size - 7), 0)  # bottom left

    # place alignment pattern
    if version > 1:
        pat = ALIGNMENT_PATTERN_LOOK[version]
        qr_mat = draw_square(qr_mat, qr_size, pat[1] - 2, pat[1] - 2, 5, 1)
        qr_mat = draw_square(qr_mat, qr_size, pat[1] - 1, pat[1] - 1, 3, 0)
        qr_mat = draw_square(qr_mat, qr_size, pat[1], pat[1], 1, 1)

    # place dark module
    qr_mat[((4 * version) + 9) * qr_size + (8)] = 1

    # draw zigzag data
    x = qr_size - 1
    y = qr_size - 1
    data_idx = 0
    zig = True
    up = True

    while data_idx < len(data):
        # reached edge, bounce back
        if y == qr_size:
            up = not up
            x -= 2
            zig = True
            y = qr_size - 1
        elif y < 0:
            up = not up
            x -= 2
            zig = True
            y = 0
        next_mod = qr_mat[(y * qr_size) + x]

        # zig zag past existing structure
        if next_mod == 2:
            # negative so we know what we can and can't mask later
            qr_mat[(y * qr_size) + x] = -int(data[data_idx])
            data_idx += 1

        # zig or zag
        if zig:
            x -= 1
        else:
            y += 1 if not up else -1
            x += 1
        zig = not zig

        # skip over timing patterns
        if x == 6:
            y -= 1
            x -= 1

    # debug print to console
    print_matrix(qr_mat, qr_size)

    # determine best mask
    masks = get_masks(qr_size)
    min_penalty = 99999999
    ideal_mask_idx = -1

    for mask_idx, mask in enumerate(masks):
        penalty = 0
        masked = apply_mask(mask, qr_mat, qr_size)
        print_matrix(masked, qr_size)

        penalty += eval_rule_1(masked, qr_size)
        penalty += eval_rule_2(masked, qr_size)

        if penalty < min_penalty:
            min_penalty = penalty
            ideal_mask_idx = mask_idx

        print(f"mask {mask_idx} : {penalty}\n\n\n")

    print(f"minimum penalty is {min_penalty}. Ideal mask is mask {ideal_mask_idx}")

    # save QR code to bitmap image
    masked = apply_mask(masks[ideal_mask_idx], qr_mat, qr_size)

    fmt_str = int_to_bits(err_lvl, 2) + int_to_bits(ideal_mask_idx, 3) + '0000000000'
    fmt_str = fmt_str.lstrip('0')  # leading zeros must be removed
    print(f"fmt bits: {fmt_str}")
    fmt_poly = galois.Polynomial([int(b) for b in fmt_str])
    print(f"fmt = {fmt_poly}")

    gen_poly = galois.Polynomial([1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1][::-1])
    print(f"gen = {gen_poly}")


if __name__ == '__main__': main()
