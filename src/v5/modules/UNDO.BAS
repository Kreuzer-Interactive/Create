'$INCLUDE: 'modules\UNDO.BI'

SUB SaveUndoState (buffer() AS INTEGER)
    SHARED currentUndo AS INTEGER
    SHARED totalUndos AS INTEGER
    
    ' Create unique filename for this undo state
    currentUndo = (currentUndo MOD MAX_UNDO) + 1
    filename$ = "undo\" + "state" + LTRIM$(STR$(currentUndo)) + ".tmp"
    
    ' Get screen contents into buffer
    GET (2, 10)-(310, 198), buffer
    
    ' Save buffer to file
    DEF SEG = VARSEG(buffer(1))
    BSAVE filename$, VARPTR(buffer(1)), 57000  ' Approximate size for screen area
    DEF SEG
    
    IF totalUndos < MAX_UNDO THEN totalUndos = totalUndos + 1
END SUB

SUB RestoreUndoState (buffer() AS INTEGER)
    SHARED currentUndo AS INTEGER
    SHARED totalUndos AS INTEGER
    
    IF totalUndos = 0 THEN EXIT SUB  ' Nothing to undo
    
    ' Load previous state
    filename$ = "undo\" + "state" + LTRIM$(STR$(currentUndo)) + ".tmp"
    
    ' Load file into array
    DEF SEG = VARSEG(buffer(1))
    BLOAD filename$, VARPTR(buffer(1))
    DEF SEG
    
    ' Display the restored state
    PUT (2, 10), buffer, PSET
    
    ' Clean up file (optional)
    KILL filename$
    
    currentUndo = currentUndo - 1
    IF currentUndo = 0 THEN currentUndo = MAX_UNDO
    totalUndos = totalUndos - 1
END SUB

SUB InitializeUndo ()
    ' Create undo directory if it doesn't exist
    ON LOCAL ERROR GOTO InitError
    MKDIR "undo"
    GOTO InitContinue    ' Skip error handler if no error

InitError:
    ' Just continue if directory already exists
    RESUME InitContinue

InitContinue:    
    ' Clean up any existing temp files
    ON LOCAL ERROR GOTO InitCleanup
    KILL "undo\*.tmp"
InitCleanup:
    RESUME NEXT
    currentUndo = 0
    totalUndos = 0
END SUB

SUB CleanupUndo ()
    ' Remove all temporary undo files
    ON LOCAL ERROR GOTO CleanupError
    KILL "undo\*.tmp"
    RMDIR "undo"
    GOTO CleanupContinue    ' Skip error handler if no error

CleanupError:
    ' Ignore errors (like directory not found)
    RESUME CleanupContinue

CleanupContinue:
    EXIT SUB
END SUB
