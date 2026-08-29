DPSMateFile("DPSMate_OptionsFuncs3a3.lua")
DPSMateMark("opt:FUNCS3a3")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:ToggleVisibility()
	-- Minimap-Linksklick: alle Fenster gemeinsam. hidden wird in Settings
	-- gespeichert und beim Login in ApplyWindowVisibility wiederhergestellt.
	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) ~= "table" then return end
	local anyShown = false
	for _, val in windows do
		if val then
			local frame = getglobal("DPSMate_"..val["name"])
			if not frame then
				DPSMate:InitializeFrames()
				frame = getglobal("DPSMate_"..val["name"])
			end
			if frame and frame.IsShown and frame:IsShown() then
				anyShown = true
				break
			end
		end
	end
	for _, val in windows do
		if val then
			local frame = getglobal("DPSMate_"..val["name"])
			if frame then
				if anyShown then
					frame:Hide()
					val["hidden"] = true
				else
					frame:Show()
					val["hidden"] = false
				end
			end
		end
	end
end


