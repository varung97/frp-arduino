CC = avr-gcc
OBJ_COPY = avr-objcopy

F_CPU = 16000000
MCU = atmega328p


PROGRAMMER = arduino
BOARD = ATMEGA328P
PORT = /dev/cu.usbmodem1411


MAIN_FILE = main

# Note about Makefile vars:
# https://www.gnu.org/software/make/manual/html_node/Static-Usage.html
#   $< prereq
#   $@ output

# The first command line takes the C source file and compiles it into an object
# file. The options tell the compilerto optimize for code size,what is the
# clock frequency (it’s useful for delay functions for example) and which is
# the processor for which to compile code.
%.o: %.c
	$(CC) -Os -DF_CPU=$(F_CPU)UL -mmcu=$(MCU) -c -o $@ $<

# The second commands links the object file together with system libraries
# (that are linked implicitly as needed) into an ELF program.
%.elf: %.o
	$(CC) -mmcu=$(MCU) $< -o $@

# The third command converts the ELF program into an IHEX file.
%.hex: %.elf
	$(OBJ_COPY) -O ihex -R .eeprom $< $@

build: $(MAIN_FILE).hex

# The fourth command uploads the IHEX data ito the Atmega chip embedded flash,
# and the options tells avrdude program to communicate using the Arduino serial
# protocol, through a particular serial port which is the Linux device
# “/dev/ttyACM0“, and to use 115200bps as the data rate.
upload: build
	avrdude -F -V -c $(PROGRAMMER) -p $(BOARD) -P $(PORT) -U flash:w:$(MAIN_FILE).hex

clean:
	rm -f *.c *.h
	rm -f *.hex *.elf *.o

.PHONY: build upload clean
