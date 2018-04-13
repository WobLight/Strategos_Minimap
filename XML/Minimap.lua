local GetNumMapOverlays = StrategosMinimap_Safe.GetNumMapOverlays

function StrategosMinimapDot_Update()
    if not UnitExists(this.unit) then
        this:Hide()
        return
    end
    local i = this.i
    local unit = this.unit
    local p = UnitHealth(unit)/UnitHealthMax(unit)
    local function colorize(t)
        if UnitIsGhost(unit) then
            t:SetVertexColor(0.3,0.3,1)
        elseif UnitIsDead(unit) then
            t:SetVertexColor(0.7,0.7,1)
        else
            t:SetVertexColor((1 - p)*2,p*2,0)
        end
    end
    local function getCoord(idx)
        local x, y = mod(idx,4), floor(idx/4)
        return {x/4,(x+1)/4,y/4,(y+1)/4}
    end
    
    local tex, coords, color
    
    local mark = GetRaidTargetIndex(unit)
    if UnitIsUnit("target",unit) then
        coords = getCoord(0)
    elseif mark then
        coords = getCoord(mark)
    else
        for _,p in StrategosMinimap_ActivePlugins do
            if p.getHighlight then
                local ptex, pcoords, pcolor = p:getHighlight(unit)
                if ptex then
                    tex = ptex
                    coords = pcoords
                elseif pcoords then
                    tex = nil
                    coords = getCoord(pcoords)
                end
                pcolor = pcolor or color
            end
        end
    end
    
    if tex or coords then
        this.texHigh:Show()
    else
        this.texHigh:Hide()
    end
    if this.texHigh:IsVisible() then
        this.texHigh:SetTexture(tex and tex or "Interface\\Addons\\Strategos_Minimap\\Textures\\DotHighlights.tga")
        if coords then
            this.texHigh:SetTexCoord(unpack(coords))
        end
        if color then
            this.texHigh:SetVertexColor(unpack(color))
        else
            colorize(this.texHigh)
        end
            
        if this.texbg then this.texbg:Hide() end
        this.tex:Hide()
        this:SetAlpha(1)
    else
        if UnitInParty(unit) then
            this.texParty:Show()
        else
            this.texParty:Hide()
        end
        if this.texbg then colorize(this.texbg) this.texbg:Show() end
        this.tex:Show()
        this:SetAlpha(0.50 + p*0.50)
    end
end

function StrategosMinimap_DotMenu(level)
    local info = {}
    local n = GetNumRaidMembers()
    if n == 0 then
        n = GetNumPartyMembers()
    end
    for i = 1,n do
        local f = getglobal("StrategosMinimapDot"..i)
        if f and MouseIsOver(f) and f:IsVisible() then
            local name = UnitName(f.unit)
            info.text, info.func = name, function() ChatFrame_SendTell(name, DEFAULT_CHAT_FRAME)end
            UIDropDownMenu_AddButton(info)
        end
    end
    for _,p in StrategosMinimap_ActivePlugins do
        for _,f in p.frames do
            if MouseIsOver(f) and f:IsVisible() then
                local infos = f:buildMenu()
            end
        end
    end
end

function StrategosMinimapOverlay_OnEnter()
    StrategosMinimapTooltip.last = GetTime() - 0.2
    StrategosMinimapTooltip.update = true
    StrategosMinimapTooltip_OnUpdate()
end

function StrategosMinimapTooltip_OnUpdate()
    local x = GetCursorPosition()
    local a = StrategosMinimap_GetCurrentAnchoring()
    local center = a:GetCenter() * a:GetEffectiveScale()
    local mx, my = StrategosCore.GetCursorPosition(a)
    local offset = 4
    if ( x > center ) then
        StrategosMinimapTooltip:SetOwner(a , "ANCHOR_LEFT", mx - offset, offset + my - a:GetHeight())
    else
        StrategosMinimapTooltip:SetOwner(a , "ANCHOR_RIGHT", mx + offset - a:GetWidth(), offset + my - a:GetHeight())
    end
    if not StrategosMinimapTooltip.update then return end
    if StrategosMinimapTooltip.last + 0.2 - GetTime() <= 0 then
        local n = GetNumRaidMembers()
        if n == 0 then
            n = GetNumPartyMembers()
        end
        local nl = ""
        local text = ""
        local nrm = 0
        local function cc(t)
            if t and strlen(t) > 0 then
                text = text .. nl .. t
                nl = "\n"
            end
        end
        for i = 1,n do
            local f = getglobal("StrategosMinimapDot"..i)
            if MouseIsOver(f) and f:IsVisible() then
                cc(UnitName(f.unit))
                nrm = nrm +1
            end
        end
        if nrm > 5 then cc(format("|c0000ff00%s members|r",nrm)) end
        for _,p in StrategosMinimap_ActivePlugins do
            for _,f in p.frames do
                if MouseIsOver(f) and f:IsVisible() then
                    cc(f:buildTooltip())
                end
            end
        end
        for i = 1, StrategosMinimap.lastPOI or 0 do
            local f = getglobal("StrategosMinimapPOI"..i)
            if MouseIsOver(f) and f:IsVisible() then
                cc(format("|c00FFFFFF%s|r", f.name.. (f.descr == "" and "" or ": "..f.descr)))
            end
        end
        StrategosMinimapTooltip:SetText(text)
        StrategosMinimapTooltip:Show()
    end
