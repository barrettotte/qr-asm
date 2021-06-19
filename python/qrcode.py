# scratchpad program to make a QR code from scratch.
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
    [[19, 7, 1, 19, 0, 0], [16, 10, 1, 16, 0, 0], [13, 13, 1, 13, 0, 0], [9, 17, 1, 9, 0, 0]],        # 1
    [[34, 10, 1, 34, 0, 0], [28, 16, 1, 28, 0, 0], [22, 22, 1, 22, 0, 0], [16, 28, 1, 16, 0, 0]],      # 2
    [[55, 15, 1, 55, 0, 0], [44, 26, 1, 44, 0, 0], [34, 18, 2, 17, 0, 0], [26, 22, 2, 13, 0, 0]],      # 3
    [[80, 20, 1, 80, 0, 0], [64, 18, 2, 32, 0, 0], [48, 26, 2, 24, 0, 0], [36, 16, 4, 9, 0, 0]],       # 4
    [[108, 26, 1, 108, 0, 0], [86, 24, 2, 43, 0, 0], [62, 18, 2, 15, 2, 16], [46, 22, 2, 11, 2, 12]],  # 5
    # and so on...to 40
]

# adjust indices for lookup tables based on error level
ERROR_IDX_TO_LOOKUP = [1, 0, 3, 2]


# calculate generator polynomial
def get_gen_poly(degree):
    pass


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
    group_1 = []  # only two groups
    group_2 = []  # so we can be lazy

    # map error correction confi
    ecw_per_block = ec_config[1]
    g1_blocks = ec_config[2]
    ecw_per_g1_blocks = ec_config[3]
    g2_blocks = ec_config[4]
    ecw_per_g2_blocks = ec_config[5]

    print(ec_config)
    print(f"error correction code words per block: {ecw_per_block}")
    print(f"error correction code words per group 1 block: {ecw_per_g1_blocks}")
    print(f"error correction code words per group 2 block: {ecw_per_g2_blocks}")

    # build group 1
    cw_idx = 0
    while len(group_1) < g1_blocks:
        to_idx = ecw_per_g1_blocks * (len(group_1) + 1)
        # print(f'{cw_idx}:{to_idx}')
        group_1.append(code_words[cw_idx: to_idx])
        cw_idx += ecw_per_g1_blocks
    assert len(group_1) == g1_blocks

    print(f"\ngroup 1 - {len(group_1)} block(s)")
    for i, block in enumerate(group_1):
        print(f'\nblock {i+1} - {len(block)} word(s)')
        for j, word in enumerate(block):
            print(word, end=' ')
            print("(0x{0:0>2X})".format(int(word, 2)), end='   ')
            if (j + 1) % 4 == 0:
                print('')

    # build group 2
    group2_offset = cw_idx
    while len(group_2) < g2_blocks:
        to_idx = (ecw_per_g2_blocks * (len(group_2) + 1)) + group2_offset
        group_2.append(code_words[cw_idx:to_idx])
        cw_idx += ecw_per_g2_blocks
    assert len(group_2) == g2_blocks

    print(f"\n\ngroup 2 - {len(group_2)} block(s)")
    for i, block in enumerate(group_2):
        print(f'\n\nblock {i+1} - {len(block)} word(s)\n')
        for j, word in enumerate(block):
            print(word, end=' ')
            print("(0x{0:0>2X})".format(int(word, 2)), end='   ')
            if (j + 1) % 4 == 0:
                print('')

    # error correction
    #
    # asm notes:
    #   - use log/antilog to calculate exponent and lookup in
    #     table w/alpha notation
    #
    # bit-wise modulo 2 arithmetic
    # byte-wise 100011101 (285) arithmetic
    #    -> Galois field 2^8 == GF(256)
    #    -> x^8 + x^4 + x^3 + x^2 + 1
    #
    # 2**8 = 256 ^ 285 = 29
    # when going to 2**9 don't use 512, use 2**9 = 2**8 * 2 = 29 * 2 = 58
    #
    # when a value >= 256, XOR with 285 again
    #     -> 2**12 = 2**11 * 2 = 232 * 2 = 464 ^ 285 = 205
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
    #   where n is the number of error correction keywords that
    #   must be generated
    #   https://www.thonky.com/qr-code-tutorial/error-correction-table
    #
    # https://www.thonky.com/qr-code-tutorial/show-division-steps
    # https://www.thonky.com/qr-code-tutorial/generator-polynomial-tool?degree=18

    print('')

    # group 1 error correction
    for i, block in enumerate(group_1):
        print(f'block {i}')
        print([int(word, 2) for word in block])

        msg_poly = galois.block_to_poly(block)
        print(f"\nmsg = \n    {msg_poly}\n")

        mono = galois.new_monomial(1, ecw_per_block)
        msg_poly = galois.poly_mul(msg_poly, mono)
        print(f"msg * {mono} = \n    {msg_poly}\n")

        gen_poly = galois.get_gen_poly(ecw_per_block)
        print(f"gen = \n    {gen_poly}")

        # lead term of gen polynomial and msg polynomial should have same degree
        # deg = msg_poly.get_degree() - gen_poly.get_degree()
        # mono = galois.new_monomial(1, deg)
        # gen_poly = galois.poly_mul(gen_poly, mono)
        # print(f"gen * {mono} = \n    {gen_poly}")
        # assert gen_poly.get_degree() == msg_poly.get_degree()
        # print(f" gen = \n    {gen_poly.str_alpha()}")

        # multiply gen polynomial by lead term of message polynomial
        # lead = msg_poly.terms[-1]
        # gen_poly = galois.poly_alpha_mul(gen_poly, galois.GF256_LOG[lead])
        # print(f"gen * α^{lead} = \n    {gen_poly}")

        # find error correction bytes via polynomial long division
        rem_poly = galois.poly_remainder(msg_poly, gen_poly)
        print(f"rem = \n    {rem_poly}")
        ec_bytes = [hex(x) for x in rem_poly.terms[::-1]]
        print(f"EC bytes: {ec_bytes}")
        assert len(ec_bytes) == ecw_per_block

        print('')
        break


if __name__ == '__main__': main()
