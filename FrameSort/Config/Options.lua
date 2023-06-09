local _, addon = ...
addon.OptionsBuilder = {
    VerticalSpacing = 15,
    HorizontalSpacing = 50
}

local builder = addon.OptionsBuilder
local verticalSpacing = addon.OptionsBuilder.VerticalSpacing
local horizontalSpacing = addon.OptionsBuilder.HorizontalSpacing

function builder:TextShim(frame)

    frame.Text = frame.text
end

---Adds the title UI components.
---@param panel table the parent UI panel.
---@return table The bottom left most control to use for anchoring subsequent UI components.
local function BuiltTitle(panel)
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", verticalSpacing, -verticalSpacing)
    title:SetText("FrameSort")

    local lines = {
        Group = "party1 > party2 > partyN > partyN+1",
        Role  = "tank > healer > dps",
        Alpha = "NameA > NameB > NameZ"
    }

    local anchor = title
    local keyWidth = 50
    local i = 1
    for k, v in pairs(lines) do
        local keyText = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        keyText:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -verticalSpacing * 0.75)
        keyText:SetText(k .. ": ")
        keyText:SetWidth(keyWidth)
        keyText:SetJustifyH("LEFT")
        anchor = keyText

        local valueText = panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
        valueText:SetPoint("LEFT", keyText, "RIGHT")
        valueText:SetText(v)
        i = i + 1
    end

    return anchor
end

---Adds a row of the player and group sort mode checkboxes.
---@param parentPanel table the parent UI panel.
---@param pointOffset table a UI component used as a relative position anchor for the new components.
---@param labelText string the text to display on the enabled checkbox.
---@param sortingEnabled boolean whether sorting is currently enabled.
---@param playerSortMode string current player sort mode.
---@param sortMode string current group sort mode.
---@param reverse boolean current reverse sorting status.
---@param onEnabledChanged function function(enabled) callback function when enabled changes.
---@param onPlayerSortModeChanged function function(mode) callback function when the player sort mode changes.
---@param onSortModeChanged function function(mode) callback function when the group sort mode changes.
---@return table The bottom left most control to use for anchoring subsequent UI components.
local function BuildSortModeCheckboxes(
    parentPanel,
    pointOffset,
    labelText,
    sortingEnabled,
    playerSortMode,
    sortMode,
    reverse,
    onEnabledChanged,
    onPlayerSortModeChanged,
    onSortModeChanged,
    onReverseChanged)
    local enabled = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    -- not sure why, but checkbox left seems to be off by about 4 units by default
    enabled:SetPoint("TOPLEFT", pointOffset, "BOTTOMLEFT", -4, -verticalSpacing)
    builder:TextShim(enabled)
    enabled.Text:SetText(" " .. labelText)
    enabled.Text:SetFontObject("GameFontNormalLarge")
    enabled:SetChecked(sortingEnabled)
    enabled:HookScript("OnClick", function() onEnabledChanged(enabled:GetChecked()) end)

    local playerLabel = parentPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    playerLabel:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -verticalSpacing)
    playerLabel:SetText("Player: ")

    local top = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    builder:TextShim(top)
    top.Text:SetText("Top")
    top:SetPoint("LEFT", playerLabel, "RIGHT", horizontalSpacing / 2, 0)
    top:SetChecked(playerSortMode == addon.PlayerSortMode.Top)

    local middle = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    builder:TextShim(middle)
    middle.Text:SetText("Middle")
    middle:SetPoint("LEFT", top, "RIGHT", horizontalSpacing, 0)
    middle:SetChecked(playerSortMode == addon.PlayerSortMode.Middle)

    local bottom = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    builder:TextShim(bottom)
    bottom.Text:SetText("Bottom")
    bottom:SetPoint("LEFT", middle, "RIGHT", horizontalSpacing, 0)
    bottom:SetChecked(playerSortMode == addon.PlayerSortMode.Bottom)

    local hidden = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    builder:TextShim(hidden)
    hidden.Text:SetText("Hidden")
    hidden:SetPoint("LEFT", bottom, "RIGHT", horizontalSpacing, 0)
    hidden:SetChecked(playerSortMode == addon.PlayerSortMode.Hidden)

    local playerModes = {
        [top] = addon.PlayerSortMode.Top,
        [middle] = addon.PlayerSortMode.Middle,
        [bottom] = addon.PlayerSortMode.Bottom,
        [hidden] = addon.PlayerSortMode.Hidden,
    }

    local function onPlayerClick(sender)
        -- uncheck the others
        for chkbox, _ in pairs(playerModes) do
            if chkbox ~= sender then chkbox:SetChecked(false) end
        end

        local mode = playerModes[sender]
        onPlayerSortModeChanged(mode)
        addon:TrySort()
    end

    for chkbox, _ in pairs(playerModes) do
        chkbox:HookScript("OnClick", onPlayerClick)
    end

    local modeLabel = parentPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    modeLabel:SetPoint("TOPLEFT", playerLabel, "BOTTOMLEFT", 0, -verticalSpacing * 1.5)
    modeLabel:SetText("Sort: ")

    -- why use checkboxes instead of a dropdown box?
    -- because the dropdown box control has taint issues that haven't been fixed for years
    -- also it seems to have become much worse in dragonflight
    -- so while a dropdown would be better ui design, it's too buggy to use at the moment
    local group = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    group:SetPoint("LEFT", top, "LEFT")
    -- TODO: not sure why this doesn't align well even when aligning TOP/BOTTOM, so just hacking in a +10 to fix it for now
    group:SetPoint("TOP", modeLabel, "TOP", 0, 10)
    builder:TextShim(group)
    group.Text:SetText(addon.GroupSortMode.Group)
    group:SetChecked(sortMode == addon.GroupSortMode.Group)

    local role = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    role:SetPoint("LEFT", group, "RIGHT", horizontalSpacing, 0)
    builder:TextShim(role)
    role.Text:SetText(addon.GroupSortMode.Role)
    role:SetChecked(sortMode == addon.GroupSortMode.Role)

    local alpha = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    alpha:SetPoint("LEFT", role, "RIGHT", horizontalSpacing, 0)
    builder:TextShim(alpha)
    alpha.Text:SetText("Alpha")
    alpha:SetChecked(sortMode == addon.GroupSortMode.Alphabetical)

    local rev = CreateFrame("CheckButton", nil, parentPanel, "UICheckButtonTemplate")
    rev:SetPoint("LEFT", alpha, "RIGHT", horizontalSpacing, 0)
    builder:TextShim(rev)
    rev.Text:SetText("Reverse")
    rev:SetChecked(reverse)

    local modes = {
        [group] = addon.GroupSortMode.Group,
        [role] = addon.GroupSortMode.Role,
        [alpha] = addon.GroupSortMode.Alphabetical
    }

    local function onModeClick(sender)
        -- uncheck the others
        for chkbox, _ in pairs(modes) do
            if chkbox ~= sender then chkbox:SetChecked(false) end
        end

        local mode = modes[sender]
        onSortModeChanged(mode)
        addon:TrySort()
    end

    for chkbox, _ in pairs(modes) do
        chkbox:HookScript("OnClick", onModeClick)
    end

    rev:HookScript("OnClick", function()
        local value = rev:GetChecked()
        onReverseChanged(value)
        addon:TrySort()
    end)

    return modeLabel
