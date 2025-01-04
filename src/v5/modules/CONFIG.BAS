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

