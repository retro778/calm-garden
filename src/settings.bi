' settings.bi - user preferences, stored as a UTF-8 "key = value" text file.
' Unknown keys are ignored; invalid or out-of-range values fall back to the
' defaults (counted in Settings_Load's return value). No personal information.
#pragma once

Type Settings
    lang As String          ' "en" / "he"
    fontPct As Long         ' 80..160 text size
    highContrast As Long
    reducedMotion As Long
    childMode As Long
    adultStyle As Long      ' 1 = calmer, less playful look
    fullscreen As Long
    winW As Long
    winH As Long
    ' audio
    soundOn As Long         ' master switch
    sfxOn As Long
    sfxVol As Long          ' 0..100
    ambientOn As Long
    ambientVol As Long
    ambientId As Long       ' AMB_* (audio.bi)
    musicOn As Long         ' gentle music in the menus
    narrationOn As Long
    ' breathing
    inhaleSec As Long       ' 2..8
    exhaleSec As Long       ' 2..10
    pauseOn As Long         ' optional comfortable rest after breathing out
    pauseSec As Long        ' 1..4
    sessionMin As Long      ' 1..20
    animPct As Long         ' 50..150 animation speed
    theme As Long           ' 0 garden, 1 sunset, 2 ocean, 3 night
    ' progress
    trackingOn As Long
    askRatings As Long
End Type

Declare Sub Settings_Defaults(ByRef s As Settings)
' returns the number of invalid lines/values replaced by defaults, -1 if the file is missing
Declare Function Settings_Load(ByRef s As Settings, ByRef path As String) As Long
Declare Function Settings_Save(ByRef s As Settings, ByRef path As String) As Boolean
Declare Function Settings_Validate(ByRef s As Settings) As Long
