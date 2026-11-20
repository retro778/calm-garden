' settings.bas - load/save/validate preferences (see settings.bi)
#include once "settings.bi"

Sub Settings_Defaults(ByRef s As Settings)
    s.lang = "en"
    s.fontPct = 100
    s.highContrast = 0
    s.reducedMotion = 0
    s.childMode = 0
    s.adultStyle = 0
    s.fullscreen = 0
    s.winW = 1024
    s.winH = 768
    s.soundOn = 1
    s.sfxOn = 1
    s.sfxVol = 60
    s.ambientOn = 1
    s.ambientVol = 40
    s.ambientId = 0
    s.musicOn = 0
    s.narrationOn = 1
    s.inhaleSec = 4
    s.exhaleSec = 6
    s.pauseOn = 0
    s.pauseSec = 2
    s.sessionMin = 3
    s.animPct = 100
    s.theme = 0
    s.trackingOn = 1
    s.askRatings = 1
End Sub

' clamps v into [lo, hi]; counts a fix when it was outside
Private Sub Clamp(ByRef v As Long, ByVal lo As Long, ByVal hi As Long, ByVal def As Long, ByRef fixes As Long)
    If v < lo OrElse v > hi Then v = def: fixes += 1
End Sub

Function Settings_Validate(ByRef s As Settings) As Long
    Dim As Settings d
    Settings_Defaults(d)
    Dim As Long f = 0
    If s.lang <> "en" AndAlso s.lang <> "he" Then s.lang = d.lang: f += 1
    Clamp(s.fontPct, 80, 160, d.fontPct, f)
    Clamp(s.highContrast, 0, 1, 0, f)
    Clamp(s.reducedMotion, 0, 1, 0, f)
    Clamp(s.childMode, 0, 1, 0, f)
    Clamp(s.adultStyle, 0, 1, 0, f)
    Clamp(s.fullscreen, 0, 1, 0, f)
    Clamp(s.winW, 640, 16384, d.winW, f)
    Clamp(s.winH, 480, 16384, d.winH, f)
    Clamp(s.soundOn, 0, 1, 1, f)
    Clamp(s.sfxOn, 0, 1, 1, f)
    Clamp(s.sfxVol, 0, 100, d.sfxVol, f)
    Clamp(s.ambientOn, 0, 1, 1, f)
    Clamp(s.ambientVol, 0, 100, d.ambientVol, f)
    Clamp(s.ambientId, 0, 5, 0, f)
    Clamp(s.musicOn, 0, 1, 0, f)
    Clamp(s.narrationOn, 0, 1, 1, f)
    Clamp(s.inhaleSec, 2, 8, d.inhaleSec, f)
    Clamp(s.exhaleSec, 2, 10, d.exhaleSec, f)
    Clamp(s.pauseOn, 0, 1, 0, f)
    Clamp(s.pauseSec, 1, 4, d.pauseSec, f)
    Clamp(s.sessionMin, 1, 20, d.sessionMin, f)
    Clamp(s.animPct, 50, 150, d.animPct, f)
    Clamp(s.theme, 0, 3, 0, f)
    Clamp(s.trackingOn, 0, 1, 1, f)
    Clamp(s.askRatings, 0, 1, 1, f)
    Return f
End Function

' strict integer parse: optional minus sign and 1..9 digits
Private Function ParseInt(ByRef t As String, ByRef v As Long) As Boolean
    Dim As String u = Trim(t)
    If Len(u) = 0 OrElse Len(u) > 10 Then Return False
    For i As Long = 0 To Len(u) - 1
        If (u[i] < 48 OrElse u[i] > 57) AndAlso Not (i = 0 AndAlso u[i] = 45 AndAlso Len(u) > 1) Then Return False
    Next
    v = ValInt(u)
    Return True
End Function

