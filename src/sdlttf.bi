' sdlttf.bi - minimal binding for SDL2_ttf >= 2.20 (HarfBuzz-enabled builds).
' The SDL_ttf.bi shipped with FreeBASIC predates TTF_SetFontDirection /
' TTF_SetFontScriptName / TTF_SetFontSize, so only what Calm Garden needs is
' declared here.
#pragma once
#include once "SDL2/SDL.bi"

#inclib "SDL2_ttf"

Type TTF_Font As _TTF_Font

Const TTF_DIRECTION_LTR = 0
Const TTF_DIRECTION_RTL = 1

Extern "C"
Declare Function TTF_Init() As Long
Declare Sub TTF_Quit()
Declare Function TTF_WasInit() As Long
Declare Function TTF_OpenFont(ByVal file As Const ZString Ptr, ByVal ptsize As Long) As TTF_Font Ptr
Declare Sub TTF_CloseFont(ByVal font As TTF_Font Ptr)
Declare Function TTF_SetFontSize(ByVal font As TTF_Font Ptr, ByVal ptsize As Long) As Long
Declare Function TTF_SetFontDirection(ByVal font As TTF_Font Ptr, ByVal direction As Long) As Long
Declare Function TTF_SetFontScriptName(ByVal font As TTF_Font Ptr, ByVal script As Const ZString Ptr) As Long
Declare Sub TTF_SetFontHinting(ByVal font As TTF_Font Ptr, ByVal hinting As Long)
Declare Sub TTF_SetFontKerning(ByVal font As TTF_Font Ptr, ByVal allowed As Long)
Declare Function TTF_FontHeight(ByVal font As TTF_Font Ptr) As Long
Declare Function TTF_FontAscent(ByVal font As TTF_Font Ptr) As Long
Declare Function TTF_FontDescent(ByVal font As TTF_Font Ptr) As Long
Declare Function TTF_FontLineSkip(ByVal font As TTF_Font Ptr) As Long
Declare Function TTF_GlyphIsProvided32(ByVal font As TTF_Font Ptr, ByVal ch As ULong) As Long
Declare Function TTF_SizeUTF8(ByVal font As TTF_Font Ptr, ByVal text As Const ZString Ptr, ByVal w As Long Ptr, ByVal h As Long Ptr) As Long
Declare Function TTF_RenderUTF8_Blended(ByVal font As TTF_Font Ptr, ByVal text As Const ZString Ptr, ByVal fg As SDL_Color) As SDL_Surface Ptr
Declare Sub TTF_ByteSwappedUNICODE(ByVal swapped As Long)
End Extern

Const TTF_HINTING_LIGHT = 1
