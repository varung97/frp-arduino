import Arduino.Uno
import qualified Arduino.Library.LCD as LCD
import Prelude hiding (Word)

main = compileProgram $ do
  let startstop = buttonInput pin10 1
  let lapreset = buttonInput pin11 2
  let clockInput = every 2000 ~> arr (const 3)
  let inputs = mergeS [startstop, lapreset, clockInput]
  let init_state = makeState 0 0 (isHigh bitHigh) (isHigh bitLow)
  let state = foldpS update init_state inputs
  let displayTime = state ~> arr extractTime
  setupLCD $ displayTime ~> arr ((*) 10) ~>
            arr formatNumber ~> arr prependSpecial ~>
            flattenS ~> mapS statusText ~> flattenS

update :: Expression Word -> Expression ((Word, Word), (Bool, Bool)) -> Expression ((Word, Word), (Bool, Bool))
update action state =
  let
    (times, states) = unpack2 state
    (time, frozenTime) = unpack2 times
    (running, frozen) = unpack2 states
  in
    if_ (isEqual action 1)
      (makeState time frozenTime (notBool running) frozen)
      (if_ (isEqual action 2)
        (makeState time frozenTime running (notBool frozen))
        (if_ (isEqual action 3)
          (updateTimes time frozenTime running frozen)
          (makeState time frozenTime running frozen)
        )
      )

updateTimes ::  Expression Word -> Expression Word -> Expression Bool -> Expression Bool -> Expression ((Word, Word), (Bool, Bool))
updateTimes time frozenTime running frozen =
  if_ (running `boolAnd` (notBool frozen))
    (makeState (time + 1) (time + 1) running frozen)
    (if_ (running `boolAnd` frozen)
      (makeState (time + 1) frozenTime running frozen)
      (if_ ((notBool running) `boolAnd` frozen)
        (makeState 0 0 running frozen)
        (makeState time time running frozen)
      )
    )

makeState :: Expression Word -> Expression Word -> Expression Bool -> Expression Bool -> Expression ((Word, Word), (Bool, Bool))
makeState time frozenTime running frozen = pack2 (pack2 (time, frozenTime), pack2 (running, frozen))

getLeadingEdge :: Stream Bit -> Stream Bit
getLeadingEdge = (foldpS capture (pack2 (bitLow, bitLow))) >>> arr (fst . unpack2)
  where
    capture new state =
      if_ ((isHigh new) `boolAnd` (isHigh $ flipBit $ snd $ unpack2 state))
        (pack2 (bitHigh, new))
        (pack2 (bitLow, new))

buttonInput :: GPIO -> Expression Word -> Stream Word
buttonInput pin val = digitalRead pin ~> invert >>> getLeadingEdge >>> filterS isHigh >>> arr (const val)

extractTime :: Expression ((Word, Word), (Bool, Bool)) -> Expression Word
extractTime state =
  let
    (times, states) = unpack2 state
    (_, frozen) = unpack2 states
  in
    if_ (frozen)
      (snd $ unpack2 times) -- frozen Time
      (fst $ unpack2 times) -- normal Time

prependSpecial :: Expression [Byte] -> Expression [Byte]
prependSpecial = concatLists (convToExprList [32])

statusText :: Expression Byte -> Expression [LCD.Command]
statusText val =
  if_ (isEqual val 32)
    (convToExprList $
      concat
        [ LCD.position 0 0
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
