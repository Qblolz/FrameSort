local _, addon = ...
local eventFrame = nil

local function CanUpdate(frame)
    if not frame then return end
    if not IsInGroup() then return false end
    if InCombatLockdown() then return false end
    if not frame.unit or not frame.unitExists then return end
    if not UnitIsUnit("player", frame.unit) then return end

    return true
end

local function UpdateVisible(frame)
    if not CanUpdate(frame) then return end

    local enabled, mode, _, _ = addon:GetSortMode()

    if not enabled then return end

    frame:SetShown(mode ~= addon.PlayerSortMode.Hidden)
end

local function Run()
    local player = addon:GetPlayerFrame()
    if not player then return end

    UpdateVisible(player)
end

---Initialises the player show/hide module.
function addon:InitPlayerHiding()
    eventFrame = CreateFrame("Frame")
    eventFrame:HookScript("OnEvent", Run)
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    hooksecurefunc("CompactUnitFrame_UpdateVisible", UpdateVisible)
    addon:RegisterPostSortCallback(Run)
end
