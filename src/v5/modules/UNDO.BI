CONST MAX_UNDO = 50  ' Number of undo states to keep
DIM SHARED currentUndo AS INTEGER
DIM SHARED totalUndos AS INTEGER

DECLARE SUB SaveUndoState (buffer() AS INTEGER)
DECLARE SUB RestoreUndoState (buffer() AS INTEGER)
DECLARE SUB InitializeUndo ()
DECLARE SUB CleanupUndo ()
