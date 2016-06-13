# frp-arduino

Arduino library is from the repo frp-arduino/frp-arduino. This repo adds supports for arrows to the original library.
Arduino-Makefile libary is from the repo sudar/Arduino-Makefile.
Makefile can be found at rgoulter/arduino-atom-examples/tree/master/blink/atom

Link to a paper on arrows:
http://www.cse.chalmers.se/~rjmh/afp-arrows.pdf

Running `./make fileName` will compile the file and upload to an Arduino Uno on port /dev/cu.usbmodem1411
If the shell throws an error while linking, then first run `./make fileName clean` and then `./make fileName`
