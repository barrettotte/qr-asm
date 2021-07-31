# qr-asm

Generate a QR code image from scratch with ARM assembly.

This was made to learn how QR codes work and to get better with ARM assembly.

## Running Locally

Requires ARM cross compiler - `apt-get install gcc-arm-linux-gnueabihf`

### Debugging with GDB

I'm still new to GDB, but this worked for me.

- `make && make debug`
- `arm-none-eabi-gdb -ex 'file bin/qrcode' -ex 'target remote localhost:1234' -ex 'layout regs'`

## References

- https://www.thonky.com/qr-code-tutorial/
- Reed Solomon Encoding (Computerphile) https://www.youtube.com/watch?v=fBRMaEAFLE0
- https://www.youtube.com/watch?v=Ct2fyigNgPY
- https://en.wikipedia.org/wiki/QR_code#Design
- https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders
- https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI
