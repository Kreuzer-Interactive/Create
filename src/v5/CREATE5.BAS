'$INCLUDE: 'modules\CONFIG.BI'
'$INCLUDE: 'modules\PAL.BI'
'$INCLUDE: 'modules\UNDO.BI'
DECLARE SUB SavePicture (filename$)
DECLARE SUB SaveSpecialData (filename$)
DECLARE SUB DrawCanvasBorder ()
DECLARE SUB Mouse ()
DECLARE SUB DisplayImageArray (imageArray() AS INTEGER, startX AS INTEGER, startY AS INTEGER)

DEFINT B-C
DIM SHARED palettes$(10, 1)  ' Up to 10 palettes, with name and type

' Mouse tracking
DIM SHARED lastB, lastA   ' Previous mouse X,Y coordinates
DIM SHARED buttons AS INTEGER  ' Current mouse button state
DIM SHARED blt AS INTEGER     ' Button state for debouncing (1=ready, 0=pressed)

DIM SHARED inary(7) AS INTEGER, outary(7) AS INTEGER

DIM SHARED stampBuffer() AS INTEGER  ' New array for stamp data
DIM SHARED c() AS INTEGER
DIM SHARED fca AS STRING
DIM SHARED fit AS INTEGER
DIM SHARED qa() AS INTEGER, qb() AS INTEGER
DIM SHARED x() AS INTEGER, y() AS INTEGER
DIM SHARED settings(10, 10) AS STRING

' Mouse interrupt constants and variables
CONST BOUSE = 51 ' Mouse interrupt number
CONST ax = 0     ' Register indices for INT86
CONST bx = 1
CONST cx = 2
CONST dx = 3

SCREEN 13, 0
REDIM c(1 TO bufferSize) AS INTEGER
REDIM stampBuffer(1 TO bufferSize) AS INTEGER
0 PRINT "Starting...":' Must include this to load
  
  SCREEN 13
  ' End of including
  fe$ = "n"
  fr$ = "n"       ' Flag to track if stamp tool is active
  stampSet = 0    ' Flag to track if stamp data exists
  activeGame = 1
  activePalette = 1
  DIM basicPal(255) AS LONG
  DIM pl(255) AS LONG
  DIM games(10) AS GAMECONFIG   ' Allow for up to 10 games
  gameCount = 0                 ' No games loaded yet
  activeGame = 1               ' Start with first game
  CLS
