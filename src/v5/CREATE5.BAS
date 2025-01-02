DECLARE SUB SavePicture (filename$)
DECLARE SUB SaveSpecialData (filename$)
DECLARE SUB FindNeutralGray (closestColor AS INTEGER)
DECLARE SUB DrawCanvasBorder ()
DECLARE SUB LoadPalette ()
DECLARE SUB Mouse()

DECLARE SUB DisplayImageArray (imageArray() AS INTEGER, startX AS INTEGER, startY AS INTEGER)

DEFINT B-C
DIM SHARED palettes$(10, 1)  ' Up to 10 palettes, with name and type
DIM SHARED activePalette AS INTEGER
DIM SHARED basicPal(255) AS LONG
DIM SHARED pl(255) AS LONG

' Mouse tracking
DIM SHARED lastB, lastA   ' Previous mouse X,Y coordinates
DIM SHARED buttons AS INTEGER  ' Current mouse button state
DIM SHARED blt AS INTEGER     ' Button state for debouncing (1=ready, 0=pressed)

DIM SHARED inary(7) AS INTEGER, outary(7) AS INTEGER

g = 32000
DIM SHARED stampBuffer(1 TO g) AS INTEGER  ' New array for stamp data
DIM SHARED c() AS INTEGER
DIM SHARED fca AS STRING
DIM SHARED fit AS INTEGER
DIM SHARED qa() AS INTEGER, qb() AS INTEGER
DIM SHARED x() AS INTEGER, y() AS INTEGER

' Mouse interrupt constants and variables
CONST BOUSE = 51 ' Mouse interrupt number
CONST ax = 0     ' Register indices for INT86
CONST bx = 1
CONST cx = 2
CONST dx = 3
CONST PALV1 = 1 ' Dream Giver
CONST PALV2 = 2 ' Space 2
CONST PALV3 = 3 ' Dark visions 2

initPalettes
SCREEN 13, 0
REDIM c(1 TO g) AS INTEGER  ' Allocate when needed
0 ' Must include this to load
  
  SCREEN 13
  ' End of including
  fe$ = "n" 
  fr$ = "n"       ' Flag to track if stamp tool is active
  stampSet = 0    ' Flag to track if stamp data exists
  CLS
1
  DIM h(500): DIM i(500)
  DIM su(100): DIM sm(100)
  DIM si(100): DIM col(300)
  DIM cl(5): DIM a(15)
  DIM word$(50): DIM low(50)
  DIM CS(31): DIM bs(31): DIM mess$(31)
  DIM ky$(31): DIM df$(31)
  DIM st(31): DIM vh$(50)
  
  FOR i = 1 TO 50
    vh$(i) = "                                                                               "
  NEXT i
  
  RANDOMIZE TIMER    ' Initialize random number generator using system timer
  DEF SEG = 0        ' Set the current segment to the BIOS data area
  POKE 1047, 32      ' Turns CAPS LOCK ON
  
  inary(ax) = 2  ' Initialize mouse
  CALL INT86OLD(BOUSE, inary(), outary())
  IF outary(ax) = 0 THEN
    PRINT "Mouse not available"
    END
  END IF

3
  DRAW "bm1,1c50r1"
  GET (1, 1)-(1, 1), a

5
  CLS
  a = 100
  B = 160
  gk = 1: fca = "z"
  q$ = "Type in name"
  f = 0
  e$ = "n"
  s = 1: c = 0
  COLOR 42
  LoadPalette
  DrawCanvasBorder
  'PALETTE 15, 50 + 50 * 65536 + 50 * 256

10
  oldB = B
  oldA = a
  
  ' Erase old cursor first if needed
  IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
  
  a$ = INKEY$
  ' Get mouse state first
  CALL Mouse
  
  ' Handle mouse movement and buttons
  IF buttons <> 0 THEN  ' Mouse button pressed
    xb = lastB
    ya = lastA
    IF f <> 0 AND buttons = 1 THEN LINE (xb, ya)-(B, a), f
  END IF
  ' Handle keyboard input if any
  IF a$ <> "" THEN GOTO 16
  GOTO 10
