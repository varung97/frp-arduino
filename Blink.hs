import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do

    let stream = funcToStream "test" "int" ["test.h"]
    let stream1 = funcToStream "test1" "int" ["test1.h"]
    digitalOutput pin3 =: stream
    digitalOutput pin5 =: stream1