1
  DIM h(500): DIM I(500)
  DIM su(100): DIM sm(100)
  DIM si(100): DIM col(300)
  DIM cl(5): DIM a(15)
  DIM word$(50): DIM low(50)
  DIM CS(31): DIM bs(31): DIM mess$(31)
  DIM ky$(31): DIM df$(31)
  DIM st(31): DIM vh$(50)
  CALL CleanupUndo
  CALL InitializeUndo
  LoadGameINI "CFG.INI"
  InitPalettes
  
  FOR i = 1 TO 50
    vh$(i) = "                                                                               "
  NEXT i
  
  RANDOMIZE TIMER    ' Initialize random number generator using system timer
  DEF SEG = 0        ' Set the current segment to the BIOS data area
  POKE 1047, 32      ' Turns CAPS LOCK ON
  
  ' Try to initialize mouse multiple times
  FOR mouseRetry = 1 TO 3
    inary(ax) = 2  ' Initialize mouse
    CALL INT86OLD(BOUSE, inary(), outary())
    IF outary(ax) <> 0 THEN EXIT FOR  ' Mouse initialized successfully
    ' Small delay between retries
    FOR delay = 1 TO 1000: NEXT delay
  NEXT mouseRetry

  IF outary(ax) = 0 THEN
    LOCATE 25, 1: PRINT "Mouse not available - Press any key to continue anyway";
    WHILE INKEY$ = "": WEND  ' Wait for keypress
    ' Continue without mouse
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
  oldB = B: oldA = a

  a$ = INKEY$
  ' Get mouse state first
  CALL Mouse
  
  ' Handle mouse movement and buttons
  IF buttons <> 0 THEN  ' Mouse button pressed
    xb = oldB: ya = oldA
    IF d <> 0 AND buttons = 1 THEN LINE (xb, ya)-(B, a), d
  END IF
  ' Handle keyboard input if any
  IF a$ = "" THEN GOTO 10

  ' Process keyboard/mouse input
  IF a$ = "[" OR a$ = "]" THEN
    IF a$ = "[" THEN
      d = d - 1  ' Decrease color
    ELSE
      d = d + 1  ' Increase color
    END IF
    
    IF d < 0 THEN d = 0
    IF d > 255 THEN d = 255
    
    IF f <> 0 THEN f = d
    DRAW "c0"
  END IF

  ' Handle Ctrl+Z for undo
  IF a$ = CHR$(26) THEN  ' Ctrl+Z
    ' Erase cursor before undo
    IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
    
    ' Restore previous state
    CALL RestoreUndoState(c())
    
    ' Redraw cursor after undo
    IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
  END IF



  IF a$ = " " THEN 
    IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
    CALL SaveUndoState(c())
    PSET (B, a), d  'Draw point at current position (B,a) using current color f
    IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
  END IF

  'Add arrow key support (ASCII codes: up=0+72, down=0+80, left=0+75, right=0+77)
  
  IF ASC(a$) = 0 THEN  'Extended key (arrow keys)
    ' Always erase cursor before moving
    SELECT CASE ASC(RIGHT$(a$, 1))
      CASE 72: a$ = "8"  'Up arrow
      CASE 80: a$ = "2"  'Down arrow
      CASE 75: a$ = "4"  'Left arrow
      CASE 77: a$ = "6"  'Right arrow
    END SELECT
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

  IF oldB <> B OR oldA <> a THEN
    IF f = 0 AND e$ = "n" THEN
      PUT (oldB, oldA), a, XOR
      ' Always draw cursor after moving
      PUT (B, a), a, XOR
    END IF
  END IF

  IF a$ = "-" THEN DrawCanvasBorder
  If a$ = "'" THEN GOSUB ChangeActiveGame

  IF a$ = "i" THEN
    PUT (B, a), a, XOR
    d = POINT(B, a)
    PUT (B, a), a, XOR
  END IF

  ' Update currenet color display box
  ' Update the color preview box when current color changes
  IF fd <> d THEN
    ' Draw filled box showing current color in top-left corner
    LINE (310, 1)-(315, 6), d, BF
    
    ' Store current color to detect changes
    fd = d
    ' Draw single point at cursor position to set current position
    LINE (B, a)-(B, a), POINT(B, a)

    DRAW "c=" + VARPTR$(d)
  END IF

  IF a$ = ";" THEN
    PUT (B, a), a, XOR
    ' Get color at current cursor position
    colorAtCursor = POINT(B, a)
    ' Calculate palette position (row and column)
    IF colorAtCursor <= 120 THEN
      row = 1
      column = colorAtCursor
    ELSE
      row = 2
      column = colorAtCursor - 120
    END IF
    ' Display color information
    LOCATE 25, 1
    PRINT USING "Color ###/255 (Row #, Column ##)"; colorAtCursor; row; column; 
    PUT (B, a), a, XOR
  END IF

  IF a$ = "." THEN
    IF isBigCurMode = 0 THEN
      GOTO EnterLargeCursorMode
    ELSE
      isBigCurMode = 0
      f = d: DRAW "c=" + VARPTR$(f)
      a$ = "5"
      GOTO toggleDrawMode
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

  IF a$ = "\" THEN GOSUB FillWithColorPattern

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

  IF a$ = "t" THEN ft = POINT(B, a)
  
  IF a$ = "y" THEN fy = POINT(B, a)
  
  IF a$ = "=" THEN
    IF stampSet = 0 THEN
      LOCATE 25, 1
      PRINT "Capture stamp first with 'g' key";
    ELSE
      PUT (B, a), stampBuffer, PSET
    END IF
  END IF

  ' Fill effect: Replace colors in a 5x5 grid around cursor
  ' Replaces any pixels that match source color (ft) with target color (fy)
  IF fe$ = "y" THEN
    FOR gf = 0 TO 4
      FOR gi = 0 TO 4
        IF POINT(B + gf, a + gi) = ft THEN PSET (B + gf, a + gi), fy
      NEXT gi
    NEXT gf
  END IF

