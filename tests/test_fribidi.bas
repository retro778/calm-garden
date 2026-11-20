' deps: src/bidi.bas src/localization.bas
' test_fribidi.bas - (Linux only) our UAX #9 reordering must agree with GNU FriBidi
' for every Hebrew interface string and for mixed Hebrew/English/number samples.
#include once "../src/bidi.bi"
#include once "../src/localization.bi"
#include once "testutil.bi"

#ifdef __FB_LINUX__
#inclib "fribidi"
Extern "C"
Declare Function fribidi_log2vis(ByVal s As ULong Ptr, ByVal ln As Long, ByVal pbase As ULong Ptr, ByVal vis As ULong Ptr, ByVal l2v As Long Ptr, ByVal v2l As Long Ptr, ByVal levels As Byte Ptr) As Long
End Extern
Const FRIBIDI_PAR_LTR = &h110
Const FRIBIDI_PAR_RTL = &h111

Function Fri(ByRef s As String, ByVal rtl As Long) As String
    Dim As Long cps(Any)
    Dim As Long n = Utf8_Decode(s, cps())
    If n = 0 Then Return ""
    Dim As ULong src(0 To n - 1), vis(0 To n)
    For i As Long = 0 To n - 1: src(i) = cps(i): Next
    Dim As ULong pb = IIf(rtl, FRIBIDI_PAR_RTL, FRIBIDI_PAR_LTR)
    fribidi_log2vis(@src(0), n, @pb, @vis(0), 0, 0, 0)
    Dim As String r
    For i As Long = 0 To n - 1: r &= Utf8_Encode(vis(i)): Next
    Return r
End Function

Dim As Long nCmp = 0
Sub Cmp(ByRef s As String, ByVal rtl As Long, ByRef what As String)
    Dim As String a = Bidi_VisualString(s, rtl), b = Fri(s, rtl)
    CheckEq(a, b, what & " [" & s & "]")
End Sub

Dim As String samples(0 To 9) = { _
    "שלום world", "Hello עולם!", "גרסה 1.0.0 (חדשה)", "נשימה 4-6 שניות", "Ctrl+Q: יציאה", _
    "15:30 - תרגיל", "‏(א) [ב] {ג}", "abc (דוגמה) def", "100% גודל", "SDL2 ו-SDL2_ttf (רישיון zlib)" }
For i As Long = 0 To 9
    Cmp(samples(i), 1, "sample RTL")
    Cmp(samples(i), 0, "sample LTR")
Next
Loc_Load(ExePath() & "/../assets/lang", "he")
For i As Long = 0 To Loc_Count() - 1
    Dim As String v = L(Loc_KeyAt(i))
    ' compare each line separately (paragraphs)
    Dim As Long p = 1
    Do
        Dim As Long q = InStr(p, v, !"\n")
        Dim As String ln = IIf(q, Mid(v, p, q - p), Mid(v, p))
        If Len(ln) Then Cmp(ln, 1, Loc_KeyAt(i)): nCmp += 1
        If q = 0 Then Exit Do
        p = q + 1
    Loop
Next
Print "compared " & nCmp & " Hebrew interface lines with FriBidi"
#else
Print "test_fribidi: skipped (FriBidi comparison runs on Linux only)"
#endif
End Test_Finish("test_fribidi")
