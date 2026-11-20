' audio.bas - BASS loaded at run time + procedural sound synthesis (see audio.bi)
#include once "audio.bi"
#include once "app_state.bi"

#ifdef __FB_WIN32__
#define BCALL StdCall
#else
#define BCALL Cdecl
#endif

Type FnInit As Function BCALL(ByVal device As Long, ByVal freq As ULong, ByVal flags As ULong, ByVal win As Any Ptr, ByVal guid As Any Ptr) As Long
Type FnFree As Function BCALL() As Long
Type FnSampleLoad As Function BCALL(ByVal mem As Long, ByVal file As Any Ptr, ByVal offset As ULongInt, ByVal length As ULong, ByVal max As ULong, ByVal flags As ULong) As ULong
Type FnSampleGetChannel As Function BCALL(ByVal handle As ULong, ByVal flags As ULong) As ULong
Type FnStreamCreateFile As Function BCALL(ByVal mem As Long, ByVal file As Any Ptr, ByVal offset As ULongInt, ByVal length As ULongInt, ByVal flags As ULong) As ULong
Type FnChannelPlay As Function BCALL(ByVal handle As ULong, ByVal restart As Long) As Long
Type FnChannelStop As Function BCALL(ByVal handle As ULong) As Long
Type FnChannelSetAttribute As Function BCALL(ByVal handle As ULong, ByVal attrib As ULong, ByVal value As Single) As Long
Type FnChannelSlideAttribute As Function BCALL(ByVal handle As ULong, ByVal attrib As ULong, ByVal value As Single, ByVal time_ As ULong) As Long
Type FnChannelIsActive As Function BCALL(ByVal handle As ULong) As ULong
Type FnStreamFree As Function BCALL(ByVal handle As ULong) As Long

Const BASS_ATTRIB_VOL = 2
Const BASS_SAMPLE_LOOP = 4
Const BASS_SAMPLE_OVER_POS = &h30000
Const BASS_UNICODE = &h80000000

Dim Shared As Any Ptr bassLib
Dim Shared As FnInit pInit
Dim Shared As FnFree pFree
Dim Shared As FnSampleLoad pSampleLoad
Dim Shared As FnSampleGetChannel pSampleGetChannel
Dim Shared As FnStreamCreateFile pStreamCreateFile
Dim Shared As FnChannelPlay pChannelPlay
Dim Shared As FnChannelStop pChannelStop
Dim Shared As FnChannelSetAttribute pChannelSetAttribute
Dim Shared As FnChannelSlideAttribute pChannelSlide
Dim Shared As FnChannelIsActive pChannelIsActive
Dim Shared As FnStreamFree pStreamFree

Dim Shared As Long audioOk
Dim Shared As String audioStatus
Dim Shared As String gRes
Dim Shared As ULong sndHandle(0 To SND_COUNT - 1)
Dim Shared As String sndData(0 To SND_COUNT - 1)
Dim Shared As String ambData(0 To AMB_COUNT - 1)
Dim Shared As ULong ambStream, ambOld, narrStream
Dim Shared As Long ambCur = -1

Const RATE = 22050
Const TAU = 6.2831853

' ---------------- synthesis ----------------

Private Function MakeWav(buf() As Single, ByVal n As Long, ByVal peak As Single) As String
    Dim As Single mx = 0.0001
    For i As Long = 0 To n - 1
        If Abs(buf(i)) > mx Then mx = Abs(buf(i))
    Next
    Dim As Single g = peak * 32767 / mx
    Dim As Long dataBytes = n * 2
    Dim As String h = "RIFF" & MKL(36 + dataBytes) & "WAVE" & "fmt " & MKL(16) & MKShort(1) & MKShort(1) & MKL(RATE) & MKL(RATE * 2) & MKShort(2) & MKShort(16) & "data" & MKL(dataBytes)
    Dim As String body = Space(dataBytes)
    For i As Long = 0 To n - 1
        Dim As Long v = CLng(buf(i) * g)
        If v > 32767 Then v = 32767
        If v < -32768 Then v = -32768
        body[i * 2] = v And 255
        body[i * 2 + 1] = (v Shr 8) And 255
    Next
    Return h & body
End Function

Function Audio_WavPeak(ByRef wav As String) As Long
    Dim As Long mx = 0
    For i As Long = 44 To Len(wav) - 2 Step 2
        Dim As Long v = wav[i] Or (CLng(wav[i + 1]) Shl 8)
        If v >= 32768 Then v -= 65536
        If Abs(v) > mx Then mx = Abs(v)
    Next
    Return mx
End Function