57
  ' Handle image restore functionality ("<" key)
  IF a$ = "<" THEN
    ' Prompt user to restore image
    LOCATE 25, 1: PRINT "Restore image?";
    
    ' Wait for Y/N response
    cc$ = INKEY$
    IF cc$ = "" THEN 57
    
    IF cc$ = "y" THEN
      ' Restore saved image from buffer
      PUT (1, 10), c, PSET
    ELSE
      ' Clear prompt if not restoring
      LOCATE 25, 1: PRINT "                    "
    END IF
  END IF

  IF a$ = "g" THEN GOSUB CaptureStampData
  IF a$ = "d" THEN GOSUB PasteStampWithOR
  IF a$ = "e" THEN GOSUB ScaleAndDrawRegion
  IF a$ = "%" THEN LOCATE 15, 1: INPUT gk: LOCATE 15, 1: PRINT "             ";
  IF a$ = "s" OR a$ = "S" THEN SavePicture q$
  IF a$ = "b" THEN LOCATE 15, 1: INPUT c: COLOR c
  
  IF isBigCurMode = 1 THEN 70
  
  IF a$ = "5" THEN GOSUB ToggleDrawMode ' Handle toggling drawing mode with '5' key
    

70
  ON ERROR GOTO 200
  IF f = 0 AND e$ = "n" THEN PUT (B, a), a, XOR
  IF f = 0 AND e$ = "y" AND isBigCurMode = 0 THEN DRAW "c43u2r2d2l2c0u2r2d2l1u1bg1"
  IF a$ = "0" THEN s = s + 2: IF s = 5 OR s = 8 THEN s = 1
  IF a$ = "$" THEN GOSUB CountUniqueColors
  IF a$ = "z" THEN mz = B: mx = a
  IF a$ = "{" THEN GOSUB DrawScaledMirrorImage
  IF a$ = "x" THEN nz = B: nx = a
  IF a$ = "l" THEN IF f <> 0 THEN LINE (mz, mx)-(nz, nx), f ELSE LINE (mz, mx)-(nz, nx), d
  IF a$ = "u" THEN DRAW "c1": f = 1
  IF a$ = "o" THEN GOSUB 101
  IF a$ = "a" THEN GOSUB 185: GET (B, a)-(B + 18, a + 18), stampBuffer
  IF a$ = CHR$(13) THEN 115
  IF a$ = "r" OR a$ = "R" THEN GOSUB LoadPictureMenu
  IF a$ = "(" THEN GOSUB IncrementColors
  IF a$ = ")" THEN GOSUB 242
  IF a$ = "k" THEN GOSUB 800
  IF a$ = "+" THEN IF s <> 6 THEN s = 6 ELSE s = 1
  IF a$ = CHR$(6) THEN GOTO FillWithColor  ' Ctrl+F (ASCII 6)
96
  IF a$ = "q" THEN
    LOCATE 25, 1
    PRINT "Really quit?";
    ad$ = INKEY$
    IF ad$ = "" THEN 96 ELSE IF ad$ = "y" THEN CALL CleanupUndo: SYSTEM ELSE LOCATE 25, 1: PRINT "                 ";
  END IF
  IF f = 0 AND e$ = "n" AND isBigCurMode = 0 THEN PUT (B, a), a, XOR
  IF a$ = "/" AND isBigCurMode = 0 THEN IF e$ = "y" THEN e$ = "n" ELSE e$ = "y"
100 GOTO 10

CountUniqueColors:
  ' This subroutine counts the number of unique colors used in the drawing area
  ' Initialize array to track which colors are used
  FOR I = 1 TO 256
    col(I) = 0
  NEXT I

  ' Scan the drawing area (301x189 pixels) and mark each color found
  FOR I = 1 TO 301
    FOR d = 11 TO 199
      col(POINT(I, d)) = 1  ' Mark color as used
    NEXT d
  NEXT I

  ' Count total number of unique colors used
  tc = 0
  FOR I = 0 TO 256
    IF col(I) = 1 THEN tc = tc + 1
  NEXT I

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

FillWithColor:
  CALL SaveUndoState(c())
  GET (1, 10)-(319, 199), c
  LINE (0, 9)-(321, 9), d
  LINE (B, a)-(B, a), 0
  PAINT (B, a), d, d
  LINE (0, 9)-(321, 9), 0, BF
  DrawCanvasBorder
  ' draw cursor and refresh current position
  PUT (B, a), a, XOR
  DRAW "c=" + VARPTR$(d)
GOTO 100

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

ToggleDrawMode:
  IF f <> 0 THEN
    ' Turn off drawing mode
    DRAW "c0"
    IF isBigCurMode = 0 THEN
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
RETURN

