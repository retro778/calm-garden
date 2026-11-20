' animation.bi - time-based animation helpers and the guided-breathing model.
' Pure logic (no drawing), so it is covered by tests/test_animation.bas.
'
' Breathing safety rules built into the model:
'  * there is never a hold after breathing in (no breath holding at all);
'  * the optional pause comes after breathing out and is described as "rest";
'  * paces are limited to 2..8 s in and 2..10 s out (no fast breathing), and
'    a whole cycle is never shorter than 5 seconds (no hyperventilation pace).
#pragma once

Const BP_IN = 0
Const BP_OUT = 1
Const BP_REST = 2
Const BP_NATURAL = 3

Type BreathPattern
    inSec As Single
    outSec As Single
    restSec As Single      ' 0 = no rest
End Type

Type BreathState
    phase As Long          ' BP_*
    phaseFrac As Single         ' 0..1 progress inside the phase
    amount As Single       ' 0 (empty) .. 1 (full), eased - drives the animations
    cycle As Long          ' completed cycles
    phaseLeft As Single    ' seconds left in this phase
End Type

Declare Function Ease_InOutSine(ByVal t As Single) As Single
Declare Function Ease_OutCubic(ByVal t As Single) As Single
Declare Function Ease_Smooth(ByVal t As Single) As Single
Declare Function Lerp(ByVal a As Single, ByVal b As Single, ByVal t As Single) As Single
Declare Function Clamp01(ByVal t As Single) As Single
Declare Function Approach(ByVal cur As Single, ByVal target As Single, ByVal rate As Single, ByVal dt As Single) As Single

Declare Sub Breath_MakePattern(ByRef p As BreathPattern, ByVal inSec As Single, ByVal outSec As Single, ByVal restOn As Long, ByVal restSec As Single)
Declare Function Breath_CycleLen(ByRef p As BreathPattern) As Single
Declare Sub Breath_Eval(ByRef p As BreathPattern, ByVal t As Double, ByRef st As BreathState)
' gentle, unguided motion used in "breathe naturally" mode
Declare Sub Breath_Natural(ByVal t As Double, ByRef st As BreathState)

' A session clock that only advances while not paused.
Type SessionClock
    total As Single        ' planned length in seconds (0 = open-ended)
    elapsed As Double
    paused As Long
    running As Long
End Type

Declare Sub Clock_Start(ByRef c As SessionClock, ByVal totalSec As Single)
Declare Sub Clock_Tick(ByRef c As SessionClock, ByVal dt As Single)
Declare Function Clock_Done(ByRef c As SessionClock) As Boolean
Declare Function Clock_Frac(ByRef c As SessionClock) As Single
Declare Function Clock_Left(ByRef c As SessionClock) As Single
Declare Function Fmt_MinSec(ByVal sec As Single) As String
