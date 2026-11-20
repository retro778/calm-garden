' deps: src/progress.bas
' test_progress.bas - sessions, totals, daily chart data, favourites, gratitude, deletion, privacy switch
#include once "../src/progress.bi"
#include once "testutil.bi"

Dim As String dir_ = Test_TempDir("progress")
Kill dir_ & "/progress.txt"
Progress_Init(dir_)
Check(Progress_Count() = 0, "starts empty")
Check(Progress_TopAct() = "", "no top activity yet")

Progress_AddSession("flower", 180, 2, 4, 1, "2026-11-18 09:30")
Progress_AddSession("flower", 120, 0, 0, 1, "2026-11-19 20:00")
Progress_AddSession("clouds", 300, 3, 0, 0, "2026-11-20 10:15")
Progress_AddSession("timer", 3, 0, 0, 1, "2026-11-20 10:20")      ' too short: ignored
Progress_AddSession("bad|key", 60, 9, -2, 5, "2026-11-20 11:00")    ' sanitised and clamped
Check(Progress_Count() = 4, "short sessions are not recorded")
Check(Progress_TotalMinutes() = 11, "total minutes (" & Progress_TotalMinutes() & ")")
Check(Progress_CompletedCount() = 3, "completed count")
Check(Progress_TopAct() = "flower", "favourite by practice")
Dim As SessionRec r = Progress_Get(3)
Check(r.act = "bad key" AndAlso r.before = 0 AndAlso r.after = 0 AndAlso r.completed = 1, "fields sanitised")

' reload from disk
Progress_Init(dir_)
Check(Progress_Count() = 4, "reloaded")
Dim As Single mins(Any), ab(Any), aa(Any)
Dim As String labels(Any)
Progress_Daily(7, mins(), ab(), aa(), labels(), "2026-11-20")
Check(labels(6) = "2026-11-20" AndAlso labels(0) = "2026-11-14", "7-day labels")
Check(Abs(mins(4) - 3) < 0.01 AndAlso Abs(mins(5) - 2) < 0.01 AndAlso Abs(mins(6) - 6) < 0.01, "daily minutes")
Check(ab(4) = 2 AndAlso aa(4) = 4 AndAlso ab(6) = 3 AndAlso aa(6) = 0, "daily subjective ratings")
Check(Progress_StreakDays("2026-11-20") = 3, "three-day streak")
Check(Progress_StreakDays("2026-11-21") = 3, "streak survives a day not yet practised")
Check(Progress_StreakDays("2026-11-23") = 0, "streak ends")
Check(Progress_DayAdd("2026-12-31", 1) = "2027-01-01", "date arithmetic")

' favourites & gratitude
Progress_ToggleFav("star")
Check(Progress_IsFav("star"), "favourite added")
Progress_AddGratitude("The sun was warm | today" & Chr(10))
Progress_AddGratitude("השמש הייתה נעימה")
Progress_Init(dir_)
Check(Progress_IsFav("star"), "favourite persisted")
Check(Progress_GratitudeCount() = 2, "gratitude persisted")
Check(Progress_Gratitude(0) = "The sun was warm   today", "gratitude sanitised (" & Progress_Gratitude(0) & ")")
Check(Progress_Gratitude(1) = "השמש הייתה נעימה", "Hebrew gratitude kept")
Progress_ToggleFav("star")
Check(Not Progress_IsFav("star"), "favourite removed")

' corrupted lines are skipped
Dim As Long fh = FreeFile
Open dir_ & "/progress.txt" For Append As #fh
Print #fh, "S|not a date|flower|60|0|0|1"
Print #fh, "S|2026-11-20 12:00|flower|99999999|0|0|1"
Print #fh, "random text"
Print #fh, "S|2026-11-20 12:30|ocean|60|1|5|1"
Close #fh
Progress_Init(dir_)
Check(Progress_Count() = 5, "bad lines skipped, good line kept (" & Progress_Count() & ")")

' privacy switch: nothing new is written
Progress_SetTracking(0)
Progress_AddSession("star", 120, 0, 0, 1)
Progress_SetTracking(1)
Progress_Init(dir_)
Check(Progress_Count() = 5, "tracking off records nothing")

Progress_DeleteAll()
Check(Progress_Count() = 0 AndAlso Progress_GratitudeCount() = 0, "delete all")
Progress_Init(dir_)
Check(Progress_Count() = 0, "deleted on disk")
End Test_Finish("test_progress")
