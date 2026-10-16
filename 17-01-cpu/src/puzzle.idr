import System
import System.File.ReadWrite
import Data.String
import Data.List1
import Data.Either

main : IO ()
main = do
	spec <- load
	t <- case (interpret spec) of
		Right t => pure t
		Left s => die s
	run t

where
	load : IO String
	load = do -- Take 1 command line argument, treat as path, return contents of file
		args <- getArgs
		arg <- case args of
			[_,x] => pure x
			_ => die "Wrong number of arguments"

		spec <- readFile arg
		case spec of
			Right x => pure x     -- String
			Left x => die(show x) -- FileError

	interpret_register : String -> Either String Int
	interpret_register line = -- Helper: Turn a line of format "Register X: \d\d\d" into a number
		let words = split (== ' ') line in -- Split on spaces, throw away first two cells
			case words of
				(_ ::: [_, i_string]) => case parseInteger i_string of
					Just i => Right i
					_ => Left "Register value is not number"
				_ => Left "Register line malformed"

	interpret_program_value : String -> Either String Int
	interpret_program_value string =  -- Helper: Turn a string number into a number, or die
		case parseInteger string of
			Just i => Right i
			_ => Left "Program tape value is not number"

	interpret_program : String -> Either String (List Int)
	interpret_program line =  -- Helper: Turn a line of format "Program: \d,\d,\d..." into a list of numbers
		let words = split (== ' ') line in -- Split on spaces, throw away first cell
			case words of
				_ ::: [tape] => traverse interpret_program_value (forget (split (== ',') tape))
				_ => Left "Register line malformed"

	-- This function is wrong and I know this function is wrong
	interpret : String -> Either String (Int, Int, Int, List Int)
	interpret spec = -- Interpret the puzzle input format
		let specl = lines spec in
		case specl of
			a::b::c::_::program::_ => do
				a <- interpret_register a
				b <- interpret_register b
				c <- interpret_register c
				d <- interpret_program program
				Right (a,b,c,d)
			_ => Left "File has too few lines"

	run : (Int, Int, Int, List Int) -> IO ()
	run (a,b,c,program) =
		putStrLn "Success"
