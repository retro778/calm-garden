' testutil.bi - minimal test helpers shared by all test programs
#pragma once

Dim Shared As Long tu_pass, tu_fail

Sub Check(ByVal cond As Boolean, ByRef what As String)
    If cond Then
        tu_pass += 1
    Else
        tu_fail += 1
        Print "FAIL: " & what
    End If
End Sub

Sub CheckEq(ByRef got As String, ByRef want As String, ByRef what As String)
    If got = want Then
        tu_pass += 1
    Else
        tu_fail += 1
        Print "FAIL: " & what & !"\n   got:  " & got & !"\n   want: " & want
    End If
End Sub

Function Test_Finish(ByRef suite As String) As Long
    Print suite & ": " & tu_pass & " passed, " & tu_fail & " failed"
    If tu_fail > 0 Then Return 1
    Return 0
End Function

' A scratch directory inside the build tree (never /tmp, so it also works on Windows)
Function Test_TempDir(ByRef suite As String) As String
    Dim As String d = ExePath() & "/tmp_" & suite
    MkDir(ExePath() & "")
    MkDir(d)
    Return d
End Function
