local JOBACTION_ORDER = { --Job names are available in multiple languages.
    { job = "Ritter", actions = {1} },
    { job = "吟遊詩人", actions = {1} },
    { job = "monk", actions = {1} },
    -- { job = "Geomancer", actions = {2,1} }, -- Multiple skills can be specified for a single job.
}
local useSimpleTweaksCommand = true -- Need Simple Tweaks Command
local jobChangeCommand = "/phantomjob"
local intervalTime = 0.1 -- seconds
local actionStatusThreshold = 10 -- seconds
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
    Freelancer = {
        jobName = { jp = "すっぴん", en = "Freelancer", de = "Freiberufler", fr = "Freelance" },
        jobId = 0,
        jobStatusId = 4357,
        actions = {}
    },
    Knight = {
        jobName = { jp = "ナイト", en = "Knight", de = "Ritter", fr = "Paladin" },
        jobId = 1,
        jobStatusId = 4358,
        actions = {
            { actionId = 32, actionStatusId = 4233, actionLevel = 2, statusTime = 1800, crystal = true },
        }
    },
    Berserker = {
        jobName = { jp = "バーサーカー", en = "Berserker", de = "Berserker", fr = "Berserker" },
        jobId = 2,
        jobStatusId = 4359,
        actions = {
        }
    },
    Monk = {
        jobName = { jp = "モンク", en = "Monk", de = "Mönch", fr = "Moine" },
        jobId = 3,
        jobStatusId = 4360,
        actions = {
            { actionId = 33, actionStatusId = 4239, actionLevel = 3, statusTime = 1800, crystal = true },
        }
    },
    Ranger = {
        jobName = { jp = "狩人", en = "Ranger", de = "Jäger", fr = "Rôdeur" },
        jobId = 4,
        jobStatusId = 4361,
        actions = {
        }
    },
    Samurai = {
        jobName = { jp = "侍", en = "Samurai", de = "Samurai", fr = "Samouraï" },
        jobId = 5,
        jobStatusId = 4362,
        actions = {
        }
    },
    Bard = {
        jobName = { jp = "吟遊詩人", en = "Bard", de = "Barde", fr = "Barde" },
        jobId = 6,
        jobStatusId = 4363,
        actions = {
            { actionId = 32, actionStatusId = 4244, actionLevel = 2, statusTime = 1800, crystal = true },
            { actionId = 31, actionStatusId = 4247, actionLevel = 1, statusTime = 70 },
        }
    },
    Geomancer = {
        jobName = { jp = "風水士", en = "Geomancer", de = "Geomant", fr = "Chronomancien" },
        jobId = 7,
        jobStatusId = 4364,
        actions = {
            { actionId = 31, actionStatusId = 4251, actionLevel = 1, statusTime = 60 },
            { actionId = 34, actionStatusId = 4258, actionLevel = 4, statusTime = 60 },
        }
    },
    TimeMage = {
        jobName = { jp = "時魔道士", en = "Time Mage", de = "Zeitmagier", fr = "Artilleur" },
        jobId = 8,
        jobStatusId = 4365,
        actions = {
            { actionId = 35, actionStatusId = 4260, actionLevel = 5, statusTime = 20 },
        }
    },
    Cannoneer = {
        jobName = { jp = "砲撃士", en = "Cannoneer", de = "Grenadier", fr = "Canonier" },
        jobId = 9,
        jobStatusId = 4366,
        actions = {
        }
    },
    Chemist = {
        jobName = { jp = "薬師", en = "Chemist", de = "Alchemist", fr = "Alchimiste" },
        jobId = 10,
        jobStatusId = 4367,
        actions = {
        }
    },
    Oracle = {
        jobName = { jp = "予言士", en = "Oracle", de = "Seher", fr = "Devin" },
        jobId = 11,
        jobStatusId = 4368,
        actions = {
        }
    },
    Thief = {
        jobName = { jp = "シーフ", en = "Thief", de = "Dieb", fr = "Voleur" },
        jobId = 12,
        jobStatusId = 4369,
        actions = {
            { actionId = 31, actionStatusId = 4276, actionLevel = 1, statusTime = 10 },
        }
    },
}

local JOB_MAP_LOWER = {}
for name, data in pairs(JOB_MAP) do
    JOB_MAP_LOWER[string.lower(name)] = data
end

local function findJobKeyByAnyName(name)
    local nameLower = string.lower(name)
    for key, data in pairs(JOB_MAP) do
        for lang, jobName in pairs(data.jobName) do
            if string.lower(jobName) == nameLower then
                return key
            end
        end
    end
    return nil
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

