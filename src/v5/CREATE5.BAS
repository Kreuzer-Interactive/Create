'$INCLUDE: 'modules\CONFIG.BI'
'$INCLUDE: 'modules\PAL.BI'
'$INCLUDE: 'modules\UNDO.BI'
'$INCLUDE: 'modules\CREATE.BI'

SCREEN 13, 0
REDIM screenBuffer(1 TO bufferSize) AS INTEGER  ' 64,600 bytes (32,300 integers × 2 bytes each)
REDIM stampBuffer(1 TO bufferSize) AS INTEGER   ' 64,600 bytes (32,300 integers × 2 bytes each)
0 PRINT "Starting...":' Must include this to load
  
  SCREEN 13
  ' End of including
  eraserMode$ = "n"
  stampMode$ = "n"       ' Was fr$
  stampSet = 0    
  activeGame = 1
  activePalette = 1 
  gameCount = 0         
  activeGame = 1               
  CLS
1 
  ' Initialize cursor position
  cursorX = 160    ' Starting X position (was B)
  cursorY = 100    ' Starting Y position (was a)
  moveSize = 1     ' Starting movement increment (was s)
  isDrawing = 0    ' Drawing mode flag (was f)
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
  GET (1, 1)-(1, 1), cursorSprite   ' Was a()

5
  CLS
  cursorY = 100                      ' Was a
  cursorX = 160                      ' Was B
  gk = 1: fca = "z"
  q$ = "Type in name"
  isDrawing = 0                      ' Was f
  eraserMode$ = "n"                  ' Was e$
  moveSize = 1: c = 0                ' Was s
  COLOR 42
  LoadPalette
  DrawCanvasBorder

