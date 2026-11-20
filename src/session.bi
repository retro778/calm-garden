' session.bi - the shared flow of every activity: intro -> running -> done.
' Handles pausing, the optional (never required) "how do you feel" ratings,
' gentle ambient sound, chimes, and recording the session in the progress file.
#pragma once
#include once "ui.bi"
#include once "animation.bi"

Const SS_INTRO = 0
Const SS_RUN = 1
Const SS_DONE = 2

Type SessFlow
    act As Long
    state As Long
    clk As SessionClock
    before As Long
    after As Long
    recorded As Long
    completed As Long
    natural As Long        ' "breathe naturally" chosen during the session
    msgIdx As Long
    afterSaved As Long
End Type

Declare Sub Sess_Reset(ByRef s As SessFlow, ByVal act As Long)
Declare Sub Sess_Begin(ByRef s As SessFlow, ByVal totalSec As Single, ByVal chime As Long = 1)
Declare Sub Sess_Tick(ByRef s As SessFlow)
Declare Sub Sess_Finish(ByRef s As SessFlow, ByVal completed As Long, ByVal chime As Long = 1)
' leaving the screen: an unfinished session is recorded as practice time (not "completed")
Declare Sub Sess_Leave(ByRef s As SessFlow)
' optional rating row in an intro panel; returns the height used
Declare Function Sess_BeforeRating(ByRef s As SessFlow, ByVal x As Long, ByVal y As Long, ByVal w As Long) As Long
Declare Function Sess_BeforeRatingH() As Long
' bottom control bar while running: returns 1 when the user chose to finish
Declare Function Sess_Controls(ByRef s As SessFlow, ByVal showNatural As Long) As Long
Declare Function Sess_ControlsH() As Long
' soft progress line + "about N minutes left"
Declare Sub Sess_Progress(ByRef s As SessFlow, ByVal y As Long)
' end panel: returns 1 = again, 2 = back to the list
Declare Function Sess_DonePanel(ByRef s As SessFlow, ByRef extra As String) As Long
Declare Function Sess_Minutes(ByVal configured As Long) As Long   ' shorter in child mode
Declare Sub Sess_FavButton(ByRef s As SessFlow, ByVal x As Long, ByVal y As Long, ByVal w As Long)
