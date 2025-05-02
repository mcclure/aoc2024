import Control.Monad.Amb

sumTen :: Int -> Amb Bool Bool
sumTen plus = do
    times <- aMemberOf [-1 :: Int, 1 :: Int]
    return (6 + plus * times == 10)

main :: IO ()
main = do
    print (isPossible (sumTen 3))
    print (isPossible (sumTen 4))
    print (isPossible (sumTen 5))
