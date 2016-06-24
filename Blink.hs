import Arduino.Uno
import qualified Arduino.Library.LCD as LCD
import Prelude hiding (Word)

main = compileProgram $ do

    -- let inputs = pack2Stream (every timeSecond) (pack2Stream (every timeSecond ~> liftStreamToMap (digitalRead pin10)) (every timeSecond ~> liftStreamToMap (digitalRead pin11)))
    let inputs = every timeSecond ~> (arr id &&& liftStreamToMap (digitalRead pin10) &&& liftStreamToMap (digitalRead pin11))
    setupLCD $ inputs ~> stopwatch ~> arr extractTime ~> arr formatNumber ~> arr prependSpecial ~> flattenS ~> mapS statusText ~> flattenS
    -- uart =: inputs ~> stopwatch ~> arr extractTime ~> uartConvert

stopwatch :: Stream (Word, (Bit, Bit)) -> Stream (Word, (Bit, Word))
stopwatch = foldpS increment (pack2 (0, pack2 (bitHigh, 1)))

increment :: Expression (Word, (Bit, Bit)) -> Expression (Word, (Bit, Word)) -> Expression (Word, (Bit, Word))
increment action state =
  let
    (clockVal, inputs) = unpack2 action
    (start, stop) = unpack2 inputs
    (val, state') = unpack2 state
    (running, oldClock) = unpack2 state'
    running' = if_ (isHigh stop) (bitLow) (running)
    running'' = if_ (isHigh start) (bitHigh) (running')
    val' = if_ (greater clockVal oldClock)
      (if_ (isHigh running'')
        (val + 1)
        (val)
      )
      (val)
  in
    pack2 (val', pack2 (running'', clockVal))

extractTime :: Expression (Word, a) -> Expression Word
extractTime state =
  let (time, _) = unpack2 state
  in time

uartConvert :: Stream Word -> Stream Byte
uartConvert stream = stream ~> mapSMany formatDelta ~> flattenS

formatDelta :: Expression Word -> [Expression [Byte]]
formatDelta delta = [ formatNumber delta
                    , formatString "\r\n"
                    ]

prependSpecial :: Expression [Byte] -> Expression [Byte]
prependSpecial = concatLists (convToExprList [200])

statusText :: Expression Byte -> Expression [LCD.Command]
statusText val =
  if_ (isEqual val 200)
    (convToExprList $
      concat
        [ LCD.position 1 0
        ]
    )
    (convToExprList $
      concat
        [ LCD.byteText val
        ]
    )

setupLCD :: Stream LCD.Command -> Action ()
setupLCD streams = do
    LCD.output rs d4 d5 d6 d7 enable =: streams
    where
        rs     = digitalOutput pin3
        d4     = digitalOutput pin5
        d5     = digitalOutput pin6
        d6     = digitalOutput pin7
        d7     = digitalOutput pin8
        enable = digitalOutput pin4