10
  oldCursorX = cursorX: oldCursorY = cursorY   ' Was oldB/oldA

  key$ = INKEY$
  ' Get mouse state first
  CALL Mouse
  

  IF key$ = "m" THEN CALL DisplayMemoryUsage

  ' Handle mouse movement and buttons
  IF buttons <> 0 THEN  ' Mouse button pressed
    xb = oldCursorX: ya = oldCursorY ' TODO: Check if this is correct
    IF activeColor <> 0 AND buttons = 1 THEN LINE (xb, ya)-(cursorX, cursorY), activeColor
  END IF
  ' Handle keyboard input if any
  IF key$ = "" THEN GOTO 10

  ' Process keyboard/mouse input
  IF key$ = "[" OR key$ = "]" THEN
    IF key$ = "[" THEN
      activeColor = activeColor - 1  ' Decrease color
    ELSE
      activeColor = activeColor + 1  ' Increase color
    END IF
    
    IF activeColor < 0 THEN activeColor = 0
    IF activeColor > 255 THEN activeColor = 255
    
    IF isDrawing <> 0 THEN isDrawing = activeColor
    DRAW "c0"
  END IF

  ' Handle Ctrl+Z for undo
  IF key$ = CHR$(26) THEN  ' Ctrl+Z
    ' Erase cursor before undo
    IF isDrawing = 0 AND eraserMode$ = "n" THEN PUT (cursorX, cursorY), cursorSprite, XOR
    
    ' Restore previous state
    CALL RestoreUndoState(screenBuffer())
    
    ' Redraw cursor after undo
    IF isDrawing = 0 AND eraserMode$ = "n" THEN PUT (cursorX, cursorY), cursorSprite, XOR
  END IF

  IF key$ = " " THEN 
    IF isDrawing = 0 AND eraserMode$ = "n" THEN PUT (cursorX, cursorY), cursorSprite, XOR
    CALL SaveUndoState(screenBuffer())
    PSET (cursorX, cursorY), activeColor  'Draw point at current position using current color
    IF isDrawing = 0 AND eraserMode$ = "n" THEN PUT (cursorX, cursorY), cursorSprite, XOR
  END IF

  'Add arrow key support (ASCII codes: up=0+72, down=0+80, left=0+75, right=0+77)
  
  IF ASC(key$) = 0 THEN
    SELECT CASE ASC(RIGHT$(key$, 1))
      CASE 72: key$ = "8"  ' Up arrow
      CASE 80: key$ = "2"  ' Down arrow
      CASE 75: key$ = "4"  ' Left arrow
      CASE 77: key$ = "6"  ' Right arrow
    END SELECT
  END IF

  ' Process numpad movement
  IF key$ = "8" THEN cursorY = cursorY - moveSize  ' Up
  IF key$ = "2" THEN cursorY = cursorY + moveSize  ' Down
  IF key$ = "4" THEN cursorX = cursorX - moveSize  ' Left
  IF key$ = "6" THEN cursorX = cursorX + moveSize  ' Right

  ' Draw lines if in drawing mode
  IF (isDrawing <> 0 OR eraserMode$ = "y") AND (key$ = "8" OR key$ = "2" OR key$ = "4" OR key$ = "6") THEN
    SELECT CASE key$
      CASE "8": DRAW "u=" + VARPTR$(moveSize)  ' Up
      CASE "2": DRAW "d=" + VARPTR$(moveSize)  ' Down
      CASE "4": DRAW "l=" + VARPTR$(moveSize)  ' Left
      CASE "6": DRAW "r=" + VARPTR$(moveSize)  ' Right
    END SELECT
  END IF

  IF oldCursorX <> cursorX OR oldCursorY <> cursorY THEN
    IF isDrawing = 0 AND eraserMode$ = "n" THEN
      PUT (oldCursorX, oldCursorY), cursorSprite, XOR
      ' Always draw cursor after moving
      PUT (cursorX, cursorY), cursorSprite, XOR
    END IF
  END IF

  IF key$ = "-" THEN CALL DrawCanvasBorder
  If key$ = "'" THEN GOSUB ChangeActiveGame

  IF key$ = "i" THEN GOSUB GetColorAtCursor

  ' Update currenet color display box
  ' Update the color preview box when current color changes
  IF previousColor <> activeColor THEN
    ' Draw filled box showing current color in top-left corner
    LINE (310, 1)-(315, 6), activeColor, BF
    
    ' Store current color to detect changes
    previousColor = activeColor
    ' Draw single point at cursor position to set current position
    LINE (cursorX, cursorY)-(cursorX, cursorY), POINT(cursorX, cursorY)

    DRAW "c=" + VARPTR$(activeColor)
  END IF

  IF key$ = ";" THEN GOSUB GetColorAtCursorPalletInfo

  IF key$ = "." THEN
    IF isLargeCursorMode = 0 THEN
      GOTO EnterLargeCursorMode
    ELSE
      isLargeCursorMode = 0
      isDrawing = activeColor: DRAW "c=" + VARPTR$(isDrawing)
      key$ = "5"
      GOTO toggleDrawMode
    END IF
  END IF

  IF key$ = "c" THEN
    IF c = 0 THEN
      c = 1
      GET (2, 10)-(310, 199), screenBuffer
      LINE (2, 10)-(310, 199), 0, BF
    ELSE c = 0
      PUT (2, 10), screenBuffer, PSET
    END IF
  END IF

  IF key$ = "C" THEN
    GOTO click
  END IF

  IF key$ = "1" THEN
    IF isDrawing <> 0 OR eraserMode$ = "y" THEN
      DRAW "g=" + VARPTR$(moveSize)
      cursorY = cursorY + moveSize
      cursorX = cursorX - moveSize
    ELSE
      cursorY = cursorY + moveSize
      cursorX = cursorX - moveSize
    END IF
  END IF

  IF key$ = "n" THEN
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

  IF key$ = "\" THEN GOSUB FillWithColorPattern

  IF key$ = "9" THEN
    IF isDrawing <> 0 OR eraserMode$ = "y" THEN
      DRAW "e=" + VARPTR$(moveSize)
      cursorY = cursorY - moveSize
      cursorX = cursorX + moveSize
    ELSE
      cursorY = cursorY - moveSize
      cursorX = cursorX + moveSize
    END IF
  END IF

  IF key$ = "`" THEN GOSUB TextInputMode
  
  IF key$ = "p" THEN
    activePalette = (activePalette + 1) MOD 4  ' Cycles through palettes 0-3
    LoadPalette
    DrawCanvasBorder
  END IF

  IF key$ = CHR$(KEY_CTRL_E) THEN IF eraserMode$ = "y" THEN eraserMode$ = "n" ELSE eraserMode$ = "y"
  
  IF key$ = "7" THEN 
    IF isDrawing <> 0 OR eraserMode$ = "y" THEN 
      DRAW "h=" + VARPTR$(moveSize)
      cursorY = cursorY - moveSize
      cursorX = cursorX - moveSize
    ELSE 
      cursorY = cursorY - moveSize
      cursorX = cursorX - moveSize
    END IF
  END IF
  IF key$ = "3" THEN 
    IF isDrawing <> 0 OR eraserMode$ = "y" THEN 
      DRAW "f=" + VARPTR$(moveSize)
      cursorY = cursorY + moveSize
      cursorX = cursorX + moveSize
    ELSE 
      cursorY = cursorY + moveSize
      cursorX = cursorX + moveSize
    END IF
  END IF

  IF key$ = "t" THEN fillSourceColor = POINT(cursorX, cursorY)  ' Was ft
  
  IF key$ = "y" THEN fillTargetColor = POINT(cursorX, cursorY)  ' Was fy
  
  IF key$ = "=" THEN
    IF stampSet = 0 THEN
      LOCATE 25, 1
      PRINT "Capture stamp first with 'g' key";
    ELSE
      PUT (cursorX, cursorY), stampBuffer, PSET
    END IF
  END IF

  ' Fill effect: Replace colors in a 5x5 grid around cursor
  ' Replaces any pixels that match source color (fillSourceColor) with target color (fillTargetColor)
  IF eraserMode$ = "y" THEN
    FOR gf = 0 TO 4
      FOR gi = 0 TO 4
        IF POINT(cursorX + gf, cursorY + gi) = fillSourceColor THEN 
          PSET (cursorX + gf, cursorY + gi), fillTargetColor
        END IF
      NEXT gi
    NEXT gf
  END IF

  IF key$ = "g" THEN GOSUB CaptureStampData
  IF key$ = "d" THEN GOSUB PasteStampWithOR
  IF key$ = "e" THEN GOSUB ScaleAndDrawRegion
  IF key$ = "%" THEN LOCATE 15, 1: INPUT gk: LOCATE 15, 1: PRINT "             ";
  IF key$ = "s" OR key$ = "S" THEN SavePicture q$
  IF key$ = "b" THEN LOCATE 15, 1: INPUT c: COLOR c
  
  IF key$ = "5" THEN 
    GOSUB ToggleDrawMode ' Handle toggling drawing mode with '5' key
  ELSEIF NOT isLargeCursorMode THEN
    ' Only process remaining key handlers if not in large cursor mode
    IF key$ = "0" THEN moveSize = moveSize + 2: IF moveSize = 5 OR moveSize = 8 THEN moveSize = 1
    IF key$ = "$" THEN GOSUB CountUniqueColors
    IF key$ = "z" THEN mz = cursorX: mx = cursorY
    IF key$ = "{" THEN GOSUB DrawScaledMirrorImage
    IF key$ = "x" THEN nz = cursorX: nx = cursorY
    IF key$ = "l" THEN IF isDrawing <> 0 THEN LINE (mz, mx)-(nz, nx), isDrawing ELSE LINE (mz, mx)-(nz, nx), activeColor
    IF key$ = "u" THEN DRAW "c1": isDrawing = 1
    IF key$ = "o" THEN GOSUB 101
    IF key$ = "a" THEN GOSUB 185: GET (cursorX, cursorY)-(cursorX + 18, cursorY + 18), stampBuffer
    IF key$ = CHR$(KEY_ENTER) THEN 115
    IF key$ = "r" OR key$ = "R" THEN GOSUB LoadPictureMenu
    IF key$ = "(" THEN GOSUB IncrementColors
    IF key$ = ")" THEN GOSUB DecrementColors
    IF key$ = "~" THEN GOSUB ClearArea ' lets see what this does
    IF key$ = "k" THEN GOSUB 800
    IF key$ = "+" THEN IF moveSize <> 6 THEN moveSize = 6 ELSE moveSize = 1
    IF key$ = CHR$(KEY_CTRL_F) THEN GOTO FillWithColor

    IF key$ = "q" THEN
      LOCATE 25, 1
      PRINT "Really quit?";
      DO
        ad$ = INKEY$
      LOOP UNTIL ad$ <> ""
      
      IF ad$ = "y" THEN 
        CALL CleanupUndo
        SYSTEM 
      ELSE 
        LOCATE 25, 1
        PRINT "                 ";
      END IF
    END IF
    IF isDrawing = 0 AND eraserMode$ = "n" AND isLargeCursorMode = 0 THEN PUT (cursorX, cursorY), cursorSprite, XOR
    IF key$ = "/" AND isLargeCursorMode = 0 THEN IF eraserMode$ = "y" THEN eraserMode$ = "n" ELSE eraserMode$ = "y"
  END IF
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
  FOR I = 0 TO 256
    IF col(I) = 1 THEN tc = tc + 1
  NEXT I

  ' Display count at line 17
  LOCATE 25, 1: PRINT tc;
