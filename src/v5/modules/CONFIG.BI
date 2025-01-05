DECLARE SUB LoadINI (filename$)
DECLARE FUNCTION NormalizeExtension$ (ext AS STRING)
' Game Configuration Type Definitions
TYPE SCREENCONFIG
    mode AS INTEGER        ' Screen mode (13)
END TYPE

TYPE PALETTECONFIG
  ptype AS INTEGER        ' Palette type (1,2,3)
  fnames AS STRING * 128  ' comma separated list of filenames
END TYPE

TYPE FILECONFIG
  dataExt AS STRING * 4    ' .DAT
  picExt AS STRING * 4     ' .PIC
END TYPE

TYPE GAMECONFIG
  name AS STRING * 16         ' Game name
  screen AS SCREENCONFIG      ' Screen settings
  palette AS PALETTECONFIG    ' Palette settings
  files AS FILECONFIG         ' File extensions
  path AS string * 64         ' Asset path
END TYPE

' Shared variable declarations
COMMON SHARED settings() AS STRING     ' General settings
COMMON SHARED games() AS GAMECONFIG    ' Array of games
COMMON SHARED gameCount AS INTEGER     ' Number of games loaded
COMMON SHARED activeGame AS INTEGER    ' Currently selected game
COMMON SHARED palType AS INTEGER       ' Palette type

CONST bufferSize = 32300
