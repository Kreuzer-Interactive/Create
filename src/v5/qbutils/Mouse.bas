'By Jon Kreuzer
'Quick Basic Mouse Utility. (This won't work in Qbasic, because Qbasic
'does not support the INT86 function. I tried creating a Mouse Utility
'with CALL ABSOLUTE, but it kept locking up. There is code for using
'the mouse available on AOL, but here I only include programs that are
'100% my work)
'=You can also use the PEN statement in Qbasic, but for that to work both
'=mouse buttons must be held down.
'type <QB /L qb.qlb> to run Quick Basic with the INT86OLD function
DEFINT A-Q, S-Z
CONST mouse = 51' The mouse driver uses interupt 51
CONST ax = 0, bx = 1, cx = 2, dx = 3, bp = 4, si = 5, di = 6, FL = 7
DECLARE SUB INT86OLD (intnum AS INTEGER, inarray() AS INTEGER, outarray() AS INTEGER)
DIM inary(7) AS INTEGER, outary(7) AS INTEGER
DIM mousex AS INTEGER, mousey AS INTEGER, buttons AS INTEGER, bbb AS INTEGER
'==The line above is only needed if you don't use the DEFINT A-Q,S-Z


SCREEN 13
'==Note mousex returns the x coordinate of the mouse
'==Note mousey returns the y coordinate of the mouse
'==Note bbb returns the buttons currently being pressed (1 left, 2 right
'==3 both)
'==If there is a click, buttons returns (1 left-click, 2 right click)

Looper:
lx = mousex: ly = mousey
GOSUB mouser '===Get mouse coordinates and button values from mouser
LOCATE 1, 1: PRINT "x"; mousex; " y"; mousey; " buttons"; bbb; "   "
PSET (mousex, mousey), 1 + bbb
IF INKEY$ = "q" THEN END 'Q-quit
GOTO Looper


mouser:
inary(ax) = 3 '==sub function 3 of the mouse driver is the coordinates.
              '==sub functions 1 and 2 are show and hide pointer, but the
              '==pointer has a tendency to get written over, so you should
              '==make you own.
CALL INT86OLD(mouse, inary(), outary()) '==Calls the mouse driver
mousex = outary(cx) / 2'==For screen mode 12 we don't need this / 2
mousey = outary(dx)
bbb = outary(bx)
buttons = 0
IF bbb = 1 AND blt = 1 THEN buttons = 1: blt = 0 'Buttons=1 for left click
IF bbb = 2 AND blt = 1 THEN buttons = 2: blt = 0 'Buttons=2 for right click
IF bbb = 0 THEN blt = 1
RETURN

