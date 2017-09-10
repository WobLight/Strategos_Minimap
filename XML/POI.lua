 if not StrategosMinimapPOI then
     StrategosMinimapPOI = {}
end

function StrategosMinimapPOI:new(o)
    local super = getmetatable(o).__index
    setmetatable(o, { __index = function(self, k)
        return StrategosMinimapPOI[k] or super(self,k)
    end })
end

function StrategosMinimapPOI:buildTooltip()
    return t
end

function StrategosMinimapPOI:buildMenu()
end
