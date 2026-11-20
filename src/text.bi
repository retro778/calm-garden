' text.bi - Unicode text rendering for Calm Garden.
'
' Pipeline (per line):
'   UTF-8 -> code points -> UAX #9 levels (bidi.bas) -> line breaking ->
'   L1/L2 visual reordering -> visual runs (same level, same font) ->
'   each run shaped by HarfBuzz inside SDL2_ttf with its own direction (RTL for
'   odd levels, which also mirrors brackets) and script (Hebr / Latn) ->
'   anti-aliased coverage mask -> blended into the software canvas.
'
' Hebrew glyphs come from Noto Sans Hebrew, Latin from Noto Sans, anything
' missing from DejaVu Sans. Rendered runs are cached.
#pragma once
#include once "graphics.bi"

Const FACE_REGULAR = 0
Const FACE_BOLD = 1

Const ALIGN_START = 0     ' left for left-to-right paragraphs, right for right-to-left ones
Const ALIGN_CENTER = 1
Const ALIGN_END = 2
Const ALIGN_LEFT = 3      ' always left
Const ALIGN_RIGHT = 4     ' always right

' direction argument: 0 = left-to-right paragraph, 1 = right-to-left paragraph,
' -1 = automatic (first strong character, used for text typed by the user)
Const DIR_LTR = 0
Const DIR_RTL = 1
Const DIR_AUTO = -1

Declare Function Txt_Init(ByRef fontDir As String) As Boolean
Declare Sub Txt_Shutdown()
Declare Function Txt_LastError() As String
Declare Function Txt_LineHeight(ByVal face As Long, ByVal size As Long) As Long
Declare Function Txt_Width(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal dir_ As Long = DIR_AUTO) As Long
' single line, (x, y) = top-left of the line box
Declare Sub Txt_Draw(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal dir_ As Long)
' single line aligned inside [x, x + w); cut with an ellipsis when too long
Declare Sub Txt_DrawLine(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal align As Long, ByVal dir_ As Long)
' word-wrapped paragraphs ("\n" separates paragraphs); returns the height used.
' doDraw = 0 only measures.
Declare Function Txt_Wrap(ByRef cv As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal col As ULong, ByVal align As Long, ByVal dir_ As Long, ByVal doDraw As Long = 1) As Long
Declare Function Txt_WrapHeight(ByRef s As String, ByVal w As Long, ByVal face As Long, ByVal size As Long, ByVal dir_ As Long) As Long
' largest size <= size (but >= minSize) at which s fits in maxW on one line
Declare Function Txt_FitSize(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal maxW As Long, ByVal minSize As Long, ByVal dir_ As Long = DIR_AUTO) As Long
Declare Function Txt_Fit(ByRef s As String, ByVal face As Long, ByVal size As Long, ByVal maxW As Long, ByVal dir_ As Long = DIR_AUTO) As String
' test helper: the visual runs of one line as "R:text|L:text" (left to right)
Declare Function Txt_DebugRuns(ByRef s As String, ByVal dir_ As Long) As String
Declare Function Txt_CacheCount() As Long
