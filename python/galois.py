# all the mess of dealing with galois field arithmetic and polynomials

GF256_ANTILOG = [
    1, 2, 4, 8, 16, 32, 64, 128, 29, 58,               # 0 - 9
    116, 232, 205, 135, 19, 38, 76, 152, 45, 90,       # 10 - 19
    180, 117, 234, 201, 143, 3, 6, 12, 24, 48,         # 20 - 29
    96, 192, 157, 39, 78, 156, 37, 74, 148, 53,        # 30 - 39
    106, 212, 181, 119, 238, 193, 159, 35, 70, 140,    # 40 - 49
    5, 10, 20, 40, 80, 160, 93, 186, 105, 210,         # 50 - 59
    185, 111, 222, 161, 95, 190, 97, 194, 153, 47,     # 60 - 69
    94, 188, 101, 202, 137, 15, 30, 60, 120, 240,      # 70 - 79
    253, 231, 211, 187, 107, 214, 177, 127, 254, 225,  # 80 - 89
    223, 163, 91, 182, 113, 226, 217, 175, 67, 134,    # 90 - 99
    17, 34, 68, 136, 13, 26, 52, 104, 208, 189,        # 100 - 109
    103, 206, 129, 31, 62, 124, 248, 237, 199, 147,    # 110 - 119
    59, 118, 236, 197, 151, 51, 102, 204, 133, 23,     # 120 - 129
    46, 92, 184, 109, 218, 169, 79, 158, 33, 66,       # 130 - 139
    132, 21, 42, 84, 168, 77, 154, 41, 82, 164,        # 140 - 149
    85, 170, 73, 146, 57, 114, 228, 213, 183, 115,     # 150 - 159
    230, 209, 191, 99, 198, 145, 63, 126, 252, 229,    # 160 - 169
    215, 179, 123, 246, 241, 255, 227, 219, 171, 75,   # 170 - 179
    150, 49, 98, 196, 149, 55, 110, 220, 165, 87,      # 180 - 189
    174, 65, 130, 25, 50, 100, 200, 141, 7, 14,        # 190 - 199
    28, 56, 112, 224, 221, 167, 83, 166, 81, 162,      # 200 - 209
    89, 178, 121, 242, 249, 239, 195, 155, 43, 86,     # 210 - 219
    172, 69, 138, 9, 18, 36, 72, 144, 61, 122,         # 220 - 229
    244, 245, 247, 243, 251, 235, 203, 139, 11, 22,    # 230 - 239
    44, 88, 176, 125, 250, 233, 207, 131, 27, 54,      # 240 - 249
    108, 216, 173, 71, 142, 1                          # 250 - 255
]

GF256_LOG = [
    -1, 0, 1, 25, 2, 50, 26, 198, 3, 223,              # 0 - 9
    51, 238, 27, 104, 199, 75, 4, 100, 224, 14,        # 10 - 19
    52, 141, 239, 129, 28, 193, 105, 248, 200, 8,      # 20 - 29
    76, 113, 5, 138, 101, 47, 225, 36, 15, 33,         # 30 - 39
    53, 147, 142, 218, 240, 18, 130, 69, 29, 181,      # 40 - 49
    194, 125, 106, 39, 249, 185, 201, 154, 9, 120,     # 50 - 59
    77, 228, 114, 166, 6, 191, 139, 98, 102, 221,      # 60 - 69
    48, 253, 226, 152, 37, 179, 16, 145, 34, 136,      # 70 - 79
    54, 208, 148, 206, 143, 150, 219, 189, 241, 210,   # 80 - 89
    19, 92, 131, 56, 70, 64, 30, 66, 182, 163,         # 90 - 99
    195, 72, 126, 110, 107, 58, 40, 84, 250, 133,      # 100 - 109
    186, 61, 202, 94, 155, 159, 10, 21, 121, 43,       # 110 - 119
    78, 212, 229, 172, 115, 243, 167, 87, 7, 112,      # 120 - 129
    192, 247, 140, 128, 99, 13, 103, 74, 222, 237,     # 130 - 139
    49, 197, 254, 24, 227, 165, 153, 119, 38, 184,     # 140 - 149
    180, 124, 17, 68, 146, 217, 35, 32, 137, 46,       # 150 - 159
    55, 63, 209, 91, 149, 188, 207, 205, 144, 135,     # 160 - 169
    151, 178, 220, 252, 190, 97, 242, 86, 211, 171,    # 170 - 179
    20, 42, 93, 158, 132, 60, 57, 83, 71, 109,         # 180 - 189
    65, 162, 31, 45, 67, 216, 183, 123, 164, 118,      # 190 - 199
    196, 23, 73, 236, 127, 12, 111, 246, 108, 161,     # 200 - 209
    59, 82, 41, 157, 85, 170, 251, 96, 134, 177,       # 210 - 219
    187, 204, 62, 90, 203, 89, 95, 176, 156, 169,      # 220 - 229
    160, 81, 11, 245, 22, 235, 122, 117, 44, 215,      # 230 - 239
    79, 174, 213, 233, 230, 231, 173, 232, 116, 214,   # 240 - 249
    244, 234, 168, 80, 88, 175                         # 250 - 255
]

