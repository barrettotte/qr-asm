# qr-asm

Generate a QR code image from scratch with ARM assembly.

- ARM cross compiler - ```apt-get install gcc-arm-linux-gnueabihf```
- QEMU - ```apt-get install qemu-user```
- Cross compile ARM - ```arm-linux-gnueabihf-gcc -static pgm.s -o bin/pgm; qemu-arm bin/pgm```

## References

- https://www.thonky.com/qr-code-tutorial/
- Reed Solomon Encoding (Computerphile) https://www.youtube.com/watch?v=fBRMaEAFLE0
- https://www.youtube.com/watch?v=Ct2fyigNgPY
- https://en.wikipedia.org/wiki/QR_code#Design
- https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders
