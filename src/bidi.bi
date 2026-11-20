' bidi.bi - UTF-8 helpers and the Unicode Bidirectional Algorithm (UAX #9)
' Implemented: paragraph level (P2/P3), isolates (LRI/RLI/FSI/PDI), weak types (W1-W7),
' paired brackets (N0), neutrals (N1/N2), implicit levels (I1/I2), line rules (L1/L2)
' and mirroring (L4). Explicit embeddings/overrides (LRE/RLE/LRO/RLO/PDF) are ignored
' (treated as BN) - the application never generates them.
#pragma once

Const BC_L = 0
Const BC_R = 1
Const BC_AL = 2
Const BC_EN = 3
Const BC_ES = 4
Const BC_ET = 5
Const BC_AN = 6
Const BC_CS = 7
Const BC_NSM = 8
Const BC_BN = 9
Const BC_B = 10
Const BC_S = 11
Const BC_WS = 12
Const BC_ON = 13
Const BC_LRI = 14
Const BC_RLI = 15
Const BC_FSI = 16
Const BC_PDI = 17

Const CP_LRM = &h200E
Const CP_RLM = &h200F
Const CP_LRI = &h2066
Const CP_RLI = &h2067
Const CP_FSI = &h2068
Const CP_PDI = &h2069

Declare Function Utf8_Decode(ByRef s As String, cps() As Long) As Long
Declare Function Utf8_Encode(ByVal cp As Long) As String
Declare Function Utf8_Len(ByRef s As String) As Long
Declare Function Bidi_Class(ByVal cp As Long) As Long
Declare Function Bidi_Mirror(ByVal cp As Long) As Long
Declare Function Bidi_FirstStrong(cps() As Long, ByVal s As Long, ByVal e As Long) As Long
Declare Function Bidi_Levels(cps() As Long, ByVal n As Long, ByVal baseLevel As Long, levels() As Long) As Long
Declare Sub Bidi_ReorderLine(cps() As Long, levels() As Long, ByVal start As Long, ByVal count As Long, ByVal baseLevel As Long, order() As Long)
Declare Function Bidi_VisualString(ByRef s As String, ByVal baseLevel As Long) As String
Declare Function Bidi_Iso(ByRef s As String) As String
Declare Function Bidi_HasRTL(ByRef s As String) As Boolean
