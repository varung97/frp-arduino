import Arduino.Uno
import Prelude hiding (Word)

main = compileProgram $ do

    let stream = clock ~> mapSMany dup ~> toggleEvery
    -- output2 (digitalOutput pin3) (digitalOutput pin5) =: streams
    digitalOutput pin3 =: stream
    -- uart =: stream ~> mapSMany formatDelta ~> flattenS

dup a = [a, a, a]

toggleEvery :: Stream Word -> Stream Bit
toggleEvery = foldpS (\_ -> flipBit) bitLow

-- formatDelta :: Expression (Word, Word) -> [Expression [Byte]]
-- formatDelta delta = [ formatString "delta: "
--                     , formatNumber a
--                     , formatString " "
--                     , formatNumber b
--                     , formatString "\r\n"
--                     ]
--                     where (a, b) = unpack2 delta


formatDelta delta = [ formatString "delta: "
                    , formatNumber delta
                    , formatString "\r\n"
                    ]