RETURN

GetColorAtCursor:
  PUT (cursorX, cursorY), cursorSprite, XOR
  activeColor = POINT(cursorX, cursorY)
  PUT (cursorX, cursorY), cursorSprite, XOR
RETURN

GetColorAtCursorPalletInfo:
  PUT (cursorX, cursorY), cursorSprite, XOR
  ' Get color at current cursor position
  colorAtCursor = POINT(cursorX, cursorY)
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
  PUT (cursorX, cursorY), cursorSprite, XOR
RETURN 

101 RETURN: LOCATE 1, 1: PRINT "What color   "
INPUT cl

204
  DRAW "c=" + VARPTR$(cl): isDrawing = cl
  LOCATE 15, 1: PRINT "             ": LOCATE 16, 1: PRINT "      "
RETURN

102 LOCATE 15, 1: INPUT isDrawing
105 IF isDrawing > 250 THEN 102
108 DRAW "c=" + VARPTR$(isDrawing)
110 GOTO 10
115 LOCATE 15, 1: INPUT q
125 CIRCLE (cursorX, cursorY), q, isDrawing
130 GOTO 100

FillWithColor:
  CALL SaveUndoState(screenBuffer())
  GET (1, 10)-(319, 199), screenBuffer
  LINE (0, 9)-(321, 9), activeColor
  LINE (cursorX, cursorY)-(cursorX, cursorY), 0
  PAINT (cursorX, cursorY), activeColor, activeColor
  LINE (0, 9)-(321, 9), 0, BF
  DrawCanvasBorder
  ' draw cursor and refresh current position
  PUT (cursorX, cursorY), cursorSprite, XOR
  DRAW "c=" + VARPTR$(activeColor)
