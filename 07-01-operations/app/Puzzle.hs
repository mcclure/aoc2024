import System.Environment
import System.IO
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

type LineParser = Parsec Void String

spaceThenNumber :: LineParser Int
spaceThenNumber = do
    _ <- hspace1 -- Commenting this line out breaks it
    L.decimal

parseLine :: LineParser (Int, [Int])
parseLine = do
    lsum <- L.decimal
    _ <- char ':'
    nums <- many spaceThenNumber
    _ <- eof
    return (lsum, nums)

-- Read a line, parse it to get a number, add it to total so far
takeLine :: Handle -> Int -> IO Int
takeLine inHandle acc =
    do  inEof <- hIsEOF inHandle
        if inEof
            then return acc
            else do inStr <- hGetLine inHandle
                    (lsum, operands) <- case parse parseLine "DUMMY-FILE" inStr of
                        Right x -> return x
                        Left e -> error ("\n\nInvalid input\n\n" ++ show e)
                    -- TODO: DO THINGS WITH "OPERANDS" ARRAY HERE
                    takeLine inHandle (acc + lsum)

-- Initial case for takeLine
takeLines :: Handle -> IO Int
takeLines inHandle = do takeLine inHandle 0

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    [inFile] <- getArgs
    file <- openFile inFile ReadMode
    total <- takeLines file            -- TODO do in loop
    putStr (show total)
    putStr "\n"