end

function StrategosMinimapOverlay_OnClick()
    local n = GetNumRaidMembers()
    if n == 0 then
        n = GetNumPartyMembers()
    end
    local targets = {}
    local t
    local k = 0
    local first
    for i = 1,n do
        local f = getglobal("StrategosMinimapDot"..i)
        if MouseIsOver(f) and f:IsVisible() then
            targets[f.unit] = true
            k = k +1
            if not first then
                first = f.unit
            end
            if not t then
                if not StrategosMinimap.lastDotTarget then
                    StrategosMinimap.lastDotTarget = f.unit
                    t = f.unit
                else
                    if StrategosMinimap.lastDotTarget < f.unit then
                        t = f.unit
                    end
                end
            end
        end
    end
    if arg1=="LeftButton" then
        if not t then
            t = first
        end
        if targets[StrategosMinimap.lastDotTarget] and not UnitIsUnit("target", StrategosMinimap.lastDotTarget) then
            TargetUnit(StrategosMinimap.lastDotTarget)
        else
            if not t then
                return
            end
            TargetUnit(t)
            StrategosMinimap.lastDotTarget = t
        end
    else
        for _,p in StrategosMinimap_ActivePlugins do
            for _,f in p.frames do
                if MouseIsOver(f) and f:IsVisible() then
                    k = k+1
                end
            end
        end
        if k == 0 then
            return
        end
        local ma = StrategosMinimapMenuAnchor
        if not ma then
            ma = CreateFrame("frame", "StrategosMinimapMenuAnchor", UIParent)
            ma:SetWidth(32)
            ma:SetHeight(32)
        end
        ma:SetPoint("CENTER",UIParent, StrategosCore.GetCursorPosition(UIParent))
        ToggleDropDownMenu(1,nil,StrategosMinimapDotMenu, ma:GetName(), StrategosCore.GetCursorPosition(ma))
    end
end

StrategosMinimapHandles = {}
function StrategosMinimapHandles.WORLD_MAP_UPDATE()
    StrategosMinimap_UpdateVisibility()
    local n,mw,mh = GetMapInfo()
    for i = 1,12 do
        local f = getglobal(this:GetName().."Tile"..i)
        n = n or "World"
        f:SetTexture("Interface\\WorldMap\\"..n.."\\"..n..i)
    end
    local textureCount = 1;
    local function trcr(x) return 60*x/256 end
    local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight
    for i = 1, GetNumMapOverlays() do
        local textureName, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(i)
        local numTexturesWide = ceil(textureWidth/256)
        local numTexturesTall = ceil(textureHeight/256)
        for j=1, numTexturesTall do
            if ( j < numTexturesTall ) then
                texturePixelHeight = 256
                textureFileHeight = 256
            else
                texturePixelHeight = mod(textureHeight, 256)
                if ( texturePixelHeight == 0 ) then
                    texturePixelHeight = 256
                end
                textureFileHeight = 16
                while(textureFileHeight < texturePixelHeight) do
                    textureFileHeight = textureFileHeight * 2
                end
            end
            for k=1, numTexturesWide do
                local fn = this:GetName().."Overlay"..textureCount
                local texture = getglobal(fn)
                if texture == nil then
                    texture = this:CreateTexture(fn,"Artwork")
                    this.lastOverlay = textureCount
                end
                if ( k < numTexturesWide ) then
                    texturePixelWidth = 256;
                    textureFileWidth = 256;
                else
                    texturePixelWidth = mod(textureWidth, 256)
                    if ( texturePixelWidth == 0 ) then
                            texturePixelWidth = 256
                    end
                    textureFileWidth = 16
                    while(textureFileWidth < texturePixelWidth) do
                            textureFileWidth = textureFileWidth * 2
                    end
                end
                local tox, tw, tc0, tc1 = trcr(offsetX + (256 * (k-1))), trcr(texturePixelWidth), 0, texturePixelWidth/textureFileWidth
                if tox + tw >= 60 and tox <= 180 or not StrategosMinimap_Shrunk() then
                    if StrategosMinimap_Shrunk() then
                        if tox < 60 then
                            tc0 = (60 - tox) / tw * tc1
                            tox = 60
                            tw = tw + tox - 60
                        end
                        if tox + tw > 180 then
                            tc1 = (tox + tw  - 180) / tw * tc1
                            tw = 180 - tox
                        end
                    end
                    texture:SetWidth(tw)
                    texture:SetHeight(trcr(texturePixelHeight))
                    texture:SetTexCoord(tc0, tc1, 0, texturePixelHeight/textureFileHeight)
                    texture:ClearAllPoints()
                    texture:SetPoint("TOPLEFT", this, "TOPLEFT", tox, trcr(-(offsetY + (256 * (j - 1)))))
                    texture:SetTexture(textureName..(((j - 1) * numTexturesWide) + k))
                    texture:Show()
                    textureCount = textureCount +1
                else
                    texture:Hide()
                end
            end
        end
    end
    for i = textureCount, this.lastOverlay or 0 do
        getglobal(this:GetName().."Overlay"..i):Hide()
    end
    StrategosMinimap_UpdatePOIs()
    StrategosMinimap_UpdateFormat()
