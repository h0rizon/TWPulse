local TWP = CreateFrame("Frame")

TWP:RegisterEvent("ADDON_LOADED")

TWP:SetScript("OnEvent", function()
    if event then
        if event == "ADDON_LOADED" and arg1 == 'TWPulse' then
            TWPulse:EnableMouse(false)
            TWP.scan:Show()
        end
    end
end)

TWP.tracked = {}

TWP.scan = CreateFrame("Frame")
TWP.scan:Hide()
TWP.scan:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

TWP.scan:SetScript("OnUpdate", function()
    local plus = 0.1
    if GetTime() < (this.startTime + plus) then return end
    this.startTime = GetTime()

    local seen = {}
    local shared = {}
    local id = 1
    while true do
        local spellName = GetSpellName(id, BOOKTYPE_SPELL)
        if not spellName then break end

        -- one entry per name; ranks share a cooldown and must not each increment shared
        if spellName ~= "Shoot" and spellName ~= "Auto Shot" and not seen[spellName] then
            local start, duration, enabled = GetSpellCooldown(id, BOOKTYPE_SPELL)
            if start and duration and enabled == 1 and start > 0 and duration > 2 then
                local key = start .. ":" .. duration
                shared[key] = (shared[key] or 0) + 1
                seen[spellName] = { id = id, start = start, duration = duration, key = key }
            end
        end
        id = id + 1
    end

    -- same start+duration on several different spell names is the wand timer
    for name, info in next, seen do
        if shared[info.key] == 1 then
            if not TWP.tracked[name] then
                TWP.tracked[name] = info
            end
        end
    end

    local now = GetTime()
    for name, info in next, TWP.tracked do
        local start, duration = GetSpellCooldown(info.id, BOOKTYPE_SPELL)
        local remaining = 0
        if start and duration and start > 0 then
            remaining = start + duration - now
        end

        -- only the cooldown we recorded, and only once that end time has passed
        if remaining <= 0 and now >= (info.start + info.duration - 0.2) then
            TWP.tracked[name] = nil
            local tEx = string.split(GetSpellTexture(info.id, BOOKTYPE_SPELL), "\\")
            local tex = tEx[table.getn(tEx)]
            TWP.animateQueue[tex] = 1
            TWP.animation:Show()
        end
    end
end)

TWP.animationFrames = {}
TWP.animateQueue = {}

TWP.animation = CreateFrame("Frame")
TWP.animation:Hide()

TWP.animation:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWP.animation:SetScript("OnHide", function()
end)

TWP.animation:SetScript("OnUpdate", function()
    local plus = 0.01 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        for tex, alpha in next, TWP.animateQueue do
            if alpha then

                if not TWP.animationFrames[tex] then
                    TWP.animationFrames[tex] = CreateFrame("Frame", "TWP_" .. tex, TWPulse, "TWPulseTemplate")
                end

                getglobal("TWP_" .. tex .. "Icon"):SetTexture("Interface\\Icons\\" .. tex)
                getglobal("TWP_" .. tex):Show()
                getglobal("TWP_" .. tex):SetAlpha(alpha)
                getglobal("TWP_" .. tex .. "Icon"):SetWidth(getglobal("TWP_" .. tex .. "Icon"):GetWidth() + 0.5)
                getglobal("TWP_" .. tex .. "Icon"):SetHeight(getglobal("TWP_" .. tex .. "Icon"):GetHeight() + 0.5)

                TWP.animateQueue[tex] = TWP.animateQueue[tex] - 0.02

                if TWP.animateQueue[tex] <= 0 then
                    getglobal("TWP_" .. tex):SetAlpha(alpha)
                    getglobal("TWP_" .. tex .. "Icon"):SetWidth(125)
                    getglobal("TWP_" .. tex .. "Icon"):SetHeight(125)
                    getglobal("TWP_" .. tex):SetAlpha(0)
                    TWP.animateQueue[tex] = nil
                end
            end
        end

        if TWP.locked then
            if _tablesize(TWP.animateQueue) > 0 then
                TWPulse:Show()
            else
                TWPulse:Hide()
            end
        end

        this.startTime = GetTime()

    end
end)

TWP.locked = true

SLASH_TWPLOCK1 = "/twplock"
SlashCmdList["TWPLOCK"] = function(cmd)
    if cmd then
        TWP.locked = true
        TWPulseUnlock:Hide()
        TWPulse:Hide()
        TWPulse:EnableMouse(false)
    end
end

SLASH_TWPUNLOCK1 = "/twpunlock"
SlashCmdList["TWPUNLOCK"] = function(cmd)
    if cmd then
        TWP.locked = false
        TWPulseUnlock:Show()
        TWPulse:Show()
        TWPulse:EnableMouse(true)
    end
end

function _tablesize(t)
    local size = 0
    for i in t do
        size = size + 1
    end
    return size
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end



