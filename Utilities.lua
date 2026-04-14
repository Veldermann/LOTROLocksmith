function tableLenght(table)
    if table ~= nil then
        counter = 0
        for _ in pairs(table) do
            counter = counter + 1
        end
        return counter
    end
    return 0
end

function getNormilizedEpochDays(epochTime)
    local epochDays = math.floor((epochTime - 28800) / 86400)
    return epochDays
end

function isDailyReset(completionEpoch, currentEpoch)
    local currentDay = getNormilizedEpochDays(currentEpoch)
    local completionDay = getNormilizedEpochDays(completionEpoch)
    return currentDay > completionDay
end

function isWeeklyReset(completionEpoch, currentEpoch)
    local currentWeek = math.floor(getNormilizedEpochDays(currentEpoch) / 7)
    local completionWeek = math.floor(getNormilizedEpochDays(completionEpoch) / 7)
    return currentWeek > completionWeek
end

function sortByInstances()
    local sortedByInsance = {}
    
    for playerName, instance in pairs(LocksmithLocksData["locks"]) do
        for dungeonName, dungeonData in pairs(instance) do
            -- Initialize Insance
            sortedByInsance[dungeonName] = sortedByInsance[dungeonName] or {}
            for tier, tierData in pairs(dungeonData) do
                if type(tierData) == "table" then
                    -- Initialize Tier
                    sortedByInsance[dungeonName][tier] = sortedByInsance[dungeonName][tier] or {}
                    for boss, completionsRemaining in pairs(tierData) do
                        -- Initialize Boss
                        sortedByInsance[dungeonName][tier][boss] = sortedByInsance[dungeonName][tier][boss] or {}
                        -- Assign player and completionsRemaining
                        sortedByInsance[dungeonName][tier][boss][playerName] = completionsRemaining
                    end
                end
            end
        end
    end

    return sortedByInsance
end
