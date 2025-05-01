import System.Environment
import System.IO

-- Read a line, parse it to get a number, add it to total so far
takeLine :: Handle -> Int -> IO (Int)
takeLine inHandle acc =
    do inEof <- hIsEOF inHandle
       if inEof
           then return (acc)
           else do inStr <- hGetLine inHandle
                   let result = 1
                   takeLine inHandle (acc + result)

-- Initial case for takeLine
takeLines :: Handle -> IO (Int)
takeLines inHandle = do takeLine inHandle 0

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    [inFile] <- getArgs              -- TODO exceptional cases
    file <- openFile inFile ReadMode
    total <- takeLines file            -- TODO do in loop
    putStr (show total)
    putStr "\n"
