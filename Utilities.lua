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