ChangeActiveGame:
  ' change active game
  activeGame = activeGame + 1
  IF activeGame > gameCount THEN activeGame = 1
  activePalette = 1
  LoadPalette
  DrawCanvasBorder
RETURN

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

DrawScaledMirrorImage:
  mel = 1.8: mx = 100: nx = 1: mz = 1: nz = 320
  FOR axc = 100 TO 1 STEP -1
    FOR ixc = 1 TO 320 STEP 1
      LINE (1 + (ixc - mz) * mel, 200 + (axc - mx) * mel)-(1 + (ixc - mz) * mel - (mel - .9), 200 + (axc - mx) * mel - (mel - .9)), POINT(ixc, axc), BF
    NEXT ixc
  NEXT axc
RETURN

IncrementColors:
  FOR I = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, I) <> 0 THEN PSET (d, I), POINT(d, I) + 1
    NEXT d
  NEXT I
RETURN

242
  FOR I = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, I) <> 0 THEN PSET (d, I), POINT(d, I) - 1
    NEXT d
  NEXT I
RETURN

243
  FOR I = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, I) <> 0 THEN PSET (d, I), 15
    NEXT d
  NEXT I
RETURN

185
  LOCATE 15, 1: PRINT "Which box?": INPUT I
  x(I) = B: y(I) = a
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

LoadPictureMenu:
  ' swich to a high resolution screen
  SCREEN 12
  CLS
  gamePath$ = RTRIM$(games(activeGame).path) + "\"
  picExt$ = NormalizeExtension$(games(activeGame).files.picExt)

  FILES gamePath$ + "*" + picExt$        ' Shows available .pic files
  CLOSE : INPUT q$     ' Get filename from user
  SCREEN 13
  IF a$ = "r" THEN
    GOTO LoadPictureFullscreen
  ELSE
    GOTO LoadPicturePositioned
  END IF
  CLS
  'DEF SEG = &HB800
  'BLOAD q$ + ".pic", 0: GOTO 10
RETURN

EnterLargeCursorMode:
  isBigCurMode = 1 ' Set isBigCurMode flag to 1 to indicate we're in "large cursor" mode
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

FillWithColorPattern:
  GET (2, 2)-(200, 100), c
  tile$ = ""
  FOR I = ft TO fy
    tile$ = tile$ + CHR$(I)
  NEXT I

  LINE (0, 10)-(321, 10), f, B
  PAINT (B, a), tile$, f
  tile$ = ""
RETURN

FOR I = 1 TO 120
LINE (I + 30, 1)-(I + 30, 2), I
NEXT I
FOR I = 121 TO 255
LINE (I - 95, 3)-(I - 95, 4), I
NEXT I
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
    IF a$ = "d" THEN GOSUB 789: LOCATE 1, 1: ip = 1: INPUT gp$: FOR I = 1 TO 30: GOSUB 790: NEXT I
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
624 sm(gs) = I: gs = gs + 1
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
FOR I = 1 TO 5
INPUT #1, qa(I), qb(I), x(I), y(I)
NEXT I
INPUT #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
FOR I = 1 TO 50
INPUT #1, vh$(I)
NEXT I
FOR I = 1 TO 30
 INPUT #1, mess$(I), ky$(I), bs(I), CS(I), st(I), df$(I)
 NEXT I
RETURN
789 LOCATE 1, 1: PRINT "                                                                "
LOCATE 2, 1: PRINT "                                                                "
RETURN
790 IF LEFT$(df$(I), 1) <> gp$ THEN RETURN
ip = ip + 1
    LOCATE ip, 1: PRINT mess$(I)
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
FOR I = 1 TO 5
WRITE #1, qa(I), qb(I), x(I), y(I)
NEXT I
WRITE #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
FOR I = 1 TO 50
WRITE #1, vh$(I)
NEXT I
 FOR I = 1 TO 30
 WRITE #1, mess$(I), ky$(I), bs(I), CS(I), st(I), df$(I)
 NEXT I
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
    gamePath$ = RTRIM$(games(activeGame).path) + "\"
    picExt$ = NormalizeExtension$(games(activeGame).files.picExt)
    '------- LOADING OF THE PICTURE -------
    GET (2, 10)-(310, 199), c
    DEF SEG = VARSEG(c(1))
    BLOAD gamePath$ + q$ + picExt$, VARPTR(c(1))    ' Actually loads the file
    
    DEF SEG = 0
    c = 0
    PUT (2, 10), c, PSET         ' Displays the loaded image
    'PUT (62 + 40 * 0, 173), c(1 + 510 * 2), PSET
    ' Only call DisplayImageArray for non-type 3 palettes
    IF VAL(palettes$(activePalette, 1)) = PAL_TYPE_3 THEN
      DisplayImageArray c(), 2, 10
    END IF
    GOTO 883
