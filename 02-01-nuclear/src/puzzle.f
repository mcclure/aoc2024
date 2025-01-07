( Takes solutions as STDIN )

VARIABLE partial ( Is the current number incomplete? )
VARIABLE safe    ( How many safe lines seen? )

FALSE partial !
0 safe !

: line-done
.S
( TODO: RUN ACTUAL PROGRAM HERE )
DEPTH 0> IF BEGIN DROP DEPTH 0 = UNTIL THEN ( CLEAR STACK )
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
			EMIT ." : Unknown character" CR ABORT
		ELSE
( CHAR 'B' EMIT )
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