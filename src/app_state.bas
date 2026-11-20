' app_state.bas - shared state (see app_state.bi)
#include once "app_state.bi"
#include once "localization.bi"
#include once "text.bi"

Dim Shared gApp As AppState
Dim Shared gSet As Settings
Dim Shared gCv As Canvas
Dim Shared gIn As InputState

Sub App_Go(ByVal scr As Long, ByVal arg As Long = 0)
    gApp.prevScr = gApp.scr
    gApp.scr = scr
    gApp.arg = arg
    gApp.entering = 1
    gApp.goSerial += 1
    gApp.scrStart = gApp.now
End Sub

Sub App_SaveSettings()
    Settings_Save(gSet, gApp.dataDir & "/settings.txt")
End Sub

Sub App_ApplyLanguage()
    Loc_Load(gApp.resDir & "/lang", gSet.lang)
    Loc_SetChild(gSet.childMode)
    gApp.rtl = IIf(Loc_IsRTL(), 1, 0)
End Sub

Function App_DirText() As Long
    Return IIf(gApp.rtl, DIR_RTL, DIR_LTR)
End Function

Function App_Motion() As Single
    Return IIf(gSet.reducedMotion, 0.25, 1.0)
End Function

Const ACT_KEYS = ",flower,balloon,ocean,star,pmr,bodyscan,breath_aware,place,bedtime,break5,senses,observe,clouds,gratitude,moments,biofeedback,zen,journey,leaves,night,aquarium,timer,"

Function App_ActKey(ByVal act As Long) As String
    If act < 0 OrElse act >= ACT_COUNT Then Return ""
    Dim As Long p = 1
    For i As Long = 0 To act
        p = InStr(p, ACT_KEYS, ",") + 1
    Next
    Return Mid(ACT_KEYS, p, InStr(p, ACT_KEYS, ",") - p)
End Function

Function App_ActFromKey(ByRef k As String) As Long
    For i As Long = 0 To ACT_COUNT - 1
        If App_ActKey(i) = k Then Return i
    Next
    Return -1
End Function

Function App_ActName(ByVal act As Long) As String
    Return L("act." & App_ActKey(act))
End Function
