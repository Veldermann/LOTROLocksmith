
-- Import Turbine/Lotro base libraries --
import "Turbine"
import "Turbine.UI.Lotro"
import "Locksmith.GlobalVariables"
import "Locksmith.Dictionaries"
import "Locksmith.Utilities"

-- Load in previous data
LocksmithLocksData = Turbine.PluginData.Load(Turbine.DataScope.Server, "LocksmithLocksData")
LocksmithCharacterSettings = Turbine.PluginData.Load(Turbine.DataScope.Character, "LocksmithCharacterSettings")

-- Character Specific Settings
if LocksmithCharacterSettings == nil then
    LocksmithCharacterSettings = {}
    LocksmithCharacterSettings["settings"] = {
        ["window"] = {
            ["position_x"] = 100,
            ["position_y"] = 100
        },
        ["button"] = {
            ["position_x"] = 100,
            ["position_y"] = 100
        },
        ["showButton"] = true
    }
end

Turbine.PluginData.Save(Turbine.DataScope.Character, "LocksmithCharacterSettings", LocksmithCharacterSettings)

datetime = Turbine.Engine:GetDate()
year = datetime.Year
hour = datetime.Hour
dayOfWeek = datetime.DayOfWeek  
dayOfYear = datetime.DayOfYear

-- Calculate reset day
if dayOfWeek ~= 5 then
    if dayOfWeek > 5 then
        resetWeekly = 5 - dayOfWeek + dayOfYear + 7
    else
        resetWeekly = 5 - dayOfWeek + dayOfYear
    end
else
    resetWeekly = dayOfYear
end

if hour >= 10 then
    resetDaily = dayOfYear + 1
else
    resetDaily = dayOfYear
end

-- Server wide settings
if LocksmithLocksData == nil then
    LocksmithLocksData = {}
    LocksmithLocksData["locks"] = {}
    LocksmithLocksData["characterData"] = {}
    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
end

if not LocksmithLocksData["locks"] then
    LocksmithLocksData["locks"] = {}
end

if not LocksmithLocksData["locks"][PlayerName] then
    LocksmithLocksData["locks"][PlayerName] = {}
end

if not LocksmithLocksData["characterData"] then
    LocksmithLocksData["characterData"] = {}
end

if not LocksmithLocksData["characterData"][PlayerName] then
    LocksmithLocksData["characterData"][PlayerName] = classDictionary[PlayerClass]
end

Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)

import "Locksmith.LocksmithInfoWindow"
LocksmithInfoWindow = LocksmithInfoWindow()

import "Locksmith.Commands"

import "Locksmith.LocksmithIconButton"
LocksmithIconButton = LocksmithIconButton()

-- Determine if chest opened or dungeon completed
Turbine.Chat.Received = function(sender, args)
    message = args.Message
    if args.ChatType == 4 then
        if message:find("The lock for ") and message:find(" has expired.") then
            checkForResets()
            return
        end
        if message:find(" - Tier ") or message:find("Solo") then
            for boss, instance in pairs(chestsDictionary) do
                strStart, strEnd = string.find(message:gsub("-", " "), boss)
                if strStart ~= nil then
                    _, fullLocked = message:find("resets in: ")
                    if fullLocked then
                        completionsRemaining = "LOCKED"
                    else
                        _, completionsNumberEnd = message:find("You have ")
                        completionsRemaining = message:sub(completionsNumberEnd + 1, completionsNumberEnd + 1)
                    end

                    if message:find("Solo") then
                        instanceTier = "Solo"
                    else
                        _, tierEnd = message:find("Tier ")
                        instanceTier = "Tier " .. message:sub(tierEnd + 1, tierEnd + 1)
                    end

                    add_and_save(instance, instanceTier, completionsRemaining)
                    break
                end
            end
        end

    -- Special Instances
    -- args.ChatType == 21, message:find(" -- Solo")
    -- Completed: Featured Instance: Great Barrow - Thadúr (cap level)
    elseif args.ChatType == 21 and message:find("Completed:")then
        -- Featured Instance
        if message:find("Featured Instance:") and message:find("cap level") then
            if not LocksmithLocksData["Featured Instance"] then
                _, featureStart = message:find("Instance: ")
                _, featureEnd = message:find("(cap level)")

                instance = chestsDictionary["Featured Instance"]
                instanceTier = message:sub(featureStart + 1, featureEnd - 11)
                completionsRemaining = "LOCKED"
                add_and_save(instance, instanceTier, completionsRemaining)
            end
        -- Dragon and the storms
        elseif message:find("The Dragon and the Storm") then
            if message:find(" -- Tier ") then
                for boss, instance in pairs(chestsDictionary) do
                    strStart, strEnd = string.find(message:gsub("-", " "), boss)
                    if strStart ~= nil then
                        completionsRemaining = 3
                        _, tierEnd = message:find(" -- Tier ")
                        instanceTier = "Tier " .. message:sub(tierEnd + 1, tierEnd + 1)

                        if message:find("Solo") then
                            instanceTier = "Solo"
                        else
                            _, tierEnd = message:find(" -- Tier ")
                            instanceTier = "Tier " .. message:sub(tierEnd + 1, tierEnd + 1)
                        end
                        if LocksmithLocksData["locks"][PlayerName][instance["name"]] then
                            if LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier] then
                                if LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier]["B1"] ~= "LOCKED" then
                                    if LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier]["B1"] <= 3 then
                                        completionsRemaining = LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier]["B1"] - 1
                                    end
                                else
                                    completionsRemaining = "LOCKED"
                                end
                            end
                        end
                        add_and_save(instance, instanceTier, completionsRemaining)
                        break
                    end
                end
            end
        end 
    end
