' ui.bi - small immediate-mode UI: widgets are function calls made every frame.
' Keyboard: Tab / Shift+Tab / arrow keys move the focus, Enter or Space
' activates, Left/Right change sliders and choices. Layouts are written for
' left-to-right; Ui_MX mirrors x positions for right-to-left languages.
#pragma once
#include once "app_state.bi"
#include once "text.bi"

Type UiTheme
    bgTop As ULong
    bgMid As ULong
    bgBot As ULong
    panel As ULong
    panelEdge As ULong
    text As ULong
    textSoft As ULong
    title As ULong
    accent As ULong
    accent2 As ULong
    btn As ULong
    btnHover As ULong
    btnText As ULong
    primary As ULong
    primaryText As ULong
    focus As ULong
    track As ULong
    shadow As ULong
    sim As ULong            ' "simulation only" badge
    playful As Long         ' 1 = rounder, more colourful decorations
End Type

Extern gTheme As UiTheme

Const BTN_NORMAL = 0
Const BTN_PRIMARY = 1
Const BTN_TILE = 2
Const BTN_SOFT = 3

Const FS_SMALL = 16
Const FS_BODY = 21
Const FS_LARGE = 26
Const FS_TITLE = 36
Const FS_HUGE = 52

' icons drawn by scene.bas
Declare Sub Ui_ApplyTheme()
Declare Sub Ui_BeginFrame()
Declare Sub Ui_EndFrame()
Declare Function Ui_S(ByVal v As Single) As Long
Declare Function Ui_FS(ByVal basePx As Long) As Long
Declare Function Ui_MX(ByVal x As Long, ByVal w As Long) As Long
Declare Function Ui_Hover(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Boolean
Declare Function Ui_Clicked(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Boolean
' a key press that no widget used this frame
Declare Function Ui_Key(ByVal k As Long, ByVal mods As Long = 0) As Boolean
Declare Sub Ui_ConsumeKey(ByVal k As Long)
Declare Sub Ui_SetFocus(ByRef id As String)
Declare Function Ui_HasFocus(ByRef id As String) As Boolean
Declare Function Ui_Button(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByVal kind As Long = BTN_NORMAL, ByVal icon As Long = -1, ByVal tint As ULong = 0) As Boolean
Declare Function Ui_Toggle(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef v As Long) As Boolean
Declare Function Ui_Slider(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef v As Long, ByVal lo As Long, ByVal hi As Long, ByVal stp As Long = 1, ByRef suffix As String = "") As Boolean
Declare Function Ui_Choice(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef label As String, ByRef opts As String, ByRef idx As Long) As Boolean
' returns 1 when Enter was pressed in the field
Declare Function Ui_TextField(ByRef id As String, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByRef txt As String, ByRef hint As String, ByVal maxChars As Long = 60) As Long
Declare Sub Ui_Label(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal col As ULong, ByVal align As Long = ALIGN_START, ByVal face As Long = FACE_REGULAR)
Declare Function Ui_Para(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByRef txt As String, ByVal fs As Long, ByVal col As ULong, ByVal align As Long = ALIGN_START, ByVal face As Long = FACE_REGULAR) As Long
Declare Function Ui_ParaHeight(ByRef txt As String, ByVal w As Long, ByVal fs As Long, ByVal face As Long = FACE_REGULAR) As Long
Declare Sub Ui_Panel(ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, ByVal alpha As Long = 225)
' standard header: back button (Esc), title, mute button. Returns True when "back" was chosen.
Declare Function Ui_Header(ByRef title As String, ByVal showSim As Long = 0) As Boolean
Declare Function Ui_HeaderH() As Long
Declare Sub Ui_Toast(ByRef msg As String)
Declare Sub Ui_Badge(ByVal x As Long, ByVal y As Long, ByRef txt As String, ByVal bg As ULong, ByVal fg As ULong, ByVal fs As Long)
Declare Function Ui_BadgeW(ByRef txt As String, ByVal fs As Long) As Long
Declare Sub Ui_SimBanner(ByVal x As Long, ByVal y As Long, ByVal w As Long)
Declare Function Ui_FocusVisible() As Boolean
Declare Function Ui_FocusY(ByRef h As Long) As Long
' testing: activate the widget with this id on the next frame
Declare Sub Ui_TestActivate(ByRef id As String)
Declare Function Ui_Anim(ByRef id As String, ByVal target As Single, ByVal speed As Single = 8) As Single
