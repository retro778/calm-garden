' simulated_biofeedback.bas - see simulated_biofeedback.bi
#include once "simulated_biofeedback.bi"

Const PI2 = 6.2831853

Dim Shared As BioHistory bioHist
Dim Shared As Double simT, heartPhase, sampleAcc
Dim Shared As Single calmV, focusV
Dim Shared As ULong rngS
Dim Shared As BioSample lastS

' registered sources: index 0 is always the simulation
Const MAX_SRC = 4
Dim Shared As String srcName(0 To MAX_SRC - 1)
Dim Shared As BioReadFn srcFn(0 To MAX_SRC - 1)
Dim Shared As Any Ptr srcCtx(0 To MAX_SRC - 1)
Dim Shared As Long srcN

Private Function Noise() As Single
    rngS = rngS * 1664525 + 1013904223
    Return ((rngS Shr 8) And &hFFFF) / 32768.0 - 1
End Function

Sub Bio_Reset(ByVal seed As ULong = 12345)
    simT = 0: heartPhase = 0: sampleAcc = 0
    calmV = 50: focusV = 50
    rngS = seed
    bioHist.head = 0: bioHist.count = 0
    lastS.isMeasurement = 0
End Sub

Function Bio_HeartShape(ByVal ph As Single) As Single
    ' sum of smooth bumps: purely illustrative
    ph = ph - Int(ph)
    Dim As Single v = 0
    v += 0.12 * Exp(-((ph - 0.12) / 0.03) ^ 2)      ' P
    v -= 0.15 * Exp(-((ph - 0.235) / 0.008) ^ 2)    ' Q
    v += 1.0 * Exp(-((ph - 0.25) / 0.012) ^ 2)      ' R
    v -= 0.25 * Exp(-((ph - 0.27) / 0.01) ^ 2)      ' S
    v += 0.28 * Exp(-((ph - 0.5) / 0.05) ^ 2)       ' T
    Return v
End Function

Sub Bio_Step(ByVal dt As Single, ByRef bioIn As BioInputs, ByRef outS As BioSample)
    If dt < 0 Then dt = 0
    If dt > 0.1 Then dt = 0.1
    If bioIn.paused Then outS = lastS: Exit Sub
    simT += dt
    ' breathing waveform straight from the pacer (guidance, not a measurement)
    Dim As Single br = bioIn.breathAmount * 2 - 1
    ' heart-like demo: an invented rate that rises a little with "breathing in"
    ' (illustrates the idea of heart-rate variability for learning purposes)
    Dim As Single rate = 68 + IIf(bioIn.breathing, 4 * br, 0) + Noise() * 0.5
    heartPhase += dt * rate / 60
    If heartPhase >= 1 Then heartPhase -= 1
    Dim As Single heart = Bio_HeartShape(heartPhase)
    ' relaxation ANIMATION meter: a simple, transparent model
    Dim As Single target = 45
    If bioIn.selfReport > 0 Then target = 15 + bioIn.selfReport * 15        ' the user's own rating dominates
    If bioIn.breathing Then target += 12                                  ' following the pacer
    target -= bioIn.activity * 30                                         ' hurried clicking moves it down a little
    If target < 5 Then target = 5
    If target > 95 Then target = 95
    calmV += (target - calmV) * (1 - Exp(-dt * 0.35)) + Noise() * dt * 2
    If calmV < 0 Then calmV = 0
    If calmV > 100 Then calmV = 100
    ' focus GAME: time the pointer rests inside the slowly moving circle
    Dim As Single ft = IIf(bioIn.pointerInside, 100, 25)
    focusV += (ft - focusV) * (1 - Exp(-dt * 0.6))
    outS.t = simT
    outS.breath = br
    outS.heartDemo = heart
    outS.heartRateDemo = rate
    outS.calm = calmV
    outS.focus = focusV
    outS.isMeasurement = 0
    lastS = outS
    ' history at 30 samples per second
    sampleAcc += dt
    While sampleAcc >= 1 / 30.0
        sampleAcc -= 1 / 30.0
        bioHist.breath(bioHist.head) = br
        bioHist.heart(bioHist.head) = heart
        bioHist.calm(bioHist.head) = calmV
        bioHist.focus(bioHist.head) = focusV
        bioHist.head = (bioHist.head + 1) Mod BIO_HIST
        If bioHist.count < BIO_HIST Then bioHist.count += 1
    Wend
End Sub

Function Bio_History() As BioHistory Ptr
    Return @bioHist
End Function

' which: 0 breath, 1 heart, 2 calm, 3 focus; ageIdx 0 = newest
Function Bio_HistGet(ByRef h As BioHistory, ByVal which As Long, ByVal ageIdx As Long) As Single
    If ageIdx < 0 OrElse ageIdx >= h.count Then Return 0
    Dim As Long i = (h.head - 1 - ageIdx + BIO_HIST * 2) Mod BIO_HIST
    Select Case which
    Case 0: Return h.breath(i)
    Case 1: Return h.heart(i)
    Case 2: Return h.calm(i)
    Case Else: Return h.focus(i)
    End Select
End Function

' ---------------- sources ----------------

Private Sub EnsureSim()
    If srcN = 0 Then
        srcName(0) = "simulation"
        srcFn(0) = 0
        srcN = 1
    End If
End Sub

Function Bio_SourceCount() As Long
    EnsureSim()
    Return srcN
End Function

Function Bio_SourceName(ByVal i As Long) As String
    EnsureSim()
    If i < 0 OrElse i >= srcN Then Return ""
    Return srcName(i)
End Function

Function Bio_SourceIsSimulated(ByVal i As Long) As Boolean
    EnsureSim()
    Return i = 0
End Function

Function Bio_SourceConnected(ByVal i As Long) As Boolean
    EnsureSim()
    If i = 0 Then Return False          ' the simulation is never a "connected sensor"
    Return i < srcN AndAlso srcFn(i) <> 0
End Function

Function Bio_RegisterSource(ByRef nm As String, ByVal fn As BioReadFn, ByVal ctx As Any Ptr) As Long
    EnsureSim()
    If srcN >= MAX_SRC OrElse fn = 0 Then Return -1
    srcName(srcN) = nm: srcFn(srcN) = fn: srcCtx(srcN) = ctx
    srcN += 1
    Return srcN - 1
End Function

Function Bio_ActiveSource() As Long
    ' no real sensor support is shipped: the simulation is always used
    Return 0
End Function

Function Bio_ReadSource(ByVal i As Long, ByRef s As BioSample) As Boolean
    EnsureSim()
    If i = 0 Then s = lastS: s.isMeasurement = 0: Return True
    If i < 0 OrElse i >= srcN OrElse srcFn(i) = 0 Then Return False
    Return srcFn(i)(srcCtx(i), s) <> 0
End Function