end

function StrategosMinimapHandles.ZONE_CHANGED_NEW_AREA()
    SetMapToCurrentZone()
    StrategosMinimapHandles.WORLD_MAP_UPDATE()
end

function StrategosMinimapHandles.ZONE_CHANGED()
    SetMapToCurrentZone()
    StrategosMinimapHandles.WORLD_MAP_UPDATE()
end

function StrategosMinimap_UpdatePOIs()
    local n = GetNumMapLandmarks()
    for i = 1, n do
        local name, descr, textureIndex, x, y = GetMapLandmarkInfo(i)
        local f
        if not StrategosMinimap.lastPOI or StrategosMinimap.lastPOI < i then
            f = CreateFrame("frame", "StrategosMinimapPOI"..i, StrategosMinimap, "StrategosMinimapPOITemplate")
            StrategosMinimapPOI:new(f)
            f:GetRegions():SetTexture("Interface\\Minimap\\POIIcons")
            f:SetScale(StrategosMinimap_FormatSettings().poiScale)
            f.anchor = CreateFrame("frame",f:GetName().."Anchor",f:GetParent())
            f.anchor:SetWidth(1)
            f.anchor:SetHeight(1)
            f:SetPoint("CENTER",f.anchor)
            StrategosMinimap.lastPOI = i
        else
            f = getglobal("StrategosMinimapPOI"..i)
        end
        f:GetRegions():SetTexCoord(WorldMap_GetPOITextureCoords(textureIndex))
        f.anchor:SetPoint("CENTER", StrategosMinimap, "TOPLEFT", x*StrategosMinimap:GetWidth(), - y*StrategosMinimap:GetHeight())
        f.name, f.descr = name, descr
        f:Show()
    end
    for i = n+1, StrategosMinimap.lastPOI or 0 do
        getglobal("StrategosMinimapPOI"..i):Hide()
    end
end

StrategosMinimapHandles.UPDATE_WORLD_STATES = StrategosMinimap_UpdatePOIs

function StrategosMinimap_OnLoad()
    this:SetScript("OnEvent",function() (StrategosMinimapHandles[event] or debug("STRATEGOS MINIMAP: Unhendled event "..event))()end)
    this:RegisterEvent("WORLD_MAP_UPDATE")
    this:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    this:RegisterEvent("ZONE_CHANGED")
    this:RegisterEvent("UPDATE_WORLD_STATES")
    CreateMiniWorldMapArrowFrame(StrategosMinimap)
end
    
