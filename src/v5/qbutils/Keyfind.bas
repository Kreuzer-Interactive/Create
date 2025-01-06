'By Jon Kreuzer   
'You can use this program to find the codes for the keys.
'(Such as the arrow keys, the F-keys, alt+any letter, ctr+any letter)
'If it's a NULL+, simply use the second character of key$ to test for
'that key. If its not, use the first character.
'EXAMPLE <alt>+<f>. IF MID$(key$,2,1)=CHR$(33) THEN GOTO pressf:
1 key$ = INKEY$: IF key$ = "" THEN 1
IF MID$(key$, 2) <> "" THEN PRINT "Null+ ";
PRINT key$;
IF MID$(key$, 2) <> "" THEN PRINT " CHR$("; ASC(MID$(key$, 2)); ")" ELSE PRINT " CHR$("; ASC(key$); ")"
GOTO 1

