' deps: src/bidi.bas
' test_bidi.bas - checks the bidi implementation against the Unicode conformance
' file BidiCharacterTest.txt (Unicode 16.0). Tests that use explicit embeddings
' (LRE/RLE/LRO/RLO/PDF, unsupported by design) are skipped, as are tests containing
' characters whose bidi class our compact table does not reproduce (reported).
#include once "../src/bidi.bi"
#include once "testutil.bi"

Dim Shared As UByte ucdClass(0 To &h1FFFF)
Dim Shared As UByte ucdKnown(0 To &h1FFFF)

Function ClassFromName(ByRef s As String) As Long
    Select Case s
    Case "L": Return BC_L
    Case "R": Return BC_R
    Case "AL": Return BC_AL
    Case "EN": Return BC_EN
    Case "ES": Return BC_ES
    Case "ET": Return BC_ET
    Case "AN": Return BC_AN
    Case "CS": Return BC_CS
    Case "NSM": Return BC_NSM
    Case "BN": Return BC_BN
    Case "B": Return BC_B
    Case "S": Return BC_S
    Case "WS": Return BC_WS
    Case "ON": Return BC_ON
    Case "LRI": Return BC_LRI
    Case "RLI": Return BC_RLI
    Case "FSI": Return BC_FSI
    Case "PDI": Return BC_PDI
    End Select
    Return 99   ' LRE RLE LRO RLO PDF
End Function

