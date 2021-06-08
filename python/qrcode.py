# test program to make a QR code from scratch
# reference: https://www.thonky.com/qr-code-tutorial/introduction

# mode indicators
MODE_NUMERIC  = 1 # 0001
MODE_ALPHANUM = 2 # 0010
MODE_BYTE     = 4 # 0100
MODE_KANJI    = 8 # 1000
MODE_ECI      = 7 # 0111

# error correction level bits
ERROR_L = 1  # 01; low
ERROR_M = 0  # 00; medium
ERROR_Q = 3  # 11; quartile
ERROR_H = 2  # 10; high

ERROR_TO_VERSION_MAP = [1, 0, 2, 3] # slight remap of indices

# https://www.thonky.com/qr-code-tutorial/error-correction-table
BYTE_MODE_VERSION_LOOKUP = [
    # L, M, Q, H
    [0, 0, 0, 0],      # (one-indexing)
    [19, 16, 13, 9],   # 1
    [34, 28, 22, 16],  # 2
    [55, 44, 34, 26],  # 3
    # and so on...to 40
]

def is_between(low, high, test): 
    return test >= low and test <= high

# find capacity of version
def get_capacity(version, err_lvl):
    return BYTE_MODE_VERSION_LOOKUP[version][ERROR_TO_VERSION_MAP[err_lvl]]

# find version to use based on payload size and error correction
def get_version(size, err_lvl):
    err_idx = ERROR_TO_VERSION_MAP[err_lvl] 
    for col, row in enumerate(BYTE_MODE_VERSION_LOOKUP):
        if row[err_idx] > size:
            return col
    raise Exception("couldn't find version")

# determine character count indicator
def get_count(s, version, mode):
    size = len(s) 

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
def encode_byte_mode(s):
    as_hex = [c.encode('utf-8').hex() for c in s]
    return [bin(int(byte, 16))[2:].zfill(8) for byte in as_hex]

def main():
    s = 'https://github.com/barrettotte'
    payload = encode_byte_mode(s)
    
    # build segment 0
    err_lvl = ERROR_M
    version = get_version(len(payload), err_lvl)
    capacity = get_capacity(version, err_lvl)
    print(f"version {version} with max capacity of {capacity} byte(s)")

    mode = int_to_bits(MODE_BYTE, 4)
    count = get_count(s, version, mode)
    print(f"size: {len(payload)} byte(s) - count: {count}")

    terminator = '0000'
    seg_0 = mode + count + ''.join(payload) + terminator

    # pad bits to nearest byte
    if len(seg_0) % 8 != 0:
        seg_0 += ((8 - len(seg_0) % 8) * '0') 
    
    # pad bytes to full capacity
    use_EC = True
    while len(seg_0) < (capacity * 8):
        seg_0 += int_to_bits(int(0xEC), 8) if use_EC else int_to_bits(int(0x11), 8)
        use_EC = not use_EC
    
    print(f"segment 0: {len(seg_0)} byte(s)")
    print("    {0:0>4X}".format(int(seg_0, 2)))

    


    
    



if __name__ == '__main__': main()