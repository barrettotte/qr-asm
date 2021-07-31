# qr-asm build file

BIN = qrcode
SRC := $(wildcard ./*.s)

all:	clean build

build:
		arm-none-eabi-as $(SRC) -g -o $(BIN).o
		arm-none-eabi-ld $(BIN).o -o bin/$(BIN)

clean:
		rm -f ./*.o bin/$(BIN)

debug:
		qemu-arm -singlestep -g 1234 bin/$(BIN)

# make && make debug
# arm-none-eabi-gdb -ex 'file bin/qrcode' -ex 'target remote localhost:1234' -ex 'layout regs'
