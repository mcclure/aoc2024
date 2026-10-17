import System
import System.File.ReadWrite
import Data.String
import Data.List1
import Data.Either
import Data.Vect
import Data.Bits

record Cpu where
    constructor NewCpu
    ip : Nat
    reg : Vect 3 Nat
    prog: List Nat

main : IO ()
main = do
	spec <- load
	t <- case (interpret spec) of
		Right t => pure t
		Left s => die s
	run t

where

	-- Parse input file
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

	interpret_register : String -> Either String Nat
	interpret_register line = -- Helper: Turn a line of format "Register X: \d\d\d" into a number
		let words = split (== ' ') line in -- Split on spaces, throw away first two cells
			case words of
				(_ ::: [_, i_string]) => case parsePositive i_string of
					Just i => Right i
					_ => Left "Register value is not number"
				_ => Left "Register line malformed"

	interpret_program_value : String -> Either String Nat
	interpret_program_value string =  -- Helper: Turn a string number into a number, or die
		case parsePositive string of
			Just i => Right i
			_ => Left "Program tape value is not number"

	interpret_program : String -> Either String (List Nat)
	interpret_program line =  -- Helper: Turn a line of format "Program: \d,\d,\d..." into a list of numbers
		let words = split (== ' ') line in -- Split on spaces, throw away first cell
			case words of
				_ ::: [tape] => traverse interpret_program_value (forget <| split (== ',') tape)
				_ => Left "Register line malformed"

	-- This function is wrong and I know this function is wrong
	interpret : String -> Either String (Nat, Nat, Nat, List Nat)
	interpret spec = -- Naterpret the puzzle input format
		let specl = lines spec in
		case specl of
			a::b::c::_::program::_ => do
				a <- interpret_register a
				b <- interpret_register b
				c <- interpret_register c
				d <- interpret_program program
				Right (a,b,c,d)
			_ => Left "File has too few lines"

	-- Simulate CPU

	combo : Vect 3 Nat -> Nat -> IO Nat
	combo reg operand =
		case operand of
			0 => pure operand
			1 => pure operand
			2 => pure operand
			3 => pure operand
			4 => pure <| index 0 reg
			5 => pure <| index 1 reg
			6 => pure <| index 2 reg
			7 => die "Used forbidden combo operand"
			_ => die "Operand above 7 somehow"

	exec : Cpu -> Nat -> Nat -> IO ()
	step : Cpu -> IO ()

	exec (NewCpu ip reg prog) opcode operand  =
		case opcode of
			0 =>    -- ADV
				let [a, b, c] = reg in
					step <| NewCpu (ip+2) [a, b, c] prog
			1 =>    -- BXL
				let [a, b, c] = reg in
				let b = xor b operand in
					step <| NewCpu (ip+2) [a, b, c] prog
			2 =>    -- BST
				pure ()
			3 =>    -- JNZ
				pure ()
			4 =>    -- BXC
				pure ()
			5 => do -- OUT
				cop <- combo reg operand
				putStrLn <| show cop
				step <| NewCpu (ip+2) reg prog
			6 =>    -- BDV
				pure ()
			7 =>    -- CDV
				pure ()
			_ =>
				die "Unexpected opcode"

	step (NewCpu ip reg prog) =
		case inBounds ip prog of
			Yes _ =>
				case inBounds (ip+1) prog of
					Yes _ =>
						let opcode  = index ip prog in
						let operand = index (ip+1) prog in
							putStrLn "Help"
					No _ =>
						die "Invalid file: Bad operand parity"
			No _ =>
				pure ()

	run : (Nat, Nat, Nat, List Nat) -> IO ()
	run (a,b,c,program) =
		step <| NewCpu 0 [a,b,c] program
