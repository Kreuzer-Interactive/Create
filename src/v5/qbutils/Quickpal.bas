'By Jon Kreuzer
'This program changes the palette much, much quicker than the palette
'statement. You can use it for some cool effects, such as fades and
'ambient lighting.
DIM p1(256, 3) AS INTEGER 'p1 is used to store the palette in
'DIM i AS INTEGER, p1 AS INTEGER, p2 AS INTEGER, p3 AS INTEGER, fade AS INTEGER
'The above line is only needed if you don't use the DEFINT A-Q,S-Z
DEFINT A-Q, S-Z
CONST reg = &H3C8
CONST dat = &H3C9
'==

SCREEN 13
FOR i = 1 TO 500 'Fill the screen with needless junk to fade
LINE (RND * 320, RND * 200)-(RND * 320, RND * 200), RND * 255
NEXT i

palnum = 1
palred = 20
palgreen = 40
palblue = 60
GOSUB pal 'Change one color.

GOSUB getpalette:
FOR fade = 0 TO 60 STEP 2
GOSUB putpalette:
rtim = TIMER: DO: LOOP UNTIL TIMER - rtim > 0 '==Wait a timer click
NEXT fade
END

'=I use line labels here. You might want to make them into subs.
pal:
OUT pal, &HFF
OUT reg, palnum 'palnum is the number of the color to be updated
OUT dat, palred  'Red (0-63)
OUT dat, palgreen  'Green (0-63)
OUT dat, palblue  'Blue (0-63)
RETURN

getpalette:
OUT reg, 0 '===This is the number of the color we want to get first
OUT pal, &HFF
FOR i = 0 TO 255
p1(i, 1) = INP(dat) 'Red value
p1(i, 2) = INP(dat) 'Green
p1(i, 3) = INP(dat)
NEXT i
RETURN

putpalette: '==Note- Darkening this way causes slight color distortion. To
             '==darken without distortion, you need to reduce the percentage
             '==of each componnent.
OUT reg, 0 '===This is the number of the color we want to update
OUT pal, &HFF
FOR i = 0 TO 255 STEP 1    '=First we subtract fade.
p1 = p1(i, 1) - fade '=(below) makes sure the RGB values don't go below zero.
p2 = p1(i, 2) - fade '=If you're not using this with fade, you can remove
p3 = p1(i, 3) - fade '=it.
IF p1 < 0 THEN p1 = 0
IF p2 < 0 THEN p2 = 0
IF p3 < 0 THEN p3 = 0
OUT dat, p1 '==To do a fade, we update the whole palette
OUT dat, p2 '==The Palette statement is much to slow for
OUT dat, p3 '==this, so we talk to the VGA.
NEXT i
RETURN

