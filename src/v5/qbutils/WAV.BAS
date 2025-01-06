'Attention: This code was not written by me! I downloaded from the internet,
'and there was no author listed.
'However, the code was buggy, and I have corrected it.

DECLARE SUB SetVoice (OnOff%)
DIM voff AS LONG

khz = 22 ' 11 & 22 are the only two values supported.
         ' If 22 gives you a quick high-pitched wave, try 11 khz.
         ' The waves must be 8 bit.

'$DYNAMIC
  CLS
  VocFile$ = "C:\windows\killer2.WAV"       ' input-file
  VocFile% = FREEFILE             ' .
 
'-open the voc-file
  OPEN VocFile$ FOR BINARY AS #VocFile%

'-parameters for copy-to-soundblaster
  Bytes& = LOF(VocFile%)          ' number of bytes

  BytesRemaining& = Bytes&        ' number of remaining bytes
  BufferMax% = 30000             ' largest buffer
  buffer$ = SPACE$(BufferMax%)    ' create buffer

  SetVoice 1                      ' Soundblaster on

'-read {BufferMax%} bytes from disc, output on SB
  DO
     BytesRemaining& = BytesRemaining& - BufferLen%
     IF BytesRemaining& = 0 THEN EXIT DO ' nothing left over?
     IF BytesRemaining& > BufferMax% THEN ' how many bytes?
        BufferLen% = BufferMax%          '
     ELSE
        BufferLen% = BytesRemaining&     ' remaining (<BufferMax%)..
        buffer$ = ""
        buffer$ = SPACE$(BufferLen%)     ' ..throw it into SB :-)
     END IF

     GET #VocFile%, , buffer$            ' read buffer
     DEF SEG = VARSEG(buffer$)           ' get address of buffer
     voff = SADD(buffer$)               ' .

     FOR t% = 1 TO BufferLen%            ' output od {bufferlen%}
         WAIT &H22C, &H80, &HFF         ' wait for data-ready
         OUT &H22C, &H10
         WAIT &H22C, &H80, &HFF
         OUT &H22C, PEEK(voff)
IF khz = 11 THEN WAIT &H22C, &H80, &HFF: OUT &H22C, &H10: WAIT &H22C, &H80, &HFF: OUT &H22C, PEEK(voff)
                ' At 11 khz we feed the data to the soundblaster twice to slow it down.
         voff = voff + 1
     NEXT t%

LOOP WHILE INKEY$ = ""

  SetVoice 0                            ' SB off
  CLOSE #VocFile%                       ' close file
  END

REM $STATIC
SUB SetVoice (OnOff%)
    IF OnOff% THEN
       WAIT &H22C, &H80, &HFF       ' wait for data-ready on SB
       OUT &H22C, &HD1              ' ON
    ELSE
       WAIT &H22C, &H80, &HFF
       OUT &H22C, &HD3              ' OFF
    END IF
END SUB

