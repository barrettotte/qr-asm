# qr-asm

Generate a QR code from scratch with only ARM assembly.

<br>
<div align="center">
  <img src="./docs/asm_qrcode.png" alt="QR code to my GitHub profile."/>
  <p>A byte mode QR code of <a href="https://github.com/barrettotte">https://github.com/barrettotte</a> using Q error correction level.
  <br>See <a href="qrcode.pbm">qrcode.pbm</a> for the raw image file.</p>
</div>

## Why?

At first, I learned how QR codes worked with an ugly python implementation; See [docs/python](docs/python).
Midway through the python implementation, I started to learn ARM assembly. But, I had no idea what to build
to practice my knowledge.

So, this project turned into a giant coding challenge just to see if I could do it.
In a world where C exists, you should obviously never use assembly for this type of project/application.

## Usage

`Usage: qrcode msg err_lvl`

valid error levels: `L=1, M=0, Q=3, H=2`

My primary test - `./bin/qrcode "https://github.com/barrettotte" 3`

Quick build and test - `make && make test`

## Limitations

I constrained the QR code generation a lot. I just wanted to encode a url, not build a whole library.

- Byte mode encoding only
- QR version 4 and below (up to 80 characters with v4-L)
- Mask evaluation not implemented, hardcoded to mask 0 (I think masks only effect scan efficiency)
- Instead of implementing an entire image file format, I used the [PBM](https://en.wikipedia.org/wiki/Netpbm) file format to create my QR code image.

### Debugging with GDB

I'm still new to GDB, but this worked for me.

- `make && make qemu`
- `make debug`

For sanity checking this ugly thing, see my notes in [docs/3Q-test.md](docs/3Q-test.md)

## References

- [ARM A32 Calling Convention](https://en.wikipedia.org/wiki/Calling_convention#ARM_(A32))
- [ARM 32-bit EABI Syscall Reference](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI)
- [GNU ARM Assembler Quick Reference](https://www.ic.unicamp.br/~celio/mc404-2014/docs/gnu-arm-directives.pdf)
- [QR Code Design Wiki](https://en.wikipedia.org/wiki/QR_code#Design)
- [QR Code Tutorial](https://www.thonky.com/qr-code-tutorial/)
- [Reed Solomon Codes for Coders](https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders)
- [GDB Command Reference](https://visualgdb.com/gdbreference/commands/x)
- [PBM File Description](https://oceancolor.gsfc.nasa.gov/staff/norman/seawifs_image_cookbook/faux_shuttle/pbm.html)
- [Netpbm Wiki](https://en.wikipedia.org/wiki/Netpbm)