RETURN

LoadPicturePositioned:
    PRINT "LoadPicturePositioned"
    CLS
    gamePath$ = RTRIM$(games(activeGame).path) + "\"
    picExt$ = NormalizeExtension$(games(activeGame).files.picExt)
    '------- LOADING OF THE PICTURE -------
    GET (2, 10)-(310, 199), c
    DEF SEG = VARSEG(c(1))
    BLOAD gamePath$ + q$ + picExt$, VARPTR(c(1))
    DEF SEG = 0
    c = 0
    PUT (c(1), c(2)), c(3), PSET 'places picture in certain position
    '-------- END OF LOAD -------------
883
  ON ERROR GOTO 900
    'IF fca <> "c" THEN GOSUB 709
884
  LoadPalette
  COLOR FindNeutralGray%()
  ON ERROR GOTO 200
  DrawCanvasBorder
RETURN

900 RESUME 884

'----------------------All about guy------------------------
2
  x = 165: y = 145: gg = 178: f = 167: j = -120: fh = 3: bob = 0
  CS = 180: CS = 33: cp = 32: cp = 204: ch = 175: ch = 24: cf = 120: cf = 150
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  vg = 0
310
  GET (x - 22, y - 36)-(x + 11, gg + 10), c
  bob = bob + fh: IF bob = 6 THEN fh = -3 ELSE IF bob < -5 THEN fh = 3
  FOR I = 0 TO 5
    LINE (x + I, y)-(f + I - 1, gg + bob), cp - I * 1.5
    LINE (x - I, y)-(f - I + 1, gg + bob), cp - I * 1.5
  NEXT I
  FOR I = 0 TO 4
    LINE (x + I - 9, y)-(f + I - 1 - 9, gg - bob), cp - I * 1.5
    LINE (x - I - 9, y)-(f - I + 1 - 9, gg - bob), cp - I * 1.5
  NEXT I
  IF vg = 0 THEN GOSUB 420
GOTO 421

420
  x = x - 5
  FOR I = 0 TO 5
    LINE (x + I - 2, y - 2)-(x + I, y - 20 + I / 2), CS - I
    LINE (x - I + 2, y - 2)-(x - I, y - 20 + I / 2), CS - I
  NEXT I
  x = x + 5
  LINE (x - 13, y)-(x + 4, y), 4
  LINE (x - 13, y - 1)-(x + 4, y - 1), 12
RETURN

421
  FOR I = 0 TO 3
    LINE (x + 4 + I, y - 17 + I)-(x + 7 + I, y + 5 - bob / 1.5), CS - 2 - I
    LINE (x + 4 - I, y - 17 + I)-(x + 9 - I, y + 5 - bob / 1.5), CS - 2 - I
    LINE (x - 15 + I, y - 17 + I)-(x - 20 + I, y + 5 + bob / 1.5), CS - I
    LINE (x - 15 - I, y - 17 + I)-(x - 18 - I, y + 5 + bob / 1.5), CS - I
  NEXT I
  FOR I = 0 TO 2
    LINE (x + 9, y + 6 + I - bob / 1.5)-(x + 5 + I, y + 6 + I - bob / 1.5), cf
    LINE (x - 17 - I, y + 6 + I + bob / 1.5)-(x - 20, y + 6 + I + bob / 1.5), cf
    LINE (f + 4 + I, gg + 1 + I + bob)-(f - 1, gg + 1 + I + bob), cf - I * 2
    LINE (f - 12 - I, gg + 1 + I - bob)-(f - 8, gg + 1 + I - bob), cf - I * 2
  NEXT I
  IF vg = 1 THEN GOSUB 420
  IF vg = 0 THEN 415
  CIRCLE (x - 5, y - 25), 6, ch, , , 1.5
  PAINT (x - 5, y - 25), ch, ch
  FOR I = 0 TO 3
    CIRCLE (x - 5, y - 25 - I), 6, ch + 1, .5 - (I / 5), 2.5 + (I / 5), 1.5
  NEXT I
GOTO 405