16 
  ' Process keyboard/mouse input
  IF a$ = "-" THEN d = d - 1: IF f <> 0 THEN f = f - 1: DRAW "c=" + VARPTR$(d)
  IF a$ = "=" THEN d = d + 1: IF f <> 0 THEN f = f + 1: DRAW "c=" + VARPTR$(d)
  IF fd <> d THEN LINE (206, 1)-(209, 3), d, BF: fd = d: LINE (B, a)-(B, a), POINT(B, a)
  IF a$ = " " THEN PSET (B, a), d  'Draw point at current position (B,a) using current color f

  'Add arrow key support (ASCII codes: up=0+72, down=0+80, left=0+75, right=0+77)
  IF a$ <> "" THEN  'Process keyboard input
    IF ASC(a$) = 0 THEN  'Extended key (arrow keys)
        ' Always erase cursor before moving
        IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
        SELECT CASE ASC(RIGHT$(a$, 1))
            CASE 72: a = a - s  'Up arrow
            CASE 80: a = a + s  'Down arrow
            CASE 75: B = B - s  'Left arrow
            CASE 77: B = B + s  'Right arrow
        END SELECT
        ' Always draw cursor after moving
        IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
    END IF
  END IF

  ' Process numpad movement
  IF a$ = "8" THEN a = a - s  ' Up
  IF a$ = "2" THEN a = a + s  ' Down
  IF a$ = "4" THEN B = B - s  ' Left
  IF a$ = "6" THEN B = B + s  ' Right

  ' Draw lines if in drawing mode
  IF (f <> 0 OR e$ = "y") AND (a$ = "8" OR a$ = "2" OR a$ = "4" OR a$ = "6") THEN
    SELECT CASE a$
        CASE "8": DRAW "u=" + VARPTR$(s)  ' Up
        CASE "2": DRAW "d=" + VARPTR$(s)  ' Down
        CASE "4": DRAW "l=" + VARPTR$(s)  ' Left
        CASE "6": DRAW "r=" + VARPTR$(s)  ' Right
    END SELECT
  END IF

  ' Draw cursor in new position
  IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR

  If a$ = "[" THEN DrawCanvasBorder

  IF a$ = "i" THEN
    d = POINT(B, a)
  END IF

  IF a$ = "." THEN
    IF SIZ = 0 THEN
      GOTO EnterLargeCursorMode
    ELSE 
      SIZ = 0
      f = d: DRAW "c=" + VARPTR$(f)
      a$ = "5"
      GOTO 61
    END IF
  END IF

  IF a$ = "c" THEN
    IF c = 0 THEN
      c = 1
      GET (2, 10)-(310, 199), c
      LINE (2, 10)-(310, 199), 0, BF
    ELSE c = 0
      PUT (2, 10), c, PSET
    END IF
  END IF

  IF a$ = "C" THEN
    GOTO click
  END IF

  IF a$ = "1" THEN
    IF f <> 0 OR e$ = "y" THEN
      DRAW "g=" + VARPTR$(s)
      a = a + s
      B = B - s
    ELSE
      a = a + s
      B = B - s
    END IF
  END IF
  IF a$ = "v" THEN GOSUB 2
  IF a$ = "j" THEN GOSUB 14

  IF a$ = "n" THEN
    LOCATE 25, 1
    PRINT "New?";
    DO
        zx$ = INKEY$
    LOOP UNTIL zx$ <> ""
    IF zx$ = "y" THEN
        GOSUB 5
    ELSE
        LOCATE 25, 1
        PRINT "    ";
    END IF
  END IF

  IF a$ = "\" THEN
    GET (2, 2)-(200, 100), c
    GOSUB 350
  END IF

  IF a$ = "9" THEN
    IF f <> 0 OR e$ = "y" THEN
      DRAW "e=" + VARPTR$(s)
      a = a - s
      B = B + s
    ELSE
      a = a - s
      B = B + s
    END IF
  END IF

  IF a$ = "`" THEN GOSUB TextInputMode
  
  IF a$ = "p" OR a$ = "P" THEN 
    activePalette = (activePalette + 1) MOD 4  ' Cycles through palettes 0-3
    LoadPalette
    DrawCanvasBorder
  END IF

  IF a$ = "f" THEN IF fe$ = "y" THEN fe$ = "n" ELSE fe$ = "y"
  
  IF a$ = "7" THEN IF f <> 0 OR e$ = "y" THEN DRAW "h=" + VARPTR$(s): a = a - s: B = B - s ELSE a = a - s: B = B - s
  
  IF a$ = "3" THEN IF f <> 0 OR e$ = "y" THEN DRAW "f=" + VARPTR$(s): a = a + s: B = B + s ELSE a = a + s: B = B + s
  
  IF fr$ = "y" AND stampSet THEN PUT (B, a), stampBuffer, PSET
  
  IF a$ = "t" THEN ft = POINT(B, a)
  
  IF a$ = "y" THEN fy = POINT(B, a)
  
  IF a$ = "]" THEN 
    IF stampSet = 0 THEN
        LOCATE 25, 1
        PRINT "Capture stamp first with 'g' key";
        fr$ = "n"
    ELSE
        IF fr$ = "n" THEN 
            fr$ = "y" 
        ELSE 
            fr$ = "n"
        END IF
    END IF
  END IF

  ' Fill effect: Replace colors in a 5x5 grid around cursor
  ' Replaces any pixels that match source color (ft) with target color (fy)
  IF fe$ = "y" THEN
    FOR gf = 0 TO 4
      FOR g = 0 TO 4
        IF POINT(B + gf, a + g) = ft THEN PSET (B + gf, a + g), fy
      NEXT g
    NEXT gf
  END IF

57
  ' Handle image restore functionality ("<" key)
  IF a$ = "<" THEN
    ' Prompt user to restore image
    LOCATE 25, 1
    PRINT "Restore image?";
    
    ' Wait for Y/N response
    cc$ = INKEY$
    IF cc$ = "" THEN 57
    
    IF cc$ = "y" THEN
      ' Restore saved image from buffer
      PUT (1, 10), c, PSET
    ELSE
      ' Clear prompt if not restoring
      LOCATE 25, 1
      PRINT "                    "
    END IF
  END IF

  IF a$ = "g" THEN GOSUB CaptureStampData
  
  IF a$ = "d" THEN GOSUB PasteStampWithOR
  
  IF a$ = "e" THEN GOSUB ScaleAndDrawRegion
  
  IF a$ = "%" THEN LOCATE 15, 1: INPUT gk: LOCATE 15, 1: PRINT "             ";
  
  IF a$ = "s" OR a$ = "S" THEN SavePicture q$
  
  IF a$ = "b" THEN LOCATE 15, 1: INPUT c: COLOR c
  
  IF SIZ = 1 THEN 70
  
  61
  ' Handle toggling drawing mode with '5' key
  IF a$ = "5" THEN
    IF f <> 0 THEN
      ' Turn off drawing mode
      DRAW "c0"
      IF SIZ = 0 THEN
        d = f  ' Save current color
        f = 0  ' Turn off drawing
        a$ = ""
      ELSE
        f = 0  ' Just turn off drawing
        a$ = ""
      END IF
    ELSE
      ' Turn on drawing mode
      DRAW "c=" + VARPTR$(d)  ' Restore saved color
      f = d                    ' Enable drawing
      GOTO 100
    END IF
  END IF

70
  ON ERROR GOTO 200
  IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
  IF f = 0 AND e$ = "y" AND SIZ = 0 THEN DRAW "c43u2r2d2l2c0u2r2d2l1u1bg1"
  IF a$ = "0" THEN s = s + 2: IF s = 5 OR s = 8 THEN s = 1
  IF a$ = "$" THEN GOSUB CountUniqueColors
  IF a$ = "z" THEN mz = B: mx = a
  IF a$ = "{" THEN GOSUB 183
  IF a$ = "x" THEN nz = B: nx = a
  IF a$ = "l" THEN IF f <> 0 THEN LINE (mz, mx)-(nz, nx), f ELSE LINE (mz, mx)-(nz, nx), d
  IF a$ = "u" THEN DRAW "c1": f = 1
  IF a$ = "o" THEN GOSUB 101
  IF a$ = "a" THEN GOSUB 185: GET (B, a)-(B + 18, a + 18), stampBuffer
  IF a$ = CHR$(13) THEN 115
  IF a$ = "r" OR a$ = "R" THEN GOSUB 260
  IF a$ = "(" THEN GOSUB 232
  IF a$ = ")" THEN GOSUB 242
  IF a$ = "k" THEN GOSUB 800
  IF a$ = "+" THEN IF s <> 6 THEN s = 6 ELSE s = 1
  IF a$ = "*" THEN GET (1, 10)-(319, 199), c: LINE (0, 10)-(321, 10), d: GOTO 140
96
  IF a$ = "q" THEN
    LOCATE 25, 1
    PRINT "Really quit?";
    ad$ = INKEY$
    IF ad$ = "" THEN 96 ELSE IF ad$ = "y" THEN SYSTEM ELSE LOCATE 25, 1: PRINT "                 ";
  END IF
  IF f = 0 AND e$ = "n" AND SIZ = 0 THEN PUT (B, a), a, XOR
  IF a$ = "/" AND SIZ = 0 THEN IF e$ = "y" THEN e$ = "n" ELSE e$ = "y"
