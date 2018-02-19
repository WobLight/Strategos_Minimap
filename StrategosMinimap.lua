StrategosMinimap_Safe = {
    GetNumMapOverlays = GetNumMapOverlays,
}
if not StrategosMinimap_Plugins then
    StrategosMinimap_Plugins = {}
end

if not StrategosMinimap_ActivePlugins then
    StrategosMinimap_ActivePlugins = {}
end

local StrategosMinimapSettingsDefaults = {
    shrunk = true,
    animatedBorder = true,
    battlegroundOnly = false,
    groupOnly = false,
    pluginBlacklist = {},
    scale = 1,
    scaleShrunk = 1,
    poiScale = 1,
    unitScale = 1
}

function StrategosMinimap_Print(t)
    DEFAULT_CHAT_FRAME:AddMessage("|c00cccc00Strategos|r [|c0000ff00Minimap|r]: "..t)
end

local function print(t)
    DEFAULT_CHAT_FRAME:AddMessage(t)
end

local frame = CreateFrame("frame")

function StrategosMinimap_LoadPlugins()
    StrategosMinimap_Print("loading plugins...")
    for k,p in StrategosMinimap_Plugins do
        if not StrategosMinimapSettings.pluginBlacklist[p.name] then
            if p.load then p.load() end
            p.frames = p.frames or {}
            tinsert(StrategosMinimap_ActivePlugins, p)
            print(format("    [%d/%d] %s loaded", k, getn(StrategosMinimap_Plugins), p.name))
        end
    end
    frame:UnregisterEvent("ADDON_LOADED")
end
    

local function loader()
    if arg1 == "Strategos_Minimap" then
        if StrategosMinimapSettings == nil then
            StrategosMinimapSettings = {dataVersion = "1.0.0"}
        end
        setmetatable(StrategosMinimapSettings, {__index = StrategosMinimapSettingsDefaults})
        
        StrategosMinimap_UpdateFormat()
        
        StrategosMinimap:Show()
        StrategosMinimap_Print("loaded.")
        
        frame:UnregisterEvent("ADDON_LOADED")
        frame:RegisterEvent("PLAYER_LOGIN")
        frame:SetScript("OnEvent", StrategosMinimap_LoadPlugins)
    end
end

frame:SetScript("OnEvent", loader)
frame:RegisterEvent("ADDON_LOADED")

function StrategosCore.GetCursorPosition(frame)
    if not frame then
        return GetCursorPosition()
    end
    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    return x/scale - frame:GetLeft(), y/scale - frame:GetBottom()
end