GOTO 100

150 LOCATE 1, 1: PRINT q$; : INPUT f$
IF f$ = "a" OR f$ = "A" THEN RETURN
IF f$ <> "" THEN q$ = f$
IF key$ = "s" THEN 
    GOSUB 778 
    RETURN
ELSE 
    GOSUB 777
    RETURN
END IF
    ON ERROR GOTO 700
    OPEN q$ + ".pac" FOR INPUT AS #1
    INPUT #1, xzc, zxn
153 LOCATE 15, 1: PRINT "Save over previous picture?": key$ = INKEY$: IF key$ = "" THEN 153
    IF key$ = "y" THEN 151 ELSE ON ERROR GOTO 200: GOTO 10
151 CLOSE : LOCATE 15, 1
152 PRINT "                                "
155 DEF SEG = &HB800
160 BSAVE q$ + ".pic", 0, &H4000
165 OPEN q$ + ".pac" FOR OUTPUT AS #1
175 CLOSE
180 END

ToggleDrawMode:
  IF isDrawing <> 0 THEN
    ' Turn off drawing mode
    DRAW "c0"
    IF isLargeCursorMode = 0 THEN
      activeColor = isDrawing  ' Save current color
      isDrawing = 0  ' Turn off drawing
      key$ = ""
    ELSE
      isDrawing = 0  ' Just turn off drawing
      key$ = ""
    END IF
  ELSE
    ' Turn on drawing mode
    DRAW "c=" + VARPTR$(activeColor)  ' Restore saved color
    isDrawing = activeColor           ' Enable drawing
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
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), POINT(d, i) + 1
    NEXT d
  NEXT i
