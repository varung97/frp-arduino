import Arduino.Uno
import qualified Arduino.Library.LCD as LCD
import Prelude hiding (Word)

main = compileProgram $ do

    -- let inputs = pack2Stream (every 2000 ~> getClockEdge) (every 2000 ~> (liftStreamToMap $ digitalRead pin10) ~> getLeadingEdge)
    -- let inputs = pack2Stream (every timeSecond) (digitalRead pin10)
    -- let inputs = every 10000 ~> (getClockEdge &&& (liftStreamToMap (digitalRead pin10) >>> getLeadingEdge))
    -- setupLCD $ inputs ~> stopwatch ~> arr extractTime ~> arr ((*) 10) ~> arr formatNumber ~> arr prependSpecial ~> flattenS ~> arr statusText ~> flattenS
    -- digitalOutput pin13 =: every 2000 ~> getClockEdge
    -- uart =: inputs ~> stopwatch ~> arr extractTime ~> uartConvert
    -- let inputs = every 2000 ~> (getPrevious 0 &&& (liftStreamToMap (digitalRead pin10) >>> getPrevious bitLow))
    let inputs = every 2000 ~> (arr id &&&
                      (liftStreamToMap (digitalRead pin10) >>> invert) &&&
                      (liftStreamToMap (digitalRead pin11) >>> invert))
    -- digitalOutput pin13 =: digitalRead pin11
    setupLCD $ inputs ~> stopwatch ~>
              arr extractTime ~> arr ((*) 10) ~>
              arr formatNumber ~> arr prependSpecial ~>
              flattenS ~> mapS statusText ~> flattenS
    -- uart =: inputs ~> stopwatch ~> arr extractTime ~> arr formatNumber ~> arr prependSpecial ~> flattenS
    -- uart =: every 2000 ~> liftStreamToMap (digitalRead pin10) ~> arr convRunning ~> arr formatNumber ~> arr prependSpecial ~> flattenS

stopwatch :: Stream (Word, (Bit, Bit)) ->
      Stream (((Word, Word), (Bit, Bit)), (Word, (Bit, Bit)))
stopwatch = foldpS increment $
    pack2 (pack2 (pack2 (0, 0), pack2 (bitHigh, bitLow))
            , pack2 (0, pack2 (bitLow, bitLow)))

increment :: Expression (Word, (Bit, Bit)) ->
  Expression (((Word, Word), (Bit, Bit)), (Word, (Bit, Bit))) ->
  Expression (((Word, Word), (Bit, Bit)), (Word, (Bit, Bit)))
increment inputs state =
  let
    (newClock, inputs') = unpack2 inputs
    (newRunningBut, newLapBut) = unpack2 inputs'
    (state', oldVals) = unpack2 state
    (time', state'') = unpack2 state'
    (time, frozenTime) = unpack2 time'
    (running, lap) = unpack2 state''
    (oldClock, oldVals') = unpack2 oldVals
    (oldRunningBut, oldLapBut) = unpack2 oldVals'

    running' = if_ (isRisingEdge newRunningBut oldRunningBut) (flipBit running) (running)
    lap' = if_ (isRisingEdge newLapBut oldLapBut) (flipBit lap) (lap)

    newTimes =
      if_ ((hasChanged newClock oldClock))
        (if_ ((isHigh running') `boolAnd` (isLow lap')) -- Running, not frozen
          (pack2 (time + 1, time + 1))
          (if_ ((isHigh running') `boolAnd` (isHigh lap')) -- Running and frozen
            (pack2 (time + 1, frozenTime))
            (if_ ((isLow running') `boolAnd` (isLow lap')) -- Not running, not frozen
              (pack2 (time, time))
              (pack2 (0, 0)) -- Not running and frozen : reset
            )
          )
        )
        (pack2 (time, frozenTime))
  in
    -- pack2 (pack2 (time', running'), pack2 (newClock, newButton))
    pack2 (pack2 (newTimes, pack2 (running', lap')), pack2 (newClock, pack2 (newRunningBut, newLapBut)))

extractTime :: Expression (((Word, Word), (Bit, Bit)), b) -> Expression Word
extractTime state =
  let
    (state', _) = unpack2 state
    (times, state'') = unpack2 state'
    (_, lap) = unpack2 state''
  in
    if_ (isHigh lap)
      (snd $ unpack2 times) -- frozen Time
      (fst $ unpack2 times) -- normal Time

extractRunning :: Expression ((a, Bit), b) -> Expression Bit
extractRunning state =
  let (state', _) = unpack2 state
  in snd $ unpack2 state'

convRunning :: Expression Bit -> Expression Word
convRunning bit =
  if_ (isHigh bit)
    (1)
    (0)

uartConvert :: Stream Word -> Stream Byte
uartConvert stream = stream ~> mapSMany formatDelta ~> flattenS

formatDelta :: Expression Word -> [Expression [Byte]]
formatDelta delta = [ formatNumber delta
                    , formatString "\r\n"
                    ]

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
  -- convToExprList $ LCD.byteText val

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

-- getLeadingEdge :: Stream Bit -> Stream Bit
-- getLeadingEdge = (foldpS capture (pack2 (bitLow, bitLow))) >>> arr (fst . unpack2)
--   where
--     capture new state =
--       if_ ((isHigh new) `boolAnd` (isHigh $ flipBit $ snd $ unpack2 state))
--         (pack2 (bitHigh, new))
--         (pack2 (bitLow, new))

-- getClockEdge :: Stream Word -> Stream Bit
-- getClockEdge = (foldpS capture (pack2 (bitLow, 0))) >>> arr (fst . unpack2)
--   where
--     capture new state =
--       let (out, old) = unpack2 state
--       in
--         if_ (greater new old)
--           (pack2 (bitHigh, new))
--           (pack2 (bitLow, new))

getPrevious :: Expression a -> Stream a -> Stream (a, a)
getPrevious initial = foldpS prev $ pack2 (initial, initial)
  where
    prev :: Expression a -> Expression (a, a) -> Expression (a, a)
    prev new state =
      let (old, _) = unpack2 state
      in pack2 (new, old)

hasChanged :: Expression a -> Expression a -> Expression Bool
hasChanged new old = flipBool $ isEqual new old

isRisingEdge :: Expression Bit -> Expression Bit -> Expression Bool
isRisingEdge new old = (isHigh new) `boolAnd` (isLow old)