415
  CIRCLE (x - 5, y - 25), 6, cf, , , 1.5
  PAINT (x - 5, y - 25), cf, cf
  FOR I = 0 TO 3
    CIRCLE (x - 5, y - 25 - I), 6, ch, .5 - (I / 5), 2.5 + (I / 5), 1.5
  NEXT I
  PSET (x - 8, y - 26), 0: PSET (x - 2, y - 26), 0
GOTO 405

405
  FOR I = 1 TO 6400: NEXT I: a$ = "8"
  IF vg = 0 THEN j = j + 3 ELSE j = j - 3
  PUT (x - 22, y - 36), c, PSET
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  IF j > 0 THEN vg = 1
  IF j < -120 THEN WINDOW SCREEN (1, 1)-(320, 200): RETURN
GOTO 310

'-------------------Sideways guy----------------------
14
  x = 165: y = 145: gg = 178: f = 167: j = 0: fh = 4: dg = 0: bob = 0
  CS = 180: CS = 33: cp = 32: cp = 204: ch = 175: ch = 24: cf = 120: cf = 150
  IF dg = 1 THEN lk = 1: pk = 0 ELSE pk = 1: lk = 0
  WINDOW SCREEN (1 + j * 3, 1 + j * 2)-(320 - j * 3, 200 - j * 2)
  vg = 0
510
  GET (x - 30, y - 36)-(x + 18, gg + 10), c
  bob = bob + fh: IF bob > 7 THEN fh = -4 ELSE IF bob < -5 THEN fh = 4
  FOR I = 0 TO 3
    LINE (x - 13 + I, y - 17 + I)-(x - 18 + I + bob, y + 5), CS - I
    LINE (x - 13 - I, y - 17 + I)-(x - 16 - I + bob, y + 5), CS - I
  NEXT I
  FOR I = 0 TO 2
    LINE (x - 15 - I + bob, y + 6 + I)-(x - 18 + bob, y + 6 + I), cf
    LINE (f - 12 - I * pk - bob, gg + 1 + I)-(f - 8 - bob + I * lk, gg + 1 + I), cf - I * 2
  NEXT I
  FOR I = 0 TO 4
    LINE (x + I - 9, y)-(f + I - 1 - 9 - bob, gg), cp - I * 1.5
    LINE (x - I - 9, y)-(f - I + 1 - 9 - bob, gg), cp - I * 1.5
  NEXT I
  FOR I = 0 TO 5
    LINE (x - 8 + I, y)-(f - 8 + I - 1 + bob, gg + 2), cp - I * 1.5
    LINE (x - 8 - I, y)-(f - 8 - I + 1 + bob, gg + 2), cp - I * 1.5
  NEXT I
  IF vg = 0 THEN GOSUB 520
GOTO 521

520
  x = x - 5
  FOR I = 0 TO 5
    LINE (x + I - 6, y - 2)-(x + I - 4, y - 20 + I), CS - I
    LINE (x - I - 2, y - 2)-(x - I - 4, y - 20 + I), CS - I
  NEXT I
  x = x + 5
  LINE (x - 13, y)-(x - 4, y), 4
  LINE (x - 13, y - 1)-(x - 4, y - 1), 12
RETURN

521
  FOR I = 0 TO 3
    LINE (x - 6 + I, y - 17 + I)-(x - 3 + I - bob, y + 5), CS - 2 - I
    LINE (x - 6 - I, y - 17 + I)-(x - 4 - I - bob, y + 5), CS - 2 - I
  NEXT I
  FOR I = 0 TO 2
    LINE (x - 3 - bob, y + 6 + I)-(x - 6 + I - bob, y + 6 + I), cf
    LINE (f - 11 - I * pk + bob, gg + 3 + I)-(f - 6 + bob + I * lk, gg + 3 + I), cf - I * 2
  NEXT I
  IF vg = 1 THEN GOSUB 520
  IF dg = 0 THEN 515
  CIRCLE (x - 8, y - 25), 6, ch, , , 1.5
  PAINT (x - 8, y - 25), ch, ch
  FOR I = 0 TO 2
    CIRCLE (x - 9 + I, y - 25), 6, cf, 5, 1, 1.5
  NEXT I
  PSET (x - 3, y - 26), 0
GOTO 505

