# qr-asm build file

OUT = bin
BIN = qrcode
BINARGS = "https://github.com/barrettotte" 3

SRC := $(patsubst %.s,%.o,$(wildcard *.s))

AS = arm-none-eabi-as
ASFLAGS = -g

LD = arm-none-eabi-ld
LDFLAGS = 
# LDS = link.ld

GDB = arm-none-eabi-gdb
DBGARGS = -ex 'file $(OUT)/$(BIN)' -ex 'target remote localhost:1234' -ex 'layout regs'

.PHONY:		.FORCE
.FORCE:

all:		clean build link

rebuild: 	all	

build:		$(SRC)
			@echo $(SRC)

%.o : %.s
			$(AS) $(ASFLAGS) $< -o $@

link:
			$(LD) *.o $(LDFLAGS) -o $(OUT)/$(BIN) 

clean:
			@mkdir -p $(OUT)
			rm -f *.o $(OUT)/$(BIN)
			rm -f qrcode.pbm

qemu:		.FORCE
			qemu-arm -singlestep -g 1234 $(OUT)/$(BIN) $(BINARGS)

debug:		.FORCE
			$(GDB) $(DBGARGS)

test:
			./$(OUT)/$(BIN) $(BINARGS)