Function Settings_Load(ByRef s As Settings, ByRef path As String) As Long
    Settings_Defaults(s)
    Dim As Long fh = FreeFile
    If Open(path For Input As #fh) <> 0 Then Return -1
    Dim As Long bad = 0
    Dim As String ln
    While Not EOF(fh)
        Line Input #fh, ln
        ln = Trim(ln, Any !" \t\r\n")
        If Len(ln) = 0 OrElse Left(ln, 1) = "#" Then Continue While
        Dim As Long p = InStr(ln, "=")
        If p = 0 Then bad += 1: Continue While
        Dim As String k = LCase(Trim(Left(ln, p - 1))), v = Trim(Mid(ln, p + 1))
        If k = "lang" Then s.lang = LCase(v): Continue While
        Dim As Long n
        If Not ParseInt(v, n) Then bad += 1: Continue While
        Select Case k
        Case "font_pct": s.fontPct = n
        Case "high_contrast": s.highContrast = n
        Case "reduced_motion": s.reducedMotion = n
        Case "child_mode": s.childMode = n
        Case "adult_style": s.adultStyle = n
        Case "fullscreen": s.fullscreen = n
        Case "win_w": s.winW = n
        Case "win_h": s.winH = n
        Case "sound": s.soundOn = n
        Case "sfx": s.sfxOn = n
        Case "sfx_vol": s.sfxVol = n
        Case "ambient": s.ambientOn = n
        Case "ambient_vol": s.ambientVol = n
        Case "ambient_id": s.ambientId = n
        Case "music": s.musicOn = n
        Case "narration": s.narrationOn = n
        Case "inhale": s.inhaleSec = n
        Case "exhale": s.exhaleSec = n
        Case "pause": s.pauseOn = n
        Case "pause_sec": s.pauseSec = n
        Case "session_min": s.sessionMin = n
        Case "anim_pct": s.animPct = n
        Case "theme": s.theme = n
        Case "tracking": s.trackingOn = n
        Case "ask_ratings": s.askRatings = n
        Case Else
            ' unknown keys (from newer versions) are ignored, not errors
        End Select
    Wend
    Close #fh
    Return bad + Settings_Validate(s)
End Function

Function Settings_Save(ByRef s As Settings, ByRef path As String) As Boolean
    Dim As String tmp = path & ".tmp"
    Dim As Long fh = FreeFile
    If Open(tmp For Output As #fh) <> 0 Then Return False
    Print #fh, "# Calm Garden settings (UTF-8). Delete this file to restore the defaults."
    Print #fh, "lang = " & s.lang
    Print #fh, "font_pct = " & s.fontPct
    Print #fh, "high_contrast = " & s.highContrast
    Print #fh, "reduced_motion = " & s.reducedMotion
    Print #fh, "child_mode = " & s.childMode
    Print #fh, "adult_style = " & s.adultStyle
    Print #fh, "fullscreen = " & s.fullscreen
    Print #fh, "win_w = " & s.winW
    Print #fh, "win_h = " & s.winH
    Print #fh, "sound = " & s.soundOn
    Print #fh, "sfx = " & s.sfxOn
    Print #fh, "sfx_vol = " & s.sfxVol
    Print #fh, "ambient = " & s.ambientOn
    Print #fh, "ambient_vol = " & s.ambientVol
    Print #fh, "ambient_id = " & s.ambientId
    Print #fh, "music = " & s.musicOn
    Print #fh, "narration = " & s.narrationOn
    Print #fh, "inhale = " & s.inhaleSec
    Print #fh, "exhale = " & s.exhaleSec
    Print #fh, "pause = " & s.pauseOn
    Print #fh, "pause_sec = " & s.pauseSec
    Print #fh, "session_min = " & s.sessionMin
    Print #fh, "anim_pct = " & s.animPct
    Print #fh, "theme = " & s.theme
    Print #fh, "tracking = " & s.trackingOn
    Print #fh, "ask_ratings = " & s.askRatings
    Close #fh
    Kill path
    If Name(tmp, path) <> 0 Then Return False
    Return True
End Function