515 CIRCLE (x - 9, y - 25), 6, ch, , , 1.5
  PAINT (x - 9, y - 25), ch, ch
  FOR I = 0 TO 3
    CIRCLE (x - 9 + I, y - 25), 6, cf, 2.5, 4.5, 1.5
  NEXT I
  PSET (x - 12, y - 26), 0
GOTO 505

505
  FOR I = 1 TO 6200: NEXT I: a$ = "8"
  PUT (x - 30, y - 36), c, PSET
  IF dg = 1 THEN x = x + 4: f = f + 4 ELSE x = x - 4: f = f - 4
  IF vg = 0 THEN j = j + 0 ELSE j = j - 0
  WINDOW SCREEN (320 - j * 3, 1 + j * 2)-(j * 3, 200 - j * 2)
  IF j > 0 THEN vg = 1
  IF j < -120 OR x < 34 THEN WINDOW SCREEN (1, 1)-(320, 200): RETURN
GOTO 510

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

SUB DrawCanvasBorder ()
  SHARED pl() AS LONG
  
  ' Get the neutral gray color
  DIM grayColor AS INTEGER
  grayColor = FindNeutralGray%()
  
  ' Canvas coordinates
  left = 2
  top = 10
  right = 310
  bottom = 198
  
  markLength = 3  ' Length of each registration mark
  
  ' Calculate midpoints
  midX = (left + right) \ 2
  midY = (top + bottom) \ 2
  
  ' Clear top line
  LINE (0, top - 1)-(right + 1, top - 1), 0, BF
  
  ' Clear sides
  LINE (0, top)-(left - 1, bottom + 1), 0 , BF ' Left side
  LINE (right + 1, top)-(320, bottom + 1), 0, BF  ' Right side
  
  ' Clear bottom
  LINE (0, bottom + 1)-(320, bottom + 1), 0, BF

  
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

SUB Mouse ()
  SHARED lastB, lastA   ' Previous mouse X,Y coordinates
  SHARED buttons AS INTEGER  ' Current mouse button state
  SHARED blt AS INTEGER     ' Button state for debouncing (1=ready, 0=pressed)
  SHARED inary() AS INTEGER, outary() AS INTEGER
  SHARED B, a, f, e$, a() ' Add cursor array and drawing flags
  STATIC cursorVisible AS INTEGER  ' Track cursor visibility state
  STATIC lastButtons AS INTEGER    ' Track previous button state
  
  ' Get current mouse position
  inary(ax) = 3
  CALL INT86OLD(BOUSE, inary(), outary())

  ' Button handling
  newButtons = outary(bx)

  ' Create undo point when mouse button is first pressed
  IF newButtons = 1 AND lastButtons = 0 THEN
    PUT (B, a), a, XOR
    ' Save current screen state before drawing
    GET (2, 10)-(310, 198), c
    CALL SaveUndoState(c())
  END IF
  lastButtons = newButtons  ' Remember button state for next time

  ' Calculate new position
  newB = outary(cx) \ 2
  newA = outary(dx)
  
  ' Handle mouse movement and buttons
  IF buttons <> 0 THEN  ' Mouse button pressed
    xb = oldB: ya = oldA
    IF d <> 0 AND buttons = 1 THEN LINE (xb, ya)-(B, a), d
  END IF

  ' Only update position if mouse has moved
  IF newB <> lastB OR newA <> lastA THEN

    ' Turn off draw mode in case it's on
    f = 0

    ' Always erase cursor at OLD position if it was visible
    IF buttons <> 1 AND f = 0 AND e$ = "n" AND cursorVisible THEN
      PUT (B, a), a, XOR
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
    IF buttons <> 1 AND f = 0 AND e$ = "n" THEN
      PUT (B, a), a, XOR
      cursorVisible = -1
    END IF
    
    ' Save position for next time
    lastB = B
    lastA = a
  END IF

  IF buttons = 1 AND newButtons <> 1 THEN
    PUT (B, a), a, XOR
  END IF

  buttons = newButtons
  
END SUB

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
    FOR I = 1 TO 5
        WRITE #1, qa(I), qb(I), x(I), y(I)
    NEXT I
    WRITE #1, gen$, da$(1), da$(2), da$(3), da$(4), da$(5), da$(6)
    FOR I = 1 TO 50
        WRITE #1, vh$(I)
    NEXT I
    FOR I = 1 TO 30
        WRITE #1, mess$(I), ky$(I), bs(I), CS(I), st(I), df$(I)
    NEXT I
    CLOSE
END SUB