Type Rng
    s As ULong
End Type

Private Function RndF(ByRef r As Rng) As Single     ' -1 .. 1
    r.s = r.s * 1664525 + 1013904223
    Return ((r.s Shr 8) And &hFFFF) / 32768.0 - 1
End Function

Private Function Rnd01(ByRef r As Rng) As Single
    Return (RndF(r) + 1) * 0.5
End Function

' bell: inharmonic partials with exponential decay
Private Sub AddBell(buf() As Single, ByVal t0 As Single, ByVal freq As Single, ByVal amp As Single, ByVal decay As Single)
    Dim As Single parts(0 To 3) = {1.0, 2.76, 5.4, 8.93}
    Dim As Single pamp(0 To 3) = {1.0, 0.45, 0.22, 0.1}
    Dim As Long s0 = CLng(t0 * RATE)
    For i As Long = s0 To UBound(buf)
        Dim As Single t = (i - s0) / RATE
        Dim As Single env = Exp(-t * decay)
        If env < 0.0005 Then Exit For
        If i - s0 < 220 Then env *= (i - s0) / 220.0
        Dim As Single v = 0
        For k As Long = 0 To 3
            v += Sin(TAU * freq * parts(k) * t) * pamp(k) * Exp(-t * decay * k * 0.6)
        Next
        buf(i) += v * amp * env
    Next
End Sub

Private Sub AddTone(buf() As Single, ByVal t0 As Single, ByVal dur As Single, ByVal f0 As Single, ByVal f1 As Single, ByVal amp As Single)
    Dim As Long s0 = CLng(t0 * RATE), n = CLng(dur * RATE)
    Dim As Single ph = 0
    For i As Long = 0 To n - 1
        If s0 + i > UBound(buf) Then Exit For
        Dim As Single f = i / n
        Dim As Single env = Sin(f * 3.14159)       ' smooth swell, no clicks
        ph += TAU * (f0 + (f1 - f0) * f) / RATE
        buf(s0 + i) += (Sin(ph) + 0.25 * Sin(ph * 2)) * amp * env * env
    Next
End Sub

Function Audio_SynthSound(ByVal id As Long) As String
    Dim As Single buf(Any)
    Dim As Single peak = 0.35
    Select Case id
    Case SND_CLICK
        ReDim buf(0 To CLng(0.08 * RATE))
        AddTone(buf(), 0, 0.07, 880, 760, 1)
        peak = 0.12
    Case SND_CHIME
        ReDim buf(0 To CLng(3.5 * RATE))
        AddBell(buf(), 0, 528, 1, 1.4)
        peak = 0.38
    Case SND_CHIME_END
        ReDim buf(0 To CLng(4.5 * RATE))
        AddBell(buf(), 0, 528, 1, 1.4)
        AddBell(buf(), 0.9, 396, 0.9, 1.2)
        peak = 0.38
    Case SND_IN
        ReDim buf(0 To CLng(1.2 * RATE))
        AddTone(buf(), 0, 1.2, 330, 440, 1)
        peak = 0.12
    Case SND_OUT
        ReDim buf(0 To CLng(1.2 * RATE))
        AddTone(buf(), 0, 1.2, 440, 294, 1)
        peak = 0.12
    Case SND_SPARKLE
        ReDim buf(0 To CLng(2.2 * RATE))
        AddBell(buf(), 0, 784, 0.6, 2.5)
        AddBell(buf(), 0.15, 988, 0.5, 2.5)
        AddBell(buf(), 0.3, 1175, 0.45, 2.5)
        peak = 0.25
    Case SND_POP
        ReDim buf(0 To CLng(0.25 * RATE))
        AddTone(buf(), 0, 0.2, 300, 720, 1)
        peak = 0.15
    Case Else
        ReDim buf(0 To 100)
    End Select
    Return MakeWav(buf(), UBound(buf) + 1, peak)
End Function

' one-pole low-pass helper
#define LP(state, x, k) state += ((x) - state) * (k)