100 GOTO 10

CountUniqueColors:
  ' This subroutine counts the number of unique colors used in the drawing area
  ' Initialize array to track which colors are used
  FOR i = 1 TO 256
    col(i) = 0
  NEXT i

  ' Scan the drawing area (301x189 pixels) and mark each color found
  FOR i = 1 TO 301
    FOR d = 11 TO 199
      col(POINT(i, d)) = 1  ' Mark color as used
    NEXT d
  NEXT i

  ' Count total number of unique colors used
  tc = 0
  FOR i = 0 TO 256
    IF col(i) = 1 THEN tc = tc + 1
  NEXT i

  ' Display count at line 17
  LOCATE 25, 1: PRINT tc;
RETURN

101 RETURN: LOCATE 1, 1: PRINT "What color   "
INPUT cl

204
  DRAW "c=" + VARPTR$(cl): f = cl
  LOCATE 15, 1: PRINT "             ": LOCATE 16, 1: PRINT "      "
RETURN

102 LOCATE 15, 1: INPUT f
105 IF f > 250 THEN 102
108 DRAW "c=" + VARPTR$(f)
110 GOTO 10
115 LOCATE 15, 1: INPUT q
125 CIRCLE (B, a), q, f
130 GOTO 100
140 LINE (B, a)-(B, a), 0
141 PAINT (B, a), f, f
145 GOTO 100
150 LOCATE 1, 1: PRINT q$; : INPUT f$
IF f$ = "a" OR f$ = "A" THEN RETURN
IF f$ <> "" THEN q$ = f$
IF a$ = "s" GOTO 778 ELSE GOTO 777
    ON ERROR GOTO 700
    OPEN q$ + ".pac" FOR INPUT AS #1
    INPUT #1, xzc, zxn
153 LOCATE 15, 1: PRINT "Save over previous picture?": a$ = INKEY$: IF a$ = "" THEN 153
    IF a$ = "y" THEN 151 ELSE ON ERROR GOTO 200: GOTO 10
151 CLOSE : LOCATE 15, 1
152 PRINT "                                "
155 DEF SEG = &HB800
160 BSAVE q$ + ".pic", 0, &H4000
165 OPEN q$ + ".pac" FOR OUTPUT AS #1
175 CLOSE
180 END

ScaleAndDrawRegion:
  ' This subroutine scales and draws a selected region of pixels
  ' Gets a scale factor (mel) from user
  ' Clears the drawing area (110-200 pixels from top)
  ' For each pixel in source region (mx,mz to nx,nz):
  '   - Gets the pixel color
  '   - Calculates new coordinates based on scale and orientation (gk)
  '   - Draws scaled pixel as filled box at new position
  ' Orientations (gk):
  '   1 = Normal
  '   2 = Flipped horizontally and vertically  
  '   3 = Flipped vertically
  '   4 = Flipped horizontally
  ' Returns if drawing goes past bottom edge (y>200)
  
  ' Get scale factor from user
  LOCATE 10, 30: INPUT mel
  
  ' Clear drawing area
  LINE (1, 110)-(320, 200), 0, BF
  
  ' Loop through source region pixels
  FOR axc = mx TO nx STEP 1
    FOR ixc = mz TO nz STEP 1
      ' Get color of current pixel
      pixelColor = POINT(ixc, axc)
      
      ' Calculate scaled coordinates based on orientation (gk)
      SELECT CASE gk
        CASE 2 ' Flipped horizontally and vertically
          x1 = 180 - (axc - mx) * mel
          y1 = 181 - (ixc - mz) * mel
          x2 = x1 - (mel - .9)
          y2 = y1 - (mel - .9)
          
        CASE 3 ' Flipped vertically
          x1 = 1 + (ixc - mz) * mel  
          y1 = 180 - (axc - mx) * mel
          x2 = x1 - (mel - .9)
          y2 = y1 - (mel - .9)
          
        CASE 1 ' Normal orientation
          x1 = 1 + (ixc - mz) * mel
          y1 = 120 + (axc - mx) * mel
          x2 = x1 - (mel - .9) 
          y2 = y1 - (mel - .9)
          
        CASE 4 ' Flipped horizontally
          x1 = 181 - (ixc - mz) * mel
          y1 = 120 + (axc - mx) * mel
          x2 = x1 - (mel - .9)
          y2 = y1 - (mel - .9)
      END SELECT
      
      ' Draw scaled pixel as filled box
      LINE (x1, y1)-(x2, y2), pixelColor, BF
      
      ' Check if we've gone past bottom edge
      IF y1 > 200 THEN RETURN
      
    NEXT ixc
  NEXT axc
RETURN

183
  mel = 1.8: mx = 100: nx = 1: mz = 1: nz = 320
  FOR axc = 100 TO 1 STEP -1
    FOR ixc = 1 TO 320 STEP 1
      LINE (1 + (ixc - mz) * mel, 200 + (axc - mx) * mel)-(1 + (ixc - mz) * mel - (mel - .9), 200 + (axc - mx) * mel - (mel - .9)), POINT(ixc, axc), BF
    NEXT ixc
  NEXT axc
RETURN

232
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), POINT(d, i) + 1
    NEXT d
  NEXT i
RETURN

242
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), POINT(d, i) - 1
    NEXT d
  NEXT i
RETURN

243
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), 15
    NEXT d
  NEXT i
RETURN

185
  LOCATE 15, 1: PRINT "Which box?": INPUT i
  x(i) = B: y(i) = a
RETURN

200 
  IF B > 319 THEN B = 319
  IF B < 1 THEN B = 1
  IF a < 1 THEN a = 1
  IF a > 199 THEN a = 199
  SOUND 400, 1: SOUND 200, .5
RESUME 10

TextInputMode:
  ' This subroutine implements a text input mode where the user can:
  ' - Move a cursor around the screen using arrow keys (8,4,6,2)
  ' - Type characters at the cursor position
  ' - Exit with the ` key
  '
  ' The cursor position is converted from pixel coordinates (a,B) 
  ' to character coordinates by dividing by 8 since each character
  ' cell is 8x8 pixels. The cursor is shown as a "." that gets
  ' replaced by typed characters.
  '
  ' Controls:
  ' 8 - Move cursor up
  ' 4 - Move cursor left 
  ' 6 - Move cursor right
  ' 2 - Move cursor down
  ' ` - Exit text input mode
  ' Any other key - Print that character at cursor
  
  ' Convert pixel coords to character coords
  pa = a \ 8  ' Y position in characters
  pb = B \ 8  ' X position in characters
