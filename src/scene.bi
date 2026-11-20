' scene.bi - procedural artwork: icons and nature elements (all original, drawn in code)
#pragma once
#include once "graphics.bi"

Enum IconId
    ICON_FLOWER = 0
    ICON_WIND
    ICON_MOON
    ICON_LOTUS
    ICON_WAVE
    ICON_KITE
    ICON_TIMER
    ICON_CHART
    ICON_GEAR
    ICON_INFO
    ICON_ARROW_LEFT
    ICON_ARROW_RIGHT
    ICON_SOUND
    ICON_MUTE
    ICON_PLAY
    ICON_PAUSE
    ICON_STOP
    ICON_STAR
    ICON_BALLOON
    ICON_CLOUD
    ICON_SUN
    ICON_FISH
    ICON_TREE
    ICON_HEART
    ICON_CHECK
    ICON_EYE
    ICON_LEAF
    ICON_BELL
    ICON_PLUS
    ICON_TRASH
    ICON_HAND
    ICON_BODY
    ICON_COUNT
End Enum

' theme: 0 garden, 1 sunset, 2 ocean, 3 night
Declare Sub Scene_ThemeSky(ByVal theme As Long, ByRef topC As ULong, ByRef midC As ULong, ByRef bot As ULong)
Declare Sub Scene_SetIconCanvas(ByVal c As Canvas Ptr)
Declare Sub Icon_Draw(ByVal icon As Long, ByVal cx As Single, ByVal cy As Single, ByVal size As Single, ByVal col As ULong, ByVal t As Single)
Declare Sub Scene_Cloud(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal s As Single, ByVal col As ULong)
Declare Sub Scene_Flower(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal petals As Long, ByVal petalCol As ULong, ByVal centerCol As ULong, ByVal openF As Single, ByVal rot As Single)
Declare Sub Scene_FlowerStem(ByRef c As Canvas, ByVal x As Single, ByVal groundY As Single, ByVal headY As Single, ByVal sway As Single, ByVal col As ULong)
Declare Sub Scene_Tree(ByRef c As Canvas, ByVal x As Single, ByVal groundY As Single, ByVal size As Single, ByVal growth As Single, ByVal leafCol As ULong, ByVal sway As Single)
Declare Sub Scene_Butterfly(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Scene_Bird(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal t As Single, ByVal col As ULong)
Declare Sub Scene_Fish(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal dirX As Single, ByVal col As ULong, ByVal t As Single)
Declare Sub Scene_Star(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal r As Single, ByVal rot As Single, ByVal col As ULong)
Declare Sub Scene_Balloon(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal r As Single, ByVal col As ULong, ByVal stretch As Single)
Declare Sub Scene_Wave(ByRef c As Canvas, ByVal baseY As Single, ByVal amp As Single, ByVal wl As Single, ByVal phase As Single, ByVal col As ULong)
Declare Sub Scene_Leaf(ByRef c As Canvas, ByVal x As Single, ByVal y As Single, ByVal size As Single, ByVal ang As Single, ByVal col As ULong)
Declare Sub Scene_Hill(ByRef c As Canvas, ByVal baseY As Single, ByVal amp As Single, ByVal wl As Single, ByVal phase As Single, ByVal col As ULong)
' friendly animated background for menus (t = animation clock)
Declare Sub Scene_MenuBackground(ByRef c As Canvas, ByVal t As Double, ByVal theme As Long, ByVal motion As Single, ByVal hc As Long)
Declare Function Scene_Rand(ByVal i As Long) As Single   ' deterministic 0..1 per index
