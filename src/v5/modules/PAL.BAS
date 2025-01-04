'$INCLUDE: 'modules\CONFIG.BI'
'$INCLUDE: 'modules\PAL.BI'

SUB InitPalettes ()
  SHARED activePalette AS INTEGER, basicPal() AS LONG
  ' Save current palette values before loading new ones
  FOR i = 0 TO 255
    OUT &H3C7, I          ' Tell VGA we want to read color i
    ' Add a small delay to allow VGA to prepare data
    FOR delay = 1 TO 10: NEXT delay
    red = INP(&H3C9)      ' Read red component
    green = INP(&H3C9)    ' Read green component
    blue = INP(&H3C9)     ' Read blue component
    basicPal(i) = red + (green * 256) + (blue * 65536)
  NEXT i
  activePalette = 0
END SUB

SUB LoadPalette ()
  SHARED activeGame AS INTEGER
  SHARED games() AS GAMECONFIG
  SHARED pl() AS LONG, activePalette AS INTEGER, basicPal() AS LONG
  ' Reset palette to default values
  FOR i = 1 TO 255
    PALETTE i, basicPal(i)
    if basicPal(i) <> 0 then
      'print basicPal(i)
    end if
  NEXT i
  
  IF activeGame < 1 OR activeGame > UBOUND(games) THEN
    activeGame = 1   ' Reset to first game if out of range
  END IF

  pallet$ = GetPaletteFile$(games(activeGame).palette.fnames, activePalette)
  palType = games(activeGame).palette.ptype
  
  IF RIGHT$(games(activeGame).path, 1) = "\" THEN
    fullPath$ = RTRIM$(games(activeGame).path) + RTRIM$(pallet$) + ".pal"
  ELSE
    fullPath$ = RTRIM$(games(activeGame).path) + "\" + RTRIM$(pallet$) + ".pal"
  END IF
  
  OPEN fullPath$ FOR INPUT AS #1     ' Opens the palette file
  
  IF palType = PALV1 THEN
    dim tmp as LONG
    'type 1 - loads with offset and early exit on zero
    FOR i = 1 TO 255 STEP 1
      INPUT #1, tmp
      pl(i) = tmp            ' Reads each color value
      IF tmp = 0 AND i > 10 THEN i = 255
      PALETTE i + 16, tmp
    NEXT i
  ELSEIF palType = PALV3 THEN
    CLOSE #1
    bright = 3  ' Brightness multiplier (1 = normal, 2 = twice as bright, etc.)
    OPEN fullPath$ FOR BINARY AS #1
    'type 3 - loads RGB bytes individually
    FOR I = 1 TO 255
      IF EOF(1) THEN EXIT FOR
        red = (ASC(INPUT$(1, #1)) * bright) \ 4     ' Apply brightness before scaling
        IF red > 63 THEN red = 63                    ' Clamp to max brightness
        green = (ASC(INPUT$(1, #1)) * bright) \ 4
        IF green > 63 THEN green = 63
        blue = (ASC(INPUT$(1, #1)) * bright) \ 4
        IF blue > 63 THEN blue = 63
        pl(I) = (blue * 65536) + (green * 256) + red
    NEXT I
    PALETTE USING pl(0)
  ELSE
    'type 2 - loads all colors and applies at once
    FOR I = 1 TO 255 STEP 1          ' Loops through all possible colors
        INPUT #1, pl(I)              ' Reads each color value
    NEXT I
    PALETTE USING pl(0)              ' Applies the loaded palette
  END IF
  
  CLOSE #1
  
  CALL DrawPaletteDisplay
END SUB

SUB DrawPaletteDisplay ()
  ' Clear the palette display area first (black box over old palette)
  LINE (0, 1)-(360, 6), 0, BF
  
  ' Draw the palette display with 3x2 pixel rectangles
  FOR I = 1 TO 120
    LINE (I * 2, 1)-(I * 2 + 2, 2), I, BF      ' Draw top row of colors
  NEXT I
  FOR I = 121 TO 255
    LINE ((I - 120) * 2, 4)-((I - 120) * 2 + 2, 5), I, BF      ' Draw bottom row of colors
  NEXT I
END SUB

FUNCTION GetPaletteFile$(list$, index%)
    ' Count items in list
    count% = 1
    FOR i% = 1 TO LEN(list$)
        IF MID$(list$, i%, 1) = "," THEN count% = count% + 1
    NEXT i%
    
    ' Wrap index if it exceeds count
    IF index% > count% THEN index% = 1
    
    ' Find the requested item
    current% = 1
    lastPos% = 0
    
    FOR i% = 1 TO LEN(list$)
        IF MID$(list$, i%, 1) = "," OR i% = LEN(list$) THEN
            IF current% = index% THEN
                IF i% = LEN(list$) AND MID$(list$, i%, 1) <> "," THEN
                    GetPaletteFile$ = MID$(list$, lastPos% + 1, i% - lastPos%)
                ELSE
                    GetPaletteFile$ = MID$(list$, lastPos% + 1, i% - lastPos% - 1)
                END IF
                EXIT FUNCTION
            END IF
            current% = current% + 1
            lastPos% = i%
        END IF
    NEXT i%
    
    ' If we get here, return first item as fallback
    commaPos% = INSTR(list$, ",")
    IF commaPos% = 0 THEN commaPos% = LEN(list$)
    GetPaletteFile$ = LEFT$(list$, commaPos% - 1)
END FUNCTION