end

function add_and_save(instance, instanceTier, completionsRemaining)
    -- add Character
    if not LocksmithLocksData["locks"][PlayerName] then
        LocksmithLocksData["locks"][PlayerName] = {}
    end

    -- add Instance
    if not LocksmithLocksData["locks"][PlayerName][instance["name"]] then
        LocksmithLocksData["locks"][PlayerName][instance["name"]] = {}
    end

    -- add Instance Tier
    if not LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier] then
        LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier] = {}
    end

    -- Update or Add Boss
    LocksmithLocksData["locks"][PlayerName][instance["name"]][instanceTier][instance["boss"]] = completionsRemaining
    local completionEpoch = Turbine.Engine.GetLocalTime()
    LocksmithLocksData["locks"][PlayerName][instance["name"]]["completionEpoch"] = completionEpoch
    LocksmithLocksData["locks"][PlayerName][instance["name"]]["reset"] = instance["reset"]

    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
    return
end

-- Check for resets --
function checkForResets()
    local currentEpoch = Turbine.Engine.GetLocalTime()
    for character, instances in pairs(LocksmithLocksData["locks"]) do
        for instanceName, instanceData in pairs(instances) do
            if not instanceData["completionEpoch"] then
                LocksmithLocksData["locks"][character][instanceName] = nil
            else
                if (instanceData["reset"] == "daily" and isDailyReset(instanceData["completionEpoch"], currentEpoch)) or (instanceData["reset"] == "weekly" and isWeeklyReset(instanceData["completionEpoch"], currentEpoch)) then
                    LocksmithLocksData["locks"][character][instanceName] = nil
                end
            end
        end
    end
    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
end

-- Options menu on /plugins manager
function initializeOptionsMenu()
    local options = Turbine.UI.Control();
    options:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1));
    options:SetWidth(350);

    plugin.GetOptionsPanel = function(self) return options; end

    local checkbox = Turbine.UI.Lotro.CheckBox();
    checkbox:SetParent(options);
    checkbox:SetSize(350, 30);
    checkbox:SetPosition(10, 10);
    checkbox:SetText("Show Locksmith button for ease of access");
    checkbox:SetChecked(LocksmithCharacterSettings["settings"]["showButton"]);
    -- Handle checkbox state change --
    checkbox.CheckedChanged = function(sender, args)
        LocksmithIconButton:SetVisible(sender:IsChecked())
        LocksmithCharacterSettings["settings"]["showButton"] = sender:IsChecked()
        Turbine.PluginData.Save(Turbine.DataScope.Character, "LocksmithCharacterSettings", LocksmithCharacterSettings)
    end
end

initializeOptionsMenu()

checkForResets()
Turbine.Shell.WriteLine("Locksmith v" .. VersionNo .. " by Veldermann™")
