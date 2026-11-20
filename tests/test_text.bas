' deps: src/text.bas src/bidi.bas src/graphics.bas
' test_text.bas - SDL2_ttf/HarfBuzz text layout: visual runs, widths, wrapping, ellipsis
#include once "../src/text.bi"
#include once "../src/bidi.bi"
#include once "testutil.bi"

Check(Txt_Init(ExePath() & "/../assets/fonts"), "fonts load: " & Txt_LastError())
' visual runs, left to right
CheckEq(Txt_DebugRuns("hello world", DIR_LTR), "L:hello world", "plain English")
CheckEq(Txt_DebugRuns("שלום עולם", DIR_RTL), "R:שלום עולם", "plain Hebrew is one RTL run (shaped right-to-left)")
CheckEq(Txt_DebugRuns("שלום world", DIR_RTL), "L:world|R:שלום ", "English inside Hebrew")
CheckEq(Txt_DebugRuns("Hello עולם", DIR_LTR), "L:Hello |R:עולם", "Hebrew inside English")
CheckEq(Txt_DebugRuns("גרסה 1.0", DIR_RTL), "L:1.0|R:גרסה ", "numbers stay left-to-right")
' Noto Sans Hebrew has no bracket glyphs: they come from Noto Sans as separate right-to-left
' runs (logical ")" leftmost), which HarfBuzz shapes RTL and therefore mirrors.
CheckEq(Txt_DebugRuns("(שלום)", DIR_RTL), "R:)|R:שלום|R:(", "brackets: RTL runs, mirrored by HarfBuzz")
' widths
Dim As Long w1 = Txt_Width("Calm", FACE_REGULAR, 20, DIR_LTR), w2 = Txt_Width("Calm Garden", FACE_REGULAR, 20, DIR_LTR)
Check(w1 > 20 AndAlso w2 > w1, "widths grow")
Check(Txt_Width("Calm", FACE_REGULAR, 40, DIR_LTR) > w1 * 18 \ 10, "widths scale with size")
Check(Txt_Width("גן השלווה", FACE_BOLD, 24, DIR_RTL) > 50, "Hebrew width")
Check(Txt_LineHeight(FACE_REGULAR, 20) >= 20, "line height")
' wrapping
Dim As String para = "Breathe in slowly through your nose, and breathe out gently. There is no right or wrong way."
Dim As Long h1 = Txt_WrapHeight(para, 2000, FACE_REGULAR, 20, DIR_LTR)
Dim As Long h3 = Txt_WrapHeight(para, 200, FACE_REGULAR, 20, DIR_LTR)
Check(h1 = Txt_LineHeight(FACE_REGULAR, 20), "one line when wide")
Check(h3 >= 3 * h1, "several lines when narrow")
Check(Txt_WrapHeight("שורה אחת" & Chr(10) & "שורה שתיים", 2000, FACE_REGULAR, 20, DIR_RTL) = 2 * h1, "explicit line breaks")
' every wrapped line fits
Dim As String f = Txt_Fit(para, FACE_REGULAR, 20, 150, DIR_LTR)
Check(Txt_Width(f, FACE_REGULAR, 20, DIR_LTR) <= 150 AndAlso Right(f, 3) = Chr(&hE2, &h80, &hA6), "ellipsis fits")
' drawing into a canvas changes pixels
Dim As Canvas cv
Cv_Create(cv, 300, 60)
Cv_Clear(cv, &hFFFFFFFF)
Txt_Draw(cv, 5, 5, "שלום Calm", FACE_REGULAR, 28, &hFF000000, DIR_RTL)
Dim As Long dark = 0
For i As Long = 0 To 300 * 60 - 1
    If (cv.px[i] And &hFF) < 128 Then dark += 1
Next
Check(dark > 100, "text drawn (" & dark & " dark pixels)")
Check(Txt_CacheCount() > 0, "run cache used")
Txt_Shutdown()
End Test_Finish("test_text")
