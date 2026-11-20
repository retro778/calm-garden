' deps: src/simulated_biofeedback.bas src/localization.bas
' test_biofeedback.bas - the simulation is always labelled and never claims to measure anything
#include once "../src/simulated_biofeedback.bi"
#include once "../src/localization.bi"
#include once "testutil.bi"

Bio_Reset(1)
Dim As BioInputs bioIn
Dim As BioSample s
' 60 s following the pacer with a high self-report
For i As Long = 0 To 3599
    bioIn.breathAmount = 0.5 + 0.5 * Sin(i / 60.0 * 6.283 / 10)
    bioIn.breathing = 1: bioIn.selfReport = 5: bioIn.pointerInside = 1: bioIn.activity = 0
    Bio_Step(1 / 60.0, bioIn, s)
    Check(s.isMeasurement = 0, "sample never marked as a measurement")
    Check(s.calm >= 0 AndAlso s.calm <= 100 AndAlso s.focus >= 0 AndAlso s.focus <= 100, "values in range")
Next
Check(s.calm > 70, "calm animation follows the user's own high rating (" & s.calm & ")")
Check(s.focus > 80, "focus game rises while inside the circle")
Dim As Single calmHigh = s.calm
' the user's own low rating dominates
For i As Long = 0 To 3599
    bioIn.selfReport = 1: bioIn.pointerInside = 0: bioIn.activity = 1
    Bio_Step(1 / 60.0, bioIn, s)
Next
Check(s.calm < calmHigh - 30, "calm animation follows a low self-report")
Check(s.focus < 40, "focus game falls outside the circle")
' history
Dim As BioHistory Ptr h = Bio_History()
Check(h->count = BIO_HIST, "history filled")
' pause freezes the simulation
Dim As Double before = s.t
bioIn.paused = 1
For i As Long = 0 To 100: Bio_Step(1 / 60.0, bioIn, s): Next
Check(s.t = before, "paused simulation does not advance")
' heart-like demo shape: a clear peak, bounded
Dim As Single mx = -9, mn = 9
For i As Long = 0 To 999
    Dim As Single v = Bio_HeartShape(i / 1000)
    If v > mx Then mx = v
    If v < mn Then mn = v
Next
Check(mx > 0.9 AndAlso mx < 1.1 AndAlso mn > -0.5, "demo waveform shape")
' sources: the simulation is source 0 and is never a connected sensor
Check(CBool(Bio_SourceCount() = 1) AndAlso Bio_SourceIsSimulated(0) AndAlso (Not Bio_SourceConnected(0)), "only the simulation, not connected")
Check(Bio_ActiveSource() = 0, "simulation is used")
Dim As BioSample r
Check(Bio_ReadSource(0, r) AndAlso CBool(r.isMeasurement = 0), "reading the simulation is labelled")
Check(Not Bio_ReadSource(3, r), "missing sources fail safely")
' labelling text in both languages
For li As Long = 0 To 1
    Loc_Load(ExePath() & "/../assets/lang", IIf(li = 0, "en", "he"))
    Check(Len(L("sim.banner")) > 20, "simulation banner exists (" & Loc_Code() & ")")
    Check(InStr(LCase(L("bio.heart.note")), IIf(li = 0, "not your heart", "לא הלב")) > 0, "heart demo labelled (" & Loc_Code() & ")")
Next
Loc_Load(ExePath() & "/../assets/lang", "en")
Check(InStr(L("sim.banner"), "Simulation only") = 1 AndAlso InStr(L("sim.banner"), "no physiological sensors connected") > 0, "exact required banner wording")
' no string calls the simulation a measurement of the user
Dim As String keys(0 To 5) = {"bio.calm.note", "bio.breath.note", "bio.focus.note", "bio.intro", "bio.explain", "bio.done"}
For i As Long = 0 To 5
    Dim As String v = LCase(L(keys(i)))
    Check(InStr(v, "simulat") > 0 OrElse InStr(v, "not") > 0, keys(i) & " states it is not a measurement")
Next
End Test_Finish("test_biofeedback")
