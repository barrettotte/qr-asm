# qr-asm

Generate a QR code image from scratch with ARM assembly.

This was made to learn how QR codes work and to get better with ARM assembly.

## Disclaimer

If its not obvious I'm bad at assembly...I'm sure there are a disgusting amount of optimizations I could have done. 
But, I tried to keep things simple so a dummy like me could understand this a year from now.

Specifically, I didn't really leverage 32-bit word size or ARM's fancy optional shifting on each instruction.

## QR Code Limitations

I constrained the QR code generation a lot. I just wanted to encode a url, not build a whole library.

- Byte mode encoding only
- QR version 4 and below (up to 80 characters with v4-L)
- Mask evaluation not implemented, hardcoded to ?

## Running Locally

Requires ARM cross compiler - `apt-get install gcc-arm-linux-gnueabihf`

### Debugging with GDB

I'm still new to GDB, but this worked for me.

- `make && make debug`
- `arm-none-eabi-gdb -ex 'file bin/qrcode' -ex 'target remote localhost:1234' -ex 'layout regs'`

## References

- [ARM A32 Calling Convention](https://en.wikipedia.org/wiki/Calling_convention#ARM_(A32))
- [ARM 32-bit EABI Syscall Reference](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI)
- [GNU ARM Assembler Quick Reference](https://www.ic.unicamp.br/~celio/mc404-2014/docs/gnu-arm-directives.pdf)
- [QR Code Design Wiki](https://en.wikipedia.org/wiki/QR_code#Design)
- [QR Code Tutorial](https://www.thonky.com/qr-code-tutorial/)
- [Reed Solomon Codes for Coders](https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders)
