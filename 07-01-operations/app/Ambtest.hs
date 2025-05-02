import Control.Monad.Amb

sumTen :: Amb Bool Bool
sumTen = do
    times <- aMemberOf [-1, 1]
    return (6 + 4 * times == 10)

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    putStr (show (isPossible sumTen))