221
  LOCATE pa, pb: PRINT "."  ' Show cursor
  a$ = INKEY$               ' Get keypress
  IF a$ = "" THEN 221       ' Wait for key
  LOCATE pa, pb: PRINT " "  ' Clear cursor
  IF a$ = CHR$(8) THEN a$ = "4"  ' Map backspace to left
  IF a$ = "8" THEN pa = pa - 1: GOTO 221  ' Up
  IF a$ = "4" THEN pb = pb - 1: GOTO 221  ' Left
235
  IF a$ = "6" THEN pb = pb + 1: GOTO 221  ' Right
  IF a$ = "2" THEN pa = pa + 1: GOTO 221  ' Down
  IF a$ = "`" THEN RETURN                 ' Exit
  LOCATE pa, pb: PRINT a$   ' Print typed character
  a$ = "6"                  ' Move right after typing
GOTO 235
'-------------END OF TEXTINPUTMODE-------------

260
  CLS
  FILES "*.pic"        ' Shows available .pic files
  CLOSE : INPUT q$     ' Get filename from user
  IF a$ = "r" THEN
    GOTO LoadPictureFullscreen
  ELSE
    GOTO LoadPicturePositioned
  END IF
  CLS
  'DEF SEG = &HB800
  'BLOAD q$ + ".pic", 0: GOTO 10

EnterLargeCursorMode:
  SIZ = 1 ' Set SIZ flag to 1 to indicate we're in "large cursor" mode
  DRAW "c0" ' Set drawing color to black (0) to erase previous cursor
  
  IF f <> 0 THEN d = f  ' Save current color if drawing was active
  f = 4                 ' Set new color to 4
  a$ = ""              ' Clear key input
GOTO 10

CaptureStampData:
' Sets stampSet flag and copies pixels from mz,mx to nz,nx into stampBuffer
  stampSet = -1
  GET (mz, mx)-(nz, nx), stampBuffer
RETURN

PasteStampWithOR:
  ' Paste the stamp buffer at current cursor position (B,a) using OR mode
  ' OR mode combines the stamp with existing pixels rather than overwriting
  PUT (B, a), stampBuffer, OR
RETURN

350
  tile$ = ""
  FOR i = ft TO fy
    tile$ = tile$ + CHR$(i)
  NEXT i

  LINE (0, 10)-(321, 10), f, B
  PAINT (B, a), tile$, f
  tile$ = ""
RETURN

FOR i = 1 TO 120
LINE (i + 30, 1)-(i + 30, 2), i
NEXT i
FOR i = 121 TO 255
LINE (i - 95, 3)-(i - 95, 4), i
NEXT i
RETURN
400 '-------------Click starts----------------
click:
401 tr$ = "n"
    fca = "c"
440 SCREEN 13
    FILES "*.pic"
450 INPUT q$
  REM  GOSUB 709 'load specials
453 CLOSE
454 CLS : B = 50: dd = 50: GOTO 500
455 GOSUB LoadPicturePositioned
RETURN
462 LOCATE 1, 1: PRINT "                                       "
464 LOCATE 2, 1: PRINT "                                       "
465 LOCATE 3, 1: PRINT "                                       "
466 LOCATE 4, 1: PRINT "                                       "
470 RETURN
500 ON ERROR GOTO 820
CQ = CQ + 1
502 IF CQ > 30 THEN 525
503 INPUT "More"; a$
504 IF a$ = "n" OR a$ = "no" OR a$ = "N" OR a$ = "NO" THEN 525 ELSE GOSUB 455
LOCATE 1, 1: PRINT "Special #"; CQ
508 GOSUB 462: LOCATE 2, 1: PRINT "What number can`t be set?"
LOCATE 3, 1: INPUT CS(CQ)
512 GOSUB 462: LOCATE 2, 1: PRINT "What # must be set?"
514 INPUT bs(CQ)
516 GOSUB 462: LOCATE 2, 1: PRINT "What gets set?"
518 INPUT st(CQ)
GOSUB 462: LOCATE 2, 1: PRINT "What is displayed?"
522 INPUT mess$(CQ)
523 GOSUB 462: LOCATE 2, 1: PRINT "What key activates?": INPUT ky$(CQ)
524 GOSUB 462: LOCATE 2, 1: PRINT "Extra info?/Transfer": INPUT df$(CQ): GOTO 500
525 CLS
GOSUB LoadPicturePositioned
565 DRAW "c51bm1,1r3d3l3u2r1d1r1u1"
570 GET (1, 1)-(4, 4), a
571 DRAW "bm200,6c2r75"
572 PUT (B, dd), a, XOR
574 a$ = INKEY$: IF a$ = "" THEN 574
575 PUT (B, dd), a, XOR
ON ERROR GOTO 820
    IF tar$ = "y" AND a$ <> "t" THEN GOSUB 815
579 IF a$ = "2" THEN dd = dd + 4
585 IF a$ = "8" THEN dd = dd - 4
590 IF a$ = "4" THEN B = B - 4
    IF a$ = "7" THEN B = B - 4: dd = dd - 4
    IF a$ = "9" THEN B = B + 4: dd = dd - 4
    IF a$ = "1" THEN B = B - 4: dd = dd + 4
    IF a$ = "3" THEN B = B + 4: dd = dd + 4
    IF a$ = "f" THEN GOSUB 810
    IF a$ = "t" THEN IF tar$ = "n" THEN tar$ = "y": INPUT ap$ ELSE tar$ = "n"
592 IF a$ = "s" THEN GOSUB 890
    IF a$ = "d" THEN GOSUB 789: LOCATE 1, 1: ip = 1: INPUT gp$: FOR i = 1 TO 30: GOSUB 790: NEXT i
593 IF a$ = "e" THEN LOCATE 16, 1: PRINT "Exit click?": a$ = INKEY$: IF a$ = "" THEN a$ = "e": GOTO 593 ELSE IF a$ = "y" THEN RUN
595 IF a$ = "6" THEN B = B + 4
596 IF a$ = CHR$(13) THEN IF gs < 75 THEN GOSUB 610 ELSE BEEP
600 GOTO 572
610 LOCATE 1, 1
614 PRINT "What special?"
615 INPUT ap$
621 MID$(vh$(dd \ 4 + 1), B \ 4 + 1, 1) = ap$: GOTO 625
635 IF si(gs) <> 0 THEN GOTO 635
622 si(gs) = B: su(gs) = dd
624 sm(gs) = i: gs = gs + 1
625 LOCATE 1, 1: PRINT "       "
DRAW "bm275,6c0l=" + VARPTR$(gs)
630 RETURN
640 OPEN q$ + ".pac" FOR OUTPUT AS #1
    GOSUB 641
    GOTO 680
