import System.Environment
import System.IO

takeLineImpl :: Handle -> Int -> IO (Int)
takeLineImpl inHandle acc = 
    do inEof <- hIsEOF inHandle
       if inEof
           then return (acc)
           else do inStr <- hGetLine inHandle
                   let result = 1
                   takeLineImpl inHandle (acc + result)

takeLine :: Handle -> IO (Int)
takeLine inHandle = do takeLineImpl inHandle 0

main :: IO ()
main = do
    [inFile] <- getArgs              -- TODO exceptional cases
    file <- openFile inFile ReadMode
    total <- takeLine file            -- TODO do in loop
    putStr (show total)
    putStr "\n"
