import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do
    let stream = clock ~> (arr id &&& arr ((+)1) &&& arr ((+)2))
    analogOutput pin5 =: stream ~> funcToStreamMap "test" CWord "test" 3