RETURN

DecrementColors:
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), POINT(d, i) - 1
    NEXT d
  NEXT i
RETURN

ClearArea:
  FOR i = mx TO nx STEP 1
    FOR d = mz TO nz STEP 1
      IF POINT(d, i) <> 0 THEN PSET (d, i), 15
    NEXT d
  NEXT i
RETURN

185
  LOCATE 15, 1: PRINT "Which box?": INPUT i
  x(i) = cursorX: y(i) = cursorY
RETURN

200  ' Main error handler
  CALL LogError
  ' Handle boundary errors
  IF cursorX > 319 THEN cursorX = 319
  IF cursorX < 1 THEN cursorX = 1
  IF cursorY < 1 THEN cursorY = 1
  IF cursorY > 199 THEN cursorY = 199
  SOUND 400, 1: SOUND 200, .5

  ' Only use RESUME if we're handling an error
  IF ERR > 0 THEN 
    RESUME 10
  END IF
  RETURN

TextInputMode:
  ' This subroutine implements a text input mode where the user can:
  ' - Move a cursor around the screen using arrow keys (8,4,6,2)
  ' - Type characters at the cursor position
  ' - Exit with the ` key
  '
  ' The cursor position is converted from pixel coordinates (cursorX,cursorY)
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
  pa = cursorY \ 8  ' Y position in characters
  pb = cursorX \ 8  ' X position in characters
TextInputLoop:
  DO
    ' Show cursor and wait for keypress
    LOCATE pa, pb: PRINT "."
    DO
      key$ = INKEY$
    LOOP WHILE key$ = ""
    
    ' Clear cursor
    LOCATE pa, pb: PRINT " "
    
    ' Handle movement and special keys
    IF ASC(key$) = 0 THEN
      SELECT CASE ASC(RIGHT$(key$, 1))
        CASE 72: key$ = "8"  ' Up arrow
        CASE 80: key$ = "2"  ' Down arrow
        CASE 75: key$ = "4"  ' Left arrow
        CASE 77: key$ = "6"  ' Right arrow
      END SELECT
    ELSEIF key$ = CHR$(8) THEN  ' Backspace
      ' Move left and erase character
      pb = pb - 1
      LOCATE pa, pb: PRINT " "
      GOTO TextInputLoop
    END IF
    
    SELECT CASE key$
      CASE "8"  ' Up arrow or 8
        pa = pa - 1       
      CASE "4"  ' Left arrow or 4
        pb = pb - 1
      CASE "6"  ' Right arrow or 6
        pb = pb + 1
      CASE "2"  ' Down arrow or 2
        pa = pa + 1
      CASE "`"  ' Exit
        RETURN
      CASE ELSE ' Type character and move right
        LOCATE pa, pb: PRINT key$
        key$ = "6"  ' Move right after typing
        pb = pb + 1
    END SELECT
  LOOP

'221
'  LOCATE pa, pb: PRINT "."  ' Show cursor
'  key$ = INKEY$               ' Get keypress
'  IF key$ = "" THEN 221       ' Wait for key
'  LOCATE pa, pb: PRINT " "  ' Clear cursor
'  IF key$ = CHR$(8) THEN key$ = "4"  ' Map backspace to left
'  IF key$ = "8" THEN pa = pa - 1: GOTO 221  ' Up
'  IF key$ = "4" THEN pb = pb - 1: GOTO 221  ' Left
'235
'  IF key$ = "6" THEN pb = pb + 1: GOTO 221  ' Right
'  IF key$ = "2" THEN pa = pa + 1: GOTO 221  ' Down
'  IF key$ = "`" THEN RETURN                 ' Exit
'  LOCATE pa, pb: PRINT key$   ' Print typed character
'  key$ = "6"                  ' Move right after typing
'GOTO 235
'-------------END OF TEXTINPUTMODE-------------

