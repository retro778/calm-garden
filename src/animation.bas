' animation.bas - see animation.bi
#include once "animation.bi"

Const PI = 3.14159265

Function Clamp01(ByVal t As Single) As Single
    If t < 0 Then Return 0
    If t > 1 Then Return 1
    Return t
End Function

Function Ease_InOutSine(ByVal t As Single) As Single
    t = Clamp01(t)
    Return 0.5 - 0.5 * Cos(PI * t)
End Function

Function Ease_OutCubic(ByVal t As Single) As Single
    t = Clamp01(t)
    Dim As Single u = 1 - t
    Return 1 - u * u * u
End Function

Function Ease_Smooth(ByVal t As Single) As Single
    t = Clamp01(t)
    Return t * t * (3 - 2 * t)
End Function

Function Lerp(ByVal a As Single, ByVal b As Single, ByVal t As Single) As Single
    Return a + (b - a) * t
End Function

' frame-rate independent exponential approach
Function Approach(ByVal cur As Single, ByVal target As Single, ByVal rate As Single, ByVal dt As Single) As Single
    Dim As Single k = 1 - Exp(-rate * dt)
    Return cur + (target - cur) * k
End Function

Sub Breath_MakePattern(ByRef p As BreathPattern, ByVal inSec As Single, ByVal outSec As Single, ByVal restOn As Long, ByVal restSec As Single)
    If inSec < 2 Then inSec = 2
    If inSec > 8 Then inSec = 8
    If outSec < 2 Then outSec = 2
    If outSec > 10 Then outSec = 10
    If restSec < 0 Then restSec = 0
    If restSec > 4 Then restSec = 4
    p.inSec = inSec
    p.outSec = outSec
    p.restSec = IIf(restOn, restSec, 0)
    ' never faster than 12 breaths a minute
    Dim As Single c = Breath_CycleLen(p)
    If c < 5 Then p.outSec += 5 - c
End Sub

Function Breath_CycleLen(ByRef p As BreathPattern) As Single
    Return p.inSec + p.outSec + p.restSec
End Function

Sub Breath_Eval(ByRef p As BreathPattern, ByVal t As Double, ByRef st As BreathState)
    Dim As Single cl = Breath_CycleLen(p)
    If cl <= 0 Then cl = 1
    If t < 0 Then t = 0
    st.cycle = Int(t / cl)
    Dim As Single u = t - st.cycle * cl
    If u < p.inSec Then
        st.phase = BP_IN
        st.phaseFrac = u / p.inSec
        st.amount = Ease_InOutSine(st.phaseFrac)
        st.phaseLeft = p.inSec - u
    ElseIf u < p.inSec + p.outSec Then
        st.phase = BP_OUT
        st.phaseFrac = (u - p.inSec) / p.outSec
        st.amount = 1 - Ease_InOutSine(st.phaseFrac)
        st.phaseLeft = p.inSec + p.outSec - u
    Else
        st.phase = BP_REST
        st.phaseFrac = IIf(p.restSec > 0, (u - p.inSec - p.outSec) / p.restSec, 1)
        st.amount = 0
        st.phaseLeft = cl - u
    End If
End Sub

Sub Breath_Natural(ByVal t As Double, ByRef st As BreathState)
    st.phase = BP_NATURAL
    st.phaseFrac = 0
    st.cycle = 0
    st.phaseLeft = 0
    ' slow, small drift: clearly not a rhythm to follow
    st.amount = 0.45 + 0.12 * Sin(t * 0.45) + 0.05 * Sin(t * 0.17)
End Sub

Sub Clock_Start(ByRef c As SessionClock, ByVal totalSec As Single)
    c.total = totalSec
    c.elapsed = 0
    c.paused = 0
    c.running = 1
End Sub

Sub Clock_Tick(ByRef c As SessionClock, ByVal dt As Single)
    If c.running = 0 OrElse c.paused <> 0 Then Exit Sub
    c.elapsed += dt
    If c.total > 0 AndAlso c.elapsed >= c.total Then c.elapsed = c.total
End Sub

Function Clock_Done(ByRef c As SessionClock) As Boolean
    Return c.total > 0 AndAlso c.elapsed >= c.total
End Function

Function Clock_Frac(ByRef c As SessionClock) As Single
    If c.total <= 0 Then Return 0
    Return Clamp01(c.elapsed / c.total)
End Function

Function Clock_Left(ByRef c As SessionClock) As Single
    If c.total <= 0 Then Return 0
    Dim As Single l = c.total - c.elapsed
    If l < 0 Then l = 0
    Return l
End Function

Function Fmt_MinSec(ByVal sec As Single) As String
    If sec < 0 Then sec = 0
    Dim As Long s = CLng(Int(sec + 0.999))
    Return (s \ 60) & ":" & Right("0" & (s Mod 60), 2)
End Function
