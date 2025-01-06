'By Jon Kreuzer
'Kreuzer industries palette maker.
'Feel free to use or modify as you wish.
'------Read These instructions before running.--------
'put numlock on. 7-increase blue 8-increase red 9-increase green
'                1-decrease blue 2-decrease red 3-decrease green
' Enter-accept color s-save palette
' g-go back a color l-load palette to add colors
'---------------
' demo.pal included is a well-rounded palette.
' remember you have 254 colors to use!
DEFINT A-Q, S-Z
DIM B AS LONG, G AS LONG, R AS LONG, c AS LONG
CLS
SCREEN 13
i = 5
REDIM p(261) AS LONG
55 FOR kk = 5 TO 256
LINE (kk, 50)-(kk, 60), kk
NEXT kk
COLOR 254
PALETTE 254, 61
LINE (1, 1)-(20, 40), 3, BF
LINE (30, 1)-(40, 40), 1, BF
LINE (50, 1)-(60, 40), 2, BF
LINE (70, 1)-(80, 40), 4, BF
2 a$ = INKEY$: IF a$ = "" THEN 2
LOCATE 1, 20: PRINT "colors used"; i
IF a$ = "l" THEN GOTO 17
IF a$ = "8" THEN ri = ri + 2: IF ri > 62 THEN ri = 62
IF a$ = "2" THEN ri = ri - 2: IF ri < 1 THEN ri = 1
IF a$ = "g" THEN i = i - 1
IF a$ = "7" THEN bi = bi + 2: IF bi > 62 THEN bi = 62
IF a$ = "1" THEN bi = bi - 2: IF bi < 1 THEN bi = 1
IF a$ = "9" THEN gi = gi + 2: IF gi > 62 THEN gi = 62
IF a$ = "3" THEN gi = gi - 2: IF gi < 1 THEN gi = 1
IF a$ = CHR$(13) THEN p(i) = c: i = i + 1: SOUND 100, 1: PALETTE i - 1, p(i - 1)
IF a$ = "s" THEN 10
IF a$ = "q" THEN END
B = bi * 65536
G = gi * 256
R = ri
PALETTE 1, R
PALETTE 2, G
PALETTE 3, B
c = R + G + B
PALETTE 4, c
GOTO 2
10 COLOR 254: PALETTE 254, 61
INPUT "Save as file name(ex. <palette>) .pal is automatically added?"; d$
CLS
OPEN d$ + ".pal" FOR OUTPUT AS #1
FOR i = 4 TO 256 STEP 4
WRITE #1, p(i), p(i + 1), p(i + 2), p(i + 3)
NEXT i
END
17 COLOR 254: PALETTE 254, 61
INPUT "Load file name(ex. <demo>) .pal is automatically added?"; d$
OPEN d$ + ".pal" FOR INPUT AS #1: ti = 0
FOR i = 0 TO 255 STEP 1: p(i) = 0: NEXT i
FOR i = 4 TO 255 STEP 1
INPUT #1, p(i)
IF p(i) = 0 AND i > 5 AND ti = 0 THEN ti = i
NEXT i: i = ti
PALETTE USING p(0)
CLS
CLOSE
GOTO 55

'=============USE THIS TO LOAD PALLETE IN YOUR GAMES==========
100 SCREEN 13'go to graphics mode
REDIM p(261) AS LONG' define array for pallete
'---- Actual Loadind of Pallete---
OPEN "demo.pal" FOR INPUT AS #1         'LOAD demo.pal
FOR i = 4 TO 255 STEP 1
INPUT #1, p(i)
NEXT i
PALETTE USING p(0)
CLOSE
END

'==This equation will isolate the Red, Green, and Blue components
'==You can use this to change to your loaded palette quicker using
'==the quickpal.
palblue = INT(p(i) / 65536) 'Blue
palgreen = INT((p(i) - rm3 * 65536) MOD 256)'Green
palblue = INT(p(i) - rm3 * 65536 - rm2 * 256)'Red