function StrategosMinimap_Update()
    UpdateWorldMapArrowFrames()
    local px,py = GetPlayerMapPosition("player")
    if px == 0 and py == 0 then 
        ShowMiniWorldMapArrowFrame(0)
    else
        PositionMiniWorldMapArrowFrame("CENTER", "StrategosMinimap", "TOPLEFT", px*StrategosMinimap:GetWidth(), -py*StrategosMinimap:GetHeight())
        ShowMiniWorldMapArrowFrame(1)
    end
    if StrategosMinimap_IsAnimatedBorder() then
        if this.seq == nil then
            this.seq = 0
        end
        if this.last == nil or this.last > 1/16 then
            local n = 4
            StrategosMinimap_CurrentBorder():SetTexCoord(mod(this.seq,n)/n,(mod(this.seq,4)+1)/n,floor(this.seq/4)/n,floor(this.seq/4+1)/n)
            this.seq = mod(this.seq + 1,n^2)
            this.last = 0
        else
            this.last = this.last + arg1
        end
    end
    local n = GetNumRaidMembers()
    local gt = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        gt = "party"
    end
    for i = 1,n do
        local fn = this:GetName().."Dot"..i
        local f = getglobal(fn)
        if f == nil then
            f = CreateFrame("button",fn,this,"StrategosUnitDotTemplate")
            f.i = i
            f.texbg = getglobal(f:GetName().."Aura")
            f.tex = getglobal(f:GetName().."Normal")
            f.texParty = getglobal(f:GetName().."Party")
            f.texHigh = getglobal(f:GetName().."Highlight")
            f.texCustom = getglobal(f:GetName().."Custom")
            f.action = function (self) ChatFrame_SendTell(UnitName(self.unit), DEFAULT_CHAT_FRAME) end
            f.anchor = CreateFrame("frame",f:GetName().."Anchor",f:GetParent())
            f.anchor:SetWidth(1)
            f.anchor:SetHeight(1)
            f:SetPoint("CENTER",f.anchor)
            f:SetScale(StrategosMinimap_FormatSettings().unitScale)
        else
            f:Show()
        end
        local unit = gt..i
        f:SetID(i)
        f.unit = unit
        local x, y = (function(x,y)return x*this:GetWidth(), -y*this:GetHeight()end)(GetPlayerMapPosition(unit))
        if x == 0 and y == 0 or UnitIsUnit(unit,"player") then
            f:Hide()
        else
            f:Show()
        end
        f.anchor:SetPoint("CENTER",this,"TOPLEFT", x, y)
    end
end

function StrategosMinimap_SettingsMenu(level)
    local info = {}
    if level == 1 then
        info.text, info.hasArrow = "Format", true
        UIDropDownMenu_AddButton(info)
        info.text, info.hasArrow, info.checked, info.func = "Battleground only", false, StrategosMinimapSettings.battlegroundOnly, StrategosMinimap_ToggleBGOnly
        UIDropDownMenu_AddButton(info)
        info.text, info.hasArrow, info.checked, info.func = "Party/Raid only", false, StrategosMinimapSettings.groupOnly, StrategosMinimap_ToggleGroupOnly
        UIDropDownMenu_AddButton(info)
        if next(StrategosMinimap_Plugins) then
            info.text, info.hasArrow, info.checked, info.title, info.func = "Plugins", true, false, true, nil
            UIDropDownMenu_AddButton(info)
        end
    elseif UIDROPDOWNMENU_MENU_VALUE == "Format" then
        info.text, info.hasArrow, info.checked, info.enabled, info.keepShownOnClick, info.func = "Narrow", true, StrategosMinimapSettings.shrunk, StrategosMinimapSettings.shrunk, true, StrategosMinimap_ToggleShrink
        UIDropDownMenu_AddButton(info,2)
    elseif UIDROPDOWNMENU_MENU_VALUE == "Narrow" then
        info.text, info.checked, info.keepShownOnClick, info.func = "Animated", StrategosMinimapSettings.animatedBorder, true, StrategosMinimap_ToggleAnimatedBorder
        UIDropDownMenu_AddButton(info,3)
    elseif UIDROPDOWNMENU_MENU_VALUE == "Plugins" then
        for i,p in StrategosMinimap_Plugins do
            info.text, info.checked, info.keepShownOnClick, info.func, info.arg1 = p.name, not StrategosMinimapSettings.pluginBlacklist[p.name], true, StrategosMinimap_TogglePlugin, p.name
            UIDropDownMenu_AddButton(info,2)
        end
    end
end

function StrategosMinimap_ToggleShrink()
    StrategosMinimapSettings.shrunk = not StrategosMinimapSettings.shrunk
    StrategosMinimap_UpdateFormat()
end

function StrategosMinimap_ToggleAnimatedBorder()
    StrategosMinimapSettings.animatedBorder = not StrategosMinimapSettings.animatedBorder
    StrategosMinimap_UpdateBorder()
end

function StrategosMinimap_UpdateVisibility()
    if IsInInstance() and not StrategosMinimap_IsBG() or StrategosMinimapSettings.battlegroundOnly and not StrategosMinimap_IsBG() or StrategosMinimapSettings.groupOnly and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        StrategosMinimap:Hide()
        StrategosMinimapOverlay:Hide()
    else
        StrategosMinimap:Show()
        StrategosMinimapOverlay:Show()
    end
