( Takes solutions as STDIN )

VARIABLE partial ( Is the current number incomplete? )
VARIABLE safe    ( How many safe lines seen? )

FALSE partial !
0 safe !

: 2ROT
ROT ROT
;

: test ( Perl <=>. Consumes two arguments, places -1, 0 or 1 on the stack depending on equality. )
-
DUP 0> IF DROP -1 ELSE
    0< IF 1 ELSE 0
THEN THEN
;

VARIABLE report-pass/incr ( Is the line increasing or decreasing? )
VARIABLE report-pass/safe ( Is the current line safe? )

: report-pass ( Clear line and leave behind safe value )

0 report-pass/incr !    ( Current increment value unknown )
TRUE report-pass/safe ! ( Assume safe until proven otherwise )

( The conditions for safe are: [[All increasing OR all decreasing] AND [difference between 1 and 3 inclusive]] )
DEPTH 1 > IF BEGIN
	report-pass/safe @ IF ( Distance criteria )
		2DUP - ABS
		DUP 4 < AND ( Hack: AND compares the condition with the *difference*! )
			report-pass/safe !
	THEN

	report-pass/safe @ IF ( Incr/decr criteria ) ( Note if we got here, the distance is not equal to 0 )
		2DUP test
		report-pass/incr @
		DUP 0 = IF
			DROP
			report-pass/incr !
		ELSE
			=
			report-pass/safe !
		THEN
	THEN

	DROP
DEPTH 2 < UNTIL THEN

DROP ( We know for a fact there is exactly one left )

report-pass/safe @
;

( Note: Stack backups store length as first element, rest is stack backward )
( Note: We are assuming "the memory-allocation word set" )
( Note: clone/restore assume a stack of size at least 1 )

: stack-clone ( Pop one element off stack for storage location, copy rest of stack to that location )
	DEPTH SWAP OVER ( So top of stack now contains: storage depth depth )
	CELLS ALLOCATE ( Notice the depth is stacklength + 1 )
	0> IF ." Size " DROP . ." : Allocation failure" CR ABORT THEN
	( Stack top: depth storage pointer )
	DUP 3 PICK 1 - SWAP ! ( Write stacklength [depth - 1] to start of array )
	SWAP 2DUP ! ( Write pointer to storage )
	DROP SWAP DROP ( Stack top: pointer )

	DUP @ 0 ( Stack top: pointer stacklength counter )
	BEGIN
		DUP 3 + ( Stack top: pointer stacklength counter counter+3 )
		( BUG: Notice wedged in "1 +". It would be better if we had depth on the stack and we wouldn't need this. )
		PICK 3 PICK 2 PICK 1 + CELLS + ! ( assign to *pointer )
		1+ ( Increment counter )
	2DUP = UNTIL
	DROP DROP DROP
;

: stack-restore ( Pop one element off stack for storage location, push items at that backup onto stack )
	@ DUP @ ( Stack top: pointer index . index will count down to 0 )
	BEGIN
		2DUP CELLS + @ ( Stack top: pointer index newdata )
		ROT ROT ( Stack top: newdata pointer index )
		1 - ( Increment counter )
	DUP 0= UNTIL
	DROP DROP
;

VARIABLE line-done/stack-backup

: line-done ( Clear line and save results in 'safe' )
.S

DEPTH 0> IF ( Entirely skip blank lines )
	report-pass

	( Record result )
	IF
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
				2 PICK 10 * ( Digit shift value one down )
				+ ( Combine digits )
				ROT DROP ( Delete our previously PICKed value )
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