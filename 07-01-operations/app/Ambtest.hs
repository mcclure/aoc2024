import Control.Monad.Amb

sumTen :: Amb Bool Bool
sumTen = do
    times <- aMemberOf [-1 :: Int, 1 :: Int]
    return (6 + 4 * times == 10)

main :: IO ()
main = do
    putStr (show (isPossible sumTen))
