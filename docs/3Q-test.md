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

`x/18ub &m_poly`

```
byte 0     = polynomial length = 17
bytes 1-17 = polynomial terms

65x^16 + 230x^15 + 135x^14 + 71x^13 + 
71x^12 + 7x^11  + 51x^10 + 162x^9 + 
242x^8 + 246x^7 + 118x^6 + 151x^5 + 
70x^4 + 135x^3 + 86x^2 + 34x^1 + 
230x^0

Note: stored in order of term exponent

0x?????:        17      230     34      86      135     70      151     118
0x?????:        246     242     162     51      7       71      71      135
0x?????:        230     65
```

## Create the Generator Polynomial

`x/20ub &g_poly`

```
byte     0 = polynomial length = 19
bytes 1-19 = polynomial terms

1x^18 + 239x^17 + 251x^16 + 183x^15 + 
113x^14 + 149x^13 + 175x^12 + 199x^11 + 
215x^10 + 240x^9 + 220x^8 + 73x^7 + 
82x^6 + 173x^5 + 75x^4 + 32x^3 + 
67x^2 + 217x^1 + 146x^0

Note: stored in order of term exponent

```

### Verify Generator Polynomial Iterations

Verifying debug outputs from [../jupyter/lunch-and-learn.ipynb](../jupyter/lunch-and-learn.ipynb)

- `x/20ub &g_poly`
- `x/24ub &gtmpA_poly`
- `x/24ub &gtmpB_poly`
- `x/24ub &prdA_poly`
- `x/24ub &prdB_poly`

set breakpoint to `blt   _gpoly_loop` and repeat `c` and `x/20ub &g_poly` in GDB

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

Wooo! I literally struggled on this for over a week :^)
```
