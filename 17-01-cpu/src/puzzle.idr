import System
import System.File.ReadWrite
import Data.String
import Data.List1

main : IO ()
main = do
	spec <- load
	run (interpret spec)
where
	load : IO String
	load = do -- Take 1 command line argument, treat as path, return contents of file
		args <- getArgs
		arg <- case args of
			[_,x] => pure x
			_ => die "Wrong number of arguments"

		spec <- readFile arg
		case spec of
			Left x => die(show x) -- FileError
			Right x => pure x     -- String

	interpret_register : String -> Int
	interpret_register line = -- Helper: Turn a line of format "Register X: \d\d\d" into a number
		let words = split (== ' ') line in -- Split on spaces, throw away first two cells
			case words of
				(_ ::: [_, i_string]) => case parseInteger i_string of
					Just i => i
					_ => die "Register value is not number"
				_ => die "Register line malformed"

	interpret_program_value : String -> Int
	interpret_program_value string =  -- Helper: Turn a string number into a number, or die
		case parseInteger string of
			Just i => i
			_ => die "Program tape value is not number"

	interpret_program : String -> List Int
	interpret_program line =  -- Helper: Turn a line of format "Program: \d,\d,\d..." into a list of numbers
		let words = split (== ' ') line in -- Split on spaces, throw away first cell
			case line of
				[_, tape] => case map interpret_program_value (split (== ',' tape)) of
					Just i => i
					_ => die "Register value is not number"
				_ => die "Register line malformed"

	interpret : String -> (Int, Int, Int, List Int)
	interpret spec = -- Interpret the puzzle input format
		let specl = lines spec in
		case lines of
			[a, b, c, _, program]::_ =>
				(interpret_register a, interpret_register b, interpret_register c, interpret_program program)
			_ => die "File has too few lines"

