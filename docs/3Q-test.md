# Debugging My 3Q Test

Useful GDB commands for my `3Q` test on payload `https://github.com/barrettotte`

## Input Message

`x/30ub &msg`

```
30 characters representing `https://github.com/barrettotte`

0x?????:        104     116     116     112     115     58      47      47
0x?????:        103     105     116     104     117     98      46      99
0x?????:        111     109     47      98      97      114     114     101
0x?????:        116     116     111     116     116     101
```

## Padding the Payload

`x/34ub &payload`

```
34 bytes = mode + char count indicator + encoded message

0x?????:        65      230     135     71      71      7       51      162
0x?????:        242     246     118     151     70      135     86      34
0x?????:        230     54      246     210     246     38      23      39
0x?????:        38      87      71      70      247     71      70      80
0x?????:        236     17
```

## Create the Message Polynomial

Message length = 34 / 2 blocks = 17 words per block

`x/17ub &dw_block`

```
group 1, block 1 = 17 bytes

0x?????:        65      230     135     71      71      7       51      162
0x?????:        242     246     118     151     70      135     86      34
0x?????:        230
```

`x/18ub &msg_poly`

```
byte 1 = 17 terms, bytes 2-18 = terms array

230x^0 + 34x^1 + 86x^2 + 135x^3 + 70x^4 + 151x^5 + 118x^6
  + 246x^7 + 242x^8 + 162x^9 + 51x^10 + 7x^11 + 71x^12 + 71x^13
   + 135x^14 + 230x^15 + 65x^16

0x?????:        17      230     34      86      135     70      151     118
0x?????:        246     242     162     51      7       71      71      135
0x?????:        230     65
```

## Create the Generator Polynomial

Verifying debug outputs from [../jupyter/lunch-and-learn.ipynb](../jupyter/lunch-and-learn.ipynb)

- `x/20ub &gen_poly`
- `x/24ub &gtmpA_poly`
- `x/24ub &gtmpB_poly`
- `x/24ub &prdA_poly`
- `x/24ub &prdB_poly`

set breakpoint to `blt   _gpoly_loop` and repeat `c` and `x/20ub &gen_poly` in GDB

```
- [x]  00:    2     1     1
- [x]  01:    3     2     3     1
- [x]  02:    4     8    14     7     1
- [x]  03:    5    64   120    54    15     1
- [x]  04:    6   116   147    63   198    31     1
- [x]  05:    7    38   227    32   218     1    63     1
- [x]  06:    8   117    68    11   164   154   122   127     1
- [x]  07:    9    24   200   173   239    54    81    11   255     1
- [x]  08:   10    37   197   232   164   235   245   158   207   226     1
- [x]  09:   11   193   157   113    95    94   199   111   159   194   216     1
- [x]  10:   12   160   116   144   248   162   219   123    50   163   130   172     1
- [x]  11:   13    97   213   127    92    84     7    31   220   118    67   119    68     1
- [x]  12:   14   120   132    83    43    46    13    52    17   177    17   227    73   137     1
- [x]  13:   15   163   234   210   166   127   195   158    43   151   174    70   114    54    14     1
- [x]  14:   16    26   134    32   151   132   139   105   105    10    74   112   163   111   196    29     1
- [x]  15:   17    59    36    50    98   229    41    65   163     8    30   209    68   189   104    13    59     1
- [x]  16:   18    79    99   125    53    85   134   143    41   249    83   197    22   119   120    83    66   119     1
- [x]  17:   19   146   217    67    32    75   173    82    73   220   240   215   199   175   149   113   183   251   239     1

Wooo! I literally struggled on this for over a week ... :^)
```

`x/20ub &gen_poly`

```
byte 1 = 19 terms, bytes 2-20 = terms array

146x^0 + 217x^1 + 67x^2 + 32x^3 + 75x^4 + 173x^5 + 82x^6 + 73x^7
  + 220x^8 + 240x^9 + 215x^10 + 199x^11 + 175x^12 + 149x^13 + 113x^14
    + 183x^15 + 251x^16 + 239x^17 + 1x^18

0x?????:        19      146     217     67      32      75      173     82
0x?????:        73      220     240     215     199     175     149     113
0x?????:        183     251     239     1
```

## Reed-Solomon Error Correction

Verifying the rest of the Reed-Solomon error correction steps.

- `x/18ub &msg_poly`
- `x/20ub &gen_poly`

### Message Polynomial Prepare

Ensure lead term doesn't become too small during division.

- `x/35ub &tmpA_poly`
- `x/64ub &tmpB_poly`
- `x/18ub &msg_poly`

```
(1x^18) * msg_poly

byte 1 = 35 terms, bytes 2-35 = terms array

0x^0 + 0x^1 + 0x^2 + 0x^3 + 0x^4 + 0x^5 + 0x^6 + 0x^7 + 0x^8 + 0x^9 + 0x^10
  + 0x^11 + 0x^12 + 0x^13 + 0x^14 + 0x^15 + 0x^16 + 0x^17 + 230x^18 + 34x^19 
    + 86x^20 + 135x^21 + 70x^22 + 151x^23 + 118x^24 + 246x^25 + 242x^26 + 162x^27 
      + 51x^28 + 7x290 + 71x^30 + 71x^31 + 135x^32 + 230x^33 + 65x^34

0x?????:        35      0       0       0       0       0       0       0
0x?????:        0       0       0       0       0       0       0       0
0x?????:        0       0       0       230     34      86      135     70
0x?????:        151     118     246     242     162     51      7       71
0x?????:        71      135     230     65      0       0       0       0
0x?????:        0       0       0       0       0       0       0       0
0x?????:        0       0       0       0       0       0       0       0
0x?????:        0       0       0       0       0       0       0       0
```

### Polynomial Remainder

poly_remainder(msg_poly, gen_poly)

- `x/18ub &msg_poly`
- `x/40ub &tmpA_poly`
- `x/40ub &tmpB_poly`

check `divisor = denominator * mono` => `&tmpC_poly = &gen_poly * &tmp_mono`

- `x/40ub &tmp_mono`
- `x/20ub &gen_poly`
- `x/35ub &tmpC_poly`

check `remainder = remainder + divisor` => `&rem_poly = &rem_poly + &tmpC_poly`

- Byte one should go down each iteration
- `x/35ub &rem_poly`
- `x/35ub &tmpC_poly`

Verify polynomial remainder calculated correctly:

`x/19ub &rem_poly`

**Note: This is for Block 0!**

```
rem_poly = (msg_poly * 1x^18) / (gen_poly)

byte 1 = 18 terms, bytes 2-18 = terms array

202x^0 + 242x^1 + 0x^2 + 131x^3 + 35x^4 + 80x^5 + 198x^6 + 27x^7 + 233x^8
  + 174x^9 + 204x^10 + 245x^11 + 42x^12 + 54x^13 + 168x^14 + 17x^15
    + 51x^16 + 253x^17

0x?????:        18      202     242     0       131     35      80      198
0x?????:        27      233     174     204     245     42      54      168
0x?????:        17      51      253
```

### ECW Block

Verify error correction word block filled correctly.

**Note: This is for Block 0!**

- `x/28ub &ecw_block`
- `x/19ub &rem_poly`

```
18 error correction words (max of 28).

Note: we know the size of the block from the main program. (&ecwb_cap)

0x?????:        253     51      17      168     54      42      245     204
0x?????:        174     233     27      198     80      35      131     0
0x?????:        242     202     0       0       0       0       0       0
0x?????:        0       0       0       0
```


