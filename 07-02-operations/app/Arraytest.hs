-- See if I understand recursion match...

asum :: [Int] -> Int
asum [] = 0 :: Int
asum (i:rest) = i + (asum rest)

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    print (asum [9,8,7])
