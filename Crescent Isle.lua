local intervalTime = 0.1
local actionStatusThreshold = 1780
local debug = false

local JOB_MAP = {
    Freelancer = { jobId = 0, jobStatusId = 4242, actionId = "", actionStatusId = "" },
    Knight     = { jobId = 1, jobStatusId = 4358, actionId = 32, actionStatusId = 4233 },
    Berserker  = { jobId = 2, jobStatusId = 4359, actionId = "", actionStatusId = "" },
    Monk       = { jobId = 3, jobStatusId = 4360, actionId = 33, actionStatusId = 4239 },
    Ranger     = { jobId = 4, jobStatusId = 4361, actionId = "", actionStatusId = "" },
    Samurai    = { jobId = 5, jobStatusId = 4362, actionId = "", actionStatusId = "" },
    Bard       = { jobId = 6, jobStatusId = 4363, actionId = 32, actionStatusId = 4244 },
    Geomancer  = { jobId = 7, jobStatusId = 4364, actionId = "", actionStatusId = "" },
    TimeMage   = { jobId = 8, jobStatusId = 4365, actionId = "", actionStatusId = "" },
    Cannoneer  = { jobId = 9, jobStatusId = 4366, actionId = "", actionStatusId = "" },
    Chemist    = { jobId = 10, jobStatusId = 4367, actionId = "", actionStatusId = "" },
    Oracle     = { jobId = 11, jobStatusId = 4368, actionId = "", actionStatusId = "" },
    Thief      = { jobId = 12, jobStatusId = 4369, actionId = "", actionStatusId = "" },
}

local function wait(second)
    if second > 0 then
        yield("/wait " .. second)
    end
end

local function debugPrint(message)
    if message then
        yield("/e " .. tostring(message))
    end
end

local function openSupportJob()
    if IsAddonVisible("MKDSupportJob") then
        return
    end
    repeat
        yield("/callback MKDInfo true 1 0")
        wait(intervalTime)
    until IsAddonVisible("MKDSupportJob")
end

local function openSupportJobList()
    if IsAddonVisible("MKDSupportJobList") then
        return
    end
    openSupportJob()
    repeat
        yield("/callback MKDSupportJob true 0 0 0")
        wait(intervalTime)
    until IsAddonVisible("MKDSupportJobList")
end

local function changeSupportJob(jobName)
    local jobData = JOB_MAP[jobName]
    if not jobData then
        if debug then
            debugPrint("Invalid job name: " .. tostring(jobName))
        end
        return
    end
    if HasStatusId(jobData.jobStatusId) then
        if debug then
            debugPrint("Job " .. jobName .. " is already active.")
        end
        return
    end
    openSupportJobList()
    repeat
        yield("/callback MKDSupportJobList true 0 " .. jobData.jobId)
        wait(intervalTime)
    until HasStatusId(jobData.jobStatusId)
end

local function useSupportAction(JOB_ORDER)
    for __, jobName in ipairs(JOB_ORDER) do
        local jobData = JOB_MAP[jobName]

        if not jobData then
            if debug then
                debugPrint("Invalid job name: " .. tostring(jobName))
            end
            goto continue
        end

        if jobData.actionStatusId ~= "" and GetStatusTimeRemaining(jobData.actionStatusId) >= actionStatusThreshold then
            if debug then
                debugPrint("Job " .. jobName .. " status is still active.")
            end
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

local function getCurrentJobName()
    for jobName, data in pairs(JOB_MAP) do
        if HasStatusId(data.jobStatusId) then
            return jobName
        end
    end
    return nil
end

local function main()
    local originalJob = getCurrentJobName()
    if debug and originalJob then
        debugPrint("Original job: " .. originalJob)
    end

    local JOB_ORDER = {
        "Knight", "Bard", "Monk",
    }
    useSupportAction(JOB_ORDER)

    if originalJob then
        if debug then
            debugPrint("Reverting to original job: " .. originalJob)
        end
        changeSupportJob(originalJob)
    end
end

main()
