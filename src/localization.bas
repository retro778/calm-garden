' localization.bas - see localization.bi
#include once "localization.bi"

Type LocTable
    keys(Any) As String
    vals(Any) As String
    n As Long
    hashIdx(0 To 4095) As Long     ' open addressing: index+1, 0 = empty
End Type

Dim Shared As LocTable gCur, gEn
Dim Shared As String gCode
Dim Shared As Long gRtl, gChild, gMissing

Private Function H(ByRef s As String) As ULong
    Dim As ULong v = 2166136261
    For i As Long = 0 To Len(s) - 1
        v = (v Xor s[i]) * 16777619
    Next
    Return v
End Function

Private Sub TblClear(ByRef t As LocTable)
    ReDim t.keys(0 To 255)
    ReDim t.vals(0 To 255)
    t.n = 0
    For i As Long = 0 To 4095: t.hashIdx(i) = 0: Next
End Sub

Private Function TblFind(ByRef t As LocTable, ByRef k As String) As Long
    Dim As Long slot = H(k) And 4095
    While t.hashIdx(slot) <> 0
        If t.keys(t.hashIdx(slot) - 1) = k Then Return t.hashIdx(slot) - 1
        slot = (slot + 1) And 4095
    Wend
    Return -1
End Function

Private Sub TblSet(ByRef t As LocTable, ByRef k As String, ByRef v As String)
    Dim As Long i = TblFind(t, k)
    If i >= 0 Then t.vals(i) = v: Exit Sub
    If t.n >= 4000 Then Exit Sub
    If t.n > UBound(t.keys) Then
        ReDim Preserve t.keys(0 To t.n * 2)
        ReDim Preserve t.vals(0 To t.n * 2)
    End If
    t.keys(t.n) = k: t.vals(t.n) = v
    Dim As Long slot = H(k) And 4095
    While t.hashIdx(slot) <> 0: slot = (slot + 1) And 4095: Wend
    t.hashIdx(slot) = t.n + 1
    t.n += 1
End Sub

Private Function Unescape(ByRef s As String) As String
    Dim As String r
    Dim As Long i = 1
    While i <= Len(s)
        Dim As String c = Mid(s, i, 1)
        If c = "\" AndAlso i < Len(s) Then
            Dim As String d = Mid(s, i + 1, 1)
            If d = "n" Then
                r &= !"\n": i += 2: Continue While
            ElseIf d = "\" Then
                r &= "\": i += 2: Continue While
            End If
        End If
        r &= c
        i += 1
    Wend
    Return r
End Function

Private Function LoadFile(ByRef t As LocTable, ByRef path As String) As Boolean
    TblClear(t)
    Dim As Long fh = FreeFile
    If Open(path For Input As #fh) <> 0 Then Return False
    Dim As String ln
    Dim As Long first = 1
    While Not EOF(fh)
        Line Input #fh, ln
        If first Then
            ' skip a UTF-8 byte order mark
            If Left(ln, 3) = Chr(&hEF, &hBB, &hBF) Then ln = Mid(ln, 4)
            first = 0
        End If
        Dim As String tl = Trim(ln, Any !" \t\r")
        If Len(tl) = 0 OrElse Left(tl, 1) = "#" Then Continue While
        Dim As Long p = InStr(tl, "=")
        If p = 0 Then Continue While
        Dim As String k = Trim(Left(tl, p - 1), Any !" \t")
        Dim As String v = Trim(Mid(tl, p + 1), Any !" \t")
        If Len(k) Then TblSet(t, k, Unescape(v))
    Wend
    Close #fh
    Return True
End Function

Function Loc_Load(ByRef langDir As String, ByRef code As String) As Boolean
    LoadFile(gEn, langDir & "/en.txt")
    Dim As Boolean ok = True
    ok = LoadFile(gCur, langDir & "/" & code & ".txt")
    If ok Then
        gCode = code
    Else
        LoadFile(gCur, langDir & "/en.txt")
        gCode = "en"
    End If
    Dim As Long i = TblFind(gCur, "_dir")
    gRtl = IIf(i >= 0 AndAlso LCase(gCur.vals(i)) = "rtl", 1, 0)
    gMissing = 0
    Return ok
End Function

Sub Loc_SetChild(ByVal onOff As Long)
    gChild = IIf(onOff, 1, 0)
End Sub

Function Loc_Has(ByRef key As String) As Boolean
    Return TblFind(gCur, key) >= 0
End Function

Function L(ByRef key As String) As String
    Dim As Long i
    If gChild Then
        i = TblFind(gCur, key & ".child")
        If i >= 0 Then Return gCur.vals(i)
    End If
    i = TblFind(gCur, key)
    If i >= 0 Then Return gCur.vals(i)
    If gChild Then
        i = TblFind(gEn, key & ".child")
        If i >= 0 Then Return gEn.vals(i)
    End If
    i = TblFind(gEn, key)
    gMissing += 1
    If i >= 0 Then Return gEn.vals(i)
    Return key
End Function

Function Loc_F(ByRef key As String, ByRef a1 As String = "", ByRef a2 As String = "", ByRef a3 As String = "") As String
    Dim As String s = L(key)
    Dim As String args(1 To 3) = {a1, a2, a3}
    For k As Long = 1 To 3
        Dim As String tag = "{" & k & "}"
        Dim As Long p = InStr(s, tag)
        While p > 0
            s = Left(s, p - 1) & args(k) & Mid(s, p + Len(tag))
            p = InStr(p + Len(args(k)), s, tag)
        Wend
    Next
    Return s
End Function

Function Loc_IsRTL() As Boolean
    Return gRtl <> 0
End Function

Function Loc_Code() As String
    Return gCode
End Function

Function Loc_Count() As Long
    Return gCur.n
End Function

Function Loc_KeyAt(ByVal i As Long) As String
    If i < 0 OrElse i >= gCur.n Then Return ""
    Return gCur.keys(i)
End Function

Function Loc_MissingCount() As Long
    Return gMissing
End Function
