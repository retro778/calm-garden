' app_state.bi - shared application state, screen ids and activity ids
#pragma once
#include once "graphics.bi"
#include once "platform.bi"
#include once "settings.bi"

Enum ScreenId
    SCR_MENU = 0
    SCR_BREATH_LIST
    SCR_BREATH
    SCR_RELAX_LIST
    SCR_RELAX
    SCR_MIND_LIST
    SCR_MIND
    SCR_BIO
    SCR_GAME_LIST
    SCR_GAME
    SCR_TIMER
    SCR_PROGRESS
    SCR_SETTINGS
    SCR_ABOUT
    SCR_COUNT
End Enum

' Activities (used for progress tracking and favourites). The key strings are
' stored in the progress file, so never renumber/rename them.
Enum ActivityId
    ACT_FLOWER = 0
    ACT_BALLOON
    ACT_OCEAN
    ACT_STAR
    ACT_PMR
    ACT_BODYSCAN
    ACT_BREATH_AWARE
    ACT_PLACE
    ACT_BEDTIME
    ACT_BREAK5
    ACT_SENSES
    ACT_OBSERVE
    ACT_CLOUDS
    ACT_GRATITUDE
    ACT_MOMENTS
    ACT_BIO
    ACT_ZEN
    ACT_JOURNEY
    ACT_LEAVES
    ACT_NIGHT
    ACT_AQUARIUM
    ACT_TIMER
    ACT_COUNT
End Enum

Type AppState
    scr As Long
    arg As Long
    prevScr As Long
    now As Double            ' wall clock (seconds)
    dt As Single             ' frame delta, clamped
    anim As Double           ' animation clock (scaled by speed setting, frozen while paused screens)
    w As Long
    h As Long
    sc As Single             ' layout scale: 1.0 at 1024x768
    rtl As Long
    quit As Long
    frame As Long
    scrStart As Double
    dataDir As String
    resDir As String
    audioOk As Long
    headless As Long         ' screenshot/test mode: no real window
    entering As Long         ' 1 on the first frame of a new screen
    goSerial As Long         ' incremented by App_Go
End Type

Extern gApp As AppState
Extern gSet As Settings
Extern gCv As Canvas
Extern gIn As InputState

Declare Sub App_Go(ByVal scr As Long, ByVal arg As Long = 0)
Declare Sub App_SaveSettings()
Declare Sub App_ApplyLanguage()
Declare Function App_ActKey(ByVal act As Long) As String
Declare Function App_ActFromKey(ByRef k As String) As Long
Declare Function App_ActName(ByVal act As Long) As String
Declare Function App_Motion() As Single     ' 1 normally, small in reduced-motion mode
Declare Function App_DirText() As Long       ' text direction of interface strings
