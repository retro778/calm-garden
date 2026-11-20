' progress.bas - see progress.bi
' File format (progress.txt), one record per line, fields separated by "|":
'   S|YYYY-MM-DD HH:MM|activity|seconds|before|after|completed
'   F|activity                      (favourite)
'   G|YYYY-MM-DD|text               (gratitude note)
#include once "progress.bi"
#include once "datetime.bi"

Dim Shared As String pDir, pFile
Dim Shared As Long pTrack = 1
Dim Shared As SessionRec pS(Any)
Dim Shared As Long pN
Dim Shared As String pFav(Any)
Dim Shared As Long pFavN
Dim Shared As String pGrat(Any), pGratDate(Any)
Dim Shared As Long pGratN

Function Progress_Clean(ByRef s As String) As String
    Dim As String r = s
    For i As Long = 0 To Len(r) - 1
        If r[i] = Asc("|") OrElse r[i] < 32 Then r[i] = 32
    Next
    Return Trim(r)
End Function

Private Function Pad2(ByVal v As Long) As String
    Return Right("0" & v, 2)
End Function

Function Progress_Now() As String
    Dim As Double n = Now()
    Return Year(n) & "-" & Pad2(Month(n)) & "-" & Pad2(Day(n)) & " " & Pad2(Hour(n)) & ":" & Pad2(Minute(n))
End Function

Function Progress_DayAdd(ByRef ymd As String, ByVal days As Long) As String
    Dim As Double d = DateSerial(ValInt(Left(ymd, 4)), ValInt(Mid(ymd, 6, 2)), ValInt(Mid(ymd, 9, 2))) + days
    Return Year(d) & "-" & Pad2(Month(d)) & "-" & Pad2(Day(d))
End Function

Private Function SplitBar(ByRef s As String, f() As String) As Long
    Dim As Long n = 0, p = 1
    ReDim f(0 To 7)
    Do
        Dim As Long q = InStr(p, s, "|")
        If n > 7 Then Exit Do
        If q = 0 Then f(n) = Mid(s, p): n += 1: Exit Do
        f(n) = Mid(s, p, q - p): n += 1
        p = q + 1
    Loop
    Return n
End Function

Private Function ValidStamp(ByRef s As String) As Boolean
    If Len(s) < 10 Then Return False
    If Mid(s, 5, 1) <> "-" OrElse Mid(s, 8, 1) <> "-" Then Return False
    Dim As Long y = ValInt(Left(s, 4)), m = ValInt(Mid(s, 6, 2)), d = ValInt(Mid(s, 9, 2))
    Return y >= 2000 AndAlso y <= 2200 AndAlso m >= 1 AndAlso m <= 12 AndAlso d >= 1 AndAlso d <= 31
End Function

Private Sub ClearAll()
    pN = 0: pFavN = 0: pGratN = 0
    ReDim pS(0 To 63)
    ReDim pFav(0 To 15)
    ReDim pGrat(0 To 31)
    ReDim pGratDate(0 To 31)
End Sub

Private Sub PushSession(ByRef r As SessionRec)
    If pN > UBound(pS) Then ReDim Preserve pS(0 To pN * 2)
    pS(pN) = r
    pN += 1
End Sub

