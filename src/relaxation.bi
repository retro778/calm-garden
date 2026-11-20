' relaxation.bi - the step player (also used by "Calm Moments" in mindfulness.bas)
#pragma once

Declare Function Steps_Frame(ByRef prog As String, ByVal act As Long, ByRef title As String, ByRef desc As String) As Long
Declare Function Steps_Count(ByRef prog As String) As Long
Declare Function Steps_Duration(ByRef prog As String, ByVal i As Long) As Single
Declare Function Steps_Total(ByRef prog As String) As Single
