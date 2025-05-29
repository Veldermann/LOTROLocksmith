
import "Turbine.Gameplay"
import "Turbine.UI"
import "Turbine"

PlayerObject = Turbine.Gameplay.LocalPlayer.GetInstance()
PlayerName = PlayerObject:GetName()
PlayerClass = PlayerObject:GetClass()

DisplayWidth, DisplayHeight = Turbine.UI.Display.GetSize()

DisplayWidthOnePrecent = DisplayWidth / 100
DisplayHeightOnePrecent = DisplayHeight / 100

MiddleWidth, MiddleHeight = DisplayWidth / 2, DisplayHeight / 2

local function GetVersionNo()
	for _,plugin in ipairs(Turbine.PluginManager.GetAvailablePlugins()) do
		if (plugin.Name == "Locksmith") then
			return plugin.Version;
		end
	end
	return "";
end

_G.VersionNo = GetVersionNo()