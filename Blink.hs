import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do
    -- analogOutput pin11 =: clock ~> modStream 180
    -- digitalOutput pin3 =: digitalRead pin10 ~> invert
    -- digitalOutput pin4 =: digitalRead pin11 ~> invert
    -- digitalOutput pin5 =: digitalRead pin12 ~> invert
    output3 (digitalOutput pin3) (digitalOutput pin4) (digitalOutput pin5) =:
      analogRead a0 ~>
      (arr $ (`intDiv` 128)) ~>
      (arr getBit1 &&&
       arr getBit2 &&&
       arr getBit3
       )

output3 :: Output a1 -> Output a2 -> Output a3 -> Output (a1, (a2, a3))
output3 out1 out2 out3 = output2 out1 $ output2 out2 out3

getBit1 :: Expression Word -> Expression Bit
getBit1 = numToBit . (`intDiv` 4)

getBit2 :: Expression Word -> Expression Bit
getBit2 = numToBit . (`intDiv` 2) . (`intMod` 4)

getBit3 :: Expression Word -> Expression Bit
getBit3 = numToBit . (`intMod` 2)

numToBit :: Expression Word -> Expression Bit
numToBit = boolToBit . (`greater` 0)

modStream :: Expression Word -> Expression Word -> Stream Word -> Stream Word
modStream val amount = foldpS (\_ -> increment) 0
  where
    increment state = if_ (greater (state + amount) val) (state + amount - val) (state + amount)