Function Progress_Reload() As Boolean
    ClearAll()
    Dim As Long fh = FreeFile
    If Open(pFile For Input As #fh) <> 0 Then Return False
    Dim As String ln
    Dim As String f(Any)
    While Not EOF(fh)
        Line Input #fh, ln
        ln = RTrim(ln, Any !"\r\n")
        Dim As Long n = SplitBar(ln, f())
        If n < 2 Then Continue While
        Select Case f(0)
        Case "S"
            If n < 7 OrElse Not ValidStamp(f(1)) Then Continue While
            Dim As SessionRec r
            r.stamp = f(1): r.act = f(2)
            r.seconds = ValInt(f(3)): r.before = ValInt(f(4)): r.after = ValInt(f(5)): r.completed = ValInt(f(6))
            If r.seconds < 0 OrElse r.seconds > 24 * 3600 Then Continue While
            If r.before < 0 OrElse r.before > 5 Then r.before = 0
            If r.after < 0 OrElse r.after > 5 Then r.after = 0
            r.completed = IIf(r.completed <> 0, 1, 0)
            PushSession(r)
        Case "F"
            If Not Progress_IsFav(f(1)) Then
                If pFavN > UBound(pFav) Then ReDim Preserve pFav(0 To pFavN * 2)
                pFav(pFavN) = f(1): pFavN += 1
            End If
        Case "G"
            If n >= 3 AndAlso Len(f(2)) Then
                If pGratN > UBound(pGrat) Then ReDim Preserve pGrat(0 To pGratN * 2): ReDim Preserve pGratDate(0 To pGratN * 2)
                pGrat(pGratN) = f(2): pGratDate(pGratN) = f(1): pGratN += 1
            End If
        End Select
    Wend
    Close #fh
    Return True
End Function

Private Sub SaveAll()
    If pTrack = 0 Then Exit Sub
    Dim As String tmp = pFile & ".tmp"
    Dim As Long fh = FreeFile
    If Open(tmp For Output As #fh) <> 0 Then Exit Sub
    Print #fh, "# Calm Garden practice history - stays on this computer. Delete this file to forget it."
    For i As Long = 0 To pN - 1
        With pS(i)
            Print #fh, "S|" & .stamp & "|" & .act & "|" & .seconds & "|" & .before & "|" & .after & "|" & .completed
        End With
    Next
    For i As Long = 0 To pFavN - 1
        Print #fh, "F|" & pFav(i)
    Next
    For i As Long = 0 To pGratN - 1
        Print #fh, "G|" & pGratDate(i) & "|" & pGrat(i)
    Next
    Close #fh
    Kill pFile
    Name(tmp, pFile)
End Sub

Sub Progress_Init(ByRef dataDir As String)
    pDir = dataDir
    pFile = dataDir & "/progress.txt"
    Progress_Reload()
End Sub

Sub Progress_SetTracking(ByVal onOff As Long)
    pTrack = IIf(onOff, 1, 0)
End Sub

Function Progress_Tracking() As Long
    Return pTrack
End Function

Sub Progress_AddSession(ByRef act As String, ByVal seconds As Long, ByVal before As Long, ByVal after As Long, ByVal completed As Long, ByRef stamp As String = "")
    If pTrack = 0 Then Exit Sub
    If seconds < 5 Then Exit Sub         ' a glance is not a session
    Dim As SessionRec r
    r.stamp = IIf(Len(stamp), stamp, Progress_Now())
    r.act = Progress_Clean(act)
    r.seconds = seconds
    r.before = IIf(before >= 1 AndAlso before <= 5, before, 0)
    r.after = IIf(after >= 1 AndAlso after <= 5, after, 0)
    r.completed = IIf(completed, 1, 0)
    PushSession(r)
    SaveAll()
End Sub

Function Progress_Count() As Long
    Return pN
End Function

Function Progress_Get(ByVal i As Long) As SessionRec
    Dim As SessionRec r
    If i >= 0 AndAlso i < pN Then r = pS(i)
    Return r
End Function

Function Progress_CompletedCount() As Long
    Dim As Long c = 0
    For i As Long = 0 To pN - 1
        If pS(i).completed Then c += 1
    Next
    Return c
End Function

Function Progress_TotalMinutes() As Long
    Dim As LongInt s = 0
    For i As Long = 0 To pN - 1: s += pS(i).seconds: Next
    Return CLng(s \ 60)
End Function

Function Progress_ActCount(ByRef act As String) As Long
    Dim As Long c = 0
    For i As Long = 0 To pN - 1
        If pS(i).act = act Then c += 1
    Next
    Return c
End Function

Function Progress_TopAct() As String
    Dim As String best
    Dim As Long bestN = 0
    For i As Long = 0 To pN - 1
        Dim As Long c = Progress_ActCount(pS(i).act)
        If c > bestN Then bestN = c: best = pS(i).act
    Next
    Return best
End Function

Sub Progress_Daily(ByVal nDays As Long, minutes() As Single, avgBefore() As Single, avgAfter() As Single, labels() As String, ByRef today As String = "")
    Dim As String t0 = IIf(Len(today), Left(today, 10), Left(Progress_Now(), 10))
    ReDim minutes(0 To nDays - 1)
    ReDim avgBefore(0 To nDays - 1)
    ReDim avgAfter(0 To nDays - 1)
    ReDim labels(0 To nDays - 1)
    Dim As Long nb(0 To nDays - 1), na(0 To nDays - 1)
    For k As Long = 0 To nDays - 1
        labels(k) = Progress_DayAdd(t0, k - (nDays - 1))
    Next
    For i As Long = 0 To pN - 1
        Dim As String d = Left(pS(i).stamp, 10)
        For k As Long = 0 To nDays - 1
            If labels(k) = d Then
                minutes(k) += pS(i).seconds / 60.0
                If pS(i).before Then avgBefore(k) += pS(i).before: nb(k) += 1
                If pS(i).after Then avgAfter(k) += pS(i).after: na(k) += 1
                Exit For
            End If
        Next
    Next
    For k As Long = 0 To nDays - 1
        If nb(k) Then avgBefore(k) /= nb(k)
        If na(k) Then avgAfter(k) /= na(k)
    Next
End Sub

' consecutive days (ending today or yesterday) with at least one session
Function Progress_StreakDays(ByRef today As String = "") As Long
    Dim As String d = IIf(Len(today), Left(today, 10), Left(Progress_Now(), 10))
    Dim As Long streak = 0, k = 0
    Do
        Dim As String day_ = Progress_DayAdd(d, -k)
        Dim As Long found = 0
        For i As Long = 0 To pN - 1
            If Left(pS(i).stamp, 10) = day_ Then found = 1: Exit For
        Next
        If found = 0 Then
            If k = 0 Then k += 1: Continue Do     ' nothing yet today is fine
            Exit Do
        End If
        streak += 1
        k += 1
    Loop While k < 3660
    Return streak
End Function

Function Progress_IsFav(ByRef act As String) As Boolean
    For i As Long = 0 To pFavN - 1
        If pFav(i) = act Then Return True
    Next
    Return False
End Function

Sub Progress_ToggleFav(ByRef act As String)
    For i As Long = 0 To pFavN - 1
        If pFav(i) = act Then
            For j As Long = i To pFavN - 2: pFav(j) = pFav(j + 1): Next
            pFavN -= 1
            SaveAll()
            Exit Sub
        End If
    Next
    If pFavN > UBound(pFav) Then ReDim Preserve pFav(0 To pFavN * 2)
    pFav(pFavN) = Progress_Clean(act): pFavN += 1
    SaveAll()
End Sub

Sub Progress_AddGratitude(ByRef txt As String)
    Dim As String t = Progress_Clean(txt)
    If Len(t) = 0 Then Exit Sub
    If pGratN > UBound(pGrat) Then ReDim Preserve pGrat(0 To pGratN * 2): ReDim Preserve pGratDate(0 To pGratN * 2)
    pGrat(pGratN) = t: pGratDate(pGratN) = Left(Progress_Now(), 10)
    pGratN += 1
    SaveAll()
End Sub

Function Progress_GratitudeCount() As Long
    Return pGratN
End Function

Function Progress_Gratitude(ByVal i As Long) As String
    If i < 0 OrElse i >= pGratN Then Return ""
    Return pGrat(i)
End Function

Sub Progress_RemoveGratitude(ByVal i As Long)
    If i < 0 OrElse i >= pGratN Then Exit Sub
    For j As Long = i To pGratN - 2
        pGrat(j) = pGrat(j + 1): pGratDate(j) = pGratDate(j + 1)
    Next
    pGratN -= 1
    SaveAll()
End Sub

Function Progress_GardenLevel() As Long
    Return Progress_CompletedCount()
End Function

Sub Progress_DeleteAll()
    ClearAll()
    Kill pFile
    Kill pFile & ".tmp"
End Sub
