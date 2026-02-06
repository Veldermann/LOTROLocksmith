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





--[[
-- Test functions --
function getMyEpoch()
    local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    datetime = Turbine.Engine:GetDate()
    year = datetime.Year
    month = datetime.Month
    day = datetime.Day
    hour = datetime.Hour
    minutes = datetime.Minute
    seconds = datetime.Second
    
    -- 1. Count days for full years since 1970
    local days = 0
    for y = 1970, year - 1 do
        if (y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0)) then
            days = days + 366
        else
            days = days + 365
        end
    end
    
    -- 2. Count days for months in the current year
    for m = 1, month - 1 do
        days = days + days_in_month[m]
        -- Add leap day if it's Feb in a leap year
        if m == 2 and (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)) then
            days = days + 1
        end
    end
    
    -- 3. Add days in the current month
    days = days + (day - 1)
    
    -- 4. Calculate total seconds
    local epochWithTimeZone = (days * 86400) + (hour * 3600) + (minutes * 60) + seconds
    
    -- 5. Adjust for your timezone (UTC+2)
    -- Since your local time is 2 hours ahead, we subtract those 2 hours to get UTC
    return epochWithTimeZone
end

function getEpochDatetime(epoch)
    local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    
    -- Separate time from days
    local total_seconds = epoch
    local seconds = total_seconds % 60
    local total_minutes = math.floor(total_seconds / 60)
    local minutes = total_minutes % 60
    local total_hours = math.floor(total_minutes / 60)
    local hours = total_hours % 24
    local total_days = math.floor(total_hours / 24)

    -- Calculate Year
    local year = 1970
    while true do
        local leap = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0))
        local days_in_year = leap and 366 or 365
        if total_days < days_in_year then break end
        total_days = total_days - days_in_year
        year = year + 1
    end

    -- Calculate Month
    local leap = (year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0))
    if leap then days_in_month[2] = 29 end
    
    local month = 1
    while total_days >= days_in_month[month] do
        total_days = total_days - days_in_month[month]
        month = month + 1
    end
    
    local day = total_days + 1 -- total_days is 0-indexed for the month

    -- Return as a formatted string and a table
    local dateString = string.format("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hours, minutes, seconds)
    
    return {
        year = year, month = month, day = day, 
        hour = hours, minute = minutes, second = seconds,
        formatted = dateString
    }
end

function getDatetimeFromEpoch(epoch)
    -- 1. Adjust for your timezone (UTC+2 = 2 * 3600)
    local localEpoch = epoch
    
    -- 2. Days since Epoch (Jan 1, 1970 was a Thursday)
    local totalDays = math.floor(localEpoch / 86400)
    
    -- 3. Calculate Day of the Week
    -- We add 4 because the epoch started on a Thursday (the 4th day of a Sun-Sat week)
    local dayIndex = (totalDays + 4) % 7
    local days = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
    local dayName = days[dayIndex]

    -- 4. Calculate Time within the current day
    local secondsInDay = localEpoch % 86400
    local hour = math.floor(secondsInDay / 3600)
    local minute = math.floor((secondsInDay % 3600) / 60)
    local second = secondsInDay % 60
    
    return dayIndex, hour, minute, second
end

function getNextWeeklyResetEpoch()
    -- 1. Get current epoch and the server's date table
    local currentEpoch = Turbine.Engine.GetLocalTime();
    local dateTable = Turbine.Engine.GetDate();
    
    -- 2. Extract current progress through the week
    -- DayOfWeek: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    local dayOfWeek = dateTable.DayOfWeek;
    local hour = dateTable.Hour;
    local minute = dateTable.Minute;
    local second = dateTable.Second;

    -- 3. Calculate how many seconds have passed since the start of Sunday (00:00:00)
    local secondsIntoWeek = ((dayOfWeek - 1) * 86400) + (hour * 3600) + (minute * 60) + second;

    -- 4. Calculate when Thursday 03:00:00 occurs relative to Sunday 00:00:00
    -- (Thursday is the 5th day, so 4 full days have passed)
    local resetTargetSeconds = (4 * 86400) + (3 * 3600);

    -- 5. Determine seconds remaining until that target
    local remaining = resetTargetSeconds - secondsIntoWeek;

    -- If the reset for this week has already happened, the next one is in 7 days
    if (remaining <= 0) then
        remaining = remaining + 604800; -- (7 days * 86400 seconds)
    end

    -- 6. Return the absolute epoch of the next reset
    return currentEpoch + remaining;
end

function GetWeeklyResetTimer()
    -- 1. Get current epoch and date table from LOTRO Engine
    local currentTime = Turbine.Engine.GetLocalTime();
    local dateTable = Turbine.Engine.GetDate();
    
    -- 2. Determine Day of Week (LOTRO returns 1 for Sunday, 5 for Thursday)
    local dayOfWeek = dateTable.DayOfWeek;
    local hour = dateTable.Hour;
    local minute = dateTable.Minute;
    local second = dateTable.Second;

    -- 3. Calculate seconds since the start of the current week (Sunday 00:00)
    local secondsIntoWeek = ((dayOfWeek - 1) * 86400) + (hour * 3600) + (minute * 60) + second;

    -- 4. Set Reset Target: Thursday (5th day) at 03:00:00
    local resetSecondsIntoWeek = ((5 - 1) * 86400) + (3 * 3600);

    -- 5. Calculate remaining time
    local remaining = resetSecondsIntoWeek - secondsIntoWeek;

    -- If we've already passed Thursday 3am, the next reset is next week (+7 days)
    if (remaining < 0) then
        remaining = remaining + (7 * 86400);
    end

    return remaining + (7 * 3600);
end

function GetTimeParts(remaining)
    local days = math.floor(remaining / 86400);
    local hours = math.floor((remaining % 86400) / 3600);
    local minutes = math.floor((remaining % 3600) / 60);
    local seconds = math.floor(remaining % 60);
    
    return days, hours, minutes, seconds
end

-- Example Usage:
local remaining = GetWeeklyResetTimer(); -- Assume this returns 144605
local d, h, m, s = GetTimeParts(remaining);

Turbine.Shell.WriteLine(string.format("Next reset in: %d days, %d hours, %d minutes, and %d seconds", d, h, m, s));
]]