Function Audio_SynthAmbient(ByVal id As Long, ByVal seconds As Single) As String
    Dim As Long n = CLng(seconds * RATE)
    Dim As Long fade = RATE * 2            ' cross-fade for a seamless loop
    Dim As Long total = n + fade
    Dim As Single buf(0 To total - 1)
    Dim As Rng r
    r.s = 1234 + id * 9871
    Dim As Single a = 0, b = 0, c = 0, d = 0
    Select Case id
    Case AMB_RAIN
        For i As Long = 0 To total - 1
            Dim As Single x = RndF(r)
            LP(a, x, 0.5)
            LP(b, a, 0.08)
            Dim As Single hiss = a - b                       ' band of soft noise
            buf(i) = hiss * (0.8 + 0.2 * Sin(i / RATE * 0.7))
        Next
        ' drops
        For k As Long = 0 To CLng(seconds * 14)
            Dim As Long p = CLng(Rnd01(r) * (total - 400))
            Dim As Single amp = 0.2 + Rnd01(r) * 0.5
            Dim As Single f = 1800 + Rnd01(r) * 2400
            For j As Long = 0 To 300
                buf(p + j) += Sin(TAU * f * j / RATE) * amp * Exp(-j / 45.0)
            Next
        Next
    Case AMB_OCEAN
        For i As Long = 0 To total - 1
            Dim As Single t = i / RATE
            Dim As Single x = RndF(r)
            LP(a, x, 0.06)
            LP(b, a, 0.15)
            Dim As Single sw = 0.5 - 0.5 * Cos(TAU * t / (seconds / 2))   ' two waves per loop
            buf(i) = b * (0.15 + 0.85 * sw * sw)
        Next
    Case AMB_WIND
        For i As Long = 0 To total - 1
            Dim As Single t = i / RATE
            Dim As Single x = RndF(r)
            ' state-variable band-pass with a slowly moving centre
            Dim As Single fc = 250 + 180 * Sin(TAU * t / seconds * 2) + 80 * Sin(TAU * t / seconds * 5)
            Dim As Single f = 2 * Sin(3.14159 * fc / RATE)
            Dim As Single hp = x - a - 0.6 * b
            b += f * hp
            a += f * b
            buf(i) = b * (0.6 + 0.4 * Sin(TAU * t / seconds * 3))
        Next
    Case AMB_FOREST, AMB_BIRDS
        For i As Long = 0 To total - 1
            Dim As Single x = RndF(r)
            LP(a, x, IIf(id = AMB_FOREST, 0.03, 0.02))
            LP(c, x, 0.4)
            LP(d, c, 0.2)
            buf(i) = a * IIf(id = AMB_FOREST, 1.4, 0.6) + (c - d) * IIf(id = AMB_FOREST, 0.12, 0.04) * (0.5 + 0.5 * Sin(i / RATE * 0.9))
        Next
        Dim As Long chirps = CLng(seconds * IIf(id = AMB_BIRDS, 1.3, 0.35))
        For k As Long = 0 To chirps
            Dim As Single st = Rnd01(r) * (seconds - 1.5)
            Dim As Single base_ = 2200 + Rnd01(r) * 1800
            Dim As Long notes = 2 + CLng(Rnd01(r) * 4)
            Dim As Single amp = IIf(id = AMB_BIRDS, 0.35, 0.22) * (0.5 + Rnd01(r) * 0.5)
            For m As Long = 0 To notes - 1
                Dim As Single t0 = st + m * (0.09 + Rnd01(r) * 0.06)
                Dim As Long s0 = CLng(t0 * RATE), ln = CLng((0.05 + Rnd01(r) * 0.06) * RATE)
                Dim As Single f0 = base_ * (0.9 + Rnd01(r) * 0.25), f1 = f0 * (0.75 + Rnd01(r) * 0.5)
                Dim As Single ph = 0
                For j As Long = 0 To ln - 1
                    If s0 + j >= total Then Exit For
                    Dim As Single ff = j / ln
                    ph += TAU * (f0 + (f1 - f0) * ff + 120 * Sin(j / RATE * TAU * 30)) / RATE
                    buf(s0 + j) += Sin(ph) * amp * Sin(3.14159 * ff)
                Next
            Next
        Next
    Case AMB_MUSIC
        ' slow pad over four chords + a few soft pentatonic bells
        Dim As Single chords(0 To 3, 0 To 3) = {{130.81, 164.81, 196.0, 246.94}, {110.0, 130.81, 164.81, 196.0}, {87.31, 130.81, 174.61, 220.0}, {98.0, 146.83, 196.0, 246.94}}
        Dim As Single seg = seconds / 4
        For i As Long = 0 To total - 1
            Dim As Single t = i / RATE
            Dim As Single tt = t
            If tt >= seconds Then tt -= seconds
            Dim As Long ci = Int(tt / seg) Mod 4
            Dim As Single local_ = tt - ci * seg
            Dim As Single env = 1
            If local_ < 1.5 Then env = local_ / 1.5
            If local_ > seg - 1.5 Then env = (seg - local_) / 1.5
            Dim As Single v = 0
            For k As Long = 0 To 3
                Dim As Single f = chords(ci, k)
                v += Sin(TAU * f * t) * 0.25 + Sin(TAU * f * 2.003 * t) * 0.06
            Next
            buf(i) = v * env * (0.85 + 0.15 * Sin(TAU * t * 0.2))
        Next
        Dim As Single penta(0 To 4) = {523.25, 587.33, 659.25, 783.99, 880.0}
        For k As Long = 0 To CLng(seconds / 2.5)
            AddBell(buf(), k * 2.5 + Rnd01(r) * 0.8, penta(CLng(Rnd01(r) * 4.99)), 0.25, 1.8)
        Next
    End Select
    ' seamless loop: blend the tail into the head
    For i As Long = 0 To fade - 1
        Dim As Single f = i / fade
        buf(i) = buf(i) * f + buf(n + i) * (1 - f)
    Next
    Return MakeWav(buf(), n, IIf(id = AMB_MUSIC, 0.3, 0.42))
