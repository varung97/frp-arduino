# frp-arduino

This repo adds supports for the following features to the frp-arduino library:
<ul>
<li><a href="http://www.cse.chalmers.se/~rjmh/afp-arrows.pdf" target="_blank">Arrows</a></li>
<li>Lifting external C functions to Streams</li>
<li>Ability to output an Analog signal from a pin</li>
</ul>

Haskell code written using this library will be compiled to C code meant for use on an Arduino Uno (See Usage for details on how to compile).

## Usage

Download the Arduino-Makefile library from https://github.com/sudar/Arduino-Makefile. To do so, run `git clone https://github.com/sudar/Arduino-Makefile.git` in the terminal.
<br>
<br>
Also needed is avr-gcc and avrdude. Can be installed by running `brew install avr-gcc` and `brew install avrdude` on Mac and `yum install arduino-core` on Linux (hopefully :P).
<br>
<br>
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
`SF a b` = Function which transforms `Stream a` to `Stream b` (`Stream a -> Stream b`)

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
**&&&** : This infix operator takes 2 Stream functions that act on the same input type and returns a Stream function that applies both functions to an input Stream, giving a Stream of pairs containing the outputs. It is right-associative.
<br>
<br>
*Type*: `SF a b -> SF c d -> SF (a, c) (b, d)`
<br>
__***__ : This infix operator takes 2 Stream functions that can act on different input types and returns a Stream function that takes a Stream of pairs and applies the first function to the first value in the pair and the second function to the second value in the pair. It is right-associative.
<br>
<br>

The first 3 functions in fact form a minimal set of combinators with which all possible wirings can be expressed. Thus, the latter functions are defined in terms of these 3.

## External Streams

Two functions have been added:
<br>
<br>
*Type*: `String -> CType -> String -> Stream a`
<br>
**functionToInputStream** : Takes a function name, a return type (as a CType - see below) and the name of the module where it is defined (if the module is test.c, then function takes "test"). This function assumes the existence of .h files for any module being imported. It calls the external function every clock cycle, and forms a stream of the results. (The external function must have no arguments)
<br>
<br>
*Type*: `String -> CType -> String -> Int -> SF a b`
<br>
**functionToStreamMap** : This function allows passing arguments to an external function from a Stream. The first three parameters of this function are the same as for `functionToInputStream`. It also takes an integer representing the number of arguments that the external function accepts. If this is 0, then the external function will simply be called each time the input stream emits a value. If 1, then the it will be called with each value of the input stream. If 2 or more, then it expects the input stream to be in the form of nested 2-tuples - like (arg1, arg2) or (arg1, (arg2, arg3)) - with the nested tuples forming the second value of the parent tuple.
<br>
<br>
*Type*: `Output ()`
<br>
**nullOutput** : This function creates a null output. It is useful when calling an external function that has a void return type. In such a case, pass the stream calling the function to `nullOutput` using `=:`.
<br>

`CType` = `CBit | CByte | CWord | CVoid | CList CType | CTuple [CType]`

## Analog Output

One function has been added:
<br>
<br>
*Type*: `GPIO -> Output Word`
<br>
**analogOutput** : Takes a pin and returns an Output type which can take a Stream of Words and output that Word through the pin.

## Miscellaneous functions

The following functions have been included:
<br>
*Type*: `Expression Word -> Expression Word -> Expression Word`
<br>
**intDiv** : This function carries out integer division
<br>
<br>
*Type*: `Expression Word -> Expression Word -> Expression Word`
<br>
**intMod** : This function takes the modulus of two numbers
<br>
<br>
*Type*: `Expression Word -> Expression Word -> Expression Word`
<br>
**intExp** : This function raises an integer to the power of another
<br>
<br>
*Type*: `[Expression a] -> Expression [a]`
<br>
**convToList** : This function converts a list of expressions to an expression of a list

## Sources

Arduino library is from the repo frp-arduino/frp-arduino.
<br>
Arduino-Makefile libary is from the repo sudar/Arduino-Makefile.
<br>
Makefile can be found at rgoulter/arduino-atom-examples/tree/master/blink/atom

