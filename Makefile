# qr-asm build file

AS = arm-none-eabi-as
LD = arm-none-eabi-ld

OUT = bin
BIN = qrcode
SRC := $(patsubst %.s,%.o,$(wildcard *.s))

all:		clean build

rebuild: 	all	

build:		$(SRC)
			@echo $(SRC)

%.o : %.s
			$(AS) -g $< -o $@
			$(LD) *.o -o $(OUT)/$(BIN)

clean:
			@mkdir -p $(OUT)
			rm -f *.o $(OUT)/$(BIN)

debug:
			qemu-arm -singlestep -g 1234 $(OUT)/$(BIN)

# make && make debug
# arm-none-eabi-gdb -ex 'file bin/qrcode' -ex 'target remote localhost:1234' -ex 'layout regs'
