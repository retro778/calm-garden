' deps: src/settings.bas
' test_settings.bas - defaults, save/load round trip, invalid and missing files
#include once "../src/settings.bi"
#include once "testutil.bi"

Dim As String dir_ = Test_TempDir("settings")
Dim As String f = dir_ & "/settings.txt"
Dim As Settings s, t
Settings_Defaults(s)
Check(Settings_Validate(s) = 0, "defaults are valid")
Check(s.inhaleSec >= 2 AndAlso s.exhaleSec >= s.inhaleSec, "gentle default: exhale not shorter than inhale")
Check(s.pauseOn = 0, "no pause/hold by default")

Kill f
Check(Settings_Load(t, f) = -1, "missing file reported as -1")
Check(t.lang = "en", "missing file gives defaults")

s.lang = "he": s.fontPct = 140: s.highContrast = 1: s.reducedMotion = 1: s.childMode = 1
s.inhaleSec = 3: s.exhaleSec = 7: s.pauseOn = 1: s.pauseSec = 3: s.ambientId = 4: s.trackingOn = 0
Check(Settings_Save(s, f), "save")
Check(Settings_Load(t, f) = 0, "round trip without fixes")
Check(t.lang = "he" AndAlso t.fontPct = 140 AndAlso t.highContrast = 1 AndAlso t.reducedMotion = 1, "display values kept")
Check(t.childMode = 1 AndAlso t.inhaleSec = 3 AndAlso t.exhaleSec = 7 AndAlso t.pauseOn = 1 AndAlso t.pauseSec = 3, "breathing values kept")
Check(t.ambientId = 4 AndAlso t.trackingOn = 0, "audio/privacy values kept")

' invalid file: garbage lines, wrong types, out of range values, unknown keys
Dim As Long fh = FreeFile
Open f For Output As #fh
Print #fh, "this line has no equals sign"
Print #fh, "lang = klingon"
Print #fh, "font_pct = 9999"
Print #fh, "inhale = abc"
Print #fh, "exhale = -3"
Print #fh, "theme = 2"
Print #fh, "future_option = 1"
Print #fh, "sfx_vol = 1e5"
Close #fh
Dim As Long fixes = Settings_Load(t, f)
Check(fixes >= 5, "invalid values counted (" & fixes & ")")
Check(t.lang = "en" AndAlso t.fontPct = 100 AndAlso t.inhaleSec = 4 AndAlso t.exhaleSec = 6 AndAlso t.sfxVol = 60, "invalid values replaced by defaults")
Check(t.theme = 2, "valid values in a damaged file are kept")

' empty / binary file
Open f For Output As #fh
Print #fh, Chr(0, 1, 2, 255, 254)
Close #fh
Settings_Load(t, f)
Check(Settings_Validate(t) = 0, "binary garbage still yields valid settings")

End Test_Finish("test_settings")
