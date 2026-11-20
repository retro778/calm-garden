' deps: src/audio.bas src/app_state.bas src/settings.bas src/localization.bas src/text.bas src/bidi.bas src/graphics.bas
' test_audio.bas - synthesised sounds: gentle peak levels, seamless loops, works without BASS
#include once "../src/audio.bi"
#include once "../src/app_state.bi"
#include once "testutil.bi"

Settings_Defaults(gSet)
For i As Long = 0 To SND_COUNT - 1
    Dim As String w = Audio_SynthSound(i)
    Check(Left(w, 4) = "RIFF" AndAlso Mid(w, 9, 4) = "WAVE", "sound " & i & " is a WAV")
    Dim As Long pk = Audio_WavPeak(w)
    Check(pk > 1000 AndAlso pk <= 0.4 * 32767, "sound " & i & " has a gentle peak (" & pk & ")")
Next
For i As Long = 0 To AMB_COUNT - 1
    Dim As String w = Audio_SynthAmbient(i, 6)
    Check(Len(w) = 44 + 6 * 22050 * 2, "ambient " & i & " length")
    Dim As Long pk = Audio_WavPeak(w)
    Check(pk > 1000 AndAlso pk <= 0.45 * 32767, "ambient " & i & " peak is moderate (" & pk & ")")
    ' loop seam: last and first samples are close
    Dim As Long a = CShort(w[44] Or (CLng(w[45]) Shl 8)), b = CShort(w[Len(w) - 2] Or (CLng(w[Len(w) - 1]) Shl 8))
    Check(Abs(a - b) < 6000, "ambient " & i & " loops without a click (" & a & " / " & b & ")")
Next
' all calls are safe without BASS
Audio_Play(SND_CHIME)
Audio_SetAmbient(AMB_RAIN)
Check(Not Audio_PlayNarration("en", "pmr_1"), "no narration without audio")
Audio_StopNarration()
Check(Not Audio_Available(), "audio not initialised in the test")
End Test_Finish("test_audio")