641 WRITE #1, c, ia, ib, ic
645 CLOSE : RETURN
680 PRINT "Edit another file?"
682 a$ = INKEY$: IF a$ = "" THEN 682
684 IF a$ = "y" THEN RUN
685 IF a$ = "n" THEN SYSTEM
687 PRINT "Type y or n": GOTO 682
709 ' Loads screen's push/open/use/look
CLOSE
OPEN q$ + ".dat" FOR INPUT AS #1
INPUT #1, fit
FOR i = 1 TO 5
INPUT #1, qa(i), qb(i), x(i), y(i)
NEXT i
INPUT #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
FOR i = 1 TO 50
INPUT #1, vh$(i)
NEXT i
FOR i = 1 TO 30
 INPUT #1, mess$(i), ky$(i), bs(i), CS(i), st(i), df$(i)
 NEXT i
RETURN
789 LOCATE 1, 1: PRINT "                                                                "
LOCATE 2, 1: PRINT "                                                                "
RETURN
790 IF LEFT$(df$(i), 1) <> gp$ THEN RETURN
ip = ip + 1
    LOCATE ip, 1: PRINT mess$(i)
    RETURN

700 ON ERROR GOTO 200
    RESUME 151
800 LOCATE 15, 1: PRINT "Really kill image? Y/n"
a$ = INKEY$: IF a$ = "" THEN 800
IF a$ = "Y" THEN KILL q$ + ".pic": CLOSE : KILL q$ + ".dat"
LOCATE 15, 1: PRINT "                         "
RETURN
810 LOCATE 1, 1: PRINT "      "
    PRINT MID$(vh$(dd \ 4 + 1), B \ 4 + 1, 1)
    RETURN
820 B = 50: dd = 50: BEEP
    'LOCATE 20, 1: PRINT ERL, ERR
    RESUME 572
890 CLOSE : GOSUB 891
895 LOCATE 16, 1: PRINT "Saving specials"
CLOSE
OPEN q$ + ".dat" FOR OUTPUT AS #1
WRITE #1, fit
FOR i = 1 TO 5
WRITE #1, qa(i), qb(i), x(i), y(i)
NEXT i
WRITE #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
FOR i = 1 TO 50
WRITE #1, vh$(i)
NEXT i
 FOR i = 1 TO 30
 WRITE #1, mess$(i), ky$(i), bs(i), CS(i), st(i), df$(i)
 NEXT i
RETURN
891 RETURN
815 SOUND 100, .1
GOTO 621
777 GET (mz, mx)-(nz, nx), c(3)
  DEF SEG = VARSEG(c(1))
  c(1) = mz: c(2) = mx
  BSAVE q$ + ".pic", VARPTR(c(1)), (mz - nz) * (mx - nx)
  DEF SEG
  'GOSUB 895
  RETURN
778 GET (2, 10)-(310, 198), c
  DEF SEG = VARSEG(c(1))
  BSAVE q$ + ".pic", VARPTR(c(1)), 57000
  DEF SEG
  'GOSUB 895
  RETURN

LoadPictureFullscreen:
    CLS
    '------- LOADING OF THE PICTURE -------
    GET (2, 10)-(310, 199), c
    DEF SEG = VARSEG(c(1))
    BLOAD q$ + ".pic", VARPTR(c(1))  ' Actually loads the file
    
    DEF SEG = 0
    c = 0
    PUT (2, 10), c, PSET         ' Displays the loaded image
    'PUT (62 + 40 * 0, 173), c(1 + 510 * 2), PSET
    DisplayImageArray c(), 2, 10
    GOTO 883
RETURN

LoadPicturePositioned:
    print "LoadPicturePositioned"
    CLS
    '------- LOADING OF THE PICTURE -------
    GET (2, 10)-(310, 199), c
    DEF SEG = VARSEG(c(1))
    BLOAD q$ + ".pic", VARPTR(c(1))
    DEF SEG = 0
    c = 0
    PUT (c(1), c(2)), c(3), PSET 'places picture in certain position
    '-------- END OF LOAD -------------
883
  ON ERROR GOTO 900
    'IF fca <> "c" THEN GOSUB 709
884
  LoadPalette
  ON ERROR GOTO 200
RETURN

900 RESUME 884

'----------------------All about guy------------------------
2
  x = 165: y = 145: g = 178: f = 167: j = -120: fh = 3: bob = 0
  CS = 180: CS = 33: cp = 32: cp = 204: ch = 175: ch = 24: cf = 120: cf = 150
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  vg = 0
310
  GET (x - 22, y - 36)-(x + 11, g + 10), c
  bob = bob + fh: IF bob = 6 THEN fh = -3 ELSE IF bob < -5 THEN fh = 3
  FOR i = 0 TO 5
    LINE (x + i, y)-(f + i - 1, g + bob), cp - i * 1.5
    LINE (x - i, y)-(f - i + 1, g + bob), cp - i * 1.5
  NEXT i
  FOR i = 0 TO 4
    LINE (x + i - 9, y)-(f + i - 1 - 9, g - bob), cp - i * 1.5
    LINE (x - i - 9, y)-(f - i + 1 - 9, g - bob), cp - i * 1.5
  NEXT i
  IF vg = 0 THEN GOSUB 420
GOTO 421

420
  x = x - 5
  FOR i = 0 TO 5
    LINE (x + i - 2, y - 2)-(x + i, y - 20 + i / 2), CS - i
    LINE (x - i + 2, y - 2)-(x - i, y - 20 + i / 2), CS - i
  NEXT i
  x = x + 5
  LINE (x - 13, y)-(x + 4, y), 4
  LINE (x - 13, y - 1)-(x + 4, y - 1), 12
RETURN

