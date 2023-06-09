local _, addon = ...

---Returns the set of raid frames.
---@param includeInvisible boolean true to include invisible frames, otherwise false.
---@return table<table>,table<table>,table<table> frames member frames, pet frames, member and pet frames combined
function addon:GetRaidFrames(includeInvisible)
    local container = CompactRaidFrameContainer

    if not container then return {}, {}, {} end
    if not container:IsVisible() then return {}, {}, {} end

    local frames = {}
    local members = {}
    local pets = {}
    local combined = {}
    local children = { CompactRaidFrameContainer:GetChildren() }

    for _, frame in pairs(children) do
        if frame and (includeInvisible or frame:IsVisible()) and frame.unitExists then
            frames[#frames + 1] = frame
        elseif string.match(frame:GetName() or "", "CompactRaidGroup") then
            -- if the raid frames are separated by group
            -- then the member frames are further nested
            local groupChildren = { frame:GetChildren() }

            for _, sub in pairs(groupChildren) do
                if sub and (includeInvisible or sub:IsVisible()) and sub.unitExists then
                    frames[#frames + 1] = sub
                end
            end
        end
    end

    for _, frame in pairs(frames) do
        if addon:IsMember(frame.unit) then
            members[#members + 1] = frame
            combined[#combined + 1] = frame
        elseif addon:IsPet(frame.unit) then
            pets[#pets + 1] = frame
            combined[#combined + 1] = frame
        else
            addon:Debug("Unknown unit type: " .. frame.unit)
        end
    end

    return members, pets, combined
end

---Returns the set of raid frame group frames.
---@param includeInvisible boolean true to include invisible frames, otherwise false.
---@return table<table> frames group frames
function addon:GetRaidFrameGroups(includeInvisible)
    local frames = {}
    local container = CompactRaidFrameContainer

    if not container then return frames end
    if not container:IsVisible() then return frames end

    local children = { container:GetChildren() }

    for _, frame in pairs(children) do
        if (includeInvisible or frame:IsVisible()) and string.match(frame:GetName() or "", "CompactRaidGroup") then
            frames[#frames + 1] = frame
        end
    end

    return frames
end

---Returns the set of visible member frames within a raid group frame.
---@param includeInvisible boolean true to include invisible frames, otherwise false.
---@return table<table> frames group frames
function addon:GetRaidFrameGroupMembers(group, includeInvisible)
    local frames = { group:GetChildren() }
    local members = {}

    for _, frame in ipairs(frames) do
        if frame and (includeInvisible or frame:IsVisible()) and frame.unitExists then
            members[#members + 1] = frame
        end
    end

    return members
end

---Returns the set of visible party frames.
---@param includeInvisible boolean true to include invisible frames, otherwise false.
---@return table<table> frames party frames
function addon:GetPartyFrames(includeInvisible)
    local frames = {}
    local container = CompactPartyFrame

    if not container then return frames end
    if not container:IsVisible() then return frames end

    if not CompactPartyFrame then
        return frames
    end

    local children = { container:GetChildren() }

    for _, frame in pairs(children) do
        if frame and frame.unitExists and (includeInvisible or frame:IsVisible()) then
            frames[#frames + 1] = frame
        end
    end

    return frames
end

---Returns the player compact raid frame.
---@return table playerFrame
function addon:GetPlayerFrame()
    local frames = addon:GetPartyFrames(true)

    if not frames or #frames == 0 then
        frames = addon:GetRaidFrames(true)
    end

    -- find the player frame
    local player = nil
    for _, frame in ipairs(frames) do
        if UnitIsUnit("player", frame.unit) then
            player = frame
            break
        end
    end

    return player
end

---Returns the frames in order of their relative positioning to each other.
---@param frames table<table> frames in any particular order
---@return LinkedListNode root in order of parent -> child -> child -> child
function addon:ToFrameChain(frames)
    local nodesByFrame = {}
    for _, frame in ipairs(frames) do
        nodesByFrame[frame:GetName()] = {
            Next = nil,
            Previous = nil,
            Value = frame
        }
    end

    local root = nil
    for _, child in pairs(nodesByFrame) do
        local _, relativeTo, _, _, _ = child.Value:GetPoint()
        local parent = nodesByFrame[relativeTo:GetName()]

        if parent then
            if parent.Next then
                addon:Error(string.format("Encountered multiple children for frame %s in frame frame chain.", parent.Value:GetName()))
                return {}
            end

            parent.Next = child
            child.Previous = parent
        else
            root = child
        end
    end

    -- assert we have a complete chain
    local count = 0
    local current = root

    while current do
        count = count + 1
        current = current.Next
    end

    if count ~= #frames then
        addon:Error(string.format("Incomplete/broken frame chain: expected %d nodes but only found %d", #frames, count))
        return {}
    end

    return root
end
