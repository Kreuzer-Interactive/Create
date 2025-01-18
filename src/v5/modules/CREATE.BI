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
