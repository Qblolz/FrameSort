if LE_EXPANSION_LEVEL_CURRENT == nil then
    LE_EXPANSION_CLASSIC = 0
    LE_EXPANSION_BURNING_CRUSADE = 1
    LE_EXPANSION_WRATH_OF_THE_LICH_KING = 2
    LE_EXPANSION_CATACLYSM = 3
    LE_EXPANSION_MISTS_OF_PANDARIA = 4
    LE_EXPANSION_WARLORDS_OF_DRAENOR = 5
    LE_EXPANSION_LEGION = 6
    LE_EXPANSION_BATTLE_FOR_AZEROTH = 7
    LE_EXPANSION_SHADOWLANDS = 8
    LE_EXPANSION_DRAGONFLIGHT = 9
    LE_EXPANSION_THE_WAR_WITHIN = 10
    LE_EXPANSION_MIDNIGHT = 11
    LE_EXPANSION_LEVEL_CURRENT = LE_EXPANSION_MISTS_OF_PANDARIA
end

if not C_Timer then
    local timers = {}
    local nextID = 0
    local running = false

    local driver = CreateFrame("Frame")
    local function onUpdate()
        local now = GetTime()
        local any = false
        for id, timer in pairs(timers) do
            if now >= timer.at then
                timers[id] = nil
                timer.func()
            else
                any = true
            end
        end
        if not any then
            running = false
            driver:SetScript("OnUpdate", nil)
        end
    end

    local function after(delay, func)
        nextID = nextID + 1
        timers[nextID] = { at = GetTime() + (delay or 0), func = func }
        if not running then
            running = true
            driver:SetScript("OnUpdate", onUpdate)
        end
        return nextID
    end

    C_Timer = {
        After = function(first, second, third)
            if first == C_Timer then
                return after(second, third)
            end
            return after(first, second)
        end,
    }
end

if not GameTooltip_SetTitle then
    GameTooltip_SetTitle = function(tooltip, title, r, g, b)
        tooltip:SetText(title, r, g, b)
    end
end

if not GameTooltip_AddNormalLine then
    GameTooltip_AddNormalLine = function(tooltip, text, wrap)
        tooltip:AddLine(text, 1, 1, 1, wrap)
    end
end

if not GameTooltip_AddColoredLine then
    GameTooltip_AddColoredLine = function(tooltip, text, color, wrap)
        local r = color and color.r or 1
        local g = color and color.g or 1
        local b = color and color.b or 1
        tooltip:AddLine(text, r, g, b, wrap)
    end
end

if not GameTooltip_AddInstructionLine then
    GameTooltip_AddInstructionLine = function(tooltip, text, wrap)
        tooltip:AddLine(text, 0.8, 0.8, 0.8, wrap)
    end
end

-- MoP lacks Texture:SetColorTexture (added in a later expansion); map to SetTexture(r,g,b,a).
do
    local probe = UIParent:CreateTexture()
    local mt = probe and getmetatable(probe)
    local methods = mt and mt.__index
    if type(methods) == "table" and not methods.SetColorTexture then
        methods.SetColorTexture = function(self, r, g, b, a)
            self:SetTexture(r, g, b, a)
        end
    end
end