421
  FOR i = 0 TO 3
    LINE (x + 4 + i, y - 17 + i)-(x + 7 + i, y + 5 - bob / 1.5), CS - 2 - i
    LINE (x + 4 - i, y - 17 + i)-(x + 9 - i, y + 5 - bob / 1.5), CS - 2 - i
    LINE (x - 15 + i, y - 17 + i)-(x - 20 + i, y + 5 + bob / 1.5), CS - i
    LINE (x - 15 - i, y - 17 + i)-(x - 18 - i, y + 5 + bob / 1.5), CS - i
  NEXT i
  FOR i = 0 TO 2
    LINE (x + 9, y + 6 + i - bob / 1.5)-(x + 5 + i, y + 6 + i - bob / 1.5), cf
    LINE (x - 17 - i, y + 6 + i + bob / 1.5)-(x - 20, y + 6 + i + bob / 1.5), cf
    LINE (f + 4 + i, g + 1 + i + bob)-(f - 1, g + 1 + i + bob), cf - i * 2
    LINE (f - 12 - i, g + 1 + i - bob)-(f - 8, g + 1 + i - bob), cf - i * 2
  NEXT i
  IF vg = 1 THEN GOSUB 420
  IF vg = 0 THEN 415
  CIRCLE (x - 5, y - 25), 6, ch, , , 1.5
  PAINT (x - 5, y - 25), ch, ch
  FOR i = 0 TO 3
    CIRCLE (x - 5, y - 25 - i), 6, ch + 1, .5 - (i / 5), 2.5 + (i / 5), 1.5
  NEXT i
GOTO 405

415 
  CIRCLE (x - 5, y - 25), 6, cf, , , 1.5
  PAINT (x - 5, y - 25), cf, cf
  FOR i = 0 TO 3
    CIRCLE (x - 5, y - 25 - i), 6, ch, .5 - (i / 5), 2.5 + (i / 5), 1.5
  NEXT i
  PSET (x - 8, y - 26), 0: PSET (x - 2, y - 26), 0
GOTO 405

405
  FOR i = 1 TO 6400: NEXT i: a$ = "8"
  IF vg = 0 THEN j = j + 3 ELSE j = j - 3
  PUT (x - 22, y - 36), c, PSET
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  IF j > 0 THEN vg = 1
  IF j < -120 THEN WINDOW SCREEN (1, 1)-(320, 200): RETURN
GOTO 310

'-------------------Sideways guy----------------------
14
  x = 165: y = 145: g = 178: f = 167: j = 0: fh = 4: dg = 0: bob = 0
  CS = 180: CS = 33: cp = 32: cp = 204: ch = 175: ch = 24: cf = 120: cf = 150
  IF dg = 1 THEN lk = 1: pk = 0 ELSE pk = 1: lk = 0
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  vg = 0
510
  GET (x - 30, y - 36)-(x + 18, g + 10), c
  bob = bob + fh: IF bob > 7 THEN fh = -4 ELSE IF bob < -5 THEN fh = 4
  FOR i = 0 TO 3
    LINE (x - 13 + i, y - 17 + i)-(x - 18 + i + bob, y + 5), CS - i
    LINE (x - 13 - i, y - 17 + i)-(x - 16 - i + bob, y + 5), CS - i
  NEXT i
  FOR i = 0 TO 2
    LINE (x - 15 - i + bob, y + 6 + i)-(x - 18 + bob, y + 6 + i), cf
    LINE (f - 12 - i * pk - bob, g + 1 + i)-(f - 8 - bob + i * lk, g + 1 + i), cf - i * 2
  NEXT i
  FOR i = 0 TO 4
    LINE (x + i - 9, y)-(f + i - 1 - 9 - bob, g), cp - i * 1.5
    LINE (x - i - 9, y)-(f - i + 1 - 9 - bob, g), cp - i * 1.5
  NEXT i
  FOR i = 0 TO 5
    LINE (x - 8 + i, y)-(f - 8 + i - 1 + bob, g + 2), cp - i * 1.5
    LINE (x - 8 - i, y)-(f - 8 - i + 1 + bob, g + 2), cp - i * 1.5
  NEXT i
  IF vg = 0 THEN GOSUB 520
GOTO 521

520
  x = x - 5
  FOR i = 0 TO 5
    LINE (x + i - 6, y - 2)-(x + i - 4, y - 20 + i), CS - i
    LINE (x - i - 2, y - 2)-(x - i - 4, y - 20 + i), CS - i
  NEXT i
  x = x + 5
  LINE (x - 13, y)-(x - 4, y), 4
  LINE (x - 13, y - 1)-(x - 4, y - 1), 12
RETURN

521
  FOR i = 0 TO 3
    LINE (x - 6 + i, y - 17 + i)-(x - 3 + i - bob, y + 5), CS - 2 - i
    LINE (x - 6 - i, y - 17 + i)-(x - 4 - i - bob, y + 5), CS - 2 - i
  NEXT i
  FOR i = 0 TO 2
    LINE (x - 3 - bob, y + 6 + i)-(x - 6 + i - bob, y + 6 + i), cf
    LINE (f - 11 - i * pk + bob, g + 3 + i)-(f - 6 + bob + i * lk, g + 3 + i), cf - i * 2
  NEXT i
  IF vg = 1 THEN GOSUB 520
  IF dg = 0 THEN 515
  CIRCLE (x - 8, y - 25), 6, ch, , , 1.5
  PAINT (x - 8, y - 25), ch, ch
  FOR i = 0 TO 2
    CIRCLE (x - 9 + i, y - 25), 6, cf, 5, 1, 1.5
  NEXT i
  PSET (x - 3, y - 26), 0
GOTO 505

515 CIRCLE (x - 9, y - 25), 6, ch, , , 1.5
  PAINT (x - 9, y - 25), ch, ch
  FOR i = 0 TO 3
    CIRCLE (x - 9 + i, y - 25), 6, cf, 2.5, 4.5, 1.5
  NEXT i
  PSET (x - 12, y - 26), 0
GOTO 505

505
  FOR i = 1 TO 6200: NEXT i: a$ = "8"
  PUT (x - 30, y - 36), c, PSET
  IF dg = 1 THEN x = x + 4: f = f + 4 ELSE x = x - 4: f = f - 4
  IF vg = 0 THEN j = j + 0 ELSE j = j - 0
  WINDOW SCREEN (320 - j * 3, 1 + j * 2)-(j * 3, 200 - j * 2)
  IF j > 0 THEN vg = 1
  IF j < -120 OR x < 34 THEN WINDOW SCREEN (1, 1)-(320, 200): RETURN
GOTO 510