End Function

' ---------------- BASS ----------------

Private Function FileExists(ByRef p As String) As Boolean
    Dim As Long fh = FreeFile
    If Open(p For Binary Access Read As #fh) <> 0 Then Return False
    Close #fh
    Return True
End Function

Private Function FindAsset(ByRef baseP As String) As String
    Dim As String exts(0 To 2) = {".ogg", ".mp3", ".wav"}
    For i As Long = 0 To 2
        If FileExists(baseP & exts(i)) Then Return baseP & exts(i)
    Next
    Return ""
End Function

Function Audio_Init(ByRef resDir As String) As Boolean
    gRes = resDir
    audioOk = 0
    audioStatus = "audio.off"
    If Environ("CALM_NOAUDIO") = "1" Then audioStatus = "audio.disabled": Return False
#ifdef __FB_WIN32__
    bassLib = DyLibLoad(ExePath() & "\bass.dll")
    If bassLib = 0 Then bassLib = DyLibLoad("bass.dll")
#else
    bassLib = DyLibLoad(ExePath() & "/lib/linux64/libbass.so")
    If bassLib = 0 Then bassLib = DyLibLoad(ExePath() & "/libbass.so")
    If bassLib = 0 Then bassLib = DyLibLoad("libbass.so")
#endif
    If bassLib = 0 Then audioStatus = "audio.nolib": Return False
    pInit = DyLibSymbol(bassLib, "BASS_Init")
    pFree = DyLibSymbol(bassLib, "BASS_Free")
    pSampleLoad = DyLibSymbol(bassLib, "BASS_SampleLoad")
    pSampleGetChannel = DyLibSymbol(bassLib, "BASS_SampleGetChannel")
    pStreamCreateFile = DyLibSymbol(bassLib, "BASS_StreamCreateFile")
    pChannelPlay = DyLibSymbol(bassLib, "BASS_ChannelPlay")
    pChannelStop = DyLibSymbol(bassLib, "BASS_ChannelStop")
    pChannelSetAttribute = DyLibSymbol(bassLib, "BASS_ChannelSetAttribute")
    pChannelSlide = DyLibSymbol(bassLib, "BASS_ChannelSlideAttribute")
    pChannelIsActive = DyLibSymbol(bassLib, "BASS_ChannelIsActive")
    pStreamFree = DyLibSymbol(bassLib, "BASS_StreamFree")
    If pInit = 0 OrElse pSampleLoad = 0 OrElse pStreamCreateFile = 0 OrElse pChannelPlay = 0 OrElse pChannelSlide = 0 Then
        audioStatus = "audio.nolib": Return False
    End If
    If pInit(-1, 44100, 0, 0, 0) = 0 Then audioStatus = "audio.nodevice": Return False
    For i As Long = 0 To SND_COUNT - 1
        Dim As String f = ""
        If i = SND_CHIME Then f = FindAsset(resDir & "/sounds/chime")
        If Len(f) Then
            sndHandle(i) = pSampleLoad(0, StrPtr(f), 0, 0, 4, BASS_SAMPLE_OVER_POS)
        End If
        If sndHandle(i) = 0 Then
            sndData(i) = Audio_SynthSound(i)
            sndHandle(i) = pSampleLoad(1, StrPtr(sndData(i)), 0, Len(sndData(i)), 4, BASS_SAMPLE_OVER_POS)
        End If
    Next
    audioOk = 1
    audioStatus = "audio.ok"
    Return True
End Function

Sub Audio_Shutdown()
    If audioOk AndAlso pFree Then pFree()
    audioOk = 0
    If bassLib Then DyLibFree(bassLib): bassLib = 0
End Sub

Function Audio_Available() As Boolean
    Return audioOk <> 0
End Function

Function Audio_Status() As String
    If Len(audioStatus) = 0 Then Return "audio.off"
    Return audioStatus
End Function

Private Function AmbVolume() As Single
    If gSet.soundOn = 0 OrElse gSet.ambientOn = 0 Then Return 0
    Return gSet.ambientVol / 100.0 * 0.8
End Function

Sub Audio_Play(ByVal id As Long)
    If audioOk = 0 OrElse id < 0 OrElse id >= SND_COUNT Then Exit Sub
    If gSet.soundOn = 0 OrElse gSet.sfxOn = 0 Then Exit Sub
    If sndHandle(id) = 0 Then Exit Sub
    Dim As ULong ch = pSampleGetChannel(sndHandle(id), 0)
    If ch = 0 Then Exit Sub
    pChannelSetAttribute(ch, BASS_ATTRIB_VOL, gSet.sfxVol / 100.0)
    pChannelPlay(ch, 1)
End Sub

Private Sub FadeOutAndFree(ByVal h As ULong)
    If h = 0 Then Exit Sub
    ' slide to silence; a negative volume target frees the channel when the slide ends (BASS 2.4)
    pChannelSlide(h, BASS_ATTRIB_VOL, -1, 1200)
End Sub

Sub Audio_SetAmbient(ByVal id As Long)
    If audioOk = 0 Then ambCur = id: Exit Sub
    If id = ambCur AndAlso ambStream <> 0 Then
        pChannelSlide(ambStream, BASS_ATTRIB_VOL, AmbVolume(), 800)
        Exit Sub
    End If
    FadeOutAndFree(ambStream)
    ambStream = 0
    ambCur = id
    If id < 0 OrElse id >= AMB_COUNT Then Exit Sub
    Dim As String names(0 To AMB_COUNT - 1) = {"rain", "ocean", "wind", "forest", "birds", "music"}
    Dim As String f = FindAsset(gRes & "/sounds/" & names(id))
    If Len(f) Then ambStream = pStreamCreateFile(0, StrPtr(f), 0, 0, BASS_SAMPLE_LOOP)
    If ambStream = 0 Then
        If Len(ambData(id)) = 0 Then ambData(id) = Audio_SynthAmbient(id, IIf(id = AMB_MUSIC, 32, 16))
        ambStream = pStreamCreateFile(1, StrPtr(ambData(id)), 0, Len(ambData(id)), BASS_SAMPLE_LOOP)
    End If
    If ambStream = 0 Then Exit Sub
    pChannelSetAttribute(ambStream, BASS_ATTRIB_VOL, 0)
    pChannelPlay(ambStream, 0)
    pChannelSlide(ambStream, BASS_ATTRIB_VOL, AmbVolume(), 2500)      ' gentle fade-in, never sudden
End Sub

Function Audio_CurrentAmbient() As Long
    Return ambCur
End Function

Sub Audio_ApplySettings()
    If audioOk = 0 Then Exit Sub
    If ambStream Then pChannelSlide(ambStream, BASS_ATTRIB_VOL, AmbVolume(), 600)
    If narrStream AndAlso gSet.soundOn = 0 Then Audio_StopNarration()
End Sub

Private Function NarrationFile(ByRef lang As String, ByRef id As String) As String
    Return FindAsset(gRes & "/narration/" & lang & "/" & id)
End Function

Function Audio_HasNarration(ByRef lang As String, ByRef id As String) As Boolean
    Return Len(NarrationFile(lang, id)) > 0
End Function

Function Audio_PlayNarration(ByRef lang As String, ByRef id As String) As Boolean
    Audio_StopNarration()
    If audioOk = 0 OrElse gSet.soundOn = 0 OrElse gSet.narrationOn = 0 Then Return False
    Dim As String f = NarrationFile(lang, id)
    If Len(f) = 0 Then Return False
    narrStream = pStreamCreateFile(0, StrPtr(f), 0, 0, 0)
    If narrStream = 0 Then Return False
    pChannelSetAttribute(narrStream, BASS_ATTRIB_VOL, 0.9)
    pChannelPlay(narrStream, 0)
    Return True
End Function

Sub Audio_StopNarration()
    If audioOk AndAlso narrStream Then
        pChannelStop(narrStream)
        If pStreamFree Then pStreamFree(narrStream)
    End If
    narrStream = 0
End Sub

Function Audio_NarrationPlaying() As Boolean
    If audioOk = 0 OrElse narrStream = 0 OrElse pChannelIsActive = 0 Then Return False
    Return pChannelIsActive(narrStream) <> 0
End Function
