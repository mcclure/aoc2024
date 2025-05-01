import System.Environment
import System.IO

main :: IO ()
main = do
    [inFile] <- getArgs              -- TODO exceptional cases
    file <- openFile inFile ReadMode
    line <- hGetLine file            -- TODO do in loop
    putStr line
    putStr "\n"
