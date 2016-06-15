import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do

    analogOutput pin5 =: clock ~> arr ((*) 10)
