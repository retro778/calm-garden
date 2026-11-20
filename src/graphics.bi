' graphics.bi - software canvas (32-bit XRGB) with anti-aliased shapes
' and a coverage rasterizer shared with the font renderer.
#pragma once

#define ARGB_A(c) CLng(((c) Shr 24) And 255)
#define ARGB_R(c) CLng(((c) Shr 16) And 255)
#define ARGB_G(c) CLng(((c) Shr 8) And 255)
#define ARGB_B(c) CLng((c) And 255)

Declare Function MkColor(ByVal r As Long, ByVal g As Long, ByVal b As Long, ByVal a As Long = 255) As ULong
Declare Function Col_Mix(ByVal c1 As ULong, ByVal c2 As ULong, ByVal t As Single) As ULong
Declare Function Col_Alpha(ByVal c As ULong, ByVal a As Long) As ULong
Declare Function Col_Lum(ByVal c As ULong) As Single

Type Canvas
    w As Long
    h As Long
    px As ULong Ptr
    cx0 As Long          ' clip rectangle (x1/y1 exclusive)
    cy0 As Long
    cx1 As Long
    cy1 As Long
    clipSP As Long
    clipStack(0 To 63) As Long
End Type

Declare Sub Cv_Create(ByRef c As Canvas, ByVal w As Long, ByVal h As Long)
Declare Sub Cv_Free(ByRef c As Canvas)
Declare Sub Cv_Clear(ByRef c As Canvas, ByVal col As ULong)
Declare Sub Cv_PushClip(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
Declare Sub Cv_PopClip(ByRef c As Canvas)
Declare Sub Cv_FillRect(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal col As ULong)
Declare Sub Cv_Rect(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal t As Long, ByVal col As ULong)
Declare Sub Cv_VGradient(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal c1 As ULong, ByVal c2 As ULong)
Declare Sub Cv_FillRoundRect(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal w As Single, ByVal h As Single, ByVal r As Single, ByVal col As ULong)
Declare Sub Cv_RoundRectOutline(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal w As Single, ByVal h As Single, ByVal r As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Cv_FillCircle(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal col As ULong)
Declare Sub Cv_Ring(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Cv_Line(ByRef c As Canvas, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Cv_FillPoly(ByRef c As Canvas, xs() As Single, ys() As Single, ByVal n As Long, ByVal col As ULong)
Declare Sub Cv_Arrow(ByRef c As Canvas, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Cv_BlitMask(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal mask As UByte Ptr, ByVal mw As Long, ByVal mh As Long, ByVal col As ULong)
Declare Function Cv_SaveBMP(ByRef c As Canvas, ByRef fileName As String) As Boolean

' Coverage rasterizer (signed-area accumulation; non-zero-like fill)
Type Raster
    w As Long
    h As Long
    acc As Single Ptr
    cap As Long
End Type

Declare Sub Ras_Begin(ByRef r As Raster, ByVal w As Long, ByVal h As Long)
Declare Sub Ras_Line(ByRef r As Raster, ByVal x0 As Single, ByVal y0 As Single, ByVal x1 As Single, ByVal y1 As Single)
Declare Sub Ras_End(ByRef r As Raster, ByVal outMask As UByte Ptr)
Declare Sub Ras_Free(ByRef r As Raster)

Declare Sub Cv_SoftCircle(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal r As Single, ByVal col As ULong)
Declare Sub Cv_FillEllipse(ByRef c As Canvas, ByVal cx As Single, ByVal cy As Single, ByVal rx As Single, ByVal ry As Single, ByVal ang As Single, ByVal col As ULong)
Declare Sub Cv_VGradient3(ByRef c As Canvas, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal c1 As ULong, ByVal c2 As ULong, ByVal c3 As ULong)
