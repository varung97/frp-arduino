import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do

    digitalOutput pin5 =: analogRead a0 ~> funcToStreamMap "test" CWord "test"
