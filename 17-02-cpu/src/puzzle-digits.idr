-- Like cpu emulator, but does a digit-by-digit search for a program that becomes a quine.
-- Usage: puzzle [-v] maxsteps filename

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
    prog : List Bits64
    steps : Bits64

record Config where
	constructor NewConfig
	verbose : Bool
	limit : Bits64

data Result =
	Success(List Bits64)
	| Failure(String)
	| Timeout(Cpu)

main : IO ()
main = do
	(limit, spec, verbose) <- load
	t <- case (interpret spec) of
		Right t => pure t
		Left s => die s

	if verbose then let (_,_,_,program) = t in putStrLn "Program \{show program}" else pure () -- Verbose
	let limit = cast limit
	search verbose limit t

where

	allLines : List Bits64 -> IO (List Bits64)
	allLines accumulator = do
		line <- getLine
		case parsePositive line of
			Just i => let i2 = cast i in allLines (i2::accumulator)
			_ => pure accumulator

	-- Parse input file
	load : IO (Nat, String, Bool)
	load = do -- Take 1 command line argument, treat as path, return contents of file
		args <- getArgs
		(limit,arg,verbose):(String,String,Bool) <- case args of
			[_,x,y] => pure (x, y, False)
			[_, "-v", x, y] => pure (x, y, True)
			_ => die "Wrong number of arguments"

		limit <- case parsePositive limit of
			Just i => pure i
			_ => die "First arg must be a number"

		spec <- readFile arg
		case spec of
			Right x => pure (limit, x, verbose)     -- String
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

	exec : List Bits64 -> Cpu -> Bits64 -> Bits64 -> IO Result
	step : List Bits64 -> Cpu -> IO Result

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

	exec output (NewCpu ip reg prog steps) opcode operand  =
		let ns = steps-1 in
		let so = step output in -- curry
		case opcode of
			0 =>    -- ADV
				let [_, b, c] = reg in do
					a <- divide reg operand
					so <| NewCpu (ip+2) [a, b, c] prog ns
			1 =>    -- BXL
				let [a, b, c] = reg in
				let b = xor b operand in
					so <| NewCpu (ip+2) [a, b, c] prog ns
			2 =>    -- BST
				let [a, _, c] = reg in do
					cop <- combo reg operand
					let cop = mod cop 8
					so <| NewCpu (ip+2) [a, cop, c] prog ns
			3 =>    -- JNZ
				-- I really wanted to nest the a destructure inside the let assignment but the linebreak rules said no :(
				let a::_ = reg in
				let ip =
					if a==0 then ip+2 else operand
				in
					so <| NewCpu ip reg prog ns
			4 =>    -- BXC
				let [a, b, c] = reg in
				let b = xor b c in
					so <| NewCpu (ip+2) [a, b, c] prog ns
			5 => do -- OUT
				cop <- combo reg operand

				step ((mod cop 8)::output) (NewCpu (ip+2) reg prog ns)
			6 =>    -- BDV
				let [a, _, c] = reg in do
					b <- divide reg operand
					so <| NewCpu (ip+2) [a, b, c] prog ns
			7 =>    -- CDV
				let [a, b, _] = reg in do
					c <- divide reg operand
					so <| NewCpu (ip+2) [a, b, c] prog ns
			_ =>
				die "Unexpected opcode \{show opcode}"

	step output cpu = -- ip is a Bits64.
		let (NewCpu ip reg prog steps) = cpu in
		let ip_idx = cast ip in -- Notice I don't so much as hint what i casted *to*
		do
			if steps == 0 then die "TOO MANY STEPS" else pure ()
			case inBounds ip_idx prog of
				Yes _ =>
					case inBounds (ip_idx+1) prog of
						Yes _ =>
							let opcode  = index ip_idx prog in
							let operand = index (ip_idx+1) prog in
								exec output cpu opcode operand
						No _ =>
							die "Invalid file: Bad operand parity"
				No _ => do
					pure <| Success <| output -- Natural end of file -- NOTICE OUTPUT REVERSED

	-- SOME UTILITIES REAL QUICK

	-- Given a list vec, remove its first value and swap in value
	swap0 : Bits64 -> Vect 3 Bits64 -> Vect 3 Bits64
	swap0 value vec =
		let _::vec = vec in
		value::vec

	-- True if two Lists are equal up to first n elements
	-- Note: No inputs I used had a leftmost "0" in the program text.
	-- There is a bug somewhere which I believe prevents an output with a leftmost 0 from being generated.
	-- Fixing that may require changing the asserts here to returning True, False, False.
	listPrefixEq : Eq a => Nat -> List a -> List a -> Bool
	listPrefixEq n a b = do
		if n == 0 then True else case (a, b) of
			([], []) => True -- die "Matching prefix, both lists exhausted with \{show n} left"
			(_, []) => False -- die "Matching prefix, right list exhausted with \{show n} left"
			([], _) => False -- die "Matching prefix, left list exhausted with \{show n} left"
			(a1::ar, b1::br) =>
				if a1 == b1 then
				listPrefixEq (minus n 1) ar br
				else False

	-- Combine two octal digits into one byte
	octal_fold: Bits64 -> Bits64 -> Bits64
	octal_fold a b = (.|.) (shiftL a 3) b


	-- Notice: "results" List List Bits64 is an array of arrays of octal digits; return List Bits64 is an array of those same arrays but mashed into octal.
	search_step : List (List Bits64) -> List Bits64 -> Nat -> Config -> Cpu -> IO (List Bits64)
	search_step results candidates match config cpu =
		case candidates of
			try::rest => do
				let cpu = { steps := config.limit } cpu
				let cpu = { reg $= swap0 try } cpu
				result <- step [] cpu

				append: Maybe (List Bits64) <- case result of
					Success(output) => do
						putStrLn "TESTED A: \{show try} PROG: \{show cpu.prog} OUTPUT: \{show output} MATCHES?: \{show match}"
						let eq = listPrefixEq match output cpu.prog
						putStrLn "\{show match}\t\{show output} append? \{show (eq)}"
						pure <| if eq then Just output else Nothing
					Failure(msg) => do
						putStrLn "Failure \{show try} \{msg} skip"
						pure Nothing
					Timeout(_) => do
						putStrLn "Timeout \{show try} skipping"
						pure Nothing

				results <- case append of
					Just output => pure (output::results)
					Nothing => pure results

				search_step results rest match config cpu

			_ => do
				putStrLn "-------- Pass done, result count: \{show (length results)}\n"
				pure <| reverse <| map (foldl octal_fold 0) results

	search_digits : List Bits64 -> Fin 64 -> Nat -> Config -> Cpu -> IO ()
	search_digits candidates digit_shift digits_match config cpu =
		case candidates of -- Check for esearch failure
			[] => die "Completed checking digit \{show digits_match} (counting from most significant), and got an empty list of next candidates"
			_ => case digit_shift of
				0 => putStrLn (show candidates) -- Check for search success
				_ => do
					let digit_shift = digit_shift-3 -- Step down one octal digit at a time
					let digits_match = digits_match+1 -- Step up one match at a time
					let range = [0..7]

					-- For digit_shift N make a list (0..7) and shift it left N bits
					let digits = map (\digit => let digit = the Bits64 (cast digit) in shiftL digit (cast digit_shift)) range

					-- Magic Idris incantation courtesy of typeswitch from Mastodon
					-- I also have an implementation where I do this with a do in list context and a map, but this is funnier
					putStrLn "  \{show digits}"
					putStrLn "| \{show candidates} ..."
					let step_candidates = (.|.) <$> candidates <*> digits
					putStrLn "= \{show step_candidates}\n"

					-- Filter the candidates, see which ones survive
					step_results <- search_step [] step_candidates digits_match config cpu

					-- Recurse
					search_digits step_results digit_shift digits_match config cpu

	-- Entry point for search algorithm
	search : Bool -> Bits64 -> (Bits64, Bits64, Bits64, List Bits64) -> IO ()
	search verbose limit (a,b,c,program) = do
		let digits = length program
		bits <- case natToFin (cast (3*digits)) 64 of -- Digits are octal
			Just len => pure len
			_ =>
				die "Program expansion is greater than 64 bits: \{show (limit*4)}"

		search_digits [0] bits 0 (NewConfig verbose limit) (NewCpu 0 [a,b,c] program 0)
