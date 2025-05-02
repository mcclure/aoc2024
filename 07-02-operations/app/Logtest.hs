-- See if I understand recursion match...
import GHC.Num.Integer

digits :: Integer -> Integer
digits i =
    let l = integerLogBase 10 i in
    1 + fromIntegral l

-- Read one value from command line, feed it to takeLines, print result
main :: IO ()
main = do
    print (digits 0)
    print (digits 1)
    print (digits 10)
    print (digits 12)
    print (digits 100)
    print (digits 103)
    print (digits 1000)
    print (digits 1004)
    print (digits 10000)
    print (digits 99999)
    print ""
    let (accumulator, i) = (10, 19) in
        print ( (10^digits i) * accumulator + i )
