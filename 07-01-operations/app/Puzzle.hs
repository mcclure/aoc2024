import System.Environment
import System.IO
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L
import Control.Monad.Amb (Amb, aBoolean, isPossible)

------- SEARCH --------

composeMember :: Integer -> [Integer] -> Integer -> Amb Bool Bool
composeMember target [] accumulator = do
    return (target == accumulator)
composeMember target (i:rest) accumulator = do
    isTimes <- aBoolean
    newAccumulator <- if isTimes
        then return (i+accumulator)
        else return (i*accumulator)
    composeMember target rest newAccumulator

composeMembers :: Integer -> [Integer] -> Amb Bool Bool
composeMembers target operands = composeMember target operands 0

-------- PARSING --------

type LineParser = Parsec Void String

spaceThenNumber :: LineParser Integer
spaceThenNumber = do
    _ <- hspace1 -- Commenting this line out breaks it
    L.decimal

parseLine :: LineParser (Integer, [Integer])
parseLine = do
    lsum <- L.decimal
    _ <- char ':'
    nums <- many spaceThenNumber
    _ <- eof
    return (lsum, nums)

-- Read a line, parse it to get a number, add it to total so far
takeLine :: Handle -> Integer -> IO Integer
takeLine inHandle accumulator =
    do  inEof <- hIsEOF inHandle
        if inEof
            then return accumulator
            else do inStr <- hGetLine inHandle
                    (lsum, operands) <- case parse parseLine "DUMMY-FILE" inStr of
                        Right x -> return x
                        Left e -> error ("\n\nInvalid input\n\n" ++ show e)
                    let possible = isPossible (composeMembers lsum operands)
                    takeLine inHandle (if possible then accumulator + lsum else accumulator)

-- Initial case for takeLine
takeLines :: Handle -> IO Integer
takeLines inHandle = do takeLine inHandle 0

-------- INTERFACE --------

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    [inFile] <- getArgs
    file <- openFile inFile ReadMode
    total <- takeLines file            -- TODO do in loop
    putStr (show total)
    putStr "\n"
