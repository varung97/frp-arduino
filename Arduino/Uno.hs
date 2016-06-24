-- Copyright (c) 2014 Contributors as noted in the AUTHORS file
--
-- This file is part of frp-arduino.
--
-- frp-arduino is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- frp-arduino is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with frp-arduino.  If not, see <http://www.gnu.org/licenses/>.

module Arduino.Uno
    ( module Arduino.DSL
    , module Arduino.Library
    -- * GPIO
    , GPIO()
    , digitalOutput
    , digitalRead
    , pin3
    , pin4
    , pin5
    , pin6
    , pin7
    , pin8
    , pin10
    , pin11
    , pin12
    , pin13
    -- * Analog input
    , AnalogInput()
    , analogOutput
    , analogRead
    , a0
    -- * UART
    , uart
    -- * Clock
    -- | Uses TCNT1 on the Uno to make things happend at specific time
    -- intervals.
    , timerDelta
    , every
    , clock
    , timeSecond
    ) where

import Arduino.DSL
import Arduino.Library
import Data.Bits (shiftR, (.&.), testBit)
import Prelude hiding (Word)

data GPIO = GPIO
    { name              :: String
    , directionRegister :: String
    , portRegister      :: String
    , pinRegister       :: String
    , bitName           :: String
    , timer             :: Maybe String
    , comPort           :: Maybe String
    , timerOutput       :: Maybe String
    }

data AnalogInput = AnalogInput
    { analogName :: String
    , mux        :: Int
    }

-- For mappings, see http://arduino.cc/en/Hacking/PinMapping168

pin3 :: GPIO
pin3 = GPIO "pin3" "DDRD" "PORTD" "PIND" "PD3" (Just "TCCR2") (Just "COM2B1") (Just "OCR2B")

pin4 :: GPIO
pin4 = GPIO "pin4" "DDRD" "PORTD" "PIND" "PD4" Nothing Nothing Nothing

pin5 :: GPIO
pin5 = GPIO "pin5" "DDRD" "PORTD" "PIND" "PD5" (Just "TCCR0") (Just "COM2B1") (Just "OCR0B")

pin6 :: GPIO
pin6 = GPIO "pin6" "DDRD" "PORTD" "PIND" "PD6" (Just "TCCR0") (Just "COM2A1") (Just "OCR0A")

pin7 :: GPIO
pin7 = GPIO "pin7" "DDRD" "PORTD" "PIND" "PD7" Nothing Nothing Nothing

pin8 :: GPIO
pin8 = GPIO "pin8" "DDRB" "PORTB" "PINB" "PB0" Nothing Nothing Nothing

pin10 :: GPIO
pin10 = GPIO "pin10" "DDRB" "PORTB" "PINB" "PB2" Nothing Nothing Nothing

pin11 :: GPIO
pin11 = GPIO "pin11" "DDRB" "PORTB" "PINB" "PB3" (Just "TCCR2") (Just "COM2A1") (Just "OCR2A")

pin12 :: GPIO
pin12 = GPIO "pin12" "DDRB" "PORTB" "PINB" "PB4" Nothing Nothing Nothing

pin13 :: GPIO
pin13 = GPIO "pin13" "DDRB" "PORTB" "PINB" "PB5" Nothing Nothing Nothing

uart :: Output Byte
uart =
    let ubrr = floor ((16000000 / (16 * 9600)) - 1)
        ubrrlValue = ubrr .&. 0xFF
        ubrrhValue = shiftR ubrr 8 .&. 0xFF
    in
    createOutput
        "uart"
        (writeByte "UBRR0H" (byteConstant ubrrhValue) $
         writeByte "UBRR0L" (byteConstant ubrrlValue) $
         setBit "UCSR0C" "UCSZ01" $
         setBit "UCSR0C" "UCSZ00" $
         setBit "UCSR0B" "RXEN0" $
         setBit "UCSR0B" "TXEN0" $
         end)
        (\byte ->
         waitBitSet "UCSR0A" "UDRE0" $
         writeByte "UDR0" byte $
         end)

digitalOutput :: GPIO -> Output Bit
digitalOutput gpio =
    createOutput
        (name gpio)
        (setBit (directionRegister gpio) (bitName gpio) $
         end)
        (\bit ->
         writeBit (portRegister gpio) (bitName gpio) bit $
         end)

digitalRead :: GPIO -> Stream Bit
digitalRead gpio = createInput
    (name gpio)
    (clearBit (directionRegister gpio) (bitName gpio) $
     setBit (portRegister gpio) (bitName gpio) $
     end)
    (readBit (pinRegister gpio) (bitName gpio))

a0 :: AnalogInput
a0 = AnalogInput "a0" 0

analogOutput :: GPIO -> Output Word
analogOutput gpio =
  let
    timerGPIO =
      case timer gpio of
        Just pinTimer -> pinTimer
        Nothing -> error "Pin does not support Analog Output"
    comPortGPIO =
      case comPort gpio of
        Just port -> port
        Nothing -> error "Pin does not support Analog Output"
    timerOutputGPIO =
      case timerOutput gpio of
        Just timerOut -> timerOut
        Nothing -> error "Pin does not support Analog Output"
  in
    createOutput
        (name gpio)
        (setBit (directionRegister gpio) (bitName gpio) $
         setBit (timerGPIO ++ "A") (comPortGPIO) $
         setBit (timerGPIO ++ "A") ("WGM21") $
         setBit (timerGPIO ++ "A") ("WGM20") $
         setBit (timerGPIO ++ "B") ("CS22") $
         end)
        (\value ->
         writeWord (timerOutputGPIO) value $
         end)

analogRead :: AnalogInput -> Stream Word
analogRead an = createInput
    (analogName an)
    (setBit "ADCSRA" "ADEN" $
     setBit "ADMUX" "REFS0" $
     setBit "ADCSRA" "ADPS2" $
     setBit "ADCSRA" "ADPS1" $
     setBit "ADCSRA" "ADPS0" $
     end)
    ((if (testBit (mux an) 3) then setBit else clearBit) "ADMUX" "MUX3" $
     (if (testBit (mux an) 2) then setBit else clearBit) "ADMUX" "MUX2" $
     (if (testBit (mux an) 1) then setBit else clearBit) "ADMUX" "MUX1" $
     (if (testBit (mux an) 0) then setBit else clearBit) "ADMUX" "MUX0" $
     setBit "ADCSRA" "ADSC" $
     waitBitCleared "ADCSRA" "ADSC" $
     readTwoPartWord "ADCL" "ADCH" $
     end)

timerDelta :: Stream Word
timerDelta = createInput
    "timer"
    (setBit "TCCR1B" "CS12" $
     setBit "TCCR1B" "CS10" $
     end)
    (readWord "TCNT1" $
     writeWord "TCNT1" (wordConstant 0) $
     end)

every :: Expression Word -> Stream Word
every limit = accumulatorConstLimit limit timerDelta ~> count

clock :: Stream Word
clock = every 10000

timeSecond :: Expression Word
timeSecond = 16000
