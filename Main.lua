-- Import Turbine/Lotro base libraries --
import "Turbine"
import "Turbine.UI.Lotro"
import "Locksmith.GlobalVariables"
import "Locksmith.Dictionaries"
import "Locksmith.Utilities"

-- Load in previous data
LocksmithLocksData = Turbine.PluginData.Load(Turbine.DataScope.Server, "LocksmithLocksData")
LocksmithCharacterSettings = Turbine.PluginData.Load(Turbine.DataScope.Character, "LocksmithCharacterSettings")

import "Locksmith.Commands"
import "Locksmith.LocksmithIconButton"

LocksmithIconButton = LocksmithIconButton()

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
    LocksmithLocksData["reset"] = {["year"] = year, ["weekly"] = resetWeekly, ["daily"] = resetDaily}
    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
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
        }
    }
end

Turbine.PluginData.Save(Turbine.DataScope.Character, "LocksmithCharacterSettings", LocksmithCharacterSettings)

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
    end

    -- Dragon and the storms, special development
    -- args.ChatType == 21
    if args.ChatType == 21 and message:find("Completed:") and message:find("The Dragon and the Storm") then
        -- message:find(" -- Solo")
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

function add_and_save(instance, instanceTier, completionsRemaining)
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

    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
    return
end

function checkForResets()
    if year > LocksmithLocksData["reset"]["year"] then
        LocksmithLocksData["locks"] = {}
        LocksmithLocksData["reset"]["year"] = year 
        LocksmithLocksData["reset"]["weekly"] = LocksmithLocksData["reset"]["weekly"] + 7
        LocksmithLocksData["reset"]["daily"] = dayOfYear + 1
    else
        if dayOfYear >= LocksmithLocksData["reset"]["weekly"] and hour >= 10 then
            LocksmithLocksData["locks"] = {}
            LocksmithLocksData["reset"]["year"] = year
            LocksmithLocksData["reset"]["weekly"] = LocksmithLocksData["reset"]["weekly"] + 7
            LocksmithLocksData["reset"]["daily"] = dayOfYear + 1
        end
    
        if dayOfYear >= LocksmithLocksData["reset"]["daily"] and hour >= 10 then
            for chest, instance in pairs(chestsDictionary) do
                if instance["reset"] == "daily" and hour >= 10 then
                    for character, instanceLocks in pairs (LocksmithLocksData["locks"]) do
                        for instanceName, _ in pairs(instanceLocks) do
                            if instance["name"] == instanceName then
                                LocksmithLocksData["locks"][character][instanceName] = nil
                            end
                        end
                        LocksmithLocksData["reset"]["daily"] = dayOfYear + 1
                    end
                end
    
                for character, instanceLocks in pairs (LocksmithLocksData["locks"]) do
                    if instance["name"] == "Dragon" and LocksmithLocksData["locks"][character]["Dragon"] and LocksmithSettings["locks"][character]["Dragon"]["SOLO"] then
                        if tableLenght(LocksmithLocksData["locks"][character]["Dragon"]) > 1 then
                            LocksmithLocksData["locks"][character]["Dragon"]["SOLO"] = nil
                        else
                            LocksmithLocksData["locks"][character]["Dragon"] = nil
                        end 
                    end
                end
            end
        end
    end
    Turbine.PluginData.Save(Turbine.DataScope.Server, "LocksmithLocksData", LocksmithLocksData)
end

-- Disabled due to a misbehaviour

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

-- Chests
-- MK B1 - Well-worn Corsair's Chest - Tier 2: You have 3 completions remaining.
-- MK B2 - Belondor's Chest - Tier 2: You have 3 completions remaining.
-- MK B3 - Forgotten Smuggler's Chest - Tier 2: You have 3 completions remaining.


-- Tomb B1 - Sakhârshag's Chest - Tier 2: You have 9 completions remaining.
-- Tomb B2 - Imanak-tûr's Chest - Tier 2: You have 9 completions remaining.
-- Tomb B3 - Aratûg's Chest - Tier 2: You have 9 completions remaining.

-- Dragon - Ragrekhûl's Spoils



--[[ ERROR

The lock for Khâshap's Chest - Solo has expired.
The lock for Utho's Chest - Solo has expired.
The lock for Aratûg's Chest - Solo has expired.
The lock for Imanak-tûr's Chest - Solo has expired
The lock for Sakhârshag's Chest - Solo has expired.
The lock for Raghârik's Chest - Solo has expired.
The lock for Urâbaz's Chest - Solo has expired.
The lock for Arena Veteran's Chest - Solo has expired.
The lock for Arena Neophyte's Chest - Solo has expired.
The lock for Arena Champion's Chest - Solo has expired.

]]