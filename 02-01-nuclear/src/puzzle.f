( Takes solutions as STDIN )

VARIABLE partial ( Is the current number incomplete? )
VARIABLE safe    ( How many safe lines seen? )

FALSE partial !
0 safe !

: test ( Perl <=>. Consumes two arguments, places -1, 0 or 1 on the stack depending on equality. )
-
DUP 0> IF DROP -1 ELSE
    0< IF 1 ELSE 0
THEN THEN
;

VARIABLE line-done/incr ( Is the line increasing or decreasing? )
VARIABLE line-done/safe ( Previous number in line )

: line-done ( Clear line and save results in 'safe' )
.S

DEPTH 0> IF ( Entirely skip blank lines )

	0 line-done/incr !
	TRUE line-done/safe !

	( The conditions for safe are: [[All increasing OR all decreasing] AND [difference between 1 and 3 inclusive]] )
	DEPTH 1 > IF BEGIN
		line-done/safe @ IF ( Distance criteria )
			2DUP - ABS
			DUP 4 < AND ( Hack: AND compares the condition with the *difference*! )
				line-done/safe ! 
		THEN

		line-done/safe @ IF ( Incr/decr criteria ) ( Note if we got here, the distance is not equal to 0 )
			2DUP test
			line-done/incr @
			DUP 0 = IF
				DROP
				line-done/incr !
			ELSE
				=
				line-done/safe !
			THEN
		THEN

		DROP
	DEPTH 2 < UNTIL THEN

	DROP ( We know for a fact there is exactly one left )

	( Record result )
	line-done/safe @ IF
		." SAFE" CR
		safe @ 1 + safe !
	THEN

THEN

FALSE partial !
;

: run

BEGIN ( Line )
	( .S )
	KEY
	DUP 0> IF ( SKIP IF NULL/EOF )
		DUP DUP DUP 9 = SWAP 13 = OR SWAP 32 = OR IF FALSE partial ! ELSE ( Reset character parser on TAB, CR, space )
		DUP 10 = IF DROP line-done 10 ELSE ( NEWLINE -- notice ugly stack jiggling )
		DUP DUP [CHAR] 0 < SWAP [CHAR] 9 > OR IF ( Not a number )
			EMIT ." : Unknown character in puzzle input" CR ABORT
		ELSE
			DUP ( Need this on the stack for UNTIL )
			[CHAR] 0 - ( Shift out of ASCII )
			partial @ IF ( This is an incomplete character )
				OVER 10 * ( Digit shift value one down )
				+ ( Combine digits )
			ELSE
				TRUE partial ! 
			THEN
			SWAP ( Bring UNTIL operator back to top )
		THEN THEN THEN
	THEN
0> NOT UNTIL

line-done

;

run

safe @ . CR