'$INCLUDE: 'modules\CONFIG.BI'
CONST MAX_SECTIONS = 10
CONST MAX_KEYS = 10
DIM SHARED sectionNames(MAX_SECTIONS) AS STRING
DIM SHARED keyNames(MAX_SECTIONS, MAX_KEYS) AS STRING
DIM currentSectionIndex AS INTEGER

SUB LoadGameINI (filename$)
  SHARED settings() AS STRING   ' For general settings
  SHARED games() AS GAMECONFIG  ' Array of game configurations
  SHARED gameCount AS INTEGER   ' Number of games loaded

  DIM currentSection AS STRING
  DIM isGameSection AS INTEGER

  gameCount = 0

  ' Open the INI file
  OPEN filename$ FOR INPUT AS #1

  WHILE NOT EOF(1)
    LINE INPUT #1, line$
    line$ = LTRIM$(RTRIM$(line$))  ' Remove leading/trailing spaces

    ' Skip empty lines and comments
    IF LEN(line$) > 0 AND LEFT$(line$, 1) <> ";" THEN
      ' Check if this is a section header [section]
      IF LEFT$(line$, 1) = "[" AND RIGHT$(line$, 1) = "]" THEN
        currentSection = MID$(line$, 2, LEN(line$) - 2)
        ' Check if this is a game section
        isGameSection = (LEFT$(currentSection, 4) = "game")
        IF isGameSection THEN
          gameCount = gameCount + 1
          REDIM PRESERVE games(gameCount) AS GAMECONFIG
        END IF
      ELSE
        ' Look for key=value pair
        equalPos = INSTR(line$, "=")
        IF equalPos > 0 THEN
            key$ = LTRIM$(RTRIM$(LEFT$(line$, equalPos - 1)))
            value$ = LTRIM$(RTRIM$(MID$(line$, equalPos + 1)))

            IF isGameSection THEN
              ' Load into game config structure
              SELECT CASE key$
                CASE "name"
                  games(gameCount).name = value$
                  
                CASE "screenmode"
                  games(gameCount).screen.mode = VAL(value$)
                CASE "palettetype"
                  games(gameCount).palette.ptype = VAL(value$)
                CASE "palettefiles"
                  games(gameCount).palette.fnames = value$
                CASE "dataext"
                  games(gameCount).files.dataExt = value$
                CASE "picext"
                  games(gameCount).files.picExt = value$
                CASE "path"
                  games(gameCount).path = value$
              END SELECT
            ELSE
              ' Store regular settings
              ' Then in the loading code:
              currentSectionIndex% = FindOrCreateSection%(currentSection$)
              IF currentSectionIndex% > 0 THEN
                keyIndex% = FindOrCreateKey%(currentSectionIndex%, key$)
                IF keyIndex% > 0 THEN
                  settings(currentSectionIndex%, keyIndex%) = value$
                END IF
              END IF
            END IF
        END IF
      END IF
    END IF
  WEND

  CLOSE #1
  'Call WriteGameNames("games.txt")
END SUB

' print a list of all the games
SUB PrintGames()
  FOR i = 1 TO gameCount
    PRINT games(i).name
  NEXT i
END SUB

' New function to write game names to file
SUB WriteGameNames (filename AS STRING)
  OPEN filename FOR OUTPUT AS #1
  FOR i = 1 TO gameCount
    PRINT #1, games(i).name
  NEXT i
  CLOSE #1
END SUB

' In the loading routine:
FUNCTION FindOrCreateSection%(sectionName$)
    FOR i = 1 TO MAX_SECTIONS
        IF sectionNames(i) = sectionName$ THEN
            FindOrCreateSection% = i
            EXIT FUNCTION
        ELSEIF sectionNames(i) = "" THEN
            sectionNames(i) = sectionName$
            FindOrCreateSection% = i
            EXIT FUNCTION
        END IF
    NEXT i
    FindOrCreateSection% = 0  ' Section list full
END FUNCTION

FUNCTION FindOrCreateKey%(sectionIndex%, keyName$)
  FOR i = 1 TO MAX_KEYS
    IF keyNames(sectionIndex%, i) = keyName$ THEN
      FindOrCreateKey% = i
      EXIT FUNCTION
    ELSEIF keyNames(sectionIndex%, i) = "" THEN
      keyNames(sectionIndex%, i) = keyName$
      FindOrCreateKey% = i
      EXIT FUNCTION
    END IF
  NEXT i
  FindOrCreateKey% = 0  ' Key list full
END FUNCTION

FUNCTION GetSetting(sectionName AS STRING, keyName AS STRING) AS STRING
  sectionIndex% = FindOrCreateSection%(sectionName)
  IF sectionIndex% > 0 THEN
    keyIndex% = FindOrCreateKey%(sectionIndex%, keyName)
    IF keyIndex% > 0 THEN
      GetSetting = settings(sectionIndex%, keyIndex%)
    END IF
  END IF
END FUNCTION

FUNCTION NormalizeExtension$ (ext$)
  ' Ensures file extension starts with a dot
  ' Input: ext$ - file extension (with or without dot)
  ' Returns: extension with leading dot
  
  ext$ = RTRIM$(ext$)
  IF LEFT$(ext$, 1) <> "." THEN
    NormalizeExtension$ = "." + ext$
  ELSE
    NormalizeExtension$ = ext$
  END IF
END FUNCTION

SUB LogError ()
  ' Log error to file
  OPEN "error.log" FOR APPEND AS #1
  PRINT #1, "=== Error Report ==="
  PRINT #1, "Time: "; TIME$; " Date: "; DATE$
  PRINT #1, "Error #"; ERR; " at line"; ERL
  
  ' Add error description based on error number
  SELECT CASE ERR
    CASE 1: PRINT #1, "Description: NEXT without FOR"
    CASE 2: PRINT #1, "Description: Syntax error"
    CASE 3: PRINT #1, "Description: RETURN without GOSUB"
    CASE 4: PRINT #1, "Description: Out of DATA"
    CASE 5: PRINT #1, "Description: Illegal function call"
    CASE 6: PRINT #1, "Description: Overflow"
    CASE 7: PRINT #1, "Description: Out of memory"
    CASE 8: PRINT #1, "Description: Label not defined"
    CASE 9: PRINT #1, "Description: Subscript out of range"
    CASE 10: PRINT #1, "Description: Duplicate definition"
    CASE 11: PRINT #1, "Description: Division by zero"
    CASE 12: PRINT #1, "Description: Illegal in direct mode"
    CASE 13: PRINT #1, "Description: Type mismatch"
    CASE 14: PRINT #1, "Description: Out of string space"
    CASE 15: PRINT #1, "Description: String too long"
    CASE 16: PRINT #1, "Description: String formula too complex"
    CASE 17: PRINT #1, "Description: Cannot continue"
    CASE 18: PRINT #1, "Description: Function not defined"
    CASE 19: PRINT #1, "Description: No RESUME"
    CASE 20: PRINT #1, "Description: RESUME without error"
    CASE 50: PRINT #1, "Description: FIELD overflow"
    CASE 51: PRINT #1, "Description: Internal error"
    CASE 52: PRINT #1, "Description: Bad file number"
    CASE 53: PRINT #1, "Description: File not found"
    CASE 54: PRINT #1, "Description: Bad file mode"
    CASE 55: PRINT #1, "Description: File already open"
    CASE 56: PRINT #1, "Description: FIELD statement active"
    CASE 57: PRINT #1, "Description: Device I/O error"
    CASE 58: PRINT #1, "Description: File already exists"
    CASE 59: PRINT #1, "Description: Bad record length"
    CASE 61: PRINT #1, "Description: Disk full"
    CASE 62: PRINT #1, "Description: Input past end of file"
    CASE 63: PRINT #1, "Description: Bad record number"
    CASE 64: PRINT #1, "Description: Bad filename"
    CASE 67: PRINT #1, "Description: Too many files"
    CASE 68: PRINT #1, "Description: Device unavailable"
    CASE 69: PRINT #1, "Description: Communication buffer overflow"
    CASE 70: PRINT #1, "Description: Permission denied"
    CASE 71: PRINT #1, "Description: Disk not ready"
    CASE ELSE: PRINT #1, "Description: Unknown error"
  END SELECT

  ' Program state
  PRINT #1, "Program State:"
  PRINT #1, "  Cursor position: "; B; ","; a
  PRINT #1, "  Active color: "; activeColor
  PRINT #1, "  Draw mode: "; f
  PRINT #1, "  Eraser mode: "; eraserMode$
  PRINT #1, "  Big cursor mode: "; isBigCurMode
  PRINT #1, "  Active palette: "; activePalette
  PRINT #1, "  Step size: "; s
  
  CLOSE #1
END SUB

SUB LoadPCX (filename$)
  CONST mask = &H3C5
  CONST reg = &H3C8
  CONST dat = &H3C9
  CONST BUFFER_SIZE = 1024
  
  DIM buffer AS STRING * 1024
  DIM char AS STRING * 1
  DIM red AS STRING * 1, green AS STRING * 1, blue AS STRING * 1
  DIM bytepos AS LONG
  DIM header AS STRING * 128  ' PCX header is 128 bytes
  
  ' Load PCX file
  OPEN filename$ FOR BINARY AS #2
  
  ' Read PCX header
  GET #2, 1, header
  
  ' Get image dimensions from header
  xMin = ASC(MID$(header, 5, 1)) + 256 * ASC(MID$(header, 6, 1))
  yMin = ASC(MID$(header, 7, 1)) + 256 * ASC(MID$(header, 8, 1))
  xMax = ASC(MID$(header, 9, 1)) + 256 * ASC(MID$(header, 10, 1))
  yMax = ASC(MID$(header, 11, 1)) + 256 * ASC(MID$(header, 12, 1))
  
  pcxWidth = xMax - xMin + 1
  pcxHeight = yMax - yMin + 1
  
  ' Debug output
  LOCATE 25, 1
  PRINT "PCX dimensions:"; pcxWidth; "x"; pcxHeight;
  
  'LOAD PALETTE (at end of file)
  SEEK #2, LOF(2) - 767
  FOR i = 0 TO 255
    GET #2, , red
    GET #2, , green
    GET #2, , blue
    OUT dat, ASC(red) \ 4
    OUT dat, ASC(green) \ 4
    OUT dat, ASC(blue) \ 4
  NEXT i
  
  'LOAD PICTURE
  SEEK #2, 129  ' Skip header
  bytepos = 0
  screenWidth = 320  ' Mode 13h pcxWidth
  DEF SEG = &HA000
  
  DO
    GET #2, , buffer
    
    FOR i = 1 TO LEN(buffer)
      char = MID$(buffer, i, 1)
      value = ASC(char)
      
      IF bytepos >= (screenWidth * pcxHeight) THEN EXIT DO
      
      IF value > 192 THEN  ' Run-length encoded
        count = value - 192
        i = i + 1
        IF i <= LEN(buffer) THEN
          char = MID$(buffer, i, 1)
        ELSE
          GET #2, , char
        END IF
        
        value = ASC(char)
        FOR j = 1 TO count
          ' Calculate screen position
          x = bytepos MOD screenWidth
          y = bytepos \ screenWidth
          
          ' Only draw if within bounds
          IF x < pcxWidth AND y < pcxHeight THEN
            POKE bytepos, value
          END IF
          bytepos = bytepos + 1
          IF bytepos >= (screenWidth * pcxHeight) THEN EXIT DO
        NEXT j
      ELSE  ' Regular byte
        x = bytepos MOD screenWidth
        y = bytepos \ screenWidth
        
        ' Only draw if within bounds
        IF x < pcxWidth AND y < pcxHeight THEN
          POKE bytepos, value
        END IF
        bytepos = bytepos + 1
      END IF
    NEXT i
    
  LOOP UNTIL EOF(2) OR bytepos >= (screenWidth * pcxHeight)
  
  DEF SEG
  CLOSE #2
END SUB
