DECLARE SUB SavePicture (filename$)
DECLARE SUB SaveSpecialData (filename$)
DECLARE SUB DrawCanvasBorder ()
DECLARE SUB Mouse ()
DECLARE SUB LoadPCX (filename$)

DEFINT B-C
DIM SHARED palettes$(10, 1)  ' Up to 10 palettes, with name and type

' Mouse tracking
DIM SHARED lastB, lastA   ' Previous mouse X,Y coordinates
DIM SHARED buttons AS INTEGER  ' Current mouse button state
DIM SHARED blt AS INTEGER     ' Button state for debouncing (1=ready, 0=pressed)

DIM SHARED inary(7) AS INTEGER, outary(7) AS INTEGER

DIM SHARED stampBuffer() AS INTEGER  ' New array for stamp data
DIM SHARED screenBuffer() AS INTEGER
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
CONST bufferSize = 32300
CONST KEY_ENTER = 13        ' Enter/Return key
CONST KEY_CTRL_F = 6        ' Ctrl+F key
CONST KEY_CTRL_E = 5  ' Ctrl+E - Toggle eraser mode
CONST KEY_CTRL_Z = 26       ' Ctrl+Z key

DIM cursorSprite(10)            ' Reserves 22 bytes (11 integers × 2 bytes each)
DIM vh$(50)                     ' Reserves ~2.6KB (51 strings × default 1 string descriptor (4 bytes) + variable string data)
DIM basicPal(255) AS LONG       ' Reserves 1024 bytes (256 longs × 4 bytes each)
DIM pl(255) AS LONG             ' Reserves 1024 bytes (256 longs × 4 bytes each)
DIM games(10) AS GAMECONFIG     ' Depends on size of GAMECONFIG type structure