end

function StrategosMinimap_ToggleBGOnly()
    StrategosMinimapSettings.battlegroundOnly = not StrategosMinimapSettings.battlegroundOnly
    StrategosMinimap_UpdateVisibility()
end

function StrategosMinimap_ToggleGroupOnly()
    StrategosMinimapSettings.groupOnly = not StrategosMinimapSettings.groupOnly
    StrategosMinimap_UpdateVisibility()
end

function StrategosMinimap_GetCurrentAnchoring()
    return StrategosMinimap_Shrunk() and StrategosMinimapAnchoringNarrow or StrategosMinimapAnchoring
end

function StrategosMinimap_UpdateAnchoringAndSize()
    local a = StrategosMinimap_GetCurrentAnchoring()
    StrategosMinimapOverlay:SetPoint("CENTER",a)
    StrategosMinimapOverlay:SetWidth(a:GetWidth())
    StrategosMinimapOverlay:SetHeight(a:GetHeight())
end

function StrategosMinimap_CurrentBorder()
    return StrategosMinimap_Shrunk() and StrategosMinimapBorderNarrow or StrategosMinimapBorder
end
function StrategosMinimap_IsBG()
    return ({IsInInstance()})[2] == "pvp"
end

function StrategosMinimap_Shrunk()
    return StrategosMinimapSettings.shrunk and StrategosMinimap_IsBG()
end

function StrategosMinimap_UpdateBorder()
    if StrategosMinimap_Shrunk() then
        if StrategosMinimapSettings.animatedBorder then
            StrategosMinimapBorderNarrow:SetTexture("Interface\\AddOns\\Strategos_Minimap\\Textures\\MapBorderNarrowAnimated.tga")
        else
            StrategosMinimapBorderNarrow:SetTexture("Interface\\AddOns\\Strategos_Minimap\\Textures\\MapBorderNarrow.tga")
        end
        StrategosMinimapBorderNarrow:Show()
        StrategosMinimapBorder:Hide()
    else
        StrategosMinimapBorder:Show()
        StrategosMinimapBorderNarrow:Hide()
    end
    if not StrategosMinimap_IsAnimatedBorder() then
        StrategosMinimap_CurrentBorder():SetTexCoord(0,1,0,1)
    end
end

function StrategosMinimap_IsAnimatedBorder()
    return StrategosMinimap_Shrunk() and StrategosMinimapSettings.animatedBorder
end

function StrategosMinimap_UpdateFormat()
    for _,n in {1,4,5,8,9,12} do
        local t = getglobal("StrategosMinimapTile"..n)
        if StrategosMinimap_Shrunk() then
            t:Hide()
        else
            t:Show()
        end
    end
    StrategosMinimap_UpdateBorder()
    StrategosMinimap_UpdateAnchoringAndSize()
    StrategosMinimap_UpdateScale()
    StrategosMinimap_UpdatePOIScale()
    StrategosMinimap_UpdateUnitScale()
end

function StrategosMinimap_FormatSettings()
    return StrategosMinimap_Shrunk() and StrategosMinimapSettings.shrunkSettings or StrategosMinimapSettings
end

function StrategosMinimap_UpdateScale()
    StrategosMinimap:SetScale(StrategosMinimap_FormatSettings().scale)
    StrategosMinimapOverlay:SetScale(StrategosMinimap_FormatSettings().scale)
    
end

function StrategosMinimap_UpdatePOIScale()
    for i = 1, StrategosMinimap.lastPOI or 0 do
        getglobal("StrategosMinimapPOI"..i):SetScale(StrategosMinimap_FormatSettings().poiScale)
    end
end

function StrategosMinimap_SetPOIScale(s)
    StrategosMinimap_FormatSettings().poiScale = s
    StrategosMinimap_UpdatePOIScale()
end

function StrategosMinimap_UpdateUnitScale()
    for i = 1, 40 do
        local f = getglobal("StrategosMinimapDot"..i)
        if not f then return end
        
        f:SetScale(StrategosMinimap_FormatSettings().unitScale)
    end
end

function StrategosMinimap_SetUnitScale(s)
    StrategosMinimap_FormatSettings().unitScale = s
    StrategosMinimap_UpdateUnitScale()
end

function StrategosMinimap_SetScale(s)
    StrategosMinimap_FormatSettings().scale = s
    StrategosMinimap_UpdateScale()
end
