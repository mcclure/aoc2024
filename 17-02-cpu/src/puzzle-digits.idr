-- Like cpu emulator, but scans for an assignment of register A
--     that causes the program to become a quine.
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

	-- Given a list vec, remove its first value and swap in value
	swap0 : Bits64 -> Vect 3 Bits64 -> Vect 3 Bits64
	swap0 value vec =
		let _::vec = vec in
		value::vec

	search_step : List Bits64 -> List Bits64 -> Nat -> Bits64 -> Config -> Cpu -> IO (List Bits64)
	search_step results candidates match idx config cpu =
		case candidates of
			try::rest => do
				let cpu = { steps := config.limit } cpu
				let cpu = { reg $= swap0 try } cpu
				result <- step [] cpu

				continue <- case result of
					Success(output) => do
						let eq = output /= cpu.prog
						putStrLn "\{show idx}\t\{show output} eq? \{show (not eq)}"
						pure eq
					Failure(msg) => do
						putStrLn "Failure \{show try} \{msg}"
						pure True
					Timeout(_) => do
						putStrLn "Timeout \{show try}"
						pure True

				-- results <- if continue then pure results else pure (try::results)

				if continue then search_step results rest match (idx+1) config cpu else pure <| reverse results

			_ => pure <| reverse results -- EOL



	search_digits : List Bits64 -> Fin 64 -> Config -> Cpu -> IO ()
	search_digits candidates digit_shift config cpu =
		case digit_shift of
			0 => putStrLn (show candidates)
			_ => do
				let digit_idx = digit_shift-3 -- Step down one octet at a time
				let range = [0..7]
				let digits = map (\digit => let digit = the Bits64 (cast digit) in shiftL digit (cast digit_idx)) range

				-- AT THIS POINT IN THE FILE, "candidates" IS A LIST OF BITS64s AND SO IS "digits"
				let next_candidates : List (Bits64, Bits64) = do
					a <- candidates
					b <- digits
					pure (a,b)
				let () = next_candidates
--				let digits = ?b -- map (\digit => shiftL digit digit_idx) range 
				?a

		-- let over = allFins 8
--		let new = map over (\i => shiftL (the Bits64 i) digit)
		--let new = for (the (List (Fin 8)) (allFins 8)) (\i => shiftL (the Bits64 1) 3)
		-- candidates <- case candidates of
		-- 	[] => pure [] -- new
		-- 	_ => pure [] -- concatMap candidates (\c => map new (\n => | n c))
		-- results <- search_step [] candidates len (digit+1) config cpu
		-- case results of
		-- 	[] => putStrLn "abcd"
		-- 	x => putStrLn "abcd"

	search : Bool -> Bits64 -> (Bits64, Bits64, Bits64, List Bits64) -> IO ()
	search verbose limit (a,b,c,program) = do
		let octets = length program
		bits <- case natToFin (cast (3*octets)) 64 of
			Just len => pure len
			_ =>
				die "Program expansion is greater than 64 bits: \{show (limit*4)}"

		search_digits [0] bits (NewConfig verbose limit) (NewCpu 0 [a,b,c] program 0)
