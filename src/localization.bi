' localization.bi - interface strings from external UTF-8 files assets/lang/<code>.txt
'
' File format:  key = value      (# starts a comment line)
'   "\n" in a value is a line break; {1} {2} {3} are filled in by Loc_F.
'   _name = English / עברית     (display name of the language)
'   _dir  = ltr | rtl
' A key with the suffix ".child" overrides the plain key in child-friendly mode.
' Missing keys fall back to English, then to the key itself (so gaps are visible).
#pragma once

Declare Function Loc_Load(ByRef langDir As String, ByRef code As String) As Boolean
Declare Function L(ByRef key As String) As String
Declare Function Loc_F(ByRef key As String, ByRef a1 As String = "", ByRef a2 As String = "", ByRef a3 As String = "") As String
Declare Function Loc_Has(ByRef key As String) As Boolean
Declare Function Loc_IsRTL() As Boolean
Declare Function Loc_Code() As String
Declare Sub Loc_SetChild(ByVal onOff As Long)
Declare Function Loc_Count() As Long
Declare Function Loc_KeyAt(ByVal i As Long) As String
Declare Function Loc_MissingCount() As Long
