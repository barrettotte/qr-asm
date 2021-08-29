# qr-asm build file

AS = arm-none-eabi-as
LD = arm-none-eabi-ld
GDB = arm-none-eabi-gdb

OUT = bin
BIN = qrcode
SRC := $(patsubst %.s,%.o,$(wildcard *.s))

all:		clean build link

rebuild: 	all	

build:		$(SRC)
			@echo $(SRC)

%.o : %.s
			$(AS) -g $< -o $@

link:
			$(LD) *.o -o $(OUT)/$(BIN)

clean:
			@mkdir -p $(OUT)
			rm -f *.o $(OUT)/$(BIN)

qemu:
			qemu-arm -singlestep -g 1234 $(OUT)/$(BIN)

debug:  
            $(GDB) -ex 'file $(OUT)/$(BIN)' -ex 'target remote localhost:1234' -ex 'layout regs'
