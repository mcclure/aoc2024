( Takes solutions as STDIN )

VARIABLE partial ( Is the current number incomplete? )
VARIABLE safe    ( How many safe lines seen? )

FALSE partial !
0 safe !

: line-done
.S
;

: run

BEGIN ( Line ) 
	KEY
	DUP 0> IF ( SKIP IF EOF )
		DUP DUP DUP 9 <> 13 <> 20 <> AND AND IF partial TRUE ! ELSE ( Reset character parser on TAB, CR, space )
		DUP 12 = IF line-done ELSE ( NEWLINE )
		DUP DUP CHAR 0 < CHAR 9 > OR IF ( Not a number )
			EMIT ." : Unknown character" ABORT
		ELSE
			CHAR 0 - ( Shift out of ASCII )
			partial @ IF ( This is an incomplete character )
				SWAP 10 * ( Digit shift value one down )
				+ ( Combine digits )
			ELSE
				TRUE partial ! 
			THEN
		THEN THEN THEN
	THEN
0< UNTIL

line-done

;

run