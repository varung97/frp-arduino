import Arduino.Uno
import Prelude hiding (Word)

noteStream :: [Expression Word] -> Stream Word
noteStream notes = delay $ flattenS $ flattenS $ (arr createNote) <~ (flattenS $ constStream $ convToList notes)

createNote :: Expression Word -> Expression [[(Word, Word)]]
createNote val = convToList $ replicate 100 $ convToList [pack2 (100, val), pack2 (0, val)]

cNote :: Expression [[(Word, Word)]]
cNote = createNote 956

eNote :: Expression [[(Word, Word)]]
eNote = createNote 759
