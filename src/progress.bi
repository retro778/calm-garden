' progress.bi - local practice history (plain UTF-8 text file in the data folder).
'
' Stored: date/time, activity, practice seconds, completed flag, and the
' OPTIONAL self-reported "how do you feel" ratings (1..5, 0 = not given).
' Nothing identifying is stored; there is no network code anywhere.
' Completing an exercise is NOT evidence of reduced physiological stress, and
' the ratings are subjective impressions only.
#pragma once

Type SessionRec
    stamp As String        ' "YYYY-MM-DD HH:MM"
    act As String          ' activity key (app_state.bas)
    seconds As Long
    before As Long         ' 0 = not rated
    after As Long
    completed As Long
End Type

Declare Sub Progress_Init(ByRef dataDir As String)
Declare Sub Progress_SetTracking(ByVal onOff As Long)
Declare Function Progress_Tracking() As Long
Declare Function Progress_Reload() As Boolean
Declare Sub Progress_AddSession(ByRef act As String, ByVal seconds As Long, ByVal before As Long, ByVal after As Long, ByVal completed As Long, ByRef stamp As String = "")
Declare Function Progress_Count() As Long
Declare Function Progress_Get(ByVal i As Long) As SessionRec
Declare Function Progress_CompletedCount() As Long
Declare Function Progress_TotalMinutes() As Long
Declare Function Progress_ActCount(ByRef act As String) As Long
' most practised activity key ("" when none)
Declare Function Progress_TopAct() As String
' totals for the last nDays days, oldest first; avgBefore/avgAfter are 0 when no ratings that day
Declare Sub Progress_Daily(ByVal nDays As Long, minutes() As Single, avgBefore() As Single, avgAfter() As Single, labels() As String, ByRef today As String = "")
Declare Function Progress_StreakDays(ByRef today As String = "") As Long
Declare Function Progress_IsFav(ByRef act As String) As Boolean
Declare Sub Progress_ToggleFav(ByRef act As String)
Declare Sub Progress_AddGratitude(ByRef txt As String)
Declare Function Progress_GratitudeCount() As Long
Declare Function Progress_Gratitude(ByVal i As Long) As String
Declare Sub Progress_RemoveGratitude(ByVal i As Long)
' completed sessions in total (drives the Zen Garden's growth)
Declare Function Progress_GardenLevel() As Long
Declare Sub Progress_DeleteAll()
Declare Function Progress_Now() As String
Declare Function Progress_DayAdd(ByRef ymd As String, ByVal days As Long) As String
Declare Function Progress_Clean(ByRef s As String) As String