LoadPictureMenu:
  ' swich to a high resolution screen
  SCREEN 12
  LOCATE 1, 1: PRINT games(activeGame).name
  CLS
  gamePath$ = RTRIM$(games(activeGame).path) + "\"
  picExt$ = NormalizeExtension$(games(activeGame).files.picExt)

  FILES gamePath$ + "*" + picExt$        ' Shows available .pic files
  CLOSE : INPUT q$     ' Get filename from user
  SCREEN 13
  IF key$ = "r" THEN
    GOTO LoadPictureFullscreen
  ELSE
    GOTO LoadPicturePositioned
  END IF
  CLS
  'DEF SEG = &HB800
  'BLOAD q$ + ".pic", 0: GOTO 10
RETURN

EnterLargeCursorMode:
  isLargeCursorMode = 1 ' Set isLargeCursorMode flag to 1 to indicate we're in "large cursor" mode
  DRAW "c0" ' Set drawing color to black (0) to erase previous cursor
  
  IF isDrawing <> 0 THEN activeColor = isDrawing  ' Save current color if drawing was active
  isDrawing = 4                 ' Set new color to 4
  key$ = ""              ' Clear key input
GOTO 10

CaptureStampData:
' Sets stampSet flag and copies pixels from mz,mx to nz,nx into stampBuffer
  stampSet = -1
  GET (mz, mx)-(nz, nx), stampBuffer
RETURN

PasteStampWithOR:
  ' Paste the stamp buffer at current cursor position using OR mode
  ' OR mode combines the stamp with existing pixels rather than overwriting
  PUT (cursorX, cursorY), stampBuffer, OR
RETURN

FillWithColorPattern:
  GET (2, 2)-(200, 100), screenBuffer
  tile$ = ""
  FOR I = fillSourceColor TO fillTargetColor  ' Was ft/fy
    tile$ = tile$ + CHR$(I)
  NEXT I

  LINE (0, 10)-(321, 10), isDrawing, B  ' Was f
  PAINT (cursorX, cursorY), tile$, isDrawing  ' Was B,a
  tile$ = ""
RETURN

400 '-------------Click starts----------------
click:
  tr$ = "n"
  fca = "c"
  SCREEN 13
  FILES "*.pic"
  INPUT q$
  REM  GOSUB 709 'load specials
  CLOSE
  CLS
  cursorX = 50
  dd = 50
  GOTO 500  ' Was B
455
  GOSUB LoadPicturePositioned
RETURN

462 LOCATE 1, 1: PRINT "                                       "
464 LOCATE 2, 1: PRINT "                                       "
465 LOCATE 3, 1: PRINT "                                       "
466 LOCATE 4, 1: PRINT "                                       "
470 RETURN

500 ON ERROR GOTO 820
CQ = CQ + 1
502 IF CQ > 30 THEN 525
503 INPUT "More"; key$
504 IF key$ = "n" OR key$ = "no" OR key$ = "N" OR key$ = "NO" THEN 525 ELSE GOSUB 455
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
570 GET (1, 1)-(4, 4), cursorSprite
571 DRAW "bm200,6c2r75"
572 PUT (B, dd), cursorSprite, XOR
574 key$ = INKEY$: IF key$ = "" THEN 574
575 PUT (B, dd), cursorSprite, XOR
ON ERROR GOTO 820
    IF tar$ = "y" AND key$ <> "t" THEN GOSUB 815
579 IF key$ = "2" THEN dd = dd + 4
585 IF key$ = "8" THEN dd = dd - 4
590 IF key$ = "4" THEN B = B - 4
    IF key$ = "7" THEN B = B - 4: dd = dd - 4
    IF key$ = "9" THEN B = B + 4: dd = dd - 4
    IF key$ = "1" THEN B = B - 4: dd = dd + 4
    IF key$ = "3" THEN B = B + 4: dd = dd + 4
    IF key$ = "f" THEN GOSUB 810
    IF key$ = "t" THEN IF tar$ = "n" THEN tar$ = "y": INPUT ap$ ELSE tar$ = "n"
592 IF key$ = "s" THEN GOSUB 890
    IF key$ = "d" THEN GOSUB 789: LOCATE 1, 1: ip = 1: INPUT gp$: FOR I = 1 TO 30: GOSUB 790: NEXT I
