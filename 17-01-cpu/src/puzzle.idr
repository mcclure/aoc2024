import System
import System.File.ReadWrite
import Data.String

main : IO ()
main = do
	args <- getArgs
	arg <- case args of
		[_,x] => pure x
		_ => die "Wrong number of arguments"

	spec <- readFile arg
	spec <- case spec of
		Left x => die(show x) -- FileError
		Right x => pure x     -- String

--	spec <- lines spec -- Uncommenting breaks program

	putStrLn spec
