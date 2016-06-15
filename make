#!/bin/sh

set -e

EXAMPLE=$1
TARGET=$2
OUTPUT_DIR=build-output/$EXAMPLE
HELPER_DIR=helper-files

if [ "$TARGET" == "clean" ]
then
    rm -rf $OUTPUT_DIR
else
    mkdir -p $OUTPUT_DIR
    ghc \
        --make \
        -Werror \
        -fwarn-unused-imports \
        -isrc \
        -outputdir $OUTPUT_DIR \
        -o $OUTPUT_DIR/$EXAMPLE \
        $EXAMPLE.hs
    cd $OUTPUT_DIR
    ./$EXAMPLE
    if ! [ -n "$ARDUINO_MAKEFILE_PATH" ]; then
        ARDUINO_MAKEFILE_PATH="../../Arduino-Makefile/Arduino.mk"
    fi

    if [ "$TARGET" == "dot" ];
    then
        dot -Tpng -odag.png dag.dot
        xdg-open dag.png
    fi

    FILESC=""
    FILESO=""

    for i in "${@:2}";
    do
      FILESC+=$i
      FILESC+=".c"
      FILESC+=" "
      FILESO+=$i
      FILESO+=".o"
      FILESO+=" "
      cp ../../$HELPER_DIR/$i.c ./
      cp ../../$HELPER_DIR/$i.h ./
    done
    
    avr-gcc -Os -DF_CPU=16000000UL -mmcu=atmega328p -c main.c $FILESC
    avr-gcc -mmcu=atmega328p main.o $FILESO -o main.elf
    avr-objcopy -O ihex -R .eeprom main.elf main.hex
    avrdude -F -V -c arduino -p ATMEGA328P -P /dev/cu.usbmodem1411 -U flash:w:main.hex
fi