593 IF key$ = "e" THEN LOCATE 16, 1: PRINT "Exit click?": key$ = INKEY$: IF key$ = "" THEN key$ = "e": GOTO 593 ELSE IF key$ = "y" THEN RUN
595 IF key$ = "6" THEN B = B + 4
596 IF key$ = CHR$(13) THEN IF gs < 75 THEN GOSUB 610 ELSE BEEP
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
682 key$ = INKEY$: IF key$ = "" THEN 682
684 IF key$ = "y" THEN RUN
685 IF key$ = "n" THEN SYSTEM
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
key$ = INKEY$: IF key$ = "" THEN 800
IF key$ = "Y" THEN KILL q$ + ".pic": CLOSE : KILL q$ + ".dat"
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
  RETURN
778 GET (2, 10)-(310, 198), screenBuffer
  DEF SEG = VARSEG(screenBuffer(1))
  BSAVE q$ + ".pic", VARPTR(screenBuffer(1)), 57000
  DEF SEG
  RETURN

LoadPictureFullscreen:
  CLS
  gamePath$ = RTRIM$(games(activeGame).path) + "\"
  picExt$ = NormalizeExtension$(games(activeGame).files.picExt)

  ' Check if this is a PCX file for palette type 3
  IF games(activeGame).palette.ptype = PAL_TYPE_3 THEN
    ' Try to open as PCX and verify header
    ON ERROR GOTO PcxCheckFailed
    OPEN gamePath$ + q$ + picExt$ FOR BINARY AS #1
    DIM headerByte AS STRING * 1
    GET #1, 1, headerByte
    
    ' Convert to integer and reverse bits if needed
    headerValue = ASC(headerByte)
    ' Try both normal and reversed comparisons
    IF headerValue = &HA0 OR _
       (headerValue AND &HF0) \ 16 + (headerValue AND &H0F) * 16 = &HA0 THEN
      CALL LoadPCX(gamePath$ + q$ + picExt$)
      GOTO 100
    END IF
    
    CLOSE #1
  END IF
  
PcxCheckFailed:
  IF ERR > 0 THEN
    RESUME NEXT
  END IF

PcxLoadFailed:
  ' Regular picture loading code
  GET (2, 10)-(310, 199), screenBuffer
  DEF SEG = VARSEG(screenBuffer(1))
  BLOAD gamePath$ + q$ + picExt$, VARPTR(screenBuffer(1))
  DEF SEG = 0
  c = 0
  PUT (2, 10), screenBuffer, PSET
  GOTO 883
RETURN

LoadPicturePositioned:
  PRINT "LoadPicturePositioned"
  CLS
  gamePath$ = RTRIM$(games(activeGame).path) + "\"
  picExt$ = NormalizeExtension$(games(activeGame).files.picExt)
  '------- LOADING OF THE PICTURE -------
  GET (2, 10)-(310, 199), screenBuffer
  DEF SEG = VARSEG(screenBuffer(1))
  BLOAD gamePath$ + q$ + picExt$, VARPTR(screenBuffer(1))
  DEF SEG = 0
  screenBuffer = 0
  PUT (2, 10), screenBuffer, PSET 'places picture in certain position
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

SUB DrawCanvasBorder
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

