' deps: src/animation.bas
' test_animation.bas - breathing model safety rules, easing and the session clock
#include once "../src/animation.bi"
#include once "testutil.bi"

Dim As BreathPattern p
Dim As BreathState st
Breath_MakePattern(p, 4, 6, 0, 2)
Check(Breath_CycleLen(p) = 10, "4 in + 6 out = 10 s")
Breath_Eval(p, 0, st): Check(st.phase = BP_IN AndAlso st.amount < 0.01, "starts breathing in from empty")
Breath_Eval(p, 2, st): Check(st.phase = BP_IN AndAlso Abs(st.amount - 0.5) < 0.01, "half way in")
Breath_Eval(p, 4.001, st): Check(st.phase = BP_OUT AndAlso st.amount > 0.99, "breathing out right after in: no hold")
Breath_Eval(p, 9.99, st): Check(st.phase = BP_OUT AndAlso st.amount < 0.01, "empty at the end of breathing out")
Breath_Eval(p, 10.5, st): Check(st.phase = BP_IN AndAlso st.cycle = 1, "second cycle")

' smoothness: no jumps between frames
Dim As Single prev = 0, maxStep = 0
For i As Long = 1 To 6000
    Breath_Eval(p, i / 60.0, st)
    If Abs(st.amount - prev) > maxStep Then maxStep = Abs(st.amount - prev)
    prev = st.amount
    Check(st.amount >= 0 AndAlso st.amount <= 1, "amount in range")
    Check(st.phase <> BP_REST, "no rest phase when the pause is off")
Next
Check(maxStep < 0.02, "animation changes smoothly (max step " & maxStep & ")")

' optional rest comes after breathing out only
Breath_MakePattern(p, 4, 6, 1, 2)
Breath_Eval(p, 11, st): Check(st.phase = BP_REST AndAlso st.amount = 0, "rest after breathing out, lungs empty")
Breath_Eval(p, 4.5, st): Check(st.phase = BP_OUT, "still no hold after breathing in when the rest is on")

' limits: no fast breathing
Breath_MakePattern(p, 0.5, 0.5, 0, 0)
Check(p.inSec >= 2 AndAlso p.outSec >= 2 AndAlso Breath_CycleLen(p) >= 5, "pace limits (cycle " & Breath_CycleLen(p) & " s)")
Breath_MakePattern(p, 30, 30, 1, 30)
Check(p.inSec <= 8 AndAlso p.outSec <= 10 AndAlso p.restSec <= 4, "upper limits")

' natural mode is a small, slow drift
Dim As Single lo = 1, hi = 0
For i As Long = 0 To 3000
    Breath_Natural(i / 30.0, st)
    If st.amount < lo Then lo = st.amount
    If st.amount > hi Then hi = st.amount
Next
Check(hi - lo < 0.4 AndAlso st.phase = BP_NATURAL, "natural breathing is not a guided rhythm")

' easing
Check(Abs(Ease_InOutSine(0)) < 0.001 AndAlso Abs(Ease_InOutSine(1) - 1) < 0.001, "ease ends")
Check(Ease_Smooth(-1) = 0 AndAlso Ease_Smooth(2) = 1, "ease clamps")
Dim As Single a = 0
For i As Long = 1 To 120: a = Approach(a, 1, 3, 1 / 60.0): Next
Check(a > 0.85 AndAlso a < 1, "approach converges")

' session clock
Dim As SessionClock c
Clock_Start(c, 60)
For i As Long = 1 To 600: Clock_Tick(c, 1 / 60.0): Next
Check(Abs(c.elapsed - 10) < 0.01, "clock counts")
c.paused = 1
For i As Long = 1 To 600: Clock_Tick(c, 1 / 60.0): Next
Check(Abs(c.elapsed - 10) < 0.01, "clock stops while paused")
c.paused = 0
For i As Long = 1 To 6000: Clock_Tick(c, 1 / 60.0): Next
Check(Clock_Done(c) AndAlso c.elapsed = 60 AndAlso Clock_Left(c) = 0, "clock ends exactly")
CheckEq(Fmt_MinSec(125), "2:05", "format")
CheckEq(Fmt_MinSec(59.2), "1:00", "format rounds up the remaining time")
End Test_Finish("test_animation")
