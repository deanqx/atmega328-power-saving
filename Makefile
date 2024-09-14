SRC_DIR = src
BUILD_DIR = build

O ?= s
port ?= /dev/ttyUSB0
i ?= $(wildcard $(SRC_DIR)/*.c)
OBJS = $(patsubst $(SRC_DIR)/%.c, $(BUILD_DIR)/%.o, $(i))

$(shell	mkdir -p $(BUILD_DIR))

all: build upload

deps:
	sudo apt install -y avr-libc avrdude binutils-avr gcc-avr

deps_dnf:
	sudo dnf install -y avr-libc avrdude avr-binutils.x86_64 avr-gcc.x86_64 

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	avr-gcc -O$(O) -DF_CPU=16000000UL -mmcu=atmega328p -c $< -o $@

build: $(OBJS)
	avr-gcc -O$(O) -mmcu=atmega328p -o $(BUILD_DIR)/compiled.bin $(OBJS)
	avr-objcopy -O ihex -R .eeprom $(BUILD_DIR)/compiled.bin $(BUILD_DIR)/compiled.hex

lsp:
	bear -- make build

upload:
	avrdude -c arduino -p ATMEGA328P -P $(port) -b 115200 -U flash:w:$(BUILD_DIR)/compiled.hex

size: build
	avr-size --format=avr --mcu=atmega328p $(BUILD_DIR)/compiled.bin

asm:
	@mkdir -p $(BUILD_DIR)
	avr-gcc -S -Os -DF_CPU=16000000UL -mmcu=atmega328p -o $(BUILD_DIR)/compiled.asm $(SRC_DIR)/main.c

clean:
	rm -f compile_commands.json
	rm -r $(BUILD_DIR)

.PHONY: all deps upload size clean
