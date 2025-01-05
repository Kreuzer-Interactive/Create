DECLARE SUB LoadPalette ()
DECLARE SUB InitPalettes ()
DECLARE FUNCTION FindNeutralGray% ()
CONST PAL_TYPE_1 = 1 ' Dream Giver
CONST PAL_TYPE_2 = 2 ' Space 2
CONST PAL_TYPE_3 = 3 ' Dark visions 2

COMMON SHARED pl() AS LONG         ' Palette array
COMMON SHARED basicPal() AS LONG   ' Basic palette storage
COMMON SHARED activePalette AS INTEGER
