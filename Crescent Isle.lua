local JOB_ORDER = { "Knight", "Bard", "Monk" }
local jobChangeCommand = "/phantomjob" -- Need SimpleTweaksCommand
local language = "en"
local intervalTime = 0.1
local actionStatusThreshold = 1780
local debug = false


local CRYSTAL_MAP = {
    [1252] = { -- South Horn
        {x = 835.9, y = 73.1, z = -709.3},
        {x = -165.8, y = 6.5, z = -616.5},
        {x = -347.2, y = 100.3, z = -124.1},
        {x = -393.1, y = 97.5, z = 278.7},
        {x = 302.6, y = 103.1, z = 313.7},
    },
}

local JOB_MAP = {
    Freelancer = { jobName = {jp = "すっぴん", en = "Freelancer", de = "Freiberufler", fr = "Freelance" },
                    jobStatusId = 4357, actionId = "", actionStatusId = "" },
    Knight     = { jobName = {jp = "ナイト", en = "Knight", de = "Ritter", fr = "Paladin" },
                    jobStatusId = 4358, actionId = 32, actionStatusId = 4233 },
    Berserker  = { jobName = {jp = "バーサーカー", en = "Berserker", de = "Berserker", fr = "Berserker" },
                    jobStatusId = 4359, actionId = "", actionStatusId = "" },
    Monk       = { jobName = {jp = "モンク", en = "Monk", de = "Mönch", fr = "Moine" },
                    jobStatusId = 4360, actionId = 33, actionStatusId = 4239 },
    Ranger     = { jobName = {jp = "狩人", en = "Ranger", de = "Jäger", fr = "Rôdeur" },
                    jobStatusId = 4361, actionId = "", actionStatusId = "" },
    Samurai    = { jobName = {jp = "侍", en = "Samurai", de = "Samurai", fr = "Samouraï" },
                    jobStatusId = 4362, actionId = "", actionStatusId = "" },
    Bard       = { jobName = {jp = "吟遊詩人", en = "Bard", de = "Barde", fr = "Barde" },
                    jobStatusId = 4363, actionId = 32, actionStatusId = 4244 },
    Geomancer  = { jobName = { jp = "風水士", en = "Geomancer", de = "Geomant", fr = "Chronomancien" },
                    jobStatusId = 4364, actionId = "", actionStatusId = "" },
    TimeMage   = { jobName = {jp = "時魔道士", en = "Time Mage", de = "Zeitmagier", fr = "Artilleur" },
                    jobStatusId = 4365, actionId = "", actionStatusId = "" },
    Cannoneer  = { jobName = {jp = "砲撃士", en = "Cannoneer", de = "Grenadier", fr = "Canonier" },
                    jobStatusId = 4366, actionId = "", actionStatusId = "" },
    Chemist    = { jobName = {jp = "薬師", en = "Chemist", de = "Alchemist", fr = "Alchimiste" },
                    jobStatusId = 4367, actionId = "", actionStatusId = "" },
    Oracle     = { jobName = {jp = "予言士", en = "Oracle", de = "Seher", fr = "Devin" },
                    jobStatusId = 4368, actionId = "", actionStatusId = "" },
    Thief      = { jobName = {jp = "シーフ", en = "Thief", de = "Dieb", fr = "Voleur" },
                    jobStatusId = 4369, actionId = "", actionStatusId = "" },
}

local JOB_MAP_LOWER = {}
for name, data in pairs(JOB_MAP) do
    JOB_MAP_LOWER[string.lower(name)] = data
end

local function wait(second)
    if second > 0 then
        yield("/wait " .. second)
    end
end

local function debugPrint(message)
    if message and debug then
        yield("/e " .. tostring(message))
    end
end

local function getCurrentJobName()
    for jobName, data in pairs(JOB_MAP) do
        if HasStatusId(data.jobStatusId) then
            local lang = language or "en"
            if data.jobName[lang] then
                return data.jobName[lang]
            else
                return data.jobName["en"]
            end
        end
    end
    return nil
end

local function isNearAnyCrystal()
    local zoneId = GetZoneID()
    local crystalList = CRYSTAL_MAP[zoneId]
    if not crystalList then
        debugPrint("No crystals found for Zone ID " .. tostring(zoneId))
        return false
    end

    local name = GetCharacterName()
    local playerX = GetPlayerRawXPos(name)
    local playerZ = GetPlayerRawZPos(name)

    for _, crystal in ipairs(crystalList) do
        local dx = playerX - crystal.x
        local dz = playerZ - crystal.z
        local distance = math.sqrt(dx * dx + dz * dz)
        if distance <= 4.8 then
            return true
        end
    end
    return false
end

local function changeSupportJob(jobName)
    local jobKey = string.lower(jobName)
    local jobData = JOB_MAP_LOWER[jobKey]
    if not jobData then
        debugPrint("Invalid job name: " .. tostring(jobName))
        return
    end

    if HasStatusId(jobData.jobStatusId) then
        debugPrint("Job " .. jobName .. " is already active.")
        return
    end

    local lang = language or "en"
    local jobNameLocalized = jobData.jobName[lang] or jobData.jobName["en"]
    repeat
        yield(jobChangeCommand .." ".. jobNameLocalized)
        wait(intervalTime)
    until HasStatusId(jobData.jobStatusId)
end

local function useSupportAction(JOB_ORDER)
    for __, jobName in ipairs(JOB_ORDER) do
        local jobKey = string.lower(jobName)
        local jobData = JOB_MAP_LOWER[jobKey]

        if not jobData then
            debugPrint("Invalid job name: " .. tostring(jobName))
            goto continue
        end

        if jobData.actionStatusId ~= "" and GetStatusTimeRemaining(jobData.actionStatusId) >= actionStatusThreshold then
            debugPrint("Job " .. jobName .. " status is still active.")
            goto continue
        end

        changeSupportJob(jobName)

        if jobData.actionId ~= "" then
            repeat
                ExecuteGeneralAction(jobData.actionId)
                wait(intervalTime)
            until GetStatusTimeRemaining(jobData.actionStatusId) >= actionStatusThreshold
        end

        ::continue::
    end
end


local function main()
    if not isNearAnyCrystal() then
        debugPrint("Not near any crystal. Aborting.")
        return
    end

    local originalJob = getCurrentJobName()
    debugPrint("Original job: " .. originalJob)

    useSupportAction(JOB_ORDER)

    if originalJob then
        debugPrint("Reverting to original job: " .. originalJob)
        changeSupportJob(originalJob)
    end
end

main()