SUB SavePicture (filename$)
    SHARED c() AS INTEGER, fca AS STRING, fit AS INTEGER, qa() AS INTEGER, qb() AS INTEGER, x() AS INTEGER, y() AS INTEGER
    SHARED gen$, da$(), vh$(), mess$(), ky$(), bs(), CS(), st(), df$()
    
    ' Calculate image size
    ' Add 1 to include both start and end coordinates
    imageWidth = 309    ' (310 - 2 + 1) pixels wide
    imageHeight = 189   ' (198 - 10 + 1) pixels high
    headerSize = 8      ' GET/PUT overhead bytes
    imageBytes = (imageWidth * imageHeight) + headerSize

    LOCATE 1, 1
    PRINT filename$;
    INPUT f$
    
    IF f$ = "a" OR f$ = "A" THEN 
        EXIT SUB
    END IF
    
    IF f$ <> "" THEN 
        filename$ = f$
    END IF
    
    'Save screen data
    GET (2, 10)-(310, 198), c
    DEF SEG = VARSEG(c(1))
    BSAVE filename$ + ".pic", VARPTR(c(1)), imageBytes
    DEF SEG
    
    'Save special data if needed
    IF fca = "c" THEN SaveSpecialData filename$
    
    CLOSE
END SUB

SUB SaveSpecialData (filename$)
    SHARED fit AS INTEGER, qa() AS INTEGER, qb() AS INTEGER, x() AS INTEGER, y() AS INTEGER
    SHARED gen$, da$(), vh$(), mess$(), ky$(), bs(), CS(), st(), df$()
    
    CLOSE
    OPEN filename$ + ".dat" FOR OUTPUT AS #1
    WRITE #1, fit
    FOR i = 1 TO 5
        WRITE #1, qa(i), qb(i), x(i), y(i)
    NEXT i
    WRITE #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
    FOR i = 1 TO 50
        WRITE #1, vh$(i)
    NEXT i
    FOR i = 1 TO 30
        WRITE #1, mess$(i), ky$(i), bs(i), CS(i), st(i), df$(i)
    NEXT i
    CLOSE
END SUB

SUB FindNeutralGray (closestColor AS INTEGER)
  SHARED pl() AS LONG ' Assuming pl() contains the palette data as RGB longs
  
  ' Target values for 50% gray (all RGB components = 32)
  targetGray = 32
  
  closestDiff = 999  ' Start with large number
  closestColor = 0   ' Default to black
  
  ' Loop through palette colors 1-255 (skip 0 which is usually black)
  FOR i = 1 TO 255
      ' Extract RGB values from long
      blue = pl(i) \ 65536        ' Get blue component
      green = (pl(i) \ 256) MOD 256  ' Get green component
      red = pl(i) MOD 256        ' Get red component
      
      ' Calculate luminance difference using standard weights
      colorDiff = ABS(red - targetGray) * .299    ' Red contributes 30%
      colorDiff = colorDiff + ABS(green - targetGray) * .587  ' Green contributes 59%
      colorDiff = colorDiff + ABS(blue - targetGray) * .114   ' Blue contributes 11%
      
      ' Add penalty for colors where R,G,B are very different from each other
      rgDiff = ABS(red - green)
      gbDiff = ABS(green - blue)
      rbDiff = ABS(red - blue)
      colorDiff = colorDiff + (rgDiff + gbDiff + rbDiff) / 3  ' Increased penalty
      
      ' If this is closest match so far, save it
      IF colorDiff < closestDiff THEN
          closestDiff = colorDiff
          closestColor = i
      END IF
  NEXT i
  ' If active palette type is 2, add 16 to closest color
  IF activePalette = 2 THEN
    closestColor = closestColor + 16
  END IF
END SUB

SUB DrawCanvasBorder ()
  SHARED pl() AS LONG
  
  ' Get the neutral gray color
  DIM grayColor AS INTEGER
  FindNeutralGray grayColor
  
  ' Canvas coordinates
  left = 2
  top = 10
  right = 310
  bottom = 198
  
  markLength = 3  ' Length of each registration mark
  
  ' Calculate midpoints
  midX = (left + right) \ 2
  midY = (top + bottom) \ 2
  
  ' Draw corner registration marks
  ' Top Left
  LINE (left - 1, top - 1)-(left + markLength, top - 1), grayColor  ' Horizontal
  LINE (left - 1, top - 1)-(left - 1, top + markLength), grayColor  ' Vertical
  
  ' Top Right
  LINE (right - markLength, top - 1)-(right + 1, top - 1), grayColor  ' Horizontal
  LINE (right + 1, top - 1)-(right + 1, top + markLength), grayColor  ' Vertical
  
  ' Bottom Left
  LINE (left - 1, bottom + 1)-(left + markLength, bottom + 1), grayColor  ' Horizontal
  LINE (left - 1, bottom - markLength)-(left - 1, bottom + 1), grayColor  ' Vertical
  
  ' Bottom Right
  LINE (right - markLength, bottom + 1)-(right + 1, bottom + 1), grayColor  ' Horizontal
  LINE (right + 1, bottom - markLength)-(right + 1, bottom + 1), grayColor  ' Vertical
  
  ' Draw midpoint registration marks
  ' Top
  LINE (midX - markLength, top - 1)-(midX + markLength, top - 1), grayColor
  'LINE (midX, top - 1)-(midX, top + markLength), grayColor
  
  ' Bottom
  LINE (midX - markLength, bottom + 1)-(midX + markLength, bottom + 1), grayColor
  
  ' Left
  LINE (left - 1, midY - markLength)-(left - 1, midY + markLength), grayColor
  
  ' Right
  LINE (right + 1, midY - markLength)-(right + 1, midY + markLength), grayColor
END SUB

