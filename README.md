# frp-arduino

This repo adds supports for the following features to the frp-arduino library:
<ul>
<li><a href="http://www.cse.chalmers.se/~rjmh/afp-arrows.pdf" target="_blank">Arrows</a></li>
<li>Lifting external C functions to Streams</li>
<li>Ability to output an Analog signal from a pin</li>
</ul>

Haskell code written using this library will be compiled to C code meant for use on an Arduino Uno (See Usage for details on how to compile).

## Usage

Running `./make fileName` will compile the file and upload to an Arduino Uno on port /dev/cu.usbmodem1411<br>
Example: To compile Blink.hs, run `./make Blink`
<br>
<br>
If the shell throws an error while linking, then first run `./make fileName clean` and then `./make fileName`
<br>
<br>
To compile other c files along with the Haskell file, run `./make HSFileName CFileName1 CFileName2 ...`<br>
The other c files should be placed in a helper-files directory<br>
Example: To compile Blink.hs along with helper-file/test.c, run `./make Blink test`
<br>
<br>
The output is written to build-output/fileName

## Arrow functionality

Notation used below:
<br>
SF a b = Function which transforms Stream a to Stream b (Stream a -> Stream b)

The arrow functions that have been added are:
<br>
*Type*: `SF a b -> SF b c -> SF a c`
<br>
**\>>>** : This infix operator takes an `SF a b` and an `SF b c` and returns an `SF a c`. Essentially this is function composition, but it takes arguments in reverse order
<br>
<br>
*Type*: `(Expression a -> Expression b) -> SF a b`
<br>
**arr** : This function take a normal function and lifts it to Streams. The function must act on Expression types (for conversion to the DSL)
<br>
<br>
*Type*: `SF a b -> SF (a, c) (b, c)`
<br>
**first** : This takes a Stream function and returns a Stream function that takes a pair and applies the function to only the first value in the pair
<br>
<br>
*Type*: `SF a b -> SF (c, a) (c, b)`
<br>
**second** : Same as first, only it applies the function to the second value in the pair
<br>
<br>
*Type*: `SF a b -> SF a c -> SF a (b, c)`
<br>
**&&&** : This infix operator takes 2 Stream functions that act on the same input type and returns a Stream function that applies both functions to an input Stream, giving a Stream of pairs containing the outputs
<br>
<br>
*Type*: `SF a b -> SF c d -> SF (a, c) (b, d)`
<br>
__***__ : This infix operator takes 2 Stream functions that can act on different input types and returns a Stream function that takes a Stream of pairs and applies the first function to the first value in the pair and the second function to the second value in the pair
<br>
<br>

The first 3 functions in fact form a minimal set of combinators with which all possible wirings can be expressed. Thus, the latter functions are defined in terms of these 3.

## External Streams

Two functions have been added:
<br>
<br>
*Type*: `String -> String -> String -> Stream a`
<br>
**functionToStream** : Takes a function name, a return type and the name of the module where it is defined (if the module is test.c, then function take "test"). This function assumes the existence of .h files for any module being imported.
<br>
<br>
*Type*: `String -> String -> String -> SF a b`
<br>
**functionToStreamMap** : Same inputs as functionToStream, returns a stream transformer that will emit the return value of the external function every time a value is received from the input stream. In other words, maps an input stream to the return value of the external function at that time. Useful if the rate of calling the function needs to be controlled with a clock.

## Analog Output

One function has been added:
<br>
<br>
*Type*: `GPIO -> Output Word`
<br>
**analogOutput** : Takes a pin and returns an Output type which can take a Stream of Words and output that Word through the pin.

## Sources

Arduino library is from the repo frp-arduino/frp-arduino.
<br>
Arduino-Makefile libary is from the repo sudar/Arduino-Makefile.
<br>
Makefile can be found at rgoulter/arduino-atom-examples/tree/master/blink/atom

