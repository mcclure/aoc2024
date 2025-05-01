main = do
    l <- do
        l <- getLine
        return l
    putStr l
    putStr "\n"
