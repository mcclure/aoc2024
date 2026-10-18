import System
import System.File.ReadWrite
import Data.String
import Data.List1
import Data.Either
import Data.Vect
import Data.Bits
import Data.Fin

record Cpu where
    constructor NewCpu
    ip : Bits64
    reg : Vect 3 Bits64
    prog: List Bits64

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

	interpret_register : String -> Either String Bits64
	interpret_register line = -- Helper: Turn a line of format "Register X: \d\d\d" into a number
		let words = split (== ' ') line in -- Split on spaces, throw away first two cells
			case words of
				(_ ::: [_, i_string]) => case parsePositive i_string of
					Just i => Right i
					_ => Left "Register value is not number"
				_ => Left "Register line malformed"

	interpret_program_value : String -> Either String Bits64
	interpret_program_value string =  -- Helper: Turn a string number into a number, or die
		case parsePositive string of
			Just i => Right i
			_ => Left "Program tape value is not number"

	interpret_program : String -> Either String (List Bits64)
	interpret_program line =  -- Helper: Turn a line of format "Program: \d,\d,\d..." into a list of numbers
		let words = split (== ' ') line in -- Split on spaces, throw away first cell
			case words of
				_ ::: [tape] => traverse interpret_program_value (forget <| split (== ',') tape)
				_ => Left "Register line malformed"

	-- This function is wrong and I know this function is wrong
	interpret : String -> Either String (Bits64, Bits64, Bits64, List Bits64)
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

	-- Simulate CPU

	combo : Vect 3 Bits64 -> Bits64 -> IO Bits64
	combo reg operand =
		case operand of
			0 => pure operand
			1 => pure operand
			2 => pure operand
			3 => pure operand
			4 => pure <| index 0 reg
			5 => pure <| index 1 reg
			6 => pure <| index 2 reg
			7 => die "Used forbidden combo operand 7"
			_ => die "Combo operand above 7 somehow: \{show operand}"

	exec : Cpu -> Bits64 -> Bits64 -> IO ()
	step : Cpu -> IO ()

	divide : Vect 3 Bits64 -> Bits64 -> IO Bits64
	divide reg operand =
		let a::_ = reg in do
			cop <- combo reg operand
			let cop_idx = cast {to = Nat} cop
			case natToFin cop_idx 64 of
				Just cop_idx2 =>
					let divisor = shiftL (the Bits64 1) cop_idx2 in
					pure <| div a divisor
				_ =>
					die "bad exponent \{show cop_idx}"
	exec (NewCpu ip reg prog) opcode operand  =
		case opcode of
			0 =>    -- ADV
				let [_, b, c] = reg in do
					a <- divide reg operand
					step <| NewCpu (ip+2) [a, b, c] prog
			1 =>    -- BXL
				let [a, b, c] = reg in
				let b = xor b operand in
					step <| NewCpu (ip+2) [a, b, c] prog
			2 =>    -- BST
				let [a, _, c] = reg in do
					cop <- combo reg operand
					step <| NewCpu (ip+2) [a, cop, c] prog
			3 =>    -- JNZ
				-- I really wanted to nest the a destructure inside the let assignment but the linebreak rules said no :(
				let a::_ = reg in
				let ip =
					if a==0 then ip+2 else operand
				in
					step <| NewCpu ip reg prog
			4 =>    -- BXC
				let [a, b, c] = reg in
				let b = xor b c in
					step <| NewCpu (ip+2) [a, b, c] prog
			5 => do -- OUT
				cop <- combo reg operand
				putStrLn <| show (mod cop 8)
				step <| NewCpu (ip+2) reg prog
			6 =>    -- BDV
				let [a, _, c] = reg in do
					b <- divide reg operand
					step <| NewCpu (ip+2) [a, b, c] prog
			7 =>    -- CDV
				let [a, b, _] = reg in do
					c <- divide reg operand
					step <| NewCpu (ip+2) [a, b, c] prog
			_ =>
				die "Unexpected opcode \{show opcode}"

	step cpu = -- ip is a Bits64.
		let (NewCpu ip _ prog) = cpu in
		let ip_idx = cast ip in -- Notice I don't so much as hint what i casted *to*
		case inBounds ip_idx prog of
			Yes _ =>
				case inBounds (ip_idx+1) prog of
					Yes _ =>
						let opcode  = index ip_idx prog in
						let operand = index (ip_idx+1) prog in
							exec cpu opcode operand
					No _ =>
						die "Invalid file: Bad operand parity"
			No _ =>
				pure () -- Natural end of file

	run : (Bits64, Bits64, Bits64, List Bits64) -> IO ()
	run (a,b,c,program) =
		step <| NewCpu 0 [a,b,c] program