end

function builder:BuildSortingOptions(panel)
    local anchor = BuiltTitle(panel)

    anchor = BuildSortModeCheckboxes(
        panel,
        anchor,
        "Dungeon (mythics, 5-mans)",
        addon.Options.Dungeon.Enabled,
        addon.Options.Dungeon.PlayerSortMode,
        addon.Options.Dungeon.GroupSortMode,
        addon.Options.Dungeon.Reverse,
        function(enabled) addon.Options.Dungeon.Enabled = enabled end,
        function(mode) addon.Options.Dungeon.PlayerSortMode = mode end,
        function(mode) addon.Options.Dungeon.GroupSortMode = mode end,
        function(reverse) addon.Options.Dungeon.Reverse = reverse end
    )

    anchor = BuildSortModeCheckboxes(
        panel,
        anchor,
        "Raid (battlegrounds, raids)",
        addon.Options.Raid.Enabled,
        addon.Options.Raid.PlayerSortMode,
        addon.Options.Raid.GroupSortMode,
        addon.Options.Raid.Reverse,
        function(enabled) addon.Options.Raid.Enabled = enabled end,
        function(mode) addon.Options.Raid.PlayerSortMode = mode end,
        function(mode) addon.Options.Raid.GroupSortMode = mode end,
        function(reverse) addon.Options.Raid.Reverse = reverse end
    )

    anchor = BuildSortModeCheckboxes(
        panel,
        anchor,
        "World (non-instance groups)",
        addon.Options.World.Enabled,
        addon.Options.World.PlayerSortMode,
        addon.Options.World.GroupSortMode,
        addon.Options.World.Reverse,
        function(enabled) addon.Options.World.Enabled = enabled end,
        function(mode) addon.Options.World.PlayerSortMode = mode end,
        function(mode) addon.Options.World.GroupSortMode = mode end,
        function(reverse) addon.Options.World.Reverse = reverse end
    )
end

---Initialises the addon options.
function addon:InitOptions()
    local panel = CreateFrame("Frame")
    panel.name = "FrameSort"

    InterfaceOptions_AddCategory(panel)

    builder:BuildSortingOptions(panel)
    builder:BuildSortingMethodOptions(panel)
    builder:BuildKeybindingOptions(panel)
    builder:BuildMacroOptions(panel)
    builder:BuildSpacingOptions(panel)
    builder:BuildHealthCheck(panel)

    SLASH_FRAMESORT1 = "/fs"
    SLASH_FRAMESORT2 = "/framesort"

    SlashCmdList.FRAMESORT = function()
        InterfaceOptionsFrame_OpenToCategory(panel.name)
    end
end