local function openSupportJob()
    while not IsAddonVisible("MKDSupportJob") do
        yield("/callback MKDInfo true 1 0")
        wait(intervalTime)
    end
end

local function openSupportJobList()
    while not IsAddonVisible("MKDSupportJobList") do
        openSupportJob()
        yield("/callback MKDSupportJob true 0 0 0")
        wait(intervalTime)
    end
end

local function getClientLanguage()
    local jobNameText = GetNodeText("MKDInfo", 34)
    if jobNameText then
        if string.find(jobNameText, "サポート") then
            return "jp"
        elseif string.find(jobNameText, "Phantom ") then
            return "en"
        elseif string.find(jobNameText, "Phantom%-") then
            return "de"
        elseif string.find(jobNameText, "fantôme") then
            return "fr"
        end
    end
    return "en"
end

local function getOriginalJobName()
    for jobName, data in pairs(JOB_MAP) do
        if HasStatusId(data.jobStatusId) then
            return jobName
        end
    end
    return nil
end

local function getCurrentJobLevel()
    local level = GetNodeText("MKDInfo", 32)
    if level then
        return tonumber(level)
    end

    return 1
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
    local jobKey = findJobKeyByAnyName(jobName)
    local jobData = jobKey and JOB_MAP[jobKey] or nil
    if not jobData then
        debugPrint("Invalid job name: " .. tostring(jobName))
        return
    end
    if HasStatusId(jobData.jobStatusId) then
        debugPrint("Job " .. jobName .. " is already active.")
        return
    end
    if useSimpleTweaksCommand then
        repeat
            yield(jobChangeCommand .. " " .. jobData.jobId)
            wait(intervalTime)
        until HasStatusId(jobData.jobStatusId)
    else
        openSupportJobList()
        repeat
            yield("/callback MKDSupportJobList true 0 " .. jobData.jobId)
            wait(intervalTime)
        until HasStatusId(jobData.jobStatusId)
    end
end

local function useSupportAction(JOBACTION_ORDER)
    for __, jobEntry in ipairs(JOBACTION_ORDER) do
        local jobNameInput = jobEntry.job
        local jobKey = findJobKeyByAnyName(jobNameInput) or string.lower(jobNameInput)
        local jobData = JOB_MAP[jobKey] or JOB_MAP_LOWER[jobKey]
        if not jobData then
            debugPrint("Invalid job name: " .. tostring(jobNameInput))
            goto continue
        end
        local actionIndexes = jobEntry.actions or {1}
        for _, idx in ipairs(actionIndexes) do
            local action = jobData.actions[idx]
            if not action then
                debugPrint("No action index "..tostring(idx).." for job "..jobNameInput)
                goto action_continue
            end
            if action.crystal == true and not isNearAnyCrystal() then
                debugPrint("Action requires crystal, but not near any crystal. Skipping job change and action.")
                goto action_continue
            end
            changeSupportJob(jobData.jobName["en"] or jobKey)
            local threshold = (action.statusTime or 0) - actionStatusThreshold
            debugPrint("Using job: " .. jobNameInput .. " action#"..idx.." with threshold: " .. threshold)
            if action.actionStatusId and HasStatusId(action.actionStatusId) and GetStatusTimeRemaining(action.actionStatusId) >= threshold then
                debugPrint("Job " .. jobNameInput .. " action#"..idx.." status is still active.")
                goto action_continue
            end
            if action.actionId and getCurrentJobLevel() >= action.actionLevel then
                if threshold <= 0 then
                    repeat
                        if not GetCharacterCondition(27) then
                            ExecuteGeneralAction(action.actionId)
                        end
                        wait(intervalTime)
                    until HasStatusId(action.actionStatusId)
                else
                    repeat
                        if not GetCharacterCondition(27) then
                            ExecuteGeneralAction(action.actionId)
                        end
                        wait(intervalTime)
                    until HasStatusId(action.actionStatusId) and GetStatusTimeRemaining(action.actionStatusId) >= threshold
                end
            end
            ::action_continue::
        end
        ::continue::
    end
end


local function main()

    local originalJob = getOriginalJobName()
    debugPrint("Original job: " .. originalJob)

    useSupportAction(JOBACTION_ORDER)

    if originalJob then
        debugPrint("Reverting to original job: " .. originalJob)
        changeSupportJob(originalJob)
    end
end

main()
