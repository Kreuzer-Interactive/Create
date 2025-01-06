'Qbasic PCX loader. By Jon Kreuzer

'I have used some tricks here to make the loader about 5 times
'faster than a straightforward Qbasic version. Still, unless you use
'Quick Basic to compile it, it will probably run too slow for use in
'a game or a project. At the end of this program is optional code to save it
'for instant access.
DEFINT A-Q, S-Z
CONST mask = &H3C5
CONST reg = &H3C8
CONST dat = &H3C9
DIM buffer AS STRING * 12000
DIM char AS INTEGER, red AS STRING * 1, char2 AS STRING * 1
DIM back, rtim, green AS STRING * 1, blue AS STRING * 1
DIM bytepos AS LONG, buffercount AS LONG, bufferadd AS LONG, ende AS LONG
SCREEN 13

'LOAD PALLETE
OPEN "filename.pcx" FOR BINARY AS #1
ende = LOF(1)
SEEK #1, ende - 767
FOR i = 0 TO 255
GET #1, , red
GET #1, , green
GET #1, , blue
red = CHR$(ASC(red) \ 4)
green = CHR$(ASC(green) \ 4)
blue = CHR$(ASC(blue) \ 4)
OUT dat, ASC(red)
OUT dat, ASC(green)
OUT dat, ASC(blue)
NEXT i

'LOAD PICTURE
SEEK #1, 129
rtim = TIMER
again:
GET #1, , buffer
back = VARSEG(buffer)
DEF SEG = VARSEG(buffer)
bufferadd = VARPTR(buffer)
                'seek
buffercount = bufferadd
WHILE buffercount < 12000 + bufferadd
char = PEEK((buffercount))
buffercount = buffercount + 1
IF bytepos >= 64000 THEN GOTO done
        IF char > 192 THEN
                loopfor = char - 192
                char = PEEK((buffercount))
                IF 12000 + bufferadd = buffercount THEN GET #1, , char2: char = ASC(char2) 'Hits boundary
                buffercount = buffercount + 1
                FOR i = 1 TO loopfor
                DEF SEG = &HA000: POKE bytepos, char: DEF SEG = back
                bytepos = bytepos + 1
                NEXT i

        ELSE
                DEF SEG = &HA000: POKE bytepos, char: DEF SEG = back
                bytepos = bytepos + 1
        END IF
WEND
IF bytepos < 64000 THEN GOTO again
done: DEF SEG
CLOSE
'This code will write the video buffer onto the disk as test.pct
'DEF SEG = &HA000
'BSAVE "test.pct", 0, 64000
'end of video buffer saving code
'You can use this for instant access to your pictures
'The palette is not saved. You can create code to save it (easiest to use
'a separate file) yourself. I have provided you with arrays of red, green
'and blue.

'These three lines will load up the quick-saved image. (minus the palette)
'SCREEN 13
'DEF SEG = &HA000
'BLOAD "test.pct"

WHILE INKEY$ = "": WEND