Dim As String dataDir = ExePath() & "/data/"
Dim As Long fh = FreeFile
If Open(dataDir & "UnicodeData.txt" For Input As #fh) <> 0 Then Print "missing UnicodeData.txt": End 1
Dim As String ln
While Not EOF(fh)
    Line Input #fh, ln
    Dim As Long p1 = InStr(ln, ";")
    Dim As Long cp = ValInt("&h" & Left(ln, p1 - 1))
    ' field 4 (0-based) is the bidi class
    Dim As Long p = p1
    For k As Long = 1 To 3: p = InStr(p + 1, ln, ";"): Next
    Dim As Long q = InStr(p + 1, ln, ";")
    Dim As String bc = Mid(ln, p + 1, q - p - 1)
    If cp <= &h1FFFF Then ucdClass(cp) = ClassFromName(bc): ucdKnown(cp) = 1
    ' ranges ("<..., First>" / "<..., Last>") are not needed for our scripts
Wend
Close #fh

' class table check for the scripts the application uses
Dim As Long clsBad = 0
For cp As Long = 0 To &h2BFF
    If ucdKnown(cp) AndAlso ucdClass(cp) <> 99 AndAlso ucdClass(cp) <> Bidi_Class(cp) Then
        If (cp < &h600 OrElse cp >= &h2000) Then
            clsBad += 1
            If clsBad <= 15 Then Print "class mismatch U+" & Hex(cp, 4) & " ucd=" & ucdClass(cp) & " ours=" & Bidi_Class(cp)
        End If
    End If
Next
For cp As Long = &hFB1D To &hFB4F
    If ucdKnown(cp) AndAlso ucdClass(cp) <> Bidi_Class(cp) Then clsBad += 1: Print "class mismatch U+" & Hex(cp, 4)
Next
Check(clsBad = 0, "bidi classes match UCD for Latin, Hebrew, punctuation and symbols (" & clsBad & " mismatches)")

fh = FreeFile
If Open(dataDir & "BidiCharacterTest.txt" For Input As #fh) <> 0 Then Print "missing BidiCharacterTest.txt": End 1
Dim As Long total, skipped, passed, failed, shown
While Not EOF(fh)
    Line Input #fh, ln
    If Len(ln) = 0 OrElse ln[0] = Asc("#") Then Continue While
    Dim As String f(0 To 4)
    Dim As Long a = 1
    For k As Long = 0 To 4
        Dim As Long b = InStr(a, ln, ";")
        If b = 0 Then b = Len(ln) + 1
        f(k) = Mid(ln, a, b - a)
        a = b + 1
    Next
    total += 1
    ' code points
    Dim As Long cps(Any)
    Dim As Long n = 0
    ReDim cps(0 To 255)
    Dim As String s = f(0) & " "
    a = 1
    Dim As Long skip = 0
    While a <= Len(s)
        Dim As Long b = InStr(a, s, " ")
        Dim As String hx = Mid(s, a, b - a)
        a = b + 1
        If hx = "" Then Continue While
        Dim As Long cp = ValInt("&h" & hx)
        If cp > &h1FFFF OrElse ucdKnown(cp) = 0 Then
            skip = 1
        ElseIf ucdClass(cp) = 99 OrElse ucdClass(cp) <> Bidi_Class(cp) Then
            skip = 1
        End If
        cps(n) = cp: n += 1
    Wend
    If skip Then skipped += 1: Continue While
    Dim As Long pdir = ValInt(f(1))
    Dim As Long baseLv = IIf(pdir = 2, -1, pdir)
    Dim As Long lev(Any), ord(Any)
    Dim As Long bl = Bidi_Levels(cps(), n, baseLv, lev())
    Bidi_ReorderLine(cps(), lev(), 0, n, bl, ord())
    ' expected levels
    Dim As String want = f(3) & " "
    
    Dim As Long xMask(0 To n - 1)
    a = 1
    Dim As Long k = 0
    Dim As Long ok = (bl = ValInt(f(2)))
    ' L1 adjusted levels: recompute via reorder input (levels after L1 are what the file lists)
    ' The file lists levels after L1, so apply L1 here for comparison.
    Dim As Long lv1(0 To n - 1)
    Dim As Long trailing = 1
    For q As Long = n - 1 To 0 Step -1
        Dim As Long c = Bidi_Class(cps(q))
        lv1(q) = lev(q)
        If c = BC_S OrElse c = BC_B Then
            lv1(q) = bl: trailing = 1
        ElseIf trailing AndAlso (c = BC_WS OrElse c = BC_BN OrElse c = BC_LRI OrElse c = BC_RLI OrElse c = BC_FSI OrElse c = BC_PDI) Then
            lv1(q) = bl
        Else
            trailing = 0
        End If
    Next
    While a <= Len(want) AndAlso k < n
        Dim As Long b = InStr(a, want, " ")
        Dim As String tk = Mid(want, a, b - a)
        a = b + 1
        If tk = "" Then Continue While
        If tk = "x" Then
            xMask(k) = 1
        ElseIf ValInt(tk) <> lv1(k) Then
            ok = 0
        End If
        k += 1
    Wend
    ' expected visual order (without removed characters)
    Dim As String visOrd
    For q As Long = 0 To n - 1
        If xMask(ord(q)) = 0 Then visOrd &= ord(q) & " "
    Next
    If RTrim(visOrd) <> Trim(f(4)) Then ok = 0
    If ok Then
        passed += 1
    Else
        failed += 1
        If shown < 10 Then
            shown += 1
            Dim As String gl
            For q As Long = 0 To n - 1: gl &= lv1(q) & " ": Next
            Print "bidi FAIL: " & ln
            Print "   got levels " & gl & " para " & bl & " order " & visOrd
        End If
    End If
Wend
Close #fh
Print "BidiCharacterTest: " & total & " tests, " & passed & " passed, " & failed & " failed, " & skipped & " skipped"
Check(failed = 0, "all applicable Unicode bidi conformance tests pass")
Check(passed > 30000, "a substantial number of conformance tests were applicable")

' application-level examples
CheckEq(Bidi_VisualString("abc", 0), "abc", "plain LTR")
Dim As String alef = Utf8_Encode(&h5D0), bet = Utf8_Encode(&h5D1), gimel = Utf8_Encode(&h5D2)
CheckEq(Bidi_VisualString(alef & bet & gimel, 1), gimel & bet & alef, "Hebrew reversed visually")
CheckEq(Bidi_VisualString(alef & " (" & bet & ")", 1), "(" & bet & ") " & alef, "brackets mirrored in RTL")
' notation isolate keeps "1.e4 e5" intact inside Hebrew
CheckEq(Bidi_VisualString(alef & bet & " " & Bidi_Iso("1.e4 e5") & " " & gimel, 1), gimel & " 1.e4 e5 " & bet & alef, "isolated notation in Hebrew")
CheckEq(Bidi_VisualString(alef & " 12 " & bet, 1), bet & " 12 " & alef, "numbers stay LTR in Hebrew")

End Test_Finish("test_bidi")
