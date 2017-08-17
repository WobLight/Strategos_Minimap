StrategosMinimap_Safe = {
    GetNumMapOverlays = GetNumMapOverlays,
}
local StrategosMinimapSettingsDefaults = {
    shrunk = true,
    animatedBorder = true,
    battlegroundOnly = false,
    groupOnly = false
}

local frame = CreateFrame("frame")
local function loader()
    if arg1 == "Strategos_Minimap" then
        if StrategosMinimapSettings == nil then
            StrategosMinimapSettings = {dataVersion = "1.0.0"}
        end
        setmetatable(StrategosMinimapSettings, {__index = StrategosMinimapSettingsDefaults})
        
        StrategosMinimap_UpdateFormat()
        this:UnregisterEvent("ADDON_LOADED")
        
        StrategosMinimap:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|c00cccc00Strategos|r [|c0000ff00Minimap|r] loaded.")
    end
end

frame:SetScript("OnEvent", loader)
frame:RegisterEvent("ADDON_LOADED")
