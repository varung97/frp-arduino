import Arduino.Uno

main = compileProgram $ do
    let str = clock ~> toggle >>> (invert &&& arr id &&& invert)
    output2 (digitalOutput pin3) (output2 (digitalOutput pin4) (digitalOutput pin5)) =: str
