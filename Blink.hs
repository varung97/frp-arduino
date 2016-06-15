import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do

    let funcStream2 = funcToStreamMap "test1" "int" "test1"
    digitalOutput pin5 =: clock ~> funcStream2 >>> foldpS (\_ -> flipBit) bitLow