SUB Mouse
  SHARED lastMouseX, lastMouseY   ' Previous mouse X,Y coordinates (was lastB, lastA)
  SHARED buttons AS INTEGER       ' Current mouse button state
  SHARED buttonState AS INTEGER   ' Button state for debouncing (1=ready, 0=pressed) (was blt)
  SHARED inary() AS INTEGER, outary() AS INTEGER
  SHARED cursorX, cursorY, isDrawing, eraserMode$, cursorSprite() ' Add cursor array and drawing flags (was B, a, f, e$, a())
  STATIC cursorVisible AS INTEGER  ' Track cursor visibility state
  STATIC lastButtons AS INTEGER    ' Track previous button state
  
  ' Get current mouse position
  inary(ax) = 3
  CALL INT86OLD(BOUSE, inary(), outary())

  ' Button handling
  newButtons = outary(bx)

  ' Create undo point when mouse button is first pressed
  IF newButtons = 1 AND lastButtons = 0 THEN
    PUT (cursorX, cursorY), cursorSprite, XOR  ' Was PUT (B, a), a, XOR
    ' Save current screen state before drawing
    GET (2, 10)-(310, 198), screenBuffer       ' Was GET (2, 10)-(310, 198), c
    CALL SaveUndoState(screenBuffer())         ' Was CALL SaveUndoState(c())
  END IF
  lastButtons = newButtons  ' Remember button state for next time

  ' Calculate new position
  newX = outary(cx) \ 2    ' Was newB
  newY = outary(dx)        ' Was newA
  
  ' Handle mouse movement and buttons
  IF buttons <> 0 THEN  ' Mouse button pressed
    oldX = oldCursorX: oldY = oldCursorY    ' Was xb = oldB: ya = oldA
    IF activeColor <> 0 AND buttons = 1 THEN LINE (oldX, oldY)-(cursorX, cursorY), activeColor  ' Was LINE (xb, ya)-(B, a), activeColor
  END IF

  ' Only update position if mouse has moved
  IF newX <> lastMouseX OR newY <> lastMouseY THEN    ' Was IF newB <> lastB OR newA <> lastA

    ' Turn off draw mode in case it's on
    isDrawing = 0    ' Was f = 0

    ' Always erase cursor at OLD position if it was visible
    IF buttons <> 1 AND isDrawing = 0 AND eraserMode$ = "n" AND cursorVisible THEN    ' Was IF buttons <> 1 AND f = 0 AND e$ = "n" AND cursorVisible
      PUT (cursorX, cursorY), cursorSprite, XOR    ' Was PUT (B, a), a, XOR
      cursorVisible = 0
    END IF
    
    ' Update to new position
    cursorX = newX    ' Was B = newB
    cursorY = newY    ' Was a = newA
    
    ' Constrain to screen boundaries
    IF cursorX < 1 THEN cursorX = 1       ' Was IF B < 1 THEN B = 1
    IF cursorX > 319 THEN cursorX = 319   ' Was IF B > 319 THEN B = 319
    IF cursorY < 1 THEN cursorY = 1       ' Was IF a < 1 THEN a = 1
    IF cursorY > 199 THEN cursorY = 199   ' Was IF a > 199 THEN a = 199
    
    ' Draw cursor at new position
    IF buttons <> 1 AND isDrawing = 0 AND eraserMode$ = "n" THEN    ' Was IF buttons <> 1 AND f = 0 AND e$ = "n"
      PUT (cursorX, cursorY), cursorSprite, XOR    ' Was PUT (B, a), a, XOR
      cursorVisible = -1
    END IF
    
    ' Save position for next time
    lastMouseX = cursorX    ' Was lastB = B
    lastMouseY = cursorY    ' Was lastA = a
  END IF

  IF buttons = 1 AND newButtons <> 1 THEN
    PUT (cursorX, cursorY), cursorSprite, XOR    ' Was PUT (B, a), a, XOR
  END IF

  buttons = newButtons
END SUB

SUB SavePicture (filename$)
    SHARED screenBuffer() AS INTEGER, fca AS STRING, fit AS INTEGER, qa() AS INTEGER, qb() AS INTEGER, x() AS INTEGER, y() AS INTEGER
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
    GET (2, 10)-(310, 198), screenBuffer
    DEF SEG = VARSEG(screenBuffer(1))
    BSAVE filename$ + ".pic", VARPTR(screenBuffer(1)), imageBytes
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

SUB DisplayMemoryUsage
    ' Get total memory
    DEF SEG = 0
    totalMem& = CLNG(PEEK(&H413)) * 1024  ' BIOS reports memory in KB at 0:413h, convert to LONG

    ' Get free memory - need to do both string and numeric
    dummy$ = ""  ' Force string space compaction
    freeMem& = FRE("")  ' Get string memory
    IF freeMem& < 0 THEN freeMem& = freeMem& + 65536 ' Adjust for integer overflow
    
    ' Calculate used memory
    usedMem& = totalMem& - freeMem&

    ' Display at bottom of screen
    LOCATE 25, 1
    PRINT USING "Used:###.#K Free:###.#K Total:###.#K"; usedMem&/1024; freeMem&/1024; totalMem&/1024;
END SUB
