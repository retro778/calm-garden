' settings_screen.bas - accessible settings: tabs on the start side, controls on the other
#include once "screens.bi"
#include once "localization.bi"
#include once "audio.bi"
#include once "progress.bi"
#include once "scene.bi"

Dim Shared As Long setTab, setScroll, confirmDelete

Private Sub Changed()
    App_SaveSettings()
End Sub

Sub SettingsScr_Frame()
    If gApp.entering Then setScroll = 0: confirmDelete = 0
    Scr_Background()
    If Ui_Header(L("settings.title")) Then App_Go(SCR_MENU): Exit Sub
    Dim As Long hh = Ui_HeaderH()
    Dim As Long margin = Ui_S(24)
    Dim As Long tabW = Ui_S(230)
    Dim As Long tabH = Ui_S(56)
    Dim As String tabs(0 To 3) = {L("settings.tab.display"), L("settings.tab.sound"), L("settings.tab.breathing"), L("settings.tab.privacy")}
    Dim As Long tabIcons(0 To 3) = {ICON_EYE, ICON_SOUND, ICON_WIND, ICON_HEART}
    For i As Long = 0 To 3
        Dim As Long tx = Ui_MX(margin, tabW)
        Dim As Long ty = hh + Ui_S(10) + i * (tabH + Ui_S(12))
        If Ui_Button("set.tab" & i, tx, ty, tabW, tabH, tabs(i), IIf(setTab = i, BTN_PRIMARY, BTN_NORMAL), tabIcons(i)) Then
            If setTab <> i Then setTab = i: setScroll = 0: confirmDelete = 0
        End If
    Next
    Dim As Long resetY = hh + Ui_S(10) + 4 * (tabH + Ui_S(12)) + Ui_S(10)
    If Ui_Button("set.reset", Ui_MX(margin, tabW), resetY, tabW, Ui_S(48), L("settings.reset"), BTN_SOFT) Then
        Dim As String keepLang = gSet.lang
        Dim As Long keepW = gSet.winW, keepH = gSet.winH, keepFull = gSet.fullscreen
        Settings_Defaults(gSet)
        gSet.lang = keepLang: gSet.winW = keepW: gSet.winH = keepH: gSet.fullscreen = keepFull
        App_ApplyLanguage(): Ui_ApplyTheme(): Audio_ApplySettings(): Progress_SetTracking(gSet.trackingOn)
        Changed()
        Ui_Toast(L("settings.reset_done"))
    End If

    ' panel
    Dim As Long px = margin + tabW + Ui_S(24)
    Dim As Long pw = gApp.w - px - margin
    Dim As Long py = hh + Ui_S(10)
    Dim As Long ph = gApp.h - py - Ui_S(20)
    Dim As Long panelX = Ui_MX(px, pw)
    Ui_Panel(panelX, py, pw, ph)
    Dim As Long pad = Ui_S(26)
    Dim As Long cx = panelX + pad, cw = pw - 2 * pad
    Dim As Long rowH = Ui_S(54)
    Dim As Long sliderH = Ui_S(74)
    Dim As Long gapY = Ui_S(10)
    Cv_PushClip(gCv, panelX + 2, py + Ui_S(8), pw - 4, ph - Ui_S(16))
    Dim As Long y = py + pad - setScroll
    Dim As Long y0 = y
    Dim As Long fsN = Ui_FS(FS_SMALL + 1)

    Select Case setTab
    Case 0 ' display
        Dim As Long li = IIf(gSet.lang = "he", 1, 0)
        If Ui_Choice("set.lang", cx, y, cw, rowH, L("settings.language"), "English|עברית", li) Then
            gSet.lang = IIf(li = 1, "he", "en")
            App_ApplyLanguage()
            Changed()
        End If
        y += rowH + gapY
        Dim As Long fp = gSet.fontPct
        If Ui_Slider("set.font", cx, y, cw, sliderH, L("settings.textsize"), fp, 80, 160, 10, "%") Then gSet.fontPct = fp: Changed()
        y += sliderH + gapY
        If Ui_Toggle("set.child", cx, y, cw, rowH, L("settings.child"), gSet.childMode) Then
            If gSet.childMode Then gSet.adultStyle = 0
            App_ApplyLanguage(): Ui_ApplyTheme(): Changed()
        End If
        y += rowH + gapY
        If Ui_Toggle("set.adult", cx, y, cw, rowH, L("settings.adult"), gSet.adultStyle) Then
            If gSet.adultStyle Then gSet.childMode = 0
            App_ApplyLanguage(): Ui_ApplyTheme(): Changed()
        End If
        y += rowH + gapY
        If Ui_Toggle("set.hc", cx, y, cw, rowH, L("settings.contrast"), gSet.highContrast) Then Ui_ApplyTheme(): Changed()
        y += rowH + gapY
        If Ui_Toggle("set.motion", cx, y, cw, rowH, L("settings.motion"), gSet.reducedMotion) Then Changed()
        y += rowH + gapY
        Dim As Long fsOn = Plat_IsFullscreen()
        If Ui_Toggle("set.full", cx, y, cw, rowH, L("settings.fullscreen"), fsOn) Then
            gSet.fullscreen = fsOn
            Plat_SetFullscreen(fsOn)
            Changed()
        End If
        y += rowH + gapY
        Dim As Long th = gSet.theme
        If Ui_Choice("set.theme", cx, y, cw, rowH, L("settings.theme"), L("theme.garden") & "|" & L("theme.sunset") & "|" & L("theme.ocean") & "|" & L("theme.night"), th) Then gSet.theme = th: Changed()
        y += rowH + gapY
        Dim As Long ap = gSet.animPct
        If Ui_Slider("set.anim", cx, y, cw, sliderH, L("settings.animspeed"), ap, 50, 150, 10, "%") Then gSet.animPct = ap: Changed()
        y += sliderH + gapY
    Case 1 ' sound
        Dim As String st = L(Audio_Status())
        Dim As ULong stc = IIf(Audio_Available(), gTheme.textSoft, gTheme.sim)
        y += Ui_Para(cx, y, cw, st, fsN, stc) + gapY
        If Ui_Toggle("set.sound", cx, y, cw, rowH, L("settings.sound"), gSet.soundOn) Then Audio_ApplySettings(): Changed()
        y += rowH + gapY
        If Ui_Toggle("set.sfx", cx, y, cw, rowH, L("settings.sfx"), gSet.sfxOn) Then Changed()
        y += rowH + gapY
        Dim As Long sv = gSet.sfxVol
        If Ui_Slider("set.sfxvol", cx, y, cw, sliderH, L("settings.sfxvol"), sv, 0, 100, 5, "%") Then gSet.sfxVol = sv: Changed()
        y += sliderH + gapY
        If Ui_Toggle("set.amb", cx, y, cw, rowH, L("settings.ambient"), gSet.ambientOn) Then Audio_ApplySettings(): Changed()
        y += rowH + gapY
        Dim As Long ai = gSet.ambientId
        If Ui_Choice("set.ambid", cx, y, cw, rowH, L("settings.ambientsound"), L("amb.rain") & "|" & L("amb.ocean") & "|" & L("amb.wind") & "|" & L("amb.forest") & "|" & L("amb.birds") & "|" & L("amb.music"), ai) Then
            gSet.ambientId = ai: Changed()
            Audio_SetAmbient(ai)          ' preview
        End If
        y += rowH + gapY
        Dim As Long av = gSet.ambientVol
        If Ui_Slider("set.ambvol", cx, y, cw, sliderH, L("settings.ambientvol"), av, 0, 100, 5, "%") Then gSet.ambientVol = av: Audio_ApplySettings(): Changed()
        y += sliderH + gapY
        If Ui_Toggle("set.music", cx, y, cw, rowH, L("settings.music"), gSet.musicOn) Then Changed()
        y += rowH + gapY
        If Ui_Toggle("set.narr", cx, y, cw, rowH, L("settings.narration"), gSet.narrationOn) Then Changed()
        y += rowH + gapY
        y += Ui_Para(cx, y, cw, L("settings.narration.note"), fsN, gTheme.textSoft) + gapY
    Case 2 ' breathing
        y += Ui_Para(cx, y, cw, L("settings.breath.note"), fsN, gTheme.textSoft) + gapY
        Dim As Long v = gSet.inhaleSec
        If Ui_Slider("set.in", cx, y, cw, sliderH, L("settings.inhale"), v, 2, 8, 1, " " & L("unit.s")) Then gSet.inhaleSec = v: Changed()
        y += sliderH + gapY
        v = gSet.exhaleSec
        If Ui_Slider("set.out", cx, y, cw, sliderH, L("settings.exhale"), v, 2, 10, 1, " " & L("unit.s")) Then gSet.exhaleSec = v: Changed()
        y += sliderH + gapY
        If Ui_Toggle("set.pause", cx, y, cw, rowH, L("settings.pause"), gSet.pauseOn) Then Changed()
        y += rowH + gapY
        v = gSet.pauseSec
        If Ui_Slider("set.pausesec", cx, y, cw, sliderH, L("settings.pausesec"), v, 1, 4, 1, " " & L("unit.s")) Then gSet.pauseSec = v: Changed()
        y += sliderH + gapY
        v = gSet.sessionMin
        If Ui_Slider("set.session", cx, y, cw, sliderH, L("settings.session"), v, 1, 20, 1, " " & L("unit.min")) Then gSet.sessionMin = v: Changed()
        y += sliderH + gapY
    Case 3 ' privacy & progress
        y += Ui_Para(cx, y, cw, L("settings.privacy.note"), fsN, gTheme.textSoft) + gapY
        If Ui_Toggle("set.track", cx, y, cw, rowH, L("settings.tracking"), gSet.trackingOn) Then Progress_SetTracking(gSet.trackingOn): Changed()
        y += rowH + gapY
        If Ui_Toggle("set.rate", cx, y, cw, rowH, L("settings.ratings"), gSet.askRatings) Then Changed()
        y += rowH + gapY
        Dim As Long bw = Ui_S(320)
        If bw > cw Then bw = cw
        Dim As Long bx = IIf(gApp.rtl, cx + cw - bw, cx)
        If confirmDelete = 0 Then
            If Ui_Button("set.delete", bx, y, bw, rowH, L("settings.delete"), BTN_NORMAL, ICON_TRASH) Then confirmDelete = 1
            y += rowH + gapY
        Else
            y += Ui_Para(cx, y, cw, L("settings.delete.confirm"), Ui_FS(FS_BODY), gTheme.text) + gapY
            Dim As Long bw2 = (cw - Ui_S(16)) \ 2
            If bw2 > Ui_S(260) Then bw2 = Ui_S(260)
            If Ui_Button("set.delyes", IIf(gApp.rtl, cx + cw - bw2, cx), y, bw2, rowH, L("settings.delete.yes"), BTN_PRIMARY, ICON_TRASH) Then
                Progress_DeleteAll()
                confirmDelete = 0
                Ui_Toast(L("settings.delete.done"))
            End If
            If Ui_Button("set.delno", IIf(gApp.rtl, cx + cw - 2 * bw2 - Ui_S(16), cx + bw2 + Ui_S(16)), y, bw2, rowH, L("btn.cancel"), BTN_NORMAL) Then confirmDelete = 0
            y += rowH + gapY
        End If
    End Select
    Cv_PopClip(gCv)
    ' scrolling when the content is taller than the panel (large text sizes)
    Dim As Long contentH = (y + setScroll) - y0 + pad
    Dim As Long viewH = ph - Ui_S(16)
    If Ui_Hover(panelX, py, pw, ph) Then setScroll -= gIn.wheel * Ui_S(50)
    ' keep the keyboard focus visible
    Dim As Long fh
    Dim As Long fyy = Ui_FocusY(fh)
    If fyy >= 0 Then
        If fyy < py + Ui_S(10) Then setScroll -= (py + Ui_S(10) - fyy)
        If fyy + fh > py + ph - Ui_S(10) Then setScroll += fyy + fh - (py + ph - Ui_S(10))
    End If
    If Ui_Key(KEY_PGDN) Then setScroll += viewH \ 2
    If Ui_Key(KEY_PGUP) Then setScroll -= viewH \ 2
    If setScroll > contentH - viewH Then setScroll = contentH - viewH
    If setScroll < 0 Then setScroll = 0
    If contentH > viewH Then
        Dim As Long bh = viewH * viewH \ contentH
        Dim As Long by = py + Ui_S(8) + (viewH - bh) * setScroll \ IIf(contentH - viewH > 0, contentH - viewH, 1)
        Dim As Long sbx = IIf(gApp.rtl, panelX + Ui_S(6), panelX + pw - Ui_S(12))
        Cv_FillRoundRect(gCv, sbx, by, Ui_S(6), bh, Ui_S(3), Col_Alpha(gTheme.textSoft, 120))
    End If
End Sub
