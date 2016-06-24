import Arduino.Uno
import qualified Arduino.Library.LCD as LCD
import Data.List
import Prelude hiding (Word)

main = compileProgram $ do

    -- tick <- def clock
    --
    -- digitalOutput pin13 =: tick ~> toggle

    setupLCD [ bootup ~> mapSMany (const introText)
             , every 2000 ~> arr formatNumber ~> arr prependSpecial ~> flattenS ~> mapS statusText ~> flattenS
            --  , clock ~> mapSMany statusText
             ]

introText :: [Expression LCD.Command]
introText = concat
    [ LCD.position 0 0
    , LCD.text "FRP Arduino"
    ]

prependSpecial :: Expression [Byte] -> Expression [Byte]
prependSpecial = concatLists (convToExprList [1])

statusText :: Expression Byte -> Expression [LCD.Command]
statusText val =
  if_ (isEqual val 1)
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

-- statusText :: Expression Word -> [Expression LCD.Command]
-- statusText val = concat
--     [ LCD.position 1 0
--     , LCD.byteText $ formatString "Hi"
--     ]

setupLCD :: [Stream LCD.Command] -> Action ()
setupLCD streams = do
    LCD.output rs d4 d5 d6 d7 enable =: mergeS streams
    where
        rs     = digitalOutput pin3
        d4     = digitalOutput pin5
        d5     = digitalOutput pin6
        d6     = digitalOutput pin7
        d7     = digitalOutput pin8
        enable = digitalOutput pin4
