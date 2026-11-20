' deps: src/localization.bas
' test_localization.bas - both language files load, have the same keys, RTL flags, formatting
#include once "../src/localization.bi"
#include once "testutil.bi"

Dim As String langDir = ExePath() & "/../assets/lang"
Check(Loc_Load(langDir, "en"), "English loads")
Check(Not Loc_IsRTL(), "English is left-to-right")
Dim As Long nEn = Loc_Count()
Check(nEn > 100, "English has many strings (" & nEn & ")")
Dim As String enKeys(0 To nEn - 1)
For i As Long = 0 To nEn - 1: enKeys(i) = Loc_KeyAt(i): Next
Check(L("sim.banner") = "Simulation only — no physiological sensors connected.", "mandatory simulation label text")

Check(Loc_Load(langDir, "he"), "Hebrew loads")
Check(Loc_IsRTL(), "Hebrew is right-to-left")
Dim As Long missing = 0
For i As Long = 0 To nEn - 1
    If Not Loc_Has(enKeys(i)) Then missing += 1: Print "  missing in he.txt: " & enKeys(i)
Next
Check(missing = 0, "every English key is translated")
Dim As Long extra = 0
Dim As Long nHe = Loc_Count()
For i As Long = 0 To nHe - 1
    Dim As String k = Loc_KeyAt(i)
    Dim As Long found = 0
    For j As Long = 0 To nEn - 1
        If enKeys(j) = k Then found = 1: Exit For
    Next
    If found = 0 Then extra += 1: Print "  only in he.txt: " & k
Next
Check(extra = 0, "no Hebrew-only keys")
Check(InStr(L("sim.banner"), "הדמיה") > 0, "Hebrew simulation label")

' fallbacks, formatting, child overrides
Check(L("no.such.key") = "no.such.key", "unknown key shows the key")
Check(Not Loc_Load(langDir, "xx"), "unknown language fails")
Check(Loc_Code() = "en", "unknown language falls back to English")
Check(Loc_F("prog.sessions", "7") <> L("prog.sessions"), "Loc_F fills {1}")
Loc_SetChild(1)
Dim As String adult, child
Loc_SetChild(0): adult = L("app.tagline")
Loc_SetChild(1): child = L("app.tagline")
Check(adult <> child, "child-friendly override used")
Loc_SetChild(0)

' every value is valid UTF-8
Dim As Long badUtf = 0
For pass As Long = 0 To 1
    Loc_Load(langDir, IIf(pass = 0, "en", "he"))
    For i As Long = 0 To Loc_Count() - 1
        Dim As String v = L(Loc_KeyAt(i))
        Dim As Long k = 0
        While k < Len(v)
            Dim As Long c = v[k], need = 0
            If c < &h80 Then
                need = 0
            ElseIf (c And &hE0) = &hC0 Then
                need = 1
            ElseIf (c And &hF0) = &hE0 Then
                need = 2
            ElseIf (c And &hF8) = &hF0 Then
                need = 3
            Else
                badUtf += 1: Exit While
            End If
            For m As Long = 1 To need
                If k + m >= Len(v) OrElse (v[k + m] And &hC0) <> &h80 Then badUtf += 1: Exit While
            Next
            k += need + 1
        Wend
    Next
Next
Check(badUtf = 0, "all strings are valid UTF-8")
End Test_Finish("test_localization")
