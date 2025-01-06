'Jon Kreuzer of Kreuzer indrustries
'This is how to save VGA images in Qbasic. _Please_ use it in your games.
'Completely free of charge.
               ' You can create a draw program to draw masterpieces then
               ' save and load them quickly.
              
SCREEN 13
'--THIS CREATES AN ARRAY TO STORE IMAGE---
DEFINT A-Q, S-Z'Defines all variables beginning with a letter other than R
                'as integers!
DIM image(1 TO 32000)' Size depends on size of image. 32000 can hold the
        'whole VGA 256 color screen.
'---YOU WON'T NEED THIS EXACT STUFF IN YOUR PROGRAM---
x1 = 0: x2 = 200: y1 = 0: y2 = 150' Set coordinates (x values=0 TO 319
                                'y values=0 TO 199)
'GOTO 5'Take the first ' away to goto load of previously saved picture
FOR i = 1 TO 50' Fill screen with needless junk to save
LINE (RND * 320, RND * 200)-(RND * 320, RND * 200), RND * 256
NEXT i

save: '--THIS IS THE ACTUAL SAVING--
1 GET (x1, y1)-(x2, y2), image'x1,y1=upper left coordinates x2,y2=lower left
                        'coordinates. Gets image
size = 4 + INT(((x2 - x1 + 1) * (8) + 7) / 8) * ((y2 - y1) + 1)
                        'compute size of array for image
DEF SEG = VARSEG(image(1)) 'Set offset to image array
BSAVE "test.pct", VARPTR(image(1)), size  'Save memory directly with test.pct
                                        'as name
END
'--THIS IS THE ACTUAL LOADING---
5 DEF SEG = VARSEG(image(1)) 'Set offset to image array
BLOAD "test.pct", VARPTR(image(1))      'load test.pct
PUT (0, 0), image, PSET      'display test.pct
END

'I'd just like to add that I spent two days of constant tinkering
'to figure this out just from my knowledge of Qbasic, then I got
'Quickbasic 4.5, and saving like this was in the help! Sometimes even if
'you win, you lose.

