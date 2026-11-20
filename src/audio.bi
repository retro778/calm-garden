' audio.bi - optional sound through BASS (loaded at run time, never required).
'
' Every built-in sound is synthesised by the program (original, no licensing
' questions). Files dropped into assets/sounds/ replace the synthesised ones:
'   rain, ocean, wind, forest, birds, music, chime  (.ogg, .mp3 or .wav)
' Narration is optional and modular: assets/narration/<lang>/<id>.(ogg|mp3|wav).
' Without BASS, without an audio device, or with sound switched off, every
' function here is a silent no-op.
#pragma once

Const SND_CLICK = 0
Const SND_CHIME = 1        ' soft bell (start of a session)
Const SND_CHIME_END = 2    ' two gentle bells (end of a session)
Const SND_IN = 3           ' very soft rising tone: "breathe in"
Const SND_OUT = 4          ' very soft falling tone: "breathe out"
Const SND_SPARKLE = 5      ' gentle "well done"
Const SND_POP = 6          ' soft bubble
Const SND_COUNT = 7

Const AMB_RAIN = 0
Const AMB_OCEAN = 1
Const AMB_WIND = 2
Const AMB_FOREST = 3
Const AMB_BIRDS = 4
Const AMB_MUSIC = 5
Const AMB_COUNT = 6

Declare Function Audio_Init(ByRef resDir As String) As Boolean
Declare Sub Audio_Shutdown()
Declare Function Audio_Available() As Boolean
Declare Function Audio_Status() As String
Declare Sub Audio_ApplySettings()
Declare Sub Audio_Play(ByVal id As Long)
' ambient loop: id = AMB_*, or -1 for silence. Fades in/out gently.
Declare Sub Audio_SetAmbient(ByVal id As Long)
Declare Function Audio_CurrentAmbient() As Long
Declare Function Audio_PlayNarration(ByRef lang As String, ByRef id As String) As Boolean
Declare Sub Audio_StopNarration()
Declare Function Audio_NarrationPlaying() As Boolean
Declare Function Audio_HasNarration(ByRef lang As String, ByRef id As String) As Boolean
' synthesis (also used by the tests): 16-bit mono WAV bytes
Declare Function Audio_SynthAmbient(ByVal id As Long, ByVal seconds As Single) As String
Declare Function Audio_SynthSound(ByVal id As Long) As String
Declare Function Audio_WavPeak(ByRef wav As String) As Long
