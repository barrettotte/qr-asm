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

### Verify Generator Polynomial Loop

Verifying debug outputs from [../jupyter/lunch-and-learn.ipynb](../jupyter/lunch-and-learn.ipynb)

- `x/20ub &g_poly`
- `x/24ub &gtmpA_poly`
- `x/24ub &gtmpB_poly`
- `x/24ub &prdA_poly`
- `x/24ub &prdB_poly`
