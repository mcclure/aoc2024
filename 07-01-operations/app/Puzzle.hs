module Main where

main :: IO ()
main = do
    l <- do
        l <- getLine
        return l
    putStr l
    putStr "\n"