GF256_SIZE = 256
PRIMITIVE_POLYNOMIAL = 285


# addition in galois field 256
def gf256_add(a: int, b: int):
    return a ^ b


# subtraction in galois field 256 (same as addition in this field)
def gf256_sub(a: int, b: int):
    return a ^ b


# multiplication in galois field 256 using lookup table
def gf256_mul(a: int, b: int):
    if a == 0 or b == 0:
        return 0
    return GF256_ANTILOG[(GF256_LOG[a] + GF256_LOG[b]) % (GF256_SIZE - 1)]


# division in galois field 256 (using lookup table)
def gf256_div(a: int, b: int):
    if a == 0:
        return 0
    elif b == 0:
        raise Exception("div by zero in GF")
    return gf256_mul(a, gf256_inv(b))


# multiplicative inverse of a -> $a^{-1}$
def gf256_inv(a: int):
    if a == 0:
        raise Exception("Zero has no inverse")
    return GF256_ANTILOG[(GF256_SIZE - 1) - GF256_LOG[a]]


class Polynomial():

    def __init__(self, terms: list):
        self.terms = terms

    def __str__(self):
        return ' + '.join([f"{t}x^{len(self.terms) - i - 1}" for i, t in enumerate(self.terms[::-1]) if t > 0])

    # return __str__ in alpha notation
    def str_alpha(self):
        return ' + '.join([f"α^{GF256_LOG[t]}x^{len(self.terms) - i - 1}" for i, t in enumerate(self.terms[::-1]) if t > 0])

    # return degree of polynomial
    def get_degree(self):
        return len(self.terms) - 1

    # determine if two polynomials are equivalent
    def equals(self, other):
        if len(self.terms) > len(other.terms):
            min_poly = other
            max_poly = self
        else:
            min_poly = self
            max_poly = other

        for i in range(len(min_poly.terms)):
            if self.terms[i] != other.terms[i]:
                return False
        for i in range(len(min_poly.terms), len(max_poly.terms)):
            if max_poly.terms[i] != 0:
                return False
        return True


# create new polynomial from a block of words
# each word becomes the coefficient of an x term
def block_to_poly(block: list):
    terms = ([int(w, 2) for w in block])[::-1]
    return Polynomial(terms)


# multiply polynomial by alpha value
def poly_alpha_mul(p: Polynomial, alpha: int):
    for i, t in enumerate(p.terms):
        # print(GF256_ANTILOG[GF256_LOG[t]])
        t_alpha = (GF256_LOG[t] + alpha) % (GF256_SIZE - 1)
        p.terms[i] = GF256_ANTILOG[t_alpha]
    return p


# normalize polynomial
def poly_normalize(p: Polynomial):
    max_nz = len(p.terms) - 1  # max nonzero term
    for i in range(len(p.terms) - 1, 0, -1):
        if p.terms[i] != 0:
            break
        max_nz = i - 1

    if max_nz < 0:
        return Polynomial([0])
    elif max_nz < (len(p.terms) - 1):
        p.terms = p.terms[0: max_nz + 1]
    return p


# add two polynomials
def poly_add(a: Polynomial, b: Polynomial):
    term_len = len(a.terms)
    if len(b.terms) > term_len:
        term_len = len(b.terms)

    p = Polynomial([0] * term_len)

    for i in range(term_len):
        if len(a.terms) > i and len(b.terms) > i:
            p.terms[i] = gf256_add(a.terms[i], b.terms[i])
        elif len(a.terms) > i:
            p.terms[i] = a.terms[i]
        else:
            p.terms[i] = b.terms[i]
    return poly_normalize(p)


# multiply two polynomials
def poly_mul(a: Polynomial, b: Polynomial):
    p = Polynomial([0] * (len(a.terms) + len(b.terms)))

    for i in range(len(a.terms)):
        for j in range(len(b.terms)):
            if a.terms[i] != 0 and b.terms[j] != 0:
                monomial = Polynomial([0] * (i + j + 1))
                monomial.terms[i + j] = gf256_mul(a.terms[i], b.terms[j])
                p = poly_add(p, monomial)
    return poly_normalize(p)


# perform polynomial long division and return remainder polynomial
def poly_remainder(numerator: Polynomial, denominator: Polynomial):
    if numerator.equals(denominator):
        raise Exception("Remainder is zero")
    remainder = numerator

    while len(remainder.terms) >= len(denominator.terms):
        degree = len(remainder.terms) - len(denominator.terms)
        coefficient = gf256_div(remainder.terms[-1], denominator.terms[-1])

        divisor = poly_mul(denominator, new_monomial(coefficient, degree))
        remainder = poly_add(remainder, divisor)
    return poly_normalize(remainder)


# create a monomial (single term polynomial) with given term and degree
def new_monomial(term: int, degree: int):
    if term == 0:
        return Polynomial([0])
    mono = Polynomial([0] * (degree + 1))
    mono.terms[degree] = term
    return mono


# create generator polynomial for GF256
def get_gen_poly(degree: int):
    if degree < 2:
        raise Exception('generator polynomial degree must be greater than 2')

    gp = Polynomial([1])
    for i in range(degree):
        np = Polynomial([GF256_ANTILOG[i], 1])
        gp = poly_mul(gp, np)
    return gp
