# Simulated biofeedback and the sensor interface

Calm Garden has **no physiological sensors** and does not need any.

## What the simulation uses
`src/simulated_biofeedback.bas` produces every value on the biofeedback screen from:

* the breathing guide (the pacer's phase, from the user's chosen rhythm),
* mouse/keyboard interaction (the focus game; hurried clicking),
* the user's **own** calmness rating (1–5),
* elapsed time and mathematical demonstration waveforms.

| Graph | What it really is |
|---|---|
| Breathing rhythm | the breathing guide's curve – not a recording |
| Heart-like waveform | a formula (sum of smooth bumps), rate 68 ± 4 "bpm" following the guide – illustrates heart-rate variability, not anyone's heart |
| Focus game | how long the pointer rests in a moving circle (stillness counts too, for keyboard users) |
| Calm colours / meter | an animation driven mostly by the user's own rating – not a measurement of emotions |

Every `BioSample` carries `isMeasurement = 0`. The screen shows
"Simulation only — no physiological sensors connected." on every frame
(tested by `tests/test_biofeedback.bas`).

## Adding a real sensor later
```freebasic
Function MyRead(ByVal ctx As Any Ptr, ByRef s As BioSample) As Long
    ' fill s.breath / s.heartDemo ... from the device, set s.isMeasurement = 1
    Return 1   ' 0 = no data
End Function
Dim As Long id = Bio_RegisterSource("My device", @MyRead, myContext)
```
`Bio_SourceConnected(id)` then reports it, and `Bio_ReadSource(id, s)` reads it.
The shipped program never registers a source, and `Bio_ActiveSource()` always
returns the simulation. A real integration would also need its own labelling,
validation and, for any health use, professional and regulatory review.
