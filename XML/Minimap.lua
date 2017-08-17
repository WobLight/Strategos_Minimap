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
    local istar = UnitIsUnit("target",unit)
    local mark = GetRaidTargetIndex(unit)
    if istar or mark then
        colorize(this.texHigh)
        if this.texbg then this.texbg:Hide() end
        this.tex:Hide()
        if istar then
            this.texHigh:SetTexCoord(0,1/4,0,1/4)
        else
            this.texHigh:SetTexCoord(mod(mark,4)/4,(mod(mark,4)+1)/4,floor(mark/4)/4,(floor(mark/4)+1)/4)
        end
        this.texHigh:Show()
    elseif GetRaidTargetIndex(unit) then
        
    else
        if UnitInParty(unit) then
            this.texParty:Show()
        else
            this.texParty:Hide()
        end
        if this.texbg then colorize(this.texbg) this.texbg:Show() end
        this.tex:Show()
        this.texHigh:Hide()
    end
    this:SetAlpha(0.50 + p*0.50)
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
                if tox + tw >= 60 and tox <= 180 then
                    if tox < 60 then
                        tc0 = (60 - tox) / tw * tc1
                        tox = 60
                        tw = tw + tox - 60
                    end
                    if tox + tw > 180 then
                        tc1 = (tox + tw  - 180) / tw * tc1
                        tw = 180 - tox
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
    StrategosMinimap_UpdateFormat()
end
StrategosMinimapHandles.ZONE_CHANGED_NEW_AREA =StrategosMinimapHandles.WORLD_MAP_UPDATE
StrategosMinimapHandles.ZONE_CHANGED =StrategosMinimapHandles.WORLD_MAP_UPDATE

function StrategosMinimap_OnLoad()
    this:SetScript("OnEvent",function() (StrategosMinimapHandles[event] or debug("STRATEGOS MINIMAP: Unhendled event "..event))()end)
    this:RegisterEvent("WORLD_MAP_UPDATE")
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
            f = CreateFrame("frame",fn,this,"StrategosUnitDotTemplate")
            f.i = i
            f.texbg = getglobal(f:GetName().."Aura")
            f.tex = getglobal(f:GetName().."Normal")
            f.texParty = getglobal(f:GetName().."Party")
            f.texHigh = getglobal(f:GetName().."Highlight")
            f.texFlag = getglobal(f:GetName().."Flag")
        else
            f:Show()
        end
        local unit = gt..i
        f.unit = unit
        local x, y = (function(x,y)return x*this:GetWidth(), -y*this:GetHeight()end)(GetPlayerMapPosition(unit))
        if x == 0 and y == 0 or UnitIsUnit(unit,"player") then
            f:Hide()
        else
            f:Show()
        end
        f:SetPoint("CENTER",this,"TOPLEFT", x, y)
    end
end

function StrategosMinimap_SettingsMenu(level)
    local info = UIDropDownMenu_CreateInfo()
    if level == 1 then
        info.text, info.hasArrow = "Format", true
        UIDropDownMenu_AddButton(info)
        info.text, info.hasArrow, info.checked, info.func = "Battleground only", false, StrategosMinimapSettings.battlegroundOnly, StrategosMinimap_ToggleBGOnly
        UIDropDownMenu_AddButton(info)
        info.text, info.hasArrow, info.checked, info.func = "Party/Raid only", false, StrategosMinimapSettings.groupOnly, StrategosMinimap_ToggleGroupOnly
        UIDropDownMenu_AddButton(info)
    elseif UIDROPDOWNMENU_MENU_VALUE == "Format" then
        info.text, info.hasArrow, info.checked, info.enabled, info.keepShownOnClick, info.func = "Narrow", true, StrategosMinimapSettings.shrunk, StrategosMinimapSettings.shrunk, true, StrategosMinimap_ToggleShrink
        UIDropDownMenu_AddButton(info,2)
    elseif UIDROPDOWNMENU_MENU_VALUE == "Narrow" then
        info.text, info.checked, info.keepShownOnClick, info.func = "Animated", StrategosMinimapSettings.animatedBorder, true, StrategosMinimap_ToggleAnimatedBorder
        UIDropDownMenu_AddButton(info,3)
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
    StrategosMinimapOverlay:SetAllPoints(StrategosMinimap_GetCurrentAnchoring())
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
end
