' screens.bi - one *_Frame() per screen, called every frame by main.bas.
' gApp.entering is 1 on the first frame after App_Go().
#pragma once
#include once "ui.bi"

Declare Sub Menu_Frame()
Declare Sub About_Frame()
Declare Sub SettingsScr_Frame()
Declare Sub BreathList_Frame()
Declare Sub Breath_Frame()
Declare Sub RelaxList_Frame()
Declare Sub Relax_Frame()
Declare Sub MindList_Frame()
Declare Sub Mind_Frame()
Declare Sub Bio_Frame()
Declare Sub GameList_Frame()
Declare Sub Game_Frame()
Declare Sub Timer_Frame()
Declare Sub ProgressScr_Frame()

' shared helpers (menu.bas)
Declare Sub Scr_Background()
Declare Function Scr_Section(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal doDraw As Long = 1) As Long
' a grid of activity tiles; returns the index chosen or -1
Declare Function Scr_TileGrid(ByRef idPrefix As String, labels() As String, icons() As Long, tints() As ULong, ByVal n As Long, ByVal cols As Long, ByVal top As Long, descs() As String) As Long
' "how do you feel?" 1..5 rating row (optional, self-reported); returns the value picked or 0
Declare Function Scr_RatingRow(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef current As Long) As Long
Declare Sub Scr_DrawRatingFace(ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal v As Long, ByVal col As ULong)