SUB LoadPalette ()
    SHARED pl() AS LONG, palettes$(), activePalette AS INTEGER, basicPal() AS LONG
    ' Reset palette to default values
    FOR i = 1 TO 255
        PALETTE i, basicPal(i)
    NEXT i
    pallet$ = palettes$(activePalette, 0)
    palType = VAL(palettes$(activePalette, 1))
    
    OPEN pallet$ FOR INPUT AS #1     ' Opens the palette file
    
    IF palType = PALV1 THEN
      'type 1 - loads with offset and early exit on zero
      FOR i = 1 TO 255 STEP 1
          INPUT #1, pl(i)              ' Reads each color value
          IF pl(i) = 0 AND i > 10 THEN i = 255
          PALETTE i + 16, pl(i)
      NEXT i
    ELSEIF palType = PALV3 THEN
      CLOSE #1
      bright = 3  ' Brightness multiplier (1 = normal, 2 = twice as bright, etc.)
      OPEN pallet$ FOR BINARY AS #1
      'type 3 - loads RGB bytes individually
      FOR i = 1 TO 255
        IF EOF(1) THEN EXIT FOR
          red = (ASC(INPUT$(1, #1)) * bright) \ 4     ' Apply brightness before scaling
          IF red > 63 THEN red = 63                    ' Clamp to max brightness
          green = (ASC(INPUT$(1, #1)) * bright) \ 4
          IF green > 63 THEN green = 63
          blue = (ASC(INPUT$(1, #1)) * bright) \ 4
          IF blue > 63 THEN blue = 63
          pl(i) = (blue * 65536) + (green * 256) + red
      NEXT i
      PALETTE USING pl(0)
    ELSE
      'type 2 - loads all colors and applies at once
      FOR i = 1 TO 255 STEP 1          ' Loops through all possible colors
          INPUT #1, pl(i)              ' Reads each color value
      NEXT i
      PALETTE USING pl(0)              ' Applies the loaded palette
    END IF
    
    CLOSE #1
    
    ' Clear the palette display area first (black box over old palette)
    LINE (0, 1)-(360, 6), 0, BF
    
    ' Draw the palette display with 3x2 pixel rectangles
    FOR i = 1 TO 120
        LINE (i * 3, 1)-(i * 3 + 2, 2), i, BF      ' Draw top row of colors
    NEXT i
    FOR i = 121 TO 255
        LINE ((i - 120) * 3, 4)-((i - 120) * 3 + 2, 5), i, BF      ' Draw bottom row of colors
    NEXT i
END SUB

' Initialize palette configurations
SUB InitPalettes()
    SHARED palettes$(), activePalette AS INTEGER, basicPal() AS LONG
    ' Save current palette values before loading new ones
    FOR i = 0 TO 255
        OUT &H3C7, i          ' Tell VGA we want to read color i
        red = INP(&H3C9)      ' Read red component
        green = INP(&H3C9)    ' Read green component
        blue = INP(&H3C9)     ' Read blue component
        basicPal(i) = red + (green * 256) + (blue * 65536)
    NEXT i
    ' Format: palettes$(index, 0) = filename, palettes$(index, 1) = type
    palettes$(0, 0) = "house2.pal"  : palettes$(0, 1) = STR$(PALv2)
    palettes$(1, 0) = "SHIP2.pal"  : palettes$(1, 1) = STR$(PALV2)
    palettes$(2, 0) = "256colo.pal"  : palettes$(2, 1) = STR$(PALV1)
    palettes$(3, 0) = "DARK.pal"  : palettes$(3, 1) = STR$(PALV3)
    activePalette = 0
END SUB

SUB Mouse()
  SHARED lastB, lastA   ' Previous mouse X,Y coordinates
  SHARED buttons AS INTEGER  ' Current mouse button state
  SHARED blt AS INTEGER     ' Button state for debouncing (1=ready, 0=pressed)
  SHARED inary() AS INTEGER, outary() AS INTEGER
  SHARED B, a, f, e$, a() ' Add cursor array and drawing flags
  STATIC cursorVisible AS INTEGER  ' Track cursor visibility state
  
  ' Get current mouse position
  inary(ax) = 3
  CALL INT86OLD(BOUSE, inary(), outary())
  
  ' Calculate new position
  newB = outary(cx) \ 2
  newA = outary(dx)
  
  ' Only update position if mouse has moved
  IF newB <> lastB OR newA <> lastA THEN
    ' Always erase cursor at OLD position if it was visible
    IF f = 0 AND e$ = "n" AND cursorVisible THEN 
      PUT (lastB, lastA), a, XOR
      cursorVisible = 0
    END IF
    
    ' Update to new position
    B = newB
    a = newA
    
    ' Constrain to screen boundaries
    IF B < 1 THEN B = 1
    IF B > 319 THEN B = 319
    IF a < 1 THEN a = 1
    IF a > 199 THEN a = 199
    
    ' Draw cursor at new position
    IF f = 0 AND e$ = "n" THEN 
      PUT (B, a), a, XOR
      cursorVisible = -1
    END IF
    
    ' Save position for next time
    lastB = B
    lastA = a
  END IF
  
  ' Button handling with debounce
  bbb = outary(bx)
  buttons = 0
  IF bbb = 1 AND blt = 1 THEN buttons = 1: blt = 0  ' Left click
  IF bbb = 2 AND blt = 1 THEN buttons = 2: blt = 0  ' Right click
  IF bbb = 0 THEN blt = 1  ' Released
END SUB


SUB DisplayImageArray (imageArray() AS INTEGER, startX AS INTEGER, startY AS INTEGER)
  '=============================================================================
  ' Constants for screen dimensions and layout
  '=============================================================================
  CONST SPACING = 4        ' Pixels between displayed images
  CONST SCREEN_WIDTH = 320 ' Mode 13h screen width in pixels
  CONST SCREEN_HEIGHT = 200 ' Mode 13h screen height in pixels
  
  '=============================================================================
  ' Initialize position tracking variables
  '=============================================================================
  currentX = startX        ' Current X position for image placement
  currentY = startY        ' Current Y position for image placement 
  maxHeightInRow = 0       ' Tracks tallest image in current row
  imageIndex = 1           ' Index into image array
  
  '=============================================================================
  ' Main image display loop
  '=============================================================================
  DO WHILE imageIndex < UBOUND(imageArray)
    ' Get image width from header (stored as bytes, convert to pixels)
    pixelWidth = imageArray(imageIndex) \ 8
    
    ' Skip invalid images
    IF pixelWidth = 0 THEN
      imageIndex = imageIndex + 1
      GOTO LoopEnd
    END IF
    
    ' Read remaining header info
    height = imageArray(imageIndex + 1)     ' Image height in pixels
    dataStart = imageArray(imageIndex + 3)   ' Offset to image data
    
    ' Move to next row if current image won't fit
    IF currentX + pixelWidth > SCREEN_WIDTH THEN
      currentX = startX
      currentY = currentY + maxHeightInRow + SPACING
      maxHeightInRow = 0
    END IF
    
    ' Stop if we've run out of vertical space
    IF currentY + height > SCREEN_HEIGHT THEN EXIT DO
    
    ' Display the image and draw border
    PUT (currentX, currentY), imageArray(imageIndex), PSET
    LINE (currentX - 1, currentY - 1)-(currentX + pixelWidth, currentY + height), 15, B
    
    ' Update position and row height tracking
    currentX = currentX + pixelWidth + SPACING
    IF height > maxHeightInRow THEN maxHeightInRow = height
    
    ' Calculate next image position in array:
    ' Skip header (3 words) plus image data size in words
    imageSize = 3 + ((pixelWidth * height + 1) \ 2)
    imageIndex = imageIndex + imageSize
    
    ' Position debug output
    LOCATE 10, 1
      'PRINT "Found image: "; pixelWidth; "x"; height; " at index "; imageIndex; "   "
LoopEnd:
  LOOP
  
  ' Display final count
  ' LOCATE 2, 1
  'PRINT "Total images displayed: "; imageIndex; "   "
END SUB